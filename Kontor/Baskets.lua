-- Kontor: baskets (watchlist), start configuration and recipe templates
-- (Pflichtenheft 4.4, Nachtrag 1 sections 2, 3, 5, 6, Nachtrag 3).

local _, Kontor = ...

Kontor.PHASES = { "beobachten", "sammeln", "halten", "abstossen" }
Kontor.PHASE_NAMES = { beobachten = "Beobachten", sammeln = "Sammeln", halten = "Halten", abstossen = "Abstoßen" }

local G = 10000 -- copper per gold

-- Basket and item helpers ------------------------------------------------------

function Kontor:GetBasket(id)
    for _, basket in ipairs(self.db.baskets) do
        if basket.id == id then return basket end
    end
end

-- Effective phase of an item: its own override or the basket's.
function Kontor:GetItemPhase(basket, item)
    return (item and item.phase) or basket.phase
end

local function nextBasketId(db)
    local maxId = 0
    for _, b in ipairs(db.baskets) do
        if b.id > maxId then maxId = b.id end
    end
    return maxId + 1
end

function Kontor:CreateBasket(name, phase, basketType)
    local basket = {
        id = nextBasketId(self.db), name = name, note = "", phase = phase or "beobachten",
        type = basketType or "lager", items = {}, order = {},
    }
    table.insert(self.db.baskets, basket)
    return basket
end

function Kontor:DeleteBasket(id)
    for i, basket in ipairs(self.db.baskets) do
        if basket.id == id then
            table.remove(self.db.baskets, i)
            return true
        end
    end
end

-- Adds itemID to basket. An item belongs to at most one basket; the
-- exception (Nachtrag 1, 6) is a workshop basket, which only holds products.
-- Returns true, or false plus a German reason.
function Kontor:AddBasketItem(basket, itemID, settings)
    if basket.items[itemID] then return false, "steht schon in diesem Korb" end
    if basket.type ~= "werkstatt" then
        for _, other in ipairs(self.db.baskets) do
            if other ~= basket and other.type ~= "werkstatt" and other.items[itemID] then
                return false, "steht schon im Korb \"" .. other.name .. "\""
            end
        end
    end
    basket.items[itemID] = settings or {}
    table.insert(basket.order, itemID)
    return true
end

function Kontor:RemoveBasketItem(basket, itemID)
    basket.items[itemID] = nil
    for i, id in ipairs(basket.order) do
        if id == itemID then
            table.remove(basket.order, i)
            break
        end
    end
end

-- Item IDs of a basket in display order (repairs the order list if needed).
function Kontor:BasketItemIDs(basket)
    local seen, list = {}, {}
    for _, id in ipairs(basket.order or {}) do
        if basket.items[id] and not seen[id] then
            table.insert(list, id)
            seen[id] = true
        end
    end
    for id in pairs(basket.items) do
        if not seen[id] then table.insert(list, id) end
    end
    basket.order = list
    return list
end

-- Target price with the fixed price as ceiling (Nachtrag 1, 3).
function Kontor:EffectiveTarget(item)
    if item.target and item.fixedPrice then
        return math.min(item.target, item.fixedPrice)
    end
    if item.target then return item.target end
    if item.fixedPrice then return item.fixedPrice * self.db.config.fixedPriceFactor end
end

-- Start configuration (Nachtrag 1, 6 with the changes of Nachtrag 3, 4) --------

local START_BASKETS = {
    { name = "A - Launch", phase = "sammeln", items = {
        { 249391, 5 * G }, { 249427, 5 * G }, { 249399, 5 * G } } },
    { name = "B - Früh", phase = "beobachten", items = {
        { 3369 }, { 3818 }, { 5500 }, { 8151 } } },
    { name = "C - Mittel", phase = "beobachten", items = {
        { 7079 }, { 7067 }, { 7068 }, { 7971 }, { 8152 }, { 249425, 20 * G }, { 249424, 20 * G } } },
    { name = "D - Spät", phase = "beobachten", items = {
        { 249428, 20 * G }, { 249429, 50 * G }, { 249274, 50 * G }, { 13926 }, { 12808 }, { 12809 },
        { 8831 }, { 4625 } } },
    { name = "W - Werkstatt", phase = "beobachten", type = "werkstatt", items = {
        { 249410 }, { 249409 }, { 249431 }, { 249430 }, { 249432 } } },
}

-- Usage notes (Nachtrag 3, 3)
local USAGE = {
    [249391] = "Sulfuric Acid (2:1); Halskette Healing Power; Waffe Insight/Recovery; Shining-Set Schneiderei 60–125; Glimmering Staff",
    [249399] = "Cerulean Dye (2:1); Waffe Insight direkt",
    [249424] = "Magenta Dye (2:1); Halskette Healing Power direkt",
    [249274] = "Viridian Dye (2:1) → Mooncloth- und Bottomless-Taschen",
    [249425] = "Sandpaper (2:1, Ingenieurskunst) → Plattenrüstung Schmiedekunst",
    [8831] = "Brilliant Mana Oil, Dreamless Sleep, Sentinel's-Set, Cenarion Herb Bag",
    [4625] = "Brilliant Wizard Oil, Philosopher's Stone",
    [7079] = "Frothing- und Netherfroth-Set Schneiderei 140–235, Justicar's-Set Schmiedekunst",
    [13926] = "Prefect's-Set Schmiedekunst 175–270 (4–10 je Teil)",
    [7971] = "Warder's-Set Schmiedekunst 175–270 (4–10 je Teil)",
    [249410] = "Halskette Agility/Strength (je 4); Plattenrüstung Schmiedekunst 150–270 (5 Sets)",
    [249409] = "Halskette Deflection/Spell Power (je 4); Shining-, Frothing-Set; Taschen",
    [249430] = "Halskette Agility/Deflection/Spell Power (je 4); Frothing-Set; Taschen",
    [249431] = "Mooncloth- und Bottomless-Taschen (8–10 je Tasche)",
    [249432] = "Plattenrüstung Schmiedekunst (4–6 je Teil)",
}

-- Recipe templates (Nachtrag 3, 2). Vendor reagents without a known ID or
-- price leave the recipe incomplete. Empty Vial: seen in the alchemy window
-- on 12.10.2026 (Classic ID 3371, not yet confirmed in Forever).
local VENDOR = { name = "Händlerzutat" }
local VIAL = { itemID = 3371, name = "Leere Phiole" }
local RECIPE_TEMPLATES = {
    { key = 249410, product = 249410, profession = "Alchemie", skill = 50,
      reagents = { { itemID = 249391, qty = 2 }, { itemID = VIAL.itemID, name = VIAL.name, qty = 1, vendor = true } } },
    { key = 249409, product = 249409, profession = "Alchemie", skill = 50,
      reagents = { { itemID = 249399, qty = 2 }, { name = VENDOR.name, qty = 1, vendor = true } } },
    { key = 249430, product = 249430, profession = "Alchemie", skill = 130,
      reagents = { { itemID = 249424, qty = 2 }, { name = VENDOR.name, qty = 1, vendor = true } } },
    { key = 249431, product = 249431, profession = "Alchemie", skill = 230,
      reagents = { { itemID = 249274, qty = 2 }, { name = VENDOR.name, qty = 1, vendor = true } } },
    { key = 249432, product = 249432, profession = "Ingenieurskunst", skill = 130,
      reagents = { { itemID = 249425, qty = 2 }, { name = "weitere Zutat (ID offen)", qty = 1 } } },
    { key = "Brilliant Wizard Oil", productName = "Brilliant Wizard Oil", profession = "Verzauberkunst", skill = 300,
      reagents = { { name = "Illusion Dust", qty = 2 }, { itemID = 4625, qty = 3 }, { name = VENDOR.name, qty = 1, vendor = true } } },
    { key = "Brilliant Mana Oil", productName = "Brilliant Mana Oil", profession = "Verzauberkunst", skill = 300,
      reagents = { { name = "Illusion Dust", qty = 2 }, { itemID = 8831, qty = 3 }, { name = VENDOR.name, qty = 1, vendor = true } } },
}

-- Adds missing recipe templates and empty usage notes. Never changes
-- anything the user edited (Nachtrag 3, 5 last test).
function Kontor:ApplyTemplateExtras()
    local db = self.db
    db.templatesApplied = db.templatesApplied or {}
    for _, t in ipairs(RECIPE_TEMPLATES) do
        -- Each template only once: recipes the user deleted or replaced stay so.
        if not db.templatesApplied[t.key] and db.recipes[t.key] == nil then
            local reagents = {}
            for _, r in ipairs(t.reagents) do
                table.insert(reagents, { itemID = r.itemID, name = r.name, qty = r.qty, vendor = r.vendor })
            end
            db.recipes[t.key] = {
                product = t.product, productName = t.productName, yield = 1, reagents = reagents,
                profession = t.profession, skill = t.skill, source = "vorlage",
            }
        end
        db.templatesApplied[t.key] = true
    end
    for _, basket in ipairs(db.baskets) do
        for itemID, item in pairs(basket.items) do
            if (item.usage == nil or item.usage == "") and USAGE[itemID] then
                item.usage = USAGE[itemID]
            end
        end
    end
end

-- Creates the start baskets. Only when there are no baskets at all.
function Kontor:ApplyStartBaskets()
    if #self.db.baskets > 0 then return false end
    for _, def in ipairs(START_BASKETS) do
        local basket = self:CreateBasket(def.name, def.phase, def.type)
        for _, entry in ipairs(def.items) do
            self:AddBasketItem(basket, entry[1], { fixedPrice = entry[2] })
        end
    end
    self:ApplyTemplateExtras()
    return true
end

Kontor:RegisterEvent("PLAYER_LOGIN", "Körbe", function()
    local db = Kontor.db
    if not db.startBasketsApplied then
        db.startBasketsApplied = true
        if Kontor:ApplyStartBaskets() then
            Kontor:Print("Startkörbe A, B, C, D und W angelegt. /kontor öffnet sie.")
        end
    end
    Kontor:ApplyTemplateExtras()
end)
