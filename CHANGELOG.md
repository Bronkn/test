# Changelog – Kontor

## [Unveröffentlicht]

### M2 – Übersichts-Scan (0.2.0, wartet auf Abnahme)
- Knopf „Scannen“ im Kontor-Fenster und über dem AH-Fenster, nur bei offenem AH aktiv. Während des Scans wird er zu „Abbrechen“.
- Blättert das AH über die Übersichtsabfrage durch, wartet bei Drosselung, verarbeitet höchstens 300 Zeilen pro Bild.
- Speichert pro Item-ID und Markt: Tiefstpreis je Stück, Gesamtmenge, Zeitpunkt. Varianten: kleinster Preis, Mengen summiert.
- Fortschritt (Items, laufende Zeit) neben dem Knopf.
- Abbruch bei geschlossenem AH, bei eigener Suche im AH-Fenster oder nach 60 s ohne Antwort: gelesene Items behalten ihre neuen Werte, Scan gilt als unvollständig.
- Vollständiger Scan: Nicht mehr gelistete Items behalten Preis und Zeitpunkt und werden als „beim letzten Scan nicht gelistet“ markiert. (Verlaufspunkt mit Menge 0 für Watchlist-Items folgt mit M7.)
- Zusammenfassung mit Knopf „Jetzt sichern“ (lädt die Oberfläche neu).
- `/kontor preis <Item-Link>` zeigt Tiefstpreis, Menge und Alter.


### M1 – Gerüst (0.1.0, abgenommen 12.10.2026)
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
