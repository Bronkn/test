-- Kontor: error log window (/kontor fehler). Shows the log as selectable
-- text so it can be copied with Ctrl+C (Pflichtenheft 6.4).

local _, Kontor = ...

local errorFrame

function Kontor:GetStatusLines()
    local _, build, _, interface = GetBuildInfo()
    local version = GetBuildInfo()
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

local function refresh()
    if errorFrame and errorFrame:IsShown() then
        errorFrame.editBox:SetText(buildLogText())
    end
end

StaticPopupDialogs["KONTOR_CLEAR_ERRORS"] = {
    text = "Kontor: Fehlerprotokoll wirklich leeren?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        wipe(Kontor.db.errorLog)
        refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function createErrorFrame()
    local frame = Kontor:CreateWindow("KontorErrorFrame", "Kontor - Fehlerprotokoll", 640, 420, "errors")

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -64)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(580)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    -- Read-only: any typing restores the log text.
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(buildLogText()) end
    end)
    scroll:SetScrollChild(editBox)
    frame.editBox = editBox

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 64, -40)
    hint:SetText('"Alles markieren" klicken, dann Strg+C zum Kopieren.')

    local selectAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAll:SetSize(140, 22)
    selectAll:SetPoint("BOTTOMLEFT", 16, 14)
    selectAll:SetText("Alles markieren")
    selectAll:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)

    local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clear:SetSize(140, 22)
    clear:SetPoint("BOTTOMRIGHT", -16, 14)
    clear:SetText("Protokoll leeren")
    clear:SetScript("OnClick", function()
        StaticPopup_Show("KONTOR_CLEAR_ERRORS")
    end)

    frame:SetScript("OnShow", refresh)
    return frame
end

function Kontor:ShowErrorFrame()
    if not errorFrame then
        errorFrame = createErrorFrame()
    end
    errorFrame:Show()
    refresh()
end

-- Keep an open window current when new errors arrive.
function Kontor:OnErrorLogged()
    pcall(refresh)
end
