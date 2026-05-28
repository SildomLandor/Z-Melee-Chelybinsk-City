local MODE = MODE

MODE.name = "zombie"
MODE.PrintName = "Зомбари"
MODE.randomSpawns = true
MODE.LootSpawn = true
MODE.LootOnTime = false
MODE.ROUND_TIME = 1200
MODE.start_time = 35
MODE.ForBigMaps = false
MODE.Chance = 0.02

local spawnMinDistSqr = 600 * 600
local spawnMaxDist = 1400

local function getRandomSpawnPoints()
	local spawns = {}
	for _, pt in ipairs(zb.GetMapPoints("RandomSpawns") or {}) do
		spawns[#spawns + 1] = pt.pos or pt
	end
	return spawns
end

function MODE:PlacePlayer(ply)
	local spawns = getRandomSpawnPoints()
	local pos = #spawns > 0 and zb:GetRandomSpawn(ply, spawns) or zb:GetRandomSpawn(ply)
	if pos then ply:SetPos(pos) end
end

MODE.Waves = {
	{
		{type = "npc_zombie", count = 6, health = 120},
	},
	{
		{type = "npc_zombie", count = 8, health = 130},
		{type = "npc_fastzombie", count = 3, health = 95},
	},
	{
		{type = "npc_zombie", count = 8, health = 150},
		{type = "npc_fastzombie", count = 5, health = 105},
	},
	{
		{type = "npc_fastzombie", count = 7, health = 115},
		{type = "npc_poisonzombie", count = 2, health = 280},
	},
	{
		{type = "npc_fastzombie", count = 8, health = 125},
		{type = "npc_zombine", count = 3, health = 190},
	},
	{
		{type = "npc_fastzombie", count = 10, health = 135},
		{type = "npc_zombine", count = 5, health = 220},
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

local lastHighlightList = {}
local lastHighlightSent = 0

local function sendLastZombieHighlight(indices)
	local changed = #indices ~= #lastHighlightList
	if not changed then
		for i, id in ipairs(indices) do
			if lastHighlightList[i] ~= id then
				changed = true
				break
			end
		end
	end

	if not changed and CurTime() - lastHighlightSent < 10 then return end

	lastHighlightList = table.Copy(indices)
	lastHighlightSent = CurTime()

	net.Start("zombie_highlight_last")
	net.WriteTable(indices)
	net.Broadcast()
end

local function clearLastZombieHighlight()
	if #lastHighlightList == 0 then return end
	lastHighlightList = {}
	lastHighlightSent = 0
	net.Start("zombie_highlight_last")
	net.WriteTable({})
	net.Broadcast()
end

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
	clearLastZombieHighlight()

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
		ply:Give("weapon_bandage_sh")
		ply:Give("weapon_melee")

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
	local points = zb.GetMapPoints("ZOMBIE_NPC_SPAWN")
	if points and #points > 0 then
		local pt = table.Random(points)
		return pt.pos or pt
	end

	local alive = zb:CheckAlive(true)
	if #alive == 0 then
		local spawns = getRandomSpawnPoints()
		if #spawns > 0 then return zb:GetRandomSpawn(nil, spawns) end
		return zb:GetRandomSpawn()
	end

	for _ = 1, 12 do
		local ply = table.Random(alive)
		local ang = Angle(0, math.random(360), 0)
		local dist = math.random(700, spawnMaxDist)
		local pos = ply:GetPos() + ang:Forward() * dist

		local tr = util.TraceLine({
			start = pos + Vector(0, 0, 64),
			endpos = pos - Vector(0, 0, 512),
			mask = MASK_SOLID_BRUSHONLY,
		})

		if not tr.Hit then continue end

		local spawnPos = tr.HitPos + Vector(0, 0, 8)
		local tooClose = false

		for _, p in ipairs(alive) do
			if spawnPos:DistToSqr(p:GetPos()) < spawnMinDistSqr then
				tooClose = true
				break
			end
		end

		if not tooClose then return spawnPos end
	end

	return alive[1]:GetPos() + Vector(math.random(-spawnMaxDist, spawnMaxDist), math.random(-spawnMaxDist, spawnMaxDist), 0)
end

function MODE:SpawnZombie(class, health)
	local pos = self:FindSpawnPos()
	if not pos then return end

	local npc = ents.Create(class)
	if not IsValid(npc) then return end

	npc:SetPos(pos)
	npc:SetKeyValue("spawnflags", "256")
	npc:SetKeyValue("incominghate", "1")
	npc:Spawn()
	npc:Activate()

	if health then
		npc:SetHealth(health)
		npc:SetMaxHealth(health)
	end

	npc.IsZombieModeNPC = true
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
	if not waveDef then
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

	net.Start("zombie_newwave")
		net.WriteInt(num, 8)
		net.WriteInt(#self.Waves, 8)
	net.Broadcast()

	local mode = self
	local delay = 0

	for _, entry in ipairs(waveDef) do
		for _ = 1, entry.count do
			delay = delay + 0.6
			timer.Simple(delay, function()
				if zombieMode() ~= mode or not mode.WaveActive then return end
				mode:SpawnZombie(entry.type, entry.health)
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
	if self.PrepPhase or not self.WaveActive or self.WaveIntermission or self.WaveSpawnInProgress then
		clearLastZombieHighlight()
		return
	end

	local alive = self.ZombieCount or 0
	if alive <= 3 and alive > 0 then
		local indices = {}
		for _, ent in pairs(self.Zombies or {}) do
			if IsValid(ent) and ent:Health() > 0 then
				indices[#indices + 1] = ent:EntIndex()
			end
		end
		sendLastZombieHighlight(indices)
	else
		clearLastZombieHighlight()
	end
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
	clearLastZombieHighlight()

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
