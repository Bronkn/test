import sys, os, time as _t
exec(open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0])
now = int(_t.time())
s = session('{ version = 3, markets = { ["ClassicBetaPvP-Horde"] = { prices = { [10] = { p = 10000, q = 5, t = %d }, [11] = { p = 100, q = 5, t = %d }, [12] = { p = 50000, q = 5, t = %d }, [13] = { p = 3000, q = 1, t = %d, listed = false }, [14] = { p = 500, q = 1, t = %d } } } } }' % (now-600, now-600, now-600, now-600, now-600))
s.execute("function time() return %d end" % now)
s.execute('''
ITEMS[10]={name="Pyrit",sell=5} ITEMS[11]={name="Billig",sell=96} ITEMS[12]={name="Gebunden",sell=5} ITEMS[13]={name="Weg",sell=5} ITEMS[14]={name="Kleinkram",sell=1}
AuctionHouseFrame = CreateFrame("Frame", "AuctionHouseFrame")
function AuctionHouseFrame:SetPostItem(loc) POSTED = loc end
ItemLocation = { CreateFromBagAndSlot = function(_, b, s) return { bag = b, slot = s } end }
BAGS={} bagItem(1,10,20) bagItem(2,11,5) bagItem(3,12,1,{bound=true}) bagItem(4,13,1) bagItem(5,14,1)
''')
c = s.eval("(NS:FindPostingCandidates())")
ids = [c[i].itemID for i in range(1, len(c)+1)]
print("Verkaufsliste:", ids); assert ids == [10, 14]   # 11: vendor better, 12 bound, 13 not listed
s.execute('fire("AUCTION_HOUSE_SHOW")'); slash(s, "verkaufen")
assert s.eval("KontorPostingFrame:IsShown()") is True
print(s.eval("KontorPostingFrame.more._text"))
assert "1 gebunden" in s.eval("KontorPostingFrame.more._text")
s.execute('KontorPostingFrame.rows[1]._scripts.OnClick(KontorPostingFrame.rows[1], "LeftButton")')
assert s.eval("POSTED.slot") == 1
# right click -> never post
s.execute('KontorPostingFrame.rows[1]._scripts.OnClick(KontorPostingFrame.rows[1], "RightButton") StaticPopupDialogs.KONTOR_NEVER_POST.OnAccept(nil, 10)')
assert s.eval("KontorDB.postExclusions[10]") is True and s.eval("#(NS:FindPostingCandidates())") == 1
s.execute('fire("AUCTION_HOUSE_CLOSED")'); assert s.eval("KontorPostingFrame:IsShown()") is False
slash(s, "verkaufen"); print(chat(s)[-1])
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("POSTING-TESTS OK")
