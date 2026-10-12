-- Kontor: slash command /kontor.

local _, Kontor = ...

local HELP = {
    "/kontor - Fenster öffnen oder schließen",
    "/kontor status - Version, Client, Markt und Datenstand",
    "/kontor fehler - Fehlerprotokoll zum Kopieren",
    "/kontor testfehler - erzeugt absichtlich einen Fehler (zum Testen)",
}

local function printHelp()
    Kontor:Print("Befehle:")
    for _, line in ipairs(HELP) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. line)
    end
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
    testfehler = function()
        error("Testfehler, absichtlich ausgelöst mit /kontor testfehler")
    end,
    hilfe = printHelp,
    help = printHelp,
}

SLASH_KONTOR1 = "/kontor"
SlashCmdList["KONTOR"] = function(input)
    local cmd = strtrim(input or ""):match("^(%S*)"):lower()
    local handler = commands[cmd]
    if handler then
        Kontor:SafeCall("Befehl " .. (cmd == "" and "/kontor" or cmd), handler)
    else
        Kontor:Print("Unbekannter Befehl: " .. cmd)
        printHelp()
    end
end
