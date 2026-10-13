-- Kontor: account-wide SavedVariable KontorDB, defaults and migrations.
-- Rule (Pflichtenheft 5): migrations only add, they never discard data.

local ADDON_NAME, Kontor = ...

-- Version 4 = Pflichtenheft + Nachtrag 1 (v2) + Nachtrag 2 (v3) + Nachtrag 3 and M6-M14 (v4).
local DB_VERSION = 4

local DEFAULTS = {
    config = {
        -- Pflichtenheft
        ahFee = 0.05,
        maxPriceAgeHours = 48,
        cleanupMaxQuality = 2, -- green
        cleanupMargin = 0,
        minMargin = 0.20,
        depthUnits = 20,
        tooltipEnabled = true,
        autoOpenWithAH = true, -- Kontor window opens and closes with the AH
        -- Nachtrag 1
        fixedPriceFactor = 0.95,
        craftThreshold = 1.5,
        -- Nachtrag 2 (enchanterName stays nil until detected)
        deMinAdvantage = 0.10,
        deMinSamples = 10,
        deBuyDiscount = 0.25,
        deMaxQuality = 3, -- blue
        salvagerActive = false, -- switch set by the user (docs/Entscheidungen.md)
        usageTooltip = true, -- usage note as last tooltip line (Nachtrag 3)
        deTooltip = true, -- disenchant line in the tooltip (Nachtrag 2, 4.1)
        bankCharName = nil, -- receiver for disenchant goods; defaults to enchanterName
    },
    markets = {},
    baskets = {},
    recipes = {},
    ledger = {},
    exclusions = {},
    postExclusions = {}, -- Verkaufsliste: "nicht anbieten"
    errorLog = {},
    deLog = {},
    deFailures = {},
    deImport = {},
    deExclusions = {},
    ui = {}, -- window positions
    chars = {}, -- per character: professions (for "fremder Beruf")
    deStats = {}, -- disenchant group sums, see DisenchantEval.lua
    deRelease = {}, -- epic items released for disenchanting
}

-- Copies every key of defaults that is missing in target. Existing values,
-- including ones the user changed, are left alone.
local function fillMissing(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                fillMissing(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            fillMissing(target[key], value)
        end
    end
end

-- MIGRATIONS[n] upgrades a database from version n-1 to n. Added fields come
-- from fillMissing; a migration only has to move or reshape existing data.
local MIGRATIONS = {
    [2] = function(db)
        -- Nachtrag 1: recipes move from baskets[].recipes to db.recipes.
        db.recipes = db.recipes or {}
        for _, basket in ipairs(db.baskets or {}) do
            for _, recipe in ipairs(basket.recipes or {}) do
                if recipe.product and db.recipes[recipe.product] == nil then
                    db.recipes[recipe.product] = recipe
                end
            end
        end
    end,
}

local function initDatabase()
    local db = KontorDB
    if type(db) ~= "table" then
        db = { version = DB_VERSION }
        KontorDB = db
    end
    db.version = db.version or 1

    for v = db.version + 1, DB_VERSION do
        if MIGRATIONS[v] then
            MIGRATIONS[v](db)
        end
        db.version = v
    end

    fillMissing(db, DEFAULTS)
    Kontor.db = db
    Kontor:FlushPendingErrors()
end

Kontor:RegisterEvent("ADDON_LOADED", "Datenbank", function(_, name)
    if name == ADDON_NAME then
        initDatabase()
    end
end)
