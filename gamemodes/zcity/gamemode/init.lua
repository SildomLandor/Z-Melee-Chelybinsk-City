
zb = zb or {}
hg = hg or {}
zb.ROUND_STATE = zb.ROUND_STATE or 0

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("loader.lua")
include("loader.lua")

local hook_Add, net_Start, net_WriteFloat, net_Broadcast, util_AddNetworkString, ents_FindByClass, ents_Create, player_GetAll, player_GetHumans, player_GetListByName, RunConsoleCommand, CurTime, game_GetMap, IsValid, next, pairs, table_Random, table_IsEmpty, math_pow, ErrorNoHalt, isvector, FindMetaTable, Vector = hook.Add, net.Start, net.WriteFloat, net.Broadcast, util.AddNetworkString, ents.FindByClass, ents.Create, player.GetAll, player.GetHumans, player.GetListByName, RunConsoleCommand, CurTime, game.GetMap, IsValid, next, pairs, table.Random, table.IsEmpty, math.pow, ErrorNoHalt, isvector, FindMetaTable, Vector

local zb_GetMapPoints, RandomPairs, CurrentRound, hg_CreateInv, hg_tpPlayer, ApplyAppearance, OverrideSpawn = zb.GetMapPoints, RandomPairs, CurrentRound, hg.CreateInv, hg.tpPlayer, ApplyAppearance, OverrideSpawn

local PLAYER_Meta = FindMetaTable("Player")

local CONST_DEFAULT_SPAWNS = {
    "info_player_deathmatch", "info_player_combine", "info_player_rebel",
    "info_player_counterterrorist", "info_player_terrorist", "info_player_axis",
    "info_player_allies", "gmod_player_start", "info_player_teamspawn",
    "ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
    "info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red",
    "info_player_red", "info_player_blue", "info_player_coop", "info_player_human", "info_player_zombie",
    "info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

local spawners = {}

local function clear_spawners()
    for i = #spawners, 1, -1 do
        spawners[i] = nil
    end
end

local function getRandSpawn()
    clear_spawners()
    local mapPoints = zb_GetMapPoints("Spawnpoint")
    if #mapPoints > 0 then
        for k, v in RandomPairs(mapPoints) do
            spawners[#spawners + 1] = v.pos
        end
    else
        local starts = ents_FindByClass("info_player_start")
        for i, ent in RandomPairs(starts) do
            spawners[#spawners + 1] = ent:GetPos()
        end
        for i = 1, #CONST_DEFAULT_SPAWNS do
            local classname = CONST_DEFAULT_SPAWNS[i]
            local found = ents_FindByClass(classname)
            for k, v in RandomPairs(found) do
                spawners[#spawners + 1] = v:GetPos()
            end
        end
    end
end

getRandSpawn()

hook_Add("InitPostEntity", "OwOmooooove", function()
    getRandSpawn()
end)

hook_Add("ZB_PreRoundStart", "reset_spawns", function()
    zb.ctspawn = nil
    zb.tspawn = nil
end)

function PLAYER_Meta:CanSpawn()
    local round = CurrentRound and CurrentRound()
    if round and round.CanSpawn then
        return round:CanSpawn(self)
    end
    return zb.ROUND_STATE == 0
end

function PLAYER_Meta:GiveEquipment(team_)
end

local function check_playerspawns(SpawnPos, ply, tolerance)
    if not ply:Alive() then return true end
    local usedPos = ply:GetPos()
    local checkdist = 1024 / (math_pow(2, tolerance))
    if usedPos:DistToSqr(SpawnPos) < checkdist * checkdist then
        return false
    end
    return true
end

function zb:GetTeamSpawn(ply)
    local team_ = ply:Team()
    local round = CurrentRound()
    local team0spawns, team1spawns = round:GetTeamSpawn()

    if not team0spawns or not next(team0spawns) then
        team0spawns = {zb:GetRandomSpawn()}
    end
    if not team1spawns or not next(team1spawns) then
        team1spawns = {zb:GetRandomSpawn()}
    end

    local pos
    if team_ == 0 then
        if not zb.tspawn then
            zb.tspawn = table_Random(team0spawns)
            pos = zb.tspawn
        else
            local idx = ply:EntIndex() % 24 + 1
            local clampVal = idx < 1 and 1 or (idx > 24 and 24 or idx)
            pos = hg_tpPlayer(zb.tspawn, ply, clampVal, 0)
        end
        return pos
    else
        if not zb.ctspawn then
            zb.ctspawn = table_Random(team1spawns)
            pos = zb.ctspawn
        else
            local idx = ply:EntIndex() % 24 + 1
            local clampVal = idx < 1 and 1 or (idx > 24 and 24 or idx)
            pos = hg_tpPlayer(zb.ctspawn, ply, clampVal, 0)
        end
        return pos
    end

    ErrorNoHalt("TEAM SPAWN COULDN'T BE FOUND. INVALID TEAM")
    return team0spawns[1]
end

function zb:GetRandomSpawn(target, spawns)
    if not spawns or table_IsEmpty(spawns) then
        spawns = spawners
    end
    if table_IsEmpty(spawns) then
        getRandSpawn()
        spawns = spawners
    end
    if table_IsEmpty(spawns) then return end

    local pos = zb:FurthestFromEveryone(spawns, player_GetAll(), check_playerspawns)
    if isvector(pos) then return pos end

    pos = table_Random(spawners)
    if isvector(pos) then return pos end
end

function zb:FurthestFromEveryone(chooseTbl, restrictTbl, func, iStart, iEnd)
    if not chooseTbl or table_IsEmpty(chooseTbl) then
        chooseTbl = spawners
    end
    if not restrictTbl then
        restrictTbl = player_GetAll()
        func = check_playerspawns
    end

    local startTol = iStart or 1
    local endTol = iEnd or 5
    for tolerance = startTol, endTol do
        for i, SpawnPos in RandomPairs(chooseTbl) do
            if SpawnPos then
                local allow = true
                for j = 1, #restrictTbl do
                    local value = restrictTbl[j]
                    allow = func(SpawnPos, value, tolerance)
                    if allow == false then break end
                end
                if allow then
                    return SpawnPos
                end
            end
        end
    end

    return table_Random(chooseTbl)
end

function PLAYER_Meta:GetRandomSpawn()
    local spawnPos = zb:GetRandomSpawn(self)
    if not spawnPos then return end
    self:SetPos(spawnPos)
end

function GM:PlayerSelectSpawn(ply, transition)
end

local function PlayerSelectSpawn(ply, transition)
    local round = CurrentRound()
    local pos
    if round.randomSpawns then
        pos = zb:GetRandomSpawn()
    else
        pos = zb:GetTeamSpawn(ply) or zb:GetRandomSpawn()
    end
    if isvector(pos) then
        ply:SetPos(pos)
    end
end

function PLAYER_Meta:SetupTeam(team_)
    self:SetTeam(team_)
    hg_CreateInv(self)
    PlayerSelectSpawn(self)
end

function GM:PlayerSpawn(ply)
    ply:SuppressHint("OpeningMenu")
    ply:SuppressHint("Annoy1")
    ply:SuppressHint("Annoy2")

    if OverrideSpawn then return end

    ply.viewmode = 3
    ply:UnSpectate()
    ply:SetMoveType(MOVETYPE_WALK)

    if ply.initialspawn then
        ply:KillSilent()
        ply:SetTeam(1001)
        ply.initialspawn = nil
        return
    end

    local round = CurrentRound()
    if round and not round.OverrideSpawn then
        ply:SetTeam(1001)
        ApplyAppearance(ply, nil, nil, nil, true)
        ply:SetTeam(zb:BalancedChoice(0, 1))
    end
end

function GM:PlayerDisconnected()
end

RunConsoleCommand("mp_show_voice_icons", "0")

util_AddNetworkString("updtime")
function hg.UpdateRoundTime(time, time2, time3)
    zb.ROUND_TIME = time or zb.ROUND_TIME
    zb.ROUND_START = time2 or zb.ROUND_START or CurTime()
    zb.ROUND_BEGIN = time3 or zb.ROUND_BEGIN or CurTime() + 5
    net_Start("updtime")
    net_WriteFloat(zb.ROUND_TIME)
    net_WriteFloat(zb.ROUND_START)
    net_WriteFloat(zb.ROUND_BEGIN)
    net_Broadcast()
end

function GM:PlayerInitialSpawn(ply)
    ply.initialspawn = true
    if #player_GetAll() == 1 then
        RunConsoleCommand("bot")
        hg.addbot = true
        zb:EndRound()
    end
    if #player_GetHumans() > 1 and hg.addbot then
        local bots = player_GetListByName("bot")
        for i = 1, #bots do
            RunConsoleCommand("kick", bots[i]:Name())
        end
        hg.addbot = false
    end
end

function GM:IsSpawnpointSuitable(pl, spawnpointent, bMakeSuitable)
    return true
end

local function getspawnpos()
    local tab = {}
    local tbl = ents_FindByClass("info_player_start")
    for k, v in pairs(tbl) do
        if v:HasSpawnFlags(1) then
            tab[#tab + 1] = v:GetPos()
        end
    end
    if #tab > 0 then
        return tab[1]
    elseif #tbl > 0 then
        return tbl[1]:GetPos()
    end
end

hook_Add("PostCleanupMap", "changelevel_generate", function()
    local round = CurrentRound()
    if round.name ~= "coop" then return end
    local player_pos = getspawnpos()
    if not player_pos then return end
    local dist = 0
    local map = nil
    local maps = {}
    local changelevels = ents_FindByClass("trigger_changelevel")
    for i = 1, #changelevels do
        local mapEnt = changelevels[i]
        local min, max = mapEnt:WorldSpaceAABB()
        local tdmlPos = max - ((max - min) * 0.5)
        maps[mapEnt] = tdmlPos
    end
    local currentMap = game_GetMap()
    for ent, pos in pairs(maps) do
        if ent.map == currentMap then goto skip end
        local dist2 = pos:Distance(player_pos)
        if dist2 > dist then
            dist = dist2
            map = ent
        end
        ::skip::
    end
    if not IsValid(map) then
        map = table_Random(maps)
        if not map then return end
    end
    local min, max = map:WorldSpaceAABB()
    local tdmlPos = max - ((max - min) * 0.5)
    local tdml = ents_Create("coop_mapend")
    tdml:SetPos(tdmlPos)
    tdml:SetAngles(map:GetAngles())
    tdml.min = min
    tdml.max = max
    tdml.map = map.map
    tdml:Spawn()
    tdml:Activate()
end)

local TRIGGER_CHANGELEVEL_CLASS, NPC_COMBINE_S_CLASS, MAP_KEY, ADDITIONAL_EQUIPMENT_KEY, WEAPON_SHOTGUN_VALUE = "trigger_changelevel", "npc_combine_s", "map", "additionalequipment", "weapon_shotgun"

function GM:EntityKeyValue(ent, key, value)
    local class = ent:GetClass()
    if class == TRIGGER_CHANGELEVEL_CLASS and key == MAP_KEY then
        ent.map = value
        ent:AddEFlags(2)
        ent:AddFlags(2)
    end
    if class == NPC_COMBINE_S_CLASS then
        ent:SetLagCompensated(true)
        if key == ADDITIONAL_EQUIPMENT_KEY and value == WEAPON_SHOTGUN_VALUE then
            ent:SetSkin(1)
        end
    end
end

hook_Add("CanProperty", "AntiExploit", function(ply, property, ent)
    if not ply:IsAdmin() then
        return false
    end
end)