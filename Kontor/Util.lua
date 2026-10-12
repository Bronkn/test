-- Kontor: small formatting helpers.

local _, Kontor = ...

function Kontor:FormatDateTime(t)
    if not t then return "–" end
    return date("%d.%m.%Y %H:%M", t)
end

function Kontor:CountKeys(tbl)
    local n = 0
    if tbl then
        for _ in pairs(tbl) do n = n + 1 end
    end
    return n
end
