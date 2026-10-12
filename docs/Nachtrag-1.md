# Kontor – Nachtrag 1 zum Pflichtenheft

Stand: 12.10.2026

Dieser Nachtrag ergänzt das Pflichtenheft vom 11.10.2026. Wo er etwas Neues festlegt, gilt der Nachtrag. Alles andere bleibt unverändert.

**Vorgehen für Claude Code:** Bereits abgeschlossene Meilensteine nicht neu bauen. Die Änderungen werden in die betroffenen Meilensteine eingearbeitet (Übersicht in Abschnitt 8). Ist ein betroffener Meilenstein schon fertig, wird die Änderung als eigener Schritt nachgezogen und mit den hier genannten Abnahmetests geprüft. Vorher kurz ansagen, welche Dateien angefasst werden.

---

## 1. Hintergrund

Die Strategie hat sich präzisiert. Es gibt jetzt zwei Modi:

- **Umschlagen** (erste Tage nach Launch): Rohstoffe billig kaufen, auf dem Bankcharakter verarbeiten, Produkt sofort verkaufen. Ziel ist, das kleine Startkapital schnell zu vervielfachen. Beispiel aus der Beta: 2 Pyrite zu je 1 Silber ergeben 1 Sulfuric Acid, die für 8 Silber verkauft wurde.
- **Lagern** (danach): Rohstoffe horten, deren Nachfrage erst später einsetzt, und gestaffelt verkaufen.

Der Bankcharakter wird **Alchemist und Verzauberer**. Er scannt, kauft, verarbeitet und verkauft.

Mehrere seltene Materialien haben beim NPC Mister Graphed (Schwarzmarkt, Powderfuse Port) einen **Festpreis ohne Kauflimit**. Damit ist das der faktische Höchstpreis im AH.

## 2. Neue Phase „Beobachten"

Abschnitt 4.4 bekommt eine vierte Phase: **Beobachten / Sammeln / Halten / Abstoßen**.

- In „Beobachten" werden Preis- und Mengenverlauf geschrieben wie bei jedem Watchlist-Item, es gibt aber **kein Kauf- und kein Verkaufssignal**.
- Standardphase für neu angelegte Körbe ist „Beobachten".
- Die Phase gilt wie bisher pro Korb. Zusätzlich kann sie **pro Item** überschrieben werden (Feld leer = Phase des Korbs). Grund: Innerhalb eines Korbs werden Items zu unterschiedlichen Zeiten interessant.

## 3. Festpreis-Obergrenze

Neues optionales Feld pro Item: **Festpreis** (in Kupfer, von Hand eingetragen, vorbelegt laut Abschnitt 6).

- Der Zielpreis darf nicht über dem Festpreis liegen. Wird ein höherer Wert eingegeben, erscheint ein Hinweis, und der Wert wird auf den Festpreis begrenzt.
- Fehlt ein Zielpreis, gilt als Ziel der Festpreis × 0,95 (Faktor einstellbar).
- Liegt der AH-Tiefstpreis über dem Festpreis, zeigt die Tabelle einen Hinweis „über Festpreis – Käufer greifen zum NPC".
- Im Tooltip erscheint bei Items mit Festpreis zusätzlich „Festpreis NPC: 5g".
- Der Händler-Verkaufspreis (Boden) wird zum Vergleich angezeigt. Die Detailansicht zeigt damit die Spanne „Boden – aktueller Preis – Festpreis".

## 4. Verarbeitung (Umschlag-Modus)

Erweitert Abschnitt 4.7 (Rezept-Rechnung).

### 4.1 Signal „Verarbeiten lohnt"
- Für jedes angelegte Rezept: Produktpreis netto (nach AH-Gebühr) ÷ Kosten der Zutaten zu aktuellen AH-Preisen = **Verarbeitungsfaktor**.
- Signal „Verarbeiten lohnt", wenn der Faktor ≥ Schwelle. Schwelle einstellbar, Standard 1,5.
- Zutaten vom Händler (z. B. Phiolen) gehen mit ihrem festen Preis in die Kosten ein.
- Das Signal erscheint in der Korb-Tabelle beim Produkt, in der Scan-Zusammenfassung und im Tooltip von Produkt und Zutaten.
- Es gilt unabhängig von der Phase, auch in „Beobachten", weil Umschlag kurzfristig ist und kein Lagern bedeutet.

### 4.2 Einkaufsliste
In der Detailansicht eines Rezepts: Eingabe „Anzahl Produkte" oder „Budget in Gold". Daraus:
- benötigte Zutaten, abzüglich des Bestands auf dem aktuellen Charakter (Taschen und Bank),
- Kosten zu aktuellen Preisen,
- erwarteter Erlös netto und Gewinn.

Nur Anzeige. Gekauft wird weiter im normalen AH-Fenster.

### 4.3 Rezepte aus dem Berufsfenster übernehmen (optional, Stufe 2)
Da der Bankcharakter die Berufe selbst hat, darf das Addon Rezepte aus dem geöffneten Berufsfenster übernehmen: Knopf „Rezept übernehmen" bei geöffnetem Rezept. Übernommen werden Produkt, Ausbeute und Zutaten mit Mengen. Manuelles Anlegen bleibt möglich.

Voraussetzung: Die nötigen Berufs-APIs sind in Forever vorhanden. In `API-NOTIZEN.md` prüfen und vermerken. Fehlen sie, entfällt dieser Punkt ohne Ersatz.

### 4.4 Ketten
Ein Rezept-Produkt kann selbst Zutat eines anderen Rezepts sein. Das Addon zeigt dann beim Rohstoff alle Rezepte an, in denen er direkt oder über ein Zwischenprodukt steckt (eine Ebene tief genügt).

## 5. Lagerplatz

- Neues optionales Feld pro Item: **Lagerlimit** (Stückzahl).
- Die Korb-Tabelle zeigt pro Item die belegten Lagerplätze: Bestand ÷ Stapelgröße, aufgerundet. Die Stapelgröße liest das Addon aus den Item-Daten.
- Die Korb-Kopfzeile zeigt die Summe der belegten Plätze.
- Ist das Lagerlimit erreicht, gibt es für das Item kein Kaufsignal mehr.

Hinweis: Pristine Leather stapelt laut Wowhead nur bis 20.

## 6. Startkonfiguration der Körbe

Beim ersten Start (oder per `/kontor vorlage`, falls noch keine Körbe existieren) legt das Addon diese Körbe an. Alle Werte sind danach frei änderbar. `/kontor vorlage` überschreibt nie vorhandene Körbe.

Festpreise sind **Beta-Werte** und müssen nach dem Launch überprüft werden. Die Kauflimits bleiben leer, die setzt der Nutzer.

**Korb A – Launch** (Phase: Sammeln)

| Item | ID | Festpreis |
|---|---|---|
| Pyrite | 249391 | 5g |
| Pristine Leather | 249427 | 5g |
| Frilled Lichen | 249399 | 5g |

**Korb B – Früh** (Phase: Beobachten)

| Item | ID | Festpreis |
|---|---|---|
| Grave Moss | 3369 | – |
| Fadeleaf | 3818 | – |
| Iridescent Pearl | 5500 | – |
| Flask of Mojo | 8151 | – |

**Korb C – Mittel** (Phase: Beobachten)

| Item | ID | Festpreis |
|---|---|---|
| Elemental Earth | 7067 | – |
| Elemental Fire | 7068 | – |
| Globe of Water | 7079 | – |
| Firebloom | 4625 | – |
| Purple Lotus | 8831 | – |
| Black Pearl | 7971 | – |
| Flask of Big Mojo | 8152 | – |
| Bauxite | 249425 | 20g |

**Korb D – Spät** (Phase: Beobachten)

| Item | ID | Festpreis |
|---|---|---|
| Pristine Hide | 249428 | 20g |
| Rosecap | 249424 | 20g |
| Pristine Scale | 249429 | 50g |
| Stranglevine | 249274 | 50g |
| Golden Pearl | 13926 | – |
| Essence of Undeath | 12808 | – |
| Guardian Stone | 12809 | – |

**Korb W – Werkstatt** (Phase: Beobachten; hier laufen die Verarbeitungs-Signale)

| Item | ID | Festpreis |
|---|---|---|
| Sulfuric Acid | 249410 | – |
| Cerulean Dye | 249409 | – |
| Viridian Dye | 249431 | – |
| Magenta Dye | 249430 | – |
| Sandpaper | 249432 | – |

**Ausnahme zur Regel „ein Item gehört höchstens zu einem Korb"** (Abschnitt 4.4 des Pflichtenhefts): Zutaten der Werkstatt-Rezepte dürfen zusätzlich in Korb A–D stehen. Rezepte verweisen nur auf Item-IDs, nicht auf Körbe.

**Vorangelegte Rezepte** (nur was bekannt ist; Rest legt der Nutzer an oder übernimmt es aus dem Berufsfenster):

| Produkt | Zutaten | Ausbeute | Status |
|---|---|---|---|
| Sulfuric Acid | 2 × Pyrite | 1 | weitere Zutaten in der Beta prüfen |
| Cerulean Dye | Frilled Lichen, Menge offen | offen | als „unvollständig" anlegen |

## 7. Datenmodell

Ergänzungen zu Abschnitt 5 des Pflichtenhefts. `version` wird auf 2 erhöht. Die Migration von Version 1 ergänzt nur fehlende Felder und verändert keine vorhandenen Werte.

```
KontorDB.config:
  fixedPriceFactor = 0.95,   -- Ziel ohne Zielpreis = Festpreis × Faktor
  craftThreshold   = 1.5,    -- Schwelle für „Verarbeiten lohnt"

Korb:
  type = "lager" | "werkstatt",
  phase = "beobachten" | "sammeln" | "halten" | "abstossen",

Item im Korb (zusätzlich):
  phase      = nil | <Phase>,  -- überschreibt die Korb-Phase
  fixedPrice = nil | Kupfer,
  stockLimit = nil | Stückzahl,

Rezepte:
  wandern von baskets[].recipes nach KontorDB.recipes (korbunabhängig, Schlüssel: Produkt-ID)
  zusätzlich: complete = true/false, source = "manuell" | "berufsfenster"
```

Bestehende Rezepte aus Version 1 werden bei der Migration nach `KontorDB.recipes` verschoben.

## 8. Auswirkungen auf die Meilensteine

| Meilenstein | Änderung |
|---|---|
| M0 | zusätzlich prüfen: Berufs-APIs für 4.3, Stapelgröße aus Item-Daten |
| M3 (Tooltip) | Festpreis-Zeile, Verarbeitungs-Signal |
| M6 (Körbe) | Phase „Beobachten", Phase pro Item, Festpreis, Lagerlimit, Startkonfiguration, Korbtyp |
| M9 (Rezepte) | Rezepte korbunabhängig, Verarbeitungsfaktor, Einkaufsliste, Ketten; Stufe 2: Übernahme aus Berufsfenster |
| M10 (Signale) | Signale berücksichtigen Phase „Beobachten", Festpreis und Lagerlimit; Verarbeitungs-Signal in der Scan-Zusammenfassung |

## 9. Zusätzliche Abnahmetests

**Startkonfiguration**
- [ ] Nach dem ersten Start existieren Korb A, B, C, D und W mit den Items aus Abschnitt 6.
- [ ] `/kontor vorlage` bei vorhandenen Körben: Meldung, nichts wird überschrieben.

**Phasen**
- [ ] Korb in „Beobachten": Verlauf wird geschrieben, kein Kauf- und kein Verkaufssignal.
- [ ] Ein Item auf „Sammeln" setzen, Korb bleibt „Beobachten": Nur dieses Item kann ein Kaufsignal bekommen.

**Festpreis**
- [ ] Zielpreis über dem Festpreis eingeben: Hinweis, Wert wird auf den Festpreis begrenzt.
- [ ] Item ohne Zielpreis mit Festpreis 5g: Verkaufssignal ab 4g 75s netto.
- [ ] Tooltip zeigt „Festpreis NPC".

**Verarbeitung**
- [ ] Rezept Sulfuric Acid mit Pyrite zu 1s und Säure zu 8s: Faktor wird angezeigt und stimmt mit Handrechnung überein (8s × 0,95 ÷ 2s = 3,8). Signal „Verarbeiten lohnt" erscheint.
- [ ] Pyrite-Preis so setzen, dass der Faktor unter 1,5 fällt: Signal verschwindet.
- [ ] Einkaufsliste für 10 Säuren mit 4 Pyrite im Bestand: zeigt 16 Pyrite zu kaufen.
- [ ] Tooltip von Pyrite nennt Sulfuric Acid als Verwendung.
- [ ] Rezept mit Händlerzutat: Händlerpreis geht in die Kosten ein.

**Lagerplatz**
- [ ] 45 Pristine Leather im Bestand: Tabelle zeigt 3 belegte Plätze.
- [ ] Lagerlimit erreicht: kein Kaufsignal mehr.

**Migration**
- [ ] Mit Daten aus Version 1 einloggen: Körbe, Journal und Preise sind vollständig vorhanden, vorhandene Rezepte erscheinen in der neuen Rezeptliste.
