import sys, os
exec(open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0])
s = session('{ version = 3, markets = { ["ClassicBetaPvP-Horde"] = { prices = { [999] = { p = 50, q = 1, t = 1, listed = true } }, history = {} } } }')
s.execute("AuctionHouseFrame = CreateFrame('Frame', 'AuctionHouseFrame')")
P = 'KontorDB.markets["ClassicBetaPvP-Horde"].prices'
ls = 'KontorDB.markets["ClassicBetaPvP-Horde"].lastScan'
s.execute("NS.Scan:Start()"); assert any("nicht geöffnet" in c for c in chat(s))
s.execute('fire("AUCTION_HOUSE_SHOW")')
# Results depend on the class filter of the last query
s.execute('''
BYCLASS = {
  [7] = { row(100, 500, 3, 10), row(100, 400, 2, 12), row(200, 10000, 5) },
  [4] = { row(300, 123, 1) },
}
C_AuctionHouse.SendBrowseQuery = function(q)
  AH.sent = AH.sent + 1 AH.lastQuery = q
  local f = q.itemClassFilters[1]
  AH.results = { row(100, 500, 3, 10), row(100, 400, 2, 12), row(200, 10000, 5), row(300, 123, 1) }
  AH.full = true
end
''')
# re-hook since we replaced the function: emulate hooksecurefunc behaviour the addon installed earlier
s.execute('AH.ready = false NS.Scan:Start()')
assert s.eval("AH.sent") == 0
s.execute('AH.ready = true fire("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")')
n = 0
while s.eval("NS.Scan:IsRunning()") and n < 100:
    s.execute('if AH.sent ~= LASTSENT then LASTSENT = AH.sent fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED") end tick(1)'); n += 1
print("Abfragen:", s.eval("AH.sent"))
assert s.eval(f"{P}[100].p") == 400 and s.eval(f"{P}[100].q") == 5
assert s.eval(f"{P}[200].p") == 10000 and s.eval(f"{P}[300].q") == 1
assert s.eval(f"{P}[999].listed") is False
assert s.eval(f"{ls}.complete") is True and s.eval(f"{ls}.itemCount") == 3
slash(s, "scaninfo"); print("\n".join(chat(s)[-18:]))
# A query without answer is skipped after the timeout, scan counts as incomplete
s.execute(f'{P}[999].listed = true')
s.execute('C_AuctionHouse.SendBrowseQuery = function() AH.sent = AH.sent + 1 end NS.Scan:Start()')  # no answer
s.execute('local t=GetTime GetTime=function() return t()+20 end tick(1) GetTime=t')       # query skipped
n = 0
while s.eval("NS.Scan:IsRunning()") and n < 100:
    s.execute('if AH.sent ~= LASTSENT then LASTSENT = AH.sent fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED") end tick(1)'); n += 1
assert s.eval(f"{ls}.complete") is False and s.eval(f"{P}[999].listed") is True
print(chat(s)[-1])
# abort on close
s.execute('NS.Scan:Start() fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED") tick(1) fire("AUCTION_HOUSE_CLOSED")')
assert s.eval("NS.Scan:IsRunning()") is False; print(chat(s)[-1])
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("SCAN-TESTS OK")
