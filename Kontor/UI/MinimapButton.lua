-- Kontor: minimap button that opens the disenchant window (wish of the user,
-- 13.10.2026). Only shown on characters that can disenchant. Drag it along
-- the minimap edge; the position is remembered. No external libraries.

local _, Kontor = ...

local ICON = "Interface\\Icons\\INV_Enchant_Disenchant"
local RADIUS = 104

local button

local function place()
    local angle = math.rad(Kontor.db.ui.minimapAngle or 210)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    Kontor.db.ui.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
    place()
end

local function create()
    local b = CreateFrame("Button", "KontorMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    b:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then
            Kontor:SafeCall("Minimap", Kontor.ToggleMainFrame, Kontor)
        else
            Kontor:SafeCall("Minimap", Kontor.ShowDisenchantWindow, Kontor)
        end
    end)
    b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Kontor")
        GameTooltip:AddLine("Linksklick: Entzaubern", 1, 1, 1)
        GameTooltip:AddLine("Rechtsklick: Kontor-Fenster", 1, 1, 1)
        GameTooltip:AddLine("Ziehen: verschieben", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function Kontor:UpdateMinimapButton()
    local wanted = self.db.config.minimapButton and self:IsEnchanter()
    if wanted and not button then
        button = create()
        place()
    end
    if button then button:SetShown(wanted and true or false) end
end

Kontor:RegisterEvent("PLAYER_LOGIN", "Minimap", function() Kontor:UpdateMinimapButton() end)
-- Enchanting learned or unlearned while playing
Kontor:RegisterEvent("SPELLS_CHANGED", "Minimap", function() Kontor:UpdateMinimapButton() end)
