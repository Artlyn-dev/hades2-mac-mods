#!/usr/bin/env python3
"""Isolated apply checks for the damage_meter patch."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPLY_PATH = ROOT / "tools" / "apply-mod.py"


def load_apply():
    spec = importlib.util.spec_from_file_location("apply_mod", APPLY_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules["apply_mod"] = module
    spec.loader.exec_module(module)
    return module


def count(text: str, needle: str) -> int:
    return text.count(needle)


def assert_once(text: str, needle: str, label: str) -> None:
    found = count(text, needle)
    if found != 1:
        raise SystemExit(f"{label}: expected 1 occurrence of {needle!r}, found {found}")


def main() -> None:
    apply = load_apply()

    meter_only, log, enabled = apply.build_patched_texts(["damage_meter"])
    if enabled != ["damage_meter"]:
        raise SystemExit(f"enabled mismatch: {enabled}")
    combat = meter_only["CombatLogic.lua"]
    trait = meter_only["TraitLogic.lua"]
    room = meter_only["RoomLogic.lua"]
    hud = meter_only["HUDLogic.lua"]

    assert_once(combat, "function LocalModVanillaDamageEnemy", "meter-only vanilla DamageEnemy")
    assert_once(combat, "function LocalModMeterDamageEnemy", "meter-only meter DamageEnemy")
    if "LocalModMeterNameLookup" not in combat:
        raise SystemExit("meter-only name lookup missing")
    assert_once(combat, "function DamageEnemy(victim, triggerArgs)", "meter-only wrapper DamageEnemy")
    if "function DamageEnemy( victim, triggerArgs )" in combat:
        raise SystemExit("vanilla DamageEnemy signature still present")
    assert_once(trait, "function LocalModVanillaCheckChillKill", "meter-only ChillKill vanilla")
    if "LocalModMeterCheckChillKill" not in trait:
        raise SystemExit("meter-only ChillKill hook missing")
    if "LocalModMeterOnStartRoom" not in room:
        raise SystemExit("meter-only StartRoom missing")
    if "LocalModMeterOnRoomClear" not in room:
        raise SystemExit("meter-only room clear missing")
    if "LocalModMeterShow" in hud or "LocalModMeterHide" in hud:
        raise SystemExit("HUDLogic should be vanilla (no meter Hide/Show hooks)")
    if "function ShowCombatUI" not in hud:
        raise SystemExit("HUDLogic missing from apply output")
    if "waitUnmodified" not in combat:
        raise SystemExit("meter poll should use waitUnmodified")
    if "LocalModMeterFrozen" not in combat:
        raise SystemExit("meter freeze flag missing")
    if "meterHashColor" not in combat:
        raise SystemExit("meter color palette missing")
    if "SetRGB" not in combat:
        raise SystemExit("meter SetRGB tint missing")
        raise SystemExit("damage_meter alone should not prepend DreamRun helpers")

    combo, _, combo_enabled = apply.build_patched_texts(
        ["damage_meter", "reckless_abandon", "dream_length"]
    )
    if "reckless_abandon" not in combo_enabled or "dream_length" not in combo_enabled:
        raise SystemExit(f"combo enabled mismatch: {combo_enabled}")
    combo_combat = combo["CombatLogic.lua"]
    assert_once(combo_combat, "function LocalModVanillaDamageEnemy", "combo vanilla DamageEnemy")
    assert_once(combo_combat, "function LocalModMeterDamageEnemy", "combo meter DamageEnemy")
    assert_once(combo_combat, "LocalModRecklessRollValue", "combo reckless")
    combo_trait = combo["TraitLogic.lua"]
    assert_once(combo_trait, "function LocalModVanillaCheckChillKill", "combo ChillKill")
    if "LocalModPrepareDreamAllyRarity" not in combo_trait:
        raise SystemExit("dream_length TraitLogic mutator missing in combo")
    combo_room = combo["RoomLogic.lua"]
    if "LocalModMeterOnStartRoom" not in combo_room:
        raise SystemExit("meter StartRoom missing in combo")
    if "LocalModSpawnDreamPurgingWell" not in combo_room:
        raise SystemExit("dream Pool of Purging missing in combo")

    print("damage_meter apply tests: ok")
    print("\n".join(log[:8]))


if __name__ == "__main__":
    sys.exit(main())
