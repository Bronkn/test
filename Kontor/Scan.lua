-- Kontor: overview scan of the auction house (Pflichtenheft 4.1).
-- Pages through browse queries, stores lowest unit price and total
-- quantity per item ID for the current market. Processing happens in small
-- portions per frame and every request waits for the throttle system.
--
-- One query without filters returns the whole AH (test 13.10.2026: 3133 of
-- 3134 items; the earlier gaps were a queue bug fixed in 0.3.2). The query
-- list is kept so that a split scan can come back if the live AH needs it.

local _, Kontor = ...

local ROWS_PER_FRAME = 300
local QUERY_TIMEOUT = 15 -- seconds without an answer before a query is skipped

local Scan = {}
Kontor.Scan = Scan

local function buildQueries()
    return { { label = "ohne Filter" } }
end

-- Scan state, reset by start()
local state = "idle" -- "idle" | "waitingThrottle" | "running"
local market, prices
local startTime, lastActivity
-- Rows waiting for processing. queueHead/queueTail are explicit indices:
-- processed slots are cleared, so the length operator # must not be used.
local queue, queueHead, queueTail
local variants -- itemID -> { [variantKey] = { p, q } }
local itemCount
local requestPending, fullResults, waitingForMore
local queries, queryIndex, queryItems -- queryItems: itemIDs seen by the current query
local ownQuery -- true while our own SendBrowseQuery call runs

local worker = CreateFrame("Frame")
worker:Hide()

function Scan:IsRunning()
    return state ~= "idle"
end

-- items so far, seconds elapsed, current query number, number of queries
function Scan:GetProgress()
    return itemCount or 0, startTime and (GetTime() - startTime) or 0, queryIndex or 0, queries and #queries or 0
end

local function getMarketData(key, create)
    local markets = Kontor.db.markets
    if not markets[key] and create then
        markets[key] = { prices = {}, history = {} }
    end
    return markets[key]
end

function Kontor:GetMarketData(create)
    local key = self:GetMarketKey()
    return key and getMarketData(key, create)
end

-- One browse row (one item variant) into the scan aggregate and prices.
local function processRow(row)
    local key = row.itemKey
    if not key or not key.itemID or (key.battlePetSpeciesID or 0) ~= 0 then
        return
    end
    local itemID = key.itemID
    queryItems[itemID] = true
    local byVariant = variants[itemID]
    if not byVariant then
        byVariant = {}
        variants[itemID] = byVariant
        itemCount = itemCount + 1
    end
    local variantKey = (key.itemLevel or 0) .. ":" .. (key.itemSuffix or 0)
    byVariant[variantKey] = { p = row.minPrice, q = row.totalQuantity or 0 }

    -- Several variants: smallest price, quantities summed (Pflichtenheft 4.1).
    local minPrice, total
    for _, v in pairs(byVariant) do
        if v.p and (not minPrice or v.p < minPrice) then minPrice = v.p end
        total = (total or 0) + v.q
    end

    local entry = prices[itemID]
    if not entry then
        entry = {}
        prices[itemID] = entry
    end
    entry.p = minPrice
    entry.q = total
    entry.t = Scan.startedAt
    entry.listed = true
end

-- ranThrough: all queries were sent (the scan was not aborted).
local function finish(complete, reason, ranThrough)
    worker:Hide()
    local duration = math.floor(GetTime() - startTime + 0.5)
    local data = getMarketData(market, true)

    if complete then
        -- Items not seen this time keep price and timestamp, flagged as unlisted.
        for itemID, entry in pairs(prices) do
            if not variants[itemID] then
                entry.listed = false
            end
        end
    end

    local diag = {}
    for _, q in ipairs(queries) do
        if q.items then
            table.insert(diag, { label = q.label, items = q.items, timedOut = q.timedOut })
        end
    end
    data.lastScan = { t = Scan.startedAt, complete = complete, itemCount = itemCount, durationSec = duration,
        queries = diag }
    state = "idle"
    Kontor:OnScanFinished(complete, itemCount, duration, reason, ranThrough)
end

local function sendQuery()
    local sortOrder = Enum.AuctionHouseSortOrder or { Price = 0, Name = 1 }
    local current = queries[queryIndex]
    local query = {
        searchString = "",
        sorts = {
            { sortOrder = sortOrder.Price, reverseSort = false },
            { sortOrder = sortOrder.Name, reverseSort = false },
        },
        filters = current.quality and { current.quality } or {},
        itemClassFilters = current.classID and { { classID = current.classID, subClassID = current.subClassID } } or {},
    }
    queryItems = {}
    fullResults = false
    state = "running"
    requestPending = true
    lastActivity = GetTime()
    ownQuery = true
    C_AuctionHouse.SendBrowseQuery(query)
    ownQuery = false
end

local function requestMore()
    if fullResults or requestPending then return end
    if C_AuctionHouse.IsThrottledMessageSystemReady() then
        waitingForMore = false
        requestPending = true
        lastActivity = GetTime()
        C_AuctionHouse.RequestMoreBrowseResults()
    else
        waitingForMore = true -- AUCTION_HOUSE_THROTTLED_SYSTEM_READY continues
    end
end

local function enqueue(rows)
    for _, row in ipairs(rows or {}) do
        queue[queueTail] = row
        queueTail = queueTail + 1
    end
    requestPending = false
    lastActivity = GetTime()
    fullResults = C_AuctionHouse.HasFullBrowseResults()
    requestMore()
end

worker:SetScript("OnUpdate", function()
    Kontor:SafeCall("Scan", function()
        local stop = math.min(queueHead + ROWS_PER_FRAME, queueTail) - 1
        for i = queueHead, stop do
            processRow(queue[i])
            queue[i] = nil
        end
        queueHead = stop + 1

        if queueHead >= queueTail then
            queue, queueHead, queueTail = {}, 1, 1
            local timedOut = GetTime() - lastActivity > QUERY_TIMEOUT
            if (fullResults and state == "running") or timedOut then
                local q = queries[queryIndex]
                q.items = Kontor:CountKeys(queryItems)
                q.timedOut = timedOut and not fullResults
                if queryIndex == #queries then
                    -- A skipped query means items may be missing: then the scan
                    -- must not mark anything as "not listed".
                    local problem
                    for _, query in ipairs(queries) do
                        if query.timedOut then problem = "nicht alle Abfragen beantwortet" end
                    end
                    finish(problem == nil, problem, true)
                    return
                end
                queryIndex = queryIndex + 1
                queryItems, fullResults, requestPending, waitingForMore = {}, false, false, false
                lastActivity = GetTime()
                if C_AuctionHouse.IsThrottledMessageSystemReady() then
                    sendQuery()
                else
                    state = "waitingThrottle"
                end
            end
        end
    end)
end)

function Scan:Start()
    if state ~= "idle" then return end
    if not Kontor.ahOpen then
        Kontor:Print("Das Auktionshaus ist nicht geöffnet.")
        return
    end
    market = Kontor:GetMarketKey()
    if not market then
        Kontor:Print("Marktkennung unbekannt, Scan nicht möglich.")
        return
    end
    prices = getMarketData(market, true).prices
    startTime = GetTime()
    Scan.startedAt = time()
    lastActivity = startTime
    queue, queueHead, queueTail = {}, 1, 1
    variants = {}
    itemCount = 0
    requestPending, fullResults, waitingForMore = false, false, false
    queries, queryIndex, queryItems = buildQueries(), 1, {}

    if C_AuctionHouse.IsThrottledMessageSystemReady() then
        sendQuery()
    else
        state = "waitingThrottle"
    end
    worker:Show()
    Kontor:OnScanStarted()
end

function Scan:Abort(reason)
    if state == "idle" then return end
    finish(false, reason)
end

-- Events ---------------------------------------------------------------------

Kontor:RegisterEvent("AUCTION_HOUSE_SHOW", "Scan", function()
    Kontor.ahOpen = true
    Kontor:OnAuctionHouseShown()
end)

Kontor:RegisterEvent("AUCTION_HOUSE_CLOSED", "Scan", function()
    Kontor.ahOpen = false
    Scan:Abort("Auktionshaus geschlossen")
    Kontor:UpdateScanWidgets()
    Kontor:CloseMainFrameWithAH()
end)

Kontor:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "Scan", function()
    if state == "waitingThrottle" then
        sendQuery()
    elseif state == "running" and waitingForMore then
        requestMore()
    end
end)

Kontor:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "Scan", function()
    if state == "running" then
        enqueue(C_AuctionHouse.GetBrowseResults())
    end
end)

Kontor:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "Scan", function(_, added)
    if state == "running" then
        enqueue(added)
    end
end)

-- A search started in the normal AH window replaces our result list.
-- Stop cleanly instead of mixing it into the scan.
Kontor:SecureHook(C_AuctionHouse, "SendBrowseQuery", "Scan", function()
    if state ~= "idle" and not ownQuery then
        Scan:Abort("andere Suche im Auktionshaus gestartet")
    end
end)
