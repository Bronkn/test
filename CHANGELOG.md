# Changelog – Kontor

## [Unveröffentlicht]

### M1 – Gerüst (0.1.0, wartet auf Abnahme)
- Addon-Ordner `Kontor/` mit Interface-Version 16001.
- `/kontor` öffnet und schließt das (noch leere) Hauptfenster. Fenster verschiebbar, Position wird gemerkt, Escape schließt.
- `/kontor status`: Addon-Version, Client-Build, Marktkennung, letzter Scan, Anzahl Preise, Körbe, Fehler.
- `/kontor fehler`: Fehlerprotokoll (letzte 50) als markierbarer Text, mit „Protokoll leeren“.
- `/kontor testfehler` erzeugt einen Testfehler. `/kontor hilfe` listet die Befehle.
- Accountweite SavedVariable `KontorDB`, Datenmodell-Version 3 mit Migrationsgerüst.
- Jeder Event-Handler und Befehl läuft geschützt: Fehler landen im Protokoll statt andere Teile lahmzulegen.

### M0 – API-Verifikation (abgenommen 12.10.2026)
- Pflichtenheft und Nachträge 1–3 unter `docs/` abgelegt.
- `API-NOTIZEN.md`: Alle geprüften Funktionen und Events sind in Forever vorhanden. Interface-Version 16001.
- Entscheidungen zu Salvager und Entzauber-Fertigkeit in `docs/Entscheidungen.md`.
