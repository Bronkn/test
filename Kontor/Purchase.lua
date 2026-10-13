-- Kontor: purchase detection prototype (Pflichtenheft 4.6, M5).
-- Watches commodity purchases made in the normal AH window and reports
-- item, quantity and price paid in chat. Nothing is bought by the addon.
--
-- COMMODITY_PURCHASE_SUCCEEDED carries no payload (see API-NOTIZEN.md), so
-- item and quantity come from the hooked calls and the total from
-- COMMODITY_PRICE_UPDATED.

local _, Kontor = ...

local pending -- { itemID, quantity, unitPrice, totalPrice }
Kontor.sessionPurchases = {} -- recorded this session; the ledger follows with M8

local function anySecret(...)
    for i = 1, select("#", ...) do
        if Kontor:IsSecret((select(i, ...))) then return true end
    end
    return false
end

Kontor:SecureHook(C_AuctionHouse, "StartCommoditiesPurchase", "Kauf-Erkennung", function(itemID, quantity)
    if anySecret(itemID, quantity) then pending = nil return end
    pending = { itemID = itemID, quantity = quantity }
end)

Kontor:SecureHook(C_AuctionHouse, "ConfirmCommoditiesPurchase", "Kauf-Erkennung", function(itemID, quantity)
    if anySecret(itemID, quantity) then pending = nil return end
    if pending and pending.itemID == itemID then
        pending.quantity = quantity
    else
        pending = { itemID = itemID, quantity = quantity }
    end
end)

Kontor:RegisterEvent("COMMODITY_PRICE_UPDATED", "Kauf-Erkennung", function(_, unitPrice, totalPrice)
    if pending and not anySecret(unitPrice, totalPrice) then
        pending.unitPrice = unitPrice
        pending.totalPrice = totalPrice
    end
end)

Kontor:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED", "Kauf-Erkennung", function()
    local p = pending
    pending = nil
    if not p then
        Kontor:Print("Kauf erkannt, aber Item und Menge sind unbekannt.")
        return
    end
    local total = p.totalPrice
    -- The price update belongs to the quantity at purchase start; if the
    -- confirmed quantity differs, scale by the unit price.
    if p.unitPrice and total and p.unitPrice * p.quantity ~= total then
        total = p.unitPrice * p.quantity
    end
    table.insert(Kontor.sessionPurchases, { t = time(), itemID = p.itemID, qty = p.quantity, total = total })
    -- Watchlist items go into the ledger automatically (Pflichtenheft 4.6).
    local booked = false
    if total and Kontor:FindBasketItem(p.itemID) then
        Kontor:AddLedgerEntry(p.itemID, "buy", p.quantity, total / p.quantity, "auto")
        booked = true
    end
    if total then
        Kontor:Print("Kauf erkannt: " .. Kontor:ItemLabel(p.itemID) .. " × " .. p.quantity .. " für "
            .. Kontor:FormatMoney(total) .. " (je Stück " .. Kontor:FormatMoney(total / p.quantity) .. ")."
            .. (booked and " Im Journal gebucht." or ""))
    else
        Kontor:Print("Kauf erkannt: " .. Kontor:ItemLabel(p.itemID) .. " × " .. p.quantity .. ", Preis unbekannt.")
    end
end)

Kontor:RegisterEvent("COMMODITY_PURCHASE_FAILED", "Kauf-Erkennung", function()
    if pending then
        Kontor:Print("Kauf fehlgeschlagen: " .. Kontor:ItemLabel(pending.itemID) .. ".")
    end
    pending = nil
end)
