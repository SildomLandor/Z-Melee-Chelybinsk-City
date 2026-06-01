local MODE = MODE

MODE.name = "zombie"
MODE.PrintName = "Зомбари"
MODE.randomSpawns = true
MODE.LootSpawn = true
MODE.LootOnTime = false
MODE.ROUND_TIME = 1200
MODE.start_time = 10
MODE.ForBigMaps = false
MODE.Chance = 0.02

MODE.NPCList = {
	{type = "zbase_classic_zombie", health = 80, min = 2, max = 10},
	{type = "zbase_classic_zombie_torso", health = 40, min = 2, max = 2},
	{type = "zbase_classic_female_zombie", health = 70, min = 2, max = 4},
	{type = "zbase_classic_female_zombie_torso", health = 35, min = 2, max = 4},
	{type = "zbase_metro_zombie", health = 100, min = 2, max = 4},
	{type = "zbase_metro_zombie_grenade", health = 100, min = 2, max = 4},
	{type = "zbase_poison_spitter_zombie", health = 20, min = 2, max = 4},
	{type = "zbase_poison_spitter_zombie_torso", health = 10, min = 2, max = 4},
	{type = "zbase_poison_zombie", health = 120, min = 2, max = 4},
	--{type = "npc_headcrab", health = 20, min = 2, max = 4},

	{type = "zbase_fast_zombie", health = 30, min = 2, max = 4},
	{type = "zbase_fast_zombie_torso", health = 15, min = 2, max = 4},
	--{type = "npc_headcrab_fast", health = 20, min = 2, max = 4},
	
	{type = "zbase_armored_zombie", health = 100, min = 2, max = 4},
	{type = "zbase_armored_zombie_torso", health = 50, min = 2, max = 4},
	{type = "zbase_armored_zombine", health = 200, min = 2, max = 4},
	--{type = "zbase_armor_headcrab", health = 20, min = 2, max = 4},

	{type = "zbase_combine_zombie", health = 90, min = 2, max = 4},
	{type = "zbase_combine_zombie_torso", health = 45, min = 2, max = 4},
	--{type = "zbase_combine_headcrab", health = 20, min = 2, max = 4},

	{type = "zbase_funguscrab_zombie", health = 80, min = 1, max = 2},
	{type = "zbase_funguscrab_zombie_torso", health = 40, min = 1, max = 2},
	--{type = "zbase_funguscrab", health = 5, min = 1, max = 2},
}

local spawnMinDistSqr = 600 * 600
local npcHullMins = Vector(-16, -16, 0)
local npcHullMaxs = Vector(16, 16, 72)

local function getRandomSpawnPoints()
	local spawns = {}
	for _, pt in ipairs(zb.GetMapPoints("RandomSpawns") or {}) do
		spawns[#spawns + 1] = pt.pos or pt
	end
	return spawns
end

local function getZombieSpawnPoints()
	local pts = getRandomSpawnPoints()
	for _, pt in ipairs(zb.GetMapPoints("ZOMBIE_NPC_SPAWN") or {}) do
		pts[#pts + 1] = pt.pos or pt
	end
	return pts
end

local function groundNPCPos(raw)
	if not raw then return end

	local tr = util.TraceLine({
		start = raw + Vector(0, 0, 256),
		endpos = raw - Vector(0, 0, 1024),
		mask = MASK_SOLID,
	})
	if not tr.Hit or tr.HitSky then return end

	local pos = tr.HitPos + Vector(0, 0, 2)
	local hull = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = npcHullMins,
		maxs = npcHullMaxs,
		mask = MASK_NPCSOLID,
	})
	if hull.Hit then return end

	return pos
end

local function farFromPlayers(pos, minSqr)
	for _, ply in ipairs(zb:CheckAlive(true)) do
		if pos:DistToSqr(ply:GetPos()) < minSqr then return false end
	end
	return true
end

function MODE:PlacePlayer(ply)
	local spawns = getRandomSpawnPoints()
	local pos = #spawns > 0 and zb:GetRandomSpawn(ply, spawns) or zb:GetRandomSpawn(ply)
	if pos then ply:SetPos(pos) end
end

MODE.Waves = {
	{
		
	},
	{

	},
	{
		
	},
	{
		
	},
	{
		
	},
	{
		
	},
}

MODE.LootTable = {
	{30, {
		{12, "weapon_smallconsumable"},
		{10, "weapon_bigconsumable"},
		{8, "weapon_bandage_sh"},
		{7, "weapon_tourniquet"},
		{6, "weapon_painkillers"},
		{5, "weapon_ducttape"},
		{4, "weapon_walkie_talkie"},
		{3, "hg_flashlight"},
		{2, "weapon_medkit_sh"},
		{1, "weapon_matches"},
	}},
	{55, {
		{12, "weapon_pocketknife"},
		{10, "weapon_bat"},
		{8, "weapon_leadpipe"},
		{7, "weapon_hammer"},
		{6, "weapon_brick"},
		{5, "weapon_hg_crowbar"},
		{4, "weapon_hatchet"},
		{3, "weapon_hg_extinguisher"},
		{2, "weapon_hg_axe"},
		{2, "weapon_hg_machete"},
		{1, "weapon_hg_sledgehammer"},
		{0.8, "weapon_pan"},
		{0.6, "weapon_hg_shovel"},
		{0.4, "hg_brassknuckles"},
	}},
	{15, {
		{6, "weapon_remington870"},
		{5, "weapon_doublebarrel_short"},
		{4, "weapon_glock17"},
		{4, "weapon_revolver2"},
		{3, "weapon_mac11"},
		{3, "ent_armor_vest3"},
		{2, "ent_armor_helmet1"},
		{2, "*ammo*"},
	}},
}

function MODE:GetLootTable()
	if (self.Wave or 0) <= 1 then
		local tab = {}
		table.Add(tab, self.LootTable[1][2])
		table.Add(tab, self.LootTable[2][2])
		return tab
	end
end

local function zombieMode()
	local mode = CurrentRound()
	if mode and mode.name == "zombie" then return mode end
end

local function spawnLootBurst(count, delay)
	for i = 1, count do
		timer.Simple(delay * i, function()
			if not zombieMode() then return end
			hook.Run("Boxes Think")
		end)
	end
end

util.AddNetworkString("zombie_start")
util.AddNetworkString("zombie_newwave")
util.AddNetworkString("zombie_roundend")
util.AddNetworkString("zombie_highlight_last")

local zomb_hi, zomb_hi_t = {}, 0

function MODE.GuiltCheck(attacker, victim)
	if not IsValid(attacker) or not IsValid(victim) then return 1, true end
	if attacker == victim then return 1, true end
	if attacker:IsPlayer() and victim:IsPlayer() and attacker:Team() == victim:Team() then
		return 3, true
	end
	return 1, true
end

function MODE:CanLaunch()
	local navAreas = navmesh.GetAllNavAreas() or {}
	return #navAreas > 0
end

function MODE:Intermission()
	game.CleanUpMap()

	self.Wave = 0
	self.ZombieCount = 0
	self.PrepPhase = true
	self.WaveActive = false
	self.WaveCompleted = false
	self.WaveSpawnInProgress = false
	self.WaveIntermission = false
	self.Zombies = {}
	self.nextZombieCheck = nil
	zomb_hi, zomb_hi_t = {}, 0

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetupTeam(0)
		self:PlacePlayer(ply)
	end

	net.Start("zombie_start")
	net.Broadcast()
end

function MODE:GiveEquipment()
	for _, ply in player.Iterator() do
		if not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetSuppressPickupNotices(true)
		ply.noSound = true
		ply:SetPlayerClass("default")
		zb.GiveRole(ply, "Выживший", Color(0, 56, 0))
		ply:Give("weapon_hands_sh")
		ply:SetSuppressPickupNotices(false)
		ply.noSound = false
	end

	spawnLootBurst(8, 2)

	timer.Simple(self.start_time or 35, function()
		local mode = zombieMode()
		if not mode then return end
		mode.PrepPhase = false
		mode:StartWave(1)
	end)
end

function MODE:FindSpawnPos()
	local points = getZombieSpawnPoints()

	if #points == 0 then
		for _, area in RandomPairs(navmesh.GetAllNavAreas() or {}) do
			if area:IsUnderwater() then continue end
			local pos = groundNPCPos(area:GetCenter())
			if pos and farFromPlayers(pos, spawnMinDistSqr) then return pos end
		end
		return
	end

	local minSqr = spawnMinDistSqr
	for _ = 1, 4 do
		for _, raw in RandomPairs(points) do
			local pos = groundNPCPos(raw)
			if pos and farFromPlayers(pos, minSqr) then return pos end
		end
		minSqr = minSqr * 0.25
	end

	for _, raw in RandomPairs(points) do
		local pos = groundNPCPos(raw)
		if pos then return pos end
	end
end

function MODE:SpawnZombie(class, health)
	local pos = self:FindSpawnPos()
	if not pos then return end

	local npc = ents.Create(class)
	if not IsValid(npc) then return end

	npc.IsZombieModeNPC = true
	npc:SetPos(pos)
	npc:SetKeyValue("spawnflags", "256")
	npc:SetKeyValue("incominghate", "1")
	npc:Spawn()
	npc:Activate()
	if npc.DropToFloor then npc:DropToFloor() end

	if health then
		npc:SetHealth(health)
		npc:SetMaxHealth(health)
	end

	if npc.organism then
		hg.organism.Remove(npc)
		npc.organism = nil
	end
	self.Zombies[npc:EntIndex()] = npc
	self.ZombieCount = (self.ZombieCount or 0) + 1

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
			npc:AddEntityRelationship(ply, D_HT, 99)
		end
	end
end

function MODE:StartWave(num)
	local waveDef = self.Waves[num]
	if not waveDef or type(waveDef) ~= "table" or #waveDef == 0 then
		-- Generate a random wave: pick a random number of NPC types (between 1 and 4, or up to total types, but at least 2 if possible)
		local minTypes = 1
		if #MODE.NPCList >= 2 then
			minTypes = 2
		end
		local typesCount = math.min(#MODE.NPCList, math.random(minTypes, math.min(4, #MODE.NPCList)))
		-- Shuffle list and take first typesCount
		local shuffled = {}
		for _, v in ipairs(MODE.NPCList) do
			table.insert(shuffled, v)
		end
		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		waveDef = {}
		for i = 1, typesCount do
			table.insert(waveDef, shuffled[i].type)
		end
	end
	if not waveDef or type(waveDef) ~= "table" or #waveDef == 0 then
		self.WaveCompleted = true
		return
	end

	self.Wave = num
	self.WaveActive = true
	self.WaveCompleted = false
	self.WaveIntermission = false
	self.WaveSpawnInProgress = true
	self.Zombies = {}
	self.ZombieCount = 0
	self.nextZombieCheck = CurTime() + 2

	local waveCount = 0
	if type(self.Waves) == "table" then
		waveCount = #self.Waves
	end
	net.Start("zombie_newwave")
		net.WriteInt(num, 8)
		net.WriteInt(waveCount, 8)
	net.Broadcast()

	local mode = self
	local delay = 0

		for _, typeName in ipairs(waveDef) do
			local npcDef = nil
			for _, npc in ipairs(MODE.NPCList) do
				if npc.type == typeName then
					npcDef = npc
					break
				end
			end
			if not npcDef then
				-- skip unknown type
				continue
			end
			local countToSpawn = math.random(npcDef.min, npcDef.max)
			local health = npcDef.health
			for _ = 1, countToSpawn do
				delay = delay + 0.6
				timer.Simple(delay, function()
					if zombieMode() ~= mode or not mode.WaveActive then return end
					mode:SpawnZombie(typeName, health)
				end)
			end
		end

	timer.Simple(delay + 0.15, function()
		if zombieMode() ~= mode then return end
		mode.WaveSpawnInProgress = false
	end)
end

function MODE:EndWave()
	if self.WaveIntermission then return end

	self.WaveActive = false
	self.WaveSpawnInProgress = false

	if self.Wave >= #self.Waves then
		self.WaveCompleted = true
		return
	end

	self.WaveIntermission = true

	timer.Simple(8, function()
		local mode = zombieMode()
		if not mode or mode.PrepPhase then return end
		if #zb:CheckAlive(true) <= 0 then
			mode.WaveIntermission = false
			return
		end

		mode.WaveIntermission = false
		mode:StartWave(mode.Wave + 1)
	end)
end

function MODE:CountLivingZombies()
	local alive = 0

	for id, ent in pairs(self.Zombies or {}) do
		if not IsValid(ent) or ent:Health() <= 0 then
			self.Zombies[id] = nil
		else
			alive = alive + 1
		end
	end

	self.ZombieCount = alive
	return alive
end

function MODE:SyncLastZombieHighlight()
	local off = self.PrepPhase or not self.WaveActive or self.WaveIntermission or self.WaveSpawnInProgress
	local n = self.ZombieCount or 0
	local list = {}

	if not off and n > 0 and n <= 3 then
		for _, ent in pairs(self.Zombies or {}) do
			if IsValid(ent) and ent:Health() > 0 then list[#list + 1] = ent:EntIndex() end
		end
	end

	if #list == 0 then
		if #zomb_hi == 0 then return end
		zomb_hi, zomb_hi_t = {}, 0
		net.Start("zombie_highlight_last") net.WriteTable({}) net.Broadcast()
		return
	end

	if #list == #zomb_hi and CurTime() - zomb_hi_t < 10 then
		for i = 1, #list do
			if list[i] ~= zomb_hi[i] then break end
			if i == #list then return end
		end
	end

	zomb_hi, zomb_hi_t = list, CurTime()
	net.Start("zombie_highlight_last") net.WriteTable(list) net.Broadcast()
end

function MODE:RoundThink()
	if (self.nextLootThink or 0) < CurTime() then
		self.nextLootThink = CurTime() + 5
		hook.Run("Boxes Think")
	end

	if self.PrepPhase or not self.WaveActive or self.WaveIntermission or self.WaveSpawnInProgress then return end

	if (self.nextZombieCheck or 0) > CurTime() then return end
	self.nextZombieCheck = CurTime() + 2

	local alive = self:CountLivingZombies()
	self:SyncLastZombieHighlight()

	if alive <= 0 then
		self:EndWave()
	end
end

hook.Add("EntityRemoved", "ZombieModeNPCRemoved", function(ent)
	if not ent.IsZombieModeNPC then return end

	local mode = zombieMode()
	if not mode or not mode.Zombies then return end

	mode.Zombies[ent:EntIndex()] = nil
end)

function MODE:ShouldRoundEnd()
	if self.PrepPhase then return false end
	if self.WaveCompleted then return true end
	if #zb:CheckAlive(true) <= 0 then return true end
	return false
end

function MODE:EndRound()
	zomb_hi, zomb_hi_t = {}, 0
	net.Start("zombie_highlight_last") net.WriteTable({}) net.Broadcast()

	net.Start("zombie_roundend")
		net.WriteBool(self.WaveCompleted or false)
	net.Broadcast()

	for _, ent in ents.Iterator() do
		if IsValid(ent) and ent.IsZombieModeNPC then
			ent:Remove()
		end
	end

	self.Zombies = {}
	self.ZombieCount = 0
	self.WaveActive = false
	self.WaveSpawnInProgress = false
	self.WaveIntermission = false
	self.PrepPhase = false
	self.nextZombieCheck = nil
end

function MODE:RoundStart()
	spawnLootBurst(5, 3)
end
