-- Kontor: core namespace, error capture and event dispatch.
-- Every handler runs through SafeCall, so an error in one module is logged
-- and cannot stop the others (Pflichtenheft 6.2, 6.4).

local ADDON_NAME, Kontor = ...

Kontor.name = ADDON_NAME

local MAX_ERRORS = 50
local ERROR_NOTICE_INTERVAL = 10 -- seconds between chat notices about new errors

local pendingErrors = {} -- errors raised before KontorDB is available
local lastErrorNotice = 0

function Kontor:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffKontor:|r " .. tostring(msg))
end

function Kontor:GetVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return (getMetadata and getMetadata(ADDON_NAME, "Version")) or "?"
end

-- Errors -------------------------------------------------------------------

function Kontor:LogError(module, message)
    local entry = { t = time(), module = module or "?", msg = tostring(message) }

    local db = self.db
    if db and db.errorLog then
        table.insert(db.errorLog, entry)
        while #db.errorLog > MAX_ERRORS do
            table.remove(db.errorLog, 1)
        end
    else
        table.insert(pendingErrors, entry)
    end

    local now = GetTime()
    if now - lastErrorNotice >= ERROR_NOTICE_INTERVAL then
        lastErrorNotice = now
        self:Print("|cffff5555Fehler im Modul '" .. entry.module .. "'.|r Details mit /kontor fehler.")
    end

    if self.OnErrorLogged then
        self:OnErrorLogged()
    end
end

-- Moves errors that happened before the database was loaded into it.
function Kontor:FlushPendingErrors()
    local db = self.db
    for _, entry in ipairs(pendingErrors) do
        table.insert(db.errorLog, entry)
    end
    wipe(pendingErrors)
    while #db.errorLog > MAX_ERRORS do
        table.remove(db.errorLog, 1)
    end
end

local function errorHandler(err)
    local stack = debugstack and debugstack(2, 8, 0) or ""
    return tostring(err) .. "\n" .. stack
end

-- Runs fn(...) protected. On error the message goes to the error log.
-- Returns true plus fn's results, or false.
function Kontor:SafeCall(module, fn, ...)
    local n = select("#", ...)
    local args = { ... }
    local results = { xpcall(function() return fn(unpack(args, 1, n)) end, errorHandler) }
    if not results[1] then
        self:LogError(module, results[2])
        return false
    end
    return unpack(results)
end

-- Events -------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {} -- event -> list of { module, fn }

function Kontor:RegisterEvent(event, module, fn)
    if not handlers[event] then
        -- An event missing in this client must not stop the rest of the addon.
        local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok then
            self:LogError(module, "Event " .. event .. " unbekannt: " .. tostring(err))
            return
        end
        handlers[event] = {}
    end
    table.insert(handlers[event], { module = module, fn = fn })
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for _, h in ipairs(list) do
        Kontor:SafeCall(h.module, h.fn, event, ...)
    end
end)

-- Market key ---------------------------------------------------------------

-- Realm name plus faction, e.g. "ClassicBetaPvP-Horde" (see API-NOTIZEN.md).
-- Returns nil while the client cannot tell yet (very early during login).
function Kontor:GetMarketKey()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    if not realm or realm == "" then
        realm = GetRealmName and GetRealmName()
        realm = realm and realm:gsub("[%s%-]", "")
    end
    local faction = UnitFactionGroup("player")
    if not realm or realm == "" or not faction then
        return nil
    end
    return realm .. "-" .. faction
end

-- hooksecurefunc that logs instead of failing when the function is missing
-- in this client. The hook itself runs protected as well.
function Kontor:SecureHook(tbl, name, module, fn)
    if type(tbl) ~= "table" or type(tbl[name]) ~= "function" then
        self:LogError(module, "Funktion " .. name .. " fehlt, Hook nicht gesetzt.")
        return
    end
    hooksecurefunc(tbl, name, function(...)
        Kontor:SafeCall(module, fn, ...)
    end)
end
