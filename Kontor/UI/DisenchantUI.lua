-- Kontor: disenchant window with "Nächstes entzaubern" (Nachtrag 2, 7; M12)
-- and the list "Kaufen zum Entzaubern" (Nachtrag 2, 8; M14).

local _, Kontor = ...

local DISENCHANT = 13262
local ROWS = 12

-- Candidates ----------------------------------------------------------------

-- Bag items with the advice "Entzaubern", highest gain over the best
-- alternative first. Excluded: baskets, "nie entzaubern", item sets.
function Kontor:FindDisenchantCandidates()
    local list = {}
    self:ForEachBagItem(function(bag, slot, info)
        local itemID = info.itemID
        if self.db.deExclusions[itemID] or self:FindBasketItem(itemID) then return end
        local setID = select(16, C_Item.GetItemInfo(info.hyperlink or itemID))
        if setID and setID ~= 0 then return end
        local a = self:DisenchantAdvice(info.hyperlink or itemID, info.isBound)
        if a and a.advice == "Entzaubern" then
            local alt = math.max(a.vendor, a.ah or 0)
            table.insert(list, { bag = bag, slot = slot, itemID = itemID, link = info.hyperlink,
                de = a.de, alt = alt, gain = a.de - alt, n = a.n })
        end
    end)
    table.sort(list, function(x, y) return x.gain > y.gain end)
    return list
end

-- AH offers below their disenchant value (Nachtrag 2, 8). Only groups with
-- enough data; items with variants are marked "Variante prüfen".
function Kontor:FindDisenchantBuys()
    local list = {}
    local data = self:GetMarketData(false)
    if not data then return list end
    local discount = self.db.config.deBuyDiscount
    for itemID, entry in pairs(data.prices) do
        if entry.p and entry.listed ~= false and self:IsPriceFresh(entry) then
            local a = self:DisenchantAdvice(itemID, false)
            if a and a.de and a.priced and not a.uncertain and entry.p < a.de * (1 - discount) then
                table.insert(list, { itemID = itemID, price = entry.p, de = a.de, profit = a.de - entry.p,
                    n = a.n, variant = entry.v })
            end
        end
    end
    table.sort(list, function(x, y) return x.profit > y.profit end)
    return list
end

-- Secure button ---------------------------------------------------------------

local win, secure
local pendingSecureUpdate = false

-- The secure button sits on UIParent, below the window but not anchored to
-- it: anchoring would make our window protected, so it could no longer be
-- moved or closed in combat. Placed out of combat only.
local function placeSecure()
    if not (secure and win) or InCombatLockdown() then return end
    local x, bottom = win:GetCenter(), win:GetBottom()
    if not x or not bottom then return end
    local scale = win:GetEffectiveScale() / UIParent:GetEffectiveScale()
    secure:ClearAllPoints()
    secure:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x * scale, bottom * scale + 16)
end

local function spellName()
    return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(DISENCHANT)) or "Entzaubern"
end

-- Points the secure button at the first candidate. Only out of combat:
-- attributes of secure frames cannot change in combat.
local function updateSecure()
    if not secure then return end
    if InCombatLockdown() then
        pendingSecureUpdate = true
        secure:SetText("Im Kampf gesperrt")
        return
    end
    pendingSecureUpdate = false
    local shown = win and win:IsShown()
    secure:SetShown(shown and true or false)
    if not shown then return end
    placeSecure()
    local first = win.candidates and win.candidates[1]
    if first then
        -- /stopmacro [combat] keeps the button inert in combat (Nachtrag 2, 7).
        secure:SetAttribute("macrotext", "/stopmacro [combat]\n/cast " .. spellName() .. "\n/use " .. first.bag .. " " .. first.slot)
        secure:SetText("Nächstes entzaubern: " .. (C_Item.GetItemInfo(first.itemID) or "?"))
        secure:Enable()
    else
        secure:SetAttribute("macrotext", "")
        secure:SetText("Nichts zu entzaubern")
        secure:Disable()
    end
end

local function createSecure()
    -- Parented to UIParent, so our normal window stays unprotected.
    local b = CreateFrame("Button", "KontorDisenchantButton", UIParent, "SecureActionButtonTemplate, UIPanelButtonTemplate")
    b:SetSize(360, 36)
    b:SetFrameStrata("DIALOG")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")
    b:Hide()
    return b
end

StaticPopupDialogs["KONTOR_NEVER_DE"] = {
    text = "%s nie entzaubern?", button1 = "Nie entzaubern", button2 = CANCEL,
    OnAccept = function(_, data)
        Kontor.db.deExclusions[data.itemID] = true
        Kontor:FireChange()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

local COLUMNS = {
    { key = "name", title = "Item", width = 200 },
    { key = "de", title = "Entzaubern", width = 80, justify = "RIGHT" },
    { key = "alt", title = "Beste Alternative", width = 100, justify = "RIGHT" },
    { key = "gain", title = "Mehrwert", width = 80, justify = "RIGHT" },
    { key = "n", title = "n", width = 40, justify = "RIGHT" },
}

local function refresh()
    if not win or not win:IsShown() then return end
    win.candidates = Kontor:FindDisenchantCandidates()
    win.table:SetRows(win.candidates, function(row, c)
        row.cells.name:SetText(c.link or Kontor:ItemLabel(c.itemID))
        row.cells.de:SetText(Kontor:FormatMoney(c.de))
        row.cells.alt:SetText(Kontor:FormatMoney(c.alt))
        row.cells.gain:SetText(Kontor:FormatMoney(c.gain))
        row.cells.n:SetText(c.n)
    end)
    win.salvager:SetChecked(Kontor.db.config.salvagerActive and true or false)
    win.empty:SetText(#win.candidates == 0 and "Keine Items mit der Empfehlung \"Entzaubern\" in den Taschen." or "")
    updateSecure()
end

local function createWindow()
    local f = Kontor:CreateWindow("KontorDisenchant", "Kontor - Entzaubern", 560, 470, "disenchant")
    local intro = Kontor:CreateLabel(f, "Items, die entzaubert mehr bringen als im AH oder beim Händler. "
        .. "Rechtsklick: nie entzaubern.")
    intro:SetPoint("TOPLEFT", 64, -34)
    intro:SetWidth(470)
    f.table = Kontor:CreateTable(f, COLUMNS, ROWS, 20)
    f.table:SetPoint("TOPLEFT", 16, -70)
    f.table.onClick = function(c, mouse)
        if mouse == "RightButton" then
            Kontor:ShowDialog("KONTOR_NEVER_DE", c.link or Kontor:ItemLabel(c.itemID), { itemID = c.itemID })
        end
    end
    f.table.onEnter = function(row, c)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(c.bag, c.slot)
        GameTooltip:Show()
    end
    f.empty = Kontor:CreateLabel(f, "", "GameFontDisable")
    f.empty:SetPoint("TOPLEFT", 16, -100)

    f.salvager = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.salvager:SetPoint("BOTTOMLEFT", 12, 60)
    f.salvager:SetScript("OnClick", function(self)
        Kontor.db.config.salvagerActive = self:GetChecked() and true or false
        Kontor:FireChange()
    end)
    local salvLabel = Kontor:CreateLabel(f, "Arcane Salvager aktiv (wird bei jedem Entzaubern mitgespeichert)")
    salvLabel:SetPoint("LEFT", f.salvager, "RIGHT", 4, 0)

    f:HookScript("OnShow", refresh)
    f:HookScript("OnHide", updateSecure)
    Kontor:OnChange(refresh)
    return f
end

function Kontor:ShowDisenchantWindow()
    if not self:IsEnchanter() then
        self:Print("Dieser Charakter kann nicht entzaubern.")
        return
    end
    if InCombatLockdown() then
        self:Print("Das Entzauber-Fenster geht im Kampf nicht auf.")
        return
    end
    if not win then
        win = createWindow()
        win:HookScript("OnDragStop", placeSecure)
    end
    win:Show()
end

-- Created at login (out of combat), so its attributes can be set.
Kontor:RegisterEvent("PLAYER_LOGIN", "Entzauber-Fenster", function()
    secure = createSecure()
end)

Kontor:RegisterEvent("BAG_UPDATE_DELAYED", "Entzauber-Fenster", function()
    if win and win:IsShown() then refresh() end
end)
Kontor:RegisterEvent("PLAYER_REGEN_DISABLED", "Entzauber-Fenster", function()
    if secure then secure:SetText("Im Kampf gesperrt") end
end)
Kontor:RegisterEvent("PLAYER_REGEN_ENABLED", "Entzauber-Fenster", function()
    if secure then updateSecure() end
end)

-- Kaufen zum Entzaubern ---------------------------------------------------------

local buyWin

local BUY_COLUMNS = {
    { key = "name", title = "Item", width = 200 },
    { key = "price", title = "AH-Preis", width = 76, justify = "RIGHT" },
    { key = "de", title = "Entzauberwert", width = 90, justify = "RIGHT" },
    { key = "profit", title = "Gewinn", width = 76, justify = "RIGHT" },
    { key = "note", title = "", width = 100 },
}

local function refreshBuys()
    if not buyWin or not buyWin:IsShown() then return end
    local list = Kontor:FindDisenchantBuys()
    buyWin.table:SetRows(list, function(row, c)
        row.cells.name:SetText(Kontor:ItemLabel(c.itemID))
        row.cells.price:SetText(Kontor:FormatMoney(c.price))
        row.cells.de:SetText(Kontor:FormatMoney(c.de))
        row.cells.profit:SetText(Kontor:FormatMoney(c.profit))
        row.cells.note:SetText(c.variant and "|cffff8800Variante prüfen|r" or "")
    end)
    buyWin.empty:SetText(#list == 0 and "Keine Angebote unter Entzauberwert (nur Gruppen mit genug Daten)." or "")
end

function Kontor:ShowDisenchantBuys()
    if not buyWin then
        buyWin = self:CreateWindow("KontorDisenchantBuys", "Kontor - Kaufen zum Entzaubern", 600, 400, "deBuys")
        local intro = self:CreateLabel(buyWin, "AH-Angebote unter Entzauberwert minus "
            .. math.floor(self.db.config.deBuyDiscount * 100) .. " % Abschlag. Klick sucht das Item im AH. Gekauft wird von Hand.")
        intro:SetPoint("TOPLEFT", 64, -34)
        intro:SetWidth(510)
        buyWin.table = self:CreateTable(buyWin, BUY_COLUMNS, 14, 20)
        buyWin.table:SetPoint("TOPLEFT", 16, -70)
        buyWin.table.onClick = function(c)
            local name = C_Item.GetItemInfo(c.itemID)
            if not (Kontor.ahOpen and AuctionHouseFrame and AuctionHouseFrame.SearchBar and name) then
                Kontor:Print("Die AH-Suche geht nur bei geöffnetem Auktionshaus.")
                return
            end
            AuctionHouseFrame.SearchBar:SetSearchText(name)
            AuctionHouseFrame.SearchBar:StartSearch()
        end
        buyWin.empty = self:CreateLabel(buyWin, "", "GameFontDisable")
        buyWin.empty:SetPoint("TOPLEFT", 16, -100)
        buyWin:HookScript("OnShow", refreshBuys)
    end
    buyWin:Show()
end
