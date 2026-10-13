-- Kontor: ledger, stock and cost basis (Pflichtenheft 4.6, M8).
-- Entries: { t, itemID, basketId, type = "buy"|"sell"|"adjust", qty, unitPrice, source = "auto"|"manuell" }
-- For "adjust", qty is the change (+/-) so that the stock matches a counted value.

local _, Kontor = ...

function Kontor:AddLedgerEntry(itemID, entryType, qty, unitPrice, source)
    local basket = self:FindBasketItem(itemID)
    table.insert(self.db.ledger, {
        t = time(), itemID = itemID, basketId = basket and basket.id, type = entryType,
        qty = qty, unitPrice = unitPrice or 0, source = source or "manuell",
    })
    self:FireChange()
end

-- Stock and moving average cost of one item, from all its ledger entries.
-- Returns stock, average unit cost (nil without purchases).
function Kontor:GetPosition(itemID)
    local stock, avg = 0, nil
    for _, e in ipairs(self.db.ledger) do
        if e.itemID == itemID then
            if e.type == "buy" then
                local total = (avg or 0) * stock + e.unitPrice * e.qty
                stock = stock + e.qty
                avg = stock > 0 and total / stock or nil
            elseif e.type == "sell" then
                stock = stock - e.qty
            elseif e.type == "adjust" then
                stock = stock + e.qty
            end
            if stock <= 0 then
                stock = math.max(stock, 0)
                avg = nil -- nothing left: the next purchase starts a new average
            end
        end
    end
    return stock, avg
end

-- Break-even per unit: cost / (1 - AH fee).
function Kontor:BreakEven(avg)
    return avg and avg / (1 - self.db.config.ahFee)
end

-- Invested in a basket = purchases - sale proceeds (Pflichtenheft 4.6).
function Kontor:GetInvested(basket)
    local invested = 0
    for _, e in ipairs(self.db.ledger) do
        if e.basketId == basket.id then
            if e.type == "buy" then
                invested = invested + e.unitPrice * e.qty
            elseif e.type == "sell" then
                invested = invested - e.unitPrice * e.qty
            end
        end
    end
    return invested
end

function Kontor:IsOverBudget(basket)
    return basket.budget and basket.budget > 0 and self:GetInvested(basket) > basket.budget
end

-- Count on this character, bags and bank (shown next to the ledger stock).
function Kontor:GetCharacterCount(itemID)
    if C_Item.GetItemCount then
        return C_Item.GetItemCount(itemID, true)
    end
    return GetItemCount and GetItemCount(itemID, true) or 0
end

-- Change notification for open windows -------------------------------------

local listeners = {}

function Kontor:OnChange(fn)
    table.insert(listeners, fn)
end

function Kontor:FireChange()
    for _, fn in ipairs(listeners) do
        self:SafeCall("Anzeige", fn)
    end
end
