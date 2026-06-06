local MODE = MODE

local melees = {
	"weapon_buck200knife",
	"weapon_sogknife",
	"weapon_bat",
	"weapon_barbedbat",
	"weapon_melee",
	"weapon_wrench",
	"weapon_pan",
	"weapon_hg_katana",
	"weapon_hg_sledgehammer",
	"weapon_hg_crowbar",
	"weapon_hg_shovel",
	"weapon_hg_machete",
	"weapon_hg_nunchuks",
	"weapon_hg_spear_pro",
	"weapon_tomahawk",
	"weapon_ram",
	"weapon_hg_axe",
}

local meleeSet = {}
for _, cls in ipairs(melees) do
	meleeSet[cls] = true
end
meleeSet.weapon_hg_slayersword = true

local fallbacks = {"weapon_melee", "weapon_pocketknife", "weapon_bat"}

local function hasMelee(ply)
	for _, wep in ipairs(ply:GetWeapons()) do
		if meleeSet[wep:GetClass()] then return true end
	end
end

local function cleanWep(wep)
	if not IsValid(wep) then return end
	wep.IsSpawned = nil
	wep.init = nil
end

local function giveWep(ply, cls)
	local wep = ply:Give(cls)
	cleanWep(wep)
	return wep
end

local function giveRandomMelee(ply)
	local tried = {}

	for _ = 1, #melees do
		local cls = melees[math.random(#melees)]
		if tried[cls] then continue end
		tried[cls] = true
		local wep = giveWep(ply, cls)
		if IsValid(wep) then return wep end
	end

	for _, cls in ipairs(fallbacks) do
		local wep = giveWep(ply, cls)
		if IsValid(wep) then return wep end
	end
end

local function giveMelee(ply, trySlayer)
	if trySlayer then
		local wep = giveWep(ply, "weapon_hg_slayersword")
		if IsValid(wep) then return wep end
	end
	if hasMelee(ply) then return end
	return giveRandomMelee(ply)
end

function MODE:EquipPlayer(ply, trySlayer)
	if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return false end
	if CurrentRound() ~= self then return false end

	local tag = zb.ROUND_BEGIN or 0

	if ply.zb_dm_melee_loadout == tag then
		if hasMelee(ply) then return true end
		giveMelee(ply, trySlayer)
		return hasMelee(ply)
	end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:StripWeapons()
	ply:RemoveAllAmmo()
	hg.CreateInv(ply)

	giveWep(ply, "weapon_hands_sh")
	giveMelee(ply, trySlayer)
	giveWep(ply, "weapon_bandage_sh")

	ply:SelectWeapon("weapon_hands_sh")
	ply.zb_dm_melee_loadout = tag
	zb.GiveRole(ply, "Fighter", Color(190, 15, 15))

	timer.Simple(0.1, function()
		if not IsValid(ply) then return end
		ply.noSound = false
		ply:SetSuppressPickupNotices(false)
	end)

	return hasMelee(ply)
end

function MODE:Intermission()
	local dm = zb.modes.dm
	if dm and dm.Intermission then
		dm.Intermission(self)
	end
end

function MODE:RoundStart()
	if not zonepoint then
		zonepoint = zb:GetRandomSpawn() or Vector(0, 0, 0)
		zonedistance = zonedistance or 2048
		net.Start("dm_start")
			net.WriteVector(zonepoint)
			net.WriteFloat(zonedistance)
		net.Broadcast()
	end

	self.slayerRoll = math.random() < 0.01
	self.slayerGiven = false

	for _, ply in player.Iterator() do
		ply.zb_zone_dissolving = nil
	end

	local mode = self

	local function roll()
		if CurrentRound() ~= mode then return end

		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end

			local trySlayer = mode.slayerRoll and not mode.slayerGiven
			if mode:EquipPlayer(ply, trySlayer) and trySlayer and hasMelee(ply) then
				mode.slayerGiven = true
			end
		end
	end

	roll()
	timer.Simple(0, roll)
end

hook.Add("ZB_PreRoundStart", "ZB_DMMelee_Reset", function()
	for _, ply in player.Iterator() do
		ply.zb_dm_melee_loadout = nil
	end
end)

hook.Add("PlayerSpawn", "ZB_DMMelee_Loadout", function(ply)
	if zb.ROUND_STATE ~= 1 then return end
	local mode = CurrentRound()
	if not mode or mode.name ~= "dm_melee" then return end

	timer.Simple(0, function()
		if not IsValid(ply) or not ply:Alive() then return end
		local m = CurrentRound()
		if m and m.EquipPlayer then m:EquipPlayer(ply, false) end
	end)
end)
