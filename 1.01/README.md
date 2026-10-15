# AutoLoot Simplified

A simplified version of AutoLoot Advanced Settings by jerry18 for The Witcher 3 Remastered, with code credited to AeroHD and original AutoLoot code by JupiterTheGod. This build focuses on interaction with the selected container, loot-on-kill, category filters, and configurable notifications. Original source attribution remains in the scripts.

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

## Filters and protections

Enable filters activates category selection for loot-on-kill and mode 2 interaction looting. With filters off, category toggles do not restrict collection. Modes 0/1 retain their existing interaction filtering bypass.

Available categories, in menu order:

- Armor and weapons, each with an optional quality selector.
- Upgrades, tools, horse equipment, trophies, food, currency, and ingredients
- Junk, with an optional quality selector.
- Formulas, unread readable items, already-read items, keys, masks, and other items.

Quality selectors support exact quality and inclusive lower/upper thresholds. Options labelled less/greater use `<=`/`>=`. Armor and weapons support Common through Witcher quality; junk supports Common through Relic. Off means no quality restriction for that enabled category.

Global options protect Witcher schematics, special containers, trophies, beehives, Corvo Bianco herbs, and player-dropped loot. The horse-related protection disables mod looting while mounted; it does not filter horse equipment.

No accidental stealing blocks mod looting of containers marked as theft-enabled. It reads the native container `disableStealing` flag and does not scan for guards or witnesses. Normal game theft reactions remain in place.

Quest containers, Gwent-card containers, locks, decorations, and certain story-sensitive containers retain their existing protection rules. Global protections are separate from category eligibility.

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
