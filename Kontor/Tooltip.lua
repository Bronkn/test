-- Kontor: price line on item tooltips (Pflichtenheft 4.2).
-- Never runs in combat; any failure there means no line, not an error.

local _, Kontor = ...

local STALE_AFTER = 24 * 3600
local COLOR = { 0.55, 0.8, 1 }
local GREY = { 0.5, 0.5, 0.5 }

local reportedError = false

local function getItemID(tooltip, data)
    if data and type(data.id) == "number" then
        return data.id
    end
    if tooltip.GetItem then
        local _, link = tooltip:GetItem()
        return Kontor:ParseItemID(link)
    end
end

local function addLines(tooltip, data)
    local db = Kontor.db
    if not db or not db.config.tooltipEnabled then return end

    local itemID = getItemID(tooltip, data)
    if not itemID then return end

    local entry = Kontor:GetPrice(itemID)
    local basket = Kontor:FindBasketItem(itemID)

    if entry and entry.p then
        local text = "AH-Tiefstpreis: " .. Kontor:FormatMoney(entry.p) .. " · " .. Kontor:FormatAge(entry.t)
        if entry.listed == false then
            text = text .. " (zuletzt nicht gelistet)"
        end
        local color = (time() - (entry.t or 0) > STALE_AFTER) and GREY or COLOR
        tooltip:AddLine(text, color[1], color[2], color[3])
    elseif basket then
        tooltip:AddLine("AH: kein Preis im letzten Scan", GREY[1], GREY[2], GREY[3])
    end
    -- Basket, cost basis, target price and signals follow with M6/M8/M10.
end

local function onTooltip(tooltip, data)
    if InCombatLockdown() then return end
    local ok, err = pcall(addLines, tooltip, data)
    if not ok and not reportedError then
        reportedError = true -- log once per session, tooltips fire constantly
        Kontor:LogError("Tooltip", err)
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onTooltip)
end
