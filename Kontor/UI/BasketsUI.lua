-- Kontor: main window content: baskets on the left, item table on the right
-- (Pflichtenheft 4.4, Nachtrag 1 sections 2, 3, 5; M6, M7 trend, M8 columns, M10 signals).

local _, Kontor = ...

local MAX_BASKETS = 14
local ROWS = 16

local view -- the widgets, created once
local selectedId -- id of the selected basket

-- Dialogs --------------------------------------------------------------------

local function editBoxOf(dialog)
    return (dialog.GetEditBox and dialog:GetEditBox()) or dialog.editBox
end

local function textDialog(name, text, button, onAccept)
    StaticPopupDialogs[name] = {
        text = text, button1 = button, button2 = CANCEL, hasEditBox = true,
        OnShow = function(self, data)
            local box = editBoxOf(self)
            if box then box:SetText(data and data.default or "") box:HighlightText() end
        end,
        OnAccept = function(self, data)
            local box = editBoxOf(self)
            Kontor:SafeCall("Körbe", onAccept, box and box:GetText() or "", data)
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
end

local function showDialog(name, textArg, data)
    local dialog = StaticPopup_Show(name, textArg, nil, data)
    if dialog then dialog.data = data end
    return dialog
end
Kontor.ShowDialog = function(_, ...) return showDialog(...) end

textDialog("KONTOR_NEW_BASKET", "Name des neuen Korbs:", "Anlegen", function(text)
    text = strtrim(text)
    if text == "" then return end
    local basket = Kontor:CreateBasket(text, "beobachten", "lager")
    selectedId = basket.id
    Kontor:FireChange()
end)

textDialog("KONTOR_RENAME_BASKET", "Neuer Name für \"%s\":", "Umbenennen", function(text, data)
    local basket = Kontor:GetBasket(data.id)
    text = strtrim(text)
    if basket and text ~= "" then basket.name = text Kontor:FireChange() end
end)

textDialog("KONTOR_BASKET_BUDGET", "Budget für \"%s\" (z. B. 50g, leer = kein Budget):", OKAY, function(text, data)
    local basket = Kontor:GetBasket(data.id)
    if basket then basket.budget = Kontor:ParseMoney(text) Kontor:FireChange() end
end)

textDialog("KONTOR_BASKET_NOTE", "Notiz zu \"%s\":", OKAY, function(text, data)
    local basket = Kontor:GetBasket(data.id)
    if basket then basket.note = strtrim(text) Kontor:FireChange() end
end)

StaticPopupDialogs["KONTOR_DELETE_BASKET"] = {
    text = "Korb \"%s\" wirklich löschen?\n\nDie Items verlieren Kauflimit, Zielpreis und Notizen. Journal und Preise bleiben.",
    button1 = DELETE, button2 = CANCEL,
    OnAccept = function(_, data)
        Kontor:DeleteBasket(data.id)
        selectedId = nil
        Kontor:FireChange()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["KONTOR_REMOVE_ITEM"] = {
    text = "%s aus dem Korb entfernen?",
    button1 = REMOVE or "Entfernen", button2 = CANCEL,
    OnAccept = function(_, data)
        local basket = Kontor:GetBasket(data.id)
        if basket then Kontor:RemoveBasketItem(basket, data.itemID) Kontor:FireChange() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- Data -----------------------------------------------------------------------

local function selectedBasket()
    local basket = selectedId and Kontor:GetBasket(selectedId)
    if not basket then
        basket = Kontor.db.baskets[1]
        selectedId = basket and basket.id
    end
    return basket
end

-- Storage slots of a stock: ceil(stock / stack size) (Nachtrag 1, 5).
function Kontor:StorageSlots(itemID, stock)
    if stock <= 0 then return 0 end
    local stackSize = select(8, C_Item.GetItemInfo(itemID))
    if not stackSize or stackSize < 1 then return nil end
    return math.ceil(stock / stackSize)
end

local function basketTotals(basket)
    local t = { value = 0, cost = 0, slots = 0 }
    for itemID in pairs(basket.items) do
        local stock, avg = Kontor:GetPosition(itemID)
        if stock > 0 then
            local entry = Kontor:GetPrice(itemID)
            if entry and entry.p then t.value = t.value + Kontor:NetPrice(entry.p) * stock end
            t.cost = t.cost + (avg or 0) * stock
            t.slots = t.slots + (Kontor:StorageSlots(itemID, stock) or 0)
        end
    end
    t.invested = Kontor:GetInvested(basket)
    return t
end

-- Rendering --------------------------------------------------------------------

local COLUMNS = {
    { key = "name", title = "Item", width = 150 },
    { key = "price", title = "Preis", width = 64, justify = "RIGHT" },
    { key = "age", title = "Alter", width = 52, justify = "RIGHT" },
    { key = "qty", title = "Menge AH", width = 50, justify = "RIGHT" },
    { key = "trend", title = "Trend Scan / 7 T.", width = 92, justify = "RIGHT" },
    { key = "stock", title = "Bestand", width = 44, justify = "RIGHT" },
    { key = "slots", title = "Plätze", width = 36, justify = "RIGHT" },
    { key = "cost", title = "Einstand", width = 60, justify = "RIGHT" },
    { key = "be", title = "Break-even", width = 60, justify = "RIGHT" },
    { key = "signal", title = "Signal", width = 104 },
}

local function fillRow(row, itemID)
    local basket = selectedBasket()
    local item = basket.items[itemID]
    local c = row.cells
    local name, _, quality = C_Item.GetItemInfo(itemID)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    c.name:SetText((color and color.hex or "") .. (name or ("Item " .. itemID)) .. (color and "|r" or ""))

    local entry = Kontor:GetPrice(itemID)
    if entry and entry.p then
        c.price:SetText(Kontor:FormatMoney(entry.p))
        c.age:SetText((Kontor:FormatAge(entry.t):gsub("^vor ", "")))
        c.qty:SetText(entry.listed == false and "0" or (entry.q or 0))
    else
        c.price:SetText("-") c.age:SetText("-") c.qty:SetText("-")
    end
    local trend = Kontor:GetTrend(itemID)
    c.trend:SetText(Kontor:FormatChange(trend.pPrev) .. " / " .. Kontor:FormatChange(trend.pWeek))

    local stock, avg = Kontor:GetPosition(itemID)
    c.stock:SetText(stock > 0 and stock or "-")
    c.slots:SetText(stock > 0 and (Kontor:StorageSlots(itemID, stock) or "?") or "-")
    c.cost:SetText(avg and Kontor:FormatMoney(avg) or "-")
    c.be:SetText(avg and Kontor:FormatMoney(Kontor:BreakEven(avg)) or "-")

    local sig = Kontor:GetItemSignal(basket, item, itemID)
    if sig.kind then
        c.signal:SetText(Kontor:SignalText(sig))
    elseif sig.hint then
        c.signal:SetText("|cffff8800über Festpreis|r")
    else
        local phase = Kontor:GetItemPhase(basket, item)
        c.signal:SetText("|cff888888" .. Kontor.PHASE_NAMES[phase] .. (item.phase and " (Item)" or "") .. "|r")
    end
end

local function refresh()
    if not view or not view.frame:IsShown() then return end
    local db = Kontor.db
    local basket = selectedBasket()

    for i, button in ipairs(view.basketButtons) do
        local b = db.baskets[i]
        if b then
            button.basketId = b.id
            button:SetText((b.id == selectedId and "> " or "") .. b.name)
            button:Show()
        else
            button:Hide()
        end
    end

    local hasBasket = basket ~= nil
    for _, w in ipairs(view.basketWidgets) do w:SetShown(hasBasket) end
    if not basket then
        view.title:SetText("Noch keine Körbe. \"Neu\" legt einen an, /kontor vorlage die Startkörbe.")
        view.stats:SetText("")
        view.table:SetRows({}, fillRow)
        return
    end

    view.title:SetText(basket.name .. (basket.type == "werkstatt" and "  |cff66ccff(Werkstatt)|r" or ""))
    view.phaseButton:SetText("Phase: " .. Kontor.PHASE_NAMES[basket.phase])
    view.note:SetText(basket.note ~= "" and ("Notiz: " .. basket.note) or "")

    local t = basketTotals(basket)
    local over = Kontor:IsOverBudget(basket)
    local investText = "Investiert " .. Kontor:FormatMoney(t.invested)
        .. (basket.budget and (" / Budget " .. Kontor:FormatMoney(basket.budget)) or " (kein Budget)")
    if over then investText = "|cffff5555" .. investText .. " - Budget überschritten|r" end
    local unrealized = t.value - t.cost
    view.stats:SetText(investText .. "  ·  Marktwert " .. Kontor:FormatMoney(t.value)
        .. "  ·  Unrealisiert " .. (unrealized < 0 and "-" or "+") .. Kontor:FormatMoney(math.abs(unrealized))
        .. "  ·  Lagerplätze " .. t.slots)

    view.table:SetRows(Kontor:BasketItemIDs(basket), fillRow)
end
Kontor.RefreshBasketView = refresh

-- Building -------------------------------------------------------------------

local function addItemFromInput(box)
    local basket = selectedBasket()
    local itemID = basket and Kontor:ParseItemID(box:GetText())
    if not itemID then
        Kontor:Print("Item-Link (Umschalt-Klick), Item aus der Tasche ziehen oder Item-ID eingeben.")
        return
    end
    if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
    local ok, reason = Kontor:AddBasketItem(basket, itemID, {})
    if ok then
        box:SetText("")
        Kontor:FireChange()
    else
        Kontor:Print(Kontor:ItemLabel(itemID) .. " " .. reason .. ".")
    end
end

function Kontor:BuildBasketView(frame)
    view = { frame = frame, basketButtons = {}, basketWidgets = {} }

    -- top bar, next to "Verkaufsliste"
    local deButton = self:CreateButton(frame, "Entzaubern", 100, function() Kontor:ShowDisenchantWindow() end)
    deButton:SetPoint("TOPRIGHT", -136, -30)
    local buyButton = self:CreateButton(frame, "Kaufen zum Entzaubern", 160, function() Kontor:ShowDisenchantBuys() end)
    buyButton:SetPoint("RIGHT", deButton, "LEFT", -4, 0)

    -- left: baskets
    local header = self:CreateLabel(frame, "Körbe", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, -68)
    for i = 1, MAX_BASKETS do
        local b = self:CreateButton(frame, "", 172, function(btn)
            selectedId = btn.basketId
            refresh()
        end)
        b:SetPoint("TOPLEFT", 12, -84 - (i - 1) * 24)
        b:GetFontString():SetJustifyH("LEFT")
        view.basketButtons[i] = b
    end
    local new = self:CreateButton(frame, "Neu", 56, function() showDialog("KONTOR_NEW_BASKET") end)
    new:SetPoint("BOTTOMLEFT", 12, 40)
    local rename = self:CreateButton(frame, "Name", 56, function()
        local b = selectedBasket()
        if b then showDialog("KONTOR_RENAME_BASKET", b.name, { id = b.id, default = b.name }) end
    end)
    rename:SetPoint("LEFT", new, "RIGHT", 2, 0)
    local delete = self:CreateButton(frame, "Löschen", 56, function()
        local b = selectedBasket()
        if b then showDialog("KONTOR_DELETE_BASKET", b.name, { id = b.id }) end
    end)
    delete:SetPoint("LEFT", rename, "RIGHT", 2, 0)
    local recipes = self:CreateButton(frame, "Rezepte", 84, function() Kontor:ShowRecipeWindow() end)
    recipes:SetPoint("BOTTOMLEFT", 12, 14)
    local settings = self:CreateButton(frame, "Einstellungen", 86, function() Kontor:ShowSettings() end)
    settings:SetPoint("LEFT", recipes, "RIGHT", 2, 0)

    -- right: selected basket
    view.title = self:CreateLabel(frame, "", "GameFontNormalLarge")
    view.title:SetPoint("TOPLEFT", 200, -66)

    local phase = self:CreateButton(frame, "Phase", 150, function()
        local b = selectedBasket()
        if not b then return end
        local list = Kontor.PHASES
        for i, p in ipairs(list) do
            if p == b.phase then b.phase = list[i % #list + 1] break end
        end
        Kontor:FireChange()
    end)
    phase:SetPoint("TOPRIGHT", -16, -62)
    view.phaseButton = phase
    local budget = self:CreateButton(frame, "Budget", 70, function()
        local b = selectedBasket()
        if b then showDialog("KONTOR_BASKET_BUDGET", b.name, { id = b.id, default = Kontor:MoneyInputText(b.budget) }) end
    end)
    budget:SetPoint("RIGHT", phase, "LEFT", -4, 0)
    local note = self:CreateButton(frame, "Notiz", 60, function()
        local b = selectedBasket()
        if b then showDialog("KONTOR_BASKET_NOTE", b.name, { id = b.id, default = b.note }) end
    end)
    note:SetPoint("RIGHT", budget, "LEFT", -4, 0)

    view.stats = self:CreateLabel(frame, "")
    view.stats:SetPoint("TOPLEFT", 200, -90)
    view.note = self:CreateLabel(frame, "", "GameFontDisableSmall")
    view.note:SetPoint("TOPLEFT", 200, -104)
    view.note:SetWidth(760)

    view.table = self:CreateTable(frame, COLUMNS, ROWS, 20)
    view.table:SetPoint("TOPLEFT", 200, -122)
    view.table.onClick = function(itemID, mouse)
        local basket = selectedBasket()
        if mouse == "RightButton" then
            showDialog("KONTOR_REMOVE_ITEM", Kontor:ItemLabel(itemID), { id = basket.id, itemID = itemID })
        else
            Kontor:ShowItemDetail(basket.id, itemID)
        end
    end
    view.table.onEnter = function(row, itemID)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(itemID)
        local t = Kontor:GetTrend(itemID)
        GameTooltip:AddLine("Menge Trend: " .. Kontor:FormatChange(t.qPrev) .. " / " .. Kontor:FormatChange(t.qWeek), 1, 1, 1)
        GameTooltip:AddLine("Klick: Details  ·  Rechtsklick: aus dem Korb entfernen", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end

    local addLabel = self:CreateLabel(frame, "Item hinzufügen (Umschalt-Klick, Ziehen oder ID):")
    addLabel:SetPoint("BOTTOMLEFT", 200, 18)
    local input = self:CreateInput(frame, 220)
    input:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    input.onEnter = addItemFromInput
    local add = self:CreateButton(frame, "Hinzufügen", 90, function() addItemFromInput(input) end)
    add:SetPoint("LEFT", input, "RIGHT", 6, 0)

    view.basketWidgets = { phase, budget, note, rename, delete, addLabel, input, add }

    frame:HookScript("OnShow", refresh)
    Kontor:OnChange(refresh)
end
