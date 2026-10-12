-- Kontor: lookups shared by several modules.

local _, Kontor = ...

-- Price entry { p, q, t, listed } of itemID in the current character's market.
function Kontor:GetPrice(itemID)
    local data = self:GetMarketData(false)
    return data and data.prices[itemID]
end

-- True when the price is younger than the configured limit (default 48 h).
function Kontor:IsPriceFresh(entry)
    return entry and entry.t and (time() - entry.t) <= self.db.config.maxPriceAgeHours * 3600
end

-- Basket and item settings for itemID, or nil if it is on no watchlist.
function Kontor:FindBasketItem(itemID)
    for _, basket in ipairs(self.db.baskets) do
        local item = basket.items and basket.items[itemID]
        if item then
            return basket, item
        end
    end
end

-- Lowest unit price after AH fee.
function Kontor:NetPrice(price)
    return price * (1 - self.db.config.ahFee)
end

local BAG_COUNT = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4

-- Calls fn(bag, slot, info) for every filled slot in backpack and bags.
function Kontor:ForEachBagItem(fn)
    for bag = 0, BAG_COUNT do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                fn(bag, slot, info)
            end
        end
    end
end
