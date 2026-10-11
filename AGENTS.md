# HideMe – Project knowledge and working rules

## Starting future sessions

- Read AGENTS.md, README.md, HideMe.toc, and HideMe.lua first.
- Check Git status, remotes, and recent commits before making changes.
- Current code and Git state take precedence over outdated information here.
- Communicate with the user in German. All addon messages, comments, metadata, and project documentation must be in English, as requested by the user on October 11, 2026.
- Work on HideMe. Other addons in the parent directory are separate projects.
- Keep this file up to date when making relevant changes.

## Project and repository

- Small Lua addon for the WoW Forever Beta.
- Folder: C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\HideMe
- Public repository: https://github.com/ekimmerst/hideme
- Remote origin: https://github.com/ekimmerst/hideme.git
- Branch: main, tracking origin/main.
- As of October 11, 2026: version 0.6.0; interface version 16001.
- Last verified commit: a4f6394 (Add health-aware player frame visibility and English documentation).
- The user successfully published the addon previously.
- No external addon dependencies and no build step.

## Files

- HideMe.toc: metadata, version, interface version, and Lua load order.
- HideMe.lua: entire implementation.
- README.md: installation and usage.
- AGENTS.md: information for future work.

## Commands

Controlled exclusively through chat, without a settings interface.

- /hideme bag-bar on: hide the bag bar.
- /hideme bag-bar off: show the bag bar.
- /hideme micro-menu on: hide the micro menu.
- /hideme micro-menu off: show the micro menu.
- /hideme player-frame on: show the player frame with a target, in combat, or below full health.
- /hideme player-frame off: always show the player frame.
- /hideme toolbars on: show active standard action bars only with a target or in combat.
- /hideme toolbars off: always show active standard action bars.
- /hideme help: show all commands and usage.
- /hideme without parameters: show help.
- /hideme status: show all hiding settings.

on enables hiding; off disables it.
Commands are case-insensitive; leading and trailing whitespace is removed.
Invalid commands do not change settings and refer the user to help.

Status lists all targets alphabetically with the parameter name, English label,
and saved on/off state. Pending changes are marked. Status displays settings;
it does not measure actual visibility when other addons interfere.

## Technical implementation

- targets defines the setting key, label, and frames for each parameter.
- bag-bar: HideMeDB.hideBagBar; frame BagsBar.
- micro-menu: HideMeDB.hideMicroMenu; frames MicroMenuContainer and MicroMenu, if available.
- HideMeDB is saved per character through SavedVariablesPerCharacter.
- toolbars: HideMeDB.hideToolbars. MainActionBar, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft, MultiBar5/6/7, PetActionBar, StanceBar, PossessActionBar and OverrideActionBar, when available. ApplyToolbars changes alpha only, preserving Blizzard's activation/paging/special-state visibility; it never calls Show/Hide or replaces their state drivers. Transparent bars retain key bindings and may receive mouse input. Third-party bars are not covered.
- Toolbar alpha updates on target and combat changes; Show hooks restore the current alpha. Hook setup and applied-mode changes wait until out of combat, while alpha can update in combat. Later ADDON_LOADED events retry optional toolbar discovery. Inactive bars remain inactive with off.
- player-frame: HideMeDB.hidePlayerFrame; frame PlayerFrame. With curve support, the frame stays shown and health controls alpha via UnitHealthPercent("player", false, healthAlphaCurve). A Step curve maps fraction 0 to alpha 1 and fraction 1 to alpha 0. The result is passed directly to SetAlpha, never compared or inspected. Mana is not queried. Transparent frames may remain interactive.
- Version 0.5.0 failed in game with a secret-number comparison in PlayerNeedsFrame. Version 0.5.1 guarded secret values but kept the frame always visible on the user's client. The user approved removing health/mana conditions temporarily for version 0.5.2; do not restore them without discussing the client restrictions.
- RegisterStateDriver keeps the player frame shown with curve support. Clients without the required APIs retain the version 0.5.2 target/combat visibility driver. Registration and direct Show/Hide calls occur only outside combat.
- PLAYER_TARGET_CHANGED, PLAYER_REGEN_DISABLED, UNIT_HEALTH and UNIT_MAXHEALTH update player alpha; PLAYER_REGEN_ENABLED applies pending settings and reevaluates. target.appliedHiding preserves the applied mode until deferred combat changes can be applied. Target/combat/off set alpha to 1.
- Settings persist across /reload and game restarts.
- Saved values are normalized to booleans.
- Hiding is disabled by default.
- ApplyTarget applies visibility.
- ApplyTargets processes all targets or only pending targets.
- InCombatLockdown prevents Show/Hide calls and hook setup during combat.
- target.pending tracks pending changes.
- PLAYER_REGEN_ENABLED applies changes after combat ends.
- Missing frames result in pending changes; later ADDON_LOADED events retry application.
- PLAYER_LOGIN and PLAYER_ENTERING_WORLD apply all settings.
- A hooksecurefunc hook on Show hides frames again when hiding is enabled.
- hookedFrames prevents duplicate hooks.
- Hooks check the current setting so that off continues to work.
- Other addons can affect the same frames.

## Changes and verification

- Add new targets to targets, help, and README.
- Status uses targets automatically.
- Preserve existing setting keys and the meaning of on/off.
- Update the version in HideMe.toc and README for functional releases.
- Change the interface version only when supported by evidence.
- The user confirmed on October 11, 2026 that version 0.5.2 player-frame hiding and version 0.5.3 health-based visibility work in game. The full test matrix remains pending.
- Lua, LuaJIT, and luac were unavailable in the previous agent environment.
- Version 0.5.0 was checked for syntax and simulated WoW state changes using a temporary Lupa Lua 5.1 runtime (target, health/mana, combat, deferred mode changes, missing frames, and existing targets). This does not replace an in-game test.
- Version 0.5.1 passed the existing Lua 5.1 state simulations and regression simulations using comparison-rejecting sentinel values for each of the four resource APIs, including Show hooks, events, on/off, recovery to readable values, target short-circuiting, and clients without issecretvalue. Actual WoW secret values cannot be reproduced by Lupa; in-game verification remains required.
- Version 0.5.2 passed Lua 5.1 syntax and simulated target/combat transitions, enabling with an existing target, Show hooks, deferred on/off changes, invalid commands, other targets, missing-frame retry, and saved-setting reapplication. Resource API stubs raised errors if called; no health/mana reads occurred. git diff --check passed. The user subsequently confirmed player-frame hiding works in game.
- The user confirmed UnitHealthPercent and C_CurveUtil.CreateCurve exist on the beta client. Version 0.5.3 implements the researched curve-to-alpha path. Lua 5.1 simulations passed for comparison-rejecting secret-result sentinels, health boundaries (including 99.999% and 100%), maximum-health changes, target/combat transitions, deferred modes, Show hooks, missing-frame retry, saved-setting reapplication and existing targets; raw resource APIs were forbidden by the harness. git diff --check passed. The user subsequently confirmed the health/alpha behavior works in game.
- Do not report tests that were not run as passed.
- Version 0.6.0 passed Lua 5.1 syntax and toolbar simulations for target/combat transitions, deferred on/off, inactive bars staying inactive, late-loaded bars, Show hooks, invalid commands, saved-setting reapplication and independence from the existing targets. The harness also verified toolbar state drivers were untouched. The user confirmed on October 11, 2026 that toolbars works in game; the full compatibility test matrix remains pending.
- Test in game: all four targets independently with on/off, help, status, invalid commands, persistence across /reload and restarts, and changes during combat applied after combat ends.
- Test toolbars: target select/clear, combat enter/leave, deferred mode changes, enabling/disabling additional bars while hiding is enabled, pet/stance/possess/override states, key bindings, and independence from bag-bar, micro-menu and player-frame settings.
- Also test the player frame: select/clear a target, enter/leave combat (including clearing a target during combat), enable with a target already selected, change modes during combat, lose health and regenerate to exactly full health. Mana changes must not affect visibility. Verify transparent-frame mouse behavior and off restoring alpha to 1.
- Verify that UI updates do not permanently reveal hidden elements and that off restores them.
- New addons require a game restart; changes to an already loaded HideMe can be loaded with /reload.

## GitHub and execution environment

- Git and GitHub CLI are installed.
- The user configured authentication and Git identity in their Windows session.
- The previous agent environment ran as CodexSandboxOffline and could not use saved credentials or the global Git identity.
- An invalid-token message in that environment may be caused by separate user contexts; do not prematurely reset the user's authentication.
- Recheck permissions and authentication in future sessions.
- Do not store credentials in project files or outputs.
- Do not invent a commit identity.
- Commit and push according to the current user request. Previous publication does not authorize automatic future pushes.
- If access is unavailable, finish local work and provide concrete PowerShell commands for the user's normal session.
- Preserve unrelated changes; do not use destructive Git commands without authorization.
