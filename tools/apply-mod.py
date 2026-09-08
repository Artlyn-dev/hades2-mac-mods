#!/usr/bin/env python3
"""Apply named local Mac patches onto vanilla Scripts from vanilla-backup."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BACKUP = REPO / "vanilla-backup" / "Scripts"
BACKUP_GAME = REPO / "vanilla-backup" / "Game"

DEFAULT_GAME = (
    Path.home()
    / "Library/Application Support/Steam/steamapps/common/Hades II"
    / "Hades II.app/Contents/Resources/Content/Scripts"
)
DEFAULT_CONTENT = DEFAULT_GAME.parent

THIRD_HAMMER = "LocalModThirdHammerLootRequirements"
FOURTH_HAMMER = "LocalModFourthHammerLootRequirements"

HAMMER_REQS = f'''
	{THIRD_HAMMER} =
	{{
		{{
			Path = {{ "GameState", "TextLinesRecord" }},
			CountOf =
			{{
				"PoseidonFirstPickUp",
				"DemeterFirstPickUp",
				"HestiaFirstPickUp",
				"AphroditeFirstPickUp",
				"ZeusFirstPickUp",
				"HephaestusFirstPickUp",
			}},
			Comparison = ">=",
			Value = 4,
		}},
		{{
			FunctionName = "RequiredNotInStore",
			FunctionArgs = {{ Name = "WeaponUpgradeDrop", }},
		}},
		{{
			Path = {{ "CurrentRun", "EnteredBiomes" }},
			Comparison = ">",
			Value = 4,
		}},
		{{
			Path = {{ "CurrentRun", "LootTypeHistory", "WeaponUpgrade" }},
			Comparison = "==",
			Value = 2,
		}},
	}},

	{FOURTH_HAMMER} =
	{{
		{{
			Path = {{ "GameState", "TextLinesRecord" }},
			CountOf =
			{{
				"PoseidonFirstPickUp",
				"DemeterFirstPickUp",
				"HestiaFirstPickUp",
				"AphroditeFirstPickUp",
				"ZeusFirstPickUp",
				"HephaestusFirstPickUp",
			}},
			Comparison = ">=",
			Value = 4,
		}},
		{{
			FunctionName = "RequiredNotInStore",
			FunctionArgs = {{ Name = "WeaponUpgradeDrop", }},
		}},
		{{
			Path = {{ "CurrentRun", "EnteredBiomes" }},
			Comparison = ">",
			Value = 6,
		}},
		{{
			Path = {{ "CurrentRun", "LootTypeHistory", "WeaponUpgrade" }},
			Comparison = "==",
			Value = 3,
		}},
	}},
'''

LOOT_EXTRA = f'''		{{
			Name = "WeaponUpgrade",
			GameStateRequirements =
			{{
				NamedRequirements = {{ "{THIRD_HAMMER}" }},
			}}
		}},
		{{
			Name = "WeaponUpgrade",
			GameStateRequirements =
			{{
				NamedRequirements = {{ "{FOURTH_HAMMER}" }},
			}}
		}},
'''

HELPER = '''function LocalModScaleNumeric( prev, last, steps )
	if type(last) ~= "number" then
		return last
	end
	if type(prev) ~= "number" then
		return last * (1.22 ^ steps)
	end
	if prev > 0 and last > prev then
		local ratio = last / prev
		if ratio > 1.22 then
			ratio = 1.22
		end
		return last * (ratio ^ steps)
	end
	return last + (last - prev) * steps
end

function LocalModScaleModifierTable( prevTable, lastTable, steps )
	if type(lastTable) ~= "table" then
		return lastTable
	end
	local result = DeepCopyTable( lastTable )
	for key, value in pairs( lastTable ) do
		local prevVal = nil
		if type(prevTable) == "table" then
			prevVal = prevTable[key]
		end
		if type(value) == "number" then
			result[key] = LocalModScaleNumeric( prevVal, value, steps )
		elseif type(value) == "table" then
			result[key] = LocalModScaleModifierTable( prevVal, value, steps )
		end
	end
	return result
end

function LocalModScaleDreamEntry( prevTable, lastTable, steps )
	local result = DeepCopyTable( lastTable )
	if result.DataOverrides ~= nil then
		local prevOverrides = nil
		if prevTable ~= nil then
			prevOverrides = prevTable.DataOverrides
		end
		result.DataOverrides = LocalModScaleModifierTable( prevOverrides, lastTable.DataOverrides, steps )
		if result.DataOverrides.SpeedMultiplier ~= nil and type(result.DataOverrides.SpeedMultiplier) == "number" then
			local lastSpeed = lastTable.DataOverrides.SpeedMultiplier
			result.DataOverrides.SpeedMultiplier = math.min( 1.7, lastSpeed + 0.08 * steps )
		end
	end
	if result.AddOutgoingDamageModifier ~= nil then
		local prevMod = nil
		if prevTable ~= nil then
			prevMod = prevTable.AddOutgoingDamageModifier
		end
		result.AddOutgoingDamageModifier = LocalModScaleModifierTable( prevMod, lastTable.AddOutgoingDamageModifier, steps )
	end
	if result.AddOutgoingDamageModifiers ~= nil then
		local prevMod = nil
		if prevTable ~= nil then
			prevMod = prevTable.AddOutgoingDamageModifiers
		end
		result.AddOutgoingDamageModifiers = LocalModScaleModifierTable( prevMod, lastTable.AddOutgoingDamageModifiers, steps )
	end
	return result
end

function LocalModGetDreamBiomeData( dataTable, biomeLevel )
	if dataTable == nil then
		return nil
	end
	if dataTable[biomeLevel] ~= nil then
		return dataTable[biomeLevel]
	end
	local keys = {}
	for key, value in pairs( dataTable ) do
		if type(key) == "number" then
			table.insert( keys, key )
		end
	end
	table.sort( keys )
	if #keys == 0 then
		return nil
	end
	local maxKey = keys[#keys]
	if biomeLevel <= maxKey then
		local bestData = nil
		for _, key in ipairs( keys ) do
			if key <= biomeLevel then
				bestData = dataTable[key]
			end
		end
		return bestData
	end
	local lastData = dataTable[maxKey]
	local prevData = nil
	if #keys >= 2 then
		prevData = dataTable[keys[#keys - 1]]
	end
	return LocalModScaleDreamEntry( prevData, lastData, biomeLevel - maxKey )
end

function LocalModDreamFirstHalf( source, args )
	args = args or {}
	local result = (CurrentRun.EnteredBiomes or 0) <= (GameData.FullRunBiomeCount / 2)
	if args.Invert then
		return not result
	end
	return result
end

function LocalModDreamFinalBiome( source, args )
	return (CurrentRun.EnteredBiomes or 0) >= (GameData.FullRunBiomeCount or 4)
end

function LocalModGetDreamAllyDamageMultiplier()
	local biome = CurrentRun.EnteredBiomes or 1
	if biome < 1 then
		biome = 1
	end
	return 1.22 ^ (biome - 1)
end

function LocalModApplyDreamAllyDamage( unit )
	if unit == nil or unit.Name == nil then
		return
	end
	if CurrentRun == nil or not CurrentRun.IsDreamRun then
		return
	end
	if unit.Name ~= "NPC_Artemis_Field_01" and unit.Name ~= "NPC_Icarus_01" and unit.Name ~= "NPC_Heracles_01" then
		return
	end
	if GetOutgoingDamageModifier( unit, "LocalModAllyBiome" ) ~= nil then
		return
	end
	AddOutgoingDamageModifier( unit, { Name = "LocalModAllyBiome", NonPlayerMultiplier = LocalModGetDreamAllyDamageMultiplier() } )
end

function LocalModApplyNightBloomDreamDamage( unit )
	if unit == nil then
		return
	end
	if CurrentRun == nil or not CurrentRun.IsDreamRun then
		return
	end
	if not unit.AlwaysTraitor or not unit.Charmed then
		return
	end
	if GetOutgoingDamageModifier( unit, "LocalModNightBloomBiome" ) ~= nil then
		return
	end
	AddOutgoingDamageModifier( unit, { Name = "LocalModNightBloomBiome", NonPlayerMultiplier = LocalModGetDreamAllyDamageMultiplier() } )
end

function LocalModApplyDreamOutgoingModifiers( unit, dreamBiomeData )
	if unit == nil or dreamBiomeData == nil then
		return
	end
	if dreamBiomeData.AddOutgoingDamageModifier ~= nil then
		AddOutgoingDamageModifier( unit, dreamBiomeData.AddOutgoingDamageModifier )
	end
	local mods = dreamBiomeData.AddOutgoingDamageModifiers
	if mods == nil then
		return
	end
	if mods[1] ~= nil then
		for _, modifier in ipairs( mods ) do
			AddOutgoingDamageModifier( unit, modifier )
		end
	else
		AddOutgoingDamageModifier( unit, mods )
	end
end

function LocalModGetDreamPurgingWellData( roomName )
	local data =
	{
		Dream_PostBoss01 =
		{
			DestinationId = 800777,
			ShadowId = 824065,
			OffsetX = 250,
			OffsetY = -125,
			Flipped = true,
			ShadowColor = { 80/255, 169/255, 255/255, 255/255 },
		},
		Dream_PostBoss02 =
		{
			DestinationId = 800777,
			ShadowId = 824063,
			OffsetX = 300,
			OffsetY = -30,
			Flipped = true,
		},
		Dream_PostBoss03 =
		{
			DestinationId = 800777,
			ShadowId = 822826,
			OffsetX = -700,
			OffsetY = -125,
			Flipped = true,
			ShadowHSV = { 0, -1, 0 },
			ShadowOffsetX = -20,
			ShadowOffsetY = -10,
		},
	}
	return data[roomName]
end

function LocalModSpawnDreamPurgingWell( currentRun )
	if currentRun == nil or currentRun.CurrentRoom == nil then
		return
	end
	local currentRoom = currentRun.CurrentRoom
	local wellData = LocalModGetDreamPurgingWellData( currentRoom.Name )
	if wellData == nil then
		return
	end
	if currentRoom.SellTraitShop ~= nil then
		return
	end
	if currentRoom.WellShop == nil then
		return
	end
	if GameState == nil or GameState.WorldUpgradesAdded == nil or not GameState.WorldUpgradesAdded.WorldUpgradePostBossSellTraitShops then
		return
	end
	if currentRoom.WellShopRequirements ~= nil and not IsGameStateEligible( currentRoom, currentRoom.WellShopRequirements ) then
		return
	end
	if ObstacleData == nil or ObstacleData.SellTraitShop == nil then
		return
	end

	local shadowId = SpawnObstacle({
		Name = "AtmosphereShadowRectangle06",
		DestinationId = wellData.ShadowId,
		OffsetY = wellData.OffsetY + ( wellData.ShadowOffsetY or 0 ),
		OffsetX = wellData.OffsetX + ( wellData.ShadowOffsetX or 0 ),
		Group = "Terrain_Shadow_01",
		Scale = 0.102,
	})
	if shadowId ~= nil and shadowId ~= 0 then
		SetScale({ Id = shadowId, Fraction = 0.102 })
		if wellData.ShadowColor then
			SetColor({ Id = shadowId, Color = wellData.ShadowColor })
			SetHSV({ Id = shadowId, HSV = { 0, -1, 0 } })
		else
			SetColor({ Id = shadowId, Color = { 255, 255, 255, 255 } })
		end
		if wellData.ShadowHSV then
			SetHSV({ Id = shadowId, HSV = wellData.ShadowHSV })
		end
		SetThingProperty({ Property = "Ambient", Value = -1, DestinationId = shadowId })
		if not wellData.Flipped then
			FlipHorizontal({ Id = shadowId })
		end
	end

	local shop = DeepCopyTable( ObstacleData.SellTraitShop )
	shop.ObjectId = SpawnObstacle({ Name = "ChallengeSwitchBase", DestinationId = wellData.DestinationId, OffsetY = wellData.OffsetY, OffsetX = wellData.OffsetX, Group = "Standing" })
	if shop.ObjectId == nil or shop.ObjectId == 0 then
		return
	end
	SetupObstacle( shop )
	shop.ReadyToUse = false
	RefreshUseButton( shop.ObjectId, shop )
	SetAnimation({ Name = "SellTraitShopLocked", DestinationId = shop.ObjectId })
	UseableOn({ Id = shop.ObjectId })
	if wellData.Flipped then
		FlipHorizontal({ Id = shop.ObjectId })
	end
	currentRoom.SellTraitShop = shop
	GenerateSellTraitShop( currentRoom )
end

function LocalModScaleRarityMultiplier( prev, last, steps )
	if type(last) ~= "number" then
		return 1
	end
	if type(prev) ~= "number" then
		return last
	end
	if last > prev and prev > 0 then
		local ratio = last / prev
		if ratio > 1.22 then
			ratio = 1.22
		end
		return last * (ratio ^ steps)
	end
	if last < prev and last > 0 and prev > 0 then
		return 1 / ( (1 / last) + steps * ( (1 / last) - (1 / prev) ) )
	end
	return last
end

function LocalModRarityMultiplierValue( rarityEntry )
	if type(rarityEntry) ~= "table" then
		return 1
	end
	return rarityEntry.Multiplier or 1
end

function LocalModFillExtraRarityLevels( rarityData, traitName )
	if rarityData == nil or type(rarityData) ~= "table" then
		return
	end
	if rarityData.LocalModAlly5 ~= nil then
		return
	end
	local order = TraitRarityData.RarityUpgradeOrder
	local highKey = nil
	local midKey = nil
	for i = #order, 1, -1 do
		if rarityData[order[i]] ~= nil then
			if highKey == nil then
				highKey = order[i]
			else
				midKey = order[i]
				break
			end
		end
	end
	if highKey == nil then
		return
	end
	local lastMult = LocalModRarityMultiplierValue( rarityData[highKey] )
	local prevMult = lastMult
	if midKey ~= nil then
		prevMult = LocalModRarityMultiplierValue( rarityData[midKey] )
	end
	local overrides = {
		CirceShrinkTrait = { 2.1, 2.2, 2.3, 2.4 },
	}
	for extra = 1, 4 do
		local rarityName = "LocalModAlly"..(4 + extra)
		local multiplier = lastMult
		if overrides[traitName] ~= nil then
			multiplier = overrides[traitName][extra]
		else
			multiplier = LocalModScaleRarityMultiplier( prevMult, lastMult, extra )
		end
		rarityData[rarityName] = { Multiplier = multiplier }
	end
end

function LocalModFillNestedRarityTables( node, traitName, seen )
	if type(node) ~= "table" then
		return
	end
	seen = seen or {}
	if seen[node] then
		return
	end
	seen[node] = true
	if node.RarityLevels ~= nil then
		LocalModFillExtraRarityLevels( node.RarityLevels, traitName )
	end
	if node.CustomRarityMultiplier ~= nil then
		LocalModFillExtraRarityLevels( node.CustomRarityMultiplier, traitName )
	end
	for _, value in pairs( node ) do
		if type(value) == "table" then
			LocalModFillNestedRarityTables( value, traitName, seen )
		end
	end
end

function LocalModEnsureTraitAllyRarities( traitName )
	if traitName == nil or TraitData == nil then
		return
	end
	LocalModFillNestedRarityTables( TraitData[traitName], traitName )
end

function LocalModRegisterDreamAllyRarityUI()
	if TraitRarityData == nil or TraitRarityData.RarityValues == nil then
		return
	end
	for extra = 1, 4 do
		local rarityName = "LocalModAlly"..(4 + extra)
		local display = "Heroic"
		if extra >= 3 then
			display = "Legendary"
		end
		if TraitRarityData.RarityValues[rarityName] == nil then
			TraitRarityData.RarityValues[rarityName] = 4 + extra
		end
		if Color ~= nil and Color["BoonPatch"..rarityName] == nil then
			Color["BoonPatch"..rarityName] = Color["BoonPatch"..display]
		end
		if ScreenData ~= nil and ScreenData.UpgradeChoice ~= nil and ScreenData.UpgradeChoice.RarityBackingAnimations ~= nil and ScreenData.UpgradeChoice.RarityBackingAnimations[rarityName] == nil then
			ScreenData.UpgradeChoice.RarityBackingAnimations[rarityName] = ScreenData.UpgradeChoice.RarityBackingAnimations[display]
		end
	end
end

function LocalModGetDreamAllyRarity( traitName )
	LocalModRegisterDreamAllyRarityUI()
	local biome = CurrentRun.EnteredBiomes or 1
	if biome < 1 then
		biome = 1
	end
	local order = TraitRarityData.RarityUpgradeOrder
	if biome <= #order then
		return order[biome]
	end
	if biome > 8 then
		biome = 8
	end
	local rarityName = "LocalModAlly"..biome
	if traitName ~= nil then
		LocalModEnsureTraitAllyRarities( traitName )
	end
	return rarityName
end

function LocalModPrepareDreamAllyRarity( traitData, rarity )
	if traitData == nil or rarity == nil then
		return
	end
	if string.sub( rarity, 1, 12 ) ~= "LocalModAlly" then
		return
	end
	LocalModRegisterDreamAllyRarityUI()
	if traitData.Name ~= nil then
		LocalModEnsureTraitAllyRarities( traitData.Name )
	end
	LocalModFillNestedRarityTables( traitData, traitData.Name )
	local display = "Heroic"
	if rarity == "LocalModAlly7" or rarity == "LocalModAlly8" then
		display = "Legendary"
	end
	traitData.Frame = display
	traitData.CustomRarityName = "Boon_"..display
	traitData.CustomRarityColor = Color["BoonPatch"..display]
end

function LocalModApplyDreamAllyRarityToLoot( lootData )
	if lootData == nil or lootData.UpgradeOptions == nil then
		return
	end
	if CurrentRun == nil or not CurrentRun.IsDreamRun then
		return
	end
	local name = lootData.Name
	if name ~= "NPC_Artemis_Field_01" and name ~= "NPC_Athena_01" and name ~= "NPC_Icarus_01" then
		return
	end
	for _, item in pairs( lootData.UpgradeOptions ) do
		item.Rarity = LocalModGetDreamAllyRarity( item.ItemName )
	end
end


'''

Mutator = Callable[[str], str]


def replace(text: str, old: str, new: str, *, count: int | None = 1, name: str) -> str:
    found = text.count(old)
    expected = found if count is None else count
    if found != expected:
        raise SystemExit(f"{name}: expected {expected} occurrence(s) of pattern, found {found}")
    return text.replace(old, new)


def replace_or_skip(text: str, old: str, new: str, *, name: str, count: int | None = 1) -> str:
    if new in text:
        return text
    return replace(text, old, new, count=count, name=name)


@dataclass
class Patch:
    id: str
    title: str
    description: str
    files: list[str]
    mutators: dict[str, Mutator] = field(default_factory=dict)
    needs_helpers: bool = False


def patch_dream_length_narrative(text: str) -> str:
    return replace(
        text,
        "GameData.FullRunBiomeCount = 4",
        "GameData.FullRunBiomeCount = 8",
        name="NarrativeData FullRunBiomeCount",
    )


def patch_dream_length_rooms(text: str) -> str:
    return replace(
        text,
        """	Dream =
	{
		"Dream_Intro",
		"Dream_PostBoss01",
		"Dream_PostBoss02",
		"Dream_PostBoss03",
	},""",
        """	Dream =
	{
		"Dream_Intro",
		"Dream_PostBoss01",
		"Dream_PostBoss02",
		"Dream_PostBoss03",
		"Dream_PostBoss01",
		"Dream_PostBoss02",
		"Dream_PostBoss03",
		"Dream_PostBoss01",
	},""",
        name="RoomSets Dream",
    )


def patch_dream_length_logic(text: str) -> str:
    text = replace(
        text,
        "	if CurrentRun.EnteredBiomes == GameData.FullRunBiomeCount then",
        "	if CurrentRun.EnteredBiomes >= GameData.FullRunBiomeCount then",
        name="DreamRunLogic completion",
    )
    return replace(
        text,
        """		local nextRoomName = RoomSets.Dream[CurrentRun.EnteredBiomes + 1]
		local nextRoom = CreateRoom( RoomData[nextRoomName] )""",
        """		local nextRoomName = RoomSets.Dream[CurrentRun.EnteredBiomes + 1]
		if nextRoomName == nil then
			nextRoomName = "Dream_PostBoss0"..(((CurrentRun.EnteredBiomes - 1) % 3) + 1)
		end
		local nextRoom = CreateRoom( RoomData[nextRoomName] )""",
        name="DreamRunLogic next room fallback",
    )


def patch_dream_length_icons(text: str) -> str:
    return replace(
        text,
        """function GetVisitedBiomeIcons( run )
	local tooltipData = {}
	for i=1,4 do
		local icon = RoomSetIcons[run.BiomeVisitOrder[i]] or "BiomeMysteryIcon"
		tooltipData[i] = IconData[icon].TexturePath
	end
	return tooltipData
end""",
        """function GetVisitedBiomeIcons( run )
	local tooltipData = {}
	local count = math.max( 4, GameData.FullRunBiomeCount or 4, #(run.BiomeVisitOrder or {}) )
	for i=1, count do
		local icon = RoomSetIcons[run.BiomeVisitOrder[i]] or "BiomeMysteryIcon"
		tooltipData[i] = IconData[icon].TexturePath
	end
	return tooltipData
end""",
        name="RunHistoryLogic icons",
    )


def patch_dream_length_shrine(text: str) -> str:
    return replace(
        text,
        """	if args.UseShrineUpgradesCache then
		if (CurrentRun.ShrineUpgradesCache.BossDifficultyShrineUpgrade or 0) < CurrentRun.EnteredBiomes then
			return false
		end
	else
		if (GameState.ShrineUpgrades.BossDifficultyShrineUpgrade or 0) < CurrentRun.EnteredBiomes then
			return false
		end
	end""",
        """	local biomeRank = CurrentRun.EnteredBiomes
	if CurrentRun.IsDreamRun then
		biomeRank = math.min(CurrentRun.EnteredBiomes, 4)
	end
	if args.UseShrineUpgradesCache then
		if (CurrentRun.ShrineUpgradesCache.BossDifficultyShrineUpgrade or 0) < biomeRank then
			return false
		end
	else
		if (GameState.ShrineUpgrades.BossDifficultyShrineUpgrade or 0) < biomeRank then
			return false
		end
	end""",
        name="ShrineLogic VoR dream cap",
    )


def patch_dream_length_clear(text: str) -> str:
    return replace(
        text,
        """function RunClearMessagePresentation( screen, message, tooltipData )

	if message == nil then
		return
	end""",
        """function RunClearMessagePresentation( screen, message, tooltipData )

	if message == nil then
		return
	end

	if message == "ClearDreamRun" and type(tooltipData) == "table" and #tooltipData > 4 then
		local iconTemplate = "{!TooltipData[{{index}}]}"
		message = string.gsub(iconTemplate, "{{index}}", 1)
		for i = 2, #tooltipData do
			message = message .. " " .. string.gsub(iconTemplate, "{{index}}", i)
		end
	end""",
        name="UIPresentation clear icons",
    )


def patch_rewards_requirements(text: str) -> str:
    return replace(
        text,
        """			Path = { "CurrentRun", "LootTypeHistory", "WeaponUpgrade" },
			Comparison = "==",
			Value = 1,
		},
	},
	StackUpgradeLegal =""",
        f"""			Path = {{ "CurrentRun", "LootTypeHistory", "WeaponUpgrade" }},
			Comparison = "==",
			Value = 1,
		}},
	}},
{HAMMER_REQS}
	StackUpgradeLegal =""",
        name="RequirementsData extra hammers",
    )


def patch_rewards_gods(text: str) -> str:
    return replace(
        text,
        """	if currentRoom.BiomeStartRoom and HeroHasTrait("EchoRepeatKeepsakeBoon") then""",
        """	if currentRun.IsDreamRun and currentRoom.BiomeStartRoom then
		local entered = currentRun.EnteredBiomes or 1
		currentRun.MaxGodsPerRun = 4 + math.floor( (entered - 1) / 4 )
	end

	if currentRoom.BiomeStartRoom and HeroHasTrait("EchoRepeatKeepsakeBoon") then""",
        name="RoomLogic MaxGodsPerRun",
    )


def patch_rewards_loot(text: str) -> str:
    return replace(
        text,
        """			{
				NamedRequirements = { "LateHammerLootRequirements" },
			}
		},""",
        f"""			{{
				NamedRequirements = {{ "LateHammerLootRequirements" }},
			}}
		}},
{LOOT_EXTRA}""",
        count=3,
        name="LootData extra hammers",
    )


def patch_rewards_store(text: str) -> str:
    return replace(
        text,
        """					{ 
						Name = "WeaponUpgradeDrop", Weight = 2.5,
						ReplaceRequirements = 
						{ 
							{
								PathTrue = { "GameState", "UseRecord", "WeaponUpgrade" },
							},
							NamedRequirements = { "LateHammerLootRequirements" },
						},
					},""",
        f"""					{{
						Name = "WeaponUpgradeDrop", Weight = 2.5,
						ReplaceRequirements =
						{{
							{{
								PathTrue = {{ "GameState", "UseRecord", "WeaponUpgrade" }},
							}},
							NamedRequirements = {{ "LateHammerLootRequirements" }},
						}},
					}},
					{{
						Name = "WeaponUpgradeDrop", Weight = 2.5,
						ReplaceRequirements =
						{{
							{{
								PathTrue = {{ "GameState", "UseRecord", "WeaponUpgrade" }},
							}},
							NamedRequirements = {{ "{THIRD_HAMMER}" }},
						}},
					}},
					{{
						Name = "WeaponUpgradeDrop", Weight = 2.5,
						ReplaceRequirements =
						{{
							{{
								PathTrue = {{ "GameState", "UseRecord", "WeaponUpgrade" }},
							}},
							NamedRequirements = {{ "{FOURTH_HAMMER}" }},
						}},
					}},""",
        name="StoreData extra hammers",
    )


def patch_rewards_npc(text: str) -> str:
    return replace(
        text,
        """			{ Name = "WeaponUpgrade", CostResourceName = "Money", CostResourceMin = 180, CostResourceMax = 205,
				GameStateRequirements =
				{
					NamedRequirements = { "LateHammerLootRequirements", },
				},
			},""",
        f"""			{{ Name = "WeaponUpgrade", CostResourceName = "Money", CostResourceMin = 180, CostResourceMax = 205,
				GameStateRequirements =
				{{
					NamedRequirements = {{ "LateHammerLootRequirements", }},
				}},
			}},
			{{ Name = "WeaponUpgrade", CostResourceName = "Money", CostResourceMin = 180, CostResourceMax = 205,
				GameStateRequirements =
				{{
					NamedRequirements = {{ "{THIRD_HAMMER}", }},
				}},
			}},
			{{ Name = "WeaponUpgrade", CostResourceName = "Money", CostResourceMin = 180, CostResourceMax = 205,
				GameStateRequirements =
				{{
					NamedRequirements = {{ "{FOURTH_HAMMER}", }},
				}},
			}},""",
        name="NPCData Nemesis hammers",
    )


def patch_shops_requirements(text: str) -> str:
    return replace(
        text,
        """	InRunFirstHalf = 
	{
		{
			Path = { "CurrentRun", "EnteredBiomes" },
			Comparison = "<=",
			Value = 2,
		}
	},
	InRunSecondHalf = 
	{
		{
			Path = { "CurrentRun", "EnteredBiomes" },
			Comparison = ">",
			Value = 2,
		}
	},""",
        """	InRunFirstHalf =
	{
		OrRequirements =
		{
			{
				{
					Path = { "CurrentRun", "EnteredBiomes" },
					Comparison = "<=",
					Value = 2,
				},
				{
					PathFalse = { "CurrentRun", "IsDreamRun" },
				},
			},
			{
				{
					FunctionName = "LocalModDreamFirstHalf",
				},
				{
					PathTrue = { "CurrentRun", "IsDreamRun" },
				},
			},
		},
	},
	InRunSecondHalf =
	{
		OrRequirements =
		{
			{
				{
					Path = { "CurrentRun", "EnteredBiomes" },
					Comparison = ">",
					Value = 2,
				},
				{
					PathFalse = { "CurrentRun", "IsDreamRun" },
				},
			},
			{
				{
					FunctionName = "LocalModDreamFirstHalf",
					FunctionArgs =
					{
						Invert = true,
					},
				},
				{
					PathTrue = { "CurrentRun", "IsDreamRun" },
				},
			},
		},
	},""",
        name="RequirementsData InRun halves",
    )


def patch_dream_sell_shop_spawn(text: str) -> str:
    return replace_or_skip(
        text,
        """	SetupHarvestPoints( currentRoom )

	-- Anomaly
	if currentRoom.AnomalyDoorChanceSuccess and IsGameStateEligible( currentRoom, currentRoom.AnomalyDoorRequirements or RoomData.BaseRoom.AnomalyDoorRequirements ) then
		currentRoom.DoAnomalies = true
	end
end""",
        """	SetupHarvestPoints( currentRoom )

	-- Anomaly
	if currentRoom.AnomalyDoorChanceSuccess and IsGameStateEligible( currentRoom, currentRoom.AnomalyDoorRequirements or RoomData.BaseRoom.AnomalyDoorRequirements ) then
		currentRoom.DoAnomalies = true
	end

	if LocalModSpawnDreamPurgingWell ~= nil then
		LocalModSpawnDreamPurgingWell( currentRun )
	end
end""",
        name="RoomLogic Dream Pool of Purging spawn",
    )


def patch_dream_length_roomlogic(text: str) -> str:
    return patch_dream_sell_shop_spawn(patch_scaling_room(text))


def patch_night_bloom_scale(text: str) -> str:
    return replace_or_skip(
        text,
        """	if unit.IsElite and not unit.Charmed then
""",
        """	if currentRun.IsDreamRun then
		LocalModApplyNightBloomDreamDamage( unit )
	end

	if unit.IsElite and not unit.Charmed then
""",
        name="RoomLogic Night Bloom biome damage",
    )


def patch_scaling_room(text: str) -> str:
    return replace_or_skip(
        text,
        """	if currentRun.IsDreamRun and unit.DreamBiomeData ~= nil then
		local biomeLevel = currentRun.EnteredBiomes or 1
		if unit.IsFromNextBiomeEnemyShrineUpgrade then
			biomeLevel = math.min(GameData.FullRunBiomeCount, biomeLevel + 1)
		end
		local dreamBiomeData = unit.DreamBiomeData[biomeLevel]
		if dreamBiomeData ~= nil then
			if dreamBiomeData.DataOverrides ~= nil then
				OverwriteTableKeys(unit, dreamBiomeData.DataOverrides)
			end
			if dreamBiomeData.AddOutgoingDamageModifier ~= nil then
				AddOutgoingDamageModifier(unit, dreamBiomeData.AddOutgoingDamageModifier)
			end
		end
	end""",
        """	if currentRun.IsDreamRun then
		local biomeLevel = currentRun.EnteredBiomes or 1
		if unit.IsFromNextBiomeEnemyShrineUpgrade then
			biomeLevel = math.min(GameData.FullRunBiomeCount, biomeLevel + 1)
		end
		if unit.DreamBiomeData ~= nil then
			local dreamBiomeData = LocalModGetDreamBiomeData( unit.DreamBiomeData, biomeLevel )
			if dreamBiomeData ~= nil then
				if dreamBiomeData.DataOverrides ~= nil then
					OverwriteTableKeys(unit, dreamBiomeData.DataOverrides)
				end
				LocalModApplyDreamOutgoingModifiers( unit, dreamBiomeData )
			end
		end
		LocalModApplyDreamAllyDamage( unit )
	end""",
        name="RoomLogic DreamBiomeData allies",
    )


def patch_scaling_run(text: str) -> str:
    return replace_or_skip(
        text,
        "		local dreamBiomeData = encounter.DreamBiomeData[biomeLevel]",
        "		local dreamBiomeData = LocalModGetDreamBiomeData( encounter.DreamBiomeData, biomeLevel )",
        name="RunLogic DreamBiomeData",
    )


def patch_scaling_event(text: str) -> str:
    return replace_or_skip(
        text,
        "		local dreamBiomeData = boss.DreamBiomeData[currentRun.EnteredBiomes]",
        "		local dreamBiomeData = LocalModGetDreamBiomeData( boss.DreamBiomeData, currentRun.EnteredBiomes )",
        name="EventPresentation DreamBiomeData",
    )


def patch_scaling_biome_i(text: str) -> str:
    return replace_or_skip(
        text,
        "		local dreamBiomeData = boss.DreamBiomeData[currentRun.EnteredBiomes]",
        "		local dreamBiomeData = LocalModGetDreamBiomeData( boss.DreamBiomeData, currentRun.EnteredBiomes )",
        name="PresentationBiomeI DreamBiomeData",
    )


def patch_scaling_biome_q(text: str) -> str:
    return replace_or_skip(
        text,
        "		local dreamBiomeData = typhon.DreamBiomeData[currentRun.EnteredBiomes]",
        "		local dreamBiomeData = LocalModGetDreamBiomeData( typhon.DreamBiomeData, currentRun.EnteredBiomes )",
        name="PresentationBiomeQ DreamBiomeData",
    )


def patch_ally_event_rarity(text: str) -> str:
    text = replace_or_skip(
        text,
        "			item.Rarity = TraitRarityData.RarityUpgradeOrder[CurrentRun.EnteredBiomes]",
        "			item.Rarity = LocalModGetDreamAllyRarity( item.ItemName )",
        name="EventLogic NPC dream rarity",
        count=6,
    )
    return replace_or_skip(
        text,
        """		if option.ItemName == "DoubleFamiliarTrait" then
			-- Advanced surgery to try and get statlines from across the world""",
        """		if CurrentRun.IsDreamRun then
			option.Rarity = LocalModGetDreamAllyRarity( option.ItemName )
		end
		if option.ItemName == "DoubleFamiliarTrait" then
			-- Advanced surgery to try and get statlines from across the world""",
        name="EventLogic Circe dream rarity preview",
    )


def patch_ally_trait_logic(text: str) -> str:
    text = replace_or_skip(
        text,
        """	if traitData == nil then
		return
	end

	local stackNum = traitData.StackNum or args.StackNum""",
        """	if traitData == nil then
		return
	end
	if LocalModPrepareDreamAllyRarity ~= nil then
		LocalModPrepareDreamAllyRarity( traitData, rarity )
	end

	local stackNum = traitData.StackNum or args.StackNum""",
        name="ProcessTraitData ally rarity",
    )
    text = replace_or_skip(
        text,
        """	lootData.BlockReroll = blockReroll
	lootData.UpgradeOptions = upgradeOptions
end""",
        """	lootData.BlockReroll = blockReroll
	lootData.UpgradeOptions = upgradeOptions
	if CurrentRun.IsDreamRun and LocalModApplyDreamAllyRarityToLoot ~= nil then
		LocalModApplyDreamAllyRarityToLoot( lootData )
	end
end""",
        name="SetTraitsOnLoot ally rarity",
    )
    return replace_or_skip(
        text,
        """		elseif extractData.Format == "RemainingBiomes" then
			local enteredBiomes = CurrentRun.EnteredBiomes or 0 
			value = math.min(4 - enteredBiomes, value)""",
        """		elseif extractData.Format == "RemainingBiomes" then
			local enteredBiomes = CurrentRun.EnteredBiomes or 0 
			value = math.min((GameData.FullRunBiomeCount or 4) - enteredBiomes, value)""",
        name="RemainingBiomes FullRunBiomeCount",
    )


def patch_olympus_statues(text: str) -> str:
    return replace_or_skip(
        text,
        """					{
						Path = { "CurrentRun", "EnteredBiomes", },
						Comparison = "==",
						Value = 4,
					},""",
        """					{
						Path = { "CurrentRun", "EnteredBiomes", },
						Comparison = ">=",
						Value = 4,
					},""",
        name="ObstacleDataP statue zone 4+",
    )


def patch_hermes_delivery(text: str) -> str:
    return replace_or_skip(
        text,
        """				{
					Path = { "CurrentRun", "EnteredBiomes" },
					Comparison = "==",
					Value = 4,
				}""",
        """				{
					FunctionName = "LocalModDreamFinalBiome",
				}""",
        name="EncounterSets Hermes delivery",
    )


def patch_nemesis_halves(text: str) -> str:
    text = replace_or_skip(
        text,
        """					{
						Path = { "CurrentRun", "EnteredBiomes" },
						Comparison = "<=",
						Value = 2,
					},""",
        """					{
						FunctionName = "LocalModDreamFirstHalf",
					},""",
        name="NPCData Nemesis first half",
        count=4,
    )
    return replace_or_skip(
        text,
        """					{
						Path = { "CurrentRun", "EnteredBiomes" },
						Comparison = ">",
						Value = 2,
					},""",
        """					{
						FunctionName = "LocalModDreamFirstHalf",
						FunctionArgs =
						{
							Invert = true,
						},
					},""",
        name="NPCData Nemesis second half",
        count=4,
    )


def patch_discordant_bell(text: str) -> str:
    return replace(
        text,
        "		EscalatingKeepsakeGrowthPerRoom = { BaseValue = 0.005, DecimalPlaces = 3 },",
        "		EscalatingKeepsakeGrowthPerRoom = { BaseValue = 0.05, DecimalPlaces = 3 },",
        name="EscalatingKeepsake growth",
    )


def patch_scorch(text: str) -> str:
    return replace(
        text,
        "		MaxStacks = 999,",
        "		MaxStacks = 99999,",
        name="EffectData Burn MaxStacks",
    )


def patch_support_trait(text: str) -> str:
    return replace(
        text,
        """				ProjectileName = "ArtemisSupportingFire",
				DamageMultiplier = { BaseValue = 1.0 },
				Cooldown = 0.167,
				--FizzleOldestProjectileCount = 2,
				ProjectileCap = 3,""",
        """				ProjectileName = "ArtemisSupportingFire",
				DamageMultiplier =
				{
					BaseValue = 1.0,
					AbsoluteStackValues =
					{
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.4,
						[4] = 0.4,
						[5] = 0.3,
					},
				},
				Cooldown = 0,
				--FizzleOldestProjectileCount = 2,
				ProjectileCap = 30,""",
        name="SupportingFire damage/cap",
    )


def patch_support_powers(text: str) -> str:
    return replace(
        text,
        """	local cooldown = functionArgs.Cooldown or 0.1667
	local passesHitCheck = CheckCooldown("SupportFire", window )""",
        """	local cooldown = functionArgs.Cooldown or 0
	local passesHitCheck = CheckCooldown("SupportFire", cooldown )""",
        name="SupportingFire cooldown",
    )


def patch_support_scale(text: str) -> str:
    return replace(
        text,
        """		CreateProjectileFromUnit({
				Name = functionArgs.ProjectileName, 
				Id = CurrentRun.Hero.ObjectId, 
				DestinationId = victim.ObjectId,
				Angle = angle + triggerArgs.ImpactAngle,
				DamageMultiplier = functionArgs.DamageMultiplier,
				FizzleOldestProjectileCount = functionArgs.FizzleOldestProjectileCount,
				ProjectileCap = functionArgs.ProjectileCap,
			})""",
        """		local biomeLevel = CurrentRun.EnteredBiomes or 1
		local biomeBonus = 0.10 * math.max(0, biomeLevel - 1)
		CreateProjectileFromUnit({
				Name = functionArgs.ProjectileName, 
				Id = CurrentRun.Hero.ObjectId, 
				DestinationId = victim.ObjectId,
				Angle = angle + triggerArgs.ImpactAngle,
				DamageMultiplier = functionArgs.DamageMultiplier + biomeBonus,
				FizzleOldestProjectileCount = functionArgs.FizzleOldestProjectileCount,
				ProjectileCap = functionArgs.ProjectileCap,
			})""",
        name="SupportingFire biome scale",
    )


def patch_pommable_focus(text: str) -> str:
    text = replace(
        text,
        """		Icon = "Boon_Artemis_34",
		BlockStacking = true,""",
        """		Icon = "Boon_Artemis_34",""",
        name="FocusCritBoon unblock",
    )
    return replace(
        text,
        """			ValidWeapons = WeaponSets.HeroSecondaryWeapons,
			Chance = { BaseValue = 0.10 },
			ReportValues = { ReportedCritBonus = "Chance"},""",
        """			ValidWeapons = WeaponSets.HeroSecondaryWeapons,
			Chance =
			{
				BaseValue = 0.10,
				AbsoluteStackValues =
				{
					[1] = 0.05,
					[2] = 0.04,
					[3] = 0.03,
					[4] = 0.03,
					[5] = 0.02,
				},
			},
			ReportValues = { ReportedCritBonus = "Chance"},""",
        name="FocusCritBoon pom stacks",
    )


def patch_pommable_easy_shot(text: str) -> str:
    return replace(
        text,
        """				ProjectileName = "ArtemisCastVolley",
				ProjectileCap = 5,
				SpawnDistance = 2600,
				Delay = 0.04,
				DamageMultiplier = { BaseValue = 1.0 },""",
        """				ProjectileName = "ArtemisCastVolley",
				ProjectileCap = 8,
				SpawnDistance = 2600,
				Delay = 0.04,
				DamageMultiplier =
				{
					BaseValue = 1.0,
					AbsoluteStackValues =
					{
						[1] = 0.5,
						[2] = 0.5,
						[3] = 0.4,
						[4] = 0.4,
						[5] = 0.3,
					},
				},""",
        name="OmegaCastVolleyBoon pom/cap",
    )


def patch_pommable_artemis(text: str) -> str:
    return patch_pommable_easy_shot(patch_pommable_focus(text))


def patch_pommable_winners(text: str) -> str:
    text = replace(
        text,
        """		CastModifier = true,
		BlockStacking = true,""",
        """		CastModifier = true,""",
        name="HermesCastDiscountBoon unblock",
    )
    speed_stacks = """				AbsoluteStackValues =
				{
					[1] = 0.95,
					[2] = 0.96,
					[3] = 0.97,
				},"""
    text = replace(
        text,
        """			Value = 
			{
				BaseValue = 0.714,
				DecimalPlaces = 4,
				SourceIsMultiplier = true,
			},""",
        f"""			Value = 
			{{
				BaseValue = 0.714,
				DecimalPlaces = 4,
				SourceIsMultiplier = true,
{speed_stacks}
			}},""",
        name="HermesCastDiscountBoon speed stacks",
    )
    text = replace(
        text,
        """		CastDurationMultiplier = { 
			BaseValue = 0.714,
			DecimalPlaces = 4,
			SourceIsMultiplier = true,
		},""",
        f"""		CastDurationMultiplier = {{
			BaseValue = 0.714,
			DecimalPlaces = 4,
			SourceIsMultiplier = true,
{speed_stacks}
		}},""",
        name="HermesCastDiscountBoon duration stacks",
    )
    return replace(
        text,
        """				WeaponName = "WeaponCast",
				ProjectileProperty = "FuseStart",
				BaseValue = 0.714,
				SourceIsMultiplier = true,
				ChangeType = "Multiply",
				DeriveSource = "DeriveSource",""",
        f"""				WeaponName = "WeaponCast",
				ProjectileProperty = "FuseStart",
				BaseValue = 0.714,
				SourceIsMultiplier = true,
{speed_stacks}
				ChangeType = "Multiply",
				DeriveSource = "DeriveSource",""",
        name="HermesCastDiscountBoon fuse stacks",
    )


def patch_pommable_lucky(text: str) -> str:
    text = replace(
        text,
        """		InheritFrom = { "BaseTrait", "WaterBoon"},
		BlockStacking = true,""",
        """		InheritFrom = { "BaseTrait", "WaterBoon"},""",
        name="LuckyBoon unblock",
    )
    luck_stacks = """			AbsoluteStackValues =
			{
				[1] = 1.15,
				[2] = 1.12,
				[3] = 1.10,
			},"""
    text = replace(
        text,
        """		LuckMultiplier =
		{
			BaseValue = 1.3,
			SourceIsMultiplier = true,
		},""",
        f"""		LuckMultiplier =
		{{
			BaseValue = 1.3,
			SourceIsMultiplier = true,
{luck_stacks}
		}},""",
        name="LuckyBoon luck stacks",
    )
    return replace(
        text,
        """				WeaponProperty = "AdditionalProjectileWaveChance",
				BaseValue =  1.3,
				ChangeType = "Multiply",
				SourceIsMultiplier = true,""",
        f"""				WeaponProperty = "AdditionalProjectileWaveChance",
				BaseValue =  1.3,
				ChangeType = "Multiply",
				SourceIsMultiplier = true,
{luck_stacks}""",
        name="LuckyBoon wave stacks",
    )


def patch_pommable_hermes(text: str) -> str:
    return patch_pommable_lucky(patch_pommable_winners(text))


RECKLESS_HELPERS = """function LocalModRecklessAbandonSnapshot( functionArgs, traitData )
	traitData.LocalModAcquireBiome = CurrentRun.EnteredBiomes or 1
end

function LocalModRecklessRollValue( value )
	if not HeroHasTrait("RandomBaseDamageBoon") then
		return value
	end
	local trait = GetHeroTrait("RandomBaseDamageBoon")
	if trait ~= nil and trait.LocalModAcquireBiome ~= nil then
		return value + 111 * math.max(0, trait.LocalModAcquireBiome - 1)
	end
	return value
end

"""


def patch_reckless_powers(text: str) -> str:
    if text.startswith("function LocalModRecklessAbandonSnapshot"):
        return text
    return RECKLESS_HELPERS + text


def patch_reckless_dionysus(text: str) -> str:
    text = replace(
        text,
        """		Icon = "Boon_Dionysus_29",

		RarityLevels =""",
        """		Icon = "Boon_Dionysus_29",
		AcquireFunctionName = "LocalModRecklessAbandonSnapshot",

		RarityLevels =""",
        name="RandomBaseDamageBoon acquire snapshot",
    )
    return replace(
        text,
        "					Chance = {BaseValue = 0.05},",
        "					Chance = 1/3,",
        name="RandomBaseDamageBoon even chance",
    )


def patch_reckless_combat(text: str) -> str:
    return replace(
        text,
        """				if modifierData.RandomizedBaseDamage then
					triggerArgs.IgnoreFutureModifiers = true
					damage = 0
					for i, data in ipairs( modifierData.RandomizedBaseDamage ) do
						if not data.Chance then
							if damage < data.Value then
								damage = data.Value
							end
						elseif RandomChance( data.Chance * GetTotalHeroTraitValue( "LuckMultiplier", { IsMultiplier = true })) and data.Value > damage then
							damage = data.Value""",
        """				if modifierData.RandomizedBaseDamage then
					triggerArgs.IgnoreFutureModifiers = true
					damage = 0
					for i, data in ipairs( modifierData.RandomizedBaseDamage ) do
						local rollValue = LocalModRecklessRollValue( data.Value )
						if not data.Chance then
							if damage < rollValue then
								damage = rollValue
							end
						elseif RandomChance( data.Chance * GetTotalHeroTraitValue( "LuckMultiplier", { IsMultiplier = true })) and rollValue > damage then
							damage = rollValue""",
        name="CalculateBaseDamage reckless scale",
    )


def meter_lua_source() -> str:
    data = (REPO / "tools" / "damage_meter_data.lua").read_text(encoding="utf-8")
    main = (REPO / "tools" / "damage_meter.lua").read_text(encoding="utf-8")
    return (
        "-- See tools/NOTICE-JowdayDamageMeter.txt (MIT, Jen Guerra).\n"
        + data
        + "\n"
        + main
        + "\n"
    )


def patch_damage_meter_combat(text: str) -> str:
    if "function LocalModMeterDamageEnemy" in text:
        return text
    text = replace(
        text,
        "function DamageEnemy( victim, triggerArgs )",
        "function LocalModVanillaDamageEnemy( victim, triggerArgs )",
        name="CombatLogic DamageEnemy rename",
    )
    return meter_lua_source() + text


def patch_damage_meter_trait(text: str) -> str:
    return replace_or_skip(
        text,
        """function CheckChillKill( args, attacker, victim, triggerArgs )
	if SessionMapState.FiredChillKill[victim.ObjectId] then
		return
	end""",
        """function CheckChillKill( args, attacker, victim, triggerArgs )
	if LocalModMeterCheckChillKill ~= nil then
		return LocalModMeterCheckChillKill( args, attacker, victim, triggerArgs )
	end
	return LocalModVanillaCheckChillKill( args, attacker, victim, triggerArgs )
end

function LocalModVanillaCheckChillKill( args, attacker, victim, triggerArgs )
	if SessionMapState.FiredChillKill[victim.ObjectId] then
		return
	end""",
        name="TraitLogic CheckChillKill meter wrap",
    )


def patch_damage_meter_room(text: str) -> str:
    text = replace_or_skip(
        text,
        """function StartRoom( currentRun, currentRoom )
	
	local roomData = RoomData[currentRoom.Name] or currentRoom""",
        """function StartRoom( currentRun, currentRoom )
	if LocalModMeterOnStartRoom ~= nil then
		LocalModMeterOnStartRoom()
	end
	
	local roomData = RoomData[currentRoom.Name] or currentRoom""",
        name="RoomLogic StartRoom meter",
    )
    return replace_or_skip(
        text,
        """function DoUnlockRoomExits( run, room )

	-- Synchronize the RNG to its initial state. Makes room reward choices deterministic on save/load
	RandomSynchronize()""",
        """function DoUnlockRoomExits( run, room )

	-- Synchronize the RNG to its initial state. Makes room reward choices deterministic on save/load
	RandomSynchronize()
	if LocalModMeterOnRoomClear ~= nil then
		LocalModMeterOnRoomClear()
	end""",
        name="RoomLogic DoUnlockRoomExits meter",
    )


PATCHES: list[Patch] = [
    Patch(
        id="dream_length",
        title="Dream Dive: 8 zones",
        description="8 biomes, max Vow of Rivals covers 5–8, scaling past zone 4, ally rarity/damage, and a Pool of Purging after each boss.",
        files=[
            "NarrativeData.lua",
            "RoomSets.lua",
            "DreamRunLogic.lua",
            "RunHistoryLogic.lua",
            "UIPresentation.lua",
            "ShrineLogic.lua",
            "RoomLogic.lua",
            "RunLogic.lua",
            "EventPresentation.lua",
            "PresentationBiomeI.lua",
            "PresentationBiomeQ.lua",
            "EventLogic.lua",
            "TraitLogic.lua",
            "ObstacleDataP.lua",
            "EncounterSets.lua",
            "NPCData.lua",
            "RoomDataDream.lua",
        ],
        mutators={
            "NarrativeData.lua": patch_dream_length_narrative,
            "RoomSets.lua": patch_dream_length_rooms,
            "DreamRunLogic.lua": patch_dream_length_logic,
            "RunHistoryLogic.lua": patch_dream_length_icons,
            "UIPresentation.lua": patch_dream_length_clear,
            "ShrineLogic.lua": patch_dream_length_shrine,
            "RoomLogic.lua": patch_dream_length_roomlogic,
            "RunLogic.lua": patch_scaling_run,
            "EventPresentation.lua": patch_scaling_event,
            "PresentationBiomeI.lua": patch_scaling_biome_i,
            "PresentationBiomeQ.lua": patch_scaling_biome_q,
            "EventLogic.lua": patch_ally_event_rarity,
            "TraitLogic.lua": patch_ally_trait_logic,
            "ObstacleDataP.lua": patch_olympus_statues,
            "EncounterSets.lua": patch_hermes_delivery,
            "NPCData.lua": patch_nemesis_halves,
        },
        needs_helpers=True,
    ),
    Patch(
        id="dream_rewards",
        title="Dream Dive: hammers & gods",
        description="3rd hammer after 4 zones, 4th later, and a 5th god from zone 5.",
        files=[
            "RequirementsData.lua",
            "LootData.lua",
            "StoreData.lua",
            "NPCData.lua",
            "RoomLogic.lua",
        ],
        mutators={
            "RequirementsData.lua": patch_rewards_requirements,
            "LootData.lua": patch_rewards_loot,
            "StoreData.lua": patch_rewards_store,
            "NPCData.lua": patch_rewards_npc,
            "RoomLogic.lua": patch_rewards_gods,
        },
    ),
    Patch(
        id="dream_shop_pacing",
        title="Dream Dive: shop pacing",
        description="Shop and Nemesis first/second half follow half the dive, not a hard 2-zone split.",
        files=["RequirementsData.lua", "DreamRunLogic.lua", "NPCData.lua"],
        mutators={
            "RequirementsData.lua": patch_shops_requirements,
            "NPCData.lua": patch_nemesis_halves,
        },
        needs_helpers=True,
    ),
    Patch(
        id="dream_scaling",
        title="Dream Dive: 5–8 scaling",
        description="Zones 5–8 keep scaling past biome 4, including ally rarity/damage (also on with 8 zones).",
        files=[
            "DreamRunLogic.lua",
            "RoomLogic.lua",
            "RunLogic.lua",
            "EventPresentation.lua",
            "PresentationBiomeI.lua",
            "PresentationBiomeQ.lua",
            "EventLogic.lua",
            "TraitLogic.lua",
            "ObstacleDataP.lua",
            "EncounterSets.lua",
        ],
        mutators={
            "RoomLogic.lua": patch_scaling_room,
            "RunLogic.lua": patch_scaling_run,
            "EventPresentation.lua": patch_scaling_event,
            "PresentationBiomeI.lua": patch_scaling_biome_i,
            "PresentationBiomeQ.lua": patch_scaling_biome_q,
            "EventLogic.lua": patch_ally_event_rarity,
            "TraitLogic.lua": patch_ally_trait_logic,
            "ObstacleDataP.lua": patch_olympus_statues,
            "EncounterSets.lua": patch_hermes_delivery,
        },
        needs_helpers=True,
    ),
    Patch(
        id="night_bloom_scale",
        title="Night Bloom: biome damage",
        description="Raised servants keep the hex multipliers, plus ally biome damage (1.22 per zone). Independent of Artemis/Icarus/Heracles.",
        files=["DreamRunLogic.lua", "RoomLogic.lua"],
        mutators={"RoomLogic.lua": patch_night_bloom_scale},
        needs_helpers=True,
    ),
    Patch(
        id="scorch_cap",
        title="Scorch cap",
        description="Raises Scorch (Burn) stack cap from 999 to 99,999.",
        files=["EffectData.lua"],
        mutators={"EffectData.lua": patch_scorch},
    ),
    Patch(
        id="support_fire",
        title="Support Fire",
        description="Arrows keep up with attack speed (cap 30) and Poms actually raise damage.",
        files=["TraitData_Artemis.lua", "PowersLogic.lua"],
        mutators={
            "TraitData_Artemis.lua": patch_support_trait,
            "PowersLogic.lua": patch_support_powers,
        },
    ),
    Patch(
        id="support_fire_scale",
        title="Support Fire: biome damage",
        description="Arrow damage +10% per biome after the first (biome 8 = +70%).",
        files=["PowersLogic.lua"],
        mutators={"PowersLogic.lua": patch_support_scale},
    ),
    Patch(
        id="pommable_boons",
        title="Pommable boons",
        description="Pom Killing Stroke, Easy Shot, Winner's Circle, and Success Rate.",
        files=["TraitData_Artemis.lua", "TraitData_Hermes.lua"],
        mutators={
            "TraitData_Artemis.lua": patch_pommable_artemis,
            "TraitData_Hermes.lua": patch_pommable_hermes,
        },
    ),
    Patch(
        id="reckless_abandon",
        title="Reckless Abandon",
        description="Even 33% rolls on 5/55/555, plus +111 per biome you picked it in.",
        files=["TraitData_Dionysus.lua", "PowersLogic.lua", "CombatLogic.lua"],
        mutators={
            "TraitData_Dionysus.lua": patch_reckless_dionysus,
            "PowersLogic.lua": patch_reckless_powers,
            "CombatLogic.lua": patch_reckless_combat,
        },
    ),
    Patch(
        id="discordant_bell",
        title="Discordant Bell",
        description="Eris keepsake grows +5% damage dealt and taken after each encounter.",
        files=["TraitData_Keepsake.lua"],
        mutators={"TraitData_Keepsake.lua": patch_discordant_bell},
    ),
    Patch(
        id="damage_meter",
        title="Damage meter",
        description="In-combat breakdown of damage by source with % of the room (Jowday-style). Independent of Dream Dive toggles.",
        files=["CombatLogic.lua", "TraitLogic.lua", "RoomLogic.lua", "HUDLogic.lua"],
        mutators={
            "CombatLogic.lua": patch_damage_meter_combat,
            "TraitLogic.lua": patch_damage_meter_trait,
            "RoomLogic.lua": patch_damage_meter_room,
        },
    ),
]

PATCH_BY_ID = {p.id: p for p in PATCHES}


def game_scripts_path() -> Path:
    return Path(os.environ.get("HADES2_SCRIPTS", DEFAULT_GAME))


def game_content_path() -> Path:
    return Path(os.environ.get("HADES2_CONTENT", DEFAULT_CONTENT))


def all_patch_files() -> list[str]:
    files: list[str] = []
    seen: set[str] = set()
    for patch in PATCHES:
        for rel in patch.files:
            if rel not in seen:
                files.append(rel)
                seen.add(rel)
    return files


def read_vanilla(rel: str) -> str:
    return (BACKUP / rel).read_text(encoding="utf-8-sig")


def hades_running() -> bool:
    result = subprocess.run(
        ["pgrep", "-x", "Hades II"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def status_payload() -> dict:
    game = game_scripts_path()
    content = game_content_path()
    return {
        "ok": True,
        "repo": str(REPO),
        "game": game.is_dir(),
        "game_path": str(game),
        "content": str(content),
        "backup": BACKUP.is_dir() and BACKUP_GAME.is_dir(),
        "backup_path": str(BACKUP.parent),
        "hades_running": hades_running(),
        "patches": [
            {"id": p.id, "title": p.title, "description": p.description}
            for p in PATCHES
        ],
    }


def build_patched_texts(enabled_ids: list[str]) -> tuple[dict[str, str], list[str], list[str]]:
    unknown = [pid for pid in enabled_ids if pid not in PATCH_BY_ID]
    if unknown:
        raise SystemExit(f"unknown patch id(s): {', '.join(unknown)}")

    enabled = [PATCH_BY_ID[pid] for pid in PATCH_BY_ID if pid in set(enabled_ids)]
    texts = {rel: read_vanilla(rel) for rel in all_patch_files()}
    log: list[str] = []

    needs_helpers = any(p.needs_helpers for p in enabled)
    if needs_helpers:
        texts["DreamRunLogic.lua"] = HELPER + texts["DreamRunLogic.lua"]
        log.append("helpers: LocalMod* in DreamRunLogic.lua")

    for patch in enabled:
        for rel, mutator in patch.mutators.items():
            texts[rel] = mutator(texts[rel])
            log.append(f"{patch.id}: {rel}")

    return texts, log, [p.id for p in enabled]


def apply_enabled(enabled_ids: list[str]) -> dict:
    game = game_scripts_path()
    if not BACKUP.is_dir():
        raise SystemExit(f"missing backup: {BACKUP}")
    if not game.is_dir():
        raise SystemExit(f"missing game Scripts: {game}")

    texts, log, enabled = build_patched_texts(enabled_ids)

    for rel, text in texts.items():
        dest = game / rel
        dest.write_text(text, encoding="utf-8")

    log.append("apply-mod: done")
    return {
        "ok": True,
        "enabled": enabled,
        "patched_files": all_patch_files(),
        "hades_running": hades_running(),
        "log": log,
    }


def restore_vanilla() -> dict:
    content = game_content_path()
    if not BACKUP.is_dir() or not BACKUP_GAME.is_dir():
        raise SystemExit(f"missing backup at {BACKUP.parent}")
    if not content.is_dir():
        raise SystemExit(f"Game Content not found: {content}")
    for name, src in (("Scripts", BACKUP), ("Game", BACKUP_GAME)):
        dest = content / name
        result = subprocess.run(
            ["rsync", "-a", "--delete", f"{src}/", f"{dest}/"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise SystemExit(result.stderr or result.stdout or f"rsync {name} failed")
    return {
        "ok": True,
        "enabled": [],
        "log": [f"Restored Scripts and Game into {content}"],
    }


def parse_enable(raw: str | None, enable_file: Path | None) -> list[str]:
    if enable_file is not None:
        data = json.loads(enable_file.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return list(data.get("enabled") or [])
        if isinstance(data, list):
            return list(data)
        raise SystemExit("enable file must be a JSON list or {\"enabled\": [...]}")
    if raw is None:
        return [p.id for p in PATCHES]
    if raw.strip() == "":
        return []
    return [part.strip() for part in raw.split(",") if part.strip()]


def main() -> None:
    parser = argparse.ArgumentParser(description="Hades II local Mac patcher")
    parser.add_argument("--enable", help="Comma-separated patch ids. Empty string applies none.")
    parser.add_argument("--enable-file", type=Path, help="JSON file with enabled patch ids")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument("--restore", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        if args.status or args.list:
            payload = status_payload()
            if args.json or args.status:
                print(json.dumps(payload, indent=2 if not args.json else None))
            else:
                for patch in PATCHES:
                    print(f"{patch.id}\t{patch.title}\t{patch.description}")
            return

        if args.restore:
            payload = restore_vanilla()
        else:
            enabled_ids = parse_enable(args.enable, args.enable_file)
            payload = apply_enabled(enabled_ids)

        if args.json:
            print(json.dumps(payload))
        else:
            for line in payload.get("log", []):
                print(line)
    except SystemExit as exc:
        if isinstance(exc.code, int):
            raise
        message = str(exc)
        if args.json:
            print(json.dumps({"ok": False, "error": message}))
            raise SystemExit(1) from None
        print(message, file=sys.stderr)
        raise SystemExit(1) from None


if __name__ == "__main__":
    main()
