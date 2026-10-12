# Entscheidungen

Abweichungen und Ergänzungen zum Pflichtenheft und den Nachträgen, jeweils vom Nutzer bestätigt.

## 12.10.2026 – Nachtrag 2, Entzaubern

1. **Arcane Salvager:** Der Nutzer hat keinen Salvager, der Buff ist unbekannt. Es gilt der in Nachtrag 2
   vorgesehene Schalter „Salvager aktiv“ im Entzauber-Fenster. Zusätzlich speichert jeder Protokolleintrag
   die Spell-IDs aller Buffs des Charakters zum Zeitpunkt des Entzauberns, damit Einträge später
   nachträglich zugeordnet werden können, falls der Buff bekannt wird.
2. **Fertigkeit:** In Classic und bisher in Forever lässt sich jedes Item mit Fertigkeit 1 entzaubern.
   Abschnitt 4.2 aus Nachtrag 2 entfällt (keine Fertigkeitsprüfung, kein „Fertigkeit unklar“).
   Fehlermeldungen beim Entzaubern werden trotzdem in `deFailures` protokolliert, falls sich das zum
   Launch ändert. Der M5b-Abnahmetest „Entzaubern wegen zu niedriger Fertigkeit“ entfällt.

## 12.10.2026 – Umsetzung M1

- Fensterpositionen liegen in `KontorDB.ui` (im Datenmodell nicht aufgeführt, nötig für Pflichtenheft 6.3).
- Eine neue Installation startet direkt mit Datenmodell-Version 3 (Pflichtenheft + Nachtrag 1 + 2).
  Die Migration von Version 1 (Rezepte aus den Körben nach `KontorDB.recipes`) ist trotzdem eingebaut.
- Zusatzbefehl `/kontor testfehler`, damit sich das Fehlerprotokoll im Spiel prüfen lässt.
