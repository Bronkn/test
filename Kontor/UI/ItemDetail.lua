-- Kontor: item detail window (M6 settings, M7 history, M8 ledger, M10 market depth;
-- Nachtrag 1 sections 2, 3, 5; Nachtrag 3, 3).

local _, Kontor = ...

local detail -- the window
local current -- { basketId, itemID }

-- Ledger dialogs: "Menge Preis", e.g. "20 1g 50s" -------------------------------

local function parseQtyPrice(text)
    local qty, rest = strtrim(text or ""):match("^(%-?%d+)%s*(.*)$")
    return tonumber(qty), Kontor:ParseMoney(rest)
end

local function ledgerDialog(name, prompt, entryType)
    StaticPopupDialogs[name] = {
        text = prompt, button1 = OKAY, button2 = CANCEL, hasEditBox = true,
        OnShow = function(self)
            local box = (self.GetEditBox and self:GetEditBox()) or self.editBox
            if box then box:SetText("") end
        end,
        OnAccept = function(self, data)
            local box = (self.GetEditBox and self:GetEditBox()) or self.editBox
            Kontor:SafeCall("Journal", function()
                local qty, price = parseQtyPrice(box and box:GetText())
                if not qty or (qty == 0 and entryType ~= "adjust") then
                    Kontor:Print("Bitte Menge (und Preis je Stück) eingeben, z. B. \"20 1g 50s\".")
                    return
                end
                if entryType == "adjust" then
                    -- "Bestand korrigieren": the number is the counted stock
                    local stock = Kontor:GetPosition(data.itemID)
                    Kontor:AddLedgerEntry(data.itemID, "adjust", qty - stock, 0, "manuell")
                else
                    if not price then
                        Kontor:Print("Bitte auch den Preis je Stück angeben, z. B. \"20 1g 50s\".")
                        return
                    end
                    Kontor:AddLedgerEntry(data.itemID, entryType, qty, price, "manuell")
                end
            end)
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
ledgerDialog("KONTOR_BOOK_BUY", "Kauf buchen: %s\n\nMenge und Preis je Stück, z. B. \"20 1g 50s\"", "buy")
ledgerDialog("KONTOR_BOOK_SELL", "Verkauf buchen: %s\n\nMenge und Erlös je Stück (nach Gebühr), z. B. \"10 4g\"", "sell")
ledgerDialog("KONTOR_BOOK_ADJUST", "Bestand korrigieren: %s\n\nTatsächlicher Bestand (Stück):", "adjust")

-- Fields ---------------------------------------------------------------------

local FIELDS = {
    { key = "buyLimit", label = "Kauflimit je Stück", money = true },
    { key = "target", label = "Zielpreis je Stück", money = true },
    { key = "targetQty", label = "Zielmenge" },
    { key = "fixedPrice", label = "Festpreis NPC", money = true },
    { key = "stockLimit", label = "Lagerlimit (Stück)" },
}

local PHASE_CHOICES = { false, "beobachten", "sammeln", "halten", "abstossen" }

local function getItem()
    local basket = current and Kontor:GetBasket(current.basketId)
    return basket, basket and basket.items[current.itemID]
end

local function save()
    local basket, item = getItem()
    if not item then return end
    for _, f in ipairs(FIELDS) do
        local text = detail.inputs[f.key]:GetText()
        local value
        if f.money then value = Kontor:ParseMoney(text) else value = tonumber(strtrim(text)) end
        item[f.key] = value
    end
    -- The target must not exceed the NPC fixed price (Nachtrag 1, 3).
    if item.target and item.fixedPrice and item.target > item.fixedPrice then
        item.target = item.fixedPrice
        Kontor:Print("Zielpreis über dem Festpreis: auf " .. Kontor:FormatMoney(item.fixedPrice) .. " begrenzt.")
    end
    local usage = strtrim(detail.usage:GetText())
    item.usage = usage ~= "" and usage:sub(1, 200) or nil
    Kontor:FireChange()
    Kontor:Print("Gespeichert: " .. Kontor:ItemLabel(current.itemID) .. ".")
end

-- Text blocks ------------------------------------------------------------------

local function pct(v) return v and Kontor:FormatChange(v) or "-" end

local function historyText(itemID)
    local lines = {}
    local s7, s30 = Kontor:HistoryStats(itemID, 7), Kontor:HistoryStats(itemID, 30)
    local function stat(s)
        if s.n == 0 then return "keine Daten" end
        return string.format("Preis %s-%s, Mittel %s · Menge %d-%d, Mittel %d (%d Punkte)",
            Kontor:FormatMoney(s.minP), Kontor:FormatMoney(s.maxP), Kontor:FormatMoney(s.avgP),
            s.minQ or 0, s.maxQ or 0, math.floor((s.avgQ or 0) + 0.5), s.n)
    end
    table.insert(lines, "|cffffd1007 Tage:|r " .. stat(s7))
    table.insert(lines, "|cffffd10030 Tage:|r " .. stat(s30))
    local t = Kontor:GetTrend(itemID)
    -- Reading aid (Pflichtenheft 4.5): quantity up and price down = collecting
    -- phase; quantity down and price up = time to sell.
    local reading = ""
    if t.qWeek and t.pWeek then
        if t.qWeek > 0.05 and t.pWeek < -0.05 then reading = " → Menge steigt, Preis fällt: Sammelphase"
        elseif t.qWeek < -0.05 and t.pWeek > 0.05 then reading = " → Menge schrumpft, Preis steigt: Abstoßen" end
    end
    table.insert(lines, "|cffffd100Trend 7 Tage:|r Preis " .. pct(t.pWeek) .. ", Menge " .. pct(t.qWeek) .. reading)
    table.insert(lines, "")
    table.insert(lines, "|cffffd100Letzte Scans (Zeit · Preis · Menge):|r")
    local points = Kontor:GetHistory(itemID)
    for i = #points, math.max(1, #points - 19), -1 do
        local p = points[i]
        table.insert(lines, Kontor:FormatDateTime(p.t) .. "  ·  " .. Kontor:FormatMoney(p.p) .. "  ·  " .. p.q)
    end
    if #points == 0 then table.insert(lines, "noch keine Verlaufspunkte (entstehen bei jedem vollständigen Scan)") end
    return table.concat(lines, "\n")
end

local function positionText(basket, item, itemID)
    local stock, avg = Kontor:GetPosition(itemID)
    local char = Kontor:GetCharacterCount(itemID)
    local lines = {}
    -- With Syndicator the comparison uses all characters, otherwise this one.
    local account = Kontor:GetAccountCount(itemID)
    local stockLine = "Bestand (Journal): " .. stock .. "  ·  auf diesem Charakter: " .. char
    if (account or char) ~= stock then stockLine = stockLine .. " |cffff8800(weicht ab)|r" end
    table.insert(lines, stockLine)
    local accountText = Kontor:AccountCountText(itemID)
    if accountText then table.insert(lines, accountText) end
    if avg then
        table.insert(lines, "Einstand " .. Kontor:FormatMoney(avg) .. "  ·  Break-even " .. Kontor:FormatMoney(Kontor:BreakEven(avg)))
    end
    local entry = Kontor:GetPrice(itemID)
    local vendor = select(11, C_Item.GetItemInfo(itemID))
    -- Range floor - current - fixed price (Nachtrag 1, 3)
    table.insert(lines, "Händler " .. Kontor:FormatMoney(vendor) .. "  ·  aktuell " .. Kontor:FormatMoney(entry and entry.p)
        .. "  ·  Festpreis " .. (item.fixedPrice and Kontor:FormatMoney(item.fixedPrice) or "-"))
    local sig = Kontor:GetItemSignal(basket, item, itemID)
    table.insert(lines, "Signal: " .. (sig.kind and Kontor:SignalText(sig) or "keins")
        .. (sig.hint and ("  |cffff8800" .. sig.hint .. "|r") or ""))
    local uses = Kontor:RecipesUsing(itemID)
    if #uses > 0 then
        local names = {}
        for _, u in ipairs(uses) do
            table.insert(names, Kontor:RecipeName(u.recipe) .. (u.via and (" (über " .. Kontor:RecipeName(u.via) .. ")") or ""))
        end
        table.insert(lines, "Verwendet in: " .. table.concat(names, ", "))
    end
    table.insert(lines, "|cff888888Einlage zählt nicht zum Einstand; sie geht verloren, wenn eine Auktion ausläuft oder abgebrochen wird.|r")
    return table.concat(lines, "\n")
end

-- Window -----------------------------------------------------------------------

local function refresh()
    if not detail or not detail:IsShown() then return end
    local basket, item = getItem()
    if not item then detail:Hide() return end
    local itemID = current.itemID
    local name = C_Item.GetItemInfo(itemID) or ("Item " .. itemID)
    if detail.SetTitle then detail:SetTitle("Kontor - " .. name) end
    detail.basketLine:SetText("Korb: " .. basket.name)
    for _, f in ipairs(FIELDS) do
        local v = item[f.key]
        if not detail.inputs[f.key]:HasFocus() then
            detail.inputs[f.key]:SetText(f.money and Kontor:MoneyInputText(v) or (v and tostring(v) or ""))
        end
    end
    if not detail.usage:HasFocus() then detail.usage:SetText(item.usage or "") end
    detail.phaseButton:SetText("Phase: " .. (item.phase and Kontor.PHASE_NAMES[item.phase]
        or ("wie Korb (" .. Kontor.PHASE_NAMES[basket.phase] .. ")")))
    detail.position:SetText(positionText(basket, item, itemID))
    detail.history:SetText(historyText(itemID))
    detail.depthButton:SetEnabled(Kontor.ahOpen and true or false)
end

local function createDetail()
    local f = Kontor:CreateWindow("KontorItemDetail", "Kontor - Item", 640, 600, "detail")
    f.inputs = {}
    f.basketLine = Kontor:CreateLabel(f, "", "GameFontNormal")
    f.basketLine:SetPoint("TOPLEFT", 64, -34)

    for i, field in ipairs(FIELDS) do
        local label = Kontor:CreateLabel(f, field.label .. ":")
        label:SetPoint("TOPLEFT", 20, -70 - (i - 1) * 24)
        local input = Kontor:CreateInput(f, 110)
        input:SetPoint("TOPLEFT", 160, -66 - (i - 1) * 24)
        input.onEnter = save
        f.inputs[field.key] = input
    end
    local hint = Kontor:CreateLabel(f, "Preise z. B. \"1g 20s\" oder \"35s\".  Leer = nicht gesetzt.", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 290, -70)

    f.phaseButton = Kontor:CreateButton(f, "Phase", 220, function()
        local _, item = getItem()
        if not item then return end
        for i, p in ipairs(PHASE_CHOICES) do
            if (item.phase or false) == p then
                item.phase = PHASE_CHOICES[i % #PHASE_CHOICES + 1] or nil
                break
            end
        end
        Kontor:FireChange()
    end)
    f.phaseButton:SetPoint("TOPLEFT", 290, -90)

    local usageLabel = Kontor:CreateLabel(f, "Verwendung:")
    usageLabel:SetPoint("TOPLEFT", 20, -192)
    f.usage = Kontor:CreateInput(f, 450)
    f.usage:SetPoint("TOPLEFT", 160, -188)
    f.usage:SetMaxLetters(200)
    f.usage.onEnter = save

    local saveButton = Kontor:CreateButton(f, "Speichern", 100, save)
    saveButton:SetPoint("TOPLEFT", 290, -118)

    f.position = Kontor:CreateLabel(f, "")
    f.position:SetPoint("TOPLEFT", 20, -222)
    f.position:SetWidth(600)
    f.position:SetSpacing(3)

    local buy = Kontor:CreateButton(f, "Kauf buchen", 110, function()
        Kontor:ShowDialog("KONTOR_BOOK_BUY", Kontor:ItemLabel(current.itemID), { itemID = current.itemID })
    end)
    buy:SetPoint("TOPLEFT", 20, -316)
    local sell = Kontor:CreateButton(f, "Verkauf buchen", 120, function()
        Kontor:ShowDialog("KONTOR_BOOK_SELL", Kontor:ItemLabel(current.itemID), { itemID = current.itemID })
    end)
    sell:SetPoint("LEFT", buy, "RIGHT", 4, 0)
    local adjust = Kontor:CreateButton(f, "Bestand korrigieren", 140, function()
        Kontor:ShowDialog("KONTOR_BOOK_ADJUST", Kontor:ItemLabel(current.itemID), { itemID = current.itemID })
    end)
    adjust:SetPoint("LEFT", sell, "RIGHT", 4, 0)
    f.depthButton = Kontor:CreateButton(f, "Markttiefe", 110, function()
        Kontor:QueryDepthForDetail(current.basketId, current.itemID)
    end)
    f.depthButton:SetPoint("LEFT", adjust, "RIGHT", 4, 0)

    f.depthText = Kontor:CreateLabel(f, "")
    f.depthText:SetPoint("TOPLEFT", 20, -344)
    f.depthText:SetWidth(600)

    f.history = Kontor:CreateLabel(f, "")
    f.history:SetPoint("TOPLEFT", 20, -384)
    f.history:SetWidth(600)
    f.history:SetJustifyV("TOP")
    f.history:SetHeight(200)

    f:HookScript("OnShow", refresh)
    Kontor:OnChange(refresh)
    return f
end

function Kontor:ShowItemDetail(basketId, itemID)
    if not detail then detail = createDetail() end
    current = { basketId = basketId, itemID = itemID }
    detail.depthText:SetText("")
    detail:Show()
    refresh()
end

-- Market depth sentence by phase (Pflichtenheft 4.8).
function Kontor:QueryDepthForDetail(basketId, itemID)
    if not self.ahOpen then
        self:Print("Markttiefe geht nur bei geöffnetem Auktionshaus.")
        return
    end
    detail.depthText:SetText("Markttiefe wird abgefragt ...")
    self:QueryDepth(tostring(itemID), function(levels)
        if not detail or not current or current.itemID ~= itemID then return end
        local basket = self:GetBasket(basketId)
        local item = basket and basket.items[itemID]
        if not item then return end
        local phase = self:GetItemPhase(basket, item)
        local lines = {}
        if phase == "sammeln" and item.buyLimit then
            local n, cost = 0, 0
            for _, l in ipairs(levels) do
                if l.price <= item.buyLimit then n = n + l.qty cost = cost + l.qty * l.price end
            end
            table.insert(lines, "Bis zum Kauflimit sind " .. n .. " Stück für zusammen " .. self:FormatMoney(cost) .. " zu haben.")
        elseif phase == "abstossen" or phase == "halten" then
            local target = self:EffectiveTarget(item)
            if target then
                local n = 0
                for _, l in ipairs(levels) do
                    if self:NetPrice(l.price) < target then n = n + l.qty end
                end
                table.insert(lines, "Unter deinem Zielpreis liegen " .. n .. " Stück vor dir.")
            end
        end
        local want, got, cost = self.db.config.depthUnits, 0, 0
        for _, l in ipairs(levels) do
            local take = math.min(l.qty, want - got)
            got, cost = got + take, cost + take * l.price
            if got >= want then break end
        end
        if got > 0 then
            table.insert(lines, "Preis für die ersten " .. got .. " Stück: im Schnitt " .. self:FormatMoney(cost / got) .. " je Stück.")
        end
        if #lines == 0 then table.insert(lines, "Keine Angebote.") end
        detail.depthText:SetText(table.concat(lines, "\n"))
    end)
end
