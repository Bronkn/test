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

-- Bound according to the tooltip lines (the tooltip data has no flag for it).
local function isBound(data)
    for _, line in ipairs(data and data.lines or {}) do
        local text = line.leftText
        if text and (text == ITEM_SOULBOUND or text == ITEM_ACCOUNTBOUND or text == ITEM_BNETACCOUNTBOUND) then
            return true
        end
    end
    return false
end

local function addLines(tooltip, data)
    local db = Kontor.db
    if not db or not db.config.tooltipEnabled then return end

    local itemID = getItemID(tooltip, data)
    if not itemID then return end

    local entry = Kontor:GetPrice(itemID)
    local basket, item = Kontor:FindBasketItem(itemID)

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

    if basket then
        local stock, avg = Kontor:GetPosition(itemID)
        local parts = { "Korb: " .. basket.name }
        if stock > 0 then
            table.insert(parts, "Bestand " .. stock .. (avg and (", Einstand " .. Kontor:FormatMoney(avg)) or ""))
        end
        local target = Kontor:EffectiveTarget(item)
        if target then table.insert(parts, "Ziel " .. Kontor:FormatMoney(target)) end
        tooltip:AddLine(table.concat(parts, " · "), COLOR[1], COLOR[2], COLOR[3])
        if item.fixedPrice then
            tooltip:AddLine("Festpreis NPC: " .. Kontor:FormatMoney(item.fixedPrice), COLOR[1], COLOR[2], COLOR[3])
        end
    end

    local sig = Kontor:SignalForItem(itemID)
    if sig and sig.kind then
        tooltip:AddLine("Signal: " .. Kontor:SignalText(sig))
    end

    if db.config.deTooltip then
        local link = data and data.hyperlink or (tooltip.GetItem and select(2, tooltip:GetItem()))
        local advice = Kontor:DisenchantAdvice(link or itemID, isBound(data))
        if advice then
            if advice.de then
                local c = advice.uncertain and GREY or COLOR
                tooltip:AddLine("Entzaubern: ~" .. Kontor:FormatMoney(advice.de) .. " (n=" .. advice.n .. ")"
                    .. (advice.priced and "" or " (Materialpreise fehlen)")
                    .. " · Empfehlung: " .. advice.advice, c[1], c[2], c[3])
            else
                tooltip:AddLine("Entzaubern: noch keine Daten", GREY[1], GREY[2], GREY[3])
            end
        end
    end

    -- Usage note as the last line (Nachtrag 3, 3)
    if basket and item.usage and item.usage ~= "" and db.config.usageTooltip then
        tooltip:AddLine("Verwendung: " .. item.usage, 0.8, 0.8, 0.8, true)
    end
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
