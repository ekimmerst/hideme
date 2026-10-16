# HideMe

Version: 0.18.0

Enjoy a cleaner interface with **HideMe** for the **WoW Forever Beta**. Hide the UI elements you do not need and keep your attention on the game. Choose each element individually or enable all hiding options with one command.

HideMe can hide the bag bar, micro menu, experience and reputation bars, chat controls, and the minimap calendar icon, addon icon, and day-night indicator. When their hiding options are enabled, action bars appear with a target or in combat, and the player frame also appears whenever you are below full health.

## Getting started

Type `/hideme all on` in chat to enable all hiding options. Use `off` to disable an option, for example `/hideme calendar-icon off` to keep the calendar icon visible. `/hideme all off` disables all hiding options.

Settings are saved per character. Changes made during combat take effect after combat ends.

## Commands

Use `/hideme <option> on` to enable hiding or `/hideme <option> off` to disable it.

| Option | When hiding is enabled |
| --- | --- |
| `all` | Enable every hiding option at once |
| `addons-icon` | Hide the minimap addon menu icon |
| `bag-bar` | Hide the bag bar |
| `calendar-icon` | Hide the minimap calendar icon |
| `chat-bar` | Hide chat input while idle; press Enter to type |
| `chat-buttons` | Hide standard chat buttons and scroll controls |
| `chat-tabs` | Hide all chat tabs |
| `day-night-indicator` | Hide the minimap day-night indicator |
| `exp-bar` | Hide experience, reputation and other status bars, including borders |
| `fishing-bobber-tooltip` | Hide the fishing bobber tooltip (English and German clients) |
| `micro-menu` | Hide the micro menu |
| `player-frame` | Show the player frame only with a target, in combat, or below full health |
| `targetauras` | Hide buffs and debuffs on the standard target frame |
| `toolbars` | Show active standard action bars only with a target or in combat |

Type `/hideme status` to view your settings or `/hideme help` to see all commands.

Use `/hideme except toolbar 2` to also show action bar 2 when your health is below 100%, in addition to having a target or being in combat. This applies while `toolbars on` is enabled and only if the bar is enabled in the game settings. Numbers 1–8 match the game's action bar settings. You can add several exceptions; remove one with `/hideme except toolbar 2 off`. Exceptions are saved per character and retained by `all on` and `all off`. Without the required health API, bars still appear with a target or in combat.

With `chat-bar off`, the General chat input stays visible. With `chat-tabs off`, only the General tab is shown. The Combat Log window always stays hidden, including with `all off`.

## Installation

Place the **HideMe** folder in your game's `Interface/AddOns` folder, restart WoW, and enable **HideMe** in the addon list.

## Changelog

### 0.18.0

- Added `/hideme fishing-bobber-tooltip on` to hide the fishing bobber tooltip on English and German clients. Use `off` to show it normally on mouseover.
- Included the option in `all`, help, status, and per-character saved settings.

### 0.17.0

- Added `/hideme day-night-indicator on` to hide the minimap day-night indicator. Use `/hideme day-night-indicator off` to show it again.
- Included the new option in `all`, help, status, and per-character saved settings.

### 0.16.2

- Fixed `targetauras` for the Forever Beta's target aura display, including buffs and debuffs added after hiding is enabled.

### 0.16.1

- Fixed target buffs and debuffs remaining visible when their buttons are created after target-aura hiding is enabled, including when selecting yourself.

### 0.16.0

- Added `/hideme targetauras on` to hide target buffs and debuffs. Use `/hideme targetauras off` to restore available auras.
- Included target auras in `all`, help, status, and per-character saved settings.

### 0.15.0

- Added `/hideme except toolbar <1-8>` to let selected active action bars also appear below full health while toolbar hiding is enabled.
- Support multiple exceptions, saved per character and retained when using `all on` or `all off`. Remove an exception with `/hideme except toolbar <1-8> off` and view saved exceptions with `/hideme status`.
- Added this changelog covering the complete commit history from a player's perspective.

### 0.14.0 — Documentation update

- Simplified the README with a quick start, a compact command reference, and clearer installation instructions.

### 0.14.0

- Changed `exp-bar on` to keep the entire experience, reputation, and other status-bar area hidden, including its borders. Gaining experience or leveling up no longer reveals it briefly.
- Use `exp-bar off` to restore available status bars.

### 0.13.1

- Added a golden closed-eye icon with a violet glow to help identify HideMe in the addon list.

### 0.13.0

- Added `/hideme all on` and `/hideme all off` to change every hiding option at once. Individual options can still be changed afterward.
- Updated command and usage documentation.

### 0.12.0

- Added `addons-icon` to hide or show the minimap addon menu button without disabling your addons.

### 0.11.0

- Added `calendar-icon` to hide or show the minimap calendar button and its invitation indicators.

### 0.10.1

- Added `chat-buttons` to hide standard chat buttons and scroll controls, including those in new and temporary chat windows.
- Added `chat-tabs`: `on` hides every tab; `off` shows only the General tab.
- Added `chat-bar` to hide idle chat input while keeping Enter available to start typing. With `off`, the General input stays visible without taking keyboard focus.
- Permanently hid the Combat Log window and its controls, independently of the hiding options.

### 0.7.1

- Added `exp-bar` to hide the complete status-bar area and its borders, with a two-second reveal after experience gains or leveling up. Version 0.14.0 later replaced this temporary reveal with permanent hiding.

### 0.6.0

- Added `toolbars` to show active standard action bars only with a target or in combat, including available pet, stance, possess, and override bars.
- Kept action-bar key bindings usable while bars are hidden and left disabled bars inactive.

### 0.5.3

- Added `player-frame` to show the player frame with a target, in combat, or below full health, and hide it when resting at full health without a target. Mana changes do not reveal it.
- Switched addon messages, help, and documentation to English.

### 0.4.0 — Documentation update

- Added project maintenance notes; commands and in-game behavior were unchanged.

### 0.4.0 — Initial release

- Added chat commands to hide or show the bag bar and micro menu.
- Added `/hideme help` and `/hideme status`, including indicators for pending changes.
- Saved settings per character across reloads and restarts, with combat-time changes applied after combat ends.
