local MODE = MODE

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)

MODE.name = "dm"
MODE.PrintName = "Против всех"
MODE.LootSpawn = false
MODE.GuiltDisabled = true
MODE.randomSpawns = true

MODE.ForBigMaps = false
MODE.Chance = 0.04

local radius = nil
local mapsize = 7500
-- MODE.MapSize = mapsize

util.AddNetworkString("dm_start")
util.AddNetworkString("dm_end")

function MODE:CanLaunch()
    return true//(zb.GetWorldSize() >= ZBATTLE_BIGMAP)
end

function MODE:Intermission()
	game.CleanUpMap()

	local poses = {}
	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then
			continue
		end
		
		ApplyAppearance(ply)
		ply:SetupTeam(0)
		table.insert(poses, ply:GetPos())
	end

	if #poses == 0 then
		zonepoint = zb:GetRandomSpawn() or Vector(0, 0, 0)
		zonedistance = 2048
	else
		local centerpoint = Vector(0, 0, 0)
		for _, pos in ipairs(poses) do
			centerpoint:Add(pos)
		end
		centerpoint:Div(#poses)

		local dist = 0
		for _, pos in ipairs(poses) do
			local dist2 = pos:Distance(centerpoint)
			if dist < dist2 then
				dist = dist2
			end
		end

		zonepoint = centerpoint
		zonedistance = dist
	end
	
	net.Start("dm_start")
		net.WriteVector(zonepoint)
		net.WriteFloat(zonedistance)
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	local AlivePlyTbl = {
	}
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if ply.organism and ply.organism.incapacitated then continue end
		AlivePlyTbl[#AlivePlyTbl + 1] = ply
	end
	return AlivePlyTbl
end

function MODE:ShouldRoundEnd()
	return (#zb:CheckAlive(true) <= 1)
end

local loadouts = {
	{primary = "weapon_glock17", attachments = {{"supressor4"},{"holo16","laser3"},{"holo15","laser1"},""}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_cz75", attachments = {{"supressor4"},{"supressor4"},""}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_deagle", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_ar15", attachments = {{"holo1","grip1","supressor2"},{"holo5","grip3","supressor2"},{"laser4","grip2"},{"laser4","supressor2"}}, armor = {"vest4","helmet1"}, ammo = 3},
	{primary = "weapon_sr25", attachments = {{"holo1","laser2"},{"optic2"},{"holo8","supressor7"},{"holo5","supressor7"}}, armor = {"vest1","helmet1","nightvision1"}, ammo = 3},
	{primary = "weapon_ptrd", attachments = "", armor = {}, ammo = 12},
	{primary = "weapon_mp7", attachments = {{"holo1","supressor2"},{"holo5","supressor2"},{"laser4","supressor2"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_p90", attachments = {{"holo15","supressor4"},{"laser1","supressor4"},{"holo14","supressor4"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_doublebarrel_short", attachments = "", armor = {"vest3","helmet1","mask1"}, ammo = 6},
	{primary = "weapon_akm", attachments = {{"holo6","supressor1"},{"holo4","laser1"},{"supressor1"}}, armor = {"vest1","helmet1","nightvision1"}, ammo = 3},
	{primary = "weapon_remington870", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_m4a1", attachments = {{"holo1","grip1","supressor2"},{"holo5","grip3","supressor2"},{"laser4","grip2"},{"laser4","supressor2"}}, armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_mac11", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_mp5", attachments = {{"supressor4"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_m590a1", attachments = "", armor = {"vest4","helmet1","mask1"}, ammo = 3},
	{primary = "weapon_draco", attachments = "", armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_uzi", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_tmp", attachments = {{"optic8"},{"holo3"},{"holo4"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_xm1014", attachments = "", armor = {"vest3","helmet1","mask1"}, ammo = 3},
	{primary = "weapon_saiga12", attachments = "", armor = {"vest3","helmet1","mask1"}, ammo = 4},
	{primary = "weapon_svd", attachments = {{"holo13"},{"holo6"},{"holo2"}}, armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_spas12", attachments = {{"supressor5"}}, armor = {"vest3","helmet1","mask1"}, ammo = 3},
	{primary = "weapon_hk416", attachments = {{"holo1","grip1","supressor2"},{"holo5","grip3","supressor2"},{"laser4","grip2"},{"laser4","supressor2"}}, armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_akmwreked", attachments = "", armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_hk_usp", attachments = {{"supressor3"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_glock18c", attachments = {{"mag1","holo16"}}, armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_skorpion", attachments = "", armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_tec9", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_sg552", attachments = {{"optic8"},{"holo3"},{"holo4"}}, armor = {"vest4","helmet1"}, ammo = 3},
	{primary = "weapon_vector", attachments = {{"supressor4","holo3"},{"holo4"},{"holo7"}}, armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_revolver2", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_revolver357", attachments = "", armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_pkm", attachments = "", armor = {"vest1","helmet1"}, ammo = 0},
	{primary = "weapon_ak74", attachments = {{"holo6"},{"holo4"},{"optic8"}}, armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_ak74u", attachments = {{"holo6"},{"holo4"}}, armor = {"vest1","helmet1"}, ammo = 3},
	{primary = "weapon_winchester", attachments = "", armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_sks", attachments = {{"optic8"},{"holo6"}}, armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_ruger", attachments = "", armor = {"vest3","helmet1"}, ammo = 5},
	{primary = "weapon_mini14", attachments = {{"optic8"},{"holo6"}}, armor = {"vest3","helmet1"}, ammo = 4},
	{primary = "weapon_ac556", attachments = {{"holo6"},{"holo4"}}, armor = {"vest3","helmet1"}, ammo = 3},
	{primary = "weapon_ar15", secondary = "weapon_cz75", attachments = {{"holo1","grip1"},{"holo5","grip3"}}, armor = {"vest3","helmet1"}, ammo = 3, ammo2 = 2},
	{primary = "weapon_akm", secondary = "weapon_px4beretta", attachments = {{"holo6"},{"holo4"}}, armor = {"vest3","helmet1"}, ammo = 3, ammo2 = 2},
	{primary = "weapon_m4a1", secondary = "weapon_p22", attachments = {{"holo1","grip1"},{"holo5","grip3"}}, armor = {"vest3","helmet1"}, ammo = 3, ammo2 = 2},
	{primary = "weapon_mp5", secondary = "weapon_revolver2", attachments = {{"supressor4"}}, armor = {"vest3","helmet1"}, ammo = 3, ammo2 = 2},
	{primary = "weapon_sks", secondary = "weapon_flintlock", attachments = "", armor = {"vest3","helmet1"}, ammo = 4, ammo2 = 3},
	{primary = "weapon_winchester", secondary = "weapon_cz75", attachments = "", armor = {"vest3","helmet1"}, ammo = 4, ammo2 = 2},
	{primary = "weapon_mini14", secondary = "weapon_px4beretta", attachments = {{"holo6"}}, armor = {"vest3","helmet1"}, ammo = 3, ammo2 = 2},
	{primary = "weapon_hg_bow", attachments = "", armor = {"helmet1"}, ammo = 25, melee = "weapon_pocketknife", noGrenade = true, medicine = {"weapon_bandage_sh"}, medicineCount = 1},
	{primary = "weapon_hg_bow", attachments = "", armor = {"helmet7"}, ammo = 25, melee = "weapon_pocketknife", noGrenade = true, medicine = {"weapon_bigbandage_sh"}, medicineCount = 1},
	{primary = "weapon_musket", secondary = "weapon_flintlock", attachments = "", armor = {"vest2","helmet1"}, ammo = 10, ammo2 = 6, melee = "weapon_pocketknife", randomMedicine = true},
	{primary = "weapon_musket", secondary = "weapon_flintlock", attachments = "", armor = {"vest3"}, ammo = 12, ammo2 = 8, melee = "weapon_pocketknife", randomMedicine = true},
}

local randomGrenades = {"weapon_hg_rgd_tpik", "weapon_hg_pipebomb_tpik", "weapon_hg_smokenade_tpik", "weapon_hg_flashbang_tpik"}
local randomMedicine = {"weapon_bandage_sh", "weapon_bigbandage_sh", "weapon_medkit_sh", "weapon_fentanyl", "weapon_morphine", "weapon_adrenaline", "weapon_tourniquet"}
local randomMelees = {"weapon_melee", "weapon_pocketknife"}

local function MakeDissolver(ent, position, dissolveType)
	local dissolver = ents.Create("env_entity_dissolver")
	if not IsValid(dissolver) then return end

	timer.Simple(5, function()
		if IsValid(dissolver) then dissolver:Remove() end
	end)

	local target = "dissolve" .. ent:EntIndex()
	dissolver:SetKeyValue("dissolvetype", dissolveType or 0)
	dissolver:SetKeyValue("magnitude", 0)
	dissolver:SetPos(position)
	dissolver:SetPhysicsAttacker(ent)
	dissolver:Spawn()
	ent:SetName(target)
	ent:Fire("Open")
	dissolver:Fire("Dissolve", target, 0)
	dissolver:Fire("Kill", "", 0.1)
	return dissolver
end

local function DissolveZonePlayer(ply)
	if not IsValid(ply) or ply.zb_zone_dissolving then return end
	ply.zb_zone_dissolving = true

	local org = ply.organism
	if org then
		org.alive = false
		org.assimilated = 1
		ply:SetLocalVar("assimilation", 1)
	end

	if not IsValid(ply.FakeRagdoll) then
		hg.Fake(ply, nil, true)
	end

	local rag = ply.FakeRagdoll
	local pos = IsValid(rag) and rag:GetPos() or ply:GetPos()
	local target = IsValid(rag) and rag or ply

	MakeDissolver(target, pos, 0)

	timer.Simple(0.15, function()
		if IsValid(ply) and ply:Alive() then ply:Kill() end
	end)
end

function MODE:RoundStart()
	if not zonepoint then
		zonepoint = zb:GetRandomSpawn() or Vector(0, 0, 0)
		zonedistance = zonedistance or 2048
	end

	for _, ply in player.Iterator() do
		ply.zb_zone_dissolving = nil
		if not ply:Alive() then continue end

		local loadout = loadouts[math.random(#loadouts)]
		local selectedAttachments = istable(loadout.attachments) and table.Random(loadout.attachments) or loadout.attachments

		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:Give("weapon_hands_sh")

		local inv = ply:GetNetVar("Inventory", {}) or {}
		inv.Weapons = inv.Weapons or {}
		inv.Weapons.hg_sling = true
		ply:SetNetVar("Inventory", inv)
		
		local gun = ply:Give(loadout.primary)
		if IsValid(gun) then
			ply:GiveAmmo(gun:GetMaxClip1() * loadout.ammo, gun:GetPrimaryAmmoType(), true)
			hg.AddAttachmentForce(ply, gun, selectedAttachments)
		end

		if loadout.secondary then
			local pistol = ply:Give(loadout.secondary)
			if IsValid(pistol) then
				ply:GiveAmmo(pistol:GetMaxClip1() * (loadout.ammo2 or 2), pistol:GetPrimaryAmmoType(), true)
			end
		end

		hg.AddArmor(ply, loadout.armor)
		ply:Give(loadout.melee or randomMelees[math.random(#randomMelees)])

		if not loadout.noGrenade then
			local grenadeCount = math.random(1, 2)
			local usedGrenades = {}
			for i = 1, grenadeCount do
				local grenade = randomGrenades[math.random(#randomGrenades)]
				while usedGrenades[grenade] and i > 1 do
					grenade = randomGrenades[math.random(#randomGrenades)]
				end
				usedGrenades[grenade] = true
				ply:Give(grenade)
			end
		end

		if loadout.medicine then
			for i = 1, (loadout.medicineCount or 1) do
				ply:Give(loadout.medicine[math.random(#loadout.medicine)])
			end
		elseif loadout.randomMedicine then
			for i = 1, math.random(1, 2) do
				ply:Give(randomMedicine[math.random(#randomMedicine)])
			end
		else
			ply:Give("weapon_bandage_sh")
			ply:Give("weapon_tourniquet")
		end

		ply:Give("weapon_walkie_talkie")
		ply:SelectWeapon("weapon_hands_sh")

		if ply.organism then ply.organism.recoilmul = 0.5 end

		timer.Simple(0.1, function() ply.noSound = false end)
		ply:SetSuppressPickupNotices(false)
		zb.GiveRole(ply, "Fighter", Color(190,15,15))
	end
end

local cooldown = CurTime()
local dmDoorClasses = {
	"prop_door_rotating",
	"func_door_rotating",
	"prop_door",
	"func_door",
}

local dmPropClasses = {
	"prop_physics",
	"prop_physics_multiplayer",
	"func_physbox",
}

local function ZoneEntPos(ent)
	if ent:IsPlayer() then
		local rag = ent.FakeRagdoll
		if IsValid(rag) then return rag:GetPos() end
	end
	return ent:GetPos()
end

hook.Add("Think", "bober", function()
	if zb.ROUND_STATE ~= 1 then return end
	local rnd = CurrentRound()
	if not rnd or not MODE.IsDMFamily(rnd) then return end
	if rnd:ShouldRoundEnd() then return end
	if (zb.ROUND_START or 0) + 20 > CurTime() then return end
	if cooldown > CurTime() then return end
	if deathmatch_nozone:GetBool() then return end

	local pos = zonepoint
	if not pos then return end

	cooldown = CurTime() + 0.5

	local radius = MODE.GetZoneRadius()
	if radius <= 0 then return end
	local radiussqr = radius * radius

	for _, ent in player.Iterator() do
		if not ent:Alive() or ent.zb_zone_dissolving then continue end
		local org = ent.organism
		if not org then continue end

		if pos:DistToSqr(ZoneEntPos(ent)) <= radiussqr then
			if (org.assimilated or 0) > 0 then
				org.assimilated = math.Approach(org.assimilated, 0, 0.2)
				ent:SetLocalVar("assimilation", org.assimilated)
			end
			continue
		end

		org.assimilated = math.Approach(org.assimilated or 0, 1, 0.125)
		ent:SetLocalVar("assimilation", org.assimilated)

		if org.assimilated >= 1 then
			DissolveZonePlayer(ent)
		end
	end

	for i = 1, #dmDoorClasses do
		local list = ents.FindByClass(dmDoorClasses[i])
		for j = 1, #list do
			local ent = list[j]
			if not IsValid(ent) then continue end
			if pos:DistToSqr(ent:GetPos()) <= radiussqr then continue end
			if ent:GetNoDraw() then continue end
			hgBlastThatDoor(ent)
		end
	end

	for i = 1, #dmPropClasses do
		local list = ents.FindByClass(dmPropClasses[i])
		for j = 1, #list do
			local ent = list[j]
			if not IsValid(ent) then continue end
			if pos:DistToSqr(ent:GetPos()) <= radiussqr then continue end
			if hg.expItems[ent:GetModel()] then continue end
			MakeDissolver(ent, ent:GetPos(), 0)
		end
	end
end)

function MODE:GiveWeapons()
end

function MODE:GiveEquipment()
end

function MODE:RoundThink()
end

function MODE:PlayerDeath(ply)
	if zb.ROUND_STATE == 1 then
		ply:GiveSkill(-0.1)
	end
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	local playersharm = {}
	for ply, tbl in pairs(zb.HarmDone) do
		for attacker, harm in pairs(tbl) do
			playersharm[attacker] = (playersharm[attacker] or 0) + harm
		end
	end

	local most_violent_player
	local curharm = 0
	for ply, harm in pairs(playersharm) do
		if harm > curharm then
			most_violent_player = ply
			curharm = harm
		end
	end

	timer.Simple(2,function()
		net.Start("dm_end")
		local ent = zb:CheckAlive(true)[1]
		
		if IsValid(ent) then
			ent:GiveRoundExp("major")
			ent:GiveSkill(math.Rand(0.2,0.3))
		end

		if IsValid(most_violent_player) then
			most_violent_player:GiveRoundExp("major")
			most_violent_player:GiveSkill(math.Rand(0.2,0.3))
		end

		net.WriteEntity(IsValid(ent) and ent:Alive() and ent or NULL)
		net.WriteEntity(IsValid(most_violent_player) and most_violent_player or NULL)
		net.Broadcast()
	end)
end
