local entMeta = FindMetaTable("Entity")

--[[-------------------------------------------------------------------------
IsOnFire Override
---------------------------------------------------------------------------]]
local oldIsOnFire = entMeta.IsOnFire
entMeta.IsOnFire = function(ent)
	if vFireIsVFireEnt(ent) then return true end
	if ent.fires then
		if table.Count(ent.fires) > 0 then return true end
	end
	return oldIsOnFire(ent)
end

if SERVER then
	--[[-------------------------------------------------------------------------
	Ignite Override
	---------------------------------------------------------------------------]]
	local vFireIgniteOverrideEnabled = true
	function vFireGetIgniteOverride()
		return vFireIgniteOverrideEnabled
	end
	function vFireIgniteOverride(enabled)
		vFireIgniteOverrideEnabled = enabled
	end

	-- Ignite throttle factors
	local igniteThrottle = 0
	local igniteUnThrottleTime = 1
	local igniteLimit = 15

	local oldIgnite = entMeta.Ignite
	entMeta.Ignite = function(ent, time, radius)

		-- Should we override ignite behavior?
		if vFireGetIgniteOverride() then -- We should

			-- Some addons actually try to ignite the world...
			if not IsValid(ent) then return end
			if ent:IsWorld() then return end
			
			local igniteSuccessful = false
			
			if igniteThrottle < igniteLimit then

				local count = 5

				-- Only create fires if we're not burning enough
				count = count - table.Count(ent.fires or {})
				if count > 0 then

					if vFireIsCharacter(ent) then

						for i = 1, count do
							CreateVFire(ent, ent:GetPos(), VectorRand(), 70)
						end
						igniteSuccessful = true

					else

						igniteSuccessful = CreateVFireEntFires(ent, count)

					end

				end

				if isnumber(radius) then
					if radius > 0 then
						for _, closeEnt in pairs(ents.FindInSphere(ent:GetPos(), radius)) do
							closeEnt:Ignite(time, 0)
						end
					end
				end

			end

			-- Throttle our next ignite calls - we need to do this because a lot of addons like to ignite
			-- a lot of entities at once, and we need to avoid immense lag
			if igniteSuccessful then
				igniteThrottle = igniteThrottle + 1
				timer.Simple(igniteUnThrottleTime, function()
					igniteThrottle = math.Max(igniteThrottle - 1, 0)
				end)
			end

		else -- We're not overriding the ignite function
			-- Trigger the old function, default fire is suppressed by other means
			oldIgnite(ent, time, radius)
			return
		end
	end

	--[[-------------------------------------------------------------------------
	Extinguish Override
	---------------------------------------------------------------------------]]
	local oldExtinguish = entMeta.Extinguish
	entMeta.Extinguish = function(ent)
		
		if vFireIsVFireEnt(ent) then
			if ent:GetClass() == "vfire" then
				ent:ChangeLife(0)
			elseif ent:GetClass() == "vfire_ball" then
				ent:ChangeLife(0)
			end

			return
		end


		if ent.fires then
			for fire, lPos in pairs(ent.fires) do
				if IsValid(fire) then
					fire:Remove()
				end
			end
		end

		-- Nothing bad happens if we also call the normal extinguish function
		oldExtinguish(ent)

	end
end

--[[-------------------------------------------------------------------------
vFire Globals
---------------------------------------------------------------------------]]
vFireMaxState = 7

local lifeBase = 2.295 -- Originally 2.5
vFireMaxLife = lifeBase^vFireMaxState

vFireStatesLifeThresholds = {}
	vFireStatesLifeThresholds[1] = lifeBase^1 -- or lower is state 1 else
	vFireStatesLifeThresholds[2] = lifeBase^2 -- or lower is state 2 else
	vFireStatesLifeThresholds[3] = lifeBase^3 -- or lower is state 3 else
	vFireStatesLifeThresholds[4] = lifeBase^4 -- or lower is state 4 else
	vFireStatesLifeThresholds[5] = lifeBase^5 -- or lower is state 5 else
	vFireStatesLifeThresholds[6] = lifeBase^6 -- or lower is state 6 else
	vFireStatesLifeThresholds[7] = vFireMaxLife -- or lower is state 7

vFireStateToSizeTable = {}
	vFireStateToSizeTable[1] = "Tiny"
	vFireStateToSizeTable[2] = "Small"
	vFireStateToSizeTable[3] = "Medium"
	vFireStateToSizeTable[4] = "Big"
	vFireStateToSizeTable[5] = "Huge"
	vFireStateToSizeTable[6] = "Gigantic"
	vFireStateToSizeTable[7] = "Inferno"

vFireClusterSize = 400

vFireDummyModel = "models/hunter/plates/plate.mdl"
util.PrecacheModel(vFireDummyModel)

function vFireStateToSize(state)
	local size = vFireStateToSizeTable[state] or "Tiny"
	return size
end

function vFireLifeToState(life)
	local stateReturn = vFireMaxState
	for stateIndex, lifeThreshold in pairs(vFireStatesLifeThresholds) do
		if life <= lifeThreshold then
			stateReturn = stateIndex
			return stateReturn
		end
	end
	return stateReturn
end

function vFireStateToLife(state)
	return vFireStatesLifeThresholds[state]
end

-- Helper used to determine if we're burning a character or not
function vFireIsCharacter(ent)
	if !IsValid(ent) then return false end
	if ent.vFireIsCharacter != nil then return ent.vFireIsCharacter end
	local isCharacter = ent:IsRagdoll() or ent:IsNPC() or ent:IsPlayer()
	ent.vFireIsCharacter = isCharacter
	return isCharacter
end

function vFireIsMobile(ent)
	local parent = ent.parent
	if !IsValid(parent) then return false end
	return (parent == NULL or !parent:IsWorld())
end

-- Helper used to determine if an entity is ours or not
function vFireIsVFireEnt(ent)
	if !IsValid(ent) then return false end
	if ent.vFireIsVFireEnt != nil then return ent.vFireIsVFireEnt end
	
	local c = ent:GetClass()
	local isVFireEnt = c == "vfire" or c == "vfire_ball" or c == "vfire_cluster"
	ent.vFireIsVFireEnt = isVFireEnt
	return isVFireEnt
end

local baseRadius = {10, 30, 50, 80, 125, 230, 390}
function vFireBaseRadius(state)
	return baseRadius[state]
end

function vFireGetFires(ent)
	local fires = {}
	local firesTable = ent.fires
	if firesTable then
		for fire, lPos in pairs(firesTable) do 
			table.insert(fires, fire)
		end
	end
	return fires
end

--[[-------------------------------------------------------------------------
Burning Entities Tracking
---------------------------------------------------------------------------]]
local burningEntities = {}
function vFireGetBurningEntities()
	return table.Copy(burningEntities)
end
hook.Add("vFireEntityStartedBurning", "vFireAddBurningEntity", function(ent)
	burningEntities[ent] = ent
end)
hook.Add("vFireEntityStoppedBurning", "vFireRemBurningEntity", function(ent)
	if burningEntities[ent] then
		burningEntities[ent] = nil
	end
end)

--[[-------------------------------------------------------------------------
vFiresCount Tracking
---------------------------------------------------------------------------]]
vFiresCount = 0
hook.Add("vFireCreated", "vFiresCountIncrement", function(fire)
	-- Update vFiresCount
	vFiresCount = vFiresCount + 1

	-- Update whatever else we need to update
	vFireUpdateThinkThrottle()
	
	if SERVER then
		vFireUpdateLifeThrottle()
	end
end)

hook.Add("vFireRemoved", "vFiresCountDecrement", function(fire)
	-- Update vFiresCount
	vFiresCount = math.Max(vFiresCount - 1, 0)

	-- Update whatever else we need to update
	vFireUpdateThinkThrottle()
	
	if SERVER then
		vFireUpdateLifeThrottle()
	end
end)

--[[-------------------------------------------------------------------------
Tickrates Management
---------------------------------------------------------------------------]]
if CLIENT then
	vFireClusterThinkTickRate = 5
	vFireParticlesThinkTickRate = 1.15
	vFireAnimationThinkTickRate = 15
	
	vFireThrottleMultiplier = 0.01
	vFireThinkThrottle = 0
	function vFireUpdateThinkThrottle()
		vFireThinkThrottle = vFiresCount * vFireThrottleMultiplier
	end
end

if SERVER then
	vFireFuelThinkTickRate = 2
	vFireLifeThinkTickRate = 1.15
	vFireEatThinkTickRate = 2
	vFireBurnThinkTickRate = 2
	vFireDropThinkTickRate = 3
	vFireSpreadThinkTickRate = 0.5

	vFireThrottleMultiplier = 0.1
	vFireThinkThrottle = 0
	vFireMaxThinkThrottle = 30 -- Cap the throttling to avoid non-thinking fires (bad at performance heavy scenarios)
	function vFireUpdateThinkThrottle()
		vFireThinkThrottle = math.min(vFiresCount * vFireThrottleMultiplier, vFireMaxThinkThrottle)
	end
end

--[[-------------------------------------------------------------------------
ConVars
---------------------------------------------------------------------------]]
if CLIENT or SERVER then
	--[[-------------------------------------------------------------------------
	Wind functionalities
	---------------------------------------------------------------------------]]
	local windVec = Vector(0.7, -1, 0)
	windVec:Normalize()
	function vFireGetWindVector()
		return windVec
	end

	-- Used to calcualte the wind flow of a given position
	local windExposureCheckDist = 10000
	function vFireCalcWindExposure(pos, filter)
		return 1
	end

	--[[-------------------------------------------------------------------------
	Smoke functionalities
	---------------------------------------------------------------------------]]
	local vFireEnableSmokeConVar = CreateConVar("vfire_enable_smoke", "1", FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Enables fire smoke.")
	vFireEnableSmoke = vFireEnableSmokeConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_smoke", function(convar, old, new)
		vFireEnableSmoke = vFireEnableSmokeConVar:GetBool()
	end)
end

if CLIENT then
	--[[-------------------------------------------------------------------------
	Toggle fire LODs
	---------------------------------------------------------------------------]]
	local vFireLODsConVar = CreateClientConVar("vfire_lod", "1", true, false, "Set to 0 to disable all fire LODs, 1 for automatic LODs, and 2 to force LODs on.")
	vFireLODs = vFireLODsConVar:GetInt()
	cvars.AddChangeCallback("vfire_lod", function(convar, old, new)
		vFireLODs = math.Clamp(vFireLODsConVar:GetInt(), 0, 2)
	end)

	
	--[[-------------------------------------------------------------------------
	Toggle fire glows
	---------------------------------------------------------------------------]]
	local vFireEnableGlowsConVar = CreateClientConVar("vfire_enable_glows", "1", true, false, "Set to 0 to disable fire glow effects.")
	vFireEnableGlows = vFireEnableGlowsConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_glows", function(convar, old, new)
		vFireEnableGlows = vFireEnableGlowsConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Toggle fire dynamic lights
	---------------------------------------------------------------------------]]
	local vFireEnableLightsConVar = CreateClientConVar("vfire_enable_lights", "1", true, false, "Set to 0 to disable all fire light effects for increased performance at the cost of visual fidelity.")
	vFireEnableLights = vFireEnableLightsConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_lights", function(convar, old, new)
		vFireEnableLights = vFireEnableLightsConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Set fire light brightness
	---------------------------------------------------------------------------]]
	local vFireLightMulConVar = CreateClientConVar("vfire_light_brightness", "0.4", true, false, "Set the fire light brightness multiplier.")
	vFireLightMul = vFireLightMulConVar:GetFloat()
	cvars.AddChangeCallback("vfire_light_brightness", function(convar, old, new)
		vFireLightMul = vFireLightMulConVar:GetFloat()
	end)

	--[[-------------------------------------------------------------------------
	Reset all ConVars
	---------------------------------------------------------------------------]]
	concommand.Add("vfire_default_visual_settings", function()
		vFireLODsConVar:SetBool(vFireLODsConVar:GetDefault())
		vFireEnableGlowsConVar:SetBool(vFireEnableGlowsConVar:GetDefault())
		vFireEnableLightsConVar:SetBool(vFireEnableLightsConVar:GetDefault())
		vFireLightMulConVar:SetFloat(vFireLightMulConVar:GetDefault())
		vFireMessage("vFire client settings reset to default!")
	end)
end

if SERVER then
	--[[-------------------------------------------------------------------------
	Set throttle multiplier
	---------------------------------------------------------------------------]]
	local vFireThrottleMultiplierConVar = CreateConVar("vfire_throttle_multiplier", tostring(vFireThrottleMultiplier), FCVAR_ARCHIVE, "Performance Warning: advanced setting, may result in unexpected behavior! Set the fire throttle multiplier - lower values will result in more responsive fires at the cost of performance.")
	vFireThrottleMultiplier = vFireThrottleMultiplierConVar:GetFloat()
	cvars.AddChangeCallback("vfire_throttle_multiplier", function(convar, old, new)
		vFireThrottleMultiplier = vFireThrottleMultiplierConVar:GetFloat()
		vFireUpdateThinkThrottle()
	end)


	--[[-------------------------------------------------------------------------
	Toggle fire damage
	---------------------------------------------------------------------------]]
	local vFireEnableDamageConVar = CreateConVar("vfire_enable_damage", "1", FCVAR_ARCHIVE, "Set to 0 to disable fire damage.")
	vFireEnableDamage = vFireEnableDamageConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_damage", function(convar, old, new)
		vFireEnableDamage = vFireEnableDamageConVar:GetBool()
	end)

	
	--[[-------------------------------------------------------------------------
	Toggle fire damage for players in vehicles
	---------------------------------------------------------------------------]]
	local vFireEnableDamageInVehiclesConVar = CreateConVar("vfire_enable_damage_in_vehicles", "0", FCVAR_ARCHIVE, "Set to 1 to enable fire damage to players inside vehicles.")
	vFireEnableDamageInVehicles = vFireEnableDamageInVehiclesConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_damage_in_vehicles", function(convar, old, new)
		vFireEnableDamageInVehicles = vFireEnableDamageInVehiclesConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Set fire damage multiplier
	---------------------------------------------------------------------------]]
	local vFireDamageMultiplierConVar = CreateConVar("vfire_damage_multiplier", "1", FCVAR_ARCHIVE, "Set the damage multiplier for fires, 0 disables all damage.")
	vFireDamageMultiplier = 2.5
	cvars.AddChangeCallback("vfire_damage_multiplier", function(convar, old, new)
		vFireDamageMultiplier = vFireDamageMultiplierConVar:GetFloat()
	end)


	--[[-------------------------------------------------------------------------
	Toggle explosion fire balls
	---------------------------------------------------------------------------]]
	local vFireEnableExplosionFiresConVar = CreateConVar("vfire_enable_explosion_fires", "1", FCVAR_ARCHIVE, "Set to 0 to disable explosion fires.")
	vFireEnableExplosionFires = vFireEnableExplosionFiresConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_explosion_fires", function(convar, old, new)
		vFireEnableExplosionFires = vFireEnableExplosionFiresConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Toggle enhanced explosion effects
	---------------------------------------------------------------------------]]
	local vFireEnableExplosionEffectsConVar = CreateConVar("vfire_enable_explosion_effects", "1", FCVAR_ARCHIVE, "Set to 0 to disable fancy explosion effects.")
	vFireEnableExplosionEffects = vFireEnableExplosionEffectsConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_explosion_effects", function(convar, old, new)
		vFireEnableExplosionEffects = vFireEnableExplosionEffectsConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Toggle fire decals
	---------------------------------------------------------------------------]]
	local vFireEnableDecalsConVar = CreateConVar("vfire_enable_decals", "1", FCVAR_ARCHIVE, "Set to 0 to disable fire decals.")
	vFireEnableDecals = vFireEnableDecalsConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_decals", function(convar, old, new)
		vFireEnableDecals = vFireEnableDecalsConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Set fire decal probability
	---------------------------------------------------------------------------]]
	local vFireDecalProbabilityConVar = CreateConVar("vfire_decal_probability", "0.4", FCVAR_ARCHIVE, "Set the probability (a value between 0 and 1) of creating fire decals.")
	vFireDecalProbability = vFireDecalProbabilityConVar:GetFloat()
	cvars.AddChangeCallback("vfire_decal_probability", function(convar, old, new)
		vFireDecalProbability = vFireDecalProbabilityConVar:GetFloat()
	end)


	--[[-------------------------------------------------------------------------
	Toggle fire spread
	---------------------------------------------------------------------------]]
	local vFireEnableSpreadConVar = CreateConVar("vfire_enable_spread", "1", FCVAR_ARCHIVE, "Set to 0 to disable fire spread.")
	vFireEnableSpread = vFireEnableSpreadConVar:GetBool()
	cvars.AddChangeCallback("vfire_enable_spread", function(convar, old, new)
		vFireEnableSpread = vFireEnableSpreadConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Set fire spread rate
	---------------------------------------------------------------------------]]
	local vFireSpreadRateConVar = CreateConVar("vfire_spread_delay", tostring(vFireSpreadThinkTickRate), FCVAR_ARCHIVE, "Set fire spread delay in seconds - the smaller the number the faster fires will spread. Performance Warning: use this to limit spread, not increase it! If you want to increase spread, use vfire_spread_boost!")
	vFireSpreadThinkTickRate = math.Max(vFireSpreadRateConVar:GetFloat(), 0.0001)
	cvars.AddChangeCallback("vfire_spread_delay", function(convar, old, new)
		vFireSpreadThinkTickRate = math.Max(vFireSpreadRateConVar:GetFloat(), 0.0001)
	end)


	--[[-------------------------------------------------------------------------
	Set fire decay rate
	---------------------------------------------------------------------------]]
	local vFireDecayRateConVar = CreateConVar("vfire_decay_rate", "0.1", FCVAR_ARCHIVE, "Set fire decay rate, 1 is max decay rate, 0 is no decay rate. Performance Warning: removing decay entirely may increase load as fires accumulate.")
	vFireDecayRate = vFireDecayRateConVar:GetFloat()
	cvars.AddChangeCallback("vfire_decay_rate", function(convar, old, new)
		vFireDecayRate = math.Clamp(vFireDecayRateConVar:GetFloat(), 0, 1)
	end)


	--[[-------------------------------------------------------------------------
	Toggle custom NPC behavior
	---------------------------------------------------------------------------]]
	local vFireEnableNPCBehaviorConVar = CreateConVar("vfire_affect_npcs", "1", FCVAR_ARCHIVE, "Set to 0 to disable custom NPC behavior.")
	vFireEnableNPCBehavior = vFireEnableNPCBehaviorConVar:GetBool()
	cvars.AddChangeCallback("vfire_affect_npcs", function(convar, old, new)
		vFireEnableNPCBehavior = vFireEnableNPCBehaviorConVar:GetBool()
	end)


	--[[-------------------------------------------------------------------------
	Add cluster feed - in the 'prettified' name of spread boost
	---------------------------------------------------------------------------]]
	local vFireClusterFeedConVar = CreateConVar("vfire_spread_boost", "0", FCVAR_ARCHIVE, "Set the spread boost of new fires. Higher values will achieve faster, and stronger spread. Performance Warning: excessively high values may result in endless spreading.")
	vFireClusterFeed = vFireClusterFeedConVar:GetFloat()
	cvars.AddChangeCallback("vfire_spread_boost", function(convar, old, new)
		vFireClusterFeed = math.Max(vFireClusterFeedConVar:GetFloat(), 0)
	end)


	--[[-------------------------------------------------------------------------
	Remove all fires
	---------------------------------------------------------------------------]]
	concommand.Add("vfire_remove_all", function(ply)

		if IsValid(ply) and !ply:IsAdmin() then return end

		for k, fire in pairs(ents.FindByClass("vfire")) do
			fire:Remove()
		end
	end)

	--[[-------------------------------------------------------------------------
	Reset all ConVars
	---------------------------------------------------------------------------]]
	concommand.Add("vfire_default_settings", function(ply)

		if IsValid(ply) and !ply:IsAdmin() then return end

		vFireThrottleMultiplierConVar:SetFloat(vFireThrottleMultiplierConVar:GetDefault())
		vFireEnableDamageConVar:SetBool(vFireEnableDamageConVar:GetDefault())
		vFireDamageMultiplierConVar:SetFloat(vFireDamageMultiplierConVar:GetDefault())
		vFireEnableExplosionEffectsConVar:SetFloat(vFireEnableExplosionEffectsConVar:GetDefault())
		vFireEnableDecalsConVar:SetBool(vFireEnableDecalsConVar:GetDefault())
		vFireDecalProbabilityConVar:SetFloat(vFireDecalProbabilityConVar:GetDefault())
		vFireEnableSpreadConVar:SetBool(vFireEnableSpreadConVar:GetDefault())
		vFireSpreadRateConVar:SetFloat(vFireSpreadRateConVar:GetDefault())
		vFireDecayRateConVar:SetFloat(vFireDecayRateConVar:GetDefault())
		vFireEnableNPCBehaviorConVar:SetBool(vFireEnableNPCBehaviorConVar:GetDefault())
		vFireClusterFeedConVar:SetFloat(vFireClusterFeedConVar:GetDefault())
		
		vFireMessage("vFire settings reset to default!")
	end)
end

--[[-------------------------------------------------------------------------
Life Throttle Calculation
---------------------------------------------------------------------------]]
if SERVER then
	vFireLifeThrottle = 0
	function vFireUpdateLifeThrottle()
		vFireLifeThrottle = math.Max(vFiresCount * 1.5, 10) * vFireDecayRate * vFireThrottleMultiplier
	end
end

--[[-------------------------------------------------------------------------
How much fuel does each prop material give?
---------------------------------------------------------------------------]]
if SERVER then
	local matsFuelAmount = {
		wood_crate = 40,
		wood = 40,
		plastic_barrel = 15,
		plastic = 10,
		wood_furniture = 40,
		rubbertire = 20,
		cardboard = 8,
		paper = 6,
		rubber = 18,
		alienflesh = 7,
		wood_solid = 40,
		tile = 1
	}

	local matsFuelRate = {
		wood_crate = 0.5,
		wood = 0.5,
		plastic_barrel = 1.8,
		plastic = 1.8,
		wood_furniture = 0.5,
		rubbertire = 1.5,
		cardboard = 9,
		paper = 13,
		rubber = 0.6,
		alienflesh = 0.7,
		wood_solid = 0.5,
		tile = 0.2
	}
	
	local matTypesFuelRate = {}
		matTypesFuelRate[MAT_ANTLION] = 0.8
		matTypesFuelRate[MAT_BLOODYFLESH] = 0.4
		matTypesFuelRate[MAT_DIRT] = 0.3
		matTypesFuelRate[MAT_FLESH] = 0.45
		matTypesFuelRate[MAT_ALIENFLESH] = 0.8
		matTypesFuelRate[MAT_PLASTIC] = 0.7
		matTypesFuelRate[MAT_FOLIAGE] = 0.375
		matTypesFuelRate[MAT_GRASS] = 0.375
		matTypesFuelRate[MAT_WOOD] = 1.2

	function vFireMatToFuelRate(mat)
		return matsFuelRate[mat] or matTypesFuelRate[mat] or 0.5
	end

	local matTypesFeed = {}
		matTypesFeed[MAT_ANTLION] = 100
		matTypesFeed[MAT_BLOODYFLESH] = 40 
		matTypesFeed[MAT_DIRT] = 165
		matTypesFeed[MAT_FLESH] = 200
		matTypesFeed[MAT_ALIENFLESH] = 200
		matTypesFeed[MAT_PLASTIC] = 500
		matTypesFeed[MAT_FOLIAGE] = 575
		matTypesFeed[MAT_COMPUTER] = 40
		matTypesFeed[MAT_GRASS] = 300
		matTypesFeed[MAT_WOOD] = 4000

	function vFireMatToFeed(mat)
		return matTypesFeed[mat] or 0
	end

	local matTypesDamageMul = {}
		matTypesDamageMul[MAT_PLASTIC] = 2
		matTypesDamageMul[MAT_METAL] = 8
		matTypesDamageMul[MAT_COMPUTER] = 3
		matTypesDamageMul[MAT_SLOSH] = 2
		matTypesDamageMul[MAT_GLASS] = 2
		matTypesDamageMul[MAT_FLESH] = 10

	function vFireMatToDamageMultiplier(mat)
		return matTypesDamageMul[mat] or 1
	end

	function vFireSetDamageData(ent)
		if ent:IsPlayer() then
			ent.vFireDamageData = {dmgMul = 10, dmgType = DMG_BURN}
		elseif ent:IsNPC() then
			ent.vFireDamageData = {dmgMul = 5, dmgType = DMG_DIRECT}
		elseif string.StartWith(ent:GetClass(), "func") then
			ent.vFireDamageData = {dmgMul = vFireMatToDamageMultiplier(ent:GetMaterialType()), dmgType = DMG_BURN, inflict = true}
		elseif ent:IsVehicle() then
			if vFireEnableDamageInVehicles then
				ent.vFireDamageData = {dmgMul = 5, dmgType = DMG_BURN, inflict = true}
			else
				ent.vFireDamageData = {dmgMul = 5, dmgType = DMG_CRUSH, inflict = true}
			end
		else
			ent.vFireDamageData = {dmgMul = vFireMatToDamageMultiplier(ent:GetMaterialType()), dmgType = DMG_BURN, inflict = true}
		end
	end

	function vFireTakeFuel(ent, fuelTake)
		if !IsValid(ent) then return 0 end

		if ent.vFireFuelAmount != nil and ent.vFireFuelRate != nil then
			local take = math.Min(fuelTake * ent.vFireFuelRate, ent.vFireFuelAmount)
			ent.vFireFuelAmount = ent.vFireFuelAmount - take
			return take
		end
		
		ent.vFireFuelAmount = 0
		ent.vFireFuelRate = 0

		if vFireIsCharacter(ent) then
			if ent:IsPlayer() then
				ent.vFireFuelAmount = math.huge
			else
				ent.vFireFuelAmount = 50
			end
			ent.vFireFuelRate = 1.5
		elseif ent:IsVehicle() then
			ent.vFireFuelAmount = 1650
			ent.vFireFuelRate = 1
		elseif ent:GetClass() == "vfire_cluster" then
			local parent = ent.parent
			local feedMul = (parent:IsWorld() or !IsValid(parent)) and 1 or vFireTakeFuel(parent, 1)
			local matFeed = vFireMatToFeed(ent.matType)
			ent.vFireFuelAmount = matFeed * math.Rand(0.5, 1) * feedMul + vFireClusterFeed

			local fuelRate
			if IsValid(parent) then
				local phys = parent:GetPhysicsObject()
				if IsValid(phys) then
					fuelRate = vFireMatToFuelRate(phys:GetMaterial())
				end
			end
			if !fuelRate then fuelRate = vFireMatToFuelRate(ent.matType) end
			ent.vFireFuelRate = fuelRate
		else
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				local mat = phys:GetMaterial()
				local volume = phys:GetVolume() or 0
				local matGive = matsFuelAmount[mat] or 0
				local give = matGive * volume^0.5 / 5
				local fuelRate = vFireMatToFuelRate(mat)
				ent.vFireFuelAmount = give
				ent.vFireFuelRate = fuelRate
			end
		end

		local take = math.Min(fuelTake * ent.vFireFuelRate, ent.vFireFuelAmount)
		ent.vFireFuelAmount = ent.vFireFuelAmount - take
		return take
	end
end

--[[-------------------------------------------------------------------------
Fire Creation Interface (SERVER)
---------------------------------------------------------------------------]]
if SERVER then
	local mergeDistToSqr = 500
	local mergeDist = math.sqrt(mergeDistToSqr)
	local lastSpawned = CurTime()
	local spawnedammout = 0
	function CreateVFire(parent, pos, normal, newFeed, spreader)

		--;; КАКАЩКЕ
		if VFIRE_DISABLED then return end

		-- Just to make sure
		if vFireIsVFireEnt(parent) then return end
		
		-- Handle information regarding our spreader
		local owner = parent
		local spreaderIsFire = false
		if IsValid(spreader) then
			if spreader:GetClass() == "vfire" then
				spreaderIsFire = true
			end
			owner = spreader:GetOwner()
		end

		-- Settle on our bone
		local bone
		if vFireIsCharacter(parent) then
			local boneCount = parent:GetBoneCount()
			-- Build a valid set of bones to attach to
			if !parent.vFireValidBones then
				parent.vFireValidBones = {}
				for b = 0, boneCount do
					if parent:BoneHasFlag(b, BONE_USED_BY_ATTACHMENT) then
						local bonePos = parent:GetBonePosition(b)
						-- Avoid bones with bad positions
						if bonePos:DistToSqr(pos) <= 10000000 then
							parent.vFireValidBones[b] = b
						end
					end
				end
			end
			-- Choose a random bone from the verified ones
			bone = table.Random(parent.vFireValidBones)
		end
		if bone == nil then
			bone = 0
		end

		if !parent.fires then parent.fires = {} end

		-- Use a table of close fires
		local closeEnts
		if parent:IsWorld() then
			closeEnts = ents.FindInSphere(pos, mergeDist)
		else
			closeEnts = {}
			local clustersTable = parent.fireClusters
			if clustersTable then
				for cluster, clusterPos in pairs(parent.fireClusters) do
					if cluster.fires then
						for k, fire2 in pairs(cluster.fires) do
							table.insert(closeEnts, fire2)
						end
					end
				end
			end
		end

		-- Prevent fire entity spams by merging ourselves with existing neighbors

		for _, fire2 in pairs(closeEnts) do
		    if not parent.fires[fire2] then continue end
		    if vFireIsCharacter(parent) and fire2.bone != bone then continue end
		    if not IsValid(fire2) then continue end

		    if pos:DistToSqr(fire2:GetPos()) <= mergeDistToSqr then
		        if spreaderIsFire then
		            spreader:GiveFeed(fire2, newFeed)
		        else
		            fire2.feed = fire2.feed + newFeed
		            fire2:Prioritize(5, true)  
		        end
		        return
		    end
		end

		-- We didn't merge, create a new entity
		local fire = ents.Create("vfire")

		fire:SetAngles(normal:Angle())

		-- Place our fire in respect to the parent
		if vFireIsCharacter(parent) then
			-- Fix position
			local bonePos = parent:GetBonePosition(bone)

			-- Parent is set internally through FollowBone
			fire:FollowBone(parent, bone)
			if bonePos then
				fire:SetPos(bonePos)
			else
				fire:SetPos(pos)
			end
		else
			fire:SetPos(pos)
			if IsValid(parent) then
				fire:SetParent(parent)
			end
		end

		-- Override some state limitations
		if vFireIsCharacter(parent) then
			local boneLen = parent:BoneLength(bone) or 1
			local maxState = math.Clamp(math.Round(boneLen / 8, 0), 2, 5)
			fire.stateDown = maxState
			fire.stateUp = maxState
		else
			-- Before we actually spawn, make sure we have the minimal placement requirement
			local canGrow, newPos = fire:ImprovePlacement(1, parent)
			if !canGrow then -- We're not worthy
				fire:Remove()
				return
			else
				fire:SetPos(newPos)
				fire.stateUp = 1
			end
		end

		-- Remember the bone for bone remembering purposes
		fire.bone = bone

		-- Initialize the owner as the parent or the spreader's owner
		fire:SetOwner(owner)

		fire:Spawn()

		-- Pass the new feed
		if spreaderIsFire then
			spreader:GiveFeed(fire, newFeed)
		else
			fire.feed = newFeed
		end

		-- Create a delayed decal
		if vFireEnableDecals then
			if math.Rand(0, 1) < vFireDecalProbability then
				timer.Simple(math.Rand(2, 15), function()
					if IsValid(fire) then
						local size = vFireStateToSize(fire:GetFireState())
						local scorch = "VScorch_"..size
						util.Decal(
							scorch,
							fire:GetPos() + fire:GetForward(),
							fire:GetPos() + fire:GetForward() * -15,
							fire
						)
					end
				end)
			end
		end

		return fire
	end

	local lastSpawned2 = CurTime()
	local spawnedammout = 0
	function CreateVFireBall(life, feedCarry, pos, vel, owner)

		local fireBall = ents.Create("vfire_ball")
			fireBall:SetPos(pos)
			if owner then
				fireBall:SetOwner(owner)
			end
		fireBall:Spawn()

		fireBall:GetPhysicsObject():AddVelocity(vel)
		fireBall:ChangeLife(life)
		fireBall.feedCarry = feedCarry

		return fireBall
	end

	function CreateVFireEntFires(ent, count)
		if not IsValid(ent) then return end
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then

			if !ent.vFireIgnitePositions then ent.vFireIgnitePositions = {} end

			local meshConvexes
			local radius
			local center
			
			for i = 1, count do
				
				local pos = ent.vFireIgnitePositions[i]

				if pos then
					pos = ent:LocalToWorld(pos)
				else
					if !meshConvexes then meshConvexes = phys:GetMeshConvexes() end
					if !meshConvexes then return false end

					local convexData = table.Random(meshConvexes)

					local sumVec = Vector()
					local sum = 0
					for k, posTable in pairs(convexData) do
						local weight = math.Rand(0, 1)
						sumVec = sumVec + ent:LocalToWorld(posTable.pos) * weight
						sum = sum + weight
					end
					sumVec = sumVec / sum

					ent.vFireIgnitePositions[i] = ent:WorldToLocal(sumVec)
					pos = sumVec
				end

				if pos then
					if !radius then radius = ent:GetModelRadius() end
					if !center then center = ent:WorldSpaceCenter() end

					if radius and center then
						local vel = (center - pos) * radius
						local norm = -vel
						norm:Normalize()
						local life = math.Rand(5, 7)
						local feed = radius

						CreateVFireBall(life, feed, pos + norm * 25, vel)
					end
				end
			end

			return true
		end

		return false
	end
end

--[[-------------------------------------------------------------------------
Client-side Effects
---------------------------------------------------------------------------]]
if CLIENT then

	local function physDummyValid(c)
		return IsValid(c.dummy)
	end
	local function physDummyStep(c)
		if CurTime() > c.endTime then
			c.dummy:Remove()
		end
	end
	function CreateCSVFirePhysDummy(pos, vel, lifeTime, nocollide)

		local colGroup = COLLISION_GROUP_IN_VEHICLE
		if !nocollide then colGroup = COLLISION_GROUP_WORLD end

		local dummy = ents.CreateClientProp()
			dummy:SetNoDraw(true)
			dummy:SetModel(vFireDummyModel)
			dummy:SetPos(pos)
			dummy:PhysicsInit(SOLID_VPHYSICS)
			dummy:SetMoveType(MOVETYPE_VPHYSICS)
			dummy:SetSolid(SOLID_VPHYSICS)
			dummy:SetCollisionGroup(colGroup)
			dummy:SetAngles(AngleRand())
		dummy:Spawn()

		local phys = dummy:GetPhysicsObject()
		phys:SetVelocity(vel)
		phys:SetMaterial("gmod_silent")

		local context = {
			IsValid = physDummyValid,
			dummy = dummy,
			endTime = CurTime() + lifeTime
		}

		hook.Add("Think", context, physDummyStep)

		return dummy
	end

	local function followForceValid(c)
		return c.isValid
	end
	local function followForceStep(c)
		local curTime = CurTime()
		if curTime < c.nextRun then return end
		c.nextRun = curTime + c.frequency

		if !IsValid(c.follower) then
			c.isValid = false
			return
		end

		if c.isEntity then
			if !IsValid(c.target) then c.isValid = false return end
		end

		if curTime > c.endTime then c.isValid = false return end

		local frac1to0 = (c.endTime - curTime) / (c.lifeTime)
		local strength = c.startStrength * frac1to0 + c.endStrength * (1 - frac1to0)

		local targetPos = c.target
		if isentity(c.target) then targetPos = targetPos:GetPos() end

		local diff = targetPos - c.follower:GetPos()
		if c.normalize then diff = diff:GetNormalized() end
		c.follower:GetPhysicsObject():AddVelocity(diff * strength)
	end
	function CreateVFireFollowForce(follower, target, lifeTime, frequency, startStrength, endStrength, normalize)
		
		local startTime = CurTime()
		local endTime = CurTime() + lifeTime
		local isEntity = isentity(target)
		
		local context = {
			IsValid = followForceValid,
			isValid = true,

			isEntity = isEntity,

			nextRun = 0,
			lifeTime = lifeTime,
			startTime = startTime,
			endTime = endTime,
			frequency = frequency,

			follower = follower,
			target = target,

			startStrength = startStrength,
			endStrength = endStrength,

			normalize = normalize
		}

		followForceStep(context)

		hook.Add("Think", context, followForceStep)
	end

	function CreateVFireFireHazeParticle(pos, vel, size, dieTime, gravity, resist, roll, brightness, alpha)
		local pe = ParticleEmitter(pos)
		if (pe) then

			local p = pe:Add("effects/muzzleflash3", pos)

			p:SetLifeTime(0)
			p:SetDieTime(dieTime)
			
			p:SetStartSize(0)
			p:SetEndSize(size)

			p:SetStartAlpha(math.random(alpha / 2, alpha))
			p:SetEndAlpha(0)

			p:SetColor(brightness, brightness, brightness)
			p:SetLighting(false)
			
			p:SetVelocity(vel)
			p:SetGravity(gravity * size)
			p:SetAirResistance(resist)

			p:SetCollide(false)

			p:SetRoll(math.Rand(0, 2 * math.pi))
			p:SetRollDelta(roll)

			pe:Finish()
		end
	end

	function CreateVFireDebrisSpurt(pos, count, minDieTime, maxDieTime, minSize, maxSize, roll, vel, spread, collide)
		local pe = ParticleEmitter(pos)
		if (pe) then
			for i = 1, count do
				local p = pe:Add(table.Random(list.Get("vFireDebris")), pos)

				p:SetLifeTime(0)
				p:SetDieTime(math.Rand(minDieTime, maxDieTime))
				
				local size = math.Rand(minSize, maxSize)
				p:SetStartSize(size)
				p:SetEndSize(size)

				p:SetStartAlpha(255)
				p:SetEndAlpha(255)

				p:SetColor(255, 255, 255)
				p:SetLighting(true)
				
				p:SetVelocity(vel * math.Rand(0.5, 1) + VectorRand() * spread)
				p:SetGravity(Vector(0, 0, -750))
				p:SetAirResistance(0)

				p:SetCollide(collide)
				p:SetBounce(0.15)

				p:SetRoll(math.Rand(0, 2 * math.pi))
				p:SetRollDelta(math.Rand(-roll, roll))
			end
			pe:Finish()
		end
	end

	function CreateVFireDirtSpurt(pos, count, minDieTime, maxDieTime, minSize, maxSize, roll, vel, spread, collide)
		local pe = ParticleEmitter(pos)
		if (pe) then
			for i = 1, count do
				local p = pe:Add(table.Random(list.Get("vFireDirt")), pos)

				p:SetLifeTime(0)
				p:SetDieTime(math.Rand(minDieTime, maxDieTime))
				
				local size = math.Rand(minSize, maxSize)
				p:SetStartSize(0)
				p:SetEndSize(size)

				p:SetStartAlpha(255)
				p:SetEndAlpha(0)

				p:SetColor(255, 255, 255)
				p:SetLighting(true)
				
				p:SetVelocity(vel * math.Rand(0.5, 1) + VectorRand() * spread)
				p:SetGravity(Vector(0, 0, -750))
				p:SetAirResistance(0)

				p:SetCollide(collide)
				p:SetBounce(0.15)

				p:SetRoll(math.Rand(0, 2 * math.pi))
				p:SetRollDelta(math.Rand(-roll, roll))
			end
			pe:Finish()
		end
	end

	function CreateVFireSparksSpurt(pos, count, minDieTime, maxDieTime, minSize, maxSize, roll, vel, spread, resistance)
		local pe = ParticleEmitter(pos)
		if (pe) then
			for i = 1, count do
				local p = pe:Add("effects/yellowflare", pos)

				p:SetLifeTime(0)
				p:SetDieTime(math.Rand(minDieTime, maxDieTime))
				
				local size = math.Rand(minSize, maxSize)
				p:SetStartSize(size)
				p:SetEndSize(0)

				p:SetStartAlpha(255)
				p:SetEndAlpha(255)

				p:SetColor(255, 255, 255)
				p:SetLighting(false)
				
				p:SetVelocity(vel * math.Rand(0.5, 1) + VectorRand() * spread)
				p:SetGravity(Vector(0, 0, -750))
				p:SetAirResistance(resistance)

				p:SetCollide(collide)

				p:SetRoll(math.Rand(0, 2 * math.pi))
				p:SetRollDelta(math.Rand(-roll, roll))
			end
			pe:Finish()
		end
	end

	function CreateVFireShockwave(pos, magnitude, particleCount)
		local pe = ParticleEmitter(pos)
		if (pe) then

			local bubble = pe:Add("particle/particle_ring_wave_8", pos)

			local dieTime = math.sqrt(magnitude * 0.01) / 2
			bubble:SetLifeTime(0)
			bubble:SetDieTime(dieTime)
			
			local endSize = dieTime * 36000
			bubble:SetStartSize(0)
			bubble:SetEndSize(endSize)

			local alpha = math.max(math.tanh((magnitude - 7) / 20) * 255, 0)
			bubble:SetStartAlpha(alpha)
			bubble:SetEndAlpha(0)

			bubble:SetColor(128, 128, 128)
			bubble:SetLighting(false)
			
			bubble:SetVelocity(Vector())
			bubble:SetGravity(Vector())
			bubble:SetAirResistance(10000)

			bubble:SetCollide(false)

			bubble:SetRoll(math.Rand(0, 2 * math.pi))
			local rollDelta = 10
			bubble:SetRollDelta(math.Rand(-rollDelta, rollDelta))

			local kick = pe:Add("particle/smokestack", pos)
			kick:SetLifeTime(0)
			kick:SetDieTime(dieTime * 1.5)
			
			kick:SetStartSize(0)
			kick:SetEndSize(endSize * 1.5)

			kick:SetStartAlpha(alpha * 0.75)
			kick:SetEndAlpha(0)

			kick:SetColor(128, 128, 128)
			kick:SetLighting(false)
			
			kick:SetVelocity(Vector())
			kick:SetGravity(Vector())
			kick:SetAirResistance(1)

			kick:SetCollide(false)

			kick:SetRoll(math.Rand(0, 2 * math.pi))
			kick:SetRollDelta(math.Rand(-rollDelta, rollDelta) * 0.5)

			pe:Finish()
		end
	end

	function CreateVFireSmokeParticle(pos, vel, size, dieTime, gravity, resist, roll, brightness, alpha)

		local pe = ParticleEmitter(pos)
		if (pe) then

			local p = pe:Add(table.Random(list.Get("vFireSmoke")), pos)

			p:SetLifeTime(0)
			p:SetDieTime(dieTime)
			
			p:SetStartSize(0)
			p:SetEndSize(size)

			p:SetStartAlpha(alpha)
			p:SetEndAlpha(0)

			p:SetColor(brightness, brightness, brightness)
			p:SetLighting(true)
			
			p:SetVelocity(vel)
			p:SetGravity(gravity * size)
			p:SetAirResistance(size * resist)

			p:SetCollide(false)

			p:SetRoll(math.Rand(0, 2 * math.pi))
			p:SetRollDelta(roll * 900 / size)

			pe:Finish()
		end
	end

	local function explosionTrailValid(c)
		if c.reps <= 0 then return false end
		if c.isEntity and !IsValid(c.follow) then return false end
		return true
	end
	local function explosionTrailStep(c)
		local curTime = CurTime()
		if curTime < c.nextRun then return end
		c.nextRun = curTime + c.interval

			local pos
			if c.isEntity then
				pos = c.follow:GetPos()
			else
				pos = c.follow
			end

			local radiusOffset = VectorRand() * math.Rand(c.minRadius or 0, c.maxRadius or 0)

			local particleString
			if c.bigBurst then
				particleString = "vFire_Burst_Main_Big"
			else
				particleString = "vFire_Burst_Main"
			end
			ParticleEffect(particleString, pos + radiusOffset, Angle())

		c.reps = c.reps - 1	
	end
	function CreateVFireExplosionTrail(follow, lifeTime, interval, bigBurst, minRadius, maxRadius)
		
		local isEntity = isentity(follow)

		if isEntity and !IsValid(follow) then return end

		local reps = math.floor(lifeTime / interval, 0)
		
		local context = {
			IsValid = explosionTrailValid,
			interval = interval,
			reps = reps,
			nextRun = 0,
			
			follow = follow,
			isEntity = isEntity,

			bigBurst = bigBurst,
			minRadius = minRadius,
			maxRadius = maxRadius
		}

		explosionTrailStep(context)

		hook.Add("Think", context, explosionTrailStep)
	end

	local function smokeTrailValid(c)
		if c.reps <= 0 then return false end
		if c.isEntity and !IsValid(c.follow) then return false end
		return true
	end
	local function smokeTrailStep(c)
		local curTime = CurTime()
		if curTime < c.nextRun then return end
		c.nextRun = curTime + c.interval
		
			local size = c.startRadius * (1 - c.frac) + c.endRadius * c.frac

			local dieTime
			if c.dieTimeNoise then
				dNoise = math.Rand(-c.dieTimeNoise, c.dieTimeNoise)
				local dFrc = math.Clamp(c.frac + dNoise, 0, 1)
				dieTime = c.startLength * (1 - dFrc) + c.endLength * dFrc
			else
				dieTime = c.startLength * (1 - c.frac) + c.endLength * c.frac
			end
			
			local brightness = math.random(c.minBright, c.maxBright)
			local alpha = math.random(c.minAlpha, c.maxAlpha)
			local pos, vel
			if c.isEntity then
				vel = c.follow:GetVelocity()
				pos = c.follow:GetPos()
			else
				pos = c.follow
				vel = Vector()
			end

			c.frac = c.frac + c.fracAdd

			local roll = math.Rand(c.minRoll, c.maxRoll)

			CreateVFireSmokeParticle(pos, vel, size, dieTime, c.gravity, c.resist, roll, brightness, alpha)

		c.reps = c.reps - 1	
	end
	function CreateVFireSmokeTrail(follow, lifeTime, interval, startRadius, endRadius, startLength, endLength, gravity, resist, minRoll, maxRoll, minBright, maxBright, minAlpha, maxAlpha, dieTimeNoise, delay)
		
		local isEntity = isentity(follow)

		if isEntity and !IsValid(follow) then return end

		local reps = math.ceil(lifeTime / interval)
		local frac, fracAdd = 0, 1 / reps

		delay = delay or 0
		
		local context = {
			IsValid = smokeTrailValid,
			interval = interval,
			reps = reps,
			nextRun = CurTime() + delay,
			
			isEntity = isEntity,
			frac = frac,
			fracAdd = fracAdd,
			follow = follow,
			startRadius = startRadius,
			endRadius = endRadius,
			startLength = startLength,
			endLength = endLength,
			gravity = gravity,
			resist = resist,
			minRoll = minRoll,
			maxRoll = maxRoll,
			minBright = minBright,
			maxBright = maxBright,
			minAlpha = minAlpha,
			maxAlpha = maxAlpha,
			dieTimeNoise = dieTimeNoise
		}

		smokeTrailStep(context)

		hook.Add("Think", context, smokeTrailStep)
	end

	local function fireTrailValid(c)
		if c.reps <= -1 then return false end
		if c.isEntity and !IsValid(c.attach) then return false end
		return true
	end
	local function fireTrailStep(c)

		local curTime = CurTime()
		if curTime < c.nextRun then return end
		c.nextRun = curTime + c.interval

		if IsValid(c.trailFlames) then
			c.trailFlames:StopEmission()
		end

		if c.reps > 0 then
			c.trailFlames = CreateParticleSystem(
				c.attach,
				"vFire_Flames_"..vFireStateToSize(c.state)..c.LODStr,
				1,
				0,
				c.attachPos
			)

			if c.pullPos then
				vFirePullParticlesToPos(c.trailFlames, c.pullPos)
			end
		end

		c.reps = c.reps - 1
		c.state = c.state + c.add
	end
	function CreateVFireTrail(follow, startLife, endLife, lifeTime, canLOD, pullPos)

		local isEntity = isentity(follow)

		local LODStr = ""
		if canLOD == nil then
			LODStr = "_LOD"
		else
			if canLOD and vFireGetLOD(follow) == 1 then
				LODStr = "_LOD"
			end
		end
		
		local state = vFireLifeToState(startLife)
		local targetState = vFireLifeToState(endLife)
		local reps = math.max(math.abs(state - targetState), 1) + 1
		local interval = lifeTime / reps

		local attach, attachPos
		if !isEntity then
			attach = game.GetWorld()
			attachPos = follow
		else
			attach = follow
			attachPos = Vector()
		end

		local add = 0
		if targetState < state then add = -1 end
		if targetState > state then add = 1 end

		local context = {
			IsValid = fireTrailValid,
			interval = interval,
			reps = reps,
			nextRun = 0,
			add = add,

			state = state,
			targetState = targetState,
			attach = attach,
			attachPos = attachPos,
			isEntity = isEntity,
			trailFlames = nil,
			LODStr = LODStr,
			pullPos = pullPos
		}

		fireTrailStep(context)

		hook.Add("Think", context, fireTrailStep)
	end

	local function dynamicLightValid(c)
		if CurTime() > c.endTime then return false end
		if c.isEntity and !IsValid(c.follow) then return false end
		return true
	end
	local function dynamicLightStep(c)

		local attachPos
		if !c.isEntity then
			attachPos = c.follow
		else
			attachPos = c.follow:GetPos()
		end

		local curTime = CurTime()
		local frac = (c.endTime - curTime) / (c.lifeTime)
		local fracRev = 1 - frac

		local yellowness = c.startYellowness * frac + c.endYellowness * fracRev
		local glowSize = c.startSize * frac + c.endSize * fracRev

		local d = DynamicLight(c.lightID)
		if d then
			d.pos = attachPos
			d.r = 255 * frac
			d.g = yellowness * frac
			d.b = c.blue * frac
			d.brightness = c.brightness
			d.decay = 0
			d.size = glowSize
			d.dietime = CurTime() + c.dieTime
		end
	end
	local vFireLightAttachID = 5000
	function CreateVFireDynamicLight(follow, lifeTime, brightness, startSize, endSize, dieTime, startYellowness, endYellowness, blue)
		do return end
		local isEntity = isentity(follow)

		local startTime = CurTime()
		local endTime = startTime + lifeTime

		local context = {
			IsValid = dynamicLightValid,
			isEntity = isEntity,
			follow = follow,
			startTime = startTime,
			endTime = endTime,
			lifeTime = lifeTime,
			startSize = startSize,
			endSize = endSize,
			startYellowness = startYellowness,
			endYellowness = endYellowness,
			blue = blue,
			brightness = brightness,
			dieTime = dieTime,
			lightID = vFireLightAttachID
		}

		dynamicLightStep(context)

		hook.Add("Think", context, dynamicLightStep)

		vFireLightAttachID = vFireLightAttachID + 1
	end

	local glowSpriteMat = Material("sprites/physg_glow1")
	local glowSpriteMatNoZ = Material("sprites/light_ignorez")
	local function glowSpriteValid(c)
		if CurTime() > c.endTime then return false end
		if c.isEntity and !IsValid(c.follow) then return false end
		return true
	end
	local function glowSpriteStep(c)

		local attachPos
		if !c.isEntity then
			attachPos = c.follow
		else
			attachPos = c.follow:GetPos()
		end

		local curTime = CurTime()
		local frac = (c.endTime - curTime) / (c.lifeTime)
		local fracRev = 1 - frac

		local alpha = c.startAlpha * frac + c.endAlpha * fracRev
		local yellowness = c.startYellowness * frac + c.endYellowness * fracRev
		local glowCol = Color(255, yellowness, c.blue, alpha)
		local glowSize = c.startSize * frac + c.endSize * fracRev

		if c.pixvis then
			local vis = util.PixelVisible(attachPos, 1, c.pixvis)
			if vis <= 0 then return end
			glowSize = glowSize * vis
			render.SetMaterial(glowSpriteMatNoZ)
		else
			render.SetMaterial(glowSpriteMat)
		end
		render.DrawSprite(attachPos, glowSize, glowSize, glowCol)
	end
	function CreateVFireGlowSprite(follow, lifeTime, startSize, endSize, startAlpha, endAlpha, startYellowness, endYellowness, blue, drawThroughEffects, usePixVis)

		local isEntity = isentity(follow)

		local startTime = CurTime()
		local endTime = startTime + lifeTime

		local pixvis
		if usePixVis then
			pixvis = util.GetPixelVisibleHandle()
		end

		local context = {
			IsValid = glowSpriteValid,
			isEntity = isEntity,
			follow = follow,
			startTime = startTime,
			endTime = endTime,
			lifeTime = lifeTime,
			startSize = startSize,
			endSize = endSize,
			startAlpha = startAlpha,
			endAlpha = endAlpha,
			startYellowness = startYellowness,
			endYellowness = endYellowness,
			blue = blue,
			pixvis = pixvis
		}

		if drawThroughEffects then
			hook.Add("PostDrawTranslucentRenderables", context, glowSpriteStep)
		else
			hook.Add("PreDrawTranslucentRenderables", context, glowSpriteStep)
		end
	end

	function CreateCSVFireSmokeBall(pos, vel, lifeTime, rate, startRadius, endRadius, startLength, endLength, gravity, resist, roll, minBright, maxBright, minAlpha, maxAlpha)
		local dummy = CreateCSVFirePhysDummy(pos, vel, lifeTime)
		
		CreateVFireSmokeTrail(
			dummy,
			lifeTime,
			rate,
			startRadius,
			endRadius,
			startLength,
			endLength,
			gravity,
			resist,
			roll,
			minBright,
			maxBright,
			minAlpha,
			maxAlpha
		)

		return dummy
	end

	function CreateCSVFireBall(life, pos, vel, lifeTime, canLOD)

		local dummy = CreateCSVFirePhysDummy(pos, vel, lifeTime)

		if dummy:WaterLevel() > 0 then dummy:Remove() return end

		CreateVFireTrail(dummy, life, 0, lifeTime, canLOD)

		return dummy
	end

	local mushRoomID = 0
	function CreateVFireMushroom(pos, levels, ranDelay, spread, smokeFactor, startVel, span)

		if levels <= 0 then return end

		mushRoomID = mushRoomID + 1
		local timerID = "vFireMushroom"..mushRoomID

		if !startVel then startVel = VectorRand() end

		local follow = pos
		local startLife = vFireMaxLife
		local endLife = vFireMaxLife
		local lifeTime = 0.2 + math.Rand(0, ranDelay)
		local canLOD = true
		CreateVFireTrail(follow, startLife, endLife, lifeTime, canLOD)

		if math.Rand(0, 1) < smokeFactor / levels then
			CreateVFireSmokeTrail(
				follow,
				lifeTime,
				1,
				1000,
				100,
				lifeTime * 10,
				0.5,
				vFireGetWindVector() * math.Rand(1, 5) + Vector(0, 0, math.Rand(2, 6)),
				1,
				0.5,
				0,
				100,
				60,
				255
			)
		end

		levels = levels - 1
		if levels <= 0 then return end

		local size = 300 + 150 * levels
		timer.Simple(math.Rand(0, ranDelay), function()
			local newPos = follow + startVel * size
			local ranVector, ranVector2, newVel, newVel2
			if span then
				ranVector = Vector(span.x * math.Rand(-1, 1), span.y * math.Rand(-1, 1), span.z * math.Rand(-1, 1))
				ranVector2 = Vector(span.x * math.Rand(-1, 1), span.y * math.Rand(-1, 1), span.z * math.Rand(-1, 1))
				ranVector:Normalize()
				ranVector2:Normalize()
			else
				ranVector = VectorRand()
				ranVector2 = VectorRand()
			end
			local newVel = (startVel + ranVector * spread) / (1 + spread)
			local newVel2 = (startVel + ranVector2 * spread) / (1 + spread)
			local newSpread = spread * 0.9
			CreateVFireMushroom(newPos, levels, ranDelay, newSpread, smokeFactor, newVel, span)
			CreateVFireMushroom(newPos, levels - 1, ranDelay, newSpread, smokeFactor, newVel2, span)
		end)
	end

	function CreateVFireExplosionEffect(pos, magnitude)
		local magnitudeSqrd = magnitude * magnitude
		local canLOD = true

		for i = 1, math.random(1, 4) * magnitude do
			local life = math.Rand(1, 5) * magnitudeSqrd
			local vel = VectorRand() * (50 + math.Rand(90, 325) * magnitude)
			local lifeTime = 0.3 + math.Rand(0.05, 0.3) * magnitude
			CreateCSVFireBall(life, pos, vel, lifeTime, canLOD)
		end

		local life = magnitudeSqrd * math.Rand(40, 150)
		local vel = VectorRand() * math.Rand(0, 30)
		local lifeTime = math.Rand(0.6, 1.8) + 0.4 * magnitude
		CreateCSVFireBall(life, pos, vel, lifeTime, canLOD)
	end

	function CreateVFireSmokePlume(pos, dir, magnitude, entity)
		local effectData = EffectData()
			effectData:SetOrigin(pos)
			effectData:SetNormal(dir)
			effectData:SetMagnitude(magnitude)
			effectData:SetEntity(entity)
		util.Effect("vfire_smoke_plume", effectData, true, true)
	end

end

--[[-------------------------------------------------------------------------
Hooks to suppress default ignites
---------------------------------------------------------------------------]]
if SERVER then

	local defaultFireRemoveTime = 0.1

	hook.Add("EntityEmitSound", "vFireSuppressDefaultIngiteSound", function(data)
		local ent = data.Entity
		if IsValid(ent) then
			if ent:GetClass() == "entityflame" then return false end
		end
	end)
	hook.Add("OnEntityCreated", "vFireRemoveDefaultFires", function(oldFire)
		if !vFireGetIgniteOverride() then return end

		if oldFire:GetClass() != "entityflame" then return end
		timer.Simple(defaultFireRemoveTime, function()
			if IsValid(oldFire) then
				oldFire:Remove()
			end
		end)
	end)

	--[[-------------------------------------------------------------------------
	Have fires fall off of dying players
	---------------------------------------------------------------------------]]
	hook.Add("PlayerDeath", "vFireDropFiresFromPlayer", function(ply)
		if ply.fires then
			for fire, pos in pairs(ply.fires) do
				if IsValid(fire) then
					local fireBall = fire:Drop()
					if !IsValid(fireBall) then
						fire:Remove()
					end
				end
			end
		end
	end)

	--[[-------------------------------------------------------------------------
	Make sure players are no longer buning after a respawn
	---------------------------------------------------------------------------]]
	hook.Add("PlayerSpawn", "vFireRemoveFiresFromPlayer", function(ply)
		if ply.fires then
			for fire, pos in pairs(ply.fires) do
				fire:Remove()
			end
		end
	end)

	--[[-------------------------------------------------------------------------
	Handle fires of a burning NPC's death
	---------------------------------------------------------------------------]]
	hook.Add("OnNPCKilled", "vFireDropFiresFromNPC", function(npc, attacker, inflictor)
		if npc.fires then
			for fire, pos in pairs(npc.fires) do
				if IsValid(fire) then
					local fireBall = fire:Drop()
					if IsValid(fireBall) then
						fireBall:Ignore(npc)
					else
						fire:Remove()
					end
				end
			end
		end
	end)

	--[[-------------------------------------------------------------------------
	Handle fires on props that break
	---------------------------------------------------------------------------]]
	hook.Add("PropBreak", "vFireDropFiresFromProp", function(attacker, prop)
		if prop.fires then
			for fire, pos in pairs(prop.fires) do
				if IsValid(fire) then
					fire:ChangeLife(fire.life * 1.15)
					fire:Drop()
				end
			end
		end
	end)

	--[[-------------------------------------------------------------------------
	Fix fire dependent entities' behaviors
	---------------------------------------------------------------------------]]
	hook.Add("EntityTakeDamage", "vFireFixExplosion", function(ent, dmg)

		if hook.Call("vFireSuppressExplosionBehavior") then return end

		if !dmg:IsExplosionDamage() then return end
		local hp = ent:Health()
		if hp < dmg:GetDamage() and hp > 0 then
			if math.random(1, 3) == 1 then
				ent:SetHealth(0)
			end
		end
	end)

	--[[-------------------------------------------------------------------------
	Create fire balls from explosions
	---------------------------------------------------------------------------]]
	local IsValid = IsValid
	local math_random = math.random
	local math_Rand = math.Rand
	local VectorRand = VectorRand
	local hook_Call = hook.Call
	local CreateVFireBall = CreateVFireBall

	hook.Add("AcceptInput", "vFireFireBallByExplosion", function(explosion, name)
	    if explosion:GetClass() ~= "env_explosion" then return end
	    if not vFireEnableExplosionFires then return end
	    if name ~= "Explode" then return end

	    if hook_Call("vFireSuppressExplosionBehavior") then return end
	    local count
	    if game.SinglePlayer() then
	        count = math_random(3, 5)
	    else
	        count = math_random(2, 3)
	    end

	    local pos = explosion:GetPos()

	    for i = 1, count do
	        local life = math_Rand(10, 50)
	        local feed = life / 200
	        if math_random(1, 10) == 1 then
	            feed = feed * 6
	        end
	        local vel = VectorRand() * math_Rand(20000, 80000) / life
	        CreateVFireBall(life, feed, pos, vel)
	    end
	end)

	--[[-------------------------------------------------------------------------
	Support ignite calls via inputs
	---------------------------------------------------------------------------]]
	hook.Add("AcceptInput", "vFireIgniteByInput", function(ent, name)
		if (name != "Ignite") then return end
		vFireIgniteOverride(true)
		ent:Ignite()
	end)

	--[[-------------------------------------------------------------------------
	NPC Behaviors
	---------------------------------------------------------------------------]]
	local NPCOnFireActs = {
		61, -- ACT_COWER
		125, -- ACT_IDLE_ON_FIRE
		126, -- ACT_WALK_ON_FIRE
		127, -- ACT_RUN_ON_FIRE
	}

	local NPCClassAvailableFireActs = {}

	function StopNPCBurningBehavior(npc)
		npc:SetSchedule(0)
	end

	function NPCBurningBehavior(npc, behavior, fireAct)
		if !IsValid(npc) then return end
		if !npc.isBurning then return end
		if !vFireEnableNPCBehavior then return end

		local nextCall = 3.5

		if behavior == 1 then
			npc:SetCurrentWeaponProficiency(1)

			if math.random(1, 8) == 1 then
				npc:SetEnemy(npc)
			end
			
			if math.random(1, 3) == 1 then
				npc:SetSchedule(SCHED_DIE_RAGDOLL)
			end

			timer.Simple(0.1, function()
				if !IsValid(npc) then return end
				npc:SetSchedule(SCHED_RUN_RANDOM)
			end)

			nextCall = math.Rand(1, 2)

		elseif behavior == 2 then
			
			if !npc.lastSound or math.random(1, 10) == 1 then
				npc:SetSchedule(SCHED_DIE_RAGDOLL)
			end

			timer.Simple(0.1, function()
				if !IsValid(npc) then return end
				npc:SetSchedule(77)

				vFireIgniteOverride(false)
					npc:Ignite(defaultFireRemoveTime)
				vFireIgniteOverride(true)
			end)

			nextCall = math.Rand(3, 14)

		elseif behavior == 3 then

			if math.random(1, 1) == 1 then
				npc:SetSchedule(SCHED_DIE_RAGDOLL)
			end

			timer.Simple(0.1 , function()

				if !IsValid(npc) then return end

				local class = npc:GetClass()
				if !NPCClassAvailableFireActs[class] then
					local availableFireActs = {}
					for k, actID in pairs(NPCOnFireActs) do
						local seqID = npc:SelectWeightedSequence(actID)
						if seqID != -1 then
							availableFireActs[#availableFireActs + 1] = {actID, seqID}
						end
					end
					NPCClassAvailableFireActs[class] = availableFireActs
				end

				if !fireAct then fireAct = table.Random(NPCClassAvailableFireActs[class]) end

				if fireAct then
					local actID = fireAct[1]
					local seqID = fireAct[2]

					npc:SetMovementActivity(actID)
					npc:SetMovementSequence(seqID)
				end
			end)

			nextCall = math.Rand(1, 2)
		end

		timer.Simple(nextCall, function()
			NPCBurningBehavior(npc, behavior, fireAct)
		end)
	end

	local defaultNPCs = {}
	defaultNPCs["npc_crow"] = true
	defaultNPCs["npc_monk"] = true
	defaultNPCs["npc_pigeon"] = true
	defaultNPCs["npc_seagull"] = true
	defaultNPCs["npc_cscanner"] = true
	defaultNPCs["npc_combinedropship"] = true
	defaultNPCs["npc_combine_s"] = true
	defaultNPCs["npc_combinegunship"] = true
	defaultNPCs["npc_hunter"] = true
	defaultNPCs["npc_helicopter"] = true
	defaultNPCs["npc_manhack"] = true
	defaultNPCs["npc_metropolice"] = true
	defaultNPCs["npc_rollermine"] = true
	defaultNPCs["npc_clawscanner"] = true
	defaultNPCs["npc_stalker"] = true
	defaultNPCs["npc_strider"] = true
	defaultNPCs["bullseye_strider_focus"] = true
	defaultNPCs["npc_turret_floor"] = true
	defaultNPCs["npc_alyx"] = true
	defaultNPCs["npc_barney"] = true
	defaultNPCs["npc_citizen"] = true
	defaultNPCs["npc_dog"] = true
	defaultNPCs["npc_magnusson"] = true
	defaultNPCs["npc_kleiner"] = true
	defaultNPCs["npc_mossman"] = true
	defaultNPCs["npc_eli"] = true
	defaultNPCs["npc_gman"] = true
	defaultNPCs["npc_vortigaunt"] = true
	defaultNPCs["npc_breen"] = true
	defaultNPCs["npc_antlion"] = true
	defaultNPCs["npc_antlionguard"] = true
	defaultNPCs["npc_antlion_worker"] = true
	defaultNPCs["npc_headcrab_fast"] = true
	defaultNPCs["npc_fastzombie"] = true
	defaultNPCs["npc_fastzombie_torso"] = true
	defaultNPCs["npc_headcrab"] = true
	defaultNPCs["npc_headcrab_black"] = true
	defaultNPCs["npc_poisonzombie"] = true
	defaultNPCs["npc_headcrab_poison"] = true
	defaultNPCs["npc_zombie"] = true
	defaultNPCs["npc_zombie_torso"] = true
	defaultNPCs["npc_zombine"] = true

	local function shouldDoBehavior(npc)
		if !IsValid(npc) then return false end
		if npc.vFireCustomBehavior != nil then return npc.vFireCustomBehavior end
		local class = npc:GetClass()
		
		npc.vFireCustomBehavior = defaultNPCs[class] or false
		
		return npc.vFireCustomBehavior
	end

	hook.Add("vFireEntityStoppedBurning", "vFireStopNPCBurningBehavior", function(npc)
		if !IsValid(npc) then return end
		if !npc:IsNPC() then return end
		if !vFireEnableDamage then return end
		if !vFireEnableNPCBehavior then return end
		if !shouldDoBehavior(npc) then return end

		npc.isBurning = false
		StopNPCBurningBehavior(npc)
	end)
	
	hook.Add("vFireEntityStartedBurning", "vFireStartNPCBurningBehavior", function(npc)
		if !IsValid(npc) then return end
		if !npc:IsNPC() then return end
		if !vFireEnableDamage then return end
		if !vFireEnableNPCBehavior then return end
		if !shouldDoBehavior(npc) then return end
		
		npc.isBurning = true

		local behavior = 2
		NPCBurningBehavior(npc, behavior)
	end)

end

--[[-------------------------------------------------------------------------
Content Loading
---------------------------------------------------------------------------]]

if SERVER then
	resource.AddWorkshop("1525218777")
end

game.AddParticles("particles/vFire_Base_Tiny.pcf")
game.AddParticles("particles/vFire_Base_Small.pcf")
game.AddParticles("particles/vFire_Base_Medium.pcf")
game.AddParticles("particles/vFire_Base_Big.pcf")
game.AddParticles("particles/vFire_Base_Huge.pcf")
game.AddParticles("particles/vFire_Base_Gigantic.pcf")
game.AddParticles("particles/vFire_Base_Inferno.pcf")

game.AddParticles("particles/vFire_Base_Tiny_LOD.pcf")
game.AddParticles("particles/vFire_Base_Small_LOD.pcf")
game.AddParticles("particles/vFire_Base_Medium_LOD.pcf")
game.AddParticles("particles/vFire_Base_Big_LOD.pcf")
game.AddParticles("particles/vFire_Base_Huge_LOD.pcf")
game.AddParticles("particles/vFire_Base_Gigantic_LOD.pcf")
game.AddParticles("particles/vFire_Base_Inferno_LOD.pcf")

game.AddParticles("particles/vFire_Flames_Tiny.pcf")
game.AddParticles("particles/vFire_Flames_Small.pcf")
game.AddParticles("particles/vFire_Flames_Medium.pcf")
game.AddParticles("particles/vFire_Flames_Big.pcf")
game.AddParticles("particles/vFire_Flames_Huge.pcf")
game.AddParticles("particles/vFire_Flames_Gigantic.pcf")
game.AddParticles("particles/vFire_Flames_Inferno.pcf")

game.AddParticles("particles/vFire_Flames_Tiny_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Small_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Medium_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Big_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Huge_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Gigantic_LOD.pcf")
game.AddParticles("particles/vFire_Flames_Inferno_LOD.pcf")

game.AddParticles("particles/vFire_Burst_Infant.pcf")
game.AddParticles("particles/vFire_Burst_Lines.pcf")
game.AddParticles("particles/vFire_Burst_Main.pcf")
game.AddParticles("particles/vFire_Burst_Main_Big.pcf")
game.AddParticles("particles/vFire_Burst_Plume.pcf")
game.AddParticles("particles/vFire_Burst_Trail.pcf")
game.AddParticles("particles/vFire_Burst_Trail_Plume.pcf")

PrecacheParticleSystem("vFire_Base_Tiny")
PrecacheParticleSystem("vFire_Base_Small")
PrecacheParticleSystem("vFire_Base_Medium")
PrecacheParticleSystem("vFire_Base_Big")
PrecacheParticleSystem("vFire_Base_Huge")
PrecacheParticleSystem("vFire_Base_Gigantic")
PrecacheParticleSystem("vFire_Base_Inferno")

PrecacheParticleSystem("vFire_Base_Tiny_LOD")
PrecacheParticleSystem("vFire_Base_Small_LOD")
PrecacheParticleSystem("vFire_Base_Medium_LOD")
PrecacheParticleSystem("vFire_Base_Big_LOD")
PrecacheParticleSystem("vFire_Base_Huge_LOD")
PrecacheParticleSystem("vFire_Base_Gigantic_LOD")
PrecacheParticleSystem("vFire_Base_Inferno_LOD")

PrecacheParticleSystem("vFire_Flames_Tiny")
PrecacheParticleSystem("vFire_Flames_Small")
PrecacheParticleSystem("vFire_Flames_Medium")
PrecacheParticleSystem("vFire_Flames_Big")
PrecacheParticleSystem("vFire_Flames_Huge")
PrecacheParticleSystem("vFire_Flames_Gigantic")
PrecacheParticleSystem("vFire_Flames_Inferno")

PrecacheParticleSystem("vFire_Flames_Tiny_LOD")
PrecacheParticleSystem("vFire_Flames_Small_LOD")
PrecacheParticleSystem("vFire_Flames_Medium_LOD")
PrecacheParticleSystem("vFire_Flames_Big_LOD")
PrecacheParticleSystem("vFire_Flames_Huge_LOD")
PrecacheParticleSystem("vFire_Flames_Gigantic_LOD")
PrecacheParticleSystem("vFire_Flames_Inferno_LOD")

PrecacheParticleSystem("vFire_Burst_Infant")
PrecacheParticleSystem("vFire_Burst_Lines")
PrecacheParticleSystem("vFire_Burst_Main")
PrecacheParticleSystem("vFire_Burst_Main_Big")
PrecacheParticleSystem("vFire_Burst_Plume")
PrecacheParticleSystem("vFire_Burst_Trail")
PrecacheParticleSystem("vFire_Burst_Trail_Plume")

--[[-------------------------------------------------------------------------
Loop sounds
---------------------------------------------------------------------------]]
list.Add("vFireLoopSounds", "ambient/fire/firebig.wav")
list.Add("vFireLoopSounds", "ambient/fire/fire_big_loop1.wav")
list.Add("vFireLoopSounds", "ambient/fire/fire_med_loop1.wav")
list.Add("vFireLoopSounds", "ambient/fire/fire_small1.wav")
list.Add("vFireLoopSounds", "ambient/fire/fire_small_loop2.wav")

--[[-------------------------------------------------------------------------
Decal loading
---------------------------------------------------------------------------]]
list.Add("VScorches_Tiny", "Decals/vFireScorch1_Tiny")
list.Add("VScorches_Tiny", "Decals/vFireScorch2_Tiny")
list.Add("VScorches_Tiny", "Decals/vFireScorch3_Tiny")
list.Add("VScorches_Tiny", "Decals/vFireScorch4_Tiny")
list.Add("VScorches_Tiny", "Decals/vFireScorch5_Tiny")
game.AddDecal("VScorch_Tiny", list.Get("VScorches_Tiny"))

list.Add("VScorches_Small", "Decals/vFireScorch1_Small")
list.Add("VScorches_Small", "Decals/vFireScorch2_Small")
list.Add("VScorches_Small", "Decals/vFireScorch3_Small")
list.Add("VScorches_Small", "Decals/vFireScorch4_Small")
list.Add("VScorches_Small", "Decals/vFireScorch5_Small")
game.AddDecal("VScorch_Small", list.Get("VScorches_Small"))

list.Add("VScorches_Medium", "Decals/vFireScorch1_Medium")
list.Add("VScorches_Medium", "Decals/vFireScorch2_Medium")
list.Add("VScorches_Medium", "Decals/vFireScorch3_Medium")
list.Add("VScorches_Medium", "Decals/vFireScorch4_Medium")
list.Add("VScorches_Medium", "Decals/vFireScorch5_Medium")
game.AddDecal("VScorch_Medium", list.Get("VScorches_Medium"))

list.Add("VScorches_Big", "Decals/vFireScorch1_Big")
list.Add("VScorches_Big", "Decals/vFireScorch2_Big")
list.Add("VScorches_Big", "Decals/vFireScorch3_Big")
list.Add("VScorches_Big", "Decals/vFireScorch4_Big")
list.Add("VScorches_Big", "Decals/vFireScorch5_Big")
game.AddDecal("VScorch_Big", list.Get("VScorches_Big"))

list.Add("VScorches_Huge", "Decals/vFireScorch1_Huge")
list.Add("VScorches_Huge", "Decals/vFireScorch2_Huge")
list.Add("VScorches_Huge", "Decals/vFireScorch3_Huge")
list.Add("VScorches_Huge", "Decals/vFireScorch4_Huge")
list.Add("VScorches_Huge", "Decals/vFireScorch5_Huge")
game.AddDecal("VScorch_Huge", list.Get("VScorches_Huge"))

list.Add("VScorches_Gigantic", "Decals/vFireScorch1_Gigantic")
list.Add("VScorches_Gigantic", "Decals/vFireScorch2_Gigantic")
list.Add("VScorches_Gigantic", "Decals/vFireScorch3_Gigantic")
list.Add("VScorches_Gigantic", "Decals/vFireScorch4_Gigantic")
list.Add("VScorches_Gigantic", "Decals/vFireScorch5_Gigantic")
game.AddDecal("VScorch_Gigantic", list.Get("VScorches_Gigantic"))

list.Add("VScorches_Inferno", "Decals/vFireScorch1_Inferno")
list.Add("VScorches_Inferno", "Decals/vFireScorch2_Inferno")
list.Add("VScorches_Inferno", "Decals/vFireScorch3_Inferno")
list.Add("VScorches_Inferno", "Decals/vFireScorch4_Inferno")
list.Add("VScorches_Inferno", "Decals/vFireScorch5_Inferno")
game.AddDecal("VScorch_Inferno", list.Get("VScorches_Inferno"))

if CLIENT then
	hook.Add("InitPostEntity", "vFireEditDecals", function()
		for s = 1, vFireMaxState do
			local sizeStr = vFireStateToSize(s)
			for i = 1, 5 do
				local matName = "Decals/vFireScorch"..i.."_"..sizeStr
				local mat = Material(matName)
				mat:SetFloat("$decalscale", s * s * 0.04)
				mat:Recompute()
			end
		end
	end)
end

list.Add("vFireSmoke", "particle/smokesprites_0001")
list.Add("vFireSmoke", "particle/smokesprites_0002")
list.Add("vFireSmoke", "particle/smokesprites_0003")
list.Add("vFireSmoke", "particle/smokesprites_0004")
list.Add("vFireSmoke", "particle/smokesprites_0005")
list.Add("vFireSmoke", "particle/smokesprites_0006")
list.Add("vFireSmoke", "particle/smokesprites_0007")
list.Add("vFireSmoke", "particle/smokesprites_0008")
list.Add("vFireSmoke", "particle/smokesprites_0009")
list.Add("vFireSmoke", "particle/smokesprites_0010")
list.Add("vFireSmoke", "particle/smokesprites_0011")
list.Add("vFireSmoke", "particle/smokesprites_0012")
list.Add("vFireSmoke", "particle/smokesprites_0013")
list.Add("vFireSmoke", "particle/smokesprites_0014")
list.Add("vFireSmoke", "particle/smokesprites_0015")
list.Add("vFireSmoke", "particle/smokesprites_0016")
list.Add("vFireSmoke", "particle/particle_smokegrenade1")
list.Add("vFireSmoke", "particle/particle_smokegrenade")

list.Add("vFireDebris", "effects/fleck_cement1")
list.Add("vFireDebris", "effects/fleck_cement2")
list.Add("vFireDebris", "effects/fleck_tile1")
list.Add("vFireDebris", "effects/fleck_tile2")

list.Add("vFireExplosionSounds", "weapons/explode3.wav")
list.Add("vFireExplosionSounds", "weapons/explode4.wav")
list.Add("vFireExplosionSounds", "weapons/explode5.wav")

list.Add("vFireDirt", "particle/particle_debris_01")
list.Add("vFireDirt", "particle/particle_debris_02")

--[[-------------------------------------------------------------------------
Specifics & External Support
---------------------------------------------------------------------------]]
vFireInstalled = true
vFireVersion = 1

if CLIENT then
	local map = game.GetMap()
	local isHL2Map = string.StartWith(map, "d1_") or string.StartWith(map, "d2_") or string.StartWith(map, "d3_")
	if isHL2Map then
		vFireLightMul = vFireLightMul * 0.165
	end
end

if SERVER then
	hook.Add("ExtinguisherDoExtinguish", "vFireSoftExtinguishFires", function(prop)
		if vFireIsVFireEnt(prop) then
			if prop:GetClass() == "vfire" then
				prop:SoftExtinguish(2)
				prop:Prioritize(2)
			end
			return true
		end
	end)
end

if SERVER or CLIENT then
	hook.Add("InitPostEntity", "vFireULXSupport", function()
		local ulxInstalled = istable(ulx)
		if !ulxInstalled then return end

		local CATEGORY = "vFire"

		function ulx.vextinguish(ply)
			local lookedAt = ents.FindInCone(ply:EyePos(), ply:EyeAngles():Forward(), 30000, 0.9)
			local removeCount = 0
			for k, v in pairs(lookedAt) do
				local class = v:GetClass()
				if class == "vfire" or class == "vfire_ball" then
					v:Remove()
					removeCount = removeCount + 1
				end
			end
			ulx.fancyLogAdmin(ply, "#A extinguished "..removeCount.." fires.")
		end

		local vextinguish = ulx.command(CATEGORY, "ulx vextinguish", ulx.vextinguish, "!vextinguish")
		vextinguish:defaultAccess(ULib.ACCESS_ADMIN)
		vextinguish:help("Extinguish fires you're looking at.")

		function ulx.vextinguishall(ply)
			local removeCount = 0
			for k, v in pairs(ents.FindByClass("vfire")) do
				v:Remove()
				removeCount = removeCount + 1
			end
			ulx.fancyLogAdmin(ply, "#A extinguished all "..removeCount.." fires.")
		end

		local vextinguishall = ulx.command(CATEGORY, "ulx vextinguishall", ulx.vextinguishall, "!vextinguishall")
		vextinguishall:defaultAccess(ULib.ACCESS_ADMIN)
		vextinguishall:help("Extinguish all fires.")

		function ulx.vstartfire(ply, size)
			local tr = ply:GetEyeTrace()
			local life = size
			local feedCarry = size
			local pos = tr.HitPos - tr.Normal * 250
			local vel = tr.Normal * 1000
			local owner = ply
			CreateVFireBall(life, feedCarry, pos, vel, owner)
			ulx.fancyLogAdmin(ply, "#A started a fire.")
		end

		local vstartfire = ulx.command(CATEGORY, "ulx vstartfire", ulx.vstartfire, "!vstartfire")
		vstartfire:addParam{ type=ULib.cmds.NumArg, min=1, default=30, hint="size", ULib.cmds.optional, ULib.cmds.round }
		vstartfire:defaultAccess(ULib.ACCESS_ADMIN)
		vstartfire:help("Place a fire wherever you're looking at with a given size.")
	end)
end

if SERVER then
	hook.Add("vFire - StormFox Handeshake", "vFire - StormFox Handeshake", function()
		vFireMessage("The same thing we do every night StormFox. Try to take over the world! >:D")
	end)
end

--[[-------------------------------------------------------------------------
LOD & Particle helpers (CLIENT)
---------------------------------------------------------------------------]]
if CLIENT then
	vFireLODMaxDetailThreshold = 120
	vFireLODMedDetailThreshold = 3

	function vFireGetLOD(data)
		local pos
		if isvector(data) then
			pos = data
		else
			pos = data:GetPos()
		end

		if vFireLODs == 0 then return false end
		if vFireLODs == 2 then return 1 end

		local dist = GetViewEntity():GetPos():DistToSqr(pos)
		local fov = LocalPlayer():GetFOV()
		local LODVal = 1000000000 / (dist * fov)

		local LOD = false
		if LODVal < vFireLODMaxDetailThreshold then
			if LODVal < vFireLODMedDetailThreshold then
				LOD = 1
			else
				LOD = 2
			end
		end
		return LOD
	end

	vFirePullForceControlPointIndex = 2
	function vFirePullParticlesToPos(particles, pos)
		if IsValid(particles) then
			particles:SetControlPoint(vFirePullForceControlPointIndex, pos)
		end
	end
end

--[[-------------------------------------------------------------------------
Console notifications
---------------------------------------------------------------------------]]
function vFireMessage(string)
	if SERVER then
		MsgC(Color(250,115,35),"[vFire] ",Color(255,255,255), string, "\n")
	else
		MsgC(Color(250,175,75),"[vFire] ",Color(255,255,255), string, "\n")
	end
end

if CLIENT then
	if GetConVar("gmod_mcore_test"):GetInt() == 0 then
		vFireMessage("vFire performs best with gmod_mcore_test set to 1, enable it and restart your game for changes to take effect.")
	end
end
