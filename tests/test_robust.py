import sys, os
src = open(os.path.join(os.path.dirname(__file__), "test_core.py")).read().split("# 1) fresh install")[0]
src = src.replace('lua.execute(f\'REALM', 'lua.execute(\'UNKNOWN_EVENTS = { ITEM_SEARCH_RESULTS_UPDATED = true, UNIT_SPELLCAST_INTERRUPTED = true }\')\n    lua.execute(f\'REALM')
exec(src)
s = session()
slash(s, "status"); print("\n".join(chat(s)[-9:]))
assert s.eval("#KontorDB.errorLog") == 2
slash(s, "fehler"); print(s.eval("KontorText_errors.editBox._text").split("\n\n",1)[1][:400])
print("ROBUST OK")
