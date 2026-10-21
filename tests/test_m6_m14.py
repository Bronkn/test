import sys, os, time as _t
exec(open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0])
now = int(_t.time()) // 3600 * 3600 + 120
G, S = 10000, 100
s = session()
s.execute("function time() return NOW end NOW = %d" % now)
s.execute('fire("PLAYER_LOGIN")')
M = 'KontorDB.markets["ClassicBetaPvP-Horde"]'
def setprice(i, p, q=10, listed=True):
    s.execute(f'NS:GetMarketData(true).prices[{i}] = {{ p = {p}, q = {q}, t = NOW - 60, listed = {str(listed).lower()} }}')
def basket(name):
    return s.eval(f'(function() for _, b in ipairs(KontorDB.baskets) do if b.name == "{name}" then return b end end end)()')

# --- Startkonfiguration (Nachtrag 1, 9 / Nachtrag 3, 5)
names = [s.eval(f"KontorDB.baskets[{i}].name") for i in range(1, s.eval("#KontorDB.baskets")+1)]
print("Körbe:", names); assert names == ["A - Launch", "B - Früh", "C - Mittel", "D - Spät", "W - Werkstatt"]
assert s.eval('KontorDB.baskets[3].order[1]') == 7079                     # Globe of Water first in C
assert s.eval('KontorDB.baskets[3].items[249424].fixedPrice') == 20*G     # Rosecap in C
assert s.eval('KontorDB.baskets[4].items[8831] ~= nil and KontorDB.baskets[4].items[4625] ~= nil')
assert s.eval('KontorDB.baskets[1].phase') == "sammeln" and s.eval('KontorDB.baskets[5].type') == "werkstatt"
assert s.eval('KontorDB.recipes[249410].source') == "vorlage" and s.eval('KontorDB.recipes["Brilliant Wizard Oil"] ~= nil')
assert s.eval('KontorDB.baskets[1].items[249391].usage').startswith("Sulfuric Acid")
slash(s, "vorlage"); assert "überschreibt nie" in chat(s)[-1]
# user edits a recipe and deletes a template: next login keeps both decisions
s.execute('KontorDB.recipes[249409].yield = 3 KontorDB.recipes[249430] = nil fire("PLAYER_LOGIN")')
assert s.eval('KontorDB.recipes[249409].yield') == 3 and s.eval('KontorDB.recipes[249430] == nil') and s.eval("#KontorDB.baskets") == 5
# an install that never had a template gets it
s.execute('KontorDB.templatesApplied[249430] = nil fire("PLAYER_LOGIN")'); assert s.eval('KontorDB.recipes[249430] ~= nil')
# one item, one basket (W exception)
ok = s.eval('(NS:AddBasketItem(KontorDB.baskets[2], 249391, {}))'); assert ok is False
ok = s.eval('(NS:AddBasketItem(KontorDB.baskets[5], 249391, {}))'); assert ok is True
s.execute('NS:RemoveBasketItem(KontorDB.baskets[5], 249391)')

# --- Signale / Phasen / Festpreis
s.execute('ITEMS[249391]={name="Pyrit",sell=5} ITEMS[249410]={name="Schwefelsäure",sell=10} ITEMS[249427]={name="Pristine Leather",sell=5}')
A = 'KontorDB.baskets[1]'; B = 'KontorDB.baskets[2]'
setprice(3369, 50*S)
s.execute(f'{B}.items[3369].buyLimit = 60*100')
assert s.eval(f'NS:GetItemSignal({B}, {B}.items[3369], 3369).kind') is None      # Beobachten: nothing
s.execute(f'{B}.items[3369].phase = "sammeln"')
assert s.eval(f'NS:GetItemSignal({B}, {B}.items[3369], 3369).kind') == "buy"
assert s.eval(f'NS:GetItemSignal({B}, {B}.items[3818], 3818).kind') is None
# fixed price 5g, no target, Abstoßen, stock: sell from 4g75 net
s.execute(f'{A}.items[249427].phase = "abstossen" NS:AddLedgerEntry(249427, "buy", 45, 2*{G}, "manuell")')
setprice(249427, 500*S)    # 5g gross -> 4g75 net
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') == "sell"
setprice(249427, 499*S)
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') is None
setprice(249427, 600*S)
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).hint') == "über Festpreis - Käufer greifen zum NPC"
# storage slots: 45 at stack 20 -> 3
assert s.eval('NS:StorageSlots(249427, 45)') == 3
# stock limit / budget block buy signal
s.execute(f'{A}.items[249427].phase = "sammeln" {A}.items[249427].buyLimit = 10*{G}')
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') == "buy"
s.execute(f'{A}.items[249427].stockLimit = 45')
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') is None
s.execute(f'{A}.items[249427].stockLimit = nil {A}.budget = 50*{G}')
assert s.eval(f'NS:IsOverBudget({A})') is True and s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') is None
s.execute(f'{A}.budget = nil')
# stale price: no signal
s.execute(f'NS:GetMarketData(true).prices[249427].t = NOW - 49*3600')
assert s.eval(f'NS:GetItemSignal({A}, {A}.items[249427], 249427).kind') is None

# --- Bestand / Einstand (M8)
s.execute('NS:AddLedgerEntry(3818, "buy", 10, 10000, "manuell") NS:AddLedgerEntry(3818, "buy", 10, 20000, "manuell")')
st, avg = s.eval('NS:GetPosition(3818)'); assert st == 20 and avg == 15000, (st, avg)
inv0 = s.eval(f'NS:GetInvested({B})')
s.execute('NS:AddLedgerEntry(3818, "sell", 5, 30000, "manuell")')
st, avg = s.eval('NS:GetPosition(3818)'); assert st == 15 and avg == 15000
assert s.eval(f'NS:GetInvested({B})') == inv0 - 150000
assert abs(s.eval('NS:BreakEven(15000)') - 15000/0.95) < 0.01
# auto purchase books into ledger
s.execute('fire("AUCTION_HOUSE_SHOW") C_AuctionHouse.StartCommoditiesPurchase(3369, 4) fire("COMMODITY_PRICE_UPDATED", 5000, 20000) C_AuctionHouse.ConfirmCommoditiesPurchase(3369, 4) fire("COMMODITY_PURCHASE_SUCCEEDED")')
print(chat(s)[-1]); assert "gebucht" in chat(s)[-1] and s.eval('(NS:GetPosition(3369))') == 4

# --- Rezepte (M9 / Nachtrag 1, 9)
setprice(249391, 1*S); setprice(249410, 8*S)
s.execute('KontorDB.recipes[249410].reagents[2].fixedPrice = 0')
calc = 'NS:CalcRecipe(KontorDB.recipes[249410])'
print("Faktor:", s.eval(f'{calc}.factor')); assert abs(s.eval(f'{calc}.factor') - 3.8) < 1e-9
s.execute('KontorDB.chars["Bankchar-X"] = { professions = { Alchemie = 66 } }')
assert s.eval('NS:CraftSignal(KontorDB.recipes[249410])') == "Verarbeiten lohnt"
setprice(249391, 3*S)   # 8*0.95/6 = 1.27 < 1.5
assert s.eval('NS:CraftSignal(KontorDB.recipes[249410])') is None
setprice(249391, 1*S)
s.execute('CHARCOUNT = { [249391] = 4 }')
sl = s.eval('NS:ShoppingList(KontorDB.recipes[249410], 10)')
assert sl.lines[1].buy == 16, sl.lines[1].buy
assert s.eval('NS:CalcRecipe(KontorDB.recipes[249409]).complete') is None   # vendor reagent without price
# foreign profession (Sandpaper, Ingenieurskunst)
setprice(249425, 1*S); setprice(249432, 10*S)
s.execute('KontorDB.recipes[249432].reagents[2] = { itemID = 1234, qty = 1, vendor = true, fixedPrice = 0 }')
assert s.eval('NS:CraftSignal(KontorDB.recipes[249432])') == "Verarbeiten lohnt (fremder Beruf)"
# chains: Pyrit used directly in Schwefelsäure
uses = s.eval('NS:RecipesUsing(249391)'); assert len(uses) >= 1
# tooltip shows usage and craft signal for Pyrit
lines = list(s.eval('(function() local t=makeTooltip() TOOLTIP_CALLS[0](t, {id=249391}) return t.lines end)()').values())
print("Tooltip Pyrit:", [l[:60] for l in lines]); assert lines[-1].startswith("Verwendung:") and any("Verarbeiten lohnt" in l for l in lines)

# --- Verlauf (M7)
s.execute('AuctionHouseFrame = CreateFrame("Frame", "AuctionHouseFrame")')
s.execute('C_AuctionHouse.SendBrowseQuery = function() AH.sent = AH.sent + 1 AH.results = { row(3369, 4000, 7), row(249391, 100, 50) } AH.full = true end')
def scan():
    s.execute('NS.Scan:Start()')
    n = 0
    while s.eval("NS.Scan:IsRunning()") and n < 50:
        s.execute('if AH.sent ~= LASTSENT then LASTSENT = AH.sent fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED") end tick(1)'); n += 1
scan()
h = f'#{M}.history[3369]'
n1 = s.eval(h)
s.execute('NOW = NOW + 600'); scan()
assert s.eval(h) == n1, "same hour -> replaced"
s.execute('NOW = NOW + 2*3600'); scan()
assert s.eval(h) == n1 + 1, "next hour -> new point"
assert s.eval(f'{M}.history[249427][#{M}.history[249427]].q') == 0   # watchlist item not listed -> quantity 0
print("Scan-Zusammenfassung:", chat(s)[-1])
st = s.eval('NS:HistoryStats(3369, 7)'); assert st.n >= 2

# --- Entzaubern (M11)
s.execute('ITEMS[30]={name="Grüner Helm",sell=20,quality=2,ilvl=22,classID=4} ITEMS[10940]={name="Seltsamer Staub",sell=0}')
setprice(10940, 1*G)
s.execute('for i=1,10 do local e={t=NOW,itemID=30,quality=2,ilvl=22,class="armor",results={[10940]=2},salvager=false} table.insert(KontorDB.deLog,e) NS:OnDisenchantLogged(e) end')
a = s.eval('NS:DisenchantAdvice(30, false)')
print("Entzauber-Empfehlung:", a.advice, a.de, a.n); assert a.advice == "Entzaubern" and a.n == 10 and abs(a.de - 2*9500) < 1
assert s.eval('#KontorDB.baskets') == 6 and s.eval('KontorDB.baskets[6].name') == "E - Verzauberung"
s.execute('ITEMS[31]={name="Grüne Hose",sell=20,quality=2,ilvl=37,classID=4}')
s.execute('local e={t=NOW,itemID=31,quality=2,ilvl=37,class="armor",results={[10940]=3},salvager=false} table.insert(KontorDB.deLog,e) NS:OnDisenchantLogged(e)')
assert s.eval('NS:DisenchantAdvice(31, false).advice') == "Entzaubern? (unsicher)"
# tooltip DE line
lines = list(s.eval('(function() local t=makeTooltip() TOOLTIP_CALLS[0](t, {id=30}) return t.lines end)()').values())
print("Tooltip Helm:", lines[-1]); assert "n=10" in lines[-1] and "Entzaubern" in lines[-1]
# cleanup holds back
s.execute(f'NS:GetMarketData(true).prices[30] = {{ p = 15, q = 1, t = NOW }} BAGS={{}} bagItem(1, 30, 1, {{quality=2}})')
c, held = s.eval('NS:FindCleanupCandidates()'); assert s.eval('#(NS:FindCleanupCandidates())') == 0 and held == 1
# export / import roundtrip
txt = s.eval('NS:BuildDisenchantTable()'); print(txt)
s.execute('KontorDB.deImport = {}')
full = s.eval('NS:BuildDisenchantTable()') + "\n\n" + "# Kontor Entzauber-Protokoll\n# 1;2;3"
cnt = s.eval('NS:ImportDisenchantTable([[%s]])' % full); assert cnt == 2, cnt
# DE window + secure macro
slash(s, "entzaubern")
mt = s.eval('KontorDisenchantButton:GetAttribute("macrotext")'); print("Makro:", repr(mt)); assert "/use 0 1" in mt and "/stopmacro [combat]" in mt
s.execute('KontorDisenchant.table.onClick(KontorDisenchant.candidates[1], "RightButton") StaticPopupDialogs.KONTOR_NEVER_DE.OnAccept(nil, {itemID=30})')
assert s.eval('#NS:FindDisenchantCandidates()') == 0
s.execute('KontorDB.deExclusions[30] = nil')
# Kaufen zum Entzaubern: AH offer at 5s with EV 1g90 -> listed
s.execute('NS:GetMarketData(true).prices[30] = { p = 500, q = 1, t = NOW, v = true }')
buys = s.eval('NS:FindDisenchantBuys()'); assert len(buys) == 1 and buys[1].variant is True
# non-enchanter (M13)
s.execute('C_SpellBook.IsSpellKnown = function() return false end KontorDB.config.enchanterName = "Bankchar"')
assert s.eval('NS:DisenchantAdvice(30, false).advice') == "an Bankchar schicken"
assert s.eval('NS:DisenchantAdvice(30, true).advice') in ("Händler", "AH")
s.execute('''MailFrame = CreateFrame("Frame","MailFrame") SendMailNameEditBox = CreateFrame("EditBox")
ATTACHED = 0 function ClickSendMailItemButton() ATTACHED = ATTACHED + 1 end function CursorHasItem() return false end
C_Container.PickupContainerItem = function() end MailFrameTab_OnClick = function() end
BAGS={} bagItem(1,30,1,{quality=2}) bagItem(2,30,1,{quality=2,bound=true}) fire("MAIL_SHOW")''')
btn = [x for x in s.eval("(function() local r={} for _,f in ipairs(FRAMES) do local x=rawget(f,'_text') if type(x)=='string' and x:find('Entzauberware') then table.insert(r,x) end end return r end)()").values()]
print(btn); assert "(1 Items)" in btn[-1]
s.execute('for _,f in ipairs(FRAMES) do local x=rawget(f,"_text") if type(x)=="string" and x:find("Entzauberware") then f._scripts.OnClick(f) end end')
assert s.eval("ATTACHED") == 1 and s.eval("SendMailNameEditBox._text") == "Bankchar"; print(chat(s)[-1])

# --- UI smoke: main window, detail, recipes, settings
s.execute('C_SpellBook.IsSpellKnown = function() return true end')
slash(s, ""); s.execute('NS:FireChange()')
s.execute('NS:ShowItemDetail(KontorDB.baskets[1].id, 249427)')
s.execute('KontorItemDetail.inputs.target:SetText("6g") KontorItemDetail.inputs.target.onEnter(KontorItemDetail.inputs.target)')
assert s.eval('KontorDB.baskets[1].items[249427].target') == 5*G; print(chat(s)[-2])
slash(s, "rezepte"); slash(s, "einstellungen")
s.execute('KontorSettings.inputs.ahFee:SetText("6") for _,f in ipairs(FRAMES) do if rawget(f,"_text")=="Speichern" and f:GetParent()==nil then end end')
slash(s, "entzauber import")
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("M6-M14 TESTS OK")

# money parsing
for txt, want in [("1,5g", 15000), ("1.5", 15000), ("2", 20000), ("1g 20s", 12000), ("120s", 12000), ("35c", 35), ("1.5s", None)]:
    got = s.eval('NS:ParseMoney("%s")' % txt); assert got == want, (txt, got)
# shift-click goes through ChatFrameUtil.InsertLink
s.execute('local box = NS:CreateInput(UIParent, 100) box._shown = true box._focus = true ChatFrameUtil.InsertLink("|Hitem:42|h[x]|h") LINKBOX = box')
assert s.eval('LINKBOX._text') == "|Hitem:42|h[x]|h"
# Bestand auf 0 korrigieren
s.execute('StaticPopupDialogs.KONTOR_BOOK_ADJUST.OnAccept({ GetEditBox = function() return { GetText = function() return "0" end } end }, { itemID = 3818 })')
assert s.eval('(NS:GetPosition(3818))') == 0
print("FIX-TESTS OK")
# minimap button only for enchanters
assert s.eval('KontorMinimapButton ~= nil and KontorMinimapButton:IsShown()') is True
s.execute('C_SpellBook.IsSpellKnown = function() return false end fire("SPELLS_CHANGED")')
assert s.eval('KontorMinimapButton:IsShown()') is False
s.execute('C_SpellBook.IsSpellKnown = function() return true end fire("SPELLS_CHANGED")')
s.execute('KontorMinimapButton._scripts.OnClick(KontorMinimapButton, "LeftButton")')
assert s.eval('KontorDisenchant:IsShown()') is True
# unknown item name shows a placeholder, then the name
s.execute('NS:AddBasketItem(KontorDB.baskets[2], 777777, {}) NS:FireChange()')
s.execute('ITEMS[777777] = { name = "Spätes Item", sell = 1 } fire("GET_ITEM_INFO_RECEIVED", 777777, true) runTimers()')
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("MINIMAP-TESTS OK")
# basket editor
s.execute('NS:ShowBasketEditor(KontorDB.baskets[2].id) KontorBasketEditor.name:SetText("B - Neu") KontorBasketEditor.budget:SetText("50g") KontorBasketEditor.phase._scripts.OnClick(KontorBasketEditor.phase)')
s.execute('for _,f in ipairs(FRAMES) do if rawget(f,"_text")=="Speichern" and f._scripts.OnClick then f._scripts.OnClick(f) end end')
assert s.eval('KontorDB.baskets[2].name') == "B - Neu" and s.eval('KontorDB.baskets[2].budget') == 500000
assert s.eval("#KontorDB.errorLog") == 0, s.eval("KontorDB.errorLog[1].msg")
print("EDITOR-TESTS OK")
