# Kontor – Nachtrag 3 zum Pflichtenheft: Startrezepte und Körbe

Stand: 12.10.2026, Fassung 2 (ersetzt die erste Fassung vom selben Tag vollständig)

Ergänzt Pflichtenheft, Nachtrag 1 und Nachtrag 2. Betrifft nur die Startkonfiguration (Nachtrag 1, Abschnitt 6) und ein kleines Zusatzfeld. Keine neuen Meilensteine.

---

## 1. Herkunft der Daten

Die Rezepte unten stammen aus Wowhead-Daten der Beta, vom Nutzer per Screenshot und Tooltip geprüft. Händlerzutaten (Phiolen, Fläschchen) sind nicht namentlich bekannt und stehen als „Händlerzutat, ID offen".

**Regel:** Vorangelegte Rezepte haben `source = "vorlage"`. Sobald der Bankcharakter ein Rezept über „Rezept übernehmen" (Nachtrag 1, 4.3) aus dem Berufsfenster einliest, ersetzt die Übernahme die Vorlage vollständig, einschließlich aller Zutaten-IDs. Ist 4.3 nicht umsetzbar, korrigiert der Nutzer die Vorlage von Hand.

## 2. Startrezepte (ersetzt die Tabelle „Vorangelegte Rezepte" in Nachtrag 1)

Alle Ausbeuten 1.

| Produkt | ID | Beruf | Zutaten | Status |
|---|---|---|---|---|
| Sulfuric Acid | 249410 | Alchemie 50 | 2 × Pyrite (249391), 1 × Händlerzutat | unvollständig (Händlerzutat) |
| Cerulean Dye | 249409 | Alchemie 50 | 2 × Frilled Lichen (249399), 1 × Händlerzutat | unvollständig (Händlerzutat) |
| Magenta Dye | 249430 | Alchemie 130 | 2 × Rosecap (249424), 1 × Händlerzutat | unvollständig (Händlerzutat) |
| Viridian Dye | 249431 | Alchemie 230 | 2 × Stranglevine (249274), 1 × Händlerzutat | unvollständig (Händlerzutat) |
| Sandpaper | 249432 | Ingenieurskunst 130 | 2 × Bauxite (249425), 1 × weitere Zutat (ID offen) | unvollständig |
| Brilliant Wizard Oil | – | Verzauberkunst 300 | 2 × Illusion Dust, 3 × Firebloom (4625), 1 × Händlerzutat | unvollständig (IDs) |
| Brilliant Mana Oil | – | Verzauberkunst 300 | 2 × Illusion Dust, 3 × Purple Lotus (8831), 1 × Händlerzutat | unvollständig (IDs) |

Hinweise:
- **Sandpaper** wird mit Ingenieurskunst hergestellt, die der Bankcharakter nicht hat. Das Rezept dient nur der Rechnung und als Nachfrage-Anzeiger für Bauxite. Das Signal „Verarbeiten lohnt" wird für Rezepte eines Berufs, den kein Charakter des Accounts hat, als „Verarbeiten lohnt (fremder Beruf)" angezeigt.
- Die beiden **Öle** dienen vor allem als Nachfrage-Anzeiger für Firebloom und Purple Lotus.

## 3. Verwendungs-Notiz pro Item

Neues optionales Textfeld pro Watchlist-Item: **Verwendung** (Freitext, höchstens 200 Zeichen). Anzeige in der Detailansicht und als letzte Zeile im Tooltip (abschaltbar). Zweck: Der Nutzer sieht beim Handeln, wofür das Item gebraucht wird.

Vorbelegung:

| Item | Verwendung |
|---|---|
| Pyrite | Sulfuric Acid (2:1); Halskette Healing Power; Waffe Insight/Recovery; Shining-Set Schneiderei 60–125; Glimmering Staff |
| Frilled Lichen | Cerulean Dye (2:1); Waffe Insight direkt |
| Rosecap | Magenta Dye (2:1); Halskette Healing Power direkt |
| Stranglevine | Viridian Dye (2:1) → Mooncloth- und Bottomless-Taschen |
| Bauxite | Sandpaper (2:1, Ingenieurskunst) → Plattenrüstung Schmiedekunst |
| Purple Lotus | Brilliant Mana Oil, Dreamless Sleep, Sentinel's-Set, Cenarion Herb Bag |
| Firebloom | Brilliant Wizard Oil, Philosopher's Stone |
| Globe of Water | Frothing- und Netherfroth-Set Schneiderei 140–235, Justicar's-Set Schmiedekunst |
| Golden Pearl | Prefect's-Set Schmiedekunst 175–270 (4–10 je Teil) |
| Black Pearl | Warder's-Set Schmiedekunst 175–270 (4–10 je Teil) |
| Sulfuric Acid | Halskette Agility/Strength (je 4); Plattenrüstung Schmiedekunst 150–270 (5 Sets) |
| Cerulean Dye | Halskette Deflection/Spell Power (je 4); Shining-, Frothing-Set; Taschen |
| Magenta Dye | Halskette Agility/Deflection/Spell Power (je 4); Frothing-Set; Taschen |
| Viridian Dye | Mooncloth- und Bottomless-Taschen (8–10 je Tasche) |
| Sandpaper | Plattenrüstung Schmiedekunst (4–6 je Teil) |

## 4. Änderungen an den Körben (Nachtrag 1, Abschnitt 6)

- **Korb A – Launch:** unverändert (Pyrite, Pristine Leather, Frilled Lichen).
- **Korb C – Mittel:** Globe of Water an die erste Stelle. Rosecap aus Korb D hierher verschieben (Magenta Dye ab Alchemie 130).
- **Korb D – Spät:** Purple Lotus und Firebloom aus Korb C hierher verschieben (Nachfrage vor allem über die Öle auf Stufe 300, also Raid-Verbrauchsgüter).
- **Korb W – Werkstatt:** Brilliant Wizard Oil und Brilliant Mana Oil ergänzen. Item-IDs bei der Umsetzung nachschlagen oder bei der Übernahme aus dem Berufsfenster setzen; bis dahin ohne ID nicht anlegen.

Die Festpreise aus Nachtrag 1 bleiben: Rosecap und Bauxite 20g, Stranglevine 50g.

## 5. Abnahmetests

- [ ] Neue Installation: Korb W enthält die Rezepte aus Abschnitt 2, unvollständige sind als solche markiert und werden nicht gerechnet.
- [ ] Sulfuric Acid über „Rezept übernehmen" einlesen: Die Vorlage wird vollständig ersetzt, Status „vollständig", `source = "berufsfenster"`.
- [ ] Sandpaper vollständig angelegt, Faktor über der Schwelle: Signal lautet „Verarbeiten lohnt (fremder Beruf)".
- [ ] Tooltip von Pyrite zeigt die Verwendungs-Notiz als letzte Zeile; abschaltbar.
- [ ] Rosecap steht in Korb C, Purple Lotus und Firebloom in Korb D.
- [ ] Bestehende Installation (Nachtrag 1 schon umgesetzt): Vorhandene Körbe und vom Nutzer geänderte Rezepte bleiben unverändert. Nur fehlende Vorlagen und leere Verwendungs-Notizen werden ergänzt.
