# API-Notizen – Kontor

Ergebnis von **M0 – API-Verifikation** (Pflichtenheft, Abschnitt 3).

Stand: 12.10.2026 · **Status: Block 1 bis 6 erledigt (6.2 und 6.3 entfallen), Block 7 optional offen.**

## Wie diese Datei aufgebaut ist

- **Retail 12.1.0**: Nachgeschlagen in Blizzards erzeugter API-Doku
  (`Blizzard_APIDocumentationGenerated`, Build 12.1.0 (69933), 22.09.2026).
  Das ist nur die Vergleichsbasis. Es sagt **nichts** darüber, ob Forever die Funktion hat.
- **Forever**: Was der Forever-Client wirklich liefert. Diese Spalte füllen wir mit deinen Ausgaben aus dem Spiel.
  Mögliche Werte: ✅ vorhanden · ❌ fehlt · ⚠️ weicht ab.

Fehlt in Forever etwas, wird gestoppt und du bekommst Alternativen (Pflichtenheft, Abschnitt 3, „Regel").

---

## Was du im Spiel tun musst

Es gibt zwei Wege. **Weg B reicht aus**, Weg A ist gründlicher.

### Weg A: Interface-Code exportieren

1. Forever-Client mit dem Startparameter `-console` starten.
2. Im Login-Bildschirm die Konsole öffnen (Taste links neben der 1).
3. `ExportInterfaceFiles code` eingeben.
4. Im Spielverzeichnis sollte jetzt ein Ordner `BlizzardInterfaceCode` liegen.
   Daraus brauche ich den Unterordner `Interface/AddOns/Blizzard_APIDocumentationGenerated`
   (als ZIP schicken oder ins Repo legen).
5. Wenn es den Ordner nicht gibt oder er anders heißt: Bescheid sagen, nicht weitersuchen.

### Weg B: Befehle im Chat eingeben

Einloggen, irgendein Charakter. Jede Zeile einzeln in den Chat kopieren und Enter drücken.
Danach die **gesamte Chat-Ausgabe** abschreiben oder als Screenshot schicken.

**Block 1: Version und Marktkennung** (überall)

```
/dump select(4, GetBuildInfo())
/dump GetBuildInfo()
/dump UnitFactionGroup("player"), GetRealmName(), GetNormalizedRealmName(), GetCurrentRegion(), GetCurrentRegionName()
```

**Block 2: Funktionen** (überall). Erwartet wird jeweils `function`. Steht dort `nil`, fehlt die Funktion.

```
/run local a=C_AuctionHouse or {} for _,n in ipairs({"SendBrowseQuery","GetBrowseResults","HasFullBrowseResults","RequestMoreBrowseResults","IsThrottledMessageSystemReady"}) do print(n, type(a[n])) end
/run local a=C_AuctionHouse or {} for _,n in ipairs({"SendSearchQuery","GetNumCommoditySearchResults","GetCommoditySearchResultInfo","StartCommoditiesPurchase","ConfirmCommoditiesPurchase"}) do print(n, type(a[n])) end
/run print("TooltipDataProcessor", type(TooltipDataProcessor), "Item-Typ", Enum.TooltipDataType and Enum.TooltipDataType.Item, "hooksecurefunc", type(hooksecurefunc))
/run print("C_Item.GetItemInfo", type(C_Item and C_Item.GetItemInfo), "C_Container.GetContainerItemInfo", type(C_Container and C_Container.GetContainerItemInfo), "UseContainerItem", type(C_Container and C_Container.UseContainerItem))
```

**Block 3: Events** (überall). Erwartet wird jeweils `true`. `false` heißt: Das Event gibt es nicht.

```
/run local f=CreateFrame("Frame") for _,e in ipairs({"SHOW","CLOSED","BROWSE_RESULTS_UPDATED","BROWSE_RESULTS_ADDED","THROTTLED_SYSTEM_READY"}) do e="AUCTION_HOUSE_"..e print(e,(pcall(f.RegisterEvent,f,e))) end
/run local f=CreateFrame("Frame") for _,e in ipairs({"COMMODITY_SEARCH_RESULTS_UPDATED","COMMODITY_PRICE_UPDATED","COMMODITY_PURCHASE_SUCCEEDED","COMMODITY_PURCHASE_FAILED","MERCHANT_SHOW","MERCHANT_CLOSED"}) do print(e,(pcall(f.RegisterEvent,f,e))) end
```

**Block 4: Rückgabewerte** (überall)

1. Irgendein Item in den **ersten Platz des Rucksacks** legen (oben links), dann:
   ```
   /dump C_Container.GetContainerItemInfo(0, 1)
   ```
   Ich prüfe, ob `isBound`, `hasNoValue` und `quality` dabei sind.
2. Leinenstoff (Item 2589) als Test für den Händlerpreis. **Zweimal** eingeben,
   beim ersten Mal kann die Antwort leer sein, weil die Daten erst nachgeladen werden:
   ```
   /dump C_Item.GetItemInfo(2589)
   ```

**Block 5: Zusatzprüfungen aus Nachtrag 1 und 2** (überall). Erwartet: `function` bzw. `true`.

```
/run for _,n in ipairs({"GetProfessions","GetProfessionInfo","GetNumLootItems","GetLootSlotInfo","GetLootSlotLink","ClickSendMailItemButton"}) do print(n, type(_G[n])) end
/run local t=C_TradeSkillUI or {} for _,n in ipairs({"GetRecipeSchematic","GetRecipeInfo","GetAllRecipeIDs"}) do print(n,type(t[n])) end print("Auren",type(C_UnitAuras and C_UnitAuras.GetAuraDataByIndex))
/run local f=CreateFrame("Frame") for _,e in ipairs({"UNIT_SPELLCAST_SUCCEEDED","LOOT_READY","LOOT_OPENED","LOOT_CLOSED","UI_ERROR_MESSAGE","TRADE_SKILL_SHOW","MAIL_SHOW"}) do print(e,(pcall(f.RegisterEvent,f,e))) end
/run local ok=pcall(CreateFrame,"Button","KontorTestKnopf",UIParent,"SecureActionButtonTemplate") print("Gesicherter Knopf", ok)
```

**Block 6: Auf dem Verzauberer** (Bankcharakter, nicht im Kampf)

1. Prüfen, ob „Entzaubern" bekannt ist (Zauber 13262 ist in Classic „Entzaubern"):
   ```
   /dump C_SpellBook.IsSpellKnown(13262), C_Spell.GetSpellName(13262)
   ```
2. **Arcane Salvager** aufstellen, reinstellen, dann deine Buffs auflisten lassen:
   ```
   /run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i) if not a then break end print(i,a.name,a.spellId) end
   ```
   Denselben Befehl noch einmal **ohne** Salvager. Ich vergleiche die beiden Listen.
3. Ein Item entzaubern, für das deine Fertigkeit **nicht** reicht. Den genauen roten Text oben
   im Bild abschreiben.
4. Ein normales grünes Item entzaubern. Nur sagen: Ging ein Beutefenster auf, oder landete alles
   direkt in der Tasche?
5. Berufsfenster Alchemie öffnen, Sulfuric Acid anklicken, Screenshot.

**Block 7: Marktkennung** (nur wenn du Zeit hast)

Block 1 auf einem Charakter der **anderen Fraktion** wiederholen. Und, falls es in Forever
unterschiedliche Regelwerke gibt (Normal / PvP / RP), auf je einem Charakter pro Regelwerk.

---

## Ergebnis-Tabelle

| Zweck | Name | Retail 12.1.0 | Forever | Anmerkung |
|---|---|---|---|---|
| AH offen/zu | Event `AUCTION_HOUSE_SHOW` | ✅ AuctionHouseDocumentation | ✅ | |
| | Event `AUCTION_HOUSE_CLOSED` | ✅ AuctionHouseDocumentation | ✅ | |
| Übersichts-Scan | `C_AuctionHouse.SendBrowseQuery` | ✅ | ✅ | Argument: `AuctionHouseBrowseQuery` |
| | `C_AuctionHouse.GetBrowseResults` | ✅ | ✅ | Liefert `BrowseResultInfo`: `itemKey`, `totalQuantity`, `minPrice` |
| | `C_AuctionHouse.HasFullBrowseResults` | ✅ | ✅ | |
| | `C_AuctionHouse.RequestMoreBrowseResults` | ✅ | ✅ | |
| | Event `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` | ✅ | ✅ | |
| | Event `AUCTION_HOUSE_BROWSE_RESULTS_ADDED` | ✅ | ✅ | Payload: `addedBrowseResults` |
| Drosselung | `C_AuctionHouse.IsThrottledMessageSystemReady` | ✅ | ✅ | |
| | Event `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` | ✅ | ✅ | |
| Markttiefe | `C_AuctionHouse.SendSearchQuery` | ✅ | ✅ | |
| | `C_AuctionHouse.GetNumCommoditySearchResults` | ✅ | ✅ | |
| | `C_AuctionHouse.GetCommoditySearchResultInfo` | ✅ | ✅ | Argumente `itemID`, Index |
| | Event `COMMODITY_SEARCH_RESULTS_UPDATED` | ✅ | ✅ | |
| Kauf-Erkennung | `C_AuctionHouse.StartCommoditiesPurchase` | ✅ | ✅ | Argumente `itemID`, `quantity`. In Retail als `HasRestrictions` markiert, Hook muss praktisch getestet werden (M5) |
| | `C_AuctionHouse.ConfirmCommoditiesPurchase` | ✅ | ✅ | Argumente `itemID`, `quantity` |
| | Event `COMMODITY_PRICE_UPDATED` | ✅ | ✅ | Payload: `updatedUnitPrice`, `updatedTotalPrice` |
| | Event `COMMODITY_PURCHASE_SUCCEEDED` | ✅ | ✅ | **Ohne Payload.** Item und Menge müssen aus dem Hook gemerkt werden |
| | Event `COMMODITY_PURCHASE_FAILED` | ✅ | ✅ | |
| Tooltip | `TooltipDataProcessor.AddTooltipPostCall` | ✅ Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua | ✅ | `TooltipDataProcessor` ist `table`, `Enum.TooltipDataType.Item` = `0`, `hooksecurefunc` vorhanden |
| Händlerpreis | `C_Item.GetItemInfo` → `sellPrice` | ✅ ItemDocumentation | ✅ | Reihenfolge der Rückgabewerte wie Retail. Leinenstoff: `sellPrice` (11.) = 13 Kupfer, Qualität 1, `isCraftingReagent` true. Erster Aufruf lieferte sofort Daten |
| Tascheninhalt | `C_Container.GetContainerItemInfo` | ✅ ContainerDocumentation | ✅ | Felder `isBound`, `hasNoValue`, `quality` vorhanden. Forever: Rucksack Platz 1 lieferte `empty result` (leerer Platz?), Wiederholung ausstehend |
| Händler | Event `MERCHANT_SHOW` | ✅ MerchantFrameDocumentation | ✅ | |
| | Event `MERCHANT_CLOSED` | ✅ MerchantFrameDocumentation | ✅ | |
| | `C_Container.UseContainerItem` | ✅ ContainerDocumentation | ✅ | |
| Marktkennung | `UnitFactionGroup` | ✅ UnitDocumentation | ✅ | `"Horde"` |
| | `GetRealmName` / `GetNormalizedRealmName` | ✅ | ✅ | `"Classic Beta PvP"` / `"ClassicBetaPvP"`. Der Name enthält das Regelwerk |
| | `GetCurrentRegion` / `GetCurrentRegionName` | ✅ | ⚠️ | `110` / `""` (leer). Ungewöhnliche Region, vermutlich Beta-intern. Nicht für die Marktkennung verwenden |

### Ergänzungen aus Nachtrag 1 und 2

| Zweck | Name | Retail 12.1.0 | Forever | Anmerkung |
|---|---|---|---|---|
| Stapelgröße | `C_Item.GetItemInfo` → `itemStackCount` | ✅ ItemDocumentation | ✅ | 8. Rückgabewert. Leinenstoff: 20 (wie Classic) |
| Berufe (Rezept übernehmen) | `C_TradeSkillUI.GetRecipeSchematic`, `GetRecipeInfo` | ✅ TradeSkillUIDocumentation | ✅ | Zusätzlich vorhanden: `C_TradeSkillUI.GetAllRecipeIDs` (fehlt in der Retail-Doku). Screenshot Block 6.5: Berufsfenster zeigt Rezept, Zutaten und Mengen (Schwefelsäure: 2 × Pyrit, 1 × Leere Phiole). Übernahme (Nachtrag 1, 4.3) erscheint machbar |
| | Event `TRADE_SKILL_SHOW` | ✅ | ✅ | |
| | `GetProfessions` / `GetProfessionInfo` | Altfunktion, nicht in der Doku | ✅ | für Fertigkeitswert Verzauberkunst |
| Entzaubern erkennen | Event `UNIT_SPELLCAST_SUCCEEDED` | ✅ UnitDocumentation | ✅ | |
| | Events `LOOT_READY`, `LOOT_OPENED`, `LOOT_CLOSED` | ✅ LootDocumentation | ✅ | |
| | `GetNumLootItems`, `GetLootSlotInfo`, `GetLootSlotLink` | Altfunktionen | ✅ | |
| | `C_SpellBook.IsSpellKnown(13262)` | ✅ SpellBookDocumentation | ✅ | `true`, Name „Entzaubern“. Spell-ID 13262 gilt auch in Forever |
| | Beutefenster nach Entzaubern | – | ✅ | Ein Beutefenster („Gegenstände“) öffnet sich, Ergebnis im Test: 2 × Seelenstaub (neues Material, Qualität „Verbreitet“) |
| Fertigkeit zu niedrig | Event `UI_ERROR_MESSAGE` | ✅ SystemDocumentation | ✅ | Praxistest entfällt: Laut Nutzer lässt sich in Classic und bisher in Forever jedes Item mit Fertigkeit 1 entzaubern (12.10.2026). genauer Text aus Block 6.3 |
| Salvager-Buff | `C_UnitAuras.GetAuraDataByIndex` | ✅ UnitAuraDocumentation | ✅ | Praxistest entfällt: Nutzer hat keinen Arcane Salvager. Buff-Name/ID unbekannt. Buff-Name/ID aus Block 6.2 |
| „Nächstes entzaubern" | `SecureActionButtonTemplate` | ✅ | ✅ | Knopf ließ sich anlegen. Wirkt der Knopf wirklich, zeigt erst M12 |
| Post befüllen | `C_Container.PickupContainerItem`, `ClickSendMailItemButton` | ✅ / Altfunktion | ✅ (nur `ClickSendMailItemButton` geprüft) | Wirklich erlaubt? Zeigt erst M13 |
| | Event `MAIL_SHOW` | ✅ MailInfoDocumentation | ✅ | |

### Zusätzlich verwendet ab Version 0.3.0 (in Forever noch nicht einzeln geprüft)

Fehlt eines davon, lädt das Addon trotzdem; der Fehler steht dann in `/kontor fehler`.

| Name | Wofür |
|---|---|
| `C_XMLUtil.GetTemplateInfo` | prüft, ob Fenstervorlagen vorhanden sind |
| `C_Timer.After` | verzögerte Neuberechnung beim Händler, Zeitlimit Markttiefe |
| Events `BAG_UPDATE_DELAYED`, `GET_ITEM_INFO_RECEIVED` | Aufräumen-Knopf aktuell halten |
| `C_Container.GetContainerItemQuestInfo` | Quest-Items beim Aufräumen ausschließen |
| `C_AuctionHouse.MakeItemKey`, Events `COMMODITY_SEARCH_RESULTS_ADDED`, `ITEM_SEARCH_RESULTS_UPDATED` | Markttiefe |
| Events `UNIT_SPELLCAST_START`, `UNIT_SPELLCAST_FAILED`, `UNIT_SPELLCAST_INTERRUPTED` | Entzaubern erkennen |
| `GetLootSourceInfo` | Beute stammt vom Item, nicht von einem Gegner |
| `C_Item.GetDetailedItemLevelInfo` | genaue Gegenstandsstufe |
| `issecretvalue` | erkennt vom Spiel verborgene Werte (optional) |

## Erkenntnisse zu Rezepten

- Händlerzutat von Sulfuric Acid (Schwefelsäure) ist **Leere Phiole** (Classic-ID 3371, in Forever noch zu bestätigen).
- Deutsche Namen: Sulfuric Acid = Schwefelsäure, Cerulean Dye = Himmelblauer Farbstoff, Pyrite = Pyrit.

## Interface-Version für die `.toc`

**16001** (aus `/dump select(4, GetBuildInfo())`, 12.10.2026)

Vollständige Ausgabe von `GetBuildInfo()`: `"1.60.1"`, `"70338"`, `"Oct  9 2026"`, `16001`.

⚠️ Die Spielversion heißt **1.60.1**, nicht 12.x wie Retail. Das Pflichtenheft geht von der
Retail-Architektur 12.1.5 aus. Ob die Funktionen trotzdem wie in Retail heißen, zeigen Block 2 bis 5.

## Marktkennung (Vorschlag)

`<GetNormalizedRealmName()>-<UnitFactionGroup()>`, in der Beta also `ClassicBetaPvP-Horde`.

- Der Realm-Name enthält das Regelwerk (hier PvP). Damit sind Normal / PvP / RP automatisch getrennt.
  Ob das richtig ist oder Commodities regionsweit gehandelt werden, bleibt offener Punkt 2 im Pflichtenheft.
- Zum Launch ändert sich der Name. Beta-Preise landen dann unter einer anderen Kennung und werden
  auf dem Live-Server nicht angezeigt. Das ist gewollt, Beta-Preise taugen dort nicht.

## Beobachtungen aus der Retail-Doku

- `COMMODITY_PURCHASE_SUCCEEDED` liefert weder Item noch Menge. Die Kauf-Erkennung muss sich
  Item und Menge beim Aufruf von `StartCommoditiesPurchase`/`ConfirmCommoditiesPurchase` merken und
  den Gesamtpreis aus `COMMODITY_PRICE_UPDATED` nehmen. Das ist so in M5 zu prüfen.
- Mehrere AH-Funktionen tragen in Retail die Markierung `SecretArguments = "AllowedWhenUntainted"`.
  Für reine Lese-Abfragen eines Addons sollte das kein Problem sein, wird aber in M2 praktisch bestätigt.
