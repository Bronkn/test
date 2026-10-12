-- Kontor: disenchant log (Nachtrag 2, M5b). Records every disenchant that can
-- be attributed without doubt: item, its properties and what came out.
-- Unclear cases are dropped, never guessed.

local _, Kontor = ...

local DISENCHANT = 13262
local ENCHANTING_SKILL_LINE = 333
local LOOT_WINDOW = 5 -- seconds between cast success and loot
local ERROR_WINDOW = 2 -- seconds an error message counts for a failed cast

local attempt -- { link, itemID, quality, ilvl, class, reqLevel, unclear, succeededAt, auras, skill }
local lastError -- { msg, at }

local function classLabel(classID)
    if classID == 4 then return "armor" end
    if classID == 2 then return "weapon" end
    return "other"
end

-- The item being disenchanted is locked while the spell runs.
local function findTarget()
    local found, count = nil, 0
    Kontor:ForEachBagItem(function(_, _, info)
        if info.isLocked then
            found = info
            count = count + 1
        end
    end)
    if count ~= 1 then return nil end
    return found
end

local function describe(info)
    if not info then return { unclear = true } end
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
local castEvents = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_INTERRUPTED" }
for _, event in ipairs(castEvents) do
    if not pcall(castFrame.RegisterUnitEvent, castFrame, event, "player") then
        Kontor:LogError("Entzaubern", "Event " .. event .. " unbekannt")
    end
end

local function logFailure(reason)
    local a = attempt or describe(findTarget())
    table.insert(Kontor.db.deFailures, {
        t = time(), itemID = a.itemID, quality = a.quality, ilvl = a.ilvl, class = a.class,
        skill = enchantingSkill(), msg = reason,
    })
    Kontor:Print("Entzaubern fehlgeschlagen" .. (a.link and (" (" .. a.link .. ")") or "") .. ": " .. reason)
end

castFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    Kontor:SafeCall("Entzaubern", function()
        if not isDisenchant(unit, spellID) then return end

        if event == "UNIT_SPELLCAST_START" then
            attempt = describe(findTarget())
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            attempt = attempt or describe(findTarget())
            attempt.succeededAt = GetTime()
            attempt.auras = playerAuras()
            attempt.skill = enchantingSkill()
        else -- failed or interrupted
            -- Only failures with a game error message are logged (e.g. skill
            -- too low); moving or pressing Escape is no failure of the item.
            if event == "UNIT_SPELLCAST_FAILED" and lastError and GetTime() - lastError.at <= ERROR_WINDOW then
                logFailure(lastError.msg)
            end
            attempt = nil
        end
    end)
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

local function onLoot()
    local a = attempt
    if not a or not a.succeededAt then return end -- not ours (mob, chest, ...)
    attempt = nil
    if GetTime() - a.succeededAt > LOOT_WINDOW or not lootIsFromItem() then return end
    if a.unclear then
        Kontor:Print("Entzaubern nicht protokolliert: Item nicht eindeutig erkannt.")
        return
    end

    local results, parts = readLoot()
    if #parts == 0 then return end

    local cfg = Kontor.db.config
    table.insert(Kontor.db.deLog, {
        t = time(), itemID = a.itemID, quality = a.quality, ilvl = a.ilvl, class = a.class,
        reqLevel = a.reqLevel, skill = a.skill, salvager = cfg.salvagerActive and true or false,
        auras = a.auras, results = results,
    })
    Kontor:Print("Entzaubert: " .. (a.link or Kontor:ItemLabel(a.itemID)) .. " → " .. table.concat(parts, ", ")
        .. (cfg.salvagerActive and " (Salvager aktiv)" or ""))
end

Kontor:RegisterEvent("LOOT_READY", "Entzaubern", onLoot)
Kontor:RegisterEvent("LOOT_OPENED", "Entzaubern", onLoot)

-- Enchanter name (Nachtrag 2, 5): remembered on the first login with enchanting.
Kontor:RegisterEvent("PLAYER_LOGIN", "Entzaubern", function()
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
