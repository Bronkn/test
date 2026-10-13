# Kontor – Checkliste zum Launch (04.11.2026)

## Vor dem ersten Einloggen auf Live

- [ ] **Entzauber-Daten aus der Beta mitnehmen.** Beta und Live haben getrennte Ordner, die Daten wandern nicht von selbst.
  Datei kopieren:
  `World of Warcraft\_classic_beta_\WTF\Account\<ACCOUNTNAME>\SavedVariables\Kontor.lua`
  nach
  `World of Warcraft\<Live-Ordner>\WTF\Account\<ACCOUNTNAME>\SavedVariables\Kontor.lua`
  (Spiel dabei geschlossen). Damit kommen Entzauber-Protokoll, Körbe, Rezepte und Einstellungen mit.
  Beta-Preise stören nicht: Sie hängen an der Beta-Marktkennung und werden auf Live nicht angezeigt.
- [ ] Addon-Ordner `Kontor` auch in den Live-AddOns-Ordner kopieren.

## Erster Abend auf Live

- [ ] Erscheint Kontor in der Addon-Liste als „veraltet“, hat Blizzard die Interface-Nummer geändert:
  `/dump select(4, GetBuildInfo())` ausführen und mir die Zahl schicken (oder „Veraltete AddOns laden“ anhaken).
- [ ] `/kontor status`: Markt zeigt den Live-Realm.
- [ ] `/kontor fehler`: leer? Sonst kopieren und schicken.
- [ ] Ersten Scan machen, Zahl der Items notieren.

## In den ersten Tagen prüfen

- [ ] **Festpreise** der Startkörbe (Nachtrag 1) sind Beta-Werte: beim NPC Mister Graphed nachsehen und im Kontor anpassen.
- [ ] **AH-Gebühr** (Pflichtenheft, offener Punkt 1): stimmt 5 %? Sonst in den Einstellungen ändern.
- [ ] **Gemeinsames AH beider Fraktionen?** Wenn ja: Bescheid sagen, dann trenne ich den Markt nur noch nach Realm.
- [ ] **Leere Phiole** (Händlerzutat Schwefelsäure): Rezept aus dem Berufsfenster übernehmen und Festpreis eintragen.
- [ ] **Öl-Rezepte** auf Verzauberkunst 300 aus dem Berufsfenster übernehmen, sobald gelernt.

## Noch nicht im Spiel getestet

Aus `docs/Testliste-M6-M14.md` alles, was nicht abgehakt ist, vor allem:
Kauf-Erkennung ins Journal, Rezept-Übernahme aus dem Berufsfenster, „Nächstes entzaubern“-Knopf,
Briefkasten-Knopf, Baganator-Symbole, Syndicator-Zahlen. Fehler landen in `/kontor fehler`.
