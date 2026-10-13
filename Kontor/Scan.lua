-- Kontor: overview scan of the auction house (Pflichtenheft 4.1).
-- Pages through browse queries, stores lowest unit price and total
-- quantity per item ID for the current market. Processing happens in small
-- portions per frame and every request waits for the throttle system.
--
-- One query without filters does not return the whole AH in Forever, and
-- the queries for consumables and trade goods stopped at exactly 300 items
-- (test 13.10.2026). So the scan runs one query per item class; a query that
-- hits the cap is split into subclasses, and those into qualities. A final
-- query without filters catches anything outside these classes.

local _, Kontor = ...

local ROWS_PER_FRAME = 300
local QUERY_TIMEOUT = 15 -- seconds without an answer before a query is skipped

local Scan = {}
Kontor.Scan = Scan

-- Consumable, Container, Weapon, Armor, Reagent, Projectile, Trade Goods,
-- Item Enhancement, Recipe, Quiver, Quest, Key, Miscellaneous
local ITEM_CLASSES = { 0, 1, 2, 4, 5, 6, 7, 8, 9, 11, 12, 13, 15 }
local RESULT_CAP = 300 -- a query returning exactly this many rows was cut off
local QUALITIES = { { 6, "Schlecht" }, { 7, "Verbreitet" }, { 8, "Selten" }, { 9, "Rar" }, { 10, "Episch" } }

local function className(classID)
    return (C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(classID)) or ("Klasse " .. classID)
end

local function buildQueries()
    local list = {}
    for _, classID in ipairs(ITEM_CLASSES) do
        table.insert(list, { label = className(classID), classID = classID, level = "class" })
    end
    table.insert(list, { label = "ohne Filter", level = "all" })
    return list
end

-- Finer queries replacing a capped one: subclasses, then qualities.
local function splitQuery(q)
    local parts = {}
    if q.level == "class" and C_Item.GetItemSubClassInfo then
        for sub = 0, 30 do
            local name = C_Item.GetItemSubClassInfo(q.classID, sub)
            if name and name ~= "" then
                table.insert(parts, { label = q.label .. " / " .. name, classID = q.classID,
                    subClassID = sub, level = "sub" })
            end
        end
    elseif q.level == "sub" then
        for _, quality in ipairs(QUALITIES) do
            table.insert(parts, { label = q.label .. " / " .. quality[2], classID = q.classID,
                subClassID = q.subClassID, quality = quality[1], level = "quality" })
        end
    end
    return parts
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
local queries, queryIndex, queryItems, queryRows -- itemIDs / variant keys seen by the current query
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
    queryRows[itemID .. ":" .. variantKey] = true
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
            table.insert(diag, { label = q.label, items = q.items, timedOut = q.timedOut, capped = q.capped })
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
    queryItems, queryRows = {}, {}
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
                if Kontor:CountKeys(queryRows) == RESULT_CAP and q.level ~= "all" then
                    local parts = splitQuery(q)
                    if #parts == 0 then
                        q.capped = true
                    end
                    for i, part in ipairs(parts) do
                        table.insert(queries, queryIndex + i, part)
                    end
                end
                if queryIndex == #queries then
                    -- A skipped or cut-off query means items may be missing:
                    -- then the scan must not mark anything as "not listed".
                    local problem
                    for _, query in ipairs(queries) do
                        if query.timedOut then problem = "nicht alle Abfragen beantwortet" end
                        if query.capped then problem = problem or "manche Abfragen bei 300 Items abgeschnitten" end
                    end
                    finish(problem == nil, problem, true)
                    return
                end
                queryIndex = queryIndex + 1
                queryItems, queryRows, fullResults, requestPending, waitingForMore = {}, {}, false, false, false
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
    queries, queryIndex, queryItems, queryRows = buildQueries(), 1, {}, {}

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
