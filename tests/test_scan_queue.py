import sys, os
exec(open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0])
s = session()
s.execute("AuctionHouseFrame = CreateFrame('Frame', 'AuctionHouseFrame')")
s.execute('''
local function rows(a, b) local r = {} for i = a, b do table.insert(r, row(i, i, 1)) end return r end
C_AuctionHouse.SendBrowseQuery = function(q)
  AH.sent = AH.sent + 1
  local f = q.itemClassFilters[1]
  AH.page = 1
  AH.results = AH.page == 1 and rows(1, 500) or {}
  AH.full = AH.page == 0
end
C_AuctionHouse.RequestMoreBrowseResults = function() AH.more = AH.more + 1 end
''')
s.execute('fire("AUCTION_HOUSE_SHOW") NS.Scan:Start()')
n = 0
while s.eval("NS.Scan:IsRunning()") and n < 300:
    s.execute('''
      if AH.sent ~= LASTSENT then LASTSENT = AH.sent fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED") tick(1)
        -- trade goods: pages 2 and 3 arrive while page 1 is still being processed
        if AH.page == 1 then
          AH.page = 2 fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", (function() local r={} for i=501,1000 do r[#r+1]=row(i,i,1) end return r end)())
          tick(1)
          AH.full = true fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", (function() local r={} for i=1001,1234 do r[#r+1]=row(i,i,1) end return r end)())
        end
      end
      tick(1)''')
    n += 1
ls = 'KontorDB.markets["ClassicBetaPvP-Horde"].lastScan'
print("Items:", s.eval(f"{ls}.itemCount"))
assert s.eval(f"{ls}.itemCount") == 1234
print("QUEUE-TEST OK")
