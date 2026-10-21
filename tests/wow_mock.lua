-- Minimal WoW API mock for smoke tests.
local chat = {}
CHAT = chat
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(chat, m) end }
local now = 1000
function GetTime() now = now + 0.1 return now end
function time() return 1760270000 end
function date(f, t) return os.date(f, t) end
function debugstack() return "stack..." end
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
function GetBuildInfo() return "1.60.1", "70338", "Oct  9 2026", 16001 end
function GetNormalizedRealmName() return REALM end
function GetRealmName() return "Classic Beta PvP" end
function UnitFactionGroup() return "Horde" end
C_AddOns = { GetAddOnMetadata = function(a, k) if k == "Version" then return "0.1.0" end end }
C_XMLUtil = { GetTemplateInfo = function(t) return TEMPLATES[t] end }
TEMPLATES = { ButtonFrameTemplate = {} }
UISpecialFrames = {}
StaticPopupDialogs = {}
function StaticPopup_Show(n) StaticPopupDialogs[n].OnAccept() end
YES, NO = "Ja", "Nein"
ChatFontNormal = {}
local FrameMT = {}
FrameMT.__index = function(t, k)
  if k == "SetTitle" or k == "SetPortraitToAsset" then
    if rawget(t, "_template") == "ButtonFrameTemplate" then return function() end end
    return nil
  end
  if FrameMT[k] then return FrameMT[k] end
  if type(k) == "string" and k:match("^%u") then return function() end end
  return nil
end
function FrameMT:SetScript(n, f) self._scripts[n] = f end
function FrameMT:GetScript(n) return self._scripts[n] end
function FrameMT:RegisterEvent(e) if UNKNOWN_EVENTS and UNKNOWN_EVENTS[e] then error("unknown event " .. e) end EVENTFRAMES[e] = EVENTFRAMES[e] or {} table.insert(EVENTFRAMES[e], self) end
function FrameMT:RegisterUnitEvent(e) return FrameMT.RegisterEvent(self, e) end
function FrameMT:SetPoint(p, a, b, c, d)
  if type(a) == "number" or a == nil then self._p = { p, "CENTER", a or 0, b or 0 } return end
  self._p = { p, b, c, d }
end
function FrameMT:GetPoint() return self._p[1], nil, self._p[2], self._p[3], self._p[4] end
function FrameMT:ClearAllPoints() self._p = nil end
function FrameMT:Show() self._shown = true if self._scripts.OnShow then self._scripts.OnShow(self) end end
function FrameMT:Hide() self._shown = false end
function FrameMT:IsShown() return self._shown end
function FrameMT:SetShown(v) if v then self:Show() else self:Hide() end end
function FrameMT:SetText(t) self._text = t end
function FrameMT:CreateFontString() return setmetatable({ _scripts = {} }, FrameMT) end
function FrameMT:StartMoving() end
function FrameMT:StopMovingOrSizing() self._p = { "TOPLEFT", "TOPLEFT", 123, -45 } end
EVENTFRAMES = {}
function CreateFrame(kind, name, parent, template)
  local f = setmetatable({ _scripts = {}, _template = template, _shown = true }, FrameMT)
  if name then _G[name] = f end
  return f
end
UIParent = CreateFrame("Frame")
SlashCmdList = {}
function fire(e, ...) for _, f in ipairs(EVENTFRAMES[e] or {}) do f._scripts.OnEvent(f, e, ...) end end
-- scan-related mocks
FRAMES = {}
local origCreate = CreateFrame
function CreateFrame(...) local f = origCreate(...) table.insert(FRAMES, f) return f end
function FrameMT:SetEnabled(v) self._enabled = v end
function tick(n) for _ = 1, n or 1 do for _, f in ipairs(FRAMES) do if f._shown and f._scripts.OnUpdate then f._scripts.OnUpdate(f, 0.3) end end end end
function hooksecurefunc(t, k, h)
  if type(t) == "string" then t, k, h = _G, t, k end
  local o = t[k] or function() end
  t[k] = function(...) local r = { o(...) } h(...) return unpack(r) end
end
Enum = { AuctionHouseSortOrder = { Price = 0, Name = 1 } }
AH = { ready = true, full = false, results = {}, sent = 0, more = 0 }
C_AuctionHouse = {
  SendBrowseQuery = function(q) AH.sent = AH.sent + 1 AH.lastQuery = q end,
  GetBrowseResults = function() return AH.results end,
  HasFullBrowseResults = function() return AH.full end,
  RequestMoreBrowseResults = function() AH.more = AH.more + 1 end,
  IsThrottledMessageSystemReady = function() return AH.ready end,
}
POPUPS = {}
function StaticPopup_Show(n, a) table.insert(POPUPS, { n, a }) if n == "KONTOR_CLEAR_ERRORS" then StaticPopupDialogs[n].OnAccept() end end
function ReloadUI() RELOADED = true end
function row(id, p, q, lvl) return { itemKey = { itemID = id, itemLevel = lvl or 0, itemSuffix = 0, battlePetSpeciesID = 0 }, minPrice = p, totalQuantity = q } end
-- M3-M5b mocks
function InCombatLockdown() return COMBAT == true end
Enum.TooltipDataType = { Item = 0 }
TOOLTIP_CALLS = {}
TooltipDataProcessor = { AddTooltipPostCall = function(t, fn) TOOLTIP_CALLS[t] = fn end }
function makeTooltip() local t = { lines = {} } function t:AddLine(x) table.insert(self.lines, x) end return t end
ITEMS = {} -- id -> { name, sell, classID, quality, ilvl, minLevel }
C_Item = {
  GetItemInfo = function(id)
    if type(id) == "string" then id = tonumber(id:match("item:(%d+)")) end
    local i = ITEMS[id] if not i then return nil end
    return i.name, "|cff|Hitem:" .. id .. "|h[" .. i.name .. "]|h|r", i.quality or 1, i.ilvl or 10, i.minLevel or 5, "", "", 20, "", 1, i.sell, i.classID or 7
  end,
  RequestLoadItemDataByID = function() end,
}
BAGS = {} -- [bag][slot] = info
C_Container = {
  GetContainerNumSlots = function(bag) return bag == 0 and 16 or 0 end,
  GetContainerItemInfo = function(bag, slot) return BAGS[bag] and BAGS[bag][slot] end,
  GetContainerItemQuestInfo = function(bag, slot) return { isQuestItem = QUESTSLOT == slot } end,
  UseContainerItem = function(bag, slot) SOLD = SOLD or {} table.insert(SOLD, slot) BAGS[bag][slot] = nil end,
}
function bagItem(slot, id, count, opts)
  opts = opts or {}
  BAGS[0] = BAGS[0] or {}
  BAGS[0][slot] = { itemID = id, stackCount = count, quality = opts.quality or (ITEMS[id] and ITEMS[id].quality) or 1,
    isBound = opts.bound or false, hasNoValue = opts.noValue or false, hyperlink = "|cff|Hitem:" .. id .. "|h[" .. (ITEMS[id] and ITEMS[id].name or "?") .. "]|h|r",
    iconFileID = 1, isLocked = opts.locked or false, itemName = ITEMS[id] and ITEMS[id].name }
end
TIMERS = {}
C_Timer = { After = function(d, f) table.insert(TIMERS, f) end }
function runTimers() local t = TIMERS TIMERS = {} for _, f in ipairs(t) do f() end end
GameTooltip = CreateFrame("Frame")
function FrameMT:SetChecked(v) self._checked = v end
function FrameMT:GetChecked() return self._checked end
CANCEL = "Abbrechen"
function UnitName() return "Bankchar" end
C_SpellBook = { IsSpellKnown = function(id) return id == 13262 end }
function GetProfessions() return 1, 2 end
function GetProfessionInfo(i) if i == 1 then return "Alchemie", 0, 66, 75, 0, 0, 171 end return "Verzauberkunst", 0, 42, 75, 0, 0, 333 end
C_UnitAuras = { GetAuraDataByIndex = function(u, i) if i == 1 then return { spellId = 777 } end end }
LOOT = {}
function GetNumLootItems() return #LOOT end
function GetLootSlotLink(i) return "|cff|Hitem:" .. LOOT[i][1] .. "|h[x]|h|r" end
function GetLootSlotInfo(i) return 1, "x", LOOT[i][2] end
LOOTSOURCE = "Item-1-2-3"
function GetLootSourceInfo() return LOOTSOURCE end
-- AH depth/purchase
DEPTH = {}
C_AuctionHouse.MakeItemKey = function(id) return { itemID = id } end
C_AuctionHouse.SendSearchQuery = function(k) AH.search = k.itemID end
C_AuctionHouse.GetNumCommoditySearchResults = function() return #DEPTH end
C_AuctionHouse.GetCommoditySearchResultInfo = function(_, i) return DEPTH[i] end
C_AuctionHouse.HasFullCommoditySearchResults = function() return true end
C_AuctionHouse.RequestMoreCommoditySearchResults = function() end
C_AuctionHouse.StartCommoditiesPurchase = function() end
C_AuctionHouse.ConfirmCommoditiesPurchase = function() end
MerchantFrame = CreateFrame("Frame", "MerchantFrame")
function FrameMT:CreateTexture() return setmetatable({ _scripts = {} }, FrameMT) end

function FrameMT:GetText() return rawget(self, "_text") end
function FrameMT:HookScript(n, f) local old = self._scripts[n] self._scripts[n] = function(...) if old then old(...) end f(...) end end
function FrameMT:Show() self._shown = true if self._scripts.OnShow then self._scripts.OnShow(self) end end
function FrameMT:GetFontString() return setmetatable({ _scripts = {} }, FrameMT) end
function FrameMT:SetAttribute(k, v) self._attr = self._attr or {} self._attr[k] = v end
function FrameMT:GetAttribute(k) return self._attr and self._attr[k] end
function FrameMT:HasFocus() return rawget(self, "_focus") == true end
function FrameMT:IsVisible() return self._shown end
function GetCursorInfo() return nil end
function ChatEdit_InsertLink() end
ITEM_SOULBOUND = "Seelengebunden"
OKAY, DELETE, REMOVE = "Okay", "Löschen", "Entfernen"
C_Item.GetItemCount = function(id) return CHARCOUNT and CHARCOUNT[id] or 0 end
C_Spell = { GetSpellName = function() return "Entzaubern" end }

function FrameMT:GetCenter() return 500, 400 end
function FrameMT:GetBottom() return 200 end
function FrameMT:GetEffectiveScale() return 1 end
function FrameMT:IsMultiLine() return rawget(self, "_multi") == true end
function FrameMT:SetMultiLine(v) self._multi = v end
function FrameMT:Insert(t) self._text = (rawget(self, "_text") or "") .. t end
ChatFrameUtil = { InsertLink = function() end }
Minimap = CreateFrame("Frame", "Minimap")
function GetCursorPosition() return 0, 0 end
function FrameMT:GetLeft() return 123 end
function FrameMT:GetTop() return 700 end
