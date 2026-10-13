-- Kontor: price and quantity history of watchlist items (Pflichtenheft 4.5, M7).
-- One point per complete scan and item, at most one per hour; points older
-- than 14 days are thinned out to one per day.

local _, Kontor = ...

local HOUR, DAY = 3600, 86400
local COMPACT_AFTER = 14 * DAY

local function compact(points, now)
    local kept, lastDay = {}, nil
    -- Walk backwards so the last point of each old day survives.
    for i = #points, 1, -1 do
        local p = points[i]
        if now - p.t <= COMPACT_AFTER then
            table.insert(kept, 1, p)
        else
            local day = math.floor(p.t / DAY)
            if day ~= lastDay then
                table.insert(kept, 1, p)
                lastDay = day
            end
        end
    end
    return kept
end

-- Called by the scan after a complete run. seen[itemID] = true for items
-- found in this scan.
function Kontor:RecordHistory(marketData, scanTime, seen)
    marketData.history = marketData.history or {}
    for _, basket in ipairs(self.db.baskets) do
        for itemID in pairs(basket.items) do
            local entry = marketData.prices[itemID]
            local point
            if seen[itemID] and entry then
                point = { t = scanTime, p = entry.p, q = entry.q }
            elseif entry then
                point = { t = scanTime, p = entry.p, q = 0 } -- not listed (Pflichtenheft 4.1)
            end
            if point then
                local list = marketData.history[itemID] or {}
                marketData.history[itemID] = list
                local last = list[#list]
                if last and math.floor(last.t / HOUR) == math.floor(point.t / HOUR) then
                    list[#list] = point -- a later scan in the same hour replaces the point
                else
                    table.insert(list, point)
                end
                marketData.history[itemID] = compact(list, scanTime)
            end
        end
    end
end

function Kontor:GetHistory(itemID)
    local data = self:GetMarketData(false)
    return data and data.history and data.history[itemID] or {}
end

-- Min, max and mean of price and quantity over the last `days` days.
function Kontor:HistoryStats(itemID, days)
    local since = time() - days * DAY
    local s = { n = 0 }
    local sumP, sumQ = 0, 0
    for _, p in ipairs(self:GetHistory(itemID)) do
        if p.t >= since then
            s.n = s.n + 1
            if p.q > 0 then
                s.minP = math.min(s.minP or p.p, p.p)
                s.maxP = math.max(s.maxP or p.p, p.p)
                sumP = sumP + p.p
                s.nP = (s.nP or 0) + 1
            end
            s.minQ = math.min(s.minQ or p.q, p.q)
            s.maxQ = math.max(s.maxQ or p.q, p.q)
            sumQ = sumQ + p.q
        end
    end
    if s.nP then s.avgP = sumP / s.nP end
    if s.n > 0 then s.avgQ = sumQ / s.n end
    return s
end

-- Trend of price and quantity: change against the previous point and
-- against the 7-day average, as fractions (0.1 = +10 %). nil if unknown.
function Kontor:GetTrend(itemID)
    local points = self:GetHistory(itemID)
    local last, prev = points[#points], points[#points - 1]
    local t = {}
    if last and prev then
        if prev.p and prev.p > 0 and last.q > 0 and prev.q > 0 then t.pPrev = last.p / prev.p - 1 end
        if prev.q > 0 then t.qPrev = last.q / prev.q - 1 end
    end
    local week = self:HistoryStats(itemID, 7)
    if last and week.avgP and week.avgP > 0 and last.q > 0 then t.pWeek = last.p / week.avgP - 1 end
    if last and week.avgQ and week.avgQ > 0 then t.qWeek = last.q / week.avgQ - 1 end
    return t
end
