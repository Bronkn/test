-- Kontor: window showing selectable, read-only text (error log, exports).

local _, Kontor = ...

local windows = {} -- id -> frame

local function refresh(frame)
    if frame and frame:IsShown() then
        frame.editBox:SetText(frame.buildText())
    end
end

local function createTextWindow(id, title, buildText, actionLabel, action)
    local frame = Kontor:CreateWindow("KontorText_" .. id, title, 640, 420, "text_" .. id)
    frame.buildText = buildText

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -64)
    scroll:SetPoint("BOTTOMRIGHT", -34, 44)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(580)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    -- Read-only: any typing restores the text.
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(frame.buildText()) end
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

    if actionLabel then
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(140, 22)
        button:SetPoint("BOTTOMRIGHT", -16, 14)
        button:SetText(actionLabel)
        button:SetScript("OnClick", action)
    end

    frame:SetScript("OnShow", refresh)
    return frame
end

-- Opens (or refreshes) the text window `id`. buildText() returns the text.
function Kontor:ShowTextWindow(id, title, buildText, actionLabel, action)
    local frame = windows[id]
    if not frame then
        frame = createTextWindow(id, title, buildText, actionLabel, action)
        windows[id] = frame
    end
    frame:Show()
    refresh(frame)
    return frame
end

function Kontor:RefreshTextWindow(id)
    refresh(windows[id])
end

-- Window with an editable text field and an "Übernehmen" button.
-- onAccept(text) returns true to close the window.
local inputWindows = {}

function Kontor:ShowInputWindow(id, title, hint, onAccept)
    local frame = inputWindows[id]
    if not frame then
        frame = Kontor:CreateWindow("KontorInput_" .. id, title, 640, 420, "input_" .. id)
        local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -64)
        scroll:SetPoint("BOTTOMRIGHT", -34, 44)
        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(580)
        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        scroll:SetScrollChild(editBox)
        frame.editBox = editBox
        Kontor:RegisterLinkTarget(editBox)

        frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.hint:SetPoint("TOPLEFT", 64, -40)

        local accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        accept:SetSize(140, 22)
        accept:SetPoint("BOTTOMRIGHT", -16, 14)
        accept:SetText("Übernehmen")
        accept:SetScript("OnClick", function()
            Kontor:SafeCall("Eingabe", function()
                if frame.onAccept(frame.editBox:GetText()) then frame:Hide() end
            end)
        end)
        inputWindows[id] = frame
    end
    frame.onAccept = onAccept
    frame.hint:SetText(hint or "")
    frame.editBox:SetText("")
    frame:Show()
    frame.editBox:SetFocus()
    return frame
end
