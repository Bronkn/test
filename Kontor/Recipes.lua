-- Kontor: recipe calculation (Pflichtenheft 4.7, Nachtrag 1 section 4, Nachtrag 3).
-- Recipes live in KontorDB.recipes, keyed by product item ID (templates
-- without a known product ID use their name as key).
-- Recipe: { product, productName, yield, reagents = { { itemID, name, qty, vendor, fixedPrice } },
--           profession, skill, source = "vorlage"|"manuell"|"berufsfenster" }

local _, Kontor = ...

-- Name of a recipe's product for display.
function Kontor:RecipeName(recipe)
    if recipe.product then
        return (C_Item.GetItemInfo(recipe.product)) or recipe.productName or ("Item " .. recipe.product)
    end
    return recipe.productName or "?"
end

local function reagentName(r)
    if r.itemID then return (C_Item.GetItemInfo(r.itemID)) or r.name or ("Item " .. r.itemID) end
    return r.name or "?"
end
Kontor.ReagentName = function(_, r) return reagentName(r) end

-- Unit price of a reagent: fixed price if set, otherwise a fresh AH price.
local function reagentPrice(self, r)
    if r.fixedPrice then return r.fixedPrice end
    if r.vendor then return nil end -- vendor reagents need a fixed price
    if r.itemID then
        local entry = self:GetPrice(r.itemID)
        if entry and entry.p and self:IsPriceFresh(entry) then return entry.p end
    end
end

-- Full calculation. Result fields:
--   complete (bool), missing (German reason, when incomplete)
--   costAH, costOwn: reagent cost per product unit at AH prices / own cost basis
--   productNet: product price per unit after AH fee
--   margin: productNet - costAH;  factor: productNet / costAH
--   advice: "verarbeiten" | "roh verkaufen"
function Kontor:CalcRecipe(recipe)
    local res = {}
    if not recipe.product then
        res.missing = "Produkt-ID fehlt"
        return res
    end
    local yield = recipe.yield or 1
    local costAH, costOwn = 0, 0
    for _, r in ipairs(recipe.reagents or {}) do
        local price = reagentPrice(self, r)
        if not price then
            res.missing = "kein Preis für " .. reagentName(r)
            return res
        end
        costAH = costAH + price * r.qty
        local own = price
        if r.itemID and not r.fixedPrice then
            local stock, avg = self:GetPosition(r.itemID)
            if stock > 0 and avg then own = avg end
        end
        costOwn = costOwn + own * r.qty
    end
    local entry = self:GetPrice(recipe.product)
    if not entry or not entry.p or not self:IsPriceFresh(entry) then
        res.missing = "kein Preis für das Produkt"
        return res
    end
    res.complete = true
    res.costAH = costAH / yield
    res.costOwn = costOwn / yield
    res.productNet = self:NetPrice(entry.p)
    res.margin = res.productNet - res.costAH
    res.factor = res.costAH > 0 and res.productNet / res.costAH or nil
    res.advice = res.margin > 0 and "verarbeiten" or "roh verkaufen"
    return res
end

-- Professions of all characters of the account (updated on login).
function Kontor:AccountHasProfession(name)
    for _, char in pairs(self.db.chars) do
        if char.professions and char.professions[name] then return true end
    end
    return false
end

-- "Verarbeiten lohnt" signal (Nachtrag 1, 4.1; Nachtrag 3, 2). Returns the
-- signal text or nil. Independent of the phase.
function Kontor:CraftSignal(recipe, calc)
    calc = calc or self:CalcRecipe(recipe)
    if not calc.complete or not calc.factor or calc.factor < self.db.config.craftThreshold then return nil end
    if recipe.profession and not self:AccountHasProfession(recipe.profession) then
        return "Verarbeiten lohnt (fremder Beruf)"
    end
    return "Verarbeiten lohnt"
end

-- Recipes that use itemID directly, or through one intermediate product
-- (Nachtrag 1, 4.4). Returns list of { recipe, via = intermediate recipe or nil }.
function Kontor:RecipesUsing(itemID)
    local direct, list = {}, {}
    for _, recipe in pairs(self.db.recipes) do
        for _, r in ipairs(recipe.reagents or {}) do
            if r.itemID == itemID then
                table.insert(list, { recipe = recipe })
                if recipe.product then direct[recipe.product] = recipe end
                break
            end
        end
    end
    for _, recipe in pairs(self.db.recipes) do
        for _, r in ipairs(recipe.reagents or {}) do
            if r.itemID and direct[r.itemID] and direct[r.itemID] ~= recipe then
                table.insert(list, { recipe = recipe, via = direct[r.itemID] })
                break
            end
        end
    end
    return list
end

-- Shopping list (Nachtrag 1, 4.2) for `count` products, or as many as
-- `budget` copper buys. Returns { count, lines = { { name, itemID, need, have, buy, cost } },
-- cost, revenue, profit } or nil plus reason.
function Kontor:ShoppingList(recipe, count, budget)
    local calc = self:CalcRecipe(recipe)
    if not calc.complete then return nil, calc.missing end
    local yield = recipe.yield or 1
    if budget then
        count = calc.costAH > 0 and math.floor(budget / calc.costAH) or 0
    end
    count = math.max(0, math.floor(count or 0))
    local crafts = math.ceil(count / yield)
    local res = { count = count, lines = {}, cost = 0 }
    for _, r in ipairs(recipe.reagents) do
        local need = crafts * r.qty
        local have = r.itemID and not r.vendor and self:GetCharacterCount(r.itemID) or 0
        local buy = math.max(0, need - have)
        local cost = buy * (reagentPrice(self, r) or 0)
        table.insert(res.lines, { name = reagentName(r), itemID = r.itemID, need = need, have = have, buy = buy, cost = cost })
        res.cost = res.cost + cost
    end
    res.revenue = calc.productNet * count
    res.profit = res.revenue - res.cost
    return res
end

-- Recipe from the profession window (Nachtrag 1, 4.3). Takes a recipe
-- link (Shift-click in the profession window) and replaces any template.
function Kontor:ImportRecipe(link)
    local recipeID = link and tonumber(link:match("enchant:(%d+)") or link:match("trade:[^:]*:(%d+)")
        or link:match("^%s*(%d+)%s*$"))
    if not recipeID then
        return false, "Bitte einen Rezept-Link angeben (Umschalt-Klick auf das Rezept im Berufsfenster)."
    end
    if not (C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic) then
        return false, "Die Berufs-Funktionen fehlen in diesem Client."
    end
    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    if not schematic or not schematic.outputItemID then
        return false, "Rezept nicht lesbar. Ist das Berufsfenster geöffnet?"
    end
    local reagents = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        local first = slot.reagents and slot.reagents[1]
        if first and first.itemID and slot.required ~= false and (slot.quantityRequired or 0) > 0 then
            table.insert(reagents, { itemID = first.itemID, qty = slot.quantityRequired })
        end
    end
    local product = schematic.outputItemID
    -- Templates stored under a name (no product ID) are replaced as well:
    -- matched by name, or by their known reagents all appearing in the import.
    local name = C_Item.GetItemInfo(product)
    local importedIDs = {}
    for _, r in ipairs(reagents) do importedIDs[r.itemID] = true end
    for key, recipe in pairs(self.db.recipes) do
        if type(key) == "string" and recipe.source == "vorlage" then
            local allKnownMatch, anyKnown = true, false
            for _, r in ipairs(recipe.reagents or {}) do
                if r.itemID and not r.vendor then
                    anyKnown = true
                    if not importedIDs[r.itemID] then allKnownMatch = false end
                end
            end
            if key == name or (anyKnown and allKnownMatch) then self.db.recipes[key] = nil end
        end
    end
    local old = self.db.recipes[product] or {}
    -- Fixed prices the user entered for vendor reagents are kept.
    for _, r in ipairs(reagents) do
        for _, o in ipairs(old.reagents or {}) do
            if o.itemID == r.itemID then
                r.fixedPrice, r.vendor = o.fixedPrice, o.vendor
            end
        end
    end
    self.db.recipes[product] = {
        product = product, yield = schematic.quantityMin or 1, reagents = reagents,
        profession = old.profession, skill = old.skill, source = "berufsfenster",
    }
    self:FireChange()
    return true, self:RecipeName(self.db.recipes[product])
end

-- Professions of the logged-in character.
Kontor:RegisterEvent("PLAYER_LOGIN", "Rezepte", function()
    if not GetProfessions then return end
    local profs = {}
    local professions = { GetProfessions() } -- any of the five may be nil
    for i = 1, 5 do
        local index = professions[i]
        if index then
            local name, _, level = GetProfessionInfo(index)
            if name then profs[name] = level end
        end
    end
    local key = (UnitName("player") or "?") .. "-" .. (GetNormalizedRealmName and GetNormalizedRealmName() or "")
    Kontor.db.chars[key] = { professions = profs }
end)
