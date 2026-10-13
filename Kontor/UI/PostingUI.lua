-- Kontor: "Verkaufsliste" at the AH (wish of the user 13.10.2026).
-- Lists bag items worth more in the AH than at the vendor. A click puts the
-- stack into Blizzard's sell frame; posting stays with the user.

local _, Kontor = ...

local ROW_HEIGHT = 24
local MAX_ROWS = 14

local listFrame
local buttons = {} -- "Verkaufsliste" buttons (AH window, main window)

StaticPopupDialogs["KONTOR_NEVER_POST"] = {
    text = "Kontor: %s nicht mehr in der Verkaufsliste anbieten?",
    button1 = "Nicht anbieten",
    button2 = CANCEL,
    OnAccept = function(_, itemID)
        Kontor.db.postExclusions[itemID] = true
        Kontor:SafeCall("Verkaufsliste", Kontor.RefreshPostingList, Kontor)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local COLUMNS = {
    { key = "name", title = "Item", x = 30, width = 190, justify = "LEFT" },
    { key = "count", title = "Menge", x = 224, width = 44, justify = "RIGHT" },
    { key = "unit", title = "AH je Stück", x = 274, width = 80, justify = "RIGHT" },
    { key = "net", title = "Erlös netto", x = 360, width = 84, justify = "RIGHT" },
    { key = "vendor", title = "Händler", x = 450, width = 70, justify = "RIGHT" },
    { key = "age", title = "Preis", x = 526, width = 70, justify = "RIGHT" },
}

local function createRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(600, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 12, -84 - (index - 1) * ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", 6, 0)

    row.cells = {}
    for _, col in ipairs(COLUMNS) do
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", col.x, 0)
        fs:SetWidth(col.width)
        fs:SetJustifyH(col.justify)
        fs:SetWordWrap(false)
        row.cells[col.key] = fs
    end

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)

    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints()
    row.selected:SetColorTexture(0.2, 0.6, 1, 0.18)
    row.selected:Hide()

    row:SetScript("OnEnter", function(self)
        if not self.data then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(self.data.bag, self.data.slot)
        GameTooltip:AddLine("Linksklick: ins Verkaufsfenster legen", 0.6, 0.6, 0.6)
        GameTooltip:AddLine("Rechtsklick: nicht mehr anbieten", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self, button)
        if not self.data then return end
        if button == "RightButton" then
            local dialog = StaticPopup_Show("KONTOR_NEVER_POST", self.data.link or ("Item " .. self.data.itemID))
            if dialog then dialog.data = self.data.itemID end
            return
        end
        Kontor:SafeCall("Verkaufsliste", function()
            if Kontor:PrepareListing(self.data) then
                for _, other in ipairs(listFrame.rows) do other.selected:Hide() end
                self.selected:Show()
            else
                Kontor:RefreshPostingList()
            end
        end)
    end)
    return row
end

local function createListFrame()
    local frame = Kontor:CreateWindow("KontorPostingFrame", "Kontor - Verkaufsliste", 630, 520, "posting")

    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 64, -32)
    intro:SetWidth(540)
    intro:SetJustifyH("LEFT")
    intro:SetText("Diese Items bringen im AH mehr als beim Händler. Klick legt das Item ins Verkaufsfenster; "
        .. 'Preis prüfen und dort selbst auf "Auktion erstellen" klicken.')

    for _, col in ipairs(COLUMNS) do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", 12 + col.x, -66)
        fs:SetWidth(col.width)
        fs:SetJustifyH(col.justify)
        fs:SetText(col.title)
    end

    frame.rows = {}
    for i = 1, MAX_ROWS do
        frame.rows[i] = createRow(frame, i)
    end

    frame.more = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.more:SetPoint("BOTTOMLEFT", 16, 40)
    frame.more:SetJustifyH("LEFT")
    frame.more:SetWidth(600)

    local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("BOTTOMLEFT", 16, 18)
    note:SetWidth(600)
    note:SetJustifyH("LEFT")
    note:SetText("Hinweis: Die Einlage geht verloren, wenn die Auktion ausläuft oder abgebrochen wird.")

    return frame
end

function Kontor:RefreshPostingList()
    if not listFrame or not listFrame:IsShown() then return end
    local list, skipped = self:FindPostingCandidates()
    for i, row in ipairs(listFrame.rows) do
        local c = list[i]
        row.data = c
        row.selected:Hide()
        if c then
            row.icon:SetTexture(c.icon)
            row.cells.name:SetText(c.link or ("Item " .. c.itemID))
            row.cells.count:SetText(c.count)
            row.cells.unit:SetText(self:FormatMoney(c.unitPrice))
            row.cells.net:SetText(self:FormatMoney(c.ahNetTotal))
            row.cells.vendor:SetText(self:FormatMoney(c.vendorTotal))
            row.cells.age:SetText(self:FormatAge(c.priceTime))
            row:Show()
        else
            row:Hide()
        end
    end
    local reasons = {}
    for reason, n in pairs(skipped) do
        table.insert(reasons, n .. " " .. reason)
    end
    table.sort(reasons)
    local text = #list > MAX_ROWS and ("Weitere " .. (#list - MAX_ROWS) .. " Stapel rücken nach. ") or ""
    if #list == 0 then text = "Nichts gefunden. " end
    if #reasons > 0 then
        text = text .. "Nicht in der Liste: " .. table.concat(reasons, ", ") .. "."
    end
    listFrame.more:SetText(text)
end

function Kontor:TogglePostingList()
    if not listFrame then listFrame = createListFrame() end
    if listFrame:IsShown() then
        listFrame:Hide()
    else
        listFrame:Show()
        self:RefreshPostingList()
    end
end

local function updateButtons()
    for _, b in ipairs(buttons) do
        b:SetEnabled(Kontor.ahOpen and true or false)
    end
end

-- Adds a "Verkaufsliste" button to a frame.
function Kontor:CreatePostingButton(parent, point, relativeTo, relativePoint, x, y)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(120, 22)
    button:SetPoint(point, relativeTo, relativePoint, x, y)
    button:SetText("Verkaufsliste")
    button:SetScript("OnClick", function() Kontor:SafeCall("Verkaufsliste", Kontor.TogglePostingList, Kontor) end)
    table.insert(buttons, button)
    updateButtons()
    return button
end

local ahButtonCreated = false

Kontor:RegisterEvent("AUCTION_HOUSE_SHOW", "Verkaufsliste", function()
    if not ahButtonCreated and AuctionHouseFrame then
        ahButtonCreated = true
        Kontor:CreatePostingButton(AuctionHouseFrame, "BOTTOMRIGHT", AuctionHouseFrame, "TOPRIGHT", -30, 2)
    end
    updateButtons()
end)

Kontor:RegisterEvent("AUCTION_HOUSE_CLOSED", "Verkaufsliste", function()
    if listFrame then listFrame:Hide() end
    updateButtons()
end)

local refreshPending = false
Kontor:RegisterEvent("BAG_UPDATE_DELAYED", "Verkaufsliste", function()
    if not listFrame or not listFrame:IsShown() or refreshPending then return end
    refreshPending = true
    C_Timer.After(0.3, function()
        refreshPending = false
        Kontor:SafeCall("Verkaufsliste", Kontor.RefreshPostingList, Kontor)
    end)
end)
