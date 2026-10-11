# API-Notizen – Kontor

Ergebnis von **M0 – API-Verifikation** (Pflichtenheft, Abschnitt 3).

Stand: 11.10.2026 · **Status: offen. Die Ergebnisse aus dem Forever-Client fehlen noch.**

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

**Block 5: Marktkennung** (nur wenn du Zeit hast)

Block 1 auf einem Charakter der **anderen Fraktion** wiederholen. Und, falls es in Forever
unterschiedliche Regelwerke gibt (Normal / PvP / RP), auf je einem Charakter pro Regelwerk.

---

## Ergebnis-Tabelle

| Zweck | Name | Retail 12.1.0 | Forever | Anmerkung |
|---|---|---|---|---|
| AH offen/zu | Event `AUCTION_HOUSE_SHOW` | ✅ AuctionHouseDocumentation | offen | |
| | Event `AUCTION_HOUSE_CLOSED` | ✅ AuctionHouseDocumentation | offen | |
| Übersichts-Scan | `C_AuctionHouse.SendBrowseQuery` | ✅ | offen | Argument: `AuctionHouseBrowseQuery` |
| | `C_AuctionHouse.GetBrowseResults` | ✅ | offen | Liefert `BrowseResultInfo`: `itemKey`, `totalQuantity`, `minPrice` |
| | `C_AuctionHouse.HasFullBrowseResults` | ✅ | offen | |
| | `C_AuctionHouse.RequestMoreBrowseResults` | ✅ | offen | |
| | Event `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` | ✅ | offen | |
| | Event `AUCTION_HOUSE_BROWSE_RESULTS_ADDED` | ✅ | offen | Payload: `addedBrowseResults` |
| Drosselung | `C_AuctionHouse.IsThrottledMessageSystemReady` | ✅ | offen | |
| | Event `AUCTION_HOUSE_THROTTLED_SYSTEM_READY` | ✅ | offen | |
| Markttiefe | `C_AuctionHouse.SendSearchQuery` | ✅ | offen | |
| | `C_AuctionHouse.GetNumCommoditySearchResults` | ✅ | offen | |
| | `C_AuctionHouse.GetCommoditySearchResultInfo` | ✅ | offen | Argumente `itemID`, Index |
| | Event `COMMODITY_SEARCH_RESULTS_UPDATED` | ✅ | offen | |
| Kauf-Erkennung | `C_AuctionHouse.StartCommoditiesPurchase` | ✅ | offen | Argumente `itemID`, `quantity`. In Retail als `HasRestrictions` markiert, Hook muss praktisch getestet werden (M5) |
| | `C_AuctionHouse.ConfirmCommoditiesPurchase` | ✅ | offen | Argumente `itemID`, `quantity` |
| | Event `COMMODITY_PRICE_UPDATED` | ✅ | offen | Payload: `updatedUnitPrice`, `updatedTotalPrice` |
| | Event `COMMODITY_PURCHASE_SUCCEEDED` | ✅ | offen | **Ohne Payload.** Item und Menge müssen aus dem Hook gemerkt werden |
| | Event `COMMODITY_PURCHASE_FAILED` | ✅ | offen | |
| Tooltip | `TooltipDataProcessor.AddTooltipPostCall` | ✅ Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua | offen | |
| Händlerpreis | `C_Item.GetItemInfo` → `sellPrice` | ✅ ItemDocumentation | offen | |
| Tascheninhalt | `C_Container.GetContainerItemInfo` | ✅ ContainerDocumentation | offen | Felder `isBound`, `hasNoValue`, `quality` vorhanden |
| Händler | Event `MERCHANT_SHOW` | ✅ MerchantFrameDocumentation | offen | |
| | Event `MERCHANT_CLOSED` | ✅ MerchantFrameDocumentation | offen | |
| | `C_Container.UseContainerItem` | ✅ ContainerDocumentation | offen | |
| Marktkennung | `UnitFactionGroup` | ✅ UnitDocumentation | offen | |
| | `GetRealmName` / `GetNormalizedRealmName` | ✅ | offen | Was liefert Forever ohne Realms? |
| | `GetCurrentRegion` / `GetCurrentRegionName` | ✅ | offen | Zusätzlich aufgenommen, als Teil der Marktkennung denkbar |

## Interface-Version für die `.toc`

offen (Ausgabe von `/dump select(4, GetBuildInfo())`)

## Beobachtungen aus der Retail-Doku

- `COMMODITY_PURCHASE_SUCCEEDED` liefert weder Item noch Menge. Die Kauf-Erkennung muss sich
  Item und Menge beim Aufruf von `StartCommoditiesPurchase`/`ConfirmCommoditiesPurchase` merken und
  den Gesamtpreis aus `COMMODITY_PRICE_UPDATED` nehmen. Das ist so in M5 zu prüfen.
- Mehrere AH-Funktionen tragen in Retail die Markierung `SecretArguments = "AllowedWhenUntainted"`.
  Für reine Lese-Abfragen eines Addons sollte das kein Problem sein, wird aber in M2 praktisch bestätigt.
