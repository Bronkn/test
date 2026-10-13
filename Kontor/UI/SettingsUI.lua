-- Kontor: settings window (/kontor einstellungen).

local _, Kontor = ...

-- kind: "pct" shows a fraction as percent, "num" a number, "text" a name.
local FIELDS = {
    { key = "ahFee", label = "AH-Gebühr (%)", kind = "pct" },
    { key = "maxPriceAgeHours", label = "Preise gelten höchstens (Std.)", kind = "num" },
    { key = "cleanupMaxQuality", label = "Aufräumen bis Qualität (1 weiß, 2 grün, 3 blau)", kind = "num" },
    { key = "cleanupMargin", label = "Aufräumen: Sicherheitsaufschlag (%)", kind = "pct" },
    { key = "minMargin", label = "Verkaufssignal ohne Ziel: Mindestmarge (%)", kind = "pct" },
    { key = "fixedPriceFactor", label = "Ziel ohne Zielpreis: Festpreis × (%)", kind = "pct" },
    { key = "depthUnits", label = "Markttiefe: Preis für die ersten ... Stück", kind = "num" },
    { key = "craftThreshold", label = "\"Verarbeiten lohnt\" ab Faktor", kind = "num" },
    { key = "deMinAdvantage", label = "Entzaubern nur bei Vorsprung von (%)", kind = "pct" },
    { key = "deMinSamples", label = "Entzauberwert sicher ab n =", kind = "num" },
    { key = "deBuyDiscount", label = "Kaufen zum Entzaubern: Abschlag (%)", kind = "pct" },
    { key = "deMaxQuality", label = "Entzaubern bis Qualität (3 blau, 4 episch)", kind = "num" },
    { key = "bankCharName", label = "Bankchar für Entzauberware (leer = Verzauberer)", kind = "text" },
}

local CHECKS = {
    { key = "tooltipEnabled", label = "Preiszeile im Tooltip" },
    { key = "deTooltip", label = "Entzauber-Zeile im Tooltip" },
    { key = "usageTooltip", label = "Verwendungs-Notiz im Tooltip" },
    { key = "autoOpenWithAH", label = "Kontor-Fenster mit dem AH öffnen" },
}

local win

local function load()
    local cfg = Kontor.db.config
    for _, f in ipairs(FIELDS) do
        local v = cfg[f.key]
        local text = ""
        if f.kind == "pct" and v then text = tostring(math.floor(v * 1000 + 0.5) / 10)
        elseif v ~= nil then text = tostring(v) end
        win.inputs[f.key]:SetText(text)
    end
    for _, c in ipairs(CHECKS) do win.checks[c.key]:SetChecked(cfg[c.key] and true or false) end
    win.enchanter:SetText("Erkannter Verzauberer: " .. (cfg.enchanterName or "noch keiner"))
end

local function save()
    local cfg = Kontor.db.config
    for _, f in ipairs(FIELDS) do
        local text = strtrim(win.inputs[f.key]:GetText()):gsub(",", ".")
        if f.kind == "text" then
            cfg[f.key] = text ~= "" and text or nil
        else
            local n = tonumber(text)
            if n then cfg[f.key] = f.kind == "pct" and n / 100 or n end
        end
    end
    for _, c in ipairs(CHECKS) do cfg[c.key] = win.checks[c.key]:GetChecked() and true or false end
    Kontor:FireChange()
    Kontor:Print("Einstellungen gespeichert.")
    load()
end

function Kontor:ShowSettings()
    if not win then
        win = self:CreateWindow("KontorSettings", "Kontor - Einstellungen", 560, 560, "settings")
        win.inputs, win.checks = {}, {}
        for i, f in ipairs(FIELDS) do
            local label = self:CreateLabel(win, f.label)
            label:SetPoint("TOPLEFT", 20, -70 - (i - 1) * 26)
            local input = self:CreateInput(win, f.kind == "text" and 140 or 70)
            input:SetPoint("TOPRIGHT", -24, -66 - (i - 1) * 26)
            win.inputs[f.key] = input
        end
        local y = -70 - #FIELDS * 26
        for i, c in ipairs(CHECKS) do
            local check = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", 16 + ((i - 1) % 2) * 260, y - math.floor((i - 1) / 2) * 26)
            local label = self:CreateLabel(win, c.label)
            label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            win.checks[c.key] = check
        end
        win.enchanter = self:CreateLabel(win, "", "GameFontDisableSmall")
        win.enchanter:SetPoint("BOTTOMLEFT", 20, 44)
        local saveButton = self:CreateButton(win, "Speichern", 120, save)
        saveButton:SetPoint("BOTTOMRIGHT", -16, 14)
        win:HookScript("OnShow", load)
    end
    win:Show()
    load()
end
