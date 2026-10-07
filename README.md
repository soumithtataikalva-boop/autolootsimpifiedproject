# AutoLoot Simplified

A simplified version of AutoLoot Advanced Settings for The Witcher 3 Remastered. This build focuses on interaction with the selected container, loot-on-kill, category filters, and configurable notifications.

## Looting behavior

Interaction looting processes the container Geralt is interacting with. The mod no longer scans nearby containers or automatically gathers loot while moving around.

### Interaction modes

| Mode | Behavior |
| --- | --- |
| 0 | Ordinary container interactions use the normal game loot window. Mod herb processing and loot-on-kill remain available. |
| 1 | Ordinary container interactions use mod looting without category/quality filtering. Targets classified as unique or protected use normal game interaction handling. |
| 2 | Interaction looting uses the mod processing path and applies category/quality filters when Enable filters is on. Global protections still apply. |

Unique targets include quest containers, treasure-hunt containers, keyed/locked containers, and certain targets covered by enabled protections. Mode 2 does not override quest or lock protections. Items left behind may require normal game interaction to collect.

The main Enable AutoLoot toggle controls mod processing more broadly than interaction mode 0. Turning the mod off restores the normal herb pickup path and standard loot-feed behavior.

### Loot-on-kill

Loot-on-kill attempts to process loot from enemies killed by the player, subject to protections, filters, and existing enemy exclusions. It does not scan surrounding containers. The distance slider ranges from 1 to 30 metres; the enemy loot must be strictly closer than the selected range.

### Herbs

Herbs have no category toggle or ingredient quality restriction. They remain eligible with item filters enabled, subject to applicable global protections. Herb pickups use the herb sound category; sound categories are cleared after playback so previous loot does not change a later herb sound to generic.

## Filters and protections

Enable filters activates category selection for loot-on-kill and mode 2 interaction looting. With filters off, category toggles do not restrict collection. Modes 0/1 retain their existing interaction filtering bypass.

Available categories, in menu order:

- Armor and weapons, each with an optional quality selector.
- Upgrades, tools, horse equipment, trophies, food, and currency.
- Ingredients, with no loot quality selector.
- Junk, with an optional quality selector.
- Formulas, unread readable items, already-read items, keys, masks, and other items.

Quality selectors support exact quality and inclusive lower/upper thresholds. Options labelled less/greater use `<=`/`>=`. Armor and weapons support Common through Witcher quality; junk supports Common through Relic. Off means no quality restriction for that enabled category.

Global options protect Witcher schematics, special containers, trophies, beehives, Corvo Bianco herbs, and player-dropped loot. The horse-related protection disables mod looting while mounted; it does not filter horse equipment.

No accidental stealing blocks mod looting of containers marked as theft-enabled. It reads the native container `disableStealing` flag and does not scan for guards or witnesses. Normal game theft reactions remain in place.

Quest containers, Gwent-card containers, locks, decorations, and certain story-sensitive containers retain their existing protection rules. Global protections are separate from category eligibility.

## Notifications

The notification menu controls popup appearance, position, width, font, outlines, colors, images, descriptions, quantities, item numbering, sound, and display duration. Book popup coordinates are configurable separately.

Maximum popup items controls how many entries appear per popup. Overflow entries use the delayed popup queue, with a four-second interval. Combat-hidden notifications can be displayed after combat. Empty and single-space descriptions do not add blank description lines.

Show AutoLoot loot controls the standard HUD loot feed/action log while the mod is enabled. It is separate from the mod's custom popup setting. The standard feed runs normally when the mod is disabled.

### Popup suppression

Popup suppression affects the mod notification/sound queue, not item eligibility:

| Interaction-key suppression mode | Behavior |
| --- | --- |
| 0 | Apply the configured category suppression rules. |
| 1 | Apply suppression rules, except herb suppression for herb interactions. |
| 2 | Interaction-key loot bypasses suppression; non-interaction loot still uses the rules. |

Type-3 unique-container interactions bypass suppression when they reach the mod notification path.

Suppression options cover herbs, already-read readable items, food, junk, currency, and ingredient/armor/weapon quality thresholds. These popup quality thresholds remain even though ingredient loot quality filtering was removed. Junk suppression retains the Seashell exception; ingredient suppression retains the Soltis Vodka exception. There are no popup price or currency-quantity thresholds.

## Defaults

| Setting | Default |
| --- | --- |
| Enable AutoLoot | On |
| Interaction looting mode | 2 |
| Loot-on-kill | On |
| Loot-on-kill distance | 10 metres |
| No accidental stealing | On |
| Quest-item warning | On |
| Protect Witcher schematics | On |
| Protect trophies | On |
| Exclude dropped items | On |
| Other optional global protections | Off |
| Enable filters | Off |
| All item-category toggles | Off |
| Armor, weapon, and junk quality restrictions | Off/unrestricted |
| Notifications, loot sound, colors, images, quantities | On |
| Descriptions and item numbering | Off |
| Hide notifications during combat | On |
| Standard loot-feed entries while mod enabled | Off |
| Maximum popup items | 30 |
| Notification duration | 5 seconds plus 150 ms per entry |
| Popup suppression interaction mode | 1 |
| Popup quality thresholds | Off |

Defaults apply to initialization/reset or the relevant menu preset; existing saved settings can retain earlier values. The default Item Filters preset explicitly sets Enable filters to Off. Full reset restores the mod defaults. Interaction mode retains a fallback read of older settings stored in the former InteractionKey group.

## Native game settings

The game's Accessibility AutoLoot and Gameplay LootMergeEnabled options are separate from this mod. The included game container script retains the native corpse-merging path, which can collect nearby corpse loot within 15 metres when those game options are enabled. For interaction with only one corpse, keep the native loot-merging option disabled.

Native container theft exemptions and public compatibility helpers are retained.

## Removed features

- TrueAutoLoot and dedicated radius autoloot.
- Nearby-container scanning in the mod interaction handler.
- Category quantity/value restrictions and container-count overrides.
- Corpse and dropped-item overrides that bypassed category filters.
- The Containers menu page.
- Herb category filtering and ingredient loot quality filtering.
- Common/white weapon and armor destruction.
- Forced quest-container looting.
- The option to globally disable stealing reactions and warnings.
- Junk price and currency quantity popup thresholds.

## Repository layout

The original package directory contains:

- `Mods/modAutoLootASremaster/content/scripts/local/`: mod logic and console commands.
- `Mods/modAutoLootASremaster/content/scripts/game/`: game-script integration.
- `bin/config/r4game/user_config_matrix/pc/AHDAutoLootConfig.xml`: menu controls and presets.
- The existing bundled content and metadata.

## Validation

Changes have received static script/reference checks, XML parsing, and boolean-equivalence checks for the simplified conditions. These checks do not replace in-game compilation and gameplay testing. This repository does not include the game runtime or a WitcherScript compiler.

## Credits

Based on AutoLoot Advanced Settings by jerry18, with code credited to AeroHD and original AutoLoot code by JupiterTheGod. Original source attribution remains in the scripts.
