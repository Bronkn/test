-- Kontor: which bag items are worth more in the AH than at the vendor
-- (counterpart of Cleanup.lua, wish of the user 13.10.2026). The addon only
-- lists them; a click puts one into Blizzard's sell frame and the user
-- posts it there. Nothing is posted by the addon (Pflichtenheft 2, 6.1).

local _, Kontor = ...

-- Rules of the sales list for one item. Returns true, AH net unit price,
-- vendor price, price entry, from basket; or false plus the reason.
function Kontor:PostingVerdict(itemID, isBound)
    local db = self.db
    if isBound then return false, "gebunden" end
    if db.postExclusions[itemID] then return false, "nicht anbieten" end
    -- Watchlist items only in phase "Abstoßen" (decision 13.10.2026).
    local basket, item = self:FindBasketItem(itemID)
    local selling = basket and self:GetItemPhase(basket, item) == "abstossen"
    if basket and not selling then return false, "im Korb, nicht Abstoßen" end

    local entry = self:GetPrice(itemID)
    if not entry or not entry.p then return false, "ohne Scan-Preis" end
    if entry.listed == false then return false, "zuletzt nicht im AH" end
    if not self:IsPriceFresh(entry) then return false, "Preis zu alt" end

    local sellPrice, classID = select(11, C_Item.GetItemInfo(itemID))
    if sellPrice == nil then
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        return false, "Item-Daten laden noch"
    end
    if classID == ((Enum.ItemClass and Enum.ItemClass.Questitem) or 12) then return false, "Quest-Item" end
    local net = self:NetPrice(entry.p)
    -- vendor is as good: that is Aufräumen's job
    if net <= sellPrice then return false, "Händler bringt mehr" end
    return true, net, sellPrice, entry, selling or nil
end

-- Returns candidate stacks, highest net AH value first, plus a count of
-- skipped stacks per reason (shown when items are missing from the list).
-- Each: { bag, slot, itemID, link, icon, count, unitPrice, ahNetTotal, vendorTotal, priceTime, fromBasket }
function Kontor:FindPostingCandidates()
    local list, skipped = {}, {}

    self:ForEachBagItem(function(bag, slot, info)
        local ok, net, sellPrice, entry, fromBasket = self:PostingVerdict(info.itemID, info.isBound)
        if not ok then
            skipped[net] = (skipped[net] or 0) + 1
            return
        end
        local count = info.stackCount or 1
        table.insert(list, {
            bag = bag, slot = slot, itemID = info.itemID, fromBasket = fromBasket,
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
