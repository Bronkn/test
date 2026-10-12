-- Kontor: "Aufräumen" button at the vendor and the preview list
-- (Pflichtenheft 4.3). Nothing is sold without the preview and a click on
-- "Verkaufen".

local _, Kontor = ...

local ROW_HEIGHT = 24
local MAX_ROWS = Kontor.CLEANUP_MAX_STACKS

local merchantButton, preview
local candidates = {}

-- Merchant button ----------------------------------------------------------

local function totalVendor(list)
    local sum = 0
    for _, c in ipairs(list) do sum = sum + c.vendorTotal end
    return sum
end

function Kontor:UpdateCleanupButton()
    if not merchantButton then return end
    candidates = self:FindCleanupCandidates()
    if #candidates == 0 then
        merchantButton:SetText("Kontor: Aufräumen (nichts zu tun)")
        merchantButton:SetEnabled(false)
    else
        merchantButton:SetText("Kontor: Aufräumen (" .. #candidates .. " Items, "
            .. self:FormatMoney(totalVendor(candidates)) .. ")")
        merchantButton:SetEnabled(true)
    end
end

local function createMerchantButton()
    local button = CreateFrame("Button", nil, MerchantFrame, "UIPanelButtonTemplate")
    button:SetSize(280, 22)
    -- Just above the vendor window, so it covers nothing.
    button:SetPoint("BOTTOMLEFT", MerchantFrame, "TOPLEFT", 60, 2)
    button:SetScript("OnClick", function()
        Kontor:SafeCall("Aufräumen", Kontor.ShowCleanupPreview, Kontor)
    end)
    return button
end

-- Preview ------------------------------------------------------------------

StaticPopupDialogs["KONTOR_NEVER_SELL"] = {
    text = "Kontor: %s nie verkaufen?\n\nDas Item erscheint dann nicht mehr beim Aufräumen.",
    button1 = "Nie verkaufen",
    button2 = CANCEL,
    OnAccept = function(_, itemID)
        Kontor.db.exclusions[itemID] = true
        Kontor:SafeCall("Aufräumen", Kontor.ShowCleanupPreview, Kontor)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local COLUMNS = {
    { key = "name", title = "Item", x = 52, width = 190, justify = "LEFT" },
    { key = "count", title = "Menge", x = 246, width = 44, justify = "RIGHT" },
    { key = "vendor", title = "Händler", x = 296, width = 80, justify = "RIGHT" },
    { key = "ah", title = "AH netto", x = 382, width = 80, justify = "RIGHT" },
    { key = "age", title = "Preis", x = 468, width = 76, justify = "RIGHT" },
}

local function createRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(560, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 12, -84 - (index - 1) * ROW_HEIGHT)
    row:RegisterForClicks("RightButtonUp")

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(22, 22)
    row.check:SetPoint("LEFT", 0, 0)
    row.check:SetScript("OnClick", function() Kontor:UpdateCleanupSummary() end)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(18, 18)
    row.icon:SetPoint("LEFT", 28, 0)

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

    row:SetScript("OnEnter", function(self)
        if not self.data then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(self.data.bag, self.data.slot)
        GameTooltip:AddLine("Rechtsklick: Nie verkaufen", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        if not self.data then return end
        local dialog = StaticPopup_Show("KONTOR_NEVER_SELL", self.data.link or ("Item " .. self.data.itemID))
        if dialog then dialog.data = self.data.itemID end
    end)
    return row
end

local function createPreview()
    local frame = Kontor:CreateWindow("KontorCleanupFrame", "Kontor - Aufräumen", 580, 470, "cleanup")

    local intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 64, -34)
    intro:SetWidth(500)
    intro:SetJustifyH("LEFT")
    intro:SetText("Diese Items bringen beim Händler mindestens so viel wie im AH (nach Gebühr).")

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
    frame.more:SetPoint("BOTTOMLEFT", 16, 66)
    frame.more:SetJustifyH("LEFT")

    frame.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.summary:SetPoint("BOTTOMLEFT", 16, 44)
    frame.summary:SetJustifyH("LEFT")

    local sell = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    sell:SetSize(120, 22)
    sell:SetPoint("BOTTOMRIGHT", -16, 14)
    sell:SetText("Verkaufen")
    sell:SetScript("OnClick", function() Kontor:SafeCall("Aufräumen", Kontor.SellChecked, Kontor) end)
    frame.sellButton = sell

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(120, 22)
    cancel:SetPoint("RIGHT", sell, "LEFT", -8, 0)
    cancel:SetText("Abbrechen")
    cancel:SetScript("OnClick", function() frame:Hide() end)

    return frame
end

function Kontor:UpdateCleanupSummary()
    if not preview then return end
    local count, sum = 0, 0
    for _, row in ipairs(preview.rows) do
        if row.data and row.check:GetChecked() then
            count = count + 1
            sum = sum + row.data.vendorTotal
        end
    end
    preview.summary:SetText("Ausgewählt: " .. count .. " Stapel, Erlös " .. self:FormatMoney(sum))
    preview.sellButton:SetEnabled(count > 0)
end

function Kontor:ShowCleanupPreview()
    if not self.merchantOpen then return end
    if not preview then preview = createPreview() end

    candidates = self:FindCleanupCandidates()
    for i, row in ipairs(preview.rows) do
        local c = candidates[i]
        row.data = c
        if c then
            row.check:SetChecked(true)
            row.icon:SetTexture(c.icon)
            row.cells.name:SetText(c.link or ("Item " .. c.itemID))
            row.cells.count:SetText(c.count)
            row.cells.vendor:SetText(self:FormatMoney(c.vendorTotal))
            row.cells.ah:SetText(self:FormatMoney(c.ahNetTotal))
            row.cells.age:SetText(self:FormatAge(c.priceTime))
            row:Show()
        else
            row:Hide()
        end
    end

    if #candidates == 0 then
        preview.more:SetText("Nichts zu verkaufen.")
    elseif #candidates > MAX_ROWS then
        preview.more:SetText("Weitere " .. (#candidates - MAX_ROWS) .. " Stapel beim nächsten Durchlauf "
            .. "(höchstens " .. MAX_ROWS .. ", damit alles über den Rückkauf zurückholbar bleibt).")
    else
        preview.more:SetText("")
    end

    self:UpdateCleanupSummary()
    preview:Show()
    self:UpdateCleanupButton()
end

function Kontor:SellChecked()
    if not self.merchantOpen or not MerchantFrame:IsShown() then
        self:Print("Der Händler ist nicht mehr geöffnet. Nichts verkauft.")
        return
    end
    if InCombatLockdown() then
        self:Print("Im Kampf wird nichts verkauft.")
        return
    end

    local sold, revenue, skipped = 0, 0, 0
    for _, row in ipairs(preview.rows) do
        local c = row.data
        if c and row.check:GetChecked() then
            -- Sell only if the slot still holds exactly what the preview showed.
            local info = C_Container.GetContainerItemInfo(c.bag, c.slot)
            if info and info.itemID == c.itemID and info.stackCount == c.count and not info.isLocked then
                C_Container.UseContainerItem(c.bag, c.slot)
                sold = sold + 1
                revenue = revenue + c.vendorTotal
            else
                skipped = skipped + 1
            end
        end
    end

    preview:Hide()
    local text = "Aufgeräumt: " .. sold .. " Stapel verkauft, Erlös " .. self:FormatMoney(revenue) .. "."
    if skipped > 0 then
        text = text .. " " .. skipped .. " übersprungen (Tasche hat sich geändert)."
    end
    self:Print(text)
end

-- Events -------------------------------------------------------------------

local recountPending = false
local function scheduleRecount()
    if recountPending then return end
    recountPending = true
    C_Timer.After(0.3, function()
        recountPending = false
        if Kontor.merchantOpen then
            Kontor:SafeCall("Aufräumen", Kontor.UpdateCleanupButton, Kontor)
        end
    end)
end

Kontor:RegisterEvent("MERCHANT_SHOW", "Aufräumen", function()
    Kontor.merchantOpen = true
    if not merchantButton and MerchantFrame then
        merchantButton = createMerchantButton()
    end
    Kontor:UpdateCleanupButton()
end)

Kontor:RegisterEvent("MERCHANT_CLOSED", "Aufräumen", function()
    Kontor.merchantOpen = false
    if preview then preview:Hide() end
end)

Kontor:RegisterEvent("BAG_UPDATE_DELAYED", "Aufräumen", function()
    if Kontor.merchantOpen then scheduleRecount() end
end)

Kontor:RegisterEvent("GET_ITEM_INFO_RECEIVED", "Aufräumen", function()
    if Kontor.merchantOpen then scheduleRecount() end
end)
