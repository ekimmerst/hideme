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
| `/hideme calendar-icon on` | Hide the minimap calendar icon |
| `/hideme calendar-icon off` | Show the minimap calendar icon |
| `/hideme chat-bar on` | Show chat input only while typing; press Return to start |
| `/hideme chat-bar off` | Always show the General chat input without taking keyboard focus |
| `/hideme chat-buttons on` | Hide standard chat buttons in all chat windows |
| `/hideme chat-buttons off` | Show standard chat buttons |
| `/hideme chat-tabs on` | Hide all standard chat tabs, including General and Combat Log |
| `/hideme chat-tabs off` | Show only the General tab |
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

With `calendar-icon on`, the minimap calendar button (`GameTimeFrame`) is hidden, including its child textures and invitation indicators. UI attempts to show the button are suppressed outside combat; pending changes are applied when combat ends. `off` shows the button again. The setting is saved per character and does not disable the calendar itself.

The Combat Log window (`ChatFrame2`), its tab, input, button panel and quick-filter controls are always hidden, independently of these settings. If selected, the dock returns to General outside combat. Show and alpha updates cannot reveal the log; combat uses zero opacity until direct hiding is safe. Combat messages are not deleted and combat-log collection is unchanged. The input parameter is `chat-bar` (corrected from the earlier typo `char-bar`); its saved setting is preserved.

With `chat-bar on`, inactive chat input fields are hidden. Press Return to start typing as usual; sending a message or cancelling input hides the field again. With `off`, the General window's input field stays visible without automatically activating chat or taking keyboard focus. Other chat windows show their input while used, avoiding unused input fields. The setting also covers newly opened and temporary chat windows and is independent of chat buttons and tabs. Changes during combat wait until combat ends.

With `chat-buttons on`, HideMe hides the chat menu/channel/social/voice buttons when available, each chat window's button panel, scrollbar, scroll-to-bottom and minimize buttons. Chat text, tabs, text entry and mouse-wheel scrolling are unchanged. Newly opened standard and temporary chat windows are included. `off` shows the controls again; Blizzard may subsequently update controls according to the current chat state. Buttons supplied by other addons are not covered.

With `chat-tabs on`, HideMe hides all standard chat tabs. With `off`, only the General tab is shown; Combat Log, Voice, unused and newly opened or temporary window tabs remain hidden. General is identified as the first standard chat window (`ChatFrame1`), even if renamed. Hidden tabs cannot be clicked to switch windows. Chat text and text entry remain available. This setting is independent of `chat-buttons`.

With `player-frame on`, the player frame becomes transparent at full health when you have no target and are out of combat. It is visible below full health, with a target, or in combat. WoW evaluates a step curve and passes the result directly to the frame's alpha, without addon comparisons of protected health values. A transparent frame can still receive mouse input. Mana does not affect visibility. Mode changes made during combat take effect after combat ends.

Settings are saved **per character** and persist across restarts and `/reload`. Changes made during combat take effect after combat ends. The status display marks pending changes. It shows the settings saved by HideMe; other addons can also affect actual visibility.

With `toolbars on`, the standard action bars become transparent without a target outside combat. With a target or in combat, they have full opacity. This covers the main action bar, seven additional action bars, and available pet, stance, possess and override bars. Blizzard continues to control which bars are enabled and appropriate for the current state; `off` restores full opacity without enabling disabled bars. Key bindings remain usable, and transparent bars can still receive mouse input. Bars supplied by other addons are not covered.

With `exp-bar on`, the entire status-bar area becomes transparent, including its borders and all experience, reputation and other status-bar content. A player XP update or level-up reveals the whole area for two seconds; another XP change restarts that interval. Reputation and other non-XP updates do not start an interval. Enabling the setting or reloading does not start a display interval. The timer also runs during combat, while mode changes made in combat wait until combat ends. `off` restores full opacity; Blizzard still decides which status bars are available. Transparent status bars may still receive mouse input.

## Compatibility

- Version: **0.11.0**
- Interface version: **16001** (WoW Forever Beta)
- No additional addon dependencies
- Controlled exclusively through chat commands

If the required health/curve APIs are unavailable, HideMe falls back to showing the player frame only with a target or in combat.

The user confirmed target/combat hiding in version 0.5.2 and health-based visibility in version 0.5.3 on the beta client. The full compatibility test matrix remains pending.
The user confirmed the toolbars behavior in version 0.6.0 works on the beta client. The full compatibility test matrix remains pending.
The full status-bar hiding behavior in version 0.7.1 requires in-game verification.
The user confirmed chat-buttons in version 0.8.0 and General-only chat-tabs in version 0.9.1 work in game. Chat input behavior in version 0.10.1 requires in-game verification.
