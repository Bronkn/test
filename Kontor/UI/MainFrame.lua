-- Kontor: window helper and main window (/kontor).

local _, Kontor = ...

local ICON = "Interface\\Icons\\INV_Misc_Coin_02"

local function savePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    Kontor.db.ui[frame.positionKey] = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function restorePosition(frame)
    local pos = Kontor.db.ui[frame.positionKey]
    frame:ClearAllPoints()
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("CENTER")
    end
end

local function hasTemplate(template)
    if C_XMLUtil and C_XMLUtil.GetTemplateInfo then
        return C_XMLUtil.GetTemplateInfo(template) ~= nil
    end
    return false
end

-- Creates a movable, closable window that remembers its position under
-- KontorDB.ui[positionKey]. Uses Blizzard's ButtonFrameTemplate; falls back
-- to a plain backdrop frame if the template is unavailable.
function Kontor:CreateWindow(name, title, width, height, positionKey)
    local frame
    if hasTemplate("ButtonFrameTemplate") then
        frame = CreateFrame("Frame", name, UIParent, "ButtonFrameTemplate")
        if frame.SetTitle then frame:SetTitle(title) end
        if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset, frame, ICON) end
        if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(frame) end
    else
        frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOP", 0, -14)
        text:SetText(title)
    end

    frame.positionKey = positionKey
    frame:SetSize(width, height)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    -- We store the position ourselves; keep the client's layout cache out of it.
    if frame.SetDontSavePosition then frame:SetDontSavePosition(true) end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Kontor:SafeCall("Fenster", savePosition, self)
    end)

    restorePosition(frame)
    frame:Hide()
    table.insert(UISpecialFrames, name) -- Escape closes the window
    return frame
end

-- Main window ---------------------------------------------------------------

local mainFrame

local function createMainFrame()
    local frame = Kontor:CreateWindow("KontorMainFrame", "Kontor", 760, 480, "main")
    Kontor:CreateScanWidget(frame, "TOPLEFT", frame, "TOPLEFT", 64, -30)
    Kontor:CreatePostingButton(frame, "TOPRIGHT", frame, "TOPRIGHT", -12, -30)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    hint:SetPoint("CENTER", 0, -10)
    hint:SetText("Hier entstehen die Körbe (Meilenstein M6).")

    return frame
end

local openedWithAH = false

function Kontor:ToggleMainFrame()
    if not mainFrame then
        mainFrame = createMainFrame()
    end
    openedWithAH = false
    mainFrame:SetShown(not mainFrame:IsShown())
end

-- Opens the window together with the AH (wish of the user, 13.10.2026).
-- Without a saved position it is placed right next to the AH window.
function Kontor:OpenMainFrameWithAH()
    if not self.db.config.autoOpenWithAH then return end
    if not mainFrame then
        mainFrame = createMainFrame()
    end
    if mainFrame:IsShown() then return end
    if not self.db.ui.main and AuctionHouseFrame then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 12, 0)
    end
    openedWithAH = true
    mainFrame:Show()
end

-- Closes it with the AH, but only if it was opened by the AH.
function Kontor:CloseMainFrameWithAH()
    if mainFrame and openedWithAH then
        mainFrame:Hide()
    end
    openedWithAH = false
end
