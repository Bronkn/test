-- Kontor: which bag items are worth more in the AH than at the vendor
-- (counterpart of Cleanup.lua, wish of the user 13.10.2026). The addon only
-- lists them; a click puts one into Blizzard's sell frame and the user
-- posts it there. Nothing is posted by the addon (Pflichtenheft 2, 6.1).

local _, Kontor = ...

-- Returns candidate stacks, highest net AH value first, plus a count of
-- skipped stacks per reason (shown when items are missing from the list).
-- Each: { bag, slot, itemID, link, icon, count, unitPrice, ahNetTotal, vendorTotal, priceTime }
function Kontor:FindPostingCandidates()
    local db = self.db
    local list, skipped = {}, {}
    local function skip(reason) skipped[reason] = (skipped[reason] or 0) + 1 end

    self:ForEachBagItem(function(bag, slot, info)
        local itemID = info.itemID
        if info.isBound then return skip("gebunden") end
        if db.postExclusions[itemID] then return skip("nicht anbieten") end
        -- Watchlist items only in phase "Abstoßen" (decision 13.10.2026).
        local basket, item = self:FindBasketItem(itemID)
        local selling = basket and self:GetItemPhase(basket, item) == "abstossen"
        if basket and not selling then return skip("im Korb, nicht Abstoßen") end

        local entry = self:GetPrice(itemID)
        if not entry or not entry.p then return skip("ohne Scan-Preis") end
        if entry.listed == false then return skip("zuletzt nicht im AH") end
        if not self:IsPriceFresh(entry) then return skip("Preis zu alt") end

        local sellPrice, classID = select(11, C_Item.GetItemInfo(itemID))
        if sellPrice == nil then
            if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
            return skip("Item-Daten laden noch")
        end
        if classID == ((Enum.ItemClass and Enum.ItemClass.Questitem) or 12) then return skip("Quest-Item") end

        local count = info.stackCount or 1
        local net = self:NetPrice(entry.p)
        -- vendor is as good: that is Aufräumen's job
        if net <= sellPrice then return skip("Händler bringt mehr") end

        table.insert(list, {
            bag = bag, slot = slot, itemID = itemID, fromBasket = selling or nil,
            link = info.hyperlink, icon = info.iconFileID,
            count = count, unitPrice = entry.p,
            ahNetTotal = net * count,
            vendorTotal = sellPrice * count,
            priceTime = entry.t,
        })
    end)

    table.sort(list, function(a, b) return a.ahNetTotal > b.ahNetTotal end)
    return list, skipped
end

-- Puts the stack into Blizzard's sell frame. Blizzard fills in the current
-- lowest price itself; the user checks it and clicks "Auktion erstellen".
function Kontor:PrepareListing(candidate)
    if not self.ahOpen or not AuctionHouseFrame or not AuctionHouseFrame.SetPostItem then
        self:Print("Das Auktionshaus ist nicht geöffnet.")
        return false
    end
    local info = C_Container.GetContainerItemInfo(candidate.bag, candidate.slot)
    if not info or info.itemID ~= candidate.itemID then
        self:Print("Das Item liegt nicht mehr an dieser Stelle. Die Liste wird aktualisiert.")
        return false
    end
    local location = ItemLocation:CreateFromBagAndSlot(candidate.bag, candidate.slot)
    AuctionHouseFrame:SetPostItem(location)
    return true
end
