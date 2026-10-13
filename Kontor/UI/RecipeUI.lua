-- Kontor: recipe window (Pflichtenheft 4.7, Nachtrag 1 section 4, Nachtrag 3; M9).
-- Recipes are edited as short text, one line per field:
--   Produkt: 249410
--   Ausbeute: 1
--   Beruf: Alchemie
--   Zutat: 249391 x2
--   Zutat: 3371 x1 Händler 20c
-- "Händler" marks a vendor reagent; the amount after it is its fixed price.

local _, Kontor = ...

local MAX_LIST = 16
local win
local selectedKey

local function recipeKeys()
    local keys = {}
    for key in pairs(Kontor.db.recipes) do table.insert(keys, key) end
    table.sort(keys, function(a, b)
        return Kontor:RecipeName(Kontor.db.recipes[a]) < Kontor:RecipeName(Kontor.db.recipes[b])
    end)
    return keys
end

-- Text form --------------------------------------------------------------------

local function recipeToText(recipe)
    local lines = {
        "Produkt: " .. (recipe.product or recipe.productName or ""),
        "Ausbeute: " .. (recipe.yield or 1),
        "Beruf: " .. (recipe.profession or ""),
    }
    for _, r in ipairs(recipe.reagents or {}) do
        local line = "Zutat: " .. (r.itemID or r.name or "?") .. " x" .. r.qty
        if r.vendor or r.fixedPrice then
            line = line .. " Händler" .. (r.fixedPrice and (" " .. Kontor:MoneyInputText(r.fixedPrice)) or "")
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

local function textToRecipe(text)
    local recipe = { yield = 1, reagents = {}, source = "manuell" }
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        local key, value = line:match("^%s*(%a+):%s*(.-)%s*$")
        if key == "Produkt" then
            recipe.product = Kontor:ParseItemID(value)
            if not recipe.product and value ~= "" then recipe.productName = value end
        elseif key == "Ausbeute" then
            recipe.yield = tonumber(value) or 1
        elseif key == "Beruf" then
            recipe.profession = value ~= "" and value or nil
        elseif key == "Zutat" then
            local what, qty, rest = value:match("^(.-)%s+x(%d+)%s*(.*)$")
            if not what then return nil, "Zutat ohne Menge: " .. line end
            local r = { qty = tonumber(qty) }
            r.itemID = Kontor:ParseItemID(what)
            if not r.itemID then r.name = what end
            local vendorPrice = rest:match("^[Hh]ändler%s*(.*)$")
            if vendorPrice then
                r.vendor = true
                r.fixedPrice = Kontor:ParseMoney(vendorPrice)
            end
            table.insert(recipe.reagents, r)
        end
    end
    if not recipe.product and not recipe.productName then return nil, "Zeile \"Produkt:\" fehlt." end
    if #recipe.reagents == 0 then return nil, "Keine Zutaten angegeben." end
    return recipe
end

local TEMPLATE = "Produkt: \nAusbeute: 1\nBeruf: \nZutat:  x1\nZutat:  x1 Händler "

local function editRecipe(key)
    local old = key and Kontor.db.recipes[key]
    local frame = Kontor:ShowInputWindow("recipe", "Kontor - Rezept bearbeiten",
        "Item-ID oder Umschalt-Klick-Link. Händlerzutat: \"Händler\" + Festpreis.", function(text)
            local recipe, err = textToRecipe(text)
            if not recipe then
                Kontor:Print("Rezept nicht gespeichert: " .. err)
                return false
            end
            recipe.skill = old and old.skill
            if old and key ~= (recipe.product or recipe.productName) then Kontor.db.recipes[key] = nil end
            local newKey = recipe.product or recipe.productName
            Kontor.db.recipes[newKey] = recipe
            selectedKey = newKey
            Kontor:FireChange()
            return true
        end)
    frame.editBox:SetText(old and recipeToText(old) or TEMPLATE)
end

StaticPopupDialogs["KONTOR_DELETE_RECIPE"] = {
    text = "Rezept \"%s\" löschen?", button1 = DELETE, button2 = CANCEL,
    OnAccept = function(_, data)
        Kontor.db.recipes[data.key] = nil
        selectedKey = nil
        Kontor:FireChange()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

-- Details --------------------------------------------------------------------

local function detailText(recipe)
    local lines = {}
    local status = (recipe.source == "vorlage" and "Vorlage" or recipe.source == "berufsfenster" and "aus dem Berufsfenster" or "von Hand")
    table.insert(lines, "|cffffd100" .. Kontor:RecipeName(recipe) .. "|r  ·  Ausbeute " .. (recipe.yield or 1)
        .. "  ·  " .. (recipe.profession or "Beruf unbekannt") .. (recipe.skill and (" " .. recipe.skill) or "")
        .. "  ·  " .. status)
    table.insert(lines, "")
    for _, r in ipairs(recipe.reagents or {}) do
        local price
        if r.fixedPrice then price = Kontor:FormatMoney(r.fixedPrice) .. " (Festpreis)"
        elseif r.vendor then price = "|cffff8800Festpreis fehlt|r"
        else
            local e = r.itemID and Kontor:GetPrice(r.itemID)
            price = e and e.p and (Kontor:FormatMoney(e.p) .. " (AH, " .. Kontor:FormatAge(e.t) .. ")") or "|cffff8800kein Preis|r"
        end
        table.insert(lines, r.qty .. " × " .. Kontor:ReagentName(r) .. (r.itemID and "" or " |cffff8800(ID offen)|r") .. "  ·  " .. price)
    end
    table.insert(lines, "")
    local calc = Kontor:CalcRecipe(recipe)
    if not calc.complete then
        table.insert(lines, "|cffff8800Unvollständig: " .. calc.missing .. ". Wird nicht gerechnet.|r")
    else
        table.insert(lines, "Zutatenkosten je Stück: " .. Kontor:FormatMoney(calc.costAH) .. " (AH)  ·  "
            .. Kontor:FormatMoney(calc.costOwn) .. " (eigener Einstand)")
        table.insert(lines, "Produkt netto: " .. Kontor:FormatMoney(calc.productNet) .. "  ·  Spanne je Stück: "
            .. (calc.margin < 0 and "-" or "+") .. Kontor:FormatMoney(math.abs(calc.margin)))
        table.insert(lines, string.format("Verarbeitungsfaktor: %.2f (Schwelle %.2f)", calc.factor or 0,
            Kontor.db.config.craftThreshold))
        table.insert(lines, "Empfehlung: " .. (calc.advice == "verarbeiten" and "brauen/herstellen lassen" or "roh verkaufen"))
        local craft = Kontor:CraftSignal(recipe, calc)
        if craft then table.insert(lines, "Signal: " .. Kontor.SIGNAL_COLORS.craft .. craft .. "|r") end
    end
    return table.concat(lines, "\n")
end

local function shoppingText(recipe, input)
    local text = strtrim(input or "")
    local count, budget = tonumber(text), nil
    if not count then budget = Kontor:ParseMoney(text) end
    if not count and not budget then
        return "Anzahl Produkte (z. B. 10) oder Budget (z. B. 5g) eingeben."
    end
    local list, err = Kontor:ShoppingList(recipe, count, budget)
    if not list then return "|cffff8800" .. err .. "|r" end
    local lines = { "|cffffd100Einkaufsliste für " .. list.count .. " Stück|r" }
    for _, l in ipairs(list.lines) do
        table.insert(lines, l.name .. ": " .. l.need .. " nötig, " .. l.have .. " vorhanden, |cffffffff" .. l.buy
            .. " kaufen|r (" .. Kontor:FormatMoney(l.cost) .. ")")
    end
    table.insert(lines, "Kosten " .. Kontor:FormatMoney(list.cost) .. "  ·  Erlös netto " .. Kontor:FormatMoney(list.revenue)
        .. "  ·  Gewinn " .. (list.profit < 0 and "-" or "+") .. Kontor:FormatMoney(math.abs(list.profit)))
    return table.concat(lines, "\n")
end

-- Window -----------------------------------------------------------------------

local function refresh()
    if not win or not win:IsShown() then return end
    local keys = recipeKeys()
    if not selectedKey or not Kontor.db.recipes[selectedKey] then selectedKey = keys[1] end
    for i, button in ipairs(win.list) do
        local key = keys[i]
        if key then
            local recipe = Kontor.db.recipes[key]
            local calc = Kontor:CalcRecipe(recipe)
            local mark = calc.complete and "" or "|cffff8800*|r "
            button.key = key
            button:SetText((key == selectedKey and "> " or "") .. mark .. Kontor:RecipeName(recipe))
            button:Show()
        else
            button:Hide()
        end
    end
    local recipe = selectedKey and Kontor.db.recipes[selectedKey]
    win.detail:SetText(recipe and detailText(recipe) or "Noch keine Rezepte.")
    win.shopping:SetText(recipe and win.shoppingInput:GetText() ~= "" and shoppingText(recipe, win.shoppingInput:GetText()) or "")
end

local function createWindow()
    local f = Kontor:CreateWindow("KontorRecipes", "Kontor - Rezepte", 700, 540, "recipes")
    f.list = {}
    local legend = Kontor:CreateLabel(f, "Rezepte  (|cffff8800*|r = unvollständig)", "GameFontNormal")
    legend:SetPoint("TOPLEFT", 16, -66)
    for i = 1, MAX_LIST do
        local b = Kontor:CreateButton(f, "", 190, function(btn) selectedKey = btn.key refresh() end)
        b:SetPoint("TOPLEFT", 12, -84 - (i - 1) * 24)
        b:GetFontString():SetJustifyH("LEFT")
        f.list[i] = b
    end
    local new = Kontor:CreateButton(f, "Neu", 66, function() editRecipe(nil) end)
    new:SetPoint("BOTTOMLEFT", 12, 14)
    local edit = Kontor:CreateButton(f, "Bearbeiten", 80, function() if selectedKey then editRecipe(selectedKey) end end)
    edit:SetPoint("LEFT", new, "RIGHT", 2, 0)
    local delete = Kontor:CreateButton(f, "Löschen", 66, function()
        if selectedKey then
            Kontor:ShowDialog("KONTOR_DELETE_RECIPE", Kontor:RecipeName(Kontor.db.recipes[selectedKey]), { key = selectedKey })
        end
    end)
    delete:SetPoint("LEFT", edit, "RIGHT", 2, 0)

    f.detail = Kontor:CreateLabel(f, "")
    f.detail:SetPoint("TOPLEFT", 218, -66)
    f.detail:SetWidth(466)
    f.detail:SetSpacing(3)

    local shopLabel = Kontor:CreateLabel(f, "Einkaufsliste für Anzahl oder Budget:")
    shopLabel:SetPoint("TOPLEFT", 218, -300)
    f.shoppingInput = Kontor:CreateInput(f, 90)
    f.shoppingInput:SetPoint("LEFT", shopLabel, "RIGHT", 10, 0)
    f.shoppingInput.onEnter = refresh
    local calcButton = Kontor:CreateButton(f, "Berechnen", 90, refresh)
    calcButton:SetPoint("LEFT", f.shoppingInput, "RIGHT", 6, 0)
    f.shopping = Kontor:CreateLabel(f, "")
    f.shopping:SetPoint("TOPLEFT", 218, -326)
    f.shopping:SetWidth(466)
    f.shopping:SetSpacing(2)

    local importLabel = Kontor:CreateLabel(f, "Aus dem Berufsfenster (Umschalt-Klick aufs Rezept):")
    importLabel:SetPoint("BOTTOMLEFT", 218, 44)
    local importInput = Kontor:CreateInput(f, 280)
    importInput:SetPoint("BOTTOMLEFT", 222, 16)
    local importButton = Kontor:CreateButton(f, "Rezept übernehmen", 150, function()
        local ok, msg = Kontor:ImportRecipe(importInput:GetText())
        if ok then
            Kontor:Print("Rezept übernommen: " .. msg .. ".")
            importInput:SetText("")
        else
            Kontor:Print(msg)
        end
    end)
    importButton:SetPoint("LEFT", importInput, "RIGHT", 6, 0)
    importInput.onEnter = function() importButton:Click() end

    f:HookScript("OnShow", refresh)
    Kontor:OnChange(refresh)
    return f
end

function Kontor:ShowRecipeWindow()
    if not win then win = createWindow() end
    win:Show()
    refresh()
end
