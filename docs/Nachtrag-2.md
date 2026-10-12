# Kontor – Nachtrag 2 zum Pflichtenheft: Entzaubern

Stand: 12.10.2026

Ergänzt das Pflichtenheft vom 11.10.2026 und Nachtrag 1. Wo dieser Nachtrag etwas Neues festlegt, gilt er. Vorgehen wie bei Nachtrag 1: Fertige Meilensteine nicht neu bauen, Änderungen gezielt nachziehen, vorher ansagen, welche Dateien angefasst werden.

---

## 1. Ziel

Der Bankcharakter ist Verzauberer. Das Addon soll für jedes entzauberbare Item beantworten: **Verkaufen im AH, beim Händler oder entzaubern?** Dazu kommen ein Entzauber-Knopf für die Taschen und eine Liste von AH-Angeboten, die unter ihrem Entzauberwert liegen.

## 2. Grundproblem: Die Ergebnistabelle ist unbekannt

Das Spiel liefert keine API, die sagt, was beim Entzaubern herauskommt. Dazu kommt: Forever hat offenbar neue Verzauberungsmaterialien (u. a. Mote of Magic, Lesser und Greater Astral Essence). Die Classic-Tabellen gelten deshalb nicht.

**Lösung:** Das Addon lernt die Tabelle selbst, indem es jedes Entzaubern protokolliert. Eine von Hand gepflegte Starttabelle ist optional.

**Wichtig für die Reihenfolge:** Der Protokollierer (Abschnitt 3) gehört zu den API-kritischen Teilen und soll **noch vor Beta-Ende am 22.10.** laufen, damit Daten aus Forever gesammelt werden. Die Spielmechanik ändert sich zum Launch vermutlich nicht. Alles andere aus diesem Nachtrag kann danach kommen.

## 3. Entzauber-Protokoll

- Erkennt jedes erfolgreiche Entzaubern (Zauber „Entzaubern" erfolgreich gewirkt, danach das Beutefenster) und schreibt einen Eintrag:
  - Zeit, Item-ID, Qualität, Gegenstandsstufe, Klasse (Rüstung / Waffe / sonstiges), benötigte Charakterstufe,
  - Ergebnis: Item-IDs und Mengen,
  - Fertigkeitswert Verzauberkunst des Charakters,
  - Flag „Arcane Salvager aktiv" (siehe unten).
- **Arcane Salvager:** Das Camping-Objekt soll Entzaubern effizienter machen. Ob das Addon erkennen kann, dass es aktiv ist (z. B. über einen Buff), wird in M0 geprüft. Falls nicht: Schalter im Entzauber-Fenster, den der Nutzer setzt; der Wert wird mitprotokolliert. Einträge mit und ohne Salvager werden getrennt ausgewertet.
- Es wird nur protokolliert, was eindeutig zuzuordnen ist. Unklare Fälle (z. B. Beutefenster aus anderer Quelle) werden verworfen, nicht geraten.
- Nach jedem Entzaubern kurze Chatzeile: „Entzaubert: [Item] → 2× Mote of Magic".

### 3.1 Auswertung in Gruppen
Einträge werden gruppiert nach **Qualität × Klasse × Stufenband** (Gegenstandsstufe in 5er-Bändern, z. B. 21–25). Pro Gruppe:
- Anzahl Entzauberungen (n),
- für jedes Material: Wahrscheinlichkeit, dass es fällt, und Durchschnittsmenge, wenn es fällt,
- erwarteter Ertrag in Gold zu aktuellen AH-Preisen (netto nach Gebühr).

Das Addon zeigt immer **n** mit an. Unter n = 10 gilt der Wert als „unsicher" und wird grau dargestellt.

### 3.2 Starttabelle (optional)
`/kontor entzauber import` nimmt eine Tabelle als Text entgegen (Format legt Claude Code fest, einfach und dokumentiert). Gibt es für eine Gruppe eigene Protokolldaten mit n ≥ 10, haben diese Vorrang.

### 3.3 Export
`/kontor entzauber export` gibt die ausgewertete Tabelle als markierbaren Text aus, zur Kontrolle und Weitergabe.

## 4. Entzauberwert und Empfehlung

Für jedes entzauberbare Item (Rüstung oder Waffe, Qualität grün oder besser, nicht von der Verwertung ausgenommen):

- **Händlerwert** = Händlerpreis
- **AH-Wert** = letzter Scan-Preis × (1 − AH-Gebühr); entfällt bei gebundenen Items
- **Entzauberwert** = Erwartungswert der passenden Gruppe; entfällt, wenn keine Daten

Die **Empfehlung** ist der höchste der drei Werte, mit Abstand-Schwelle: Entzaubern wird nur empfohlen, wenn der Entzauberwert den besten anderen Wert um mindestens 10 % übersteigt (einstellbar). Bei unsicherer Datenlage (n < 10) wird nicht „Entzaubern" empfohlen, sondern „Entzaubern? (unsicher)".

### 4.1 Tooltip
Neue Zeile bei entzauberbaren Items, z. B.:
`Entzaubern: ~38s (n=24) · Empfehlung: Entzaubern`

Bei fehlenden Daten: `Entzaubern: noch keine Daten`. Abschaltbar.

### 4.2 Fertigkeit
Die nötige Verzauberkunst-Fertigkeit pro Item ist ebenfalls unbekannt. Das Protokoll merkt sich je Gruppe die niedrigste Fertigkeit, mit der Entzaubern gelungen ist. Schlägt Entzaubern wegen zu niedriger Fertigkeit fehl (Fehlermeldung des Spiels), wird das ebenfalls vermerkt. Die Empfehlung „Entzaubern" erscheint nur, wenn die Fertigkeit des Verzauberers dafür bekanntermaßen reicht; sonst „Entzaubern (Fertigkeit unklar)".

## 5. Charaktere ohne Verzauberkunst

Der Main kann nicht entzaubern. Für ihn gilt:
- **Ungebundene Items** mit Empfehlung „Entzaubern": Empfehlung lautet „an Bankchar schicken".
- **Gebundene Items** können nicht verschickt werden. Für sie zählt nur Händlerwert, also keine Entzauber-Empfehlung.
- Name des Verzauberers wird beim ersten Einloggen mit Verzauberkunst automatisch erkannt und gespeichert; in den Einstellungen änderbar.

Beim Briefkasten auf einem Nicht-Verzauberer: Knopf „Kontor: Entzauberware an [Bankchar] (n Items)". Klick füllt die Post mit diesen Items (höchstens so viele, wie ein Brief fasst). Abschicken drückt der Nutzer selbst. Vorher prüfen, ob das Befüllen der Post per Addon in Forever erlaubt ist (M0); falls nicht, zeigt der Knopf nur die Liste.

## 6. Änderung am Taschen-Aufräumen (Pflichtenheft 4.3)

Zusätzliche Bedingung für Verkaufskandidaten:

8. Das Item hat **keine** Empfehlung „Entzaubern", „an Bankchar schicken" oder „Entzaubern? (unsicher)".

Damit wird nichts beim Händler verkauft, was entzaubert mehr bringen könnte. Die Vorschau zeigt am Ende eine Zeile „n Items zurückgehalten: besser entzaubern".

## 7. Entzauber-Fenster (Bankcharakter)

- `/kontor entzaubern` oder Knopf im Hauptfenster öffnet eine Liste aller Taschen-Items mit Empfehlung „Entzaubern", sortiert nach Mehrwert gegenüber der besten Alternative.
- Ein großer Knopf **„Nächstes entzaubern"**: Jeder Klick entzaubert genau ein Item, das oberste der Liste. Mehrere Items pro Klick sind nicht möglich, weil das Spiel für jeden Zauber einen echten Tastendruck oder Klick verlangt.
- Umsetzung über einen gesicherten Aktionsknopf (Secure Action Button), der „Entzaubern" auf das jeweilige Taschenfach wirkt. Machbarkeit in Forever in M0 prüfen. Falls nicht machbar: Liste bleibt, der Nutzer entzaubert per Hand.
- Im Kampf ist der Knopf gesperrt.
- Rechtsklick auf eine Zeile: „Nie entzaubern" (eigene Ausnahmeliste, getrennt von „Nie verkaufen").
- Grundsätzlich ausgenommen: Items in einem Korb, Items mit Ausrüstungsset-Zugehörigkeit des Spiels (falls abfragbar), Qualität episch oder höher (Grenze einstellbar), es sei denn, der Nutzer gibt sie ausdrücklich frei.
- Schalter „Arcane Salvager aktiv" (siehe Abschnitt 3).

## 8. Kaufen zum Entzaubern

Der Übersichts-Scan kennt den Tiefstpreis jedes Items. Nach dem Scan erstellt das Addon eine Liste:

- ungebundene, entzauberbare Items, deren **AH-Tiefstpreis unter dem Entzauberwert × (1 − Sicherheitsabschlag)** liegt, Abschlag Standard 25 %,
- nur Gruppen mit n ≥ 10 und ausreichender Fertigkeit,
- sortiert nach erwartetem Gewinn pro Stück.

Anzeige in der Scan-Zusammenfassung („7 Items unter Entzauberwert") und als eigene Liste. Ein Klick auf eine Zeile startet die AH-Suche nach diesem Item im normalen AH-Fenster. **Gekauft wird weiter von Hand.**

Hinweis: Der Übersichts-Scan liefert pro Item nur den niedrigsten Preis über alle Varianten. Bei Items mit Zufalls-Suffix kann die günstigste Variante eine andere Stufe haben. Die Liste markiert solche Items mit „Variante prüfen".

## 9. Materialien

Gefundene Entzauberungsmaterialien werden automatisch in einen neuen Korb **„E – Verzauberung"** (Typ Lager, Phase Beobachten) eingetragen, sobald sie zum ersten Mal im Protokoll auftauchen. So bekommen sie Preisverlauf und Tooltip-Daten wie alle anderen Watchlist-Items.

## 10. Datenmodell

Ergänzungen, `version` wird auf 3 erhöht. Migration ergänzt nur.

```
KontorDB.config:
  deMinAdvantage   = 0.10,   -- Entzaubern muss 10 % besser sein
  deMinSamples     = 10,
  deBuyDiscount    = 0.25,   -- Sicherheitsabschlag „Kaufen zum Entzaubern"
  deMaxQuality     = 3,      -- blau; episch nur nach Freigabe
  enchanterName    = nil,

KontorDB.deLog = {
  { t, itemID, quality, ilvl, class, reqLevel, skill, salvager, results = { [itemID] = qty } },
}
KontorDB.deFailures = { { t, itemID, quality, ilvl, class, skill } }
KontorDB.deImport   = { ... }    -- optionale Starttabelle
KontorDB.deExclusions = { [itemID] = true }
```

Das Protokoll wird nicht verdichtet, Einträge sind klein. Obergrenze 20.000 Einträge; darüber werden die ältesten entfernt, nachdem sie in die Auswertung eingeflossen sind (Gruppen-Summen getrennt speichern).

## 11. Neue Meilensteine

| Meilenstein | Inhalt | Termin |
|---|---|---|
| M0 (Ergänzung) | prüfen: Erkennung Entzaubern + Beute, Secure Action Button für Entzaubern auf Taschenfach, Salvager-Buff erkennbar, Post per Addon befüllen, Fehlermeldung bei zu niedriger Fertigkeit | vor 22.10. |
| M5b | Entzauber-Protokoll + Chatzeile + Export | **vor 22.10.** |
| M11 | Auswertung, Entzauberwert, Empfehlung, Tooltip, Änderung am Aufräumen | nach M10 |
| M12 | Entzauber-Fenster mit „Nächstes entzaubern" | nach M11 |
| M13 | Charaktere ohne Verzauberkunst, Briefkasten-Knopf | nach M11 |
| M14 | Kaufen zum Entzaubern, Korb E | nach M11 |

## 12. Abnahmetests

**M5b – Protokoll**
- [ ] Ein grünes Item entzaubern: Chatzeile nennt Item und Ergebnis korrekt.
- [ ] `/kontor entzauber export` zeigt den Eintrag mit Stufe, Qualität und Ergebnis.
- [ ] Ein Beutefenster von einem Mob öffnen: kein Protokolleintrag.
- [ ] Entzaubern wegen zu niedriger Fertigkeit fehlgeschlagen: Eintrag unter Fehlschlägen, kein Ergebnis-Eintrag.
- [ ] `/reload`: Einträge sind noch da.

**M11 – Empfehlung**
- [ ] Item aus einer Gruppe mit n ≥ 10: Tooltip zeigt Entzauberwert und n.
- [ ] Item aus einer Gruppe mit n < 10: Wert grau, Empfehlung höchstens „Entzaubern? (unsicher)".
- [ ] Entzauberwert von Hand nachrechnen (Wahrscheinlichkeit × Menge × Materialpreis netto, summiert): stimmt.
- [ ] Grünes Item mit Empfehlung „Entzaubern" taucht nicht in der Aufräum-Vorschau auf; die Vorschau nennt es unter „zurückgehalten".

**M12 – Entzauber-Fenster**
- [ ] Liste zeigt nur Items mit Empfehlung „Entzaubern", sortiert nach Mehrwert.
- [ ] Ein Klick auf „Nächstes entzaubern" entzaubert genau ein Item.
- [ ] Im Kampf ist der Knopf gesperrt.
- [ ] „Nie entzaubern": Item verschwindet aus der Liste, auch nach `/reload`.

**M13 – Main ohne Verzauberkunst**
- [ ] Ungebundenes Item mit Entzauber-Vorteil: Tooltip zeigt „an Bankchar schicken".
- [ ] Gebundenes Item: keine Entzauber-Empfehlung.
- [ ] Briefkasten-Knopf füllt die Post mit den richtigen Items; abgeschickt wird erst nach Klick des Nutzers.

**M14 – Kaufen zum Entzaubern**
- [ ] Nach einem Scan nennt die Zusammenfassung die Anzahl der Items unter Entzauberwert.
- [ ] Klick auf eine Zeile startet die Suche im AH-Fenster.
- [ ] Ein Item aus einer Gruppe mit n < 10 erscheint nicht in der Liste.
- [ ] Neues Material im Protokoll erscheint automatisch in Korb E.
