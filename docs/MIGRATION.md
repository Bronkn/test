# Kontor – Umzug auf den neuen Claude-Account

Die Chats ziehen nicht mit um. Alles, was für die Weiterarbeit nötig ist, liegt deshalb im Repository
`Bronkn/test`:

- `docs/PROJEKT-UEBERGABE.md`: der gesamte Projektstand aus den Chats
- `CLAUDE.md`: Arbeitsregeln, die eine neue Claude-Sitzung automatisch liest
- `docs/`: Pflichtenheft, Nachträge 1–3, Entscheidungen, Testlisten, Launch-Checkliste
- `tests/`: die Tests außerhalb des Spiels
- `Kontor/`: das Addon selbst

## Schritte

1. **Im neuen Claude-Account GitHub verbinden:** Unter https://claude.ai/connect-github mit **demselben
   GitHub-Konto** anmelden, dem `Bronkn/test` gehört. Prüfen, dass die Claude-GitHub-App Zugriff auf das Repo hat.
   Falls nicht, auf derselben Seite installieren und das Repo freigeben.
2. **Neue Claude-Code-Sitzung starten** (claude.ai/code) und dabei das Repository `Bronkn/test` auswählen.
   Der einzige Branch `ccr-c2eadd0d-y40nq3` ist gleichzeitig der Standard-Branch, die Sitzung findet also alles.
3. **Startnachricht einfügen:** den Text aus `docs/STARTNACHRICHT.md` als erste Nachricht schicken.
4. **Für die Tests:** Die Umgebung braucht Netzzugang zu PyPI (`pip install lupa`). Klappt das nicht, bitte die
   Netzwerk-Einstellung der Umgebung prüfen. Das Addon lässt sich auch ohne die Tests weiterbauen, dann aber
   ungeprüft.

## Was sich nicht ändert

- **Spiel und PC:** Der Ordner `Interface\AddOns\Kontor` und die Spieldaten (`WTF\…\SavedVariables\Kontor.lua`)
  bleiben, wo sie sind. Die Migration betrifft nur Claude.
- **Neueste Addon-Version:** `Kontor/` im Repo, Version 0.5.3. Auf GitHub über „Code → Download ZIP", dann daraus
  den Ordner `Kontor` nehmen.

## Was im alten Account bleibt (und nicht gebraucht wird)

- **Chatverläufe:** Ihr Inhalt steht zusammengefasst in `docs/PROJEKT-UEBERGABE.md`.
- **Hochgeladene Dateien:** Pflichtenheft und Nachträge liegen bereits unter `docs/`. Die Screenshots sind
  ausgewertet und in die Übergabe eingeflossen.
