local MODE = MODE
MODE.name = "gwars"
MODE.PrintName = "Война банд"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 180

MODE.Chance = 0.02

MODE.OverideSpawnPos = true
MODE.OverrideSpawn = true
MODE.LootSpawn = false

function MODE:CanLaunch()
	return true
	--[[local points = zb.GetMapPoints( "HMCD_TDM_T" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_CT" )
    return (#points > 0) and (#points2 > 0)--]]
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

util.AddNetworkString("gwars_start")
function MODE:Intermission()
	game.CleanUpMap()

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	
	for i, ply in player.Iterator() do
		ply.zb_gwars_loadout = nil
		ply.zb_gwars_swat_loadout = nil
		ply:SetupTeam(ply:Team())
	end

	net.Start("gwars_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	return endround
end

function MODE:BoringRoundFunction()		
	timer.Simple(2, function()
		//PrintMessage(HUD_PRINTTALK, "IT IS A GANG SHOOTOUT FFS...")
	end)
end

local swatSpawned = false

function MODE:RoundStart()
    swatSpawned = false 
end

local tblweps = {
	[0] = {
		"weapon_makarov",
		"weapon_ab10",
		"weapon_m9beretta",
		"weapon_pl15",
		"weapon_browninghp",
		"weapon_p22",
		"weapon_glock18c",
		"weapon_glock26",
		"weapon_m1911",
		"weapon_revolver2",
		"weapon_pl15",
		"weapon_deagle",
		"weapon_tec9",
		"weapon_cz75",
		"weapon_cz75a",
		"weapon_revolver357",
		"weapon_doublebarrel_short",
		"weapon_doublebarrel",
		"weapon_skorpion",
	},
	[1] = {
		"weapon_makarov",
		"weapon_ab10",
		"weapon_m9beretta",
		"weapon_pl15",
		"weapon_browninghp",
		"weapon_p22",
		"weapon_glock18c",
		"weapon_glock26",
		"weapon_m1911",
		"weapon_revolver2",
		"weapon_pl15",
		"weapon_deagle",
		"weapon_tec9",
		"weapon_cz75",
		"weapon_cz75a",
		"weapon_revolver357",
		"weapon_doublebarrel_short",
		"weapon_doublebarrel",
		"weapon_skorpion",
	}
}


--[[local tblatts = {
	[0] = {
		{"optic4"},
	},
	[1] = {
		{"holo14","laser2","grip3"}
	}
}]]

local tblarmors = {
	[0] = {
		{"ent_armor_vest3","ent_armor_helmet2"}
	},
	[1] = {
		{"ent_armor_vest3","ent_armor_helmet2"}
	}
}

function MODE:GetPlySpawn(ply)
end

local function gwars_equip_ply(ply)
	if not IsValid(ply) or not ply:Alive() then return end
	if ply:Team() == TEAM_SPECTATOR or ply:Team() == 2 then return end

	local roundTag = zb.ROUND_BEGIN or 0
	if ply.zb_gwars_loadout == roundTag then return end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	if ply:Team() == 0 then
		ply:SetPlayerClass("bloodz")
		zb.GiveRole(ply, "Bloodz", Color(190, 0, 0))
	else
		ply:SetPlayerClass("groove")
		zb.GiveRole(ply, "Groove", Color(0, 190, 0))
	end

	local pool = tblweps[ply:Team()]
	if pool and #pool > 0 then
		local wep = ply:Give(pool[math.random(#pool)])
		if IsValid(wep) and wep.GetMaxClip1 and wep.GetPrimaryAmmoType then
			local clip, ammoType = wep:GetMaxClip1(), wep:GetPrimaryAmmoType()
			if clip and clip > 0 and ammoType and ammoType >= 0 then
				ply:GiveAmmo(clip * 3, ammoType, true)
			end
		end
	end

	ply:Give("weapon_bandage_sh")
	ply:Give("weapon_tourniquet")
	ply:Give("weapon_fentanyl")

	local hands = ply:Give("weapon_hands_sh")
	if IsValid(hands) then
		ply:SelectWeapon("weapon_hands_sh")
	end

	ply.zb_gwars_loadout = roundTag

	timer.Simple(0.1, function()
		if not IsValid(ply) then return end
		ply.noSound = false
		ply:SetSuppressPickupNotices(false)
	end)
end

function MODE:GiveEquipment()
	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_TDM_CT"), self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints("HMCD_TDM_T"), self.TPoints)

	local function tryAll()
		if CurrentRound() ~= MODE then return end
		for _, ply in player.Iterator() do
			gwars_equip_ply(ply)
		end
	end

	timer.Simple(0, tryAll)
	timer.Simple(0.15, tryAll)
	timer.Simple(0.35, tryAll)
end

local function gwars_equip_swat(ply)
	if not IsValid(ply) or not ply:Alive() or ply:Team() ~= 2 then return end
	if CurrentRound() ~= MODE then return end
	if ply.zb_gwars_swat_loadout then return end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:SetPlayerClass("swat")
	zb.GiveRole(ply, "СОБР", Color(0, 0, 190))

	local inv = ply:GetNetVar("Inventory") or {}
	inv.Weapons = inv.Weapons or {}
	inv.Weapons.hg_sling = true
	ply:SetNetVar("Inventory", inv)

	ply:StripWeapons()

	local gun = ply:Give("weapon_ar15")
	if IsValid(gun) and gun.GetMaxClip1 and gun.GetPrimaryAmmoType then
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	end

	local sidearm = ply:Give("weapon_glock17")
	if IsValid(sidearm) and sidearm.GetMaxClip1 and sidearm.GetPrimaryAmmoType then
		ply:GiveAmmo(sidearm:GetMaxClip1() * 3, sidearm:GetPrimaryAmmoType(), true)
	end

	ply:Give("weapon_medkit_sh")
	ply:Give("weapon_tourniquet")
	ply:Give("weapon_walkie_talkie")
	ply:Give("weapon_hg_flashbang_tpik")
	ply:Give("weapon_melee")
	hg.AddArmor(ply, "ent_armor_helmet1")
	hg.AddArmor(ply, "ent_armor_vest4")

	local hands = ply:Give("weapon_hands_sh")
	if IsValid(hands) then
		ply:SelectWeapon("weapon_hands_sh")
	end

	ply.zb_gwars_swat_loadout = true

	timer.Simple(0.1, function()
		if not IsValid(ply) then return end
		ply.noSound = false
		ply:SetSuppressPickupNotices(false)
	end)
end

local function gwars_spawn_swat(ply, startpos, slot)
	if not IsValid(ply) then return end

	ply:SetTeam(2)
	ply:Spawn()
	ply:SetupTeam(2)

	if startpos then
		hg.tpPlayer(startpos, ply, slot or 1, 0)
	end

	local function tryEquip()
		gwars_equip_swat(ply)
	end

	timer.Simple(0, tryEquip)
	timer.Simple(0.15, tryEquip)
end

function MODE:RoundThink()
	if swatSpawned or (CurTime() - zb.ROUND_BEGIN) < 120 then return end

	local deadPlayers = {}
	for _, ply in player.Iterator() do
		if not ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
			deadPlayers[#deadPlayers + 1] = ply
		end
	end

	local startpos
	if self.TPoints and #self.TPoints > 0 and self.TPoints[1].pos then
		startpos = self.TPoints[1].pos
	else
		startpos = zb:GetRandomSpawn()
	end

	for i = 1, math.min(4, #deadPlayers) do
		gwars_spawn_swat(deadPlayers[i], startpos, i)
	end

	swatSpawned = true
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("gwars_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("gwars_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	if winner == 3 then return end

	for _, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end

function MODE:PlayerDeath(ply)
end
