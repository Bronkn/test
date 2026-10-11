# Kontor – Pflichtenheft

AH-Addon für World of Warcraft: Forever. Arbeitstitel „Kontor", Slash-Befehl `/kontor`.

Stand: 11.10.2026 · Beta läuft bis 22.10.2026 · Launch 04.11.2026

---

## 1. Ziel

Das Addon unterstützt eine Vorrats-Strategie, kein Dauer-Flipping:

> Verbrauchsgüter und deren Zutaten kaufen, solange sie beim Leveln als Nebenprodukt anfallen und noch nicht verbraucht werden. Halten. Nach und nach abstoßen, sobald der Bedarf einsetzt (z. B. Raid-Start).

Dafür braucht der Nutzer: aktuelle Preise und Mengen aus dem AH, deren Verlauf über die Zeit, einen Überblick über Bestand und Einstand, und ein klares Signal, wann Kaufen bzw. Verkaufen rentabel ist. Zusätzlich eine Aufräum-Funktion beim Händler.

Gescannt wird mit einem Bankcharakter. Die Daten müssen auf allen Charakteren des Accounts sichtbar sein.

## 2. Rahmenbedingungen

- **Spielversion:** WoW Forever. Der Client nutzt die Interface-Architektur von Retail (Stand 12.1.5) samt deren Addon-Beschränkungen und das neue Auktionshaus (`C_AuctionHouse`, Commodities).
- **Standalone:** Keine Abhängigkeit von Auctionator, TSM oder anderen Addons. Keine externen Bibliotheken, solange es ohne geht.
- **Sprache:** Oberfläche und Meldungen auf Deutsch, mit echten Umlauten. Bezeichner im Code auf Englisch.
- **Der Nutzer liest keinen Code.** Jeder Meilenstein endet mit Abnahmetests, die er im Spiel durchklicken kann (siehe Abschnitt 8). Fehler müssen als kopierbarer Text verfügbar sein (siehe 6.4).
- **Kein Automatisieren von Käufen oder Auktionen.** Gekauft und eingestellt wird über das normale AH-Fenster. Das Addon liest, rechnet und zeigt an.

## 3. Schritt 0: API-Verifikation (vor jeder Zeile Addon-Code)

Alle API-Namen in diesem Dokument sind **Hinweise aus Retail**. Forever übernimmt laut Blizzard „die große Mehrheit" der APIs, nicht alle. Deshalb:

1. Den Blizzard-Interface-Code aus dem Forever-Client exportieren. Auf Retail geht das so: Client mit Startparameter `-console` starten, im Login-Bildschirm die Konsole öffnen (Taste links neben der 1), `ExportInterfaceFiles code` eingeben. Ergebnis ist ein Ordner `BlizzardInterfaceCode` im Spielverzeichnis (in der Beta unter `_classic_beta_`). Weicht das in Forever ab: melden, nicht raten.
2. Im exportierten Code jede in Abschnitt 4 genannte Funktion und jedes Event nachschlagen.
3. Ergebnis in `API-NOTIZEN.md` festhalten: vorhanden / fehlt / weicht ab, mit Fundstelle.
4. Die Interface-Versionsnummer für die `.toc` aus dem Client auslesen lassen (`/dump select(4, GetBuildInfo())`).

**Regel:** Fehlt eine Funktion in Forever, wird gestoppt und dem Nutzer berichtet, mit Alternativen. Kein stilles Umgehen.

Zu prüfen sind mindestens:

| Zweck | Retail-Hinweis |
|---|---|
| AH offen/zu | Events `AUCTION_HOUSE_SHOW`, `AUCTION_HOUSE_CLOSED` |
| Übersichts-Scan | `C_AuctionHouse.SendBrowseQuery`, `GetBrowseResults`, `HasFullBrowseResults`, `RequestMoreBrowseResults`; Events `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED`, `AUCTION_HOUSE_BROWSE_RESULTS_ADDED` |
| Drosselung | `C_AuctionHouse.IsThrottledMessageSystemReady`, Event `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` |
| Markttiefe | `C_AuctionHouse.SendSearchQuery`, `GetNumCommoditySearchResults`, `GetCommoditySearchResultInfo`; Event `COMMODITY_SEARCH_RESULTS_UPDATED` |
| Kauf-Erkennung | `hooksecurefunc` auf `C_AuctionHouse.StartCommoditiesPurchase` / `ConfirmCommoditiesPurchase`; Events `COMMODITY_PRICE_UPDATED`, `COMMODITY_PURCHASE_SUCCEEDED`, `COMMODITY_PURCHASE_FAILED` |
| Tooltip | `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, …)` |
| Händlerpreis | `C_Item.GetItemInfo` (Rückgabewert `sellPrice`), asynchrones Nachladen beachten |
| Tascheninhalt | `C_Container.GetContainerItemInfo` (u. a. `isBound`, `hasNoValue`, `quality`) |
| Händler | Events `MERCHANT_SHOW`, `MERCHANT_CLOSED`; Verkauf über `C_Container.UseContainerItem` |
| Marktkennung | Fraktion (`UnitFactionGroup`), Regelwerk/Realm-Kennung (Forever hat keine Realms; prüfen, was `GetRealmName` o. Ä. liefert) |

## 4. Funktionsumfang

### 4.1 Übersichts-Scan

- Knopf „Scannen" im Kontor-Fenster und am AH-Fenster. Nur aktiv bei offenem AH. Der Scan startet ausschließlich per Klick.
- Blättert das gesamte AH über die Übersichtsabfrage durch und speichert **pro Item-ID**: Tiefstpreis je Stück, Gesamtmenge, Zeitstempel.
- Bei Items mit mehreren Varianten (Ausrüstung mit Suffixen/Stufen): kleinster Preis, Mengen summiert.
- Fortschrittsanzeige (Anzahl gelesener Items, laufende Zeit). Das Spiel darf nicht einfrieren: in Portionen verarbeiten, Drosselung respektieren.
- **Abbruch:** Wird das AH geschlossen, bricht der Scan sauber ab. Bereits gelesene Items behalten ihre neuen Werte, der Scan gilt aber als unvollständig; alle anderen Daten bleiben unverändert.
- **Vollständiger Scan:** Items, die vorher einen Preis hatten und jetzt nicht mehr gelistet sind, behalten ihren letzten Preis samt altem Zeitstempel und bekommen den Vermerk „beim letzten Scan nicht gelistet". Für Watchlist-Items wird in diesem Fall ein Verlaufspunkt mit Menge 0 geschrieben.
- **Nach dem Scan:** Zusammenfassung (Anzahl Items, Dauer, Kauf- und Verkaufssignale) und ein deutlicher Hinweis mit Knopf „Jetzt sichern": WoW schreibt Addon-Daten erst beim Ausloggen oder `/reload` auf die Platte. Der Knopf löst `ReloadUI()` aus.

### 4.2 Tooltip

- An jedem Item-Tooltip mit vorhandenem Scan-Preis: eine Zeile „AH-Tiefstpreis: 1g 20s · vor 3 Std.".
- Altersangabe: unter 60 Min. in Minuten, unter 48 Std. in Stunden, sonst in Tagen. Älter als 24 Std.: Zeile ausgegraut.
- Für Items ohne Scan-Preis: keine Zeile. Ausnahme Watchlist-Items: dort „kein Preis im letzten Scan".
- Für Watchlist-Items zusätzlich: Korb-Name, Einstand, Zielpreis, ggf. Signal („Kaufen" / „Verkaufen").
- Gilt für alle Charaktere des Accounts (Daten accountweit).
- Im Kampf darf das Addon keine Fehler werfen. Im Zweifel dort keine Zeile anzeigen.
- In den Einstellungen abschaltbar.

### 4.3 Taschen aufräumen (beim Händler)

Zweck: Items verkaufen, die im AH weniger bringen als beim Händler.

- Bei offenem Händlerfenster ein Knopf „Kontor: Aufräumen (n Items, Xg)". Ohne Treffer ist der Knopf ausgegraut.
- Klick öffnet eine **Vorschauliste**: Item, Menge, Händlererlös gesamt, AH-Wert netto, Alter des Scan-Preises, Häkchen pro Zeile. Erst „Verkaufen" in der Vorschau verkauft.
- **Ein Item ist Kandidat, wenn alle Bedingungen gelten:**
  1. Händlerpreis > 0.
  2. Scan-Preis vorhanden und nicht älter als die eingestellte Grenze (Standard 48 Std.).
  3. Händlerpreis ≥ AH-Tiefstpreis × (1 − AH-Gebühr) × (1 + Sicherheitsaufschlag). Gebühr Standard 5 %, Aufschlag Standard 0 %, beides einstellbar.
  4. Item ist nicht gebunden (gebundene Items sind keine AH-Entscheidung).
  5. Item steht in keinem Korb und nicht auf der Ausnahmeliste.
  6. Qualität höchstens „Ungewöhnlich" (grün). Grenze einstellbar.
  7. Kein Quest-Item.
- **Items ohne Scan-Preis werden nie angefasst.** „Kein Preis" heißt nicht „wertlos".
- Pro Durchlauf höchstens 12 Stapel, damit alles über den Rückkauf beim Händler zurückholbar bleibt. Sind es mehr, sagt die Vorschau das und der Knopf kann erneut gedrückt werden.
- Nach dem Verkauf: Zusammenfassung im Chat (Anzahl, Erlös).
- Ausnahmeliste: Rechtsklick auf eine Zeile in der Vorschau → „Nie verkaufen".

### 4.4 Körbe (Watchlist)

Ein Korb bündelt die Items einer These, z. B. „Feuerschutz".

- Korb: Name, Notiz, Phase (**Sammeln / Halten / Abstoßen**), Budget in Gold.
- Item im Korb: Kauflimit (Höchstpreis je Stück), Zielpreis (Verkauf je Stück), optional Zielmenge.
- Items hinzufügen: Item-Link per Umschalt-Klick ins Eingabefeld, Item aus der Tasche ziehen, oder Item-ID eintippen.
- Ein Item gehört höchstens zu einem Korb.
- Hauptfenster (`/kontor`): links die Körbe, rechts die Item-Tabelle des gewählten Korbs mit: Item · letzter Preis · Alter · Menge im AH · Trend (gegen vorigen Scan und gegen 7 Tage) · Bestand · Einstand · Break-even · Signal.
- Korb-Kopfzeile: investiert / Budget, aktueller Marktwert des Bestands, unrealisierter Gewinn netto.

### 4.5 Preis- und Mengenverlauf

- Nur für Watchlist-Items. Pro vollständigem Scan ein Datenpunkt: Zeit, Tiefstpreis, Gesamtmenge.
- Höchstens ein Punkt pro Stunde und Item (ein späterer Scan in derselben Stunde ersetzt den Punkt).
- Speicherbegrenzung: Punkte, die älter als 14 Tage sind, werden auf einen Punkt pro Tag verdichtet.
- Anzeige in der Item-Detailansicht. **Stufe 1:** Tabelle der letzten 20 Punkte plus Kennzahlen (Minimum, Maximum, Mittel über 7 und 30 Tage, für Preis und Menge). **Stufe 2:** Liniendiagramm mit Preis und Menge.
- Preis und Menge werden immer als Paar gezeigt. Lesart, die die Oberfläche unterstützen soll: steigende Menge bei fallendem Preis = Sammelphase; schrumpfende Menge bei steigendem Preis = Abstoßen.

### 4.6 Bestand und Einstand

- Ein Buchungsjournal pro Item: Kauf, Verkauf, Korrektur; jeweils Zeit, Menge, Stückpreis, Quelle (automatisch / manuell).
- **Käufe automatisch erfassen**, wenn die API es hergibt (siehe Schritt 0, „Kauf-Erkennung"): Commodity-Käufe im normalen AH-Fenster werden mit Menge und tatsächlich gezahltem Gesamtpreis verbucht, aber nur für Watchlist-Items.
- **Manuell buchen** ist immer möglich: „Kauf buchen", „Verkauf buchen", „Bestand korrigieren".
- Verkäufe werden in Version 1 manuell gebucht. Automatik über die Verkaufspost ist ein späterer, optionaler Ausbau.
- Einstand = gleitender Durchschnittspreis. Break-even je Stück = Einstand ÷ (1 − AH-Gebühr).
- Die Einlage (Deposit) wird nicht eingerechnet, aber als Hinweis genannt: Sie geht verloren, wenn eine Auktion ausläuft oder abgebrochen wird.
- Budget: Investiert = Summe Käufe − Summe Verkaufserlöse des Korbs. Bei Überschreitung des Budgets Warnfarbe, und es gibt kein Kaufsignal mehr.
- Zur Kontrolle neben dem Journal-Bestand: tatsächliche Stückzahl auf dem aktuellen Charakter (Taschen und Bank). Abweichungen nur anzeigen, nicht automatisch korrigieren.

### 4.7 Rezept-Rechnung

- Rezepte werden pro Korb **von Hand angelegt**: Produkt, Ausbeute, Zutaten mit Menge. Kein Auslesen aus dem Berufsfenster in Version 1 (der Bankcharakter hat den Beruf nicht unbedingt).
- Zutaten, die es beim Händler gibt (z. B. Phiolen), bekommen einen festen, von Hand eingetragenen Preis.
- Anzeige pro Rezept: Zutatenkosten zu aktuellen AH-Preisen · Zutatenkosten zum eigenen Einstand · Produktpreis netto · Spanne je Stück. Daraus die Empfehlung „roh verkaufen" oder „brauen lassen".
- Fehlt für eine Zutat ein Preis, wird das Rezept als unvollständig markiert und nicht gerechnet.

### 4.8 Signale und Markttiefe

- **Kaufsignal:** Phase „Sammeln", Tiefstpreis ≤ Kauflimit, Budget nicht ausgeschöpft.
- **Verkaufssignal:** Phase „Halten" oder „Abstoßen", Bestand > 0, Tiefstpreis netto ≥ Zielpreis. Ohne Zielpreis: netto ≥ Break-even × (1 + Mindestmarge, einstellbar, Standard 20 %).
- Signale erscheinen in der Korb-Tabelle, im Tooltip und in der Scan-Zusammenfassung.
- Signale gelten nur, solange der Scan-Preis jünger ist als die eingestellte Grenze.
- **Markttiefe** (Knopf in der Item-Detailansicht, nur bei offenem AH): holt die Preistreppe des Items und zeigt
  - in Phase Sammeln: „Bis zum Kauflimit sind N Stück für zusammen X Gold zu haben."
  - in Phase Abstoßen: „Unter deinem Zielpreis liegen N Stück vor dir."
- Der Übersichts-Scan kennt nur den Tiefstpreis. Ein einzelnes verirrtes Stück kann ihn verzerren. Deshalb zeigt die Detailansicht nach Abruf der Markttiefe zusätzlich den „Preis für die ersten 20 Stück" (Menge einstellbar).

## 5. Datenmodell

Eine accountweite SavedVariable `KontorDB`. Preise sind in Kupfer, Zeiten als Unix-Zeit.

```
KontorDB = {
  version = 1,
  config = {
    ahFee = 0.05,              -- AH-Gebühr, in der Beta zu prüfen
    maxPriceAgeHours = 48,
    cleanupMaxQuality = 2,     -- grün
    cleanupMargin = 0,
    minMargin = 0.20,
    depthUnits = 20,
    tooltipEnabled = true,
  },
  markets = {
    ["<Marktkennung>"] = {     -- mindestens Fraktion, siehe Schritt 0
      lastScan = { t, complete, itemCount, durationSec },
      prices   = { [itemID] = { p = Tiefstpreis, q = Menge, t = Zeit, listed = true/false } },
      history  = { [itemID] = { { t, p, q }, ... } },
    },
  },
  baskets = {
    { id, name, note, phase, budget,
      items   = { [itemID] = { buyLimit, target, targetQty } },
      recipes = { { product, yield, reagents = { { itemID, qty, fixedPrice } } } },
    },
  },
  ledger     = { { t, itemID, basketId, type, qty, unitPrice, source } },
  exclusions = { [itemID] = true },
  errorLog   = { ... },        -- siehe 6.4
}
```

- Die Auktionshäuser der Fraktionen sind getrennt. Preise werden pro Markt abgelegt; angezeigt wird immer der Markt des eingeloggten Charakters.
- Bei Änderungen am Datenmodell: Migration über `version`, niemals vorhandene Daten verwerfen.

## 6. Regeln für die Umsetzung

### 6.1 Sicherheit
- Kein Verkauf beim Händler ohne Vorschau und Bestätigung.
- Kein Kauf, kein Einstellen, kein Abbrechen von Auktionen durch das Addon.
- Keine Eingriffe in geschützte Frames, keine Aktionen im Kampf.

### 6.2 Robustheit
- Item-Daten laden asynchron. Nie davon ausgehen, dass Name oder Händlerpreis sofort verfügbar sind.
- Jede AH-Abfrage kann gedrosselt werden. Warten statt wiederholt senden.
- Ein Fehler in einem Modul darf die anderen nicht lahmlegen.

### 6.3 Oberfläche
- Blizzard-Standardvorlagen, schlicht, gut lesbar. Fenster verschiebbar, Position wird gemerkt.
- Geldbeträge mit Münz-Symbolen. Unter 1 Gold: Silber und Kupfer; ab 1 Gold: Kupfer weglassen.
- Minikarten-Knopf optional, Standard aus.

### 6.4 Fehlerbericht
- Das Addon fängt eigene Fehler ab und schreibt sie mit Zeit, Modul und Meldung in `errorLog` (letzte 50).
- `/kontor fehler` öffnet ein Fenster mit dem Protokoll als markierbarem Text zum Kopieren.
- `/kontor status` zeigt: Addon-Version, Client-Build, Marktkennung, Zeitpunkt des letzten Scans, Anzahl Preise, Anzahl Körbe.

### 6.5 Arbeitsweise
- Ein Meilenstein nach dem anderen. Nach jedem Meilenstein bekommt der Nutzer die Abnahmetests in einfachen Schritten und bestätigt sie, bevor es weitergeht.
- `CHANGELOG.md` und `API-NOTIZEN.md` werden mitgeführt.
- Abweichungen von diesem Dokument werden vorher angesprochen, nicht stillschweigend umgesetzt.

## 7. Bewusst nicht enthalten

- Vendor-Flip (im AH unter Händlerpreis kaufen).
- Sniping, Dauer-Scans, Benachrichtigungen ohne offenes AH.
- Kaufen oder Einstellen über das Addon, Undercut-Automatik.
- Verkauf grauer Items (dafür gibt es eigene Addons).
- Auslesen fremder Preisdatenbanken.
- Komplett-Abzug des AH (`ReplicateItems`).

## 8. Bau-Reihenfolge und Abnahmetests

**Bis zum Beta-Ende am 22.10. müssen M0 bis M5 stehen**, weil sie an der Forever-API hängen. M6 bis M10 sind Logik und Oberfläche und lassen sich auch ohne Spielzugang weitgehend bauen.

### M0 – API-Verifikation
Ergebnis: `API-NOTIZEN.md`, Interface-Version für die `.toc`.
- [ ] Der Nutzer hat den Interface-Code exportiert oder die genannten `/dump`-Befehle ausgeführt und die Ausgaben geliefert.
- [ ] Für jede Zeile der Tabelle in Abschnitt 3 steht fest: vorhanden, fehlt oder weicht ab.

### M1 – Gerüst
- [ ] Das Addon erscheint in der Addon-Liste und lädt ohne Fehlermeldung.
- [ ] `/kontor` öffnet ein leeres Fenster, erneutes `/kontor` schließt es.
- [ ] Fenster verschieben, `/reload`: Das Fenster steht an der neuen Stelle.
- [ ] `/kontor status` zeigt Version, Build und Marktkennung.

### M2 – Übersichts-Scan
- [ ] Ohne offenes AH ist „Scannen" ausgegraut.
- [ ] Am AH: Scan starten, Fortschritt läuft, das Spiel bleibt bedienbar.
- [ ] Der Scan endet mit einer Zusammenfassung (Anzahl Items, Dauer).
- [ ] Drei beliebige Items im normalen AH-Fenster suchen: Der Tiefstpreis stimmt mit `/kontor preis <Item-Link>` überein.
- [ ] Scan starten und das AH währenddessen schließen: Meldung „abgebrochen", keine Fehlermeldung.
- [ ] „Jetzt sichern" drücken: Nach dem Neuladen sind die Preise noch da.
- [ ] Auf einen Charakter der anderen Fraktion wechseln: Dort werden diese Preise nicht angezeigt.

### M3 – Tooltip
- [ ] Mauszeiger auf ein gescanntes Item in der Tasche: Zeile mit Preis und Alter.
- [ ] Mauszeiger auf ein nicht gescanntes Item: keine Zeile.
- [ ] Auf einem anderen Charakter derselben Fraktion: dieselbe Zeile.
- [ ] Item-Link im Chat anklicken: Die Zeile erscheint auch dort.
- [ ] Im Kampf über Items fahren: keine Fehlermeldung.

### M4 – Taschen aufräumen
- [ ] Beim Händler erscheint der Knopf mit Anzahl und Summe.
- [ ] Die Vorschau zeigt nur Items, deren Händlerpreis über dem AH-Nettowert liegt. Zwei Zeilen von Hand nachrechnen.
- [ ] Ein Item ohne Scan-Preis taucht nicht in der Liste auf.
- [ ] Ein gebundenes Item taucht nicht in der Liste auf.
- [ ] Häkchen bei einer Zeile entfernen, verkaufen: Dieses Item bleibt in der Tasche.
- [ ] Verkaufte Items stehen im Rückkauf des Händlers.
- [ ] Rechtsklick „Nie verkaufen": Das Item erscheint beim nächsten Mal nicht mehr.

### M5 – API-Prototypen für später (nur Chat-Ausgabe)
- [ ] Markttiefe: `/kontor tiefe <Item-Link>` bei offenem AH listet Preisstufen und Mengen; der Vergleich mit dem AH-Fenster stimmt.
- [ ] Kauf-Erkennung: Nach einem Commodity-Kauf im normalen AH-Fenster meldet der Chat Item, Menge und gezahlten Gesamtpreis.

### M6 – Körbe
- [ ] Korb anlegen, umbenennen, löschen (mit Rückfrage).
- [ ] Item per Umschalt-Klick, per Ziehen und per Item-ID hinzufügen.
- [ ] Kauflimit und Zielpreis eintragen; nach `/reload` sind sie noch da.
- [ ] Die Tabelle zeigt Preis, Alter und Menge aus dem letzten Scan.
- [ ] Ein Item aus einem Korb erscheint nicht mehr in der Aufräum-Vorschau.

### M7 – Verlauf
- [ ] Nach zwei Scans im Abstand von mehr als einer Stunde hat ein Watchlist-Item zwei Verlaufspunkte.
- [ ] Zwei Scans innerhalb derselben Stunde ergeben einen Punkt.
- [ ] Die Detailansicht zeigt Tabelle und Kennzahlen; der Trend in der Korb-Tabelle passt dazu.

### M8 – Bestand und Einstand
- [ ] Kauf im AH-Fenster: Der Bestand steigt, der Einstand stimmt mit dem gezahlten Preis überein.
- [ ] Zweiter Kauf zu anderem Preis: Der Einstand ist der gewichtete Durchschnitt (von Hand nachrechnen).
- [ ] „Verkauf buchen": Der Bestand sinkt, der investierte Betrag des Korbs sinkt um den Erlös.
- [ ] Budget überschreiten: Warnfarbe in der Korb-Kopfzeile.

### M9 – Rezept-Rechnung
- [ ] Rezept mit zwei AH-Zutaten und einer Händler-Zutat anlegen.
- [ ] Zutatenkosten und Spanne stimmen mit einer Handrechnung überein.
- [ ] Zutat ohne Preis: Das Rezept wird als unvollständig markiert.

### M10 – Signale und Markttiefe in der Oberfläche
- [ ] Kauflimit über den aktuellen Preis setzen, Phase „Sammeln": Kaufsignal in Tabelle und Tooltip.
- [ ] Zielpreis unter den aktuellen Nettopreis setzen, Phase „Abstoßen", Bestand vorhanden: Verkaufssignal.
- [ ] Scan-Preis älter als die Grenze: kein Signal.
- [ ] Die Scan-Zusammenfassung nennt die Zahl der Signale.
- [ ] „Markttiefe" in der Detailansicht zeigt den zur Phase passenden Satz.

## 9. Offene Punkte (in der Beta klären)

1. Höhe der AH-Gebühr und Regeln der Einlage bei Commodities.
2. Werden Commodities regionsweit gehandelt oder pro Regelwerk (Normal / PvP / RP)? Daraus folgt die Marktkennung.
3. Dauer eines Übersichts-Scans bei vollem AH. In der Beta ist das AH klein; der Scan muss auch mit einem Vielfachen der Items stabil laufen.
4. Liefert die Übersichtsabfrage ohne Filter wirklich alle Items, oder ist sie pro Kategorie zu stellen?
5. Sind die Rezepte der Kandidaten gegenüber Classic unverändert?
