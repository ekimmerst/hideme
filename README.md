# HideMe

Ein kleines Addon für die aktuelle **WoW-Forever-Beta**, mit dem du die Taschenleiste und das Micro-Menü per Chatbefehl aus- und einblenden kannst.

## Installation

1. Lade dieses Repository herunter oder klone es.
2. Lege die Dateien in `World of Warcraft/_classic_beta_/Interface/AddOns/HideMe/` ab.
3. `HideMe.toc` und `HideMe.lua` müssen direkt im Ordner `HideMe` liegen.
4. Starte WoW neu und aktiviere **HideMe** in der Addon-Liste.

Nach Änderungen an einem bereits geladenen Addon kannst du die Oberfläche mit `/reload` neu laden.

## Verwendung

Alle Befehle werden im WoW-Chat eingegeben.

| Befehl | Funktion |
| --- | --- |
| `/hideme bag-bar on` | Taschenleiste ausblenden |
| `/hideme bag-bar off` | Taschenleiste wieder einblenden |
| `/hideme micro-menu on` | Micro-Menü ausblenden |
| `/hideme micro-menu off` | Micro-Menü wieder einblenden |
| `/hideme status` | Gespeicherte Einstellungen aller unterstützten Elemente anzeigen |
| `/hideme help` | Verfügbare Befehle und ihre Verwendung anzeigen |
| `/hideme` | Hilfe anzeigen |

**on aktiviert die Ausblendung**, **off deaktiviert die Ausblendung**.

Die Einstellungen werden **pro Charakter** gespeichert und bleiben nach einem Neustart oder `/reload` erhalten. Änderungen während eines Kampfes werden nach Kampfende angewendet. Die Statusanzeige kennzeichnet noch ausstehende Änderungen. Sie zeigt die von HideMe gespeicherten Einstellungen; andere Addons können die tatsächliche Sichtbarkeit ebenfalls beeinflussen.

## Kompatibilität

- Version: **0.4.0**
- Interface-Version: **16001** (WoW Forever Beta)
- Keine zusätzlichen Addon-Abhängigkeiten
- Steuerung ausschließlich per Chatbefehl

Ein Funktionstest im Spiel steht noch aus.
