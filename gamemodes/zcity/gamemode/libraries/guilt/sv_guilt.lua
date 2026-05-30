zb = zb or {}

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer",0,FCVAR_SERVER_CAN_EXECUTE,"Toggle developer mode (enables damage traces)",0,1)
local guiltFilePath = "zcity/guilt.json"

file.CreateDir("zcity")

local function saveGuiltData()
    local out = {}

    for steamID64, data in pairs(zb.GuiltSQL.PlayerInstances) do
        local value = tonumber(data and data.value)
        if value then
            out[steamID64] = {
                value = value,
                steam_name = data.steam_name or ""
            }
        end
    end

    file.Write(guiltFilePath, util.TableToJSON(out, true) or "{}")
end

local function loadGuiltData()
    local raw = file.Read(guiltFilePath, "DATA")
    if not raw or raw == "" then
        zb.GuiltSQL.PlayerInstances = {}
        return
    end

    local decoded = util.JSONToTable(raw)
    if not istable(decoded) then
        zb.GuiltSQL.PlayerInstances = {}
        return
    end

    local loaded = {}
    for steamID64, data in pairs(decoded) do
        local value = tonumber(istable(data) and data.value or data)
        if value then
            loaded[steamID64] = {
                value = value,
                steam_name = istable(data) and (data.steam_name or "") or ""
            }
        end
    end

    zb.GuiltSQL.PlayerInstances = loaded
end

loadGuiltData()

hook.Add("Initialize", "GuiltLoadData", loadGuiltData)
hook.Add("ShutDown", "GuiltSaveData", saveGuiltData)

hook.Add( "PlayerInitialSpawn","ZB_GuiltSQL", function( ply )
    local name = ply:Name()
	local steamID64 = ply:SteamID64()
    local data = zb.GuiltSQL.PlayerInstances[steamID64]
    if not data then
        data = {
            value = 100,
            steam_name = name
        }
        zb.GuiltSQL.PlayerInstances[steamID64] = data
        saveGuiltData()
    else
        data.value = tonumber(data.value) or 100
        data.steam_name = name
    end

    ply.Karma = ply:guilt_GetValue()
    ply:SetNetVar("Karma", ply.Karma)

    if data.value < 0 then
        ply:guilt_SetValue(10)
        local karma = ply.Karma

        ply.Karma = 10
        ply:SetNetVar("Karma", ply.Karma)

        timer.Simple(0, function()
            if not IsValid(ply) then return end
            ply:Ban(5, false)
            ply:Kick("Твоя карма слишком низкая: " .. math.Round(karma, 0) .. ". Попробуй через 5 минут.")
        end)
    end
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()

    return zb.GuiltSQL.PlayerInstances[self:SteamID64()] and zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or 100

end

function plyMeta:guilt_SetValue( zb_guilt )
    local steamID64 = self:SteamID64()

    zb.GuiltSQL.PlayerInstances[steamID64] = zb.GuiltSQL.PlayerInstances[steamID64] or {}
    zb.GuiltSQL.PlayerInstances[steamID64].value = tonumber(zb_guilt) or 100
    zb.GuiltSQL.PlayerInstances[steamID64].steam_name = IsValid(self) and self:Name() or (zb.GuiltSQL.PlayerInstances[steamID64].steam_name or "")

    saveGuiltData()
end

local function IsLookingAt(ply, targetVec, minDot)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    local len = diff:Length()
    if len < 1 then return false end
    return ply:GetAimVector():Dot(diff) / len >= (minDot or 0.8)
end

function zb.IsHmcdAntagonist(ply)
    return IsValid(ply) and ply.isTraitor
end

function zb.KarmaSkipTeamHarm(att, vic)
    local rnd = CurrentRound()
    if not rnd or rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return true end
    if not IsValid(att) or not IsValid(vic) or att == vic or not vic:IsPlayer() then return true end
    if zb.VictimIsHeadcrabThreat(vic) then return true end

    if rnd.name == "hmcd" then
        if zb.IsHmcdAntagonist(vic) and not zb.IsHmcdAntagonist(att) then return true end
        if zb.IsHmcdAntagonist(att) and not zb.IsHmcdAntagonist(vic) then return true end
    elseif att:Team() ~= vic:Team() then
        return true
    end

    if zb.ROUND_STATE != 1 and (rnd.name != "cstrike" or not zb.RoundsLeft) then return true end
    if att:IsBerserk() then return true end

    return false
end

function zb.KarmaSync(ply, persist)
    if not IsValid(ply) then return end
    ply:SetNetVar("Karma", ply.Karma)
    if persist and ply.guilt_SetValue then ply:guilt_SetValue(ply.Karma) end
end

local function karmaBanIfNeeded(att)
    if not IsValid(att) or (att.Karma or 100) > 0 then return end

    local steamID, name = att:SteamID(), att:Name()
    att:guilt_SetValue(10)

    timer.Create("simplewaitforkarmadrop" .. att:EntIndex(), 0, 1, function()
        if ULib then
            ULib.addBan(steamID, 60, "Kicked and banned for having too low karma.", name, "System")
        end
    end)
end

function zb.ApplyKarmaLoss(att, vic, amount, opts)
    if not amount or amount <= 0 then return false end
    opts = opts or {}
    if zb.KarmaSkipTeamHarm(att, vic) then return false end

    zb.GuiltTable[att] = zb.GuiltTable[att] or {}
    zb.GuiltTable[vic] = zb.GuiltTable[vic] or {}

    if not opts.skipProvoked then
        local harmFromVictim = (zb.HarmDone[att] and zb.HarmDone[att][vic]) or 0
        if harmFromVictim > 0 then return false end
    end

    if vic.Guilt and vic.Guilt > 1 and not zb.IsForce(att) then return false end

    local guiltadd = opts.guiltadd or (amount / (zb.MaximumHarm or 10)) * 30
    local retal = math.min((zb.GuiltTable[vic][att] or 0) / 60, 1)
    local loss = amount * math.max(1 - retal, 0)
    if loss <= 0 then return false end

    zb.GuiltTable[att][vic] = math.Clamp((zb.GuiltTable[att][vic] or 0) + guiltadd, 0, 200)
    att.Guilt = (att.Guilt or 0) + guiltadd
    att.Karma = math.Clamp((att.Karma or 100) - loss, -60, zb.MaxKarma)
    zb.KarmaSync(att, opts.persist)

    if opts.trackHarm ~= false then
        zb.HarmDoneKarma[vic] = zb.HarmDoneKarma[vic] or {}
        zb.HarmDoneKarma[vic][att] = (zb.HarmDoneKarma[vic][att] or 0) + loss
    end

    karmaBanIfNeeded(att)

    if opts.notify and att.Notify then
        att:Notify(opts.notifyMsg or ("-" .. math.Round(loss, 0) .. " кармы."), opts.notifyTime or 5, opts.notifyIcon or "guilt", 1, nil, opts.notifyCol or Color(255, 80, 80))
    end

    return true, loss
end

function zb.VictimIsHeadcrabThreat(victim)
	if not IsValid(victim) then return false end
	if victim:IsPlayer() then
		if victim.PlayerClassName == "headcrabzombie" then return true end
		if victim:GetNetVar("headcrab") then return true end
		local org = victim.organism
		if org and org.headcrabon then return true end
		return false
	end
	local owner = hg.RagdollOwner and hg.RagdollOwner(victim)
	if IsValid(owner) and owner:IsPlayer() then
		return zb.VictimIsHeadcrabThreat(owner)
	end
	return false
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm) 
    local Attacker, Victim = dmgInfo:GetAttacker(), ply
    
    --[[if !IsValid(Attacker) and dmgInfo:GetInflictor().steamid then
        local steamid = dmgInfo:GetInflictor().steamid
        
        ULib.addBan( steamid, 60, "Kicked and banned for trying to exploit karma system.", steamid, "System" )
    end--]]

    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
    if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism.fakePlayer and Victim.organism.alive)) then return end
	if Victim:IsNPC() or Victim:IsNextBot() then return end

    Victim = hg.GetCurrentCharacter(Victim) or Victim
    Victim = hg.RagdollOwner(Victim) or Victim

    local id = Victim:IsPlayer() and Victim:SteamID() or Victim:EntIndex()
    local id2 = Attacker:IsPlayer() and Attacker:SteamID() or Attacker:EntIndex()
    local maxharm = zb.MaximumHarm
    zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
    zb.HarmDoneDetailed[id] = zb.HarmDoneDetailed[id] or {}
    zb.HarmDoneKarma[Victim] = zb.HarmDoneKarma[Victim] or {}
    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] or 0
    
    local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
    zb.HarmDone[Victim][Attacker] = math.Clamp((zb.HarmDone[Victim][Attacker] or 0) + harm, 0, maxharm)

    Victim.LastAttacked = CurTime()
    Victim.LastAttacker = Attacker
    
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] or 0
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] + harm

    local newharm = math.min(harm + oldharmdone, maxharm)
    local harm = newharm - oldharmdone
    local amt = harm / maxharm
    
    if amt > 0.2 or newharm / maxharm > 0.8 then
        --print("Player "..Attacker:Name().." harmed player "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).." with "..harm.." points.")
        --print("They contributed a total of "..math.Round(newharm / maxharm * 100, 0).."% of "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).."'s death")
    end

    if zb and zb.hostage and Victim == zb.hostage then
        zb.hostageLastTouched = Attacker
    end

    local attackerTeam = dmgInfo:GetInflictor().team or (Attacker:IsPlayer() and Attacker:Team()) or Attacker.team
    zb.HarmDoneDetailed[id][id2] = {
        harm = newharm,
        amt = newharm / maxharm,
        teamVictim = Victim:IsPlayer() and Victim:Team() or Victim.team or -1,
        teamAttacker = attackerTeam or -1,
        lasthitgroup = hitgroup,
        lastdmgtype = dmgInfo:GetDamageType(),
        lastattacked = CurTime(),
    }

    if hg_developer:GetBool() then
        Attacker:ChatPrint("This harm done is: "..math.Round(harm,3))
        Attacker:ChatPrint("Overall amt done is: "..math.Round(amt,3))
        Attacker:ChatPrint("Overall harm done is: "..math.Round(newharm,3))
        Attacker:ChatPrint("Guilt done is: "..math.Round(amt * 60,3))
        Attacker:ChatPrint(" ")
    end

    hook.Run("HarmDone", Attacker, Victim, amt)

    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(1) -- better make it a system that counts kills and gives frags at the end of the round
    end

    local rnd = CurrentRound()
    if zb.KarmaSkipTeamHarm(Attacker, Victim) then return end

    zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
    zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}
    Attacker.LastAttacked = CurTime()

    local harmFromVictim = (zb.HarmDone[Attacker] and zb.HarmDone[Attacker][Victim]) or 0
    local provoked = harmFromVictim > 0
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    
    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(-1)
    end
    
    amt = amt * 1
        * (Victim:IsPlayer() and math.Clamp(((Victim.Karma or 100) / 100), 1, 1.2) or 1)
        * (Victim:IsPlayer() and ((IsLookingAt(Victim, Attacker:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= (90 * 90))))) and 0.5 or 1) or 1)

    local add = amt * maxharm

    add = add * (Victim:IsPlayer() and Attacker:PlayerClassEvent("Guilt", Victim) or 1)
    add = add * 2

    local mul, shouldBanGuilt
    
    if rnd.GuiltCheck then
        mul, shouldBanGuilt = rnd.GuiltCheck(Attacker, Victim, add, harm, amt)

        add = add * (mul or 1)
    end
    
    local guiltadd = amt * 60
    zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, 200)

    if provoked then return end
    if Victim.Guilt and Victim.Guilt > 1 and !zb.IsForce(Attacker) then return end

    local retal = math.min((zb.GuiltTable[Victim][Attacker] or 0) / 60, 1)
    local loss = add * math.max(1 - retal, 0)
    if loss <= 0 then return end

    Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd
    Attacker.Karma = math.Clamp((Attacker.Karma or 100) - loss, -60, zb.MaxKarma)
    zb.KarmaSync(Attacker, false)
    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + loss

    if shouldBanGuilt and Attacker.Guilt >= 100 and ULib then
        ULib.addBan(Attacker:SteamID(), 30, "Kicked and banned for dealing too much team damage.", Attacker:Name(), "System")
    end

    karmaBanIfNeeded(Attacker)
end)

function zb.IsForce(Attacker)
    local cn = Attacker.PlayerClassName
    return cn == "police" or cn == "nationalguard" or cn == "swat"
end

function zb.ForcesAttackedInnocent(self, Victim)
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    local recent = Victim.LastAttacked and Victim.LastAttacked + 10 > CurTime()
    local armed = victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistToSqr(self:GetPos()) <= (72 * 72)))

    return (recent and 0 or 1) + (armed and 0 or 1)
end

hook.Add("PlayerDisconnected","GuiltSaveOnDisconect",function(ply)
    ply:guilt_SetValue( ply.Karma or 100 )
end)

hook.Add("Player Spawn","SlowlyRestoreKarma",function(ply)
    if OverrideSpawn then return end

    ply.lastwarning = nil
    //ply.firstwarning = nil
    ply.Karma = ply.Karma or 100
    ply:SetNetVar("Karma",ply.Karma)
    //ply:guilt_SetValue( ply.Karma or 100 )
    
    ply.Guilt = 0
end)

hook.Add("Player Think", "karmagain", function(ply)
    if (ply.KarmaGainThink or 0) > CurTime() then return end
    ply.KarmaGainThink = CurTime() + 120

    local karma = ply.Karma
    if karma == nil then
        karma = ply:guilt_GetValue()
    end

    karma = karma or 100

    local gain = karma > 100 and 0.1 or (ply.KarmaGain or 0.75)
    local newKarma = math.Clamp(karma + gain, 0, zb.MaxKarma)
    if newKarma == karma then return end

    ply.Karma = newKarma
    zb.KarmaSync(ply, true)
end)

hook.Add("Org Clear","removekarmashaking",function(org)
    org.start_shaking = nil
end)

hook.Add("Should Fake Up", "karma", function(ply)
    if ply.organism and ply.organism.start_shaking then return false end
end)

local seizuremsgs = {
    "бллллхлхмммббммммбмбмб",
    "ббб б-бббббб бллмбмммб",
    "ддгдгг-д бббглгггг",
    "ммммаммммм аагхбгбблллллб",
    "ххел-бббпхпппппх",
    "зззззблзззззззззз",
}
hook.Add("Org Think", "Its_Karma_Bro",function(owner, org, timeValue)
    if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
    if not owner:IsPlayer() or not owner:Alive() then return end
    
    local ply = owner
    
    if (ply.Karma or 100) < 50 then
        if ((math.random(math.Clamp((ply.Karma or 100),20,zb.MaxKarma) * 300) == 1 or org.start_shaking)) then
            hg.StunPlayer(ply)
            local time = 15
            
            ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
                if !IsValid(ply) then return end
                
               -- ply:ChatPrint("У тебя эпилептический припадок.")
            end)

            org.start_shaking = org.start_shaking or (CurTime() + time)
            local ent = hg.GetCurrentCharacter(owner)
            local mul = ((org.start_shaking) - CurTime()) / time
            
            if mul > 0 then
                ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul,750 * mul))
            else
                org.start_shaking = nil
            end
        else
            org.start_shaking = nil
        end
	end

    if (ply.Karma or 100) < 35 then
        if math.random(2000) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end)

hook.Add("ZB_EndRound","savevalues",function()
    for i,ply in player.Iterator() do
        ply:guilt_SetValue( ply.Karma or 100 )
    end
end)

hook.Add("ZB_StartRound","NO_HARM",function()
    for i,ply in player.Iterator() do
        if (ply.Guilt or 0) < 1 then
            ply.KarmaGain = math.Clamp((ply.KarmaGain or 0.25) + 0.25, 0.75, 1.5)
        else
            ply.KarmaGain = 0.25
        end

        //ply:guilt_SetValue( ply.Karma or 100 )
    end
    
    zb.HarmDone = {}
    zb.HarmDoneKarma = {}
    zb.GuiltTable = {}
end)

util.AddNetworkString("get_karma")
net.Receive("get_karma",function(len, ply)
    if not ply:IsAdmin() then return end

    local tbl = {}

    for i,pl in player.Iterator() do
        tbl[pl:UserID()] = pl.Karma
    end

    net.Start("get_karma")
    net.WriteTable(tbl)
    net.Send(ply)
end)

concommand.Add("hg_setkarma",function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    
    local lenargs = #args
    local newply = player.GetListByName(lenargs > 1 and args[1] or ply:Name())[1]

    if not IsValid(newply) then return end
    newply.Karma = tonumber(lenargs > 1 and args[2] or args[1]) or 100
    zb.KarmaSync(newply, true)
end)

util.AddNetworkString("open_guilt_menu")
util.AddNetworkString("forgive_player")

local function guiltMenuPayload(victim)
    local out = {}
    local karmaTbl = zb.HarmDoneKarma[victim] or {}
    local harmTbl = zb.HarmDone[victim] or {}
    for att, karma in pairs(karmaTbl) do
        if karma > 0.01 and IsValid(att) and att:IsPlayer() then
            out[#out + 1] = {
                ent = att:EntIndex(),
                harm = harmTbl[att] or 0,
                karma = karma,
            }
        end
    end
    return out
end

net.Receive("open_guilt_menu", function(_, ply)
    if not IsValid(ply) then return end
    net.Start("open_guilt_menu")
    net.WriteTable(guiltMenuPayload(ply))
    net.Send(ply)
end)

net.Receive("forgive_player", function(_, ply)
    if not IsValid(ply) or ply:Alive() then return end
    local ent = net.ReadEntity()
    if not IsValid(ent) or not ent:IsPlayer() or not zb.HarmDoneKarma[ply] then return end
    local karma = zb.HarmDoneKarma[ply][ent]
    if not karma or karma <= 0 then return end

    ent.Karma = math.Clamp((ent.Karma or 100) + karma, 0, zb.MaxKarma)
    zb.KarmaSync(ent, true)

    if zb.HarmDone[ply] then zb.HarmDone[ply][ent] = 0 end
    zb.HarmDoneKarma[ply][ent] = 0
    net.Start("open_guilt_menu")
    net.WriteTable(guiltMenuPayload(ply))
    net.Send(ply)
end)

hook.Add("ZC_SomeoneGetFallBy","IdiotsMustBeKilled",function(Attacker,Victim)
    if zb.KarmaSkipTeamHarm(Attacker, Victim) then return end
    if Victim.Guilt and Victim.Guilt > 1 then return end

    Attacker.Guilt = Attacker.Guilt or 0
    Attacker.Guilt = Attacker.Guilt < 4 and 5 or Attacker.Guilt 
end)