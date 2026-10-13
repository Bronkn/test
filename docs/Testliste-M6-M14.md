# Testliste M6 bis M14 (Kontor 0.5.0)

Nach Orten sortiert. Zum Melden reicht Nummer + „ok“ oder was anders war. Bei Fehlermeldungen
`/kontor fehler` → „Alles markieren“ → Strg+C und einfügen.

**Vorher:** Alten Ordner `Kontor` löschen, neuen hineinkopieren. Deine Daten bleiben erhalten.

---

## A – Nach dem Einloggen, Bankcharakter (5 Min.)

- [ ] **A1** Einloggen ohne Fehlermeldung. Chat: „Startkörbe A, B, C, D und W angelegt.“ (nur beim ersten Mal).
- [ ] **A2** `/kontor`: Links die Körbe A - Launch, B - Früh, C - Mittel, D - Spät, W - Werkstatt
  (und ggf. E - Verzauberung, siehe F). Klick auf einen Korb zeigt rechts seine Items.
- [ ] **A3** Korb C: Globe of Water steht oben, Rosecap ist drin. Korb D: Purple Lotus und Firebloom sind drin.
- [ ] **A4** `/kontor vorlage`: Meldung „Es gibt schon Körbe …“, nichts ändert sich.
- [ ] **A5** „Neu“ → Korb „Test“ anlegen. „Name“ → umbenennen. „Löschen“ → Rückfrage → weg.
- [ ] **A6** Korb B wählen. Unten „Item hinzufügen“: einmal per Umschalt-Klick auf ein Item, einmal ein Item
  aus der Tasche aufs Feld ziehen, einmal eine Item-ID tippen (z. B. 2589) + Enter. Alle drei erscheinen.
  Rechtsklick auf eine Zeile → entfernen.
- [ ] **A7** Ein Item, das schon in Korb A ist (z. B. Pyrit), in Korb B hinzufügen: Meldung „steht schon im Korb …“.
- [ ] **A8** Phase-Knopf oben rechts: Klick wechselt Beobachten → Sammeln → Halten → Abstoßen.
  „Budget“: 50g eintragen; „Notiz“: Text eintragen. Beides steht danach im Kopf.
- [ ] **A9** Klick auf eine Item-Zeile öffnet die Detailansicht. Kauflimit „1g 20s“, Zielpreis „6g“ bei einem Item mit
  Festpreis 5g (z. B. Pyrit) eintragen, Enter: Meldung „auf 5g begrenzt“. `/reload`: Werte sind noch da.
- [ ] **A10** Detailansicht: Phase-Knopf auf „Sammeln“ für ein Item in einem Korb, der auf „Beobachten“ steht.
  In der Korb-Tabelle steht bei diesem Item „Sammeln (Item)“.

## B – Am Auktionshaus (10 Min.)

- [ ] **B1** Scan. Die Zusammenfassung nennt „Signale: …× Kaufen, …× Verkaufen, …× Verarbeiten lohnt“ und
  „… Items unter Entzauberwert“.
- [ ] **B2** Korb-Tabelle zeigt Preis, Alter und Menge aus dem Scan.
- [ ] **B3** **Kaufsignal:** Item in Phase Sammeln (A10), Kauflimit über den aktuellen Preis setzen → Spalte Signal
  „Kaufen“ (grün), auch im Tooltip.
- [ ] **B4** **Kauf im AH-Fenster** (ein billiges Watchlist-Item, z. B. 2 Pyrit): Chat „… Im Journal gebucht.“
  Detailansicht: Bestand 2, Einstand = gezahlter Preis je Stück.
- [ ] **B5** Zweiter Kauf desselben Items zu anderem Preis: Einstand ist der gewichtete Durchschnitt (von Hand nachrechnen).
- [ ] **B6** Detailansicht → „Markttiefe“: In Phase Sammeln: „Bis zum Kauflimit sind N Stück für zusammen X zu haben.“
  plus „Preis für die ersten 20 Stück“.
- [ ] **B7** **Verkaufssignal:** Item mit Bestand auf Phase „Abstoßen“, Zielpreis unter den aktuellen Nettopreis
  → Signal „Verkaufen“. Markttiefe sagt dann „Unter deinem Zielpreis liegen N Stück vor dir.“
- [ ] **B8** „Kaufen zum Entzaubern“ (Knopf im Kontor-Fenster): Liste öffnet sich (darf leer sein, solange zu
  wenig Entzauberdaten da sind). Falls eine Zeile da ist: Klick sucht das Item im AH-Fenster.

## C – Bestand und Budget (Detailansicht, 3 Min.)

- [ ] **C1** „Verkauf buchen“: „1 5g“ → Bestand sinkt um 1, „Investiert“ im Korbkopf sinkt um 5g.
- [ ] **C2** „Bestand korrigieren“: tatsächliche Stückzahl eintragen → Bestand stimmt.
- [ ] **C3** Neben dem Journal-Bestand steht die Zahl „auf diesem Charakter“; weicht sie ab, steht „(weicht ab)“.
- [ ] **C4** Budget des Korbs unter den investierten Betrag setzen → Kopfzeile rot „Budget überschritten“,
  kein Kaufsignal mehr.

## D – Rezepte (Bankcharakter mit Alchemie, 5 Min.)

- [ ] **D1** „Rezepte“ (unten links im Kontor-Fenster): Liste mit Sulfuric Acid, Cerulean/Magenta/Viridian Dye,
  Sandpaper, Brilliant Wizard/Mana Oil. Unvollständige haben ein orangefarbenes *.
- [ ] **D2** Sulfuric Acid: „Bearbeiten“ → in der Zeile mit „Leere Phiole“ hinter „Händler“ einen Preis eintragen
  (z. B. `Händler 20c`) → Übernehmen. Mit Scan-Preisen für Pyrit und Säure: Zutatenkosten, Produkt netto,
  Spanne und Faktor stehen da. **Faktor von Hand nachrechnen:** Säurepreis × 0,95 ÷ (2 × Pyritpreis + Phiole).
- [ ] **D3** Faktor ≥ 1,5 → „Signal: Verarbeiten lohnt“ (auch in Korb W und im Tooltip von Pyrit).
- [ ] **D4** Einkaufsliste: „10“ eintragen → Berechnen: Pyrit „20 nötig, x vorhanden, 20-x kaufen“.
- [ ] **D5** **Aus dem Berufsfenster:** Alchemie öffnen, mit Umschalt-Klick auf Schwefelsäure den Link ins Feld
  „Aus dem Berufsfenster“ setzen → „Rezept übernehmen“. Status „aus dem Berufsfenster“, Zutaten stimmen.
  Klappt das nicht, bitte die Chat-Meldung schicken.
- [ ] **D6** Sandpaper (Ingenieurskunst, hat kein Charakter): Wenn es rechnet und lohnt, heißt das Signal
  „Verarbeiten lohnt (fremder Beruf)“.

## E – Tooltip (2 Min.)

- [ ] **E1** Pyrit: Preiszeile, „Korb: A - Launch · …“, „Festpreis NPC: 5g“, als letzte Zeile „Verwendung: …“.
- [ ] **E2** `/kontor einstellungen` → Haken „Verwendungs-Notiz im Tooltip“ entfernen → Speichern → Zeile weg.
- [ ] **E3** Grünes Rüstungsteil: Zeile „Entzaubern: ~X (n=…) · Empfehlung: …“ oder „Entzaubern: noch keine Daten“.

## F – Entzaubern (Bankcharakter, 5 Min.)

- [ ] **F1** Ein paar grüne Items entzaubern: Chat wie bisher. Neues Material erscheint einmalig mit
  „in Korb "E - Verzauberung" aufgenommen“.
- [ ] **F2** `/kontor entzauber export`: Oben die Gruppentabelle (Qualität;Klasse;Stufe;n;Material=…), darunter das Protokoll.
- [ ] **F3** „Entzaubern“-Knopf im Kontor-Fenster: Liste der Items mit Empfehlung „Entzaubern“ (erst ab n ≥ 10 in
  der Gruppe; bis dahin ggf. leer). Großer Knopf „Nächstes entzaubern: [Item]“: **ein** Klick entzaubert genau ein Item.
- [ ] **F4** Im Kampf auf den Knopf klicken: nichts passiert, keine Fehlermeldung.
- [ ] **F5** Rechtsklick auf eine Zeile → „Nie entzaubern“: Zeile weg, auch nach `/reload`.
- [ ] **F6** Haken „Arcane Salvager aktiv“ setzen und wieder entfernen: keine Fehlermeldung.
- [ ] **F7** Beim Händler: Ein grünes Item mit Empfehlung „Entzaubern“ steht **nicht** in der Aufräum-Vorschau;
  unten steht „n Items zurückgehalten: besser entzaubern“.

## G – Main ohne Verzauberkunst (5 Min.)

- [ ] **G1** Tooltip eines ungebundenen grünen Teils mit Entzauber-Vorteil: „Empfehlung: an Bankchar schicken“.
- [ ] **G2** Gebundenes Teil: keine Entzauber-Empfehlung (Händler/AH).
- [ ] **G3** Briefkasten: Über dem Postfenster „Kontor: Entzauberware an <Bankchar> (n Items)“. Klick füllt Empfänger
  und Anhänge. **Abschicken selbst drücken.** Kommt „Anhängen per Addon nicht möglich“, bitte melden.

## H – Einstellungen (1 Min.)

- [ ] **H1** `/kontor einstellungen`: AH-Gebühr auf 6 ändern → Speichern → `/reload` → steht noch auf 6. Danach zurück auf 5.

## I – Neu in 0.5.1 (3 Min.)

- [ ] **I1** Auf dem Verzauberer: Minimap-Knopf mit Entzauber-Symbol. Linksklick öffnet das Entzauber-Fenster,
  Rechtsklick das Kontor-Fenster, Ziehen verschiebt ihn (Position bleibt nach `/reload`).
- [ ] **I2** Auf einem Charakter ohne Verzauberkunst: **kein** Minimap-Knopf.
- [ ] **I3** Baganator-Taschen: Symbole oben links (Entzaubern / Münze für Händler / Münze für AH) und oben rechts
  (Tasche = Item im Korb). In Baganators Einstellungen bei den Ecken-Symbolen stehen vier „Kontor: …“-Einträge.
- [ ] **I4** Detailansicht eines Korb-Items: Zeile „Alle Charaktere (Syndicator): N (… Taschen, … Bank …)“.
- [ ] **I5** Kontor-Fenster direkt nach dem Einloggen öffnen: Item-Namen stehen gleich da (höchstens kurz „lädt ...“).

---

**Hinweis:** Signale und Entzauber-Empfehlungen brauchen Daten. Direkt nach der Installation ist vieles noch leer
(kein Bestand, n < 10). Was du nicht sinnvoll prüfen kannst, einfach als „nicht testbar“ markieren.
