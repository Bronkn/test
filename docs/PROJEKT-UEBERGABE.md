# Kontor – Projektübergabe

Stand: 21.10.2026, Kontor **0.5.3**. Dieses Dokument fasst alles zusammen, was bisher nur in den Chats stand,
damit eine neue Claude-Sitzung (neuer Account, gleicher PC, gleiches Repository) nahtlos weitermachen kann.

---

## 1. Worum es geht

- **Kontor** ist ein Auktionshaus-Addon für **World of Warcraft: Forever** (Retail-Oberfläche auf Classic-Basis).
  Strategie: Verbrauchsgüter und Zutaten billig sammeln, lagern, später verkaufen; dazu Verarbeiten
  (Alchemie), Entzaubern, Händler-Aufräumen.
- Grundlage sind vier Dokumente des Nutzers, alle unter `docs/`:
  - `Pflichtenheft.md`: das Hauptdokument, mit Meilensteinen M0 bis M10
  - `Nachtrag-1.md`: Phase „Beobachten", Festpreise, Verarbeitung, Startkörbe
  - `Nachtrag-2.md`: Entzaubern, M5b und M11 bis M14
  - `Nachtrag-3.md`: Startrezepte, Verwendungs-Notizen
- **Termine:**
  - Beta-Ende am 22.10.2026
  - Launch am **04.11.2026**
- **Repository:** `Bronkn/test`. Einziger Branch ist `ccr-c2eadd0d-y40nq3`, das ist damit auch der Standard-Branch.
  Addon-Code liegt in `Kontor/`, die Doku in `docs/`, die Tests in `tests/`.

## 2. Der Nutzer – Arbeitsweise (wichtig)

- **Sprache:** Deutsch, einfache Worte. Oberfläche und Meldungen im Addon auf Deutsch mit echten Umlauten,
  Bezeichner im Code auf Englisch.
- **Der Nutzer liest keinen Code.** Er testet im Spiel und meldet die Ergebnisse
  - als Text, z. B. „B4 ok, D2 falsch: …",
  - oder als Screenshot, bei Designwünschen mit roten oder gelben Markierungen.
- **Lieferung:** Der Nutzer bekommt das Addon jeweils als ZIP des Ordners `Kontor`. Er löscht den alten Ordner und
  kopiert den neuen nach `World of Warcraft\_classic_beta_\Interface\AddOns\`. Die Spieldaten bleiben dabei erhalten.
- **Testlisten:**
  - nach Orten sortiert (Einloggen, AH, Händler, Entzaubern …)
  - abhakbar, mit Nummern wie A1, B2 …
  - Der Nutzer möchte **mehrere Meilensteine am Stück** bauen lassen und dann gesammelt testen.
- **Fehler:**
  - Der Nutzer schickt die Ausgabe von `/kontor fehler`: „Alles markieren", dann Strg+C.
  - Er hat BugGrabber und BugSack installiert.
- **Abweichungen vom Pflichtenheft:** vorher ansprechen, nach der Entscheidung in `docs/Entscheidungen.md`
  festhalten.
- **Versionsstand:** `CHANGELOG.md` und `API-NOTIZEN.md` werden mitgeführt.
- **Ehrlich bleiben:** Ohne Spielzugang ist nichts „im Spiel getestet". Getestet wird außerhalb des Spiels mit
  `tests/`, und so wird es auch gesagt.
- **Andere Addons des Nutzers:** Baganator, Syndicator, BugGrabber, BugSack, Leatrix Plus und Maps, RXPGuides,
  Questie, RareScanner, NovaInstanceTracker und weitere.
- **Charaktere:**
  - Der Bankcharakter ist Alchemist und Verzauberer und scannt im AH.
  - Der Main hat keine Verzauberkunst.
  - Horde, Realm „Classic Beta PvP". Einen Allianz-Charakter gibt es nicht.

## 3. Was über Forever bekannt ist (im Spiel geprüft)

Ausführlich in `API-NOTIZEN.md`. Kurz:

- **Client:** Spielversion **1.60.1**, Build 70338 in der Beta. **Interface-Version 16001.** Gebietsschema deDE.
- **APIs:** Alle APIs aus Pflichtenheft 3 und den Nachträgen sind vorhanden, darunter:
  - `C_AuctionHouse` mit Scan, Markttiefe und Kauf
  - TooltipDataProcessor
  - Container- und Item-Funktionen
  - Berufe, Loot, Auren, Post, SecureActionButton
- **Marktkennung:** `GetNormalizedRealmName()-UnitFactionGroup()`, z. B. `ClassicBetaPvP-Horde`.
  Der Horde-Charakter bekommt AH-Post von Sturmwind. Das deutet auf ein **gemeinsames AH beider Fraktionen** hin,
  ist aber noch nicht bestätigt. Falls ja: Markt nur noch nach Realm trennen und vorhandene Daten zusammenführen.
- **Scan:**
  - Eine Übersichtsabfrage **ohne Filter liefert das ganze AH**: 3134 Items, davon 3133 schon in der einen Abfrage.
  - Die anfangs fehlenden Items waren ein **Addon-Fehler**: Die Warteschlange hat `#` auf eine Tabelle mit Lücken
    angewandt. Behoben in 0.3.2 mit expliziten Head/Tail-Indizes.
- **Entzaubern:**
  - Zauber-ID **13262**, Name „Entzaubern". Es geht ein Beutefenster auf.
  - Forever schickt beim Wirken **keinen Zielnamen** und sperrt **kein Taschenfach**. Deshalb erkennt Kontor das
    Item über einen Taschenvergleich: Schnappschuss beim Wirken, Vergleich nach der Beute.
  - Jedes Item lässt sich mit Fertigkeit 1 entzaubern (Aussage des Nutzers).
  - Gesehene Materialien: Seltsamer Staub 10940, Geringe Magieessenz 10938, Seelenstaub (neu in Forever).
  - Einen Arcane Salvager hat der Nutzer nicht. Deshalb gibt es einen Schalter, und die Buff-IDs werden mitgespeichert.
- **Berufsfenster:** Schwefelsäure (Sulfuric Acid, 249410) = 2 × Pyrit (249391) + 1 × **Leere Phiole**.
  Die Phiole hat in Classic die ID 3371, in Forever ist das unbestätigt.
- **Stapelgröße:** Leinenstoff stapelt bis 20, wie in Classic.
- **Absturz am 12.10.:** Der Client-Absturz beim Klick auf eine Aktionsleiste kam aus dem Spiel, nicht von Kontor.

## 4. Stand der Meilensteine

| Teil | Stand |
|---|---|
| M0 API-Verifikation | abgenommen |
| M1 Gerüst | abgenommen |
| M2 Scan, M3 Tooltip, M4 Aufräumen, M5 Markttiefe/Kauf-Erkennung, M5b Entzauber-Protokoll | abgenommen (`docs/Testliste-M2-M5b.md`; F1 nicht testbar) |
| Verkaufsliste (Wunsch, statt „AH-Erstellung mit einem Knopf") | abgenommen bis auf G6 |
| M6–M14 + Nachtrag 3 | gebaut (0.5.0); im Spiel nur teilweise getestet, „sieht gut aus" |
| Minimap-Knopf, Baganator/Syndicator, Kompakt-Design | gebaut (0.5.1–0.5.3), teilweise angesehen |

**Noch nicht im Spiel getestet** (der Nutzer levelt in der Beta und testet das nicht mehr gezielt):
- Kauf-Buchung ins Journal
- Rezept-Übernahme aus dem Berufsfenster
- Knopf „Nächstes entzaubern"
- Briefkasten-Knopf
- Baganator-Symbole und Syndicator-Zahlen
- Einkaufsliste und Markttiefe-Satz in der Detailansicht

Fehler sollen später einfach über `/kontor fehler` kommen.

## 5. Offene Punkte

1. **Launch** (`docs/Launch-Checkliste.md`):
   - `Kontor.lua` aus den SavedVariables der Beta in den Live-Ordner kopieren
   - Interface-Nummer prüfen
   - Festpreise (Beta-Werte) anpassen
   - AH-Gebühr von 5 % prüfen
   - gemeinsames AH klären
   - Phiole und Öl-Rezepte aus dem Berufsfenster übernehmen
2. **Unbeantwortete Frage an den Nutzer:** Soll der Tooltip statt „vor 5 Min. (zuletzt nicht gelistet)"
   lieber „jetzt nicht mehr im AH" sagen?
3. **Signale:** Sie werden als Symbol vor dem Item-Namen angezeigt. Ich habe angeboten, das bei Bedarf
   auf eingefärbte Namen umzustellen.
4. **Nicht gebaut**, weil optional:
   - das Liniendiagramm im Verlauf (Pflichtenheft 4.5, Stufe 2)
   - die automatische Buchung von Verkäufen über die Post (Pflichtenheft 4.6, „später")
5. **Pull Request oder `main`-Branch:** angeboten, noch nicht gewünscht.

## 6. Technik in Kürze

- **Struktur:**
  - Reine Logik liegt in `Kontor/*.lua`, Fenster in `Kontor/UI/*.lua`.
  - Die Ladereihenfolge steht in `Kontor/Kontor.toc`, ebenso `## OptionalDeps: Baganator, Syndicator`.
- **Fehlertoleranz:**
  - Jeder Event-Handler läuft über `Kontor:SafeCall`. Fehler landen in `KontorDB.errorLog`, höchstens 50.
  - Fehlt ein Event oder eine Funktion im Client, legt das das Addon nicht lahm, es wird nur protokolliert.
    Zuständig sind `RegisterEvent` und `SecureHook`.
- **Daten:**
  - Accountweite SavedVariable **`KontorDB`**, Datenmodell-**Version 4**.
  - Migrationen ergänzen nur, sie löschen nie etwas.
- **Feste Regeln:**
  - Kein Kaufen, Einstellen oder Abbrechen durch das Addon.
  - Händlerverkauf nur nach Vorschau, höchstens 12 Stapel.
  - Nichts Geschütztes im Kampf.
  - Keine Unterbiet-Automatik.
  - Kein Baganator-Junk-Plugin, weil sonst ein Verkauf ohne Vorschau möglich wäre.
- **Blizzard-Referenz:** Retail-UI-Quellcode 12.1, zuletzt gelesen aus `github.com/Gethe/wow-ui-source`
  (Sparse-Checkout von `Interface/AddOns/Blizzard_APIDocumentationGenerated`, `Blizzard_AuctionHouseUI` …).
- **Baganator-/Syndicator-API:** geprüft gegen Baganator Release 834 und Syndicator Release 285.
  - Gelesen aus den öffentlichen Spiegeln `github.com/hippuli/Baganator` und `github.com/hippuli/Syndicator`.
  - Die Original-Repos liegen unter `TheMouseNest`, waren aus der Sitzung aber nicht erreichbar.
- **Tests außerhalb des Spiels:** `tests/`. Lua 5.1 über `lupa`, die WoW-API ist in `tests/wow_mock.lua`
  nachgebaut.
  - Einmalig installieren: `pip install lupa`
  - Starten: `sh tests/run_all.sh`
  - Die Attrappe bildet nur ab, was gebraucht wird. Schlägt ein Test fehl, zuerst prüfen, ob die Attrappe
    oder das Addon schuld ist.
- **Zweite Prüfung:** Nach größeren Umbauten hat ein Review-Agent den Code gegen Blizzards Quelltext geprüft.
  Das hat echte Fehler gefunden, etwa den Shift-Klick-Hook: Blizzard ruft `ChatFrameUtil.InsertLink` auf, nicht
  `ChatEdit_InsertLink`. Bei größeren Änderungen wiederholen.

## 7. Ablauf je Änderung (so wurde bisher gearbeitet)

1. Den Wunsch des Nutzers verstehen. Widerspricht er dem Pflichtenheft, Varianten nennen und den Nutzer entscheiden
   lassen.
2. Umsetzen, die Tests ergänzen, `sh tests/run_all.sh` laufen lassen.
3. Pflegen: `CHANGELOG.md`, Version in `Kontor/Kontor.toc`, bei Bedarf `docs/Entscheidungen.md`, Testliste und
   `API-NOTIZEN.md`.
4. Committen und pushen auf den Branch.
5. ZIP bauen (`zip -r Kontor-x.y.z.zip Kontor`) und dem Nutzer schicken, dazu eine kurze Erklärung auf Deutsch
   und die Testpunkte.
