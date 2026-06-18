zb = zb or {}

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}

local plyMeta = FindMetaTable("Player")
local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)
local zb_dev = ConVarExists("zb_dev") and GetConVar("zb_dev")
local guiltFilePath = "zcity/guilt.json"

local medicalWeps = {
	weapon_morphine = true,
	weapon_fentanyl = true,
}

file.CreateDir("zcity")

local function saveGuiltData()
	local out = {}
	for steamID64, data in pairs(zb.GuiltSQL.PlayerInstances) do
		local value = tonumber(data and data.value)
		if value then
			out[steamID64] = {
				value = value,
				steam_name = data.steam_name or "",
			}
		end
	end
	file.Write(guiltFilePath, util.TableToJSON(out, true) or "{}")
end

local function scheduleSaveGuiltData()
	timer.Create("GuiltSaveDebounce", 2, 1, saveGuiltData)
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
				steam_name = istable(data) and (data.steam_name or "") or "",
			}
		end
	end
	zb.GuiltSQL.PlayerInstances = loaded
end

loadGuiltData()
hook.Add("Initialize", "GuiltLoadData", loadGuiltData)
hook.Add("ShutDown", "GuiltSaveData", saveGuiltData)

function plyMeta:guilt_GetValue()
	local row = zb.GuiltSQL.PlayerInstances[self:SteamID64()]
	return row and row.value or zb.DefaultKarma
end

function plyMeta:guilt_SetValue(val)
	local steamID64 = self:SteamID64()
	zb.GuiltSQL.PlayerInstances[steamID64] = zb.GuiltSQL.PlayerInstances[steamID64] or {}
	zb.GuiltSQL.PlayerInstances[steamID64].value = tonumber(val) or zb.DefaultKarma
	zb.GuiltSQL.PlayerInstances[steamID64].steam_name = IsValid(self) and self:Name() or (zb.GuiltSQL.PlayerInstances[steamID64].steam_name or "")
	scheduleSaveGuiltData()
end

local function ownerPlayer(ent)
	if not IsValid(ent) then return end
	if ent:IsPlayer() then return ent end
	return hg.RagdollOwner and hg.RagdollOwner(ent) or nil
end

function zb.IsHmcdAntagonist(ply)
	return IsValid(ply) and ply.isTraitor
end

function zb.GuiltRoundLive()
	local rnd = CurrentRound and CurrentRound()
	if not rnd or rnd.GuiltDisabled then return false end
	if zb_dev and zb_dev:GetBool() then return false end
	return zb.ROUND_STATE == 1
end

function zb.KarmaSkipTeamHarm(att, vic)
	local rnd = CurrentRound and CurrentRound()
	if not rnd or rnd.GuiltDisabled or (zb_dev and zb_dev:GetBool()) then return true end

	att = ownerPlayer(att) or att
	vic = ownerPlayer(vic) or vic

	if not IsValid(att) or not IsValid(vic) or att == vic or not vic:IsPlayer() then return true end
	if not zb.GuiltActive(att) or not zb.GuiltActive(vic) then return true end
	if zb.VictimIsHeadcrabThreat and zb.VictimIsHeadcrabThreat(vic) then return true end

	if rnd.name == "hmcd" then
		if zb.IsHmcdAntagonist(vic) and not zb.IsHmcdAntagonist(att) then return true end
		if zb.IsHmcdAntagonist(att) and not zb.IsHmcdAntagonist(vic) then return true end
	elseif att:Team() ~= vic:Team() then
		return true
	end

	if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return true end
	if att:IsBerserk() then return true end

	return false
end

function zb.KarmaSync(ply, persist)
	if not IsValid(ply) then return end
	ply:SetNetVar("Karma", ply.Karma)
	if persist then ply:guilt_SetValue(ply.Karma) end
end

local function karmaBanIfNeeded(att)
	if not IsValid(att) or (att.Karma or zb.DefaultKarma) > 0 then return end

	local steamID, name = att:SteamID(), att:Name()
	att.Karma = 10
	zb.KarmaSync(att, true)

	if not ULib then
		att:Kick("Слишком низкая карма")
		return
	end

	timer.Create("simplewaitforkarmadrop" .. att:EntIndex(), 0, 1, function()
		ULib.addBan(steamID, 60, "Слишком низкая карма", name, "System")
	end)
end

local function guiltSkipMedical(att)
	local wep = IsValid(att) and att:GetActiveWeapon()
	return IsValid(wep) and medicalWeps[wep:GetClass()] or false
end

local function isLookingAt(ply, targetVec, minDot)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	local diff = targetVec - ply:GetShootPos()
	local len = diff:Length()
	if len < 1 then return false end
	return ply:GetAimVector():Dot(diff) / len >= (minDot or 0.8)
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

function zb.IsForce(att)
	local cn = att.PlayerClassName
	return cn == "police" or cn == "nationalguard" or cn == "swat"
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

	local guiltadd = opts.guiltadd or (amount / zb.MaximumHarm) * zb.GuiltPerHarmAmt
	local retal = zb.GuiltRetal(zb.GuiltTable[vic][att])
	local loss = amount * math.max(1 - retal, 0) * (att.MentKarmaLossMul or 1)
	if loss <= 0 then return false end

	zb.GuiltTable[att][vic] = math.Clamp((zb.GuiltTable[att][vic] or 0) + guiltadd, 0, zb.MaxGuiltPair)
	att.Guilt = (att.Guilt or 0) + guiltadd
	att.Karma = math.Clamp((att.Karma or zb.DefaultKarma) - loss, zb.MinKarma, zb.MaxKarma)
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

hook.Add("PlayerInitialSpawn", "ZB_GuiltSQL", function(ply)
	local steamID64 = ply:SteamID64()
	local data = zb.GuiltSQL.PlayerInstances[steamID64]
	if not data then
		data = { value = zb.DefaultKarma, steam_name = ply:Name() }
		zb.GuiltSQL.PlayerInstances[steamID64] = data
		saveGuiltData()
	else
		data.value = tonumber(data.value) or zb.DefaultKarma
		data.steam_name = ply:Name()
	end

	ply.Karma = ply:guilt_GetValue()
	ply:SetNetVar("Karma", ply.Karma)

	if data.value < 0 then
		ply:guilt_SetValue(10)
		ply.Karma = 10
		ply:SetNetVar("Karma", ply.Karma)
		local karma = data.value
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			ply:Ban(5, false)
			ply:Kick("Твоя карма слишком низкая: " .. math.Round(karma, 0) .. ". Попробуй через 5 минут.")
		end)
	end
end)

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm)
	local Attacker = dmgInfo:GetAttacker()
	local Victim = ply

	if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
	if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism and Victim.organism.fakePlayer and Victim.organism.alive)) then return end
	if Victim:IsNPC() or Victim:IsNextBot() then return end
	if guiltSkipMedical(Attacker) then return end
	if (harm or 0) <= 0 then return end

	Victim = hg.GetCurrentCharacter(Victim) or Victim
	Victim = hg.RagdollOwner(Victim) or Victim
	if not Victim:IsPlayer() then return end

	local maxharm = zb.MaximumHarm
	local id = Victim:SteamID()
	local id2 = Attacker:SteamID()

	zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
	zb.HarmDoneDetailed[id] = zb.HarmDoneDetailed[id] or {}
	zb.HarmDoneKarma[Victim] = zb.HarmDoneKarma[Victim] or {}
	zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] or 0

	local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
	local newharm = math.min(harm + oldharmdone, maxharm)
	local harmdelta = newharm - oldharmdone

	zb.HarmDone[Victim][Attacker] = newharm
	Victim.LastAttacked = CurTime()
	Victim.LastAttacker = Attacker

	zb.HarmAttacked[Attacker] = (zb.HarmAttacked[Attacker] or 0) + harm

	local amt = harmdelta / maxharm
	local attackerTeam = dmgInfo:GetInflictor().team or (Attacker:IsPlayer() and Attacker:Team()) or Attacker.team

	zb.HarmDoneDetailed[id][id2] = {
		harm = newharm,
		amt = newharm / maxharm,
		teamVictim = Victim:Team(),
		teamAttacker = attackerTeam or -1,
		lasthitgroup = hitgroup,
		lastdmgtype = dmgInfo:GetDamageType(),
		lastattacked = CurTime(),
	}

	if zb and zb.hostage and Victim == zb.hostage then
		zb.hostageLastTouched = Attacker
	end

	hook.Run("HarmDone", Attacker, Victim, amt)

	if not zb.GuiltRoundLive() then return end
	if zb.KarmaSkipTeamHarm(Attacker, Victim) then return end

	local rnd = CurrentRound()
	if not rnd then return end

	zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
	zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}
	Attacker.LastAttacked = CurTime()

	local provoked = ((zb.HarmDone[Attacker] and zb.HarmDone[Attacker][Victim]) or 0) > 0
	local victimWep = IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()

	amt = amt * zb.GuiltKarmaMul(Victim)
		* ((isLookingAt(Victim, Attacker:EyePos()) and victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= 8100))) and 0.5 or 1)

	local add = zb.GuiltKarmaLossFromAmt(amt)
	local guiltMul = Attacker:PlayerClassEvent("Guilt", Victim) or 1
	if guiltMul <= 0 then guiltMul = 1 end
	add = add * guiltMul

	local mul, shouldBanGuilt
	if rnd.GuiltCheck then
		mul, shouldBanGuilt = rnd.GuiltCheck(Attacker, Victim, add, harmdelta, amt)
		add = add * (mul or 1)
	end

	local guiltadd = zb.GuiltAddFromAmt(amt)
	zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, zb.MaxGuiltPair)

	if provoked then return end
	if Victim.Guilt and Victim.Guilt > 1 and not zb.IsForce(Attacker) then return end
	if harmdelta < 0.5 then return end

	local retal = zb.GuiltRetal(zb.GuiltTable[Victim][Attacker])
	local loss = add * math.max(1 - retal, 0) * (Attacker.MentKarmaLossMul or 1)
	if loss < 1 then return end

	Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd
	Attacker.Karma = math.Clamp((Attacker.Karma or zb.DefaultKarma) - loss, zb.MinKarma, zb.MaxKarma)
	zb.KarmaSync(Attacker, false)
	zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + loss

	if hg_developer:GetBool() then
		Attacker:ChatPrint("[guilt] amt=" .. math.Round(amt, 4) .. " loss=" .. math.Round(loss, 4))
	end

	if shouldBanGuilt and Attacker.Guilt >= zb.GuiltBanThreshold and ULib then
		ULib.addBan(Attacker:SteamID(), 30, "Забанен за большой урон своим тиммейтам", Attacker:Name(), "System")
	end

	karmaBanIfNeeded(Attacker)
end)

function zb.ForcesAttackedInnocent(self, Victim)
	local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
	local recent = Victim.LastAttacked and Victim.LastAttacked + 10 > CurTime()
	local armed = victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistToSqr(self:GetPos()) <= 5184))
	return (recent and 0 or 1) + (armed and 0 or 1)
end

hook.Add("Player Spawn", "SlowlyRestoreKarma", function(ply)
	if OverrideSpawn then return end
	ply.lastwarning = nil
	ply.Karma = ply.Karma or zb.DefaultKarma
	ply:SetNetVar("Karma", ply.Karma)
	ply.Guilt = 0
end)

hook.Add("Player Think", "karmagain", function(ply)
	if not zb.GuiltKarmaGainAllowed(ply) then return end
	if (ply.KarmaGainThink or 0) > CurTime() then return end
	ply.KarmaGainThink = CurTime() + 120

	local karma = ply.Karma or ply:guilt_GetValue() or zb.DefaultKarma
	local gain = zb.GuiltKarmaGain(ply, karma)
	local newKarma = math.Clamp(karma + gain, zb.MinKarma, zb.MaxKarma)
	if newKarma == karma then return end

	ply.Karma = newKarma
	zb.KarmaSync(ply, true)
end)

hook.Add("Org Think", "Its_Karma_Bro", function(owner, org)
	if not zb.GuiltActive(owner) or not org.isPly or org.otrub then return end
	if (owner.Karma or zb.DefaultKarma) >= 35 or math.random(2000) ~= 1 then return end
	hg.organism.Vomit(owner)
end)

hook.Add("PlayerDisconnected", "GuiltSaveOnDisconect", function(ply)
	ply:guilt_SetValue(ply.Karma or zb.DefaultKarma)
end)

hook.Add("ZB_EndRound", "savevalues", function()
	for _, ply in player.Iterator() do
		ply:guilt_SetValue(ply.Karma or zb.DefaultKarma)
	end
end)

hook.Add("ZB_StartRound", "NO_HARM", function()
	for _, ply in player.Iterator() do
		if (ply.Guilt or 0) < 1 then
			ply.KarmaGain = math.Clamp((ply.KarmaGain or 0.25) + 0.25, 0.75, 1.5)
		else
			ply.KarmaGain = 0.25
		end
	end

	zb.HarmDone = {}
	zb.HarmDoneKarma = {}
	zb.GuiltTable = {}
end)

hook.Add("ZC_SomeoneGetFallBy", "IdiotsMustBeKilled", function(Attacker, Victim)
	if zb.KarmaSkipTeamHarm(Attacker, Victim) then return end
	if Victim.Guilt and Victim.Guilt > 1 then return end

	Attacker.Guilt = Attacker.Guilt or 0
	Attacker.Guilt = Attacker.Guilt < 4 and 5 or Attacker.Guilt
end)

util.AddNetworkString("get_karma")
net.Receive("get_karma", function(_, ply)
	if not ply:IsAdmin() then return end

	local tbl = {}
	for _, pl in player.Iterator() do
		tbl[pl:UserID()] = pl.Karma
	end

	net.Start("get_karma")
	net.WriteTable(tbl)
	net.Send(ply)
end)

concommand.Add("hg_setkarma", function(ply, _, args)
	if not ply:IsAdmin() then return end

	local lenargs = #args
	local newply = player.GetListByName(lenargs > 1 and args[1] or ply:Name())[1]
	if not IsValid(newply) then return end

	newply.Karma = tonumber(lenargs > 1 and args[2] or args[1]) or zb.DefaultKarma
	zb.KarmaSync(newply, true)
end)

util.AddNetworkString("open_guilt_menu")
util.AddNetworkString("forgive_player")

local function guiltMenuPayload(victim)
	local out = {}
	local karmaTbl = zb.HarmDoneKarma[victim] or {}
	local harmTbl = zb.HarmDone[victim] or {}

	for att, karma in pairs(karmaTbl) do
		if karma >= 1 and IsValid(att) and att:IsPlayer() and (harmTbl[att] or 0) >= 1 then
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

	ent.Karma = math.min((ent.Karma or zb.DefaultKarma) + karma, zb.MaxKarma)
	zb.KarmaSync(ent, true)

	if zb.HarmDone[ply] then zb.HarmDone[ply][ent] = 0 end
	zb.HarmDoneKarma[ply][ent] = 0

	net.Start("open_guilt_menu")
	net.WriteTable(guiltMenuPayload(ply))
	net.Send(ply)
end)
