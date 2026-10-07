# Changelog

Changes are grouped by related consecutive commits, newest first.

- Added this changelog.
- Removed three game scripts identical to version 5.00c: hudModuleLootPopup.ws, LootPopup.ws, and tutorialManager.ws.
- Removed info.json, blob0.bundle, and metadata.store.
- Moved bin and Mods to the repository root.
- Added and shortened the README to document the final functionality.
- Removed ingredient quality filtering from Item Filters; retained popup quality suppression.
- Fixed the default filter preset, blank descriptions, and notification debug output.
- Removed unused variables, simplified equivalent conditions, and cleaned GUI comments.
- Reordered menu entries and updated default interaction mode and protections.
- Clarified comments and simplified popup suppression and readable-item checks without changing behavior.
- Removed popup price and currency-quantity thresholds.
- Removed the option to disable stealing reactions; retained accidental-stealing protection.
- Removed forced quest looting, white-item destruction, corpse/drop filter overrides, and container-count loot rules.
- Fixed herb notifications and sounds, and removed the herb category filter.
- Moved interaction mode into General Settings.
- Removed per-category quantity and value restrictions.
- Restricted interaction looting to the selected target and made mode 2 apply enabled filters.
- Removed radius autoloot and gave loot-on-kill its own distance setting.
- Removed TrueAutoLoot and documented the loot-on-kill distance dependency.
- Imported the mod and game scripts; removed installation helpers and localization files.
