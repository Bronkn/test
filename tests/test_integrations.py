import sys, os, time as _t
src = open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0]
# Baganator/Syndicator exist before Kontor loads (OptionalDeps)
src = src.replace('lua.execute("NS = {}")', """lua.execute('''
WIDGETS = {} REFRESHES = 0
Baganator = { API = {
  RegisterCornerWidget = function(label, id, onUpdate, onInit, pos) WIDGETS[id] = { label = label, update = onUpdate, init = onInit, pos = pos } end,
  RequestItemButtonsRefresh = function() REFRESHES = REFRESHES + 1 end } }
Syndicator = { API = { IsReady = function() return true end,
  GetInventoryInfoByItemID = function(id) return { characters = { { bags = 3, bank = 2, mail = 1, auctions = 0, equipped = 0 }, { bags = 4 } }, warband = { 0 } } end } }
''')
    lua.execute("NS = {}")""")
exec(src)
now = int(_t.time())
s = session()
s.execute("function time() return %d end" % now)
s.execute('fire("PLAYER_LOGIN")')
ids = sorted(s.eval("WIDGETS").keys()); print("Widgets:", ids)
assert ids == ["kontor_ah", "kontor_basket", "kontor_disenchant", "kontor_vendor"]
s.execute('''ITEMS[10]={name="Billig",sell=96} ITEMS[11]={name="Teuer",sell=5} ITEMS[30]={name="Helm",sell=20,quality=2,ilvl=22,classID=4} ITEMS[10940]={name="Staub",sell=0}
local p = NS:GetMarketData(true).prices
p[10] = { p = 100, q = 1, t = %d } p[11] = { p = 50000, q = 1, t = %d } p[10940] = { p = 10000, q = 1, t = %d }
for i=1,10 do local e={t=1,itemID=30,quality=2,ilvl=22,class="armor",results={[10940]=2},salvager=false} table.insert(KontorDB.deLog,e) NS:OnDisenchantLogged(e) end''' % (now, now, now))
def w(id, d):
    return s.eval('WIDGETS.%s.update(nil, %s)' % (id, d))
assert w("kontor_vendor", '{itemID=10, quality=1}') is True
assert w("kontor_vendor", '{itemID=11, quality=1}') is False
assert w("kontor_ah", '{itemID=11, quality=1}') is True
assert w("kontor_disenchant", '{itemID=30, quality=2}') is True
assert w("kontor_basket", '{itemID=249391}') is True and w("kontor_basket", '{itemID=10}') is False
assert w("kontor_vendor", '{}') is False
s.execute('WIDGETS.kontor_disenchant.init(CreateFrame("Button"))')
s.execute('NS:FireChange() runTimers()'); assert s.eval("REFRESHES") >= 1
txt = s.eval('NS:AccountCountText(249391)'); print(txt); assert "10" in txt
s.execute('NS:ShowItemDetail(KontorDB.baskets[1].id, 249391)')
assert "Syndicator" in s.eval('KontorItemDetail.position._text')
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("INTEGRATION-TESTS OK")
