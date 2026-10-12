-- Kontor: market depth prototype (Pflichtenheft 4.8, M5): /kontor tiefe <Item>.
-- Fetches the commodity price ladder and prints it to chat.

local _, Kontor = ...

local MAX_LEVELS = 12
local MAX_REQUESTS = 10
local TIMEOUT = 15

local pending -- { itemID, requests, sent }
Kontor.lastDepth = {} -- itemID -> { t, levels = { { price, qty } } }, used later by M10

local function report(itemID)
    local levels, total = {}, 0
    for i = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
        local r = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
        if r then
            local last = levels[#levels]
            if last and last.price == r.unitPrice then
                last.qty = last.qty + r.quantity
            else
                table.insert(levels, { price = r.unitPrice, qty = r.quantity })
            end
            total = total + r.quantity
        end
    end
    Kontor.lastDepth[itemID] = { t = time(), levels = levels }

    local full = C_AuctionHouse.HasFullCommoditySearchResults(itemID)
    Kontor:Print("Markttiefe " .. Kontor:ItemLabel(itemID) .. ": " .. total .. " Stück auf "
        .. #levels .. " Preisstufen" .. (full and "" or " (Liste unvollständig)") .. ".")

    local cumQty, cumCost = 0, 0
    for i, level in ipairs(levels) do
        cumQty = cumQty + level.qty
        cumCost = cumCost + level.qty * level.price
        if i <= MAX_LEVELS then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s × %d  (bis hier %d Stück, zusammen %s)",
                Kontor:FormatMoney(level.price), level.qty, cumQty, Kontor:FormatMoney(cumCost)))
        end
    end
    if #levels > MAX_LEVELS then
        DEFAULT_CHAT_FRAME:AddMessage("  ... und " .. (#levels - MAX_LEVELS) .. " weitere Stufen")
    end

    -- Price of the first N units: a single stray cheap unit cannot distort it.
    local want = Kontor.db.config.depthUnits
    local got, cost = 0, 0
    for _, level in ipairs(levels) do
        local take = math.min(level.qty, want - got)
        got = got + take
        cost = cost + take * level.price
        if got >= want then break end
    end
    if got > 0 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Preis für die ersten %d Stück: %s, im Schnitt %s je Stück",
            got, Kontor:FormatMoney(cost), Kontor:FormatMoney(cost / got)))
    end
end

local function send()
    local sortOrder = Enum.AuctionHouseSortOrder or { Price = 0 }
    pending.sent = true
    C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(pending.itemID),
        { { sortOrder = sortOrder.Price, reverseSort = false } }, false)
end

function Kontor:QueryDepth(arg)
    local itemID = self:ParseItemID(arg)
    if not itemID then
        self:Print("Bitte ein Item angeben: /kontor tiefe, dann Umschalt-Klick auf ein Item.")
        return
    end
    if not self.ahOpen then
        self:Print("Markttiefe geht nur bei geöffnetem Auktionshaus.")
        return
    end
    if self.Scan:IsRunning() then
        self:Print("Bitte warten, bis der Scan fertig ist.")
        return
    end
    pending = { itemID = itemID, requests = 0 }
    local query = pending
    C_Timer.After(TIMEOUT, function()
        if pending == query then
            pending = nil
            Kontor:Print("Markttiefe: keine Antwort vom Auktionshaus.")
        end
    end)
    if C_AuctionHouse.IsThrottledMessageSystemReady() then
        send()
    end -- otherwise AUCTION_HOUSE_THROTTLED_SYSTEM_READY sends
end

local function onCommodityResults(_, itemID)
    if not pending or itemID ~= pending.itemID then return end
    if not C_AuctionHouse.HasFullCommoditySearchResults(itemID) and pending.requests < MAX_REQUESTS then
        pending.requests = pending.requests + 1
        C_AuctionHouse.RequestMoreCommoditySearchResults(itemID)
        return
    end
    pending = nil
    report(itemID)
end

Kontor:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED", "Markttiefe", onCommodityResults)
Kontor:RegisterEvent("COMMODITY_SEARCH_RESULTS_ADDED", "Markttiefe", onCommodityResults)

Kontor:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED", "Markttiefe", function(_, itemKey)
    if pending and itemKey and itemKey.itemID == pending.itemID then
        pending = nil
        Kontor:Print("Markttiefe: " .. Kontor:ItemLabel(itemKey.itemID)
            .. " ist keine Handelsware (Ausrüstung o. Ä.). Die Preistreppe gibt es nur für Handelswaren.")
    end
end)

Kontor:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", "Markttiefe", function()
    if pending and not pending.sent then send() end
end)

Kontor:RegisterEvent("AUCTION_HOUSE_CLOSED", "Markttiefe", function()
    pending = nil
end)
