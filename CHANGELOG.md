# Changelog – Kontor

## [Unveröffentlicht]

### 0.4.0 – Verkaufsliste
- **Neu:** Knopf „Verkaufsliste“ über dem AH-Fenster und im Kontor-Fenster, auch `/kontor verkaufen`. Listet Taschen-Items, die im AH netto mehr bringen als beim Händler (mindestens 10 Silber je Stapel, frischer Scan-Preis, nicht gebunden, nicht in einem Korb).
- Linksklick legt den Stapel in Blizzards Verkaufsfenster; Blizzard setzt den aktuellen Tiefstpreis. Eingestellt wird über „Auktion erstellen“ im AH-Fenster, nicht vom Addon.
- Rechtsklick: „nicht anbieten“. Hinweis auf die Einlage im Fenster.


### 0.3.5 – Entzaubern über Taschenvergleich erkennen
- Forever schickt beim Entzaubern keinen Zielnamen und sperrt kein Fach (Test 13.10.2026: „Ziel unbekannt, 0 gesperrt“). Das Addon merkt sich jetzt beim Wirken den Tascheninhalt und erkennt nach der Beute, welches Item verschwunden ist. Wird das Item erst kurz nach der Beute entfernt, wartet es bis zu 3 s.
- Fehlschläge werden ohne Item gespeichert (das Item ist bei einem Fehlschlag nicht sicher bekannt).


### 0.3.4 – Entzaubern zuverlässiger erkennen
- **Fehler behoben:** In Forever wurde das entzauberte Item nicht erkannt („nicht eindeutig“), weil die Erkennung nur auf die Sperre des Taschenfachs setzte. Jetzt in dieser Reihenfolge: Zielname, den das Spiel beim Wirken mitschickt; zuletzt gesperrtes Fach; einziges gesperrtes Item.
- Bleibt es unklar, nennt die Chatzeile, was gesehen wurde (Zielname, Anzahl passender und gesperrter Items).


### 0.3.3 – Scan wieder mit einer Abfrage
- Test 13.10.2026: Die Abfrage ohne Filter allein lieferte 3133 von 3134 Items. Der Scan nach Klassen und das Aufteilen bei 300 entfallen wieder, der Scan ist dadurch etwa dreimal so schnell.


### 0.3.2 – Scan verliert keine Zeilen mehr
- **Fehler behoben (Ursache der fehlenden Items):** Kam eine neue Ergebnisseite an, während die vorige noch verarbeitet wurde, konnte die Warteschlange des Scans Zeilen verlieren. Daher stammten die „genau 300 Items“ bei Verbrauchbar und Handwerkswaren (300 = Zeilen pro Bild) und das fehlende Pyrit.
- Liefert eine Abfrage trotzdem genau 300 Zeilen, teilt der Scan sie automatisch in Unterklassen und dann in Qualitäten auf. `/kontor scaninfo` markiert abgeschnittene Abfragen.
- Klassen ohne Inhalt in Forever (Juwelen, Glyphen, Berufe) werden nicht mehr abgefragt.
- **Neu:** Das Kontor-Fenster öffnet sich mit dem AH (beim ersten Mal rechts daneben) und schließt sich mit ihm, wenn es so geöffnet wurde. Abschaltbar mit `/kontor autoauf`.
- **Neu:** `/kontor sichern` speichert sofort (lädt die Oberfläche neu).
- Scan-Zusammenfassung erscheint auch bei unvollständigem Durchlauf, mit Hinweis.


### 0.3.1 – Scan nach Kategorien
- **Fehler behoben:** Eine einzige Abfrage ohne Filter lieferte in Forever nicht das ganze AH (Pyrit und Seelenstaub fehlten, obwohl gelistet). Der Scan fragt jetzt jede Item-Klasse einzeln ab und zum Schluss einmal ohne Filter.
- Fortschritt zeigt „Abfrage n/17“. `/kontor scaninfo` listet, wie viele Items jede Abfrage geliefert hat.
- Antwortet eine Abfrage 15 s lang nicht, wird sie übersprungen; der Scan gilt dann als unvollständig und markiert nichts als „nicht gelistet“.


### M3, M4, M5, M5b (0.3.0, wartet auf Abnahme)
- **Tooltip (M3):** Zeile „AH-Tiefstpreis · Alter“ an jedem Item mit Scan-Preis, grau ab 24 Std., nicht im Kampf. `/kontor tooltip` schaltet sie ab.
- **Aufräumen (M4):** Knopf über dem Händlerfenster mit Anzahl und Erlös. Vorschau mit Häkchen, Händlererlös, AH-Wert netto, Preisalter. Höchstens 12 Stapel je Durchlauf. Rechtsklick: „Nie verkaufen“. Verkauft wird nur, was noch genau so im Fach liegt.
- **Markttiefe (M5):** `/kontor tiefe <Item>` listet die Preisstufen im Chat und den Preis für die ersten 20 Stück.
- **Kauf-Erkennung (M5):** Commodity-Käufe im AH-Fenster werden im Chat mit Menge und Gesamtpreis gemeldet.
- **Entzauber-Protokoll (M5b):** Jedes eindeutig zuzuordnende Entzaubern wird mit Item, Qualität, Stufe, Klasse, Fertigkeit, Buffs und Ergebnis gespeichert, mit Chatzeile. Fehlschläge mit Fehlermeldung landen getrennt. `/kontor entzauber export`, `/kontor salvager`.
- Verzauberer-Name wird beim ersten Einloggen mit Entzaubern gespeichert.
- Fehlende Events oder Funktionen im Client legen das Addon nicht mehr lahm, sondern landen im Fehlerprotokoll.
- `/kontor status` zeigt zusätzlich das Entzauber-Protokoll.


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
