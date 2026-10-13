-- Kontor: optional links to Baganator and Syndicator (wish of the user, 13.10.2026).
-- Both are used only when installed. APIs as in Baganator release 834 /
-- Syndicator release 285 (see docs/Entscheidungen.md).
--
-- Baganator: corner icons on item buttons (Kontor advice, basket marker).
--   Not used: Baganator's junk plugin, because Baganator could then sell
--   items without Kontor's preview (Pflichtenheft 6.1).
-- Syndicator: item counts across all characters (bags, bank, mail, auctions).

local _, Kontor = ...

-- Syndicator --------------------------------------------------------------------

function Kontor:HasSyndicator()
    return Syndicator and Syndicator.API and Syndicator.API.IsReady and Syndicator.API.IsReady() or false
end

-- Count of itemID on all characters of this realm (plus warband bank).
-- Returns total and a breakdown { bags, bank, mail, auctions, equipped, warband, chars },
-- or nil without Syndicator.
function Kontor:GetAccountCount(itemID)
    if not self:HasSyndicator() or not Syndicator.API.GetInventoryInfoByItemID then return nil end
    local info = Syndicator.API.GetInventoryInfoByItemID(itemID, true, false)
    if not info then return nil end
    local b = { bags = 0, bank = 0, mail = 0, auctions = 0, equipped = 0, warband = 0, chars = 0 }
    for _, c in ipairs(info.characters or {}) do
        b.bags = b.bags + (c.bags or 0)
        b.bank = b.bank + (c.bank or 0)
        b.mail = b.mail + (c.mail or 0)
        b.auctions = b.auctions + (c.auctions or 0)
        b.equipped = b.equipped + (c.equipped or 0)
        b.chars = b.chars + 1
    end
    b.warband = (info.warband and info.warband[1]) or 0
    local total = b.bags + b.bank + b.mail + b.auctions + b.equipped + b.warband
    return total, b
end

function Kontor:AccountCountText(itemID)
    local total, b = self:GetAccountCount(itemID)
    if not total then return nil end
    local parts = {}
    if b.bags > 0 then table.insert(parts, b.bags .. " Taschen") end
    if b.bank > 0 then table.insert(parts, b.bank .. " Bank") end
    if b.mail > 0 then table.insert(parts, b.mail .. " Post") end
    if b.auctions > 0 then table.insert(parts, b.auctions .. " im AH") end
    if b.warband > 0 then table.insert(parts, b.warband .. " Kriegsmeute") end
    return "Alle Charaktere (Syndicator): " .. total .. (#parts > 0 and (" (" .. table.concat(parts, ", ") .. ")") or "")
end

-- Baganator ---------------------------------------------------------------------

local ICONS = {
    de = "Interface\\Icons\\INV_Enchant_Disenchant",
    vendor = "Interface\\Icons\\INV_Misc_Coin_01",
    ah = "Interface\\Icons\\INV_Misc_Coin_02",
    basket = "Interface\\Icons\\INV_Misc_Bag_10",
}

local function iconInit(texture)
    return function(itemButton)
        local f = CreateFrame("Frame", nil, itemButton)
        f:SetSize(14, 14)
        local tex = f:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetTexture(texture)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.padding = 1
        return f
    end
end

-- The corner callbacks get Baganator's item details: itemID, itemLink,
-- quality, isBound, hasNoValue, itemLocation (live bag items only).
local function safe(fn)
    return function(frame, d)
        if not Kontor.db or not d or not d.itemID then return false end
        local ok, res = pcall(fn, d)
        return ok and res or false
    end
end

local function adviceFor(d)
    local a = Kontor:DisenchantAdvice(d.itemLink or d.itemID, d.isBound and true or false)
    return a and a.advice
end

local function registerBaganator()
    local api = Baganator and Baganator.API
    if not api or not api.RegisterCornerWidget or Kontor.baganatorRegistered then return end
    Kontor.baganatorRegistered = true

    api.RegisterCornerWidget("Kontor: Entzaubern", "kontor_disenchant", safe(function(d)
        local advice = adviceFor(d)
        return advice == "Entzaubern" or advice == "an Bankchar schicken"
    end), iconInit(ICONS.de), { corner = "top_left", priority = 1 })

    api.RegisterCornerWidget("Kontor: beim Händler verkaufen", "kontor_vendor", safe(function(d)
        local loc = d.itemLocation
        return Kontor:CleanupVerdict(d.itemID, d.itemLink, d.quality, d.isBound and true or false, d.hasNoValue,
            loc and loc.bagID, loc and loc.slotIndex) == "sell"
    end), iconInit(ICONS.vendor), { corner = "top_left", priority = 2 })

    api.RegisterCornerWidget("Kontor: im AH verkaufen", "kontor_ah", safe(function(d)
        if adviceFor(d) == "Entzaubern" then return false end
        return (Kontor:PostingVerdict(d.itemID, d.isBound and true or false))
    end), iconInit(ICONS.ah), { corner = "top_left", priority = 3 })

    api.RegisterCornerWidget("Kontor: Item im Korb", "kontor_basket", safe(function(d)
        return Kontor:FindBasketItem(d.itemID) ~= nil
    end), iconInit(ICONS.basket), { corner = "top_right", priority = 1 })
end

-- Prices, baskets or settings changed: let Baganator redraw its icons.
local refreshPending = false
function Kontor:RefreshBagIcons()
    local api = Baganator and Baganator.API
    if not (self.baganatorRegistered and api and api.RequestItemButtonsRefresh) or refreshPending then return end
    refreshPending = true
    C_Timer.After(0.5, function()
        refreshPending = false
        pcall(api.RequestItemButtonsRefresh)
    end)
end

-- Baganator loads first (OptionalDeps in the toc); register right away and,
-- if it was not there yet, again at login.
registerBaganator()
Kontor:RegisterEvent("PLAYER_LOGIN", "Baganator", function()
    registerBaganator()
    Kontor:OnChange(function() Kontor:RefreshBagIcons() end)
end)
