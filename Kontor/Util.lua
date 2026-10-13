-- Kontor: small formatting helpers.

local _, Kontor = ...

function Kontor:FormatDateTime(t)
    if not t then return "-" end
    return date("%d.%m.%Y %H:%M", t)
end

function Kontor:CountKeys(tbl)
    local n = 0
    if tbl then
        for _ in pairs(tbl) do n = n + 1 end
    end
    return n
end

local GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

-- Coins with icons. Below 1 gold: silver and copper; from 1 gold on the
-- copper is left out (Pflichtenheft 6.3).
function Kontor:FormatMoney(copper)
    if not copper then return "-" end
    copper = math.floor(copper + 0.5)
    local g = math.floor(copper / 10000)
    local s = math.floor(copper / 100) % 100
    local c = copper % 100
    if g > 0 then
        if s > 0 then
            return g .. GOLD .. " " .. s .. SILVER
        end
        return g .. GOLD
    end
    if s > 0 then
        if c > 0 then
            return s .. SILVER .. " " .. c .. COPPER
        end
        return s .. SILVER
    end
    return c .. COPPER
end

-- "vor 12 Min.", "vor 3 Std.", "vor 4 Tagen" (Pflichtenheft 4.2).
function Kontor:FormatAge(t)
    if not t then return "-" end
    local seconds = math.max(0, time() - t)
    if seconds < 60 then
        return "gerade eben"
    elseif seconds < 3600 then
        return "vor " .. math.floor(seconds / 60) .. " Min."
    elseif seconds < 48 * 3600 then
        return "vor " .. math.floor(seconds / 3600) .. " Std."
    end
    local days = math.floor(seconds / 86400)
    return "vor " .. days .. (days == 1 and " Tag" or " Tagen")
end

-- Short age for table columns: "jetzt", "12 Min.", "3 Std.", "4 T."
function Kontor:FormatAgeShort(t)
    if not t then return "-" end
    local seconds = math.max(0, time() - t)
    if seconds < 60 then return "jetzt" end
    if seconds < 3600 then return math.floor(seconds / 60) .. " Min." end
    if seconds < 48 * 3600 then return math.floor(seconds / 3600) .. " Std." end
    return math.floor(seconds / 86400) .. " T."
end

function Kontor:FormatDuration(seconds)
    seconds = math.floor(seconds or 0)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Item ID from an item link, "item:123" string or plain number.
function Kontor:ParseItemID(text)
    if not text then return nil end
    local id = text:match("item:(%d+)") or text:match("^%s*(%d+)%s*$")
    return id and tonumber(id)
end

-- True for values the client hides from addons (secret values, e.g. in combat).
function Kontor:IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) or false
end

-- Item link if known, otherwise "Item 123".
function Kontor:ItemLabel(itemID)
    local link = itemID and select(2, C_Item.GetItemInfo(itemID))
    return link or ("Item " .. tostring(itemID))
end
