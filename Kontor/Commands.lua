-- Kontor: slash command /kontor.

local _, Kontor = ...

local HELP = {
    "/kontor - Fenster öffnen oder schließen",
    "/kontor status - Version, Client, Markt und Datenstand",
    "/kontor preis <Item-Link> - letzter Scan-Preis eines Items",
    "/kontor scaninfo - Items je Abfrage beim letzten Scan",
    "/kontor verkaufen - Verkaufsliste (nur bei offenem AH)",
    "/kontor tiefe <Item-Link> - Preistreppe im AH (nur bei offenem AH)",
    "/kontor autoauf - Fenster mit dem AH öffnen an/aus",
    "/kontor sichern - Daten jetzt speichern (lädt die Oberfläche neu)",
    "/kontor rezepte - Rezeptfenster",
    "/kontor entzaubern - Entzauber-Fenster (Verzauberer)",
    "/kontor kaufen - AH-Angebote unter Entzauberwert",
    "/kontor entzauber export - Entzauber-Tabelle und Protokoll zum Kopieren",
    "/kontor entzauber import - Starttabelle einfügen",
    "/kontor vorlage - Startkörbe anlegen (nur wenn noch keine Körbe da sind)",
    "/kontor einstellungen - Einstellungen",
    "/kontor salvager - Arcane Salvager aktiv/nicht aktiv",
    "/kontor fehler - Fehlerprotokoll zum Kopieren",
    "/kontor testfehler - erzeugt absichtlich einen Fehler (zum Testen)",
}

local function printHelp()
    Kontor:Print("Befehle:")
    for _, line in ipairs(HELP) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
    end
end

local function showPrice(arg)
    local itemID = Kontor:ParseItemID(arg)
    if not itemID then
        Kontor:Print("Bitte ein Item angeben: /kontor preis, dann Umschalt-Klick auf ein Item.")
        return
    end
    local name = arg:find("|H", 1, true) and strtrim(arg) or ("Item " .. itemID)
    local data = Kontor:GetMarketData(false)
    local entry = data and data.prices[itemID]
    if not entry then
        Kontor:Print(name .. ": kein Scan-Preis.")
        return
    end
    local text = name .. ": AH-Tiefstpreis " .. Kontor:FormatMoney(entry.p)
        .. " · " .. (entry.q or 0) .. " Stück · " .. Kontor:FormatAge(entry.t)
    if entry.listed == false then
        text = text .. " (beim letzten Scan nicht gelistet)"
    end
    Kontor:Print(text)
end

local commands = {
    [""] = function() Kontor:ToggleMainFrame() end,
    status = function()
        for i, line in ipairs(Kontor:GetStatusLines()) do
            if i == 1 then
                Kontor:Print(line)
            else
                DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
            end
        end
    end,
    fehler = function() Kontor:ShowErrorFrame() end,
    preis = showPrice,
    scaninfo = function() Kontor:PrintScanInfo() end,
    verkaufen = function()
        if not Kontor.ahOpen then
            Kontor:Print("Die Verkaufsliste geht nur bei geöffnetem Auktionshaus.")
            return
        end
        Kontor:TogglePostingList()
    end,
    tiefe = function(arg) Kontor:QueryDepth(arg) end,
    tooltip = function()
        local cfg = Kontor.db.config
        cfg.tooltipEnabled = not cfg.tooltipEnabled
        Kontor:Print("Preiszeile im Tooltip: " .. (cfg.tooltipEnabled and "an" or "aus") .. ".")
    end,
    entzauber = function(arg)
        local sub = strtrim(arg or ""):lower()
        if sub == "export" then
            Kontor:ShowDisenchantExport()
        elseif sub == "import" then
            Kontor:ShowDisenchantImport()
        else
            Kontor:Print("Entzauber-Protokoll: " .. #Kontor.db.deLog .. " Einträge. /kontor entzauber export zeigt sie.")
        end
    end,
    salvager = function() Kontor:ToggleSalvager() end,
    rezepte = function() Kontor:ShowRecipeWindow() end,
    entzaubern = function() Kontor:ShowDisenchantWindow() end,
    kaufen = function() Kontor:ShowDisenchantBuys() end,
    einstellungen = function() Kontor:ShowSettings() end,
    vorlage = function()
        if Kontor:ApplyStartBaskets() then
            Kontor:Print("Startkörbe angelegt.")
            Kontor:FireChange()
        else
            Kontor:Print("Es gibt schon Körbe. Die Vorlage überschreibt nie vorhandene Körbe.")
        end
    end,
    autoauf = function()
        local cfg = Kontor.db.config
        cfg.autoOpenWithAH = not cfg.autoOpenWithAH
        Kontor:Print("Fenster mit dem AH öffnen: " .. (cfg.autoOpenWithAH and "an" or "aus") .. ".")
    end,
    sichern = function() ReloadUI() end,
    testfehler = function()
        error("Testfehler, absichtlich ausgelöst mit /kontor testfehler")
    end,
    hilfe = printHelp,
    help = printHelp,
}

SLASH_KONTOR1 = "/kontor"
SlashCmdList["KONTOR"] = function(input)
    local cmd, rest = strtrim(input or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    local handler = commands[cmd]
    if handler then
        Kontor:SafeCall("Befehl " .. (cmd == "" and "/kontor" or cmd), handler, rest)
    else
        Kontor:Print("Unbekannter Befehl: " .. cmd)
        printHelp()
    end
end
