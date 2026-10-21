import sys, re, os
import lupa.lua51 as L
root = sys.argv[1]; here = os.path.dirname(__file__)
toc = open(os.path.join(root, "Kontor.toc"), encoding="utf-8").read()
files = [l.strip().replace("\\", "/") for l in toc.splitlines() if l.strip() and not l.startswith("#")]

def session(saved=None, realm="ClassicBetaPvP", templates=True):
    lua = L.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(open(os.path.join(here, "wow_mock.lua"), encoding="utf-8").read())
    lua.execute(f'REALM = {"nil" if realm is None else repr(realm)}')
    if not templates: lua.execute("TEMPLATES = {}")
    if saved: lua.execute("KontorDB = " + saved)
    lua.execute("NS = {}")
    for f in files:
        code = open(os.path.join(root, f), encoding="utf-8").read()
        fn = lua.execute("return function(src, name) local chunk, err = loadstring(src, name) if not chunk then error(err) end return chunk end")(code, f)
        fn("Kontor", lua.eval("NS"))
    lua.execute('fire("ADDON_LOADED", "Other") fire("ADDON_LOADED", "Kontor")')
    return lua

def slash(lua, s): lua.execute(f'SlashCmdList.KONTOR({s!r})')
def chat(lua): return list(lua.eval("CHAT").values())

ser = r'''
local function ser(v, ind) ind = ind or ""
  if type(v) == "table" then local o = {"{"} for k, x in pairs(v) do
    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
    o[#o+1] = ind .. "  " .. key .. " = " .. ser(x, ind .. "  ") .. "," end
    o[#o+1] = ind .. "}" return table.concat(o, "\n") end
  if type(v) == "string" then return string.format("%q", v) end return tostring(v) end
return ser(KontorDB)'''

# 1) fresh install, toggle, move, status
s = session()
assert s.eval("KontorDB.version") == 4
slash(s, ""); assert s.eval("KontorMainFrame:IsShown()") is True
slash(s, ""); assert s.eval("KontorMainFrame:IsShown()") is False
slash(s, "")
s.execute("KontorMainFrame._scripts.OnDragStop(KontorMainFrame)")
slash(s, "status")
print("\n".join(chat(s)))
assert any("Markt: ClassicBetaPvP-Horde" in c for c in chat(s))
saved = s.execute(ser)

# 2) reload: position restored, defaults kept
s2 = session(saved)
slash(s2, "")
assert tuple(s2.eval("{KontorMainFrame:GetPoint()}").values()) == ("TOPLEFT", "BOTTOMLEFT", 123, 700), s2.eval("{KontorMainFrame:GetPoint()}")
# 3) errors: testfehler logged, other modules keep working, window shows it, cap 50
slash(s2, "testfehler")
assert s2.eval("#KontorDB.errorLog") == 1
for _ in range(60): slash(s2, "testfehler")
assert s2.eval("#KontorDB.errorLog") == 50
slash(s2, "fehler")
txt = s2.eval("KontorText_errors.editBox._text")
assert "Testfehler" in txt and "Kontor 0.1.0" in txt
slash(s2, "quatsch"); assert any("Unbekannter Befehl" in c for c in chat(s2))
s2.execute('StaticPopup_Show("KONTOR_CLEAR_ERRORS")'); assert s2.eval("#KontorDB.errorLog") == 0
# 4) v1 migration keeps data, moves recipes
s3 = session('{ version = 1, config = { ahFee = 0.07 }, baskets = { { id = 1, name = "X", recipes = { { product = 249410, yield = 1 } } } }, ledger = { { qty = 5 } } }')
assert s3.eval("KontorDB.version") == 4 and s3.eval("KontorDB.config.ahFee") == 0.07
assert s3.eval("KontorDB.config.craftThreshold") == 1.5 and s3.eval("KontorDB.recipes[249410].yield") == 1
assert s3.eval("#KontorDB.ledger") == 1 and s3.eval("KontorDB.baskets[1].name") == "X"
# 5) fallback window + unknown realm
s4 = session(realm=None, templates=False); slash(s4, ""); slash(s4, "status")
assert any("Classic Beta PvP".replace(" ", "") in c for c in chat(s4)), chat(s4)
print("ALLE TESTS OK")
