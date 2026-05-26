MODE.name = "hl2dm"
MODE.PrintName = "Half-Life 2 Deathmatch"

MODE.Chance = 0.05

MODE.LootSpawn = false

MODE.ForBigMaps = true

local ACD_NextAirstrikeTime = 0
local ACD_MaxStrikes = 2
local ACD_StrikesLeft = {}

local function resetPlyRoundState(ply)
    ply.subClass = nil
    ply.leader = nil
    ply:SetNWString("PlayerRole", "")
end

function MODE:ClearPlayerRoles()
    for _, ply in player.Iterator() do
        resetPlyRoundState(ply)
    end
    ACD_StrikesLeft = {}
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

util.AddNetworkString("hl2dm_start")
function MODE:Intermission()
	game.CleanUpMap()

	for _, ply in player.Iterator() do
        resetPlyRoundState(ply)
		ply:SetupTeam(ply:Team())
	end

	net.Start("hl2dm_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	--print("ShouldRoundEnd", endround, winner)
	return endround
end

function MODE:RoundStart()
end

function MODE:GetPlySpawn(ply)
end

local function takeRandom(tbl)
    if #tbl == 0 then return end
    return table.remove(tbl, math.random(#tbl))
end

local function tpToMapPoint(ply, pointName)
    local points = zb.GetMapPoints(pointName)
    if #points > 0 then
        ply:SetPos(points[math.random(#points)].pos)
    end
end

local function assignHl2dmRoles(players)
    local combine, rebels = {}, {}

    for _, ply in ipairs(players) do
        if ply:Team() == 1 then
            combine[#combine + 1] = ply
        else
            rebels[#rebels + 1] = ply
        end
    end

    local big = #players > 6

    local elite = takeRandom(combine)
    if elite then
        elite.subClass = "elite"
        elite.leader = true
        elite:SetNWString("PlayerRole", "Elite")
    end

    local shotgunner = takeRandom(combine)
    if shotgunner then
        shotgunner.subClass = "shotgunner"
        shotgunner:SetNWString("PlayerRole", "Shotgunner")
    end

    if big then
        local sniper = takeRandom(combine)
        if sniper then
            sniper.subClass = "sniper"
            tpToMapPoint(sniper, "HL2DM_SNIPERSPAWN")
        end
    end

    local medic = takeRandom(rebels)
    if medic then
        medic.subClass = "medic"
        medic:SetNWString("PlayerRole", "Medic")
    end

    if big then
        local grenadier = takeRandom(rebels)
        if grenadier then
            grenadier.subClass = "grenadier"
            grenadier:SetNWString("PlayerRole", "Grenadier")
        end

        local sniper = takeRandom(rebels)
        if sniper then
            sniper.subClass = "sniper"
            sniper:SetNWString("PlayerRole", "Sniper")
            tpToMapPoint(sniper, "HL2DM_CROSSBOWSPAWN")
        end
    end
end

function MODE:EquipPlayer(ply)
    if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return false end
    if CurrentRound() ~= MODE then return false end

    ply:SetSuppressPickupNotices(true)
    ply.noSound = true

    local inv = ply:GetNetVar("Inventory", {}) or {}
    inv.Weapons = inv.Weapons or {}
    inv.Weapons["hg_sling"] = true
    ply:SetNetVar("Inventory", inv)

    ply:SetPlayerClass(ply:Team() == 1 and "Combine" or "Rebel")

    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        ply.noSound = false
        ply:SetSuppressPickupNotices(false)
    end)

    return true
end

function MODE:GiveEquipment()
    local mode = self
    local players = zb:CheckPlaying()

    for _, ply in ipairs(players) do
        resetPlyRoundState(ply)
    end

    assignHl2dmRoles(players)

    local function tryAll()
        if CurrentRound() ~= mode then return end
        for _, ply in player.Iterator() do
            mode:EquipPlayer(ply)
        end
    end

    timer.Simple(0, tryAll)
    timer.Simple(0.15, tryAll)
    timer.Simple(0.35, tryAll)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("hl2dm_roundend")
function MODE:EndRound()
	local team0, team1, winnerteam = 0, 0, 0
	for _, ply in player.Iterator() do
		if ply:Alive() and ply:Team() == 0 then
			team0 = team0 + 1
		elseif ply:Alive() and ply:Team() == 1 then
			team1 = team1 + 1
		end
	end
	if team0 > team1 then
		winnerteam = 0
	elseif team1 > team0 then
		winnerteam = 1
	elseif team0 == 0 and team1 == 0 then
		winnerteam = 3
	else
		winnerteam = 2
	end
	--print("Endround winnerteam ", winnerteam)
	self:ClearPlayerRoles()
	timer.Simple(2, function()
		net.Start("hl2dm_roundend")
			net.WriteInt(winnerteam, 3)
		net.Broadcast()
	end)
end

function MODE:PlayerDeath(ply)
end

function MODE:CanLaunch()
	return true
    --[[local TPoints = zb.GetMapPoints("HMCD_TDM_T")
    local CTPoints = zb.GetMapPoints("HMCD_TDM_CT")
    if TPoints and #TPoints > 0 and CTPoints and #CTPoints > 0 then
        return true
    end
    return false]]
end

util.AddNetworkString("ZB_RequestAirStrike")

local function FindAccessibleAngle(pos)
    for i = 1, 50 do
        local ang = AngleRand()
        local trace = util.QuickTrace(pos, ang:Forward() * 10000)
        if trace.HitSky then
            return ang
        end
    end
    return nil
end


local function FindCanisterPos(pos, normal, dist)
    local offsetPos = pos + normal * 10
    local trace = util.QuickTrace(offsetPos, -normal * dist * 2)
    
    if trace.Hit and util.PointContents(offsetPos) ~= CONTENTS_SOLID then
        local ang = FindAccessibleAngle(trace.HitPos + normal * 7)
        if ang then
            return {
                Pos = trace.HitPos + normal * 7,
                Ang = ang
            }
        end
    end
    return nil
end


local function AirStrike(pos, normal, ply)
    if CurTime() < ACD_NextAirstrikeTime then return end 
    local canisterData = FindCanisterPos(pos, normal, 1000)
    
    if canisterData then
        local ent = ents.Create("env_headcrabcanister")
        ent:SetPos(canisterData.Pos)
        ent:SetAngles(canisterData.Ang)
        ent:SetKeyValue("spawnflags", 8192)
        ent:Spawn()
        ent:Activate()
        ent:SetKeyValue("FlightSpeed", 5000)
        ent:SetKeyValue("FlightTime", 5)
        ent:SetKeyValue("SmokeLifetime", 30)
        ent:SetKeyValue("HeadcrabType", math.random(0, 2))
        ent:SetKeyValue("HeadcrabCount", 0)
        ent:SetKeyValue("Damage", 200)
        ent:SetKeyValue("DamageRadius", 300)
        ent:Fire("FireCanister")

        ACD_NextAirstrikeTime = CurTime() + 70
        ACD_StrikesLeft[ply] = (ACD_StrikesLeft[ply] or ACD_MaxStrikes) - 1
    end
end


net.Receive("ZB_RequestAirStrike", function(len, ply)
	if not ply.leader then return end

    if ACD_StrikesLeft[ply] == nil then
        ACD_StrikesLeft[ply] = ACD_MaxStrikes
    end

    if ACD_StrikesLeft[ply] > 0 then
        local pos = ply:GetEyeTrace().HitPos
        local normal = ply:GetEyeTrace().HitNormal
        AirStrike(pos, normal, ply)
    else
        ply:ChatPrint("Access denied.")
    end
end)

hook.Add("PostCleanupMap", "ACD_ResetAirstrikes", function()
    ACD_StrikesLeft = {} 
    ACD_NextAirstrikeTime = 0 
end)


