import sys, os
exec(open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0])
import time as _t
now = int(_t.time())
saved = '{ version = 3, markets = { ["ClassicBetaPvP-Horde"] = { prices = { [10] = { p = 100, q = 5, t = %d, listed = true }, [11] = { p = 1000, q = 5, t = %d, listed = true }, [12] = { p = 100, q = 5, t = %d, listed = true }, [13] = { p = 100, q = 1, t = %d, listed = false } }, history = {} } } }' % (now-600, now-600, now-3*86400, now-30*3600)
s = session(saved)
s.execute("function time() return %d end" % now)
s.execute('ITEMS[10]={name="Billig",sell=96} ITEMS[11]={name="Teuer",sell=50} ITEMS[12]={name="Alt",sell=500} ITEMS[13]={name="Grau",sell=200} ITEMS[14]={name="OhnePreis",sell=500} ITEMS[15]={name="Gebunden",sell=500} ITEMS[16]={name="Blau",sell=500,quality=3} ITEMS[17]={name="Quest",sell=500}')
s.execute('fire("PLAYER_LOGIN")')
# --- M3 tooltip
tt = lambda id, combat=False: list(s.eval(f'(function() COMBAT={str(combat).lower()} local t=makeTooltip() TOOLTIP_CALLS[0](t, {{id={id}}}) COMBAT=false return t.lines end)()').values())
print("TT10", tt(10)); assert "AH-Tiefstpreis" in tt(10)[0] and "vor 10 Min." in tt(10)[0]
assert tt(14) == [] and tt(10, True) == []
print("TT13", tt(13)); assert "zuletzt nicht gelistet" in tt(13)[0]
slash(s, "tooltip"); assert tt(10) == []; slash(s, "tooltip")
# --- M4 cleanup: candidates
s.execute('''BAGS={} bagItem(1,10,4) bagItem(2,11,1) bagItem(3,12,1) bagItem(4,14,1) bagItem(5,15,1,{bound=true}) bagItem(6,16,1,{quality=3}) bagItem(7,10,2,{quality=0}) bagItem(8,10,1,{noValue=true})''')
s.execute('ITEMS[17]={name="Quest",sell=500} KontorDB.markets["ClassicBetaPvP-Horde"].prices[17]={p=10,q=1,t=%d} bagItem(9,17,1) QUESTSLOT=9' % now)
c = s.eval("(NS:FindCleanupCandidates())")
ids = [c[i].itemID for i in range(1, len(c)+1)]
print("Kandidaten", ids); assert ids == [10]  # 96 >= 100*0.95
s.execute('fire("MERCHANT_SHOW")')
lbl = [x for x in s.eval("(function() local r={} for _,f in ipairs(FRAMES) do local x=rawget(f,'_text') if type(x)=='string' and x:find('Aufräumen') then table.insert(r,x) end end return r end)()").values()]
print(lbl)
s.execute("NS:ShowCleanupPreview()")
assert s.eval("KontorCleanupFrame:IsShown()") is True
s.execute("KontorCleanupFrame.rows[1].check._checked=false NS:SellChecked()")
assert s.eval("SOLD") is None, "unchecked must not sell"
s.execute("NS:ShowCleanupPreview() NS:SellChecked()")
assert list(s.eval("SOLD").values()) == [1]; print(chat(s)[-1])
# never sell
s.execute("bagItem(1,10,4) NS:ShowCleanupPreview() StaticPopupDialogs.KONTOR_NEVER_SELL.OnAccept(nil, 10)")
assert s.eval("KontorDB.exclusions[10]") is True and s.eval("#(NS:FindCleanupCandidates())") == 0
# selling when merchant closed must not use items
s.execute('KontorDB.exclusions[10]=nil SOLD=nil NS:ShowCleanupPreview() fire("MERCHANT_CLOSED") NS.merchantOpen=true MerchantFrame._shown=false NS:SellChecked()')
assert s.eval("SOLD") is None; print(chat(s)[-1])
s.execute('MerchantFrame._shown=true')
# >12 stacks
s.execute('BAGS={} for i=1,15 do bagItem(i,10,1) end fire("MERCHANT_SHOW") NS:ShowCleanupPreview()')
print(s.eval("KontorCleanupFrame.more._text"))
# --- M5 depth
s.execute('fire("AUCTION_HOUSE_SHOW") DEPTH={ {unitPrice=90,quantity=1}, {unitPrice=120,quantity=10}, {unitPrice=120,quantity=5}, {unitPrice=150,quantity=30} }')
slash(s, "tiefe 10"); s.execute('fire("COMMODITY_SEARCH_RESULTS_UPDATED", 10)')
print("\n".join(chat(s)[-6:]))
# --- M5 purchase
s.execute('C_AuctionHouse.StartCommoditiesPurchase(10, 5) fire("COMMODITY_PRICE_UPDATED", 120, 600) C_AuctionHouse.ConfirmCommoditiesPurchase(10, 5) fire("COMMODITY_PURCHASE_SUCCEEDED")')
print(chat(s)[-1]); assert "× 5 für" in chat(s)[-1]
s.execute('C_AuctionHouse.StartCommoditiesPurchase(10, 2) fire("COMMODITY_PURCHASE_FAILED")'); print(chat(s)[-1])
# --- M5b disenchant (bag diff)
s.execute('ITEMS[20]={name="Grüne Hose",sell=50,quality=2,ilvl=23,minLevel=18,classID=4} BAGS={} bagItem(1,20,1,{quality=2}) bagItem(2,10,5)')
# item removed before loot
s.execute('fire("UNIT_SPELLCAST_SENT","player","","g",13262) fire("UNIT_SPELLCAST_SUCCEEDED","player","g",13262) BAGS[0][1]=nil LOOT={{5000,2}} fire("LOOT_READY") fire("LOOT_OPENED")')
print(chat(s)[-1]); assert s.eval("#KontorDB.deLog") == 1
e = "KontorDB.deLog[1]"
assert s.eval(f"{e}.itemID") == 20 and s.eval(f"{e}.ilvl") == 23 and s.eval(f"{e}.class") == "armor" and s.eval(f"{e}.skill") == 42 and s.eval(f"{e}.results[5000]") == 2 and s.eval(f"{e}.auras[1]") == 777
# item removed only after loot, loot lands in the same slot (autoloot)
s.execute('bagItem(1,20,1,{quality=2}) fire("BAG_UPDATE_DELAYED") fire("UNIT_SPELLCAST_SUCCEEDED","player","g",13262) LOOT={{5000,3}} fire("LOOT_READY")')
assert s.eval("#KontorDB.deLog") == 1
s.execute('bagItem(1,5000,3) fire("BAG_UPDATE_DELAYED")')
print(chat(s)[-1]); assert s.eval("#KontorDB.deLog") == 2 and s.eval("KontorDB.deLog[2].itemID") == 20
# mob loot: nothing
s.execute('LOOTSOURCE="Creature-0-1" LOOT={{2589,3}} fire("LOOT_READY")'); assert s.eval("#KontorDB.deLog") == 2
s.execute('LOOTSOURCE="Item-1"')
# failure with error message
s.execute('fire("UNIT_SPELLCAST_SENT","player","","g",13262) fire("UI_ERROR_MESSAGE", 1, "Eure Fertigkeit ist zu niedrig.") fire("UNIT_SPELLCAST_FAILED","player","g",13262)')
assert s.eval("#KontorDB.deFailures") == 1; print(chat(s)[-1])
# interrupted without message: not logged
s.execute('fire("UNIT_SPELLCAST_START","player","g",13262) fire("UNIT_SPELLCAST_INTERRUPTED","player","g",13262)'); assert s.eval("#KontorDB.deFailures") == 1
# nothing vanishes: after the wait the entry is dropped with a message
s.execute('BAGS={} bagItem(2,10,5) fire("UNIT_SPELLCAST_SENT","player","","g",13262) fire("UNIT_SPELLCAST_SUCCEEDED","player","g",13262) LOOT={{5000,1}} fire("LOOT_READY") runTimers()')
print(chat(s)[-1]); assert "nicht eindeutig" in chat(s)[-1] and s.eval("#KontorDB.deLog") == 2
# other spell ignored
s.execute('fire("UNIT_SPELLCAST_SUCCEEDED","player","g",999)')
slash(s, "salvager"); slash(s, "entzauber export")
print(s.eval("KontorText_deExport.editBox._text"))
assert s.eval("KontorDB.config.enchanterName") == "Bankchar"
slash(s, "status"); print("\n".join(chat(s)[-8:]))
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("M3-M5b TESTS OK")
