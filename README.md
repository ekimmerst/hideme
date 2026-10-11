# HideMe

A small addon for the current **WoW Forever Beta** that lets you hide or show the bag bar and micro menu using chat commands, and show the player frame based on your target, combat state, and health.

## Installation

1. Download or clone this repository.
2. Place the files in `World of Warcraft/_classic_beta_/Interface/AddOns/HideMe/`.
3. `HideMe.toc` and `HideMe.lua` must be directly inside the `HideMe` folder.
4. Restart WoW and enable **HideMe** in the addon list.

After changing an addon that is already loaded, you can reload the interface using `/reload`.

## Usage

Enter all commands in the WoW chat.

| Command | Function |
| --- | --- |
| `/hideme bag-bar on` | Hide the bag bar |
| `/hideme bag-bar off` | Show the bag bar |
| `/hideme exp-bar on` | Show all status bars and their borders for 2 seconds after each XP change |
| `/hideme exp-bar off` | Always show available status bars and their borders |
| `/hideme micro-menu on` | Hide the micro menu |
| `/hideme micro-menu off` | Show the micro menu |
| `/hideme player-frame on` | Show the player frame with a target, in combat, or below full health |
| `/hideme player-frame off` | Always show the player frame |
| `/hideme toolbars on` | Show active action bars only with a target or in combat |
| `/hideme toolbars off` | Always show active action bars |
| `/hideme status` | Show the saved settings for all supported elements |
| `/hideme help` | Show available commands and their usage |
| `/hideme` | Show help |

**on enables hiding**, **off disables hiding**.

With `player-frame on`, the player frame becomes transparent at full health when you have no target and are out of combat. It is visible below full health, with a target, or in combat. WoW evaluates a step curve and passes the result directly to the frame's alpha, without addon comparisons of protected health values. A transparent frame can still receive mouse input. Mana does not affect visibility. Mode changes made during combat take effect after combat ends.

Settings are saved **per character** and persist across restarts and `/reload`. Changes made during combat take effect after combat ends. The status display marks pending changes. It shows the settings saved by HideMe; other addons can also affect actual visibility.

With `toolbars on`, the standard action bars become transparent without a target outside combat. With a target or in combat, they have full opacity. This covers the main action bar, seven additional action bars, and available pet, stance, possess and override bars. Blizzard continues to control which bars are enabled and appropriate for the current state; `off` restores full opacity without enabling disabled bars. Key bindings remain usable, and transparent bars can still receive mouse input. Bars supplied by other addons are not covered.

With `exp-bar on`, the entire status-bar area becomes transparent, including its borders and all experience, reputation and other status-bar content. A player XP update or level-up reveals the whole area for two seconds; another XP change restarts that interval. Reputation and other non-XP updates do not start an interval. Enabling the setting or reloading does not start a display interval. The timer also runs during combat, while mode changes made in combat wait until combat ends. `off` restores full opacity; Blizzard still decides which status bars are available. Transparent status bars may still receive mouse input.

## Compatibility

- Version: **0.7.1**
- Interface version: **16001** (WoW Forever Beta)
- No additional addon dependencies
- Controlled exclusively through chat commands

If the required health/curve APIs are unavailable, HideMe falls back to showing the player frame only with a target or in combat.

The user confirmed target/combat hiding in version 0.5.2 and health-based visibility in version 0.5.3 on the beta client. The full compatibility test matrix remains pending.
The user confirmed the toolbars behavior in version 0.6.0 works on the beta client. The full compatibility test matrix remains pending.
The full status-bar hiding behavior in version 0.7.1 requires in-game verification.
