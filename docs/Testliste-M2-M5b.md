# Testliste M2 bis M5b (Kontor 0.3.0)

Nach Orten sortiert, damit du möglichst wenig laufen musst. Am besten mit dem **Bankcharakter**
(der Verzauberer), am Ende kurz ein Charakter der anderen Fraktion.

Zum Melden reicht: Nummer + „ok“ oder was anders war. Bei Fehlermeldungen bitte `/kontor fehler`
→ „Alles markieren“ → Strg+C und einfügen.

**Vorher:** Alten Ordner `Kontor` im AddOns-Verzeichnis löschen, neuen hineinkopieren.

---

## A – Irgendwo nach dem Einloggen (2 Min.)

- [x] **A1** Einloggen ohne Fehlermeldung. Im Chat steht einmalig „Verzauberer erkannt: <Name>“.
- [x] **A2** `/kontor fehler` zeigt „Keine Fehler protokolliert“. Steht dort etwas, bitte kopieren und schicken.
- [x] **A3** `/kontor` öffnet das Fenster; oben links steht ein **ausgegrauter** Knopf „Scannen“ mit dem
  Hinweis „Scannen geht nur bei geöffnetem Auktionshaus“.

## B – Am Auktionshaus (10–15 Min.)

- [x] **B1** AH öffnen. Über dem AH-Fenster oben links steht „Kontor [Scannen]“.
- [x] **B2** „Scannen“ klicken. Daneben zählen Items und Zeit hoch, das Spiel bleibt bedienbar.
  **Währenddessen im AH nichts suchen.**
- [x] **B3** Am Ende erscheint ein Fenster „Scan fertig“ mit Anzahl und Dauer. **Bitte beides notieren.**
  Noch nicht auf „Jetzt sichern“ klicken, erst „Später“.
- [x] **B4** Drei Items im AH-Fenster suchen, den niedrigsten Stückpreis ablesen und mit
  `/kontor preis ` + Umschalt-Klick aufs Item vergleichen. Preise gleich?
- [x] **B5** Markttiefe: `/kontor tiefe ` + Umschalt-Klick auf eine Handelsware (z. B. Leinenstoff, Pyrit).
  Der Chat listet Preisstufen mit Stückzahlen. Stimmt das grob mit der Liste im AH-Fenster überein?
- [x] **B6** Dasselbe mit einem Ausrüstungsteil: Meldung „keine Handelsware“, kein Fehler.
- [x] **B7** Kauf-Erkennung: Eine **billige** Handelsware ganz normal im AH-Fenster kaufen (z. B. 1–5 Stück).
  Der Chat meldet „Kauf erkannt: [Item] × Menge für X (je Stück Y)“. Stimmt der Betrag mit dem gezahlten überein?
- [x] **B8** Neuen Scan starten und das AH **sofort schließen**. Chat: „Scan abgebrochen (Auktionshaus geschlossen)“,
  keine Fehlermeldung.
- [x] **B9** AH wieder öffnen, Scan bis zum Ende laufen lassen, diesmal **„Jetzt sichern“** klicken.
  Nach dem Neuladen liefert `/kontor preis` für die Items aus B4 weiterhin Preise.

**Nachtest mit 0.3.2 (Scan-Fehler behoben):**

- [x] **B10** Neuen Scan starten. Der Fortschritt zeigt „Abfrage n/14“ (mehr, wenn eine Klasse aufgeteilt wird). Am Ende Anzahl Items und Dauer notieren.
- [x] **B11** `/kontor scaninfo` → Liste der Abfragen mit Item-Zahlen (Screenshot).
- [x] **B12** `/kontor preis` für Pyrit und Seelenstaub: beide mit Preis, **ohne** „nicht gelistet“.
- [x] **B13** AH schließen und wieder öffnen: Das Kontor-Fenster geht mit auf und mit zu.

Falls ein Scan ohne dein Zutun mit „andere Suche im Auktionshaus gestartet“ abbricht: bitte melden.

## C – Tooltip (überall, 2 Min.)

- [x] **C1** Mit der Maus über ein gescanntes Item in der Tasche: Zeile „AH-Tiefstpreis: … · vor … Min.“
- [x] **C2** Über ein Item, das nicht im AH war: keine Zeile.
- [x] **C3** Ein Item-Link im Chat anklicken: Die Zeile steht auch im aufgehenden Fenster.
- [x] **C4** `/kontor tooltip` → Zeile weg. Nochmal `/kontor tooltip` → Zeile wieder da.
- [x] **C5** Im Kampf (z. B. ein Mob) über Items fahren: keine Fehlermeldung. (Die Zeile fehlt im Kampf absichtlich.)

## D – Beim Händler (5 Min.)

Vorbereitung: ein paar billige grüne oder weiße Items in der Tasche, die nach dem Scan gelistet waren.

- [x] **D1** Händler ansprechen: Über dem Händlerfenster steht „Kontor: Aufräumen (n Items, Betrag)“
  oder ausgegraut „nichts zu tun“.
- [x] **D2** Klick öffnet die Vorschau. Zwei Zeilen von Hand prüfen: Händler-Spalte ≥ AH netto (AH-Preis × 0,95 × Menge)?
- [x] **D3** In der Liste taucht **kein** gebundenes Item auf, **kein** graues und keins ohne Scan-Preis.
- [x] **D4** Bei einer Zeile das Häkchen entfernen, „Verkaufen“. Dieses Item bleibt in der Tasche, die anderen sind weg.
  Chat: „Aufgeräumt: n Stapel verkauft, Erlös …“
- [x] **D5** Die verkauften Items stehen im Rückkauf-Reiter des Händlers.
- [x] **D6** Rechtsklick auf eine Zeile → „Nie verkaufen“ bestätigen. Das Item verschwindet aus der Liste und
  taucht auch beim nächsten Händlerbesuch nicht mehr auf.

## E – Entzaubern (Bankcharakter, 5 Min.)

- [x] **E1** Ein grünes Item entzaubern. Chat: „Entzaubert: [Item] → 2× [Material]“ (Item und Ergebnis korrekt?).
- [x] **E2** Noch zwei, drei Items entzaubern, auch mit offenem Beutefenster und mit automatischem Plündern,
  falls du das nutzt.
- [x] **E3** `/kontor entzauber export`: Fenster mit einer Zeile pro Entzaubern (Stufe, Qualität, Ergebnis).
- [x] **E4** Einen Gegner looten: **kein** neuer Eintrag im Export.
- [x] **E5** Ein Entzaubern mittendrin abbrechen (bewegen): kein Eintrag, keine Fehlermeldung.
- [x] **E6** `/reload`, dann `/kontor status`: Die Zahl der Entzauber-Einträge ist noch da.

## G – Verkaufsliste (neu in 0.4.0, am AH, 5 Min.)

Vorbereitung: frischer Scan, ein paar Items in der Tasche, die im AH gut Geld bringen (z. B. Kräuter, Erz).

- [x] **G1** Über dem AH-Fenster oben rechts steht der Knopf „Verkaufsliste“. Klick öffnet die Liste.
- [x] **G2** Die Liste zeigt nur Items, die im AH netto mehr bringen als beim Händler (Spalten vergleichen).
- [x] **G3** Linksklick auf eine Zeile: Das AH wechselt zum Verkaufen, das Item liegt im Verkaufsfenster,
  ein Preis ist eingetragen. **Selbst** auf „Auktion erstellen“ klicken: Die Auktion wird erstellt,
  **keine** Fehlermeldung (auch nicht „Aktion blockiert“). Die Zeile verschwindet aus der Liste.
- [x] **G4** Rechtsklick auf eine Zeile → „Nicht anbieten“: Die Zeile verschwindet und kommt nicht wieder.
- [x] **G5** AH schließen: Die Liste geht mit zu.
- [ ] **G6** (0.4.1) Splitter und Staub ohne Händlerwert erscheinen in der Liste. Fehlt etwas, steht unter
  der Liste der Grund (Screenshot).

## F – Andere Fraktion (1 Min.)

- [ ] **F1** Auf einem Allianz-Charakter `/kontor status`: Markt endet auf „-Alliance“, Preise: 0.
  Tooltip zeigt dort keine Horde-Preise.

---

## Bitte zusätzlich notieren

- Anzahl Items und Dauer des Scans (B3) – offene Punkte 3 und 4 im Pflichtenheft.
- Ob der Scan in etwa so viele Items findet, wie im AH los ist.
