-- Kontor: buy, sell and craft signals (Pflichtenheft 4.8, Nachtrag 1 sections 2, 3, 4.1, 5).

local _, Kontor = ...

-- Signal of one watchlist item. Returns a table
--   { kind = "buy"|"sell"|"craft"|nil, text, hint }
-- hint: extra remark, e.g. price above the NPC fixed price.
function Kontor:GetItemSignal(basket, item, itemID)
    local res = {}
    local entry = self:GetPrice(itemID)
    local fresh = entry and entry.p and self:IsPriceFresh(entry) and entry.listed ~= false

    if entry and entry.p and item.fixedPrice and entry.p > item.fixedPrice then
        res.hint = "über Festpreis - Käufer greifen zum NPC"
    end

    -- Products of a workshop basket: craft signal, independent of the phase.
    local recipe = self.db.recipes[itemID]
    if recipe then
        local craft = self:CraftSignal(recipe)
        if craft then
            res.kind, res.text = "craft", craft
            return res
        end
    end

    if not fresh then return res end -- signals only with a fresh price (4.8)
    local phase = self:GetItemPhase(basket, item)

    if phase == "sammeln" then
        if item.buyLimit and entry.p <= item.buyLimit and not self:IsOverBudget(basket) then
            local stock = self:GetPosition(itemID)
            if not item.stockLimit or stock < item.stockLimit then
                res.kind, res.text = "buy", "Kaufen"
            end
        end
    elseif phase == "halten" or phase == "abstossen" then
        local stock, avg = self:GetPosition(itemID)
        if stock > 0 then
            local target = self:EffectiveTarget(item)
            if not target and avg then
                target = self:BreakEven(avg) * (1 + self.db.config.minMargin)
            end
            if target and self:NetPrice(entry.p) >= target then
                res.kind, res.text = "sell", "Verkaufen"
            end
        end
    end
    return res
end

-- Signal for an item ID wherever it is: basket item, or reagent of a
-- recipe whose product would be worth crafting (tooltip of reagents).
function Kontor:SignalForItem(itemID)
    local basket, item = self:FindBasketItem(itemID)
    if basket then
        local sig = self:GetItemSignal(basket, item, itemID)
        if sig.kind then return sig end
    end
    for _, use in ipairs(self:RecipesUsing(itemID)) do
        if not use.via then
            local craft = self:CraftSignal(use.recipe)
            if craft then
                return { kind = "craft", text = craft .. ": " .. self:RecipeName(use.recipe) }
            end
        end
    end
end

-- Number of buy, sell and craft signals over all baskets (scan summary).
function Kontor:CountSignals()
    local counts = { buy = 0, sell = 0, craft = 0 }
    for _, basket in ipairs(self.db.baskets) do
        for itemID, item in pairs(basket.items) do
            local sig = self:GetItemSignal(basket, item, itemID)
            if sig.kind then counts[sig.kind] = counts[sig.kind] + 1 end
        end
    end
    return counts
end

Kontor.SIGNAL_COLORS = { buy = "|cff33ff33", sell = "|cffffcc00", craft = "|cff66ccff" }

function Kontor:SignalText(sig)
    if not sig or not sig.kind then return "" end
    return (self.SIGNAL_COLORS[sig.kind] or "") .. sig.text .. "|r"
end
