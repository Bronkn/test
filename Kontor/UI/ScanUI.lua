-- Kontor: scan buttons (main window and AH window), progress display,
-- summary with "Jetzt sichern" (Pflichtenheft 4.1).

local _, Kontor = ...

local widgets = {} -- { button = Button, label = FontString }

function Kontor:UpdateScanWidgets()
    local running = self.Scan:IsRunning()
    local text
    if running then
        local count, elapsed = self.Scan:GetProgress()
        text = "Scan läuft: " .. count .. " Items · " .. self:FormatDuration(elapsed)
    elseif not self.ahOpen then
        text = "Scannen geht nur bei geöffnetem Auktionshaus."
    else
        local data = self:GetMarketData(false)
        local last = data and data.lastScan
        text = last and ("Letzter Scan: " .. self:FormatAge(last.t) .. (last.complete and "" or " (unvollständig)"))
            or "Noch kein Scan in diesem Markt."
    end
    for _, w in ipairs(widgets) do
        w.button:SetText(running and "Abbrechen" or "Scannen")
        w.button:SetEnabled(self.ahOpen and true or false)
        w.label:SetText(text)
    end
end

-- Adds a scan button plus status line to a frame.
function Kontor:CreateScanWidget(parent, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(110, 22)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetScript("OnClick", function()
        Kontor:SafeCall("Scan", function()
            if Kontor.Scan:IsRunning() then
                Kontor.Scan:Abort("vom Nutzer abgebrochen")
            else
                Kontor.Scan:Start()
            end
        end)
    end)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", button, "RIGHT", 8, 0)
    label:SetJustifyH("LEFT")

    table.insert(widgets, { button = button, label = label })
    self:UpdateScanWidgets()
    return button
end

-- Progress ticker while a scan runs
local ticker = CreateFrame("Frame")
ticker:Hide()
local sinceUpdate = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    sinceUpdate = sinceUpdate + elapsed
    if sinceUpdate >= 0.25 then
        sinceUpdate = 0
        Kontor:SafeCall("Scan-Anzeige", Kontor.UpdateScanWidgets, Kontor)
    end
end)

local ahWidgetCreated = false

function Kontor:OnAuctionHouseShown()
    if not ahWidgetCreated and AuctionHouseFrame then
        ahWidgetCreated = true
        -- Sits just above the AH window's top edge, so it covers nothing.
        local button = self:CreateScanWidget(AuctionHouseFrame, "BOTTOMLEFT", AuctionHouseFrame, "TOPLEFT", 60, 2)
        button:SetText("Scannen")
        local tag = AuctionHouseFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tag:SetPoint("RIGHT", button, "LEFT", -4, 0)
        tag:SetText("Kontor")
    end
    self:UpdateScanWidgets()
end

function Kontor:OnScanStarted()
    self:Print("Scan gestartet. Bitte das Auktionshaus offen lassen und nicht selbst suchen.")
    ticker:Show()
    self:UpdateScanWidgets()
end

StaticPopupDialogs["KONTOR_SCAN_DONE"] = {
    text = "%s",
    button1 = "Jetzt sichern",
    button2 = "Später",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function Kontor:OnScanFinished(complete, itemCount, duration, reason)
    ticker:Hide()
    self:UpdateScanWidgets()
    local durationText = self:FormatDuration(duration)

    if complete then
        self:Print("Scan fertig: " .. itemCount .. " Items in " .. durationText .. ".")
        StaticPopup_Show("KONTOR_SCAN_DONE",
            "Kontor: Scan fertig.\n\n" .. itemCount .. " Items in " .. durationText .. ".\n\n"
            .. "WoW speichert die Daten erst beim Ausloggen oder Neuladen.\n"
            .. "\"Jetzt sichern\" lädt die Oberfläche neu und speichert sofort.")
    else
        self:Print("Scan abgebrochen (" .. (reason or "unbekannt") .. "). "
            .. itemCount .. " Items aktualisiert, der Scan gilt als unvollständig. "
            .. "/reload sichert die bisher gelesenen Preise.")
    end
end
