-- Kontor: main window content: baskets on the left, item table on the right
-- (Pflichtenheft 4.4, Nachtrag 1 sections 2, 3, 5; M6, M7 trend, M8 columns, M10 signals).

local _, Kontor = ...

local MAX_BASKETS = 12 -- basket buttons on screen; more scroll with the mouse wheel
local ROWS = 16 -- item rows at most; the window grows with the basket up to this
local MIN_ROWS = 4
local LEFT = 200 -- x of the right-hand part

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
        EditBoxOnEnterPressed = function(box)
            local dialog = box:GetParent()
            StaticPopupDialogs[dialog.which].OnAccept(dialog, dialog.data)
            dialog:Hide()
        end,
        EditBoxOnEscapePressed = function(box) box:GetParent():Hide() end,
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

-- Stock, cost basis and break-even are in the detail window (user, 13.10.2026).
local COLUMNS = {
    { key = "name", title = "Item", width = 170 },
    { key = "price", title = "Preis", width = 70, justify = "RIGHT" },
    { key = "age", title = "Alter", width = 50, justify = "RIGHT" },
    { key = "qty", title = "Menge AH", width = 58, justify = "RIGHT" },
    { key = "trend", title = "Trend Scan / 7 T.", width = 100, justify = "RIGHT" },
}

-- Signal shown as a small icon before the item name (user, 13.10.2026);
-- the text is in the row tooltip.
local SIGNAL_ICONS = {
    buy = "|TInterface\\COMMON\\Indicator-Green:14:14|t ",
    sell = "|TInterface\\COMMON\\Indicator-Yellow:14:14|t ",
    craft = "|TInterface\\Icons\\Trade_Alchemy:13:13|t ",
    hint = "|TInterface\\COMMON\\Indicator-Red:14:14|t ",
}

local function fillRow(row, itemID)
    local basket = selectedBasket()
    local item = basket.items[itemID]
    local c = row.cells
    local sig = Kontor:GetItemSignal(basket, item, itemID)
    local prefix = (sig.kind and SIGNAL_ICONS[sig.kind]) or (sig.hint and SIGNAL_ICONS.hint) or ""
    local name, _, quality = C_Item.GetItemInfo(itemID)
    if name then
        local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        c.name:SetText(prefix .. (color and color.hex or "") .. name .. (color and "|r" or ""))
    else
        -- not in the client cache yet; GET_ITEM_INFO_RECEIVED redraws the row
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
        c.name:SetText(prefix .. "|cff888888lädt ...|r")
    end

    local entry = Kontor:GetPrice(itemID)
    if entry and entry.p then
        c.price:SetText(Kontor:FormatMoney(entry.p))
        c.age:SetText(Kontor:FormatAgeShort(entry.t))
        c.qty:SetText(entry.listed == false and "0" or (entry.q or 0))
    else
        c.price:SetText("-") c.age:SetText("-") c.qty:SetText("-")
    end
    local trend = Kontor:GetTrend(itemID)
    c.trend:SetText(Kontor:FormatChange(trend.pPrev) .. " / " .. Kontor:FormatChange(trend.pWeek))

end

local function refresh()
    if not view or not view.frame:IsShown() then return end
    local db = Kontor.db
    local basket = selectedBasket()

    view.basketOffset = math.min(view.basketOffset, math.max(0, #db.baskets - MAX_BASKETS))
    for i, button in ipairs(view.basketButtons) do
        local b = db.baskets[i + view.basketOffset]
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
        view.layout(0)
        return
    end

    view.title:SetText(basket.name)
    view.note:SetText(basket.note ~= "" and ("Notiz: " .. basket.note) or "")

    local t = basketTotals(basket)
    local over = Kontor:IsOverBudget(basket)
    local investText = "Investiert " .. Kontor:FormatMoney(t.invested)
        .. (basket.budget and (" / Budget " .. Kontor:FormatMoney(basket.budget)) or " (kein Budget)")
    if over then investText = "|cffff5555" .. investText .. " - Budget überschritten|r" end
    local unrealized = t.value - t.cost
    view.stats:SetText("Phase " .. Kontor.PHASE_NAMES[basket.phase] .. "  ·  " .. investText .. "  ·  Marktwert " .. Kontor:FormatMoney(t.value)
        .. "  ·  Unrealisiert " .. (unrealized < 0 and "-" or "+") .. Kontor:FormatMoney(math.abs(unrealized))
        .. "  ·  Plätze " .. t.slots)

    local ids = Kontor:BasketItemIDs(basket)
    view.layout(#ids)
    view.table:SetRows(ids, fillRow)
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
    view = { frame = frame, basketButtons = {}, basketWidgets = {}, basketOffset = 0 }

    -- top bar after the scan status (the disenchant window has the minimap button)
    local buyButton = self:CreateButton(frame, "Kaufen zum Entzaubern", 160, function() Kontor:ShowDisenchantBuys() end)
    buyButton:SetPoint("TOPLEFT", 346, -30)
    self:CreatePostingButton(frame, "LEFT", buyButton, "RIGHT", 4, 0)

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
        b:EnableMouseWheel(true)
        b:SetScript("OnMouseWheel", function(_, delta)
            view.basketOffset = math.max(0, view.basketOffset - delta)
            refresh()
        end)
        view.basketButtons[i] = b
    end
    local new = self:CreateButton(frame, "Neu", 48, function() showDialog("KONTOR_NEW_BASKET") end)
    new:SetPoint("BOTTOMLEFT", 12, 40)
    local rename = self:CreateButton(frame, "Bearbeiten", 72, function()
        local b = selectedBasket()
        if b then Kontor:ShowBasketEditor(b.id) end
    end)
    rename:SetPoint("LEFT", new, "RIGHT", 2, 0)
    local delete = self:CreateButton(frame, "Löschen", 48, function()
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
    view.title:SetPoint("TOPLEFT", LEFT, -66)

    view.stats = self:CreateLabel(frame, "")
    view.stats:SetPoint("TOPLEFT", LEFT, -90)
    view.stats:SetWordWrap(false)
    view.note = self:CreateLabel(frame, "", "GameFontDisableSmall")
    view.note:SetPoint("TOPLEFT", LEFT, -104)
    view.note:SetWordWrap(false)

    view.table = self:CreateTable(frame, COLUMNS, ROWS, 20)
    view.table:SetPoint("TOPLEFT", LEFT, -122)
    local tableWidth = view.table.totalWidth
    view.stats:SetWidth(tableWidth)
    view.note:SetWidth(tableWidth)
    frame:SetWidth(LEFT + tableWidth + 16)

    -- Height follows the content: as many item rows as the basket has (4 to
    -- 16), and enough room for the basket buttons on the left.
    view.layout = function(itemCount)
        local rows = math.max(MIN_ROWS, math.min(ROWS, itemCount))
        view.table:SetVisibleRows(rows)
        local right = 122 + (rows + 1) * 20 + 18 + 44
        local baskets = math.min(MAX_BASKETS, #Kontor.db.baskets)
        local left = 84 + baskets * 24 + 70
        frame:SetHeight(math.max(right, left, 300))
    end
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
        local accountText = Kontor:AccountCountText(itemID)
        if accountText then GameTooltip:AddLine(accountText, 1, 1, 1) end
        local basket = selectedBasket()
        local sig = Kontor:GetItemSignal(basket, basket.items[itemID], itemID)
        if sig.kind then GameTooltip:AddLine("Signal: " .. Kontor:SignalText(sig)) end
        if sig.hint then GameTooltip:AddLine(sig.hint, 1, 0.53, 0) end
        GameTooltip:AddLine("Klick: Details  ·  Rechtsklick: aus dem Korb entfernen", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end

    local addLabel = self:CreateLabel(frame, "Item hinzufügen (Umschalt-Klick, Ziehen, ID):")
    addLabel:SetPoint("BOTTOMLEFT", LEFT, 18)
    local input = self:CreateInput(frame, 120)
    input:SetPoint("LEFT", addLabel, "RIGHT", 10, 0)
    input.onEnter = addItemFromInput
    local add = self:CreateButton(frame, "Hinzufügen", 90, function() addItemFromInput(input) end)
    add:SetPoint("LEFT", input, "RIGHT", 6, 0)

    view.basketWidgets = { rename, delete, addLabel, input, add }

    frame:HookScript("OnShow", refresh)
    Kontor:OnChange(refresh)
end

-- Item names arrive a moment later when the client has not cached them.
local redrawPending = false
Kontor:RegisterEvent("GET_ITEM_INFO_RECEIVED", "Körbe", function()
    if redrawPending then return end
    redrawPending = true
    C_Timer.After(0.2, function()
        redrawPending = false
        Kontor:FireChange() -- every open Kontor window redraws its names
    end)
end)

-- Ask the client for all watchlist and recipe items right after login, so
-- the names are known before the window is opened.
Kontor:RegisterEvent("PLAYER_LOGIN", "Körbe", function()
    if not C_Item.RequestLoadItemDataByID then return end
    for _, basket in ipairs(Kontor.db.baskets) do
        for itemID in pairs(basket.items) do C_Item.RequestLoadItemDataByID(itemID) end
    end
    for _, recipe in pairs(Kontor.db.recipes) do
        if recipe.product then C_Item.RequestLoadItemDataByID(recipe.product) end
        for _, r in ipairs(recipe.reagents or {}) do
            if r.itemID then C_Item.RequestLoadItemDataByID(r.itemID) end
        end
    end
end)

-- Basket editor: name, phase, budget, note (replaces the header buttons, 13.10.2026)
local editor

function Kontor:ShowBasketEditor(basketId)
    if not editor then
        local f = self:CreateWindow("KontorBasketEditor", "Kontor - Korb bearbeiten", 340, 230, "basketEditor")
        local function row(label, y)
            local l = self:CreateLabel(f, label)
            l:SetPoint("TOPLEFT", 20, y)
            return l
        end
        row("Name:", -72)
        f.name = self:CreateInput(f, 200)
        f.name:SetPoint("TOPLEFT", 110, -68)
        row("Phase:", -100)
        f.phase = self:CreateButton(f, "", 200, function()
            local list = Kontor.PHASES
            for i, p in ipairs(list) do
                if p == f.phaseValue then f.phaseValue = list[i % #list + 1] break end
            end
            f.phase:SetText(Kontor.PHASE_NAMES[f.phaseValue])
        end)
        f.phase:SetPoint("TOPLEFT", 106, -96)
        row("Budget:", -128)
        f.budget = self:CreateInput(f, 110)
        f.budget:SetPoint("TOPLEFT", 110, -124)
        local hint = self:CreateLabel(f, "z. B. 50g, leer = keins", "GameFontDisableSmall")
        hint:SetPoint("LEFT", f.budget, "RIGHT", 8, 0)
        row("Notiz:", -156)
        f.note = self:CreateInput(f, 200)
        f.note:SetPoint("TOPLEFT", 110, -152)
        local save = self:CreateButton(f, "Speichern", 110, function()
            local b = Kontor:GetBasket(f.basketId)
            if not b then f:Hide() return end
            local name = strtrim(f.name:GetText())
            if name ~= "" then b.name = name end
            b.phase = f.phaseValue
            b.budget = Kontor:ParseMoney(f.budget:GetText())
            b.note = strtrim(f.note:GetText())
            f:Hide()
            Kontor:FireChange()
        end)
        save:SetPoint("BOTTOMRIGHT", -16, 14)
        f.name.onEnter = function() save:Click() end
        editor = f
    end
    local b = self:GetBasket(basketId)
    if not b then return end
    editor.basketId = basketId
    editor.phaseValue = b.phase
    editor.name:SetText(b.name)
    editor.phase:SetText(self.PHASE_NAMES[b.phase])
    editor.budget:SetText(self:MoneyInputText(b.budget))
    editor.note:SetText(b.note or "")
    editor:Show()
end
