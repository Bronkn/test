# Entscheidungen

Abweichungen und Ergänzungen zum Pflichtenheft und den Nachträgen, jeweils vom Nutzer bestätigt.

## 12.10.2026 – Nachtrag 2, Entzaubern

1. **Arcane Salvager:** Der Nutzer hat keinen Salvager, der Buff ist unbekannt. Es gilt der in Nachtrag 2
   vorgesehene Schalter „Salvager aktiv“ im Entzauber-Fenster. Zusätzlich speichert jeder Protokolleintrag
   die Spell-IDs aller Buffs des Charakters zum Zeitpunkt des Entzauberns, damit Einträge später
   nachträglich zugeordnet werden können, falls der Buff bekannt wird.
2. **Fertigkeit:** In Classic und bisher in Forever lässt sich jedes Item mit Fertigkeit 1 entzaubern.
   Abschnitt 4.2 aus Nachtrag 2 entfällt (keine Fertigkeitsprüfung, kein „Fertigkeit unklar“).
   Fehlermeldungen beim Entzaubern werden trotzdem in `deFailures` protokolliert, falls sich das zum
   Launch ändert. Der M5b-Abnahmetest „Entzaubern wegen zu niedriger Fertigkeit“ entfällt.

## 12.10.2026 – Umsetzung M1

- Fensterpositionen liegen in `KontorDB.ui` (im Datenmodell nicht aufgeführt, nötig für Pflichtenheft 6.3).
- Eine neue Installation startet direkt mit Datenmodell-Version 3 (Pflichtenheft + Nachtrag 1 + 2).
  Die Migration von Version 1 (Rezepte aus den Körben nach `KontorDB.recipes`) ist trotzdem eingebaut.
- Zusatzbefehl `/kontor testfehler`, damit sich das Fehlerprotokoll im Spiel prüfen lässt.

## 12.10.2026 – Testen in Blöcken

Der Nutzer testet nebenbei ein weiteres Addon und hat wenig Zeit. Abweichend von Pflichtenheft 6.5
werden mehrere Meilensteine am Stück gebaut und mit einer gemeinsamen Testliste abgenommen.
Erster Block: M2, M3, M4, M5, M5b (alles, was bis zum Beta-Ende am 22.10. stehen muss).
Testliste: `docs/Testliste-M2-M5b.md`.

## 12.10.2026 – Umsetzung M3 bis M5b

- **Tooltip:** Die Zeile wird im Kampf grundsätzlich weggelassen (Pflichtenheft 4.2 „im Zweifel keine Zeile“).
  Schalter bis zum Einstellungsfenster: `/kontor tooltip`.
- **Aufräumen:** Graue Items werden nie vorgeschlagen (Pflichtenheft 7: Verkauf grauer Items nicht enthalten).
  „Nie verkaufen“ per Rechtsklick fragt einmal nach.
- **Kauf-Erkennung (M5):** meldet alle Commodity-Käufe im Chat; das Buchen ins Journal nur für Watchlist-Items folgt mit M8.
- **Entzauber-Protokoll:** Das entzauberte Item wird per Taschenvergleich erkannt: Schnappschuss beim
  Wirken, Vergleich nach der Beute; genau ein verschwundenes Item ist das entzauberte (ab 0.3.5). Zielname
  und Fachsperre liefert Forever nicht (Tests 13.10.2026). Bleibt es unklar, wird nichts protokolliert.
  Der Salvager-Schalter ist bis zum Entzauber-Fenster (M12) der Befehl `/kontor salvager`.
  `/kontor entzauber export` zeigt in M5b das Rohprotokoll; die ausgewertete Gruppentabelle folgt mit M11.

## 13.10.2026 – Kontor-Fenster mit dem AH

Wunsch des Nutzers: Das Kontor-Fenster öffnet sich automatisch mit dem Auktionshaus und schließt mit
ihm (nur wenn es so geöffnet wurde). Standard an, abschaltbar mit `/kontor autoauf`
(Einstellung `autoOpenWithAH`). Ohne gespeicherte Position steht es rechts neben dem AH-Fenster.

## 13.10.2026 – Scan nach Klassen

Der Scan fragt jede Item-Klasse einzeln ab und zum Schluss einmal ohne Filter. Abfragen mit genau
300 Zeilen werden in Unterklassen und Qualitäten aufgeteilt. Ob das nach der Fehlerbehebung in 0.3.2
noch nötig ist, entscheiden die Zahlen aus `/kontor scaninfo`; falls nicht, kann der Scan wieder auf
eine Abfrage reduziert werden (schneller).

Nachtrag 13.10.2026: Die Zahlen (ohne Filter 3133 von 3134 Items) zeigen, dass eine Abfrage reicht.
Ab 0.3.3 fragt der Scan wieder nur einmal ohne Filter ab.

## 13.10.2026 – Verkaufsliste (Wunsch: „AH-Erstellung wie Aufräumen“)

Ein Knopf, der alles einstellt, widerspricht Pflichtenheft 2, 6.1 und 7 und ist technisch nicht möglich
(jede Auktion braucht einen eigenen Klick). Der Nutzer hat Variante 1 gewählt:

- Kontor zeigt eine **Verkaufsliste**; ein Klick legt das Item in Blizzards Verkaufsfenster.
  **Eingestellt wird vom Nutzer** mit Blizzards Knopf. Das Addon stellt nichts selbst ein.
- Kein Unterbieten: Den Preis setzt Blizzard (aktueller Tiefstpreis). Pflichtenheft 7 schließt eine
  Undercut-Automatik aus.
- Inhalt (vom Nutzer offen gelassen, so festgelegt): Taschen-Items, deren AH-Preis nach Gebühr über dem
  Händlerpreis liegt, frischer Preis, gelistet, nicht
  gebunden, keine Quest-Items, **nicht in einem Korb**. Korb-Items in Phase „Abstoßen“ kommen mit M6/M10 dazu.

Nachtrag 0.4.1: Die Mindestgrenze von 10 Silber je Stapel wurde auf Wunsch des Nutzers gestrichen.
