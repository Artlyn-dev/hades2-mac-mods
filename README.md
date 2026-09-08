# Hades II Mac Mods

Unofficial local patches and a macOS launcher for the **native Steam** build of [Hades II](https://store.steampowered.com/app/1145350/Hades_II/). This is not Hell2Modding / Thunderstore / r2modman. Patches are applied to Lua (and a few Game files) on your machine.

**Hades II © SuperGiant Games. This project is unofficial and is not affiliated with, endorsed by, or connected to SuperGiant Games.** You must own a legitimate Steam copy. Do not use these tools to redistribute game files.

## Requirements

- macOS 14+
- Hades II installed via Steam (native `.app`, not CrossOver / Windows)
- Python 3
- Xcode Command Line Tools (`swift`) if you build the launcher

Default game path:

`~/Library/Application Support/Steam/steamapps/common/Hades II/Hades II.app`

## Setup

1. Clone this repository. Do **not** commit or share `vanilla-backup/` — that folder is a copy of SuperGiant scripts and stays gitignored.
2. Close Hades II completely.
3. Back up vanilla `Scripts` and `Game`:

   ```bash
   ./tools/backup-vanilla.sh
   ```

4. Build the launcher (optional; you can also call the Python CLI):

   ```bash
   ./launcher/build.sh
   open ./launcher/Hades2Mods.app
   ```

5. Turn on the toggles you want, click **Apply patches**, then **Launch Hades II** (or start it from Steam). Restart the game after applying so scripts reload.

Restore the stock game at any time:

```bash
./tools/restore-vanilla.sh
```

Steam → Hades II → Properties → Installed Files → **Verify integrity of game files** also restores vanilla files.

CLI equivalent of the launcher:

```bash
python3 tools/apply-mod.py --status
python3 tools/apply-mod.py --enable dream_length,scorch_cap --json
```

## Toggles

| Id | What it does |
| --- | --- |
| `dream_length` | Dream Dive: 8 zones, VoR on 5–8, scaling past zone 4, ally rarity/damage, Pool of Purging after each boss |
| `dream_rewards` | Extra hammers and a 5th god on a longer dive |
| `dream_shop_pacing` | Shop / Nemesis halves follow half the dive |
| `dream_scaling` | Zones 5–8 keep scaling past biome 4 |
| `night_bloom_scale` | Night Bloom biome damage for raised servants |
| `scorch_cap` | Scorch stack cap 99,999 |
| `support_fire` | Support Fire arrow cap and Pom scaling |
| `support_fire_scale` | Support Fire +10% damage per biome after the first |
| `pommable_boons` | Pom Killing Stroke, Easy Shot, Winner's Circle, Success Rate |
| `reckless_abandon` | Reckless Abandon even rolls and per-biome bonus |
| `discordant_bell` | Discordant Bell +5% per encounter |
| `damage_meter` | In-combat damage breakdown by source |

See [CHANGELOG.md](CHANGELOG.md) for the 0.1.0 feature list.

## Requests

Want **new gameplay behind its own toggle**? Open a **new GitHub Issue** — one idea per issue. Include what should change, why, and that it should be a separate toggle.

Bugs in existing toggles also belong in separate issues.

Please do not send a pull request for a new toggle until there is an issue for it.

## Credits

- **SuperGiant Games** — Hades II. All game assets and vanilla scripts remain theirs.
- **zerp / Aditya Gupta ([adi1998](https://github.com/adi1998))** — [DreamDiveTweaks](https://github.com/adi1998/DreamDiveTweaks) (Thunderstore: [zerp/DreamDiveTweaks](https://thunderstore.io/c/hades-ii/p/zerp/DreamDiveTweaks/)), MIT. Dream Dive length, rewards, shop pacing, and late-zone scaling in this repo are inspired by that PC mod. Full license text: [tools/NOTICE-DreamDiveTweaks.txt](tools/NOTICE-DreamDiveTweaks.txt).
- **Jen Guerra (Jowday)** — [JowdayDamageMeter](https://github.com/The-Black-Lodge/JowdayDamageMeter), MIT. The Mac damage-meter overlay and source mapping are adapted from that project. Full license text: [tools/NOTICE-JowdayDamageMeter.txt](tools/NOTICE-JowdayDamageMeter.txt).

## License

This repository’s original code (launcher, patcher, and original toggle logic) is [MIT](LICENSE), copyright Artlyn.

That license does **not** cover Hades II, Steam, or SuperGiant materials. Third-party MIT notices for DreamDiveTweaks and JowdayDamageMeter are included as required.
