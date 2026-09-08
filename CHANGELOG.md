# Changelog

All notable changes to this project are documented in this file.

## [0.1.0] - 2026-09-08

First public-ready snapshot of the native macOS Hades II patcher and launcher.

### Dream Dive (inspired by DreamDiveTweaks)

- Eight biomes instead of four, extra post-boss rooms, a Pool of Purging after each boss, and Vow of Rivals coverage on zones 5–8.
- Extra hammers and gods: third hammer after four zones, fourth hammer later, fifth god from zone 5.
- Shop pacing and Nemesis first/second half follow half the dive instead of a hard two-zone split.
- Zones 5–8 keep scaling past biome 4 (enemies, NPC rarity, ally damage, Olympus statues, Hermes delivery).

### Other toggles

- Scorch (Burn) stack cap raised from 999 to 99,999.
- Support Fire: arrows keep up with attack speed (cap 30) and Poms raise damage; optional +10% arrow damage per biome after the first.
- Pommable boons: Killing Stroke, Easy Shot, Winner's Circle, and Success Rate.
- Reckless Abandon: even 33% rolls on 5 / 55 / 555, plus +111 per biome you picked it in.
- Discordant Bell: +5% damage dealt and taken after each encounter.
- Night Bloom: raised servants keep hex multipliers, plus ally biome damage (1.22 per zone).

### Damage meter

- In-combat overlay listing damage by source with amount and percent of the room (Jowday-style port). Independent of Dream Dive toggles.

### Tools

- SwiftUI launcher with per-feature toggles, Apply, Launch via Steam, and Reset to vanilla.
- Python patcher that writes named patches onto a local `vanilla-backup` copy of Scripts / Game.
