-- In-combat damage meter for native Mac Hades II.
-- Adapted from JowdayDamageMeter (MIT, Jen Guerra): source mapping, room reset,
-- and overlay layout. Engine calls are vanilla (no ModUtil / game. prefix).

LocalModMeterConfig = {
	PollingInterval = 0.2,
	TrainingRoomClearTime = 5,
	XPosition = 280,
	InitialY = 840,
	YPositionIncrement = -20,
	Margin = 40,
	DisplayWidth = 400,
	MaxRows = 12,
	BackgroundColor = { 0.09, 0.055, 0.157, 0.6 },
	SplitDashStrike = true,
	SplitOmega = true,
	MaxHistory = 10000,
	Group = "HUD_Overlay",
	-- leftover rectangle01 is a large tile; these fractions make a thin bar
	BarNativeWidth = 480,
	BarMaxWidth = 220,
	BarScaleY = 0.045,
}

LocalModMeterHistory = { first = 0, last = -1, count = 0 }
LocalModMeterWeaponVar = {}
LocalModMeterCurrentGods = {}
LocalModMeterPolling = false
LocalModMeterFrozen = false
LocalModMeterUIIds = {}
LocalModMeterNamesReady = false

LocalModMeterBarPalette = {
	{ 1.00, 0.49, 0.95, 1 },
	{ 0.00, 0.85, 1.00, 1 },
	{ 1.00, 0.98, 0.18, 1 },
	{ 0.44, 0.82, 0.18, 1 },
	{ 0.80, 0.53, 1.00, 1 },
	{ 1.00, 0.65, 0.26, 1 },
	{ 0.27, 0.69, 0.94, 1 },
	{ 0.82, 1.00, 0.38, 1 },
	{ 1.00, 0.35, 0.35, 1 },
	{ 0.95, 0.85, 0.45, 1 },
	{ 0.40, 0.90, 0.70, 1 },
	{ 0.70, 0.55, 0.30, 1 },
}

local LocalModMeterPlayerUnits = {
	["_PlayerUnit"] = true,
	["CatFamiliar"] = true,
	["FrogFamiliar"] = true,
	["PolecatFamiliar"] = true,
	["RavenFamiliar"] = true,
}

local function meterListAdd(list, value)
	local last = list.last + 1
	list.last = last
	list[last] = value
	list.count = list.count + 1
	if list.count > LocalModMeterConfig.MaxHistory then
		local first = list.first
		list[first] = nil
		list.first = first + 1
		list.count = list.count - 1
	end
end

local function meterListEmpty(list)
	for i = list.first, list.last do
		list[i] = nil
	end
	list.first = 0
	list.last = -1
	list.count = 0
end

local function meterHashColor(source)
	local h = 0
	local s = tostring(source or "")
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	local palette = LocalModMeterBarPalette
	return palette[(h % #palette) + 1]
end

local function meterTint(id, color)
	if id == nil or color == nil then
		return
	end
	SetColor({ Id = id, Color = color })
	if SetRGB ~= nil then
		SetRGB({ Id = id, Color = color })
	end
end

local function meterEnsureNames()
	if LocalModMeterNamesReady then
		return
	end
	if GetDisplayName == nil then
		return
	end
	LocalModMeterGetLocalizedNames()
	LocalModMeterNamesReady = true
end

local function meterGodMatcher(name)
	if name == nil then
		return
	end
	if name:match("Apollo") then return "Apollo" end
	if name:match("Aphrodite") then return "Aphrodite" end
	if name:match("Ares") then return "Ares" end
	if name:match("Artemis") then return "Artemis" end
	if name:match("Athena") then return "Athena" end
	if name:match("Demeter") then return "Demeter" end
	if name:match("Dionysus") then return "Dionysus" end
	if name:match("Hera") then return "Hera" end
	if name:match("Hephaestus") then return "Hephaestus" end
	if name:match("Hestia") then return "Hestia" end
	if name:match("Poseidon") then return "Poseidon" end
	if name:match("Selene") then return "Selene" end
	if name:match("Zeus") then return "Zeus" end
	if name:match("Hades") then return "Hades" end
end

local function meterClearWeaponInfo()
	if LocalModMeterNameLookup ~= nil then
		LocalModMeterNameLookup["RangedWeapon"] = "Cast"
	end
	LocalModMeterWeaponVar["Attack"] = nil
	LocalModMeterWeaponVar["Special"] = nil
	LocalModMeterWeaponVar["Cast"] = nil
	LocalModMeterWeaponVar["Dash"] = nil
	LocalModMeterWeaponVar["KnuckleBones"] = nil
	LocalModMeterWeaponVar["OldGrudge"] = nil
	LocalModMeterWeaponVar["BossPreDamage"] = nil
	LocalModMeterCurrentGods = {}
end

local function meterGetEquippedBoons(trait)
	local slot = trait.Slot or ""
	local name = trait.Name or ""
	local god = meterGodMatcher(name)

	if slot == "Melee" and god then
		LocalModMeterWeaponVar["Attack"] = god
	end
	if slot == "Secondary" and god then
		LocalModMeterWeaponVar["Special"] = god
	end
	if slot == "Ranged" and name then
		if god ~= nil then
			LocalModMeterWeaponVar["Cast"] = god
		end
		LocalModMeterNameLookup["RangedWeapon"] = name
	end
	if slot == "Rush" and name then
		if god ~= nil then
			LocalModMeterWeaponVar["Dash"] = god
		end
	end
	if god ~= nil then
		LocalModMeterCurrentGods[god] = true
	end
	if name == "BossPreDamageKeepsake" and trait.Uses ~= nil and trait.Uses > 0 then
		LocalModMeterWeaponVar["KnuckleBones"] = trait.ReportedDamage
	end
	if name == "HadesPreDamageBoon" and trait.Uses ~= nil and trait.Uses > 0 then
		LocalModMeterWeaponVar["OldGrudge"] = trait.ReportedDamage
	end
	if LocalModMeterWeaponVar["KnuckleBones"] ~= nil or LocalModMeterWeaponVar["OldGrudge"] ~= nil then
		LocalModMeterWeaponVar["BossPreDamage"] = true
	end
end

function LocalModMeterRefreshBoons()
	meterEnsureNames()
	meterClearWeaponInfo()
	if CurrentRun == nil or CurrentRun.Hero == nil or CurrentRun.Hero.Traits == nil then
		return
	end
	for _, trait in pairs(CurrentRun.Hero.Traits) do
		meterGetEquippedBoons(trait)
	end
end

local function meterLookupContains(lookup, weapon, projectile)
	if lookup == nil then
		return false
	end
	for _, pattern in pairs(lookup) do
		if weapon ~= nil and weapon:match(pattern) then
			return true
		end
		if projectile ~= nil and projectile:match(pattern) then
			return true
		end
	end
	return false
end

local function meterGetSourceName(triggerArgs, victim)
	local attackerWeaponData = triggerArgs.AttackerWeaponData or {}
	local attackerTable = triggerArgs.AttackerTable or {}
	local activeEffects = attackerTable.ActiveEffects or {}
	local activeEffectsStart = attackerTable.ActiveEffectsAtDamageStart or {}
	local source = "Unknown"
	source = triggerArgs.WeaponName or source
	source = triggerArgs.EffectName or source
	source = triggerArgs.SourceProjectile or source
	if source ~= "ApolloCast" then
		source = triggerArgs.SourceWeapon or source
		source = attackerWeaponData.LinkedUpgrades or source
	end

	if triggerArgs.SourceProjectile == "AthenaRushProjectile" then
		source = "AthenaRushProjectile"
	end

	if LocalModMeterConfig.SplitDashStrike then
		local sourceProjectile = triggerArgs.SourceProjectile
		if sourceProjectile ~= nil and meterLookupContains(LocalModMeterDashStrikeLookup, nil, sourceProjectile) then
			source = "AttackDashStrike"
		end
	end

	if source == "AresProjectile" then
		source = "OCastAres"
	end

	if LocalModMeterConfig.SplitOmega then
		local sourceProjectile = triggerArgs.SourceProjectile
		local sourceWeapon = triggerArgs.SourceWeapon
		if meterLookupContains(LocalModMeterAttackEXLookup, sourceWeapon, sourceProjectile) then
			source = "OAttack"
		elseif meterLookupContains(LocalModMeterSpecialEXLookup, sourceWeapon, sourceProjectile) then
			source = "OSpecial"
		end
		if sourceProjectile ~= nil and meterLookupContains(LocalModMeterCastEXLookup, nil, sourceProjectile) then
			source = "OCast"
		end
	end

	if triggerArgs.SourceProjectile == "ZeusApolloSynergyStrike" then
		source = "ZeusApolloSynergyStrike"
	end

	source = LocalModMeterNameLookup[source] or source

	local isCharmed = attackerTable.Charmed or activeEffects["Charm"] == 1 or activeEffectsStart["Charm"] == 1
	if isCharmed then
		source = "Charm"
	end

	if triggerArgs.ProjectileDeflected then
		source = "ParryHit"
	end

	if source == "MedeaCurse" then
		source = triggerArgs.CurseName or "MedeaCurse"
	end

	if source == "Unknown" then
		if LocalModMeterWeaponVar["BossPreDamage"] ~= nil and triggerArgs.Silent and victim ~= nil and victim.IsBoss == true then
			if triggerArgs.PreDamageBossFunctionName == "HadesPreDamagePresentation" then
				source = "OldGrudge"
				LocalModMeterWeaponVar["OldGrudge"] = nil
			end
			if LocalModMeterWeaponVar["KnuckleBones"] ~= nil and triggerArgs.PreDamageBossFunctionName == "PreDamagePresentation" then
				source = "KnuckleBones"
				LocalModMeterWeaponVar["KnuckleBones"] = nil
			end
		end
	end

	return source
end

local function meterCanHitchDamage(source)
	if source == nil then
		return false
	end
	if (source == "Attack" or source == "OAttack") and LocalModMeterWeaponVar["Attack"] == "Hera" then
		return true
	end
	if (source == "Special" or source == "OSpecial") and LocalModMeterWeaponVar["Special"] == "Hera" then
		return true
	end
	if source == "Dash" and LocalModMeterWeaponVar["Dash"] == "Hera" then
		return true
	end
	if source == "Cast" and LocalModMeterWeaponVar["Cast"] == "Hera" then
		return true
	end
	for _, hitchSource in ipairs(LocalModMeterHitchDamageLookup or {}) do
		if hitchSource == source then
			return true
		end
	end
	return false
end

local function meterLog(source, preHitHealth, rawDamage)
	local amount = math.min(preHitHealth or 0, rawDamage or 0)
	if amount <= 0 then
		return
	end
	meterListAdd(LocalModMeterHistory, { Source = source, Damage = amount, Timestamp = GetTime({}) })
end

local function meterCollectIds(ids)
	if LocalModMeterUIIds == nil then
		LocalModMeterUIIds = {}
	end
	if type(ids) == "table" then
		for _, id in ipairs(ids) do
			if id ~= nil then
				table.insert(LocalModMeterUIIds, id)
			end
		end
	elseif ids ~= nil then
		table.insert(LocalModMeterUIIds, ids)
	end
end

function LocalModMeterDestroyUI()
	if LocalModMeterUIIds ~= nil and LocalModMeterUIIds[1] ~= nil then
		local oldIds = LocalModMeterUIIds
		LocalModMeterUIIds = {}
		if DestroyOnDelay ~= nil then
			thread(DestroyOnDelay, oldIds, 0.005)
		else
			Destroy({ Ids = oldIds })
		end
	else
		LocalModMeterUIIds = {}
	end
end

local function meterColor(name, fallback)
	if Color ~= nil and Color[name] ~= nil then
		return Color[name]
	end
	return fallback
end

local function meterCreateText(id, text, args)
	local white = meterColor("White", { 255, 255, 255, 255 })
	local black = meterColor("Black", { 0, 0, 0, 255 })
	CreateTextBox({
		Id = id,
		Text = text,
		Font = args.Font or "P22UndergroundSCMedium",
		FontSize = args.FontSize or 11,
		Justification = args.Justification or "Left",
		OffsetX = args.OffsetX or 0,
		OffsetY = args.OffsetY or -1,
		Color = args.Color or white,
		OutlineThickness = args.OutlineThickness or 2.0,
		OutlineColor = black,
		ShadowOffset = { 1, 1 },
		ShadowBlur = 0,
		ShadowAlpha = 1,
		ShadowColor = black,
		TextSymbolScale = args.TextSymbolScale or 0.65,
	})
	ModifyTextBox({ Id = id, FadeTarget = 1, FadeDuration = 0.0 })
end

local function meterGetColorAndLabel(source)
	local sources = LocalModMeterSourceLookup
	local colors = LocalModMeterDpsColors
	local attack = LocalModMeterWeaponVar["Attack"]
	local special = LocalModMeterWeaponVar["Special"]
	local cast = LocalModMeterWeaponVar["Cast"]
	local dash = LocalModMeterWeaponVar["Dash"]
	local color
	local niceLabel

	if source == "Attack" then
		if attack ~= nil and sources[attack] ~= nil then
			return colors[attack], sources[attack]["Attack"]
		end
		return colors["Default"], "Attack"
	end
	if source == "OAttack" then
		if attack ~= nil and sources[attack] ~= nil then
			return colors[attack], sources[attack]["OAttack"]
		end
		return colors["Default"], LocalModMeterNameLookup.OAttackText or "Attack"
	end
	if source == "AttackDashStrike" then
		if attack ~= nil and sources[attack] ~= nil then
			return colors[attack], "DashStrike"
		end
		return colors["Default"], "DashStrike"
	end
	if source == "Special" then
		if special ~= nil and sources[special] ~= nil then
			return colors[special], sources[special]["Special"]
		end
		return colors["Default"], "Special"
	end
	if source == "OSpecial" then
		if special ~= nil and sources[special] ~= nil then
			return colors[special], sources[special]["OSpecial"]
		end
		return colors["Default"], LocalModMeterNameLookup.OSpecialText or "Special"
	end
	if source == "WeaponCast" then
		if cast ~= nil and sources[cast] ~= nil then
			return colors[cast], sources[cast]["WeaponCast"]
		end
		return colors["Default"], LocalModMeterNameLookup.OCastText or "Cast"
	end
	if source == "OCast" then
		if cast ~= nil and sources[cast] ~= nil and sources[cast]["OCast"] ~= nil then
			return colors[cast], sources[cast]["OCast"]
		end
		return colors["Default"], LocalModMeterNameLookup.OCastText or "Cast"
	end
	if source == "Dash" then
		if dash ~= nil and sources[dash] ~= nil then
			return colors[dash], sources[dash]["Dash"]
		end
		return colors["Default"], "Dash"
	end

	if source == "Artemis" then
		return colors["ArtemisAssist"], "NPC_Artemis_01"
	elseif source == "Nemesis" then
		return colors["NemesisAssist"], "NPC_Nemesis_01"
	elseif source == "Heracles" then
		return colors["HeraclesAssist"], "NPC_Heracles_01"
	elseif source == "Icarus" then
		return colors["IcarusAssist"], "NPC_Icarus_01"
	elseif source == "ShadeMercSpiritball" then
		return colors["Shade"], "WorldUpgradeShadeMercs"
	elseif source == "SoulPylonSpiritball" then
		return colors["Shade"], "Pylon Spirits"
	elseif source == "Frinos" then
		return colors["Frinos"], "FrogFamiliar"
	elseif source == "Toula" then
		return colors["Toula"], "CatFamiliar"
	elseif source == "RavenFamiliar" then
		return colors["Raven"], "RavenFamiliar"
	elseif source == "DodgeFamiliar" then
		return colors["Gale"], "DodgeFamiliar"
	end

	if sources ~= nil then
		for name in pairs(sources) do
			if sources[name][source] ~= nil then
				niceLabel = sources[name][source]
				color = colors[name]
			end
		end
	end

	if color == nil and ProjectileData ~= nil then
		local projectileData = ProjectileData[source]
		if projectileData ~= nil and projectileData.DamageTextStartColor ~= nil then
			color = { BarColor = projectileData.DamageTextStartColor }
		end
	end

	if niceLabel == nil and ScreenData ~= nil and ScreenData.RunClear ~= nil then
		niceLabel = ScreenData.RunClear.DamageSourceMap[source]
	end

	if color == nil then
		color = colors["Default"]
	end
	return color, niceLabel
end

local function meterCreateBarIcons(colors, x, y)
	local godIcons = colors and colors.Icons
	if godIcons == nil then
		return
	end
	local iconOffsetX = -18
	if #godIcons == 2 then
		iconOffsetX = -12
	end
	for i, godName in ipairs(godIcons) do
		local icon = LocalModMeterIcons[godName]
		if icon ~= nil then
			local iconId = CreateScreenObstacle({
				Name = "BlankObstacle",
				Group = LocalModMeterConfig.Group,
				X = x + iconOffsetX - ((i - 1) * 12),
				Y = y - 2,
				Scale = icon.Scale,
			})
			SetAnimation({ Name = icon.Name, DestinationId = iconId, Scale = icon.Scale })
			meterCollectIds(iconId)
		end
	end
end

local function meterCreateRow(source, damage, maxDamage, totalDamage, x, y)
	local colors, niceLabel = meterGetColorAndLabel(source)
	local abilityName = niceLabel or source
	local portion = 0
	if totalDamage > 0 then
		portion = damage / totalDamage
	end
	local scale = 0
	if maxDamage > 0 then
		scale = damage / maxDamage
	end
	local percentDamage = math.floor(portion * 100 + 0.5)
	local labelColor = (colors and colors.LabelColor) or meterColor("White", { 255, 255, 255, 255 })
	local barColor = meterHashColor(source)
	local barWidth = LocalModMeterConfig.BarMaxWidth * scale
	local scaleX = barWidth / LocalModMeterConfig.BarNativeWidth
	if scaleX < 0.02 and scale > 0 then
		scaleX = 0.02
	end

	local nameId = CreateScreenObstacle({ Name = "BlankObstacle", Group = LocalModMeterConfig.Group, X = x - 8, Y = y })
	meterCreateText(nameId, abilityName, {
		Justification = "Right",
		FontSize = 11,
		Color = labelColor,
		OffsetX = -18,
	})
	meterCollectIds(nameId)

	if colors ~= nil and colors.Icons ~= nil then
		meterCreateBarIcons(colors, x, y)
	end

	local barId = CreateScreenObstacle({
		Name = "rectangle01",
		Group = LocalModMeterConfig.Group,
		X = x + (barWidth * 0.5),
		Y = y,
	})
	SetScaleX({ Id = barId, Fraction = scaleX })
	SetScaleY({ Id = barId, Fraction = LocalModMeterConfig.BarScaleY })
	meterTint(barId, barColor)
	meterCollectIds(barId)

	if scale > 0.2 then
		local amountId = CreateScreenObstacle({ Name = "BlankObstacle", Group = LocalModMeterConfig.Group, X = x + barWidth - 6, Y = y })
		meterCreateText(amountId, tostring(damage), {
			Justification = "Right",
			Font = "NumericP22UndergroundSCMedium",
			FontSize = 10,
			OffsetX = 0,
		})
		meterCollectIds(amountId)
	end

	local percentId = CreateScreenObstacle({ Name = "BlankObstacle", Group = LocalModMeterConfig.Group, X = x + barWidth + 8, Y = y })
	meterCreateText(percentId, percentDamage .. "%", {
		Justification = "Left",
		Font = "NumericP22UndergroundSCMedium",
		FontSize = 11,
	})
	meterCollectIds(percentId)
end

local function meterCreateHeader(totalDamage, avgDps, x, y)
	local dpsText = avgDps
	if tostring(avgDps) == "inf" or avgDps == nil then
		dpsText = "···"
	end
	local text = string.format("%s DPS | Total Damage: %d", tostring(dpsText), totalDamage)
	local headerId = CreateScreenObstacle({ Name = "BlankObstacle", Group = LocalModMeterConfig.Group, X = x + 80, Y = y })
	meterCreateText(headerId, text, {
		Justification = "Center",
		FontSize = 14,
		Font = "P22UndergroundSCMedium",
		OffsetX = 0,
		OffsetY = 0,
	})
	meterCollectIds(headerId)
end

local function meterCreateBackground(x, y, width, height)
	local scaleWidth = width / LocalModMeterConfig.BarNativeWidth
	local scaleHeight = height / 270
	local bgId = CreateScreenObstacle({
		Name = "rectangle01",
		Group = LocalModMeterConfig.Group,
		X = x + LocalModMeterConfig.Margin,
		Y = y,
	})
	SetScaleX({ Id = bgId, Fraction = scaleWidth })
	SetScaleY({ Id = bgId, Fraction = scaleHeight })
	meterTint(bgId, LocalModMeterConfig.BackgroundColor)
	meterCollectIds(bgId)
end

function LocalModMeterCalculate()
	local list = LocalModMeterHistory
	local totalDamage = 0
	local earliestTimestamp = 999999
	local latestTimestamp = 0
	local totalDamageBySource = {}
	local now = GetTime({})
	for i = list.first, list.last do
		local damageData = list[i]
		if damageData ~= nil then
			totalDamage = totalDamage + damageData.Damage
			totalDamageBySource[damageData.Source] = (totalDamageBySource[damageData.Source] or 0) + damageData.Damage
			if damageData.Timestamp < earliestTimestamp then
				earliestTimestamp = damageData.Timestamp
			end
			if damageData.Timestamp > latestTimestamp then
				latestTimestamp = damageData.Timestamp
			end
		end
	end

	if totalDamage <= 0 then
		if LocalModMeterFrozen then
			return
		end
		local oldIds = LocalModMeterUIIds
		LocalModMeterUIIds = {}
		if oldIds ~= nil and oldIds[1] ~= nil then
			if DestroyOnDelay ~= nil then
				thread(DestroyOnDelay, oldIds, 0.005)
			else
				Destroy({ Ids = oldIds })
			end
		end
		return
	end

	local oldIds = LocalModMeterUIIds
	LocalModMeterUIIds = {}
	if oldIds ~= nil and oldIds[1] ~= nil then
		if DestroyOnDelay ~= nil then
			thread(DestroyOnDelay, oldIds, 0.005)
		else
			Destroy({ Ids = oldIds })
		end
	end

	local sourcesSortedByDamage = {}
	for source in pairs(totalDamageBySource) do
		table.insert(sourcesSortedByDamage, source)
	end
	table.sort(sourcesSortedByDamage, function(a, b)
		return totalDamageBySource[a] < totalDamageBySource[b]
	end)

	local maxRows = LocalModMeterConfig.MaxRows
	if #sourcesSortedByDamage > maxRows then
		local trimmed = {}
		for i = #sourcesSortedByDamage - maxRows + 1, #sourcesSortedByDamage do
			table.insert(trimmed, sourcesSortedByDamage[i])
		end
		sourcesSortedByDamage = trimmed
	end

	local maxSourceDamage = totalDamageBySource[sourcesSortedByDamage[#sourcesSortedByDamage]] or 1
	local duration = latestTimestamp - earliestTimestamp
	local avgDps = "···"
	if duration > 0 then
		avgDps = math.floor((totalDamage / duration) + 0.5)
	end

	local yPos = LocalModMeterConfig.InitialY
	local xPos = LocalModMeterConfig.XPosition
	local rowCount = #sourcesSortedByDamage
	local finalY = yPos + (rowCount * LocalModMeterConfig.YPositionIncrement)
	local height = (LocalModMeterConfig.InitialY - finalY + LocalModMeterConfig.Margin)
	local yPosOverlay = finalY + LocalModMeterConfig.YPositionIncrement + height / 2
	meterCreateBackground(xPos, yPosOverlay, LocalModMeterConfig.DisplayWidth, height)

	for _, source in ipairs(sourcesSortedByDamage) do
		local barDamageRounded = math.floor(totalDamageBySource[source] + 0.5)
		meterCreateRow(source, barDamageRounded, maxSourceDamage, totalDamage, xPos, yPos)
		yPos = yPos + LocalModMeterConfig.YPositionIncrement
	end

	local totalDamageRounded = math.floor(totalDamage + 0.5)
	meterCreateHeader(totalDamageRounded, avgDps, xPos, yPos - 5)
end

local function meterMaybeClearTrainingRoom()
	local roomName = nil
	if CurrentRun ~= nil and CurrentRun.CurrentRoom ~= nil then
		roomName = CurrentRun.CurrentRoom.Name
	end
	if CurrentHubRoom ~= nil then
		roomName = CurrentHubRoom.Name or roomName
	end
	if roomName ~= "Hub_PreRun" then
		return
	end
	local last = LocalModMeterHistory[LocalModMeterHistory.last]
	if last ~= nil and (GetTime({}) - last.Timestamp) > LocalModMeterConfig.TrainingRoomClearTime then
		meterListEmpty(LocalModMeterHistory)
	end
end

function LocalModMeterStartPolling()
	if LocalModMeterPolling then
		return
	end
	LocalModMeterPolling = true
	thread(function()
		while LocalModMeterPolling do
			meterMaybeClearTrainingRoom()
			LocalModMeterCalculate()
			waitUnmodified(LocalModMeterConfig.PollingInterval, "LocalModMeterPoll")
		end
	end)
end

function LocalModMeterEnsurePolling()
	if LocalModMeterFrozen then
		return
	end
	meterEnsureNames()
	if not LocalModMeterPolling then
		LocalModMeterRefreshBoons()
		LocalModMeterStartPolling()
	end
end

function LocalModMeterOnStartRoom()
	LocalModMeterFrozen = false
	LocalModMeterRefreshBoons()
	if not LocalModMeterPolling then
		LocalModMeterStartPolling()
	end
end

function LocalModMeterOnRoomClear()
	LocalModMeterPolling = false
	killTaggedThreads("LocalModMeterPoll")
	LocalModMeterCalculate()
	meterListEmpty(LocalModMeterHistory)
	LocalModMeterFrozen = true
end

function LocalModMeterCheckChillKill(args, attacker, victim, triggerArgs)
	local preCheckKillHealth = victim and victim.Health
	local firedChillKillCache = nil
	if SessionMapState ~= nil and SessionMapState.FiredChillKill ~= nil and victim ~= nil then
		firedChillKillCache = SessionMapState.FiredChillKill[victim.ObjectId]
	end
	LocalModVanillaCheckChillKill(args, attacker, victim, triggerArgs)
	if victim ~= nil and SessionMapState ~= nil and SessionMapState.FiredChillKill ~= nil then
		if not firedChillKillCache and SessionMapState.FiredChillKill[victim.ObjectId] then
			meterLog("DemeterChillKill", preCheckKillHealth, preCheckKillHealth)
		end
	end
end

function LocalModMeterDamageEnemy(victim, triggerArgs)
	LocalModMeterEnsurePolling()
	if victim == nil or triggerArgs == nil then
		return LocalModVanillaDamageEnemy(victim, triggerArgs)
	end

	local preHitHealth = victim.Health
	local preHitHealthBuffer = victim.HealthBuffer or 0
	local result = LocalModVanillaDamageEnemy(victim, triggerArgs)

	local attackerTable = triggerArgs.AttackerTable or {}
	local activeEffects = attackerTable.ActiveEffects or {}
	local activeEffectsStart = attackerTable.ActiveEffectsAtDamageStart or {}
	local victimCharmed = false
	if victim.ObjectId ~= nil then
		victimCharmed = IsCharmed({ Id = victim.ObjectId })
	end
	local attackerCharmed = attackerTable.Charmed or activeEffects["Charm"] == 1 or activeEffectsStart["Charm"] == 1
	local playerWasAttacker = LocalModMeterPlayerUnits[triggerArgs.AttackerName] or false
	local preDamage = triggerArgs.PreDamageBossFunctionName ~= nil
	local isCurse = triggerArgs.CurseName ~= nil

	if triggerArgs.SourceProjectile == "SoulPylonSpiritball" then
		meterLog("SoulPylonSpiritball", preHitHealth, triggerArgs.DamageAmount)
		return result
	end
	if triggerArgs.SourceProjectile == "ShadeMercSpiritball" or triggerArgs.SourceProjectile == "ShadeMercAspectSpiritball" then
		meterLog("ShadeMercSpiritball", preHitHealth, triggerArgs.DamageAmount)
		return result
	end
	if CurrentRun ~= nil and CurrentRun.Hero ~= nil and triggerArgs.AttackerId == CurrentRun.Hero.ObjectId and triggerArgs.EffectName == "BurnEffect" then
		meterLog("Burn", preHitHealth, triggerArgs.DamageAmount)
		return result
	end
	if triggerArgs.EffectName == "DamageShareDeath" then
		meterLog("DamageShareDeath", preHitHealth, triggerArgs.DamageAmount)
		return result
	end
	if triggerArgs.SourceProjectile == "ZeusOnSpawn" then
		local isInstaKill = preHitHealth <= (triggerArgs.DamageAmount or 0)
		local healthDamage = math.min(preHitHealth, triggerArgs.DamageAmount or 0)
		local healthBufferDamage = 0
		if isInstaKill then
			healthBufferDamage = preHitHealthBuffer
		end
		meterLog("ZeusOnSpawn", preHitHealth + preHitHealthBuffer, healthDamage + healthBufferDamage)
		return result
	end

	local source = meterGetSourceName(triggerArgs, victim)
	if victim.DamageShareAmount and meterCanHitchDamage(source) then
		local hitchDamage = math.floor((math.min(triggerArgs.DamageAmount or 0, preHitHealth) * victim.DamageShareAmount) + 0.5)
		meterLog("DamageShareEffect", preHitHealth, hitchDamage)
	end

	if (triggerArgs.DamageAmount or 0) > 0
		and victim.MaxHealth ~= nil
		and (victim.Name == "NPC_Skelly_01"
			or (victim.GeneratorData or {}).DifficultyRating ~= nil
			or victim.CanBeAggroed
			or victim.IsBoss)
		and not (victimCharmed and not playerWasAttacker)
		and not (not attackerCharmed and not victimCharmed and not playerWasAttacker and not preDamage and not isCurse)
	then
		if source ~= "Unknown" then
			meterLog(source, preHitHealth, triggerArgs.DamageAmount)
		end
	end
	return result
end

function DamageEnemy(victim, triggerArgs)
	return LocalModMeterDamageEnemy(victim, triggerArgs)
end
