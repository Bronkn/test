-- Kontor: disenchant log (Nachtrag 2, M5b). Records every disenchant that can
-- be attributed without doubt: item, its properties and what came out.
-- Unclear cases are dropped, never guessed.

local _, Kontor = ...

local DISENCHANT = 13262
local ENCHANTING_SKILL_LINE = 333
local LOOT_WINDOW = 5 -- seconds between cast success and loot
local ERROR_WINDOW = 2 -- seconds an error message counts for a failed cast

local attempt -- { before = bag snapshot, succeededAt, auras, skill, results, parts }
local lastError -- { msg, at }

local function classLabel(classID)
    if classID == 4 then return "armor" end
    if classID == 2 then return "weapon" end
    return "other"
end

local BAG_WAIT = 3 -- seconds to wait for the bags to update after the loot

-- Which bag item was disenchanted? Forever sends no target name and locks no
-- slot (tests 13.10.2026), so the bags are compared: a snapshot taken when
-- the cast is sent, against the bags after the loot. The one slot whose item
-- disappeared (or shrank by one) is the disenchanted item.
local function snapshotBags()
    local snap = {}
    Kontor:ForEachBagItem(function(bag, slot, info)
        snap[bag .. ":" .. slot] = info
    end)
    return snap
end

local lastSnapshot = {} -- kept current while no disenchant is pending

-- Slots of `before` whose item is gone or fewer now.
local function vanishedItems(before)
    local now = snapshotBags()
    local gone = {}
    for key, old in pairs(before) do
        local cur = now[key]
        if not cur or cur.itemID ~= old.itemID or (cur.stackCount or 1) < (old.stackCount or 1) then
            table.insert(gone, old)
        end
    end
    return gone
end

local function describe(info)
    local link = info.hyperlink
    local _, _, quality, ilvl, reqLevel, _, _, _, _, _, _, classID = C_Item.GetItemInfo(link or info.itemID)
    if C_Item.GetDetailedItemLevelInfo and link then
        ilvl = C_Item.GetDetailedItemLevelInfo(link) or ilvl
    end
    return {
        link = link,
        itemID = info.itemID,
        quality = info.quality or quality,
        ilvl = ilvl,
        reqLevel = reqLevel,
        class = classLabel(classID),
    }
end

local function enchantingSkill()
    if not GetProfessions then return nil end
    for _, index in ipairs({ GetProfessions() }) do
        if index then
            local name, _, skillLevel, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == ENCHANTING_SKILL_LINE or name == "Verzauberkunst" then
                return skillLevel
            end
        end
    end
end

-- Spell IDs of the player's buffs, so a salvager buff can be matched later.
local function playerAuras()
    local list = {}
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return list end
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.spellId and not Kontor:IsSecret(aura.spellId) then
            table.insert(list, aura.spellId)
        end
    end
    return list
end

local function isDisenchant(unit, spellID)
    if Kontor:IsSecret(spellID) or Kontor:IsSecret(unit) then return false end
    return unit == "player" and spellID == DISENCHANT
end

-- Cast events --------------------------------------------------------------

local castFrame = CreateFrame("Frame")
local castEvents = { "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }
for _, event in ipairs(castEvents) do
    if not pcall(castFrame.RegisterUnitEvent, castFrame, event, "player") then
        Kontor:LogError("Entzaubern", "Event " .. event .. " unbekannt")
    end
end

local function logFailure(reason)
    table.insert(Kontor.db.deFailures, { t = time(), skill = enchantingSkill(), msg = reason })
    Kontor:Print("Entzaubern fehlgeschlagen: " .. reason)
end

castFrame:SetScript("OnEvent", function(_, event, unit, ...)
    Kontor:SafeCall("Entzaubern", function(...)
        -- UNIT_SPELLCAST_SENT: unit, target, castGUID, spellID; the others: unit, castGUID, spellID
        local spellID
        if event == "UNIT_SPELLCAST_SENT" then
            spellID = select(3, ...)
        else
            spellID = select(2, ...)
        end
        if not isDisenchant(unit, spellID) then return end

        if event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_START" then
            -- The item is still in the bags here.
            if not attempt then
                attempt = { before = snapshotBags() }
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Without SENT/START, the snapshot from the last bag update must do.
            attempt = attempt or { before = lastSnapshot }
            attempt.succeededAt = GetTime()
            attempt.auras = playerAuras()
            attempt.skill = enchantingSkill()
        else -- failed or interrupted
            -- Only failures with a game error message are logged; moving or
            -- pressing Escape is no failure of the item.
            if event == "UNIT_SPELLCAST_FAILED" and lastError and GetTime() - lastError.at <= ERROR_WINDOW then
                logFailure(lastError.msg)
            end
            attempt = nil
        end
    end, ...)
end)

Kontor:RegisterEvent("UI_ERROR_MESSAGE", "Entzaubern", function(_, _, message)
    if message and not Kontor:IsSecret(message) then
        lastError = { msg = message, at = GetTime() }
    end
end)

-- Loot ---------------------------------------------------------------------

local function lootIsFromItem()
    if not GetLootSourceInfo then return true end -- cannot tell; timing must do
    local guid = GetLootSourceInfo(1)
    if not guid or Kontor:IsSecret(guid) then return true end
    return guid:find("^Item%-") ~= nil
end

local function readLoot()
    local results, parts = {}, {}
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        local itemID = Kontor:ParseItemID(link)
        local _, _, quantity = GetLootSlotInfo(slot)
        if itemID and quantity and quantity > 0 then
            results[itemID] = (results[itemID] or 0) + quantity
            table.insert(parts, quantity .. "× " .. link)
        end
    end
    return results, parts
end

-- Writes the entry once the vanished item is known. Returns false while the
-- bags still hold everything (the item is removed shortly after the loot).
local function tryResolve(a, final)
    local gone = vanishedItems(a.before)
    local item = (#gone == 1) and gone[1] or nil
    if not item then
        if #gone == 0 and not final then return false end
        Kontor:Print("Entzaubern nicht protokolliert: Item nicht eindeutig erkannt ("
            .. #gone .. " Items aus der Tasche verschwunden).")
        return true
    end

    local d = describe(item)
    local cfg = Kontor.db.config
    table.insert(Kontor.db.deLog, {
        t = time(), itemID = d.itemID, quality = d.quality, ilvl = d.ilvl, class = d.class,
        reqLevel = d.reqLevel, skill = a.skill, salvager = cfg.salvagerActive and true or false,
        auras = a.auras, results = a.results,
    })
    Kontor:Print("Entzaubert: " .. (d.link or Kontor:ItemLabel(d.itemID)) .. " → " .. table.concat(a.parts, ", ")
        .. (cfg.salvagerActive and " (Salvager aktiv)" or ""))
    return true
end

local resolving -- attempt waiting for the bags after its loot

local function onLoot()
    local a = attempt
    if not a or not a.succeededAt or a.results then return end -- not ours, or already read
    if GetTime() - a.succeededAt > LOOT_WINDOW or not lootIsFromItem() then
        attempt = nil
        return
    end
    a.results, a.parts = readLoot()
    attempt = nil
    if #a.parts == 0 then return end

    if not tryResolve(a, false) then
        resolving = a
        C_Timer.After(BAG_WAIT, function()
            if resolving == a then
                resolving = nil
                Kontor:SafeCall("Entzaubern", tryResolve, a, true)
            end
        end)
    end
end

Kontor:RegisterEvent("BAG_UPDATE_DELAYED", "Entzaubern", function()
    if resolving then
        local a = resolving
        if tryResolve(a, false) then resolving = nil end
    elseif not attempt then
        lastSnapshot = snapshotBags()
    end
end)

Kontor:RegisterEvent("LOOT_READY", "Entzaubern", onLoot)
Kontor:RegisterEvent("LOOT_OPENED", "Entzaubern", onLoot)

-- Enchanter name (Nachtrag 2, 5): remembered on the first login with enchanting.
Kontor:RegisterEvent("PLAYER_LOGIN", "Entzaubern", function()
    lastSnapshot = snapshotBags()
    local cfg = Kontor.db.config
    local known = C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(DISENCHANT)
    if known and not cfg.enchanterName then
        cfg.enchanterName = UnitName("player")
        Kontor:Print("Verzauberer erkannt: " .. cfg.enchanterName .. ".")
    end
end)

-- Export -------------------------------------------------------------------

local CLASS_TEXT = { armor = "Rüstung", weapon = "Waffe", other = "sonstiges" }

local function buildExport()
    local db = Kontor.db
    local lines = {
        "Kontor Entzauber-Protokoll, " .. #db.deLog .. " Einträge, " .. #db.deFailures .. " Fehlschläge",
        "Zeit;Item-ID;Item;Qualität;Stufe;Klasse;Mindeststufe;Fertigkeit;Salvager;Ergebnis",
    }
    for _, e in ipairs(db.deLog) do
        local res = {}
        for itemID, qty in pairs(e.results) do
            local name = C_Item.GetItemInfo(itemID) or ("Item " .. itemID)
            table.insert(res, qty .. "x " .. name .. " (" .. itemID .. ")")
        end
        table.sort(res)
        table.insert(lines, table.concat({
            Kontor:FormatDateTime(e.t), e.itemID or "?", C_Item.GetItemInfo(e.itemID or 0) or "?",
            e.quality or "?", e.ilvl or "?", CLASS_TEXT[e.class] or "?", e.reqLevel or "?",
            e.skill or "?", e.salvager and "ja" or "nein", table.concat(res, ", "),
        }, ";"))
    end
    if #db.deFailures > 0 then
        table.insert(lines, "")
        table.insert(lines, "Fehlschläge:")
        for _, f in ipairs(db.deFailures) do
            table.insert(lines, Kontor:FormatDateTime(f.t) .. ";" .. (f.itemID or "?") .. ";"
                .. (f.itemID and C_Item.GetItemInfo(f.itemID) or "?") .. ";" .. tostring(f.msg))
        end
    end
    return table.concat(lines, "\n")
end

function Kontor:ShowDisenchantExport()
    self:ShowTextWindow("deExport", "Kontor - Entzauber-Protokoll", buildExport)
end

function Kontor:ToggleSalvager()
    local cfg = self.db.config
    cfg.salvagerActive = not cfg.salvagerActive
    self:Print("Arcane Salvager: " .. (cfg.salvagerActive and "aktiv" or "nicht aktiv")
        .. ". Wird bei jedem Entzaubern mitgespeichert.")
end
