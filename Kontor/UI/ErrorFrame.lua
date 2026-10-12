-- Kontor: error log window (/kontor fehler). Shows the log as selectable
-- text so it can be copied with Ctrl+C (Pflichtenheft 6.4).

local _, Kontor = ...

function Kontor:GetStatusLines()
    local version, build, _, interface = GetBuildInfo()
    local db = self.db
    local market = self:GetMarketKey()
    local marketData = market and db.markets[market]
    local lastScan = marketData and marketData.lastScan

    local scanText = "noch keiner"
    if lastScan and lastScan.t then
        scanText = self:FormatDateTime(lastScan.t)
        if not lastScan.complete then
            scanText = scanText .. " (unvollständig)"
        end
    end

    return {
        "Kontor " .. self:GetVersion(),
        "Client: " .. tostring(version) .. " (Build " .. tostring(build) .. "), Interface " .. tostring(interface),
        "Markt: " .. (market or "unbekannt"),
        "Letzter Scan: " .. scanText,
        "Preise: " .. self:CountKeys(marketData and marketData.prices),
        "Körbe: " .. #db.baskets,
        "Entzauber-Protokoll: " .. #db.deLog .. " Einträge, " .. #db.deFailures .. " Fehlschläge",
        "Fehler im Protokoll: " .. #db.errorLog,
    }
end

local function buildLogText()
    local lines = Kontor:GetStatusLines()
    table.insert(lines, "")

    local log = Kontor.db.errorLog
    if #log == 0 then
        table.insert(lines, "Keine Fehler protokolliert.")
    else
        for i = #log, 1, -1 do -- newest first
            local e = log[i]
            table.insert(lines, "[" .. Kontor:FormatDateTime(e.t) .. "] " .. e.module .. ": " .. e.msg)
            table.insert(lines, "")
        end
    end
    return table.concat(lines, "\n")
end

StaticPopupDialogs["KONTOR_CLEAR_ERRORS"] = {
    text = "Kontor: Fehlerprotokoll wirklich leeren?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        wipe(Kontor.db.errorLog)
        Kontor:RefreshTextWindow("errors")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function Kontor:ShowErrorFrame()
    self:ShowTextWindow("errors", "Kontor - Fehlerprotokoll", buildLogText, "Protokoll leeren", function()
        StaticPopup_Show("KONTOR_CLEAR_ERRORS")
    end)
end

-- Keep an open window current when new errors arrive.
function Kontor:OnErrorLogged()
    pcall(self.RefreshTextWindow, self, "errors")
end
