-- Kontor: disenchant evaluation and recommendation (Nachtrag 2, sections 3.1-3.3, 4, 5; M11).
-- Group = quality × class × item level band of 5 (× salvager on/off).
-- KontorDB.deStats[group] = { n, mats = { [itemID] = { drops, total } } } is
-- kept as running sums, so old log entries can be dropped (20,000 cap).
--
-- Import/export format, one group per line:
--   Qualität;Klasse;Stufe von-bis;n;Material=Wahrscheinlichkeit*Menge,...
--   2;Rüstung;21-25;40;10940=0.75*1.5,10938=0.22*1.2
-- Klasse: Rüstung | Waffe. Optional fifth field "Salvager" marks salvager groups.

local _, Kontor = ...

local DISENCHANT = 13262
local LOG_CAP = 20000
local CLASS_OF = { [2] = "weapon", [4] = "armor" }
local CLASS_TEXT = { armor = "Rüstung", weapon = "Waffe" }
local CLASS_KEY = { ["Rüstung"] = "armor", ["Waffe"] = "weapon" }

local function band(ilvl)
    local low = math.floor(((ilvl or 1) - 1) / 5) * 5 + 1
    return low, low + 4
end

local function groupKey(quality, class, ilvl, salvager)
    local low = band(ilvl)
    return quality .. ":" .. class .. ":" .. low .. (salvager and ":s" or "")
end

function Kontor:AddDisenchantStats(entry)
    if not entry.quality or not entry.ilvl or not CLASS_TEXT[entry.class] then return end
    local key = groupKey(entry.quality, entry.class, entry.ilvl, entry.salvager)
    local g = self.db.deStats[key] or { n = 0, mats = {} }
    self.db.deStats[key] = g
    g.n = g.n + 1
    for itemID, qty in pairs(entry.results or {}) do
        local m = g.mats[itemID] or { drops = 0, total = 0 }
        g.mats[itemID] = m
        m.drops = m.drops + 1
        m.total = m.total + qty
    end
end

-- New log entry: add to the sums, drop the oldest entries above the cap.
function Kontor:OnDisenchantLogged(entry)
    self:AddDisenchantStats(entry)
    local log = self.db.deLog
    while #log > LOG_CAP do table.remove(log, 1) end
    -- New materials go to basket "E - Verzauberung" (Nachtrag 2, 9).
    for itemID in pairs(entry.results or {}) do
        if not self:FindBasketItem(itemID) then
            local basket
            for _, b in ipairs(self.db.baskets) do
                if b.name == "E - Verzauberung" then basket = b end
            end
            basket = basket or self:CreateBasket("E - Verzauberung", "beobachten", "lager")
            self:AddBasketItem(basket, itemID, {})
            self:Print("Neues Material " .. self:ItemLabel(itemID) .. " in Korb \"E - Verzauberung\" aufgenommen.")
        end
    end
    self:FireChange()
end

-- Group data for a key: own data with n >= minimum, else the imported table,
-- else own data with few samples. Returns { n, mats = { [id] = { p, avg } }, source }.
local function groupData(self, key)
    local own = self.db.deStats[key]
    local min = self.db.config.deMinSamples
    local function fromOwn()
        local mats = {}
        for id, m in pairs(own.mats) do
            mats[id] = { p = m.drops / own.n, avg = m.total / m.drops }
        end
        return { n = own.n, mats = mats, source = "eigene Daten" }
    end
    if own and own.n >= min then return fromOwn() end
    local imported = self.db.deImport[key]
    if imported then return { n = imported.n, mats = imported.mats, source = "Starttabelle" } end
    if own and own.n > 0 then return fromOwn() end
end

-- Expected net AH value of disenchanting one item of the group.
local function expectedValue(self, data)
    local value, priced = 0, true
    for id, m in pairs(data.mats) do
        local entry = self:GetPrice(id)
        if entry and entry.p and self:IsPriceFresh(entry) then
            value = value + m.p * m.avg * self:NetPrice(entry.p)
        else
            priced = false
        end
    end
    return value, priced
end

function Kontor:IsEnchanter()
    return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(DISENCHANT) or false
end

-- Disenchant assessment of an item (link or ID). Returns nil if the item
-- cannot be disenchanted or is excluded, otherwise
--   { vendor, ah, de, n, uncertain, priced, advice }
-- advice: "Entzaubern" | "Entzaubern? (unsicher)" | "an Bankchar schicken" | "AH" | "Händler" | nil
function Kontor:DisenchantAdvice(itemOrLink, isBound)
    local _, _, quality, ilvl, _, _, _, _, _, _, sellPrice, classID = C_Item.GetItemInfo(itemOrLink)
    local class = CLASS_OF[classID]
    if not class or not quality or quality < 2 then return nil end
    local itemID = type(itemOrLink) == "number" and itemOrLink or self:ParseItemID(itemOrLink)
    if quality > self.db.config.deMaxQuality and not self.db.deRelease[itemID] then return nil end
    if C_Item.GetDetailedItemLevelInfo and type(itemOrLink) == "string" then
        ilvl = C_Item.GetDetailedItemLevelInfo(itemOrLink) or ilvl
    end

    local res = { vendor = sellPrice or 0 }
    if not isBound then
        local entry = self:GetPrice(itemID)
        if entry and entry.p and self:IsPriceFresh(entry) and entry.listed ~= false then
            res.ah = self:NetPrice(entry.p)
        end
    end

    local salvager = self.db.config.salvagerActive and true or false
    local data = groupData(self, groupKey(quality, class, ilvl, salvager))
        or (salvager and groupData(self, groupKey(quality, class, ilvl, false)))
    if not data then return res end
    res.n = data.n
    res.de, res.priced = expectedValue(self, data)
    res.uncertain = data.n < self.db.config.deMinSamples

    local best = math.max(res.vendor, res.ah or 0)
    local enchanter = self:IsEnchanter()
    if isBound and not enchanter then
        -- bound items cannot be mailed: only vendor (or AH) counts (Nachtrag 2, 5)
    elseif res.de > best * (1 + self.db.config.deMinAdvantage) then
        if res.uncertain then
            res.advice = "Entzaubern? (unsicher)"
        elseif not enchanter then
            res.advice = "an Bankchar schicken"
        else
            res.advice = "Entzaubern"
        end
    end
    if not res.advice then
        res.advice = (res.ah and res.ah > res.vendor) and "AH" or "Händler"
    end
    return res
end

-- True if the cleanup must keep this item back (Nachtrag 2, 6, condition 8).
function Kontor:HoldBackForDisenchant(link, isBound)
    local a = self:DisenchantAdvice(link, isBound)
    return a and (a.advice == "Entzaubern" or a.advice == "Entzaubern? (unsicher)" or a.advice == "an Bankchar schicken")
end

-- Export / import -------------------------------------------------------------

function Kontor:BuildDisenchantTable()
    local keys = {}
    for key in pairs(self.db.deStats) do table.insert(keys, key) end
    table.sort(keys)
    local lines = { "# Kontor Entzauber-Tabelle (eigene Daten)",
        "# Qualität;Klasse;Stufe;n;Material=Wahrscheinlichkeit*Menge,...;Salvager" }
    for _, key in ipairs(keys) do
        local g = self.db.deStats[key]
        local q, class, low, s = key:match("^(%d+):(%a+):(%d+):?(s?)$")
        local mats = {}
        for id, m in pairs(g.mats) do
            local name = C_Item.GetItemInfo(id)
            table.insert(mats, string.format("%d=%.2f*%.2f", id, m.drops / g.n, m.total / m.drops)
                .. (name and (" (" .. name .. ")") or ""))
        end
        table.sort(mats)
        table.insert(lines, table.concat({ q, CLASS_TEXT[class] or class, low .. "-" .. (low + 4), g.n,
            table.concat(mats, ","), s == "s" and "Salvager" or "" }, ";"))
    end
    return table.concat(lines, "\n")
end

-- Parses the import text. Returns number of groups or nil plus error.
function Kontor:ImportDisenchantTable(text)
    local imported, count = {}, 0
    local lineNo = 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        lineNo = lineNo + 1
        line = strtrim(line)
        if line ~= "" and not line:match("^#") then
            local q, class, low, n, mats, salv = line:match("^(%d+);([^;]+);(%d+)%-%d+;(%d+);([^;]*);?(.*)$")
            local classKey = class and CLASS_KEY[strtrim(class)]
            if not q or not classKey then
                return nil, "Zeile " .. lineNo .. " nicht lesbar: " .. line
            end
            local group = { n = tonumber(n), mats = {} }
            for id, p, avg in mats:gmatch("(%d+)=([%d%.]+)%*([%d%.]+)") do
                group.mats[tonumber(id)] = { p = tonumber(p), avg = tonumber(avg) }
            end
            local key = tonumber(q) .. ":" .. classKey .. ":" .. tonumber(low)
                .. (strtrim(salv or "") == "Salvager" and ":s" or "")
            imported[key] = group
            count = count + 1
        end
    end
    if count == 0 then return nil, "Keine Gruppen gefunden." end
    self.db.deImport = imported
    self:FireChange()
    return count
end

-- Rebuild the sums once from the log (log written before 0.5.0).
Kontor:RegisterEvent("PLAYER_LOGIN", "Entzauber-Auswertung", function()
    local db = Kontor.db
    if not db.deStatsBuilt then
        wipe(db.deStats)
        for _, entry in ipairs(db.deLog) do Kontor:AddDisenchantStats(entry) end
        db.deStatsBuilt = true
    end
end)
