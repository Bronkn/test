-- Kontor: which bag items bring more at the vendor than in the AH
-- (Pflichtenheft 4.3). Only finds candidates; selling happens in CleanupUI
-- after the user confirmed the preview.

local _, Kontor = ...

Kontor.CLEANUP_MAX_STACKS = 12 -- everything stays recoverable via buyback

local QUEST_ITEM_CLASS = (Enum.ItemClass and Enum.ItemClass.Questitem) or 12

local function isQuestItem(bag, slot, classID)
    if classID == QUEST_ITEM_CLASS then return true end
    if C_Container.GetContainerItemQuestInfo then
        local q = C_Container.GetContainerItemQuestInfo(bag, slot)
        if q and (q.isQuestItem or q.questID) then return true end
    end
    return false
end

-- Returns the list of candidate stacks, highest vendor value first, and the
-- number of stacks held back because disenchanting brings more.
-- Each: { bag, slot, itemID, link, icon, count, vendorTotal, ahNetTotal, priceTime }
function Kontor:FindCleanupCandidates()
    local db = self.db
    local cfg = db.config
    local list, heldBack = {}, 0

    self:ForEachBagItem(function(bag, slot, info)
        local itemID = info.itemID
        -- 4. bound items are no AH decision; no vendor value at all: skip early
        if info.isBound or info.hasNoValue then return end
        -- 6. quality: at most the configured limit; grey is out of scope (Pflichtenheft 7)
        local quality = info.quality
        if not quality or quality < 1 or quality > cfg.cleanupMaxQuality then return end
        -- 5. watchlist and "never sell"
        if db.exclusions[itemID] or self:FindBasketItem(itemID) then return end

        local sellPrice, classID = select(11, C_Item.GetItemInfo(itemID))
        if sellPrice == nil then
            -- item data not loaded yet; GET_ITEM_INFO_RECEIVED triggers a recount
            if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
            return
        end
        -- 1. vendor price > 0
        if sellPrice <= 0 then return end
        -- 7. no quest items
        if isQuestItem(bag, slot, classID) then return end
        -- 2. scan price present and fresh. Items without a price are never touched.
        local entry = self:GetPrice(itemID)
        if not entry or not entry.p or not self:IsPriceFresh(entry) then return end
        -- 3. vendor >= AH net (plus safety margin)
        if sellPrice < entry.p * (1 - cfg.ahFee) * (1 + cfg.cleanupMargin) then return end
        -- 8. nothing that brings more when disenchanted (Nachtrag 2, 6)
        if self:HoldBackForDisenchant(info.hyperlink or itemID, info.isBound) then
            heldBack = heldBack + 1
            return
        end

        local count = info.stackCount or 1
        table.insert(list, {
            bag = bag, slot = slot, itemID = itemID,
            link = info.hyperlink, icon = info.iconFileID,
            count = count,
            vendorTotal = sellPrice * count,
            ahNetTotal = self:NetPrice(entry.p) * count,
            priceTime = entry.t,
        })
    end)

    table.sort(list, function(a, b) return a.vendorTotal > b.vendorTotal end)
    return list, heldBack
end
