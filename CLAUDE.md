# CLAUDE.md – Kontor

WoW-Forever-Addon „Kontor“ (Auktionshaus-Vorräte). **Zuerst `docs/PROJEKT-UEBERGABE.md` lesen** – dort steht der
gesamte Projektstand aus den bisherigen Chats.

## Regeln für die Zusammenarbeit
- Mit dem Nutzer **Deutsch, einfache Worte**. Er liest keinen Code; Ergebnisse kommen als Test-Rückmeldung oder Screenshot.
- Addon-Texte deutsch mit echten Umlauten; Bezeichner und Kommentare im Code englisch.
- Abweichungen von `docs/Pflichtenheft.md` / `docs/Nachtrag-*.md` vorher ansprechen, danach in `docs/Entscheidungen.md`.
- Nie behaupten, etwas sei im Spiel getestet, wenn nur `tests/` lief.
- Nie: Kaufen/Einstellen/Abbrechen von Auktionen durch das Addon, Händlerverkauf ohne Vorschau, geschützte Aktionen im Kampf.

## Arbeiten am Code
- Addon: `Kontor/` (Ladereihenfolge `Kontor/Kontor.toc`), Datenmodell `KontorDB` Version 4, Migrationen nur ergänzend.
- Tests: `pip install lupa`, dann `sh tests/run_all.sh` (WoW-API-Attrappe: `tests/wow_mock.lua`).
- Nach jeder Änderung: Tests, `CHANGELOG.md`, Version in der `.toc`, Commit + Push, ZIP des Ordners `Kontor` für den Nutzer.
