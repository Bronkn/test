-- Kontor: small UI building blocks shared by the windows.

local _, Kontor = ...

-- Money input: "1g 20s 5c", "1g20s", "120s", "35c", "1,5" or "1.5" (gold).
-- Returns copper or nil for empty/invalid text.
function Kontor:ParseMoney(text)
    text = strtrim((text or ""):lower())
    if text == "" then return nil end
    local plain = text:gsub(",", ".")
    if plain:match("^%d+%.?%d*$") then
        return math.floor(tonumber(plain) * 10000 + 0.5)
    end
    local total, found = 0, false
    for num, unit in text:gmatch("(%d+)%s*([gsck])") do
        found = true
        num = tonumber(num)
        if unit == "g" then total = total + num * 10000
        elseif unit == "s" then total = total + num * 100
        else total = total + num end
    end
    return found and total or nil
end

-- Copper as editable text, e.g. "1g 20s 5c" ("" for nil).
function Kontor:MoneyInputText(copper)
    if not copper then return "" end
    copper = math.floor(copper + 0.5)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then table.insert(parts, g .. "g") end
    if s > 0 then table.insert(parts, s .. "s") end
    if c > 0 or #parts == 0 then table.insert(parts, c .. "c") end
    return table.concat(parts, " ")
end

function Kontor:CreateLabel(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    return fs
end

-- Single-line input box. Shift-click on an item puts its link in while the
-- box has focus; an item dragged onto the box is inserted as a link.
local linkTargets = {}

function Kontor:CreateInput(parent, width)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(width or 120, 20)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if self.onEnter then self.onEnter(self) end
    end)
    box:SetScript("OnReceiveDrag", function(self)
        local kind, itemID, link = GetCursorInfo()
        if kind == "item" then
            self:SetText(link or tostring(itemID))
            ClearCursor()
            if self.onEnter then self.onEnter(self) end
        end
    end)
    table.insert(linkTargets, box)
    return box
end

local function insertLink(link)
    if not link then return end
    for _, box in ipairs(linkTargets) do
        if box:IsVisible() and box:HasFocus() then
            box:SetText(link)
            return true
        end
    end
end

-- Blizzard calls this on Shift-click; the hook only acts while one of our
-- boxes has the focus (the chat input is then closed).
if ChatEdit_InsertLink then
    hooksecurefunc("ChatEdit_InsertLink", insertLink)
elseif ChatFrameUtil and ChatFrameUtil.InsertLink then
    hooksecurefunc(ChatFrameUtil, "InsertLink", insertLink)
end

function Kontor:CreateButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 100, 22)
    button:SetText(text)
    button:SetScript("OnClick", function(self, mouse)
        Kontor:SafeCall("Fenster", onClick, self, mouse)
    end)
    return button
end

-- Simple table: header plus `rows` clickable lines with the given columns.
-- columns: { { key, title, width, justify } }; returns frame with :SetRows(data, fill).
function Kontor:CreateTable(parent, columns, rows, rowHeight)
    local t = CreateFrame("Frame", nil, parent)
    rowHeight = rowHeight or 20
    local width = 0
    for _, col in ipairs(columns) do width = width + col.width + 6 end
    t:SetSize(width, rowHeight * (rows + 1))
    t.offset = 0

    local x = 0
    for _, col in ipairs(columns) do
        local fs = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("TOPLEFT", x, 0)
        fs:SetWidth(col.width)
        fs:SetJustifyH(col.justify or "LEFT")
        fs:SetText(col.title)
        col.x = x
        x = x + col.width + 6
    end

    t.rows = {}
    for i = 1, rows do
        local row = CreateFrame("Button", nil, t)
        row:SetSize(width, rowHeight)
        row:SetPoint("TOPLEFT", 0, -i * rowHeight)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        row.cells = {}
        for _, col in ipairs(columns) do
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", col.x, 0)
            fs:SetWidth(col.width)
            fs:SetJustifyH(col.justify or "LEFT")
            fs:SetWordWrap(false)
            row.cells[col.key] = fs
        end
        row:SetScript("OnClick", function(self, mouse)
            if self.data and t.onClick then Kontor:SafeCall("Fenster", t.onClick, self.data, mouse, self) end
        end)
        row:SetScript("OnEnter", function(self)
            if self.data and t.onEnter then t.onEnter(self, self.data) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        t.rows[i] = row
    end

    t:EnableMouseWheel(true)
    t:SetScript("OnMouseWheel", function(self, delta)
        local maxOffset = math.max(0, #(self.data or {}) - rows)
        self.offset = math.min(maxOffset, math.max(0, self.offset - delta))
        self:Render()
    end)

    -- fill(row, item) writes the cells of one row.
    function t:SetRows(data, fill)
        self.data, self.fill = data, fill
        self.offset = math.min(self.offset, math.max(0, #data - rows))
        self:Render()
    end

    function t:Render()
        for i, row in ipairs(self.rows) do
            local item = self.data and self.data[i + self.offset]
            row.data = item
            if item then
                self.fill(row, item)
                row:Show()
            else
                row:Hide()
            end
        end
    end

    return t
end

-- Percent text with sign and colour, e.g. "+12 %" (green) / "-5 %" (red).
function Kontor:FormatChange(fraction)
    if not fraction then return "-" end
    local pct = math.floor(fraction * 100 + (fraction >= 0 and 0.5 or -0.5))
    local color = pct > 0 and "|cff33ff33" or (pct < 0 and "|cffff5555" or "|cffcccccc")
    return color .. (pct > 0 and "+" or "") .. pct .. " %|r"
end
