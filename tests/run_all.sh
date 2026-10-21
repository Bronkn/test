#!/bin/sh
# Runs all Kontor tests outside the game (Lua 5.1 via lupa, WoW API mocked in wow_mock.lua).
# Setup once: pip install lupa
# Usage, from the repository root: sh tests/run_all.sh
cd "$(dirname "$0")/.." || exit 1
status=0
for t in tests/test_*.py; do
    printf "%-32s " "$(basename "$t")"
    out=$(python3 "$t" Kontor 2>&1)
    if [ $? -eq 0 ]; then echo "$out" | tail -1; else echo "FEHLER"; echo "$out" | tail -15; status=1; fi
done
exit $status
