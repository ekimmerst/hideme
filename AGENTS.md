# HideMe – Projektwissen und Arbeitsregeln

## Einstieg in zukünftige Sitzungen

- Lies zuerst AGENTS.md, README.md, HideMe.toc und HideMe.lua.
- Prüfe Git-Status, Remotes und letzte Commits vor Änderungen.
- Aktueller Code und Git-Stand haben Vorrang vor veralteten Angaben hier.
- Kommuniziere auf Deutsch; Chatmeldungen und Dokumentation sind ebenfalls deutsch.
- Bearbeite HideMe. Andere Addons im übergeordneten Verzeichnis sind eigenständige Projekte.
- Halte diese Datei bei relevanten Änderungen aktuell.

## Projekt und Repository

- Kleines Lua-Addon für die WoW-Forever-Beta.
- Ordner: C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\HideMe
- Öffentliches Repository: https://github.com/ekimmerst/hideme
- Remote origin: https://github.com/ekimmerst/hideme.git
- Branch: main, mit origin/main verknüpft.
- Stand am 10. Oktober 2026: Version 0.4.0; Interface-Version 16001.
- Letzter geprüfter Commit: 7c6c550 (Initial release of HideMe).
- Veröffentlichung wurde vom Benutzer erfolgreich durchgeführt.
- Keine externen Addon-Abhängigkeiten, kein Build-Schritt.

## Dateien

- HideMe.toc: Metadaten, Version, Interface-Version und Lua-Ladereihenfolge.
- HideMe.lua: gesamte Implementierung.
- README.md: Installation und Verwendung.
- AGENTS.md: Informationen für zukünftige Arbeit.

## Befehle

Steuerung ausschließlich per Chat, ohne Einstellungsoberfläche.

- /hideme bag-bar on: Taschenleiste ausblenden.
- /hideme bag-bar off: Taschenleiste einblenden.
- /hideme micro-menu on: Micro-Menü ausblenden.
- /hideme micro-menu off: Micro-Menü einblenden.
- /hideme help: alle Befehle und Verwendung anzeigen.
- /hideme ohne Parameter: Hilfe anzeigen.
- /hideme status: Einstellungen aller Ausblendungen anzeigen.

on aktiviert die Ausblendung; off deaktiviert sie.
Groß-/Kleinschreibung wird ignoriert; äußere Leerzeichen werden entfernt.
Ungültige Befehle verändern keine Einstellungen und verweisen auf die Hilfe.

Status listet alle Ziele alphabetisch mit Parametername, deutscher
Bezeichnung und gespeichertem on/off. Ausstehende Änderungen werden
gekennzeichnet. Status zeigt Einstellungen und misst nicht die tatsächliche
Sichtbarkeit bei Eingriffen anderer Addons.

## Technische Umsetzung

- targets definiert je Parameter Einstellungsschlüssel, Bezeichnung und Frames.
- bag-bar: HideMeDB.hideBagBar; Frame BagsBar.
- micro-menu: HideMeDB.hideMicroMenu; Frames MicroMenuContainer und MicroMenu,
  sofern vorhanden.
- HideMeDB wird über SavedVariablesPerCharacter pro Charakter gespeichert.
- Einstellungen bleiben nach /reload und Spielneustarts erhalten.
- Gespeicherte Werte werden auf boolesche Werte normalisiert.
- Standardmäßig ist die Ausblendung deaktiviert.
- ApplyTarget wendet die Sichtbarkeit an.
- ApplyTargets verarbeitet alle oder nur ausstehende Ziele.
- InCombatLockdown verhindert Show/Hide und Hook-Einrichtung im Kampf.
- target.pending merkt ausstehende Änderungen.
- PLAYER_REGEN_ENABLED wendet Änderungen nach Kampfende an.
- Fehlende Frames führen zu ausstehenden Änderungen; spätere
  ADDON_LOADED-Ereignisse versuchen die Anwendung erneut.
- PLAYER_LOGIN und PLAYER_ENTERING_WORLD wenden alle Einstellungen an.
- hooksecurefunc auf Show blendet Frames bei aktiver Ausblendung erneut aus.
- hookedFrames verhindert doppelte Hooks.
- Hooks prüfen die aktuelle Einstellung, sodass off weiterhin funktioniert.
- Andere Addons können dieselben Frames beeinflussen.

## Änderungen und Prüfung

- Neue Ziele in targets, Hilfe und README ergänzen.
- Status nutzt targets automatisch.
- Bestehende Einstellungsschlüssel und die Bedeutung von on/off erhalten.
- Bei funktionalen Releases Version in HideMe.toc und README aktualisieren.
- Interface-Version nur bei belegtem Bedarf ändern.
- Ein bestätigter Funktionstest im Spiel steht bisher aus.
- Lua, LuaJIT und luac waren in der bisherigen Agent-Umgebung nicht verfügbar.
- Keine nicht ausgeführten Tests als bestanden melden.
- Im Spiel prüfen: beide Ziele unabhängig mit on/off, Hilfe, Status,
  ungültige Befehle, Speicherung nach /reload und Neustart sowie Änderungen
  im Kampf und deren Anwendung nach Kampfende.
- Prüfen, dass UI-Aktualisierungen ausgeblendete Elemente nicht dauerhaft
  wieder einblenden und off sie wiederherstellt.
- Neue Addons benötigen einen Spielneustart; Änderungen an bereits
  geladenem HideMe können mit /reload geladen werden.

## GitHub und Ausführungsumgebung

- Git und GitHub CLI sind installiert.
- Der Benutzer hat Anmeldung und Git-Identität in seiner Windows-Sitzung eingerichtet.
- Die bisherige Agent-Umgebung lief als CodexSandboxOffline und konnte
  gespeicherte Zugangsdaten und globale Git-Identität nicht nutzen.
- Eine dortige Meldung über ein ungültiges Token kann durch die getrennten
  Benutzerkontexte entstehen; Benutzeranmeldung nicht vorschnell zurücksetzen.
- Rechte und Anmeldung in zukünftigen Sitzungen erneut prüfen.
- Keine Zugangsdaten in Projektdateien oder Ausgaben speichern.
- Keine Commit-Identität erfinden.
- Commit und Push richten sich nach dem aktuellen Benutzerauftrag.
  Die frühere Veröffentlichung autorisiert keine automatischen zukünftigen Pushes.
- Bei fehlendem Zugriff lokale Arbeit fertigstellen und konkrete
  PowerShell-Befehle für die normale Benutzersitzung nennen.
- Fremde Änderungen erhalten; keine destruktiven Git-Befehle ohne Autorisierung.
