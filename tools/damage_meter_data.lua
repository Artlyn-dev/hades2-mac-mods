-- Local Mac port of JowdayDamageMeter lookup tables (MIT, Jen Guerra).
-- No ModUtil / game. prefix. Color tables are numeric so this file can
-- load before ColorData.lua.

LocalModMeterOmegaIndicator = "{!Icons.Omega_NoTooltip}"
LocalModMeterNameLookup = {}
LocalModMeterSourceLookup = {}

LocalModMeterAttackEXLookup = {
	"WeaponStaffSwing5", "WeaponDagger5", "WeaponAxeSpin", "ProjectileTorchBallLarge", "ProjectileLobCharged",
	"ProjectileSuitCharged", "ProjectileLobOverheat", "ProjectileTorchWave", "ProjectileTorchGhostLarge",
	"ProjectileTorchRepeatStrike", "ProjectileTorchSupayBallEx"
}

LocalModMeterSpecialEXLookup = {
	"ProjectileStaffBallCharged", "WeaponAxeSpecialSwing", "ProjectileTorchOrbitEx", "ProjectileThrowCharged",
	"ProjectileDaggerThrowCharged", "ProjectileSuitBomb", "ProjectileSuitRangedCharged"
}

LocalModMeterCastEXLookup = {
	"^ProjectileCast$"
}

LocalModMeterDashStrikeLookup = {
	"ProjectileDaggerDash", "ProjectileStaffDash", "ProjectileAxeDash"
}

LocalModMeterHitchDamageLookup = { "ManaRestoreBlast", "HeraSprintProjectile" }

LocalModMeterDpsColors = {
	Aphrodite = { BarColor = { 255, 126, 241, 255 }, Icons = { "Aphrodite" } },
	Apollo = { BarColor = { 246, 197, 25, 255 }, Icons = { "Apollo" } },
	Ares = { BarColor = { 180, 30, 0, 255 }, Icons = { "Ares" } },
	Artemis = { BarColor = { 111, 209, 45, 255 }, Icons = { "Artemis" } },
	ArtemisAssist = { BarColor = { 199, 255, 27, 255 }, LabelColor = { 199, 255, 27, 255 }, Icons = { "Artemis" } },
	Athena = { BarColor = { 246, 197, 25, 255 }, Icons = { "Athena" } },
	Demeter = { BarColor = { 111, 120, 189, 255 }, Icons = { "Demeter" } },
	Dionysus = { BarColor = { 129, 82, 200, 255 }, Icons = { "Dionysus" } },
	Hades = { BarColor = { 242, 79, 66, 255 }, Icons = { "Hades" } },
	Hera = { BarColor = { 70, 177, 240, 255 }, Icons = { "Hera" } },
	Hestia = { BarColor = { 250, 182, 97, 255 }, Icons = { "Hestia" } },
	Hephaestus = { BarColor = { 255, 200, 40, 255 }, Icons = { "Hephaestus" } },
	MedeaBoon = { BarColor = { 122, 198, 113, 255 } },
	Poseidon = { BarColor = { 0, 138, 255, 255 }, Icons = { "Poseidon" } },
	Selene = { BarColor = { 100, 149, 237, 255 }, Icons = { "Selene" } },
	Zeus = { BarColor = { 255, 250, 165, 255 }, Icons = { "Zeus" } },
	DuoAphroditeHestia = { BarColor = { 210, 255, 97, 255 }, Icons = { "Aphrodite", "Hestia" } },
	DuoApolloDemeter = { BarColor = { 210, 255, 97, 255 }, Icons = { "Apollo", "Demeter" } },
	DuoApolloPosedidon = { BarColor = { 210, 255, 97, 255 }, Icons = { "Apollo", "Poseidon" } },
	DuoApolloZeus = { BarColor = { 210, 255, 97, 255 }, Icons = { "Apollo", "Zeus" } },
	DuoHephaestusPoseidon = { BarColor = { 210, 255, 97, 255 }, Icons = { "Hephaestus", "Poseidon" } },
	DuoHestiaDemeter = { BarColor = { 210, 255, 97, 255 }, Icons = { "Hestia", "Demeter" } },
	DuoHestiaPoseidon = { BarColor = { 210, 255, 97, 255 }, Icons = { "Hestia", "Poseidon" } },
	DuoHeraHestia = { BarColor = { 210, 255, 97, 255 }, Icons = { "Hestia", "Hera" } },
	DuoDemeterZeus = { BarColor = { 210, 255, 97, 255 }, Icons = { "Zeus", "Demeter" } },
	DuoSeleneAres = { BarColor = { 210, 255, 97, 255 }, Icons = { "Ares", "Selene" } },
	DuoSeleneDemeter = { BarColor = { 210, 255, 97, 255 }, Icons = { "Demeter", "Selene" } },
	DuoSeleneHephaestus = { BarColor = { 210, 255, 97, 255 }, Icons = { "Hephaestus", "Selene" } },
	DuoSeleneZeus = { BarColor = { 210, 255, 97, 255 }, Icons = { "Zeus", "Selene" } },
	NemesisAssist = { BarColor = { 115, 146, 210, 255 }, LabelColor = { 115, 146, 210, 255 } },
	HeraclesAssist = { BarColor = { 255, 125, 25, 255 }, LabelColor = { 255, 125, 25, 255 } },
	IcarusBoon = { BarColor = { 243, 215, 116, 255 } },
	IcarusAssist = { BarColor = { 243, 215, 116, 255 }, LabelColor = { 243, 215, 116, 255 } },
	OdysseusKeepsake = { BarColor = { 130, 178, 180, 255 }, LabelColor = { 130, 178, 180, 255 } },
	Shade = { BarColor = { 51, 222, 160, 255 }, LabelColor = { 51, 222, 160, 255 } },
	Frinos = { BarColor = { 143, 229, 131, 255 }, LabelColor = { 143, 229, 131, 255 } },
	Toula = { BarColor = { 255, 240, 100, 255 }, LabelColor = { 255, 240, 100, 255 } },
	Raven = { BarColor = { 150, 90, 170, 255 }, LabelColor = { 150, 90, 170, 255 } },
	Gale = { BarColor = { 160, 120, 80, 255 }, LabelColor = { 160, 120, 80, 255 } },
	Default = { BarColor = { 195, 175, 175, 255 } },
}

-- Vanilla animation names (no Jowday icon pack).
LocalModMeterIcons = {
	Aphrodite = { Name = "BoonInfoSymbolAphroditeIcon", Scale = 0.22 },
	Apollo = { Name = "BoonInfoSymbolApolloIcon", Scale = 0.22 },
	Ares = { Name = "BoonInfoSymbolAresIcon", Scale = 0.22 },
	Artemis = { Name = "BoonSymbolArtemis", Scale = 0.18 },
	Athena = { Name = "BoonSymbolAthena", Scale = 0.18 },
	Demeter = { Name = "BoonInfoSymbolDemeterIcon", Scale = 0.22 },
	Dionysus = { Name = "BoonSymbolDionysus", Scale = 0.18 },
	Hades = { Name = "BoonSymbolHades", Scale = 0.18 },
	Hera = { Name = "BoonInfoSymbolHeraIcon", Scale = 0.22 },
	Hestia = { Name = "BoonInfoSymbolHestiaIcon", Scale = 0.22 },
	Hephaestus = { Name = "BoonInfoSymbolHephaestusIcon", Scale = 0.22 },
	Poseidon = { Name = "BoonInfoSymbolPoseidonIcon", Scale = 0.22 },
	Selene = { Name = "SpellDropPreview", Scale = 0.18 },
	Zeus = { Name = "BoonInfoSymbolZeusIcon", Scale = 0.22 },
	Hermes = { Name = "BoonInfoSymbolHermesIcon", Scale = 0.22 },
	Chaos = { Name = "BoonInfoSymbolChaosIcon", Scale = 0.22 },
}

function LocalModMeterGetLocalizedNames()
	local omegaPrefix = LocalModMeterOmegaIndicator
	local oAttackText = omegaPrefix .. GetDisplayName({ Text = "Attack" })
	local oSpecialText = omegaPrefix .. GetDisplayName({ Text = "Special" })
	local oCastText = omegaPrefix .. GetDisplayName({ Text = "Cast" })
	local aphOAttack = omegaPrefix .. GetDisplayName({ Text = "AphroditeWeaponBoon" })
	local aphOSpecial = omegaPrefix .. GetDisplayName({ Text = "AphroditeSpecialBoon" })
	local aphOCast = omegaPrefix .. GetDisplayName({ Text = "AphroditeCastBoon" })
	local apoOAttack = omegaPrefix .. GetDisplayName({ Text = "ApolloWeaponBoon" })
	local apoOSpecial = omegaPrefix .. GetDisplayName({ Text = "ApolloSpecialBoon" })
	local apoOCast = omegaPrefix .. GetDisplayName({ Text = "ApolloCastBoon" })
	local apoOCastEx = omegaPrefix .. GetDisplayName({ Text = "ApolloExCastBoon" })
	local areOAttack = omegaPrefix .. GetDisplayName({ Text = "AresWeaponBoon" })
	local areOSpecial = omegaPrefix .. GetDisplayName({ Text = "AresSpecialBoon" })
	local areOCast = omegaPrefix .. GetDisplayName({ Text = "AresCastBoon" })
	local demOAttack = omegaPrefix .. GetDisplayName({ Text = "DemeterWeaponBoon" })
	local demOSpecial = omegaPrefix .. GetDisplayName({ Text = "DemeterSpecialBoon" })
	local demOCast = omegaPrefix .. GetDisplayName({ Text = "DemeterCastBoon" })
	local herOAttack = omegaPrefix .. GetDisplayName({ Text = "HeraWeaponBoon" })
	local herOSpecial = omegaPrefix .. GetDisplayName({ Text = "HeraSpecialBoon" })
	local herOCast = omegaPrefix .. GetDisplayName({ Text = "HeraCastBoon" })
	local hesOAttack = omegaPrefix .. GetDisplayName({ Text = "HestiaWeaponBoon" })
	local hesOSpecial = omegaPrefix .. GetDisplayName({ Text = "HestiaSpecialBoon" })
	local hesOCast = omegaPrefix .. GetDisplayName({ Text = "HestiaCastBoon" })
	local hepOAttack = omegaPrefix .. GetDisplayName({ Text = "HephaestusWeaponBoon" })
	local hepOSpecial = omegaPrefix .. GetDisplayName({ Text = "HephaestusSpecialBoon" })
	local hepOCast = omegaPrefix .. GetDisplayName({ Text = "HephaestusCastBoon" })
	local posOAttack = omegaPrefix .. GetDisplayName({ Text = "PoseidonWeaponBoon" })
	local posOSpecial = omegaPrefix .. GetDisplayName({ Text = "PoseidonSpecialBoon" })
	local posOCast = omegaPrefix .. GetDisplayName({ Text = "PoseidonCastBoon" })
	local zeuOAttack = omegaPrefix .. GetDisplayName({ Text = "ZeusWeaponBoon" })
	local zeuOSpecial = omegaPrefix .. GetDisplayName({ Text = "ZeusSpecialBoon" })
	local zeuOCast = omegaPrefix .. GetDisplayName({ Text = "ZeusCastBoon" })
	local spellTransformTrait = GetDisplayName({ Text = "SpellTransformTrait" })
	local darkSideAttack = spellTransformTrait .. " (" .. GetDisplayName({ Text = "Attack" }) .. ")"
	local darkSideSpecial = spellTransformTrait .. " (" .. GetDisplayName({ Text = "Special" }) .. ")"
	local artOAttack = omegaPrefix .. GetDisplayName({ Text = "ArtemisWeaponBoon" })
	local artOSpecial = omegaPrefix .. GetDisplayName({ Text = "ArtemisSpecialBoon" })
	local circePoly = "(" .. GetDisplayName({ Text = "NPC_Circe_01" }) .. ") " .. GetDisplayName({ Text = "Polymorph" })

	LocalModMeterNameLookup = {
		WeaponMorphedAttack = "Sheep Attack",
		FrogFamiliarLand = "Frinos",
		CatFamiliarPounce = "Toula",
		RavenFamiliarMelee = "RavenFamiliar",
		RavenFamiliarMelee_Crit = "RavenFamiliar",
		PolecatFamiliarMelee = "DodgeFamiliar",
		FamiliarLinkLaser = "FamiliarBuff",
		PolyphemusBoulderSky = "Polyphemus Boulder",
		FireBarrelExplosion = "Traps",
		FireBarrelFireLob = "Traps",
		SteamWallBlast = "Traps",
		SteamTrapFast = "Traps",
		SteamTrap = "Traps",
		SteamCubeExplosion = "Traps",
		OilPuddleFire = "Traps",
		OilPuddleFire02 = "Traps",
		OilPuddleFire03 = "Traps",
		OilPuddleFire04 = "Traps",
		DestructibleTreeSplinter = "Traps",
		BrambleTrap = "Traps",
		ThornTreeThorn = "Traps",
		FieldsDestructiblePillarDestruction = "Traps",
		BlastCubeExplosion = "Traps",
		SpikeTrapWeapon = "Traps",
		LavaTileWeapon = "Traps",
		BaseCollision = "Traps",
		BeamTrap = "Traps",
		RubbleFall = "Traps",
		RubbleFallOlympus = "Traps",
		IcicleSplinter = "Traps",
		BrambleTrapBush = "Traps",
		DestructibleMastSplinter = "Traps",
		GunBombImmolation = "Traps",
		LavaTile = "Traps",
		LavaTileTriangle01 = "Traps",
		LavaTileTriangle02 = "Traps",
		LavaTileTriangle01Weapon = "Traps",
		LavaTileTriangle02Weapon = "Traps",
		PolyphemusBoulders = "Traps",
		BloodMinePreFused = "Traps",
		TyphonSpike = "Traps",
		TyphonSpikeSplinter = "Traps",
		TyphonEggExplosion = "Traps",
		TyphonEgg = "Traps",
		TyphonEggLarge = "Traps",
		TyphonMine = "Traps",
		HestiaStatueFireball = "Traps",
		HestiaStatueFireRing = "Traps",
		DemeterStatueFrostStorm = "Traps",
		PoseidonStatueWave = "Traps",
		ZeusStatueChasingStorm = "Traps",
		OAttackText = oAttackText,
		OSpecialText = oSpecialText,
		OCastText = oCastText,
		WeaponDagger = "Attack",
		WeaponDaggerThrow = "Special",
		WeaponBlink = "Dash",
		WomboStrike = "TripleAspectStrike",
		WeaponStaffSwing = "Attack",
		WeaponStaffBall = "Special",
		WeaponTorch = "Attack",
		WeaponTorchSpecial = "Special",
		WeaponAxe = "Attack",
		WeaponAxeSpecialSwing = "Special",
		WeaponAxeSpin = "Attack",
		WeaponAxeBlock2 = "Special",
		WeaponAxeSpecial = "Special",
		HammerAxeNova = "AxeRangedWhirlwindTrait",
		WeaponLob = "Attack",
		WeaponLobSpecial = "Special",
		WeaponLobPulse = "Attack",
		WeaponSuit = "Attack",
		WeaponSuitRanged = "Special",
		WeaponSprintEx = "NyxSprint",
		ArtemisSniperBolt = "Artemis",
		ArtemisVolleyShot = "Artemis",
		NemesisSpecial = "Nemesis",
		NemesisAttack1 = "Nemesis",
		NemesisAttack2 = "Nemesis",
		NemesisAttack3 = "Nemesis",
		NemesisDash = "Nemesis",
		HeraclesLeap = "Heracles",
		HeraclesArcRight = "Heracles",
		IcarusBombardment = "Icarus",
		IcarusBombardment_Large = "Icarus",
		LamiaMiasma = "Enemy",
		LamiaSkyCast_Miniboss = "Enemy",
		MournerRampage = "Enemy",
		LycanSwarmerChomp = "Enemy",
		CorruptedShadeMRam = "Enemy",
		LycanthropeLeapKnockback = "Enemy",
		InfestedCerberusSwipe = "Enemy",
		SatyrLanceThrow = "Enemy",
		MageRanged = "Enemy",
		GuardMelee = "Enemy",
		PolyphemusStomachAche = "Enemy",
		MorphDamageProjectile = circePoly,
		HeraCastDamageProjectile = "WeaponCast",
		DemeterSprintStorm = "Dash",
		HephSprintBlast = "Dash",
		PoseidonSprintBlast = "Dash",
		PoseidonSprintSecondaryBlast = "Dash",
		ZeusSprintStrike = "Dash",
		PoseidonCastSplashSplinter = "WeaponCast",
		AphroditeCastProjectile = "WeaponCast",
		ProjectileSpellMiniMeteor = "WeaponSpellMeteor",
	}

	LocalModMeterSourceLookup = {
		Aphrodite = {
			["Attack"] = "AphroditeWeaponBoon",
			["OAttack"] = aphOAttack,
			["Special"] = "AphroditeSpecialBoon",
			["OSpecial"] = aphOSpecial,
			["OCast"] = aphOCast,
			["AphroditeRushProjectile"] = "AphroditeSprintBoon",
			["WeaponCast"] = "AphroditeCastBoon",
			["AphroditeBurst"] = "ManaBurstBoon",
		},
		Apollo = {
			["Attack"] = "ApolloWeaponBoon",
			["OAttack"] = apoOAttack,
			["Special"] = "ApolloSpecialBoon",
			["OSpecial"] = apoOSpecial,
			["OCast"] = apoOCast,
			["Dash"] = "ApolloSprintBoon",
			["ApolloCast"] = apoOCastEx,
			["ApolloSingleCastStrike"] = "ApolloCastBoon",
			["WeaponCast"] = apoOCast,
			["ApolloRetaliateStrike"] = "ApolloRetaliateBoon",
			["ApolloPerfectDashStrike"] = "ApolloMissStrikeBoon",
			["ApolloCastRapid"] = "ApolloExCastBoon",
		},
		Ares = {
			["Attack"] = "AresWeaponBoon",
			["OAttack"] = areOAttack,
			["Special"] = "AresSpecialBoon",
			["OSpecial"] = areOSpecial,
			["OCast"] = areOCast,
			["Dash"] = "AresSprintBoon",
			["ProjectileAresSwordEx"] = "OmegaDelayedDamageBoon",
			["ProjectileAresSwordWake"] = "AresSprintBoon",
			["ProjectileAresSwordCast"] = "AresCastBoon",
			["WeaponCast"] = areOCast,
			["OCastAres"] = "BladeRift",
		},
		Artemis = {
			["ArtemisSupportingFire"] = "SupportingFireBoon",
			["ArtemisCastVolley"] = "OmegaCastVolleyBoon",
			["ArtemisSupportingFireSprint"] = "ArtemisSprintBoon",
			["Attack"] = "ArtemisWeaponBoon",
			["OAttack"] = artOAttack,
			["Special"] = "ArtemisSpecialBoon",
			["OSpecial"] = artOSpecial,
		},
		Athena = {
			["AthenaDeflectingProjectile"] = "AthenaProjectileBoon",
			["AthenaCastProjectile"] = "InvulnerabilityCastBoon",
			["AthenaRushProjectile"] = "InvulnerabilityDashBoon",
			["ProjectileAthenaManaSpear"] = "ManaSpearBoon",
		},
		Demeter = {
			["Attack"] = "DemeterWeaponBoon",
			["OAttack"] = demOAttack,
			["Special"] = "DemeterSpecialBoon",
			["OSpecial"] = demOSpecial,
			["OCast"] = demOCast,
			["Dash"] = "DemeterSprintBoon",
			["WeaponCast"] = "DemeterCastBoon",
			["DemeterChillKill"] = "InstantRootKill",
			["DemeterCastStorm"] = "CastNovaBoon",
			["DemeterCastBlast"] = "DemeterCastBoon",
		},
		Dionysus = {
			["DamageOverTime"] = "DamageOverTime",
			["WeaponCastLob"] = "CastLobBoon",
		},
		Hades = {
			["WeaponCastProjectileHades"] = "HadesCastProjectileBoon",
			["OldGrudge"] = "HadesPreDamageBoon",
			["HadesUrnDeath"] = "HadesManaUrnBoon",
			["SpearWeaponSpin"] = "HadesDashSweepBoon",
		},
		Hera = {
			["Attack"] = "HeraWeaponBoon",
			["OAttack"] = herOAttack,
			["Special"] = "HeraSpecialBoon",
			["OSpecial"] = herOSpecial,
			["OCast"] = herOCast,
			["WeaponCast"] = "HeraCastBoon",
			["HeraDamageShareProjectile"] = "DamageShareRetaliateBoon",
			["DamageShareEffect"] = "Link",
			["DamageShareDeath"] = "LinkedDeathDamageBoon",
			["ProjectileHeraOmega"] = "OmegaHeraProjectileBoon",
			["LinkNova"] = "SpawnCastDamageBoon",
			["HeraSprintProjectile"] = "HeraSprintBoon",
			["HeraCastSummonProjectile"] = "SpawnCastDamageBoon",
		},
		Hestia = {
			["Attack"] = "HestiaWeaponBoon",
			["OAttack"] = hesOAttack,
			["Special"] = "HestiaSpecialBoon",
			["OSpecial"] = hesOSpecial,
			["OCast"] = hesOCast,
			["Dash"] = "HestiaSprintBoon",
			["WeaponCast"] = "HestiaCastBoon",
			["BurnNova"] = "BurnExplodeBoon",
			["BurnEffect"] = "Burn",
			["ProjectileFireball"] = "FireballManaSpecialBoon",
			["WeaponCastProjectile"] = "CastProjectileBoon",
			["HestiaSprintPuddle"] = "HestiaSprintBoon",
			["Burn"] = "Burn",
		},
		Hephaestus = {
			["Attack"] = "HephaestusWeaponBoon",
			["OAttack"] = hepOAttack,
			["Special"] = "HephaestusSpecialBoon",
			["OSpecial"] = hepOSpecial,
			["OCast"] = hepOCast,
			["HephCastBlast"] = "HephaestusCastBoon",
			["WeaponCast"] = hepOCast,
			["Dash"] = "HephaestusSprintBoon",
			["MassiveSlamBlast"] = "MassiveSlam_Name",
			["DelayedKnockbackEffect"] = "MassiveKnockupBoon",
		},
		IcarusBoon = {
			["IcarusExplosion"] = "OmegaExplodeBoon",
			["IcarusHazardExplosion"] = "CastHazardBoon",
			["IcarusArmorExplosion"] = "BreakExplosiveArmorBoon",
		},
		MedeaBoon = {
			["MedeaCurse"] = "SpawnDamageCurse",
			["SpawnDamageCurse"] = "SpawnDamageCurse",
			["DeathDefianceRetaliateCurse"] = "DeathDefianceRetaliateCurse",
			["ArmorPenaltyCurse"] = "ArmorPenaltyCurse",
			["MedeaStatusStrike"] = "NewStatusDamage",
		},
		OdysseusKeepsake = {
			["KnuckleBones"] = "BossPreDamageKeepsake",
		},
		Poseidon = {
			["Attack"] = "PoseidonWeaponBoon",
			["OAttack"] = posOAttack,
			["Special"] = "PoseidonSpecialBoon",
			["OSpecial"] = posOSpecial,
			["OCast"] = posOCast,
			["Dash"] = "PoseidonSprintBoon",
			["WeaponCast"] = "PoseidonCastBoon",
			["PoseidonSplashSplinter"] = "PoseidonSplash_Name",
			["PoseidonCollisionBlast"] = "SlamExplosionBoon",
			["PoseidonOmegaProjectile"] = posOCast,
			["PoseidonEffectFont"] = "KnockbackAmplify",
			["PoseidonOmegaWave"] = "OmegaPoseidonProjectileBoon",
		},
		Selene = {
			["WeaponSpellLaser"] = "SpellLaserTrait",
			["WeaponSpellLeap"] = "SpellLeapTrait",
			["WeaponSpellMeteor"] = "SpellMeteorTrait",
			["WeaponTransformAttack"] = darkSideAttack,
			["WeaponTransformSpecial"] = darkSideSpecial,
			["WeaponSpellMoonBeam"] = "SpellMoonBeamTrait",
			["WeaponSpellPolymorph"] = "Polymorph",
			["PolymorphNova"] = "PolymorphDeathExplodeTalent",
		},
		Zeus = {
			["Attack"] = "ZeusWeaponBoon",
			["OAttack"] = zeuOAttack,
			["Special"] = "ZeusSpecialBoon",
			["OSpecial"] = zeuOSpecial,
			["OCast"] = zeuOCast,
			["Dash"] = "ZeusSprintBoon",
			["WeaponCast"] = "ZeusCastBoon",
			["ZeusEchoStrike"] = "Echo",
			["ProjectileZeusSpark"] = "FocusLightningBoon",
			["ZeusZeroManaStrike"] = "ZeusManaBoltBoon",
			["ZeusRetaliateStrike"] = "BoltRetaliateBoon",
			["WeaponAnywhereCast"] = "CastAnywhereBoon",
			["ZeusOnSpawn"] = "SpawnKillBoon",
		},
		DuoAphroditeHestia = {
			["ShadeMercFireball"] = "ShadeMercFireballBoon",
		},
		DuoApolloDemeter = {
			["DemeterMiniStorm"] = "StormSpawnBoon",
		},
		DuoApolloPosedidon = {
			["ProjectileSprintBall"] = "PoseidonSplashSprintBoon",
		},
		DuoApolloZeus = {
			["ZeusApolloSynergyStrike"] = "ApolloSecondStageCastBoon",
		},
		DuoHephaestusPoseidon = {
			["MassiveSlamBlastCast"] = "MassiveCastBoon",
		},
		DuoHestiaDemeter = {
			["HestiaBurnConsumeStrike"] = "BurnConsumeBoon",
		},
		DuoHestiaPoseidon = {
			["SteamBlast"] = "SteamBoon",
		},
		DuoHeraHestia = {
			["ManaRestoreBlast"] = "ManaRestoreDamageBoon",
		},
		DuoDemeterZeus = {
			["ZeusRootStrike"] = "RootStrikeBoon",
		},
		DuoSeleneAres = {
			["ProjectileBloodMoonBeam"] = "MoonBeamAresTalent",
		},
		DuoSeleneDemeter = {
			["DemeterTickEffect"] = "TimeSlowDemeterTalent",
		},
		DuoSeleneHephaestus = {
			["HephLeapBlast"] = "LeapHephaestusTalent",
		},
		DuoSeleneZeus = {
			["ZeusPolymorphStrike"] = "PolymorphZeusTalent",
		},
	}
end
