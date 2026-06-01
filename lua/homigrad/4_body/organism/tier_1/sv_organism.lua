--local Organism = hg.organism
hg.organism.module = hg.organism.module or {}
local module = hg.organism.module
hg.organism.lastindex = hg.organism.lastindex or 1000000
hook.Add("Org Clear", "Main", function(org)
	org.alive = true
	org.otrub = false
	org.entindex = IsValid(org.owner) and org.owner:EntIndex() or hg.organism.lastindex + 1
	module.pulse[1](org)
	module.pepper[1](org)
	module.blood[1](org)
	module.pain[1](org)
	module.stamina[1](org)
	module.lungs[1](org)
	module.liver[1](org)
	module.metabolism[1](org)
	module.random_events[1](org)
	module.coma[1](org)
	org.brain = 0
	org.eyeL = 0
	org.eyeR = 0
	org.consciousness = 1
	org.disorientation = 0
	org.jaw = 0
	org.spine1 = 0
	org.spine2 = 0
	org.spine3 = 0
	org.chest = 0
	org.pelvis = 0
	org.skull = 0
	org.stomach = 0
	org.intestines = 0

	org.thiamine = 0

	org.lleg = 0
	org.rleg = 0
	org.larm = 0
	org.rarm = 0
	org.llegdislocation = false
	org.rlegdislocation = false
	org.rarmdislocation = false
	org.larmdislocation = false
	org.jawdislocation = false

	org.llegamputated = false
	org.rlegamputated = false
	org.rarmamputated = false
	org.larmamputated = false
	org.headamputated = false

	org.furryinfected = false

	org.health = 100
	org.canmove = true
	org.recoilmul = 1
	org.legstrength = 1
	org.meleespeed = 1
	org.temperature = 36.7
	org.superfighter = false
	org.CantCheckPulse = nil
	org.HEV = nil
	org.bleedingmul = 1

	--\\ info for rp addition
	org.last_heartbeat = CurTime()
	org.bulletwounds = 0
	org.stabwounds = 0
	org.slashwounds = 0
	org.bruises = 0
	org.burns = 0
	org.explosionwounds = 0

	org.fear = 0
	org.fearadd = 0
	--//

	org.assimilated = 0
	org.berserk = 0
	org.noradrenaline = 0

	org.blindness = nil
	org.neckslitSoundName = nil
	org.neckslitSoundEnt = nil

	if IsValid(org.owner) then
		if org.owner:IsPlayer() and org.owner:Alive() then
			org.owner:SetHealth(100)
			org.owner:SetNetVar("wounds",{})
			org.owner:SetNetVar("arterialwounds",{})
		end

		org.owner:SetNetVar("zableval_masku", false)
	end

	org.allowholster = false
	
	org.just_damaged_bone = nil
	org.LodgedEntities = nil
	
	org.dmgstack = {}

	org.SpawnedBrainChunks = nil
	org._sentFull = nil
end)

hook.Add("Should Fake Up", "organism", function(ply)
	local org = ply.organism
	if org.otrub or org.fake or org.spine1 >= hg.organism.fake_spine1 or org.spine2 >= hg.organism.fake_spine2 or org.spine3 >= hg.organism.fake_spine3 or (org.lleg == 1 and org.rleg == 1) and org.berserk <= 0.3 or (org.blood < 2900) or org.consciousness <= 0.4 then
		return false
	end
end)

local hg_unreliable_nets = ConVarExists("hg_unreliable_nets") and GetConVar("hg_unreliable_nets") or CreateConVar("hg_unreliable_nets", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, "Toggle unreliable net messages for some of the expensive nets", 0, 1)

util.AddNetworkString("organism_send")
util.AddNetworkString("organism_sendply")
local CurTime = CurTime
local nullTbl = {}
local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)
local function send_organism(org, ply)
	if not IsValid(org.owner) then return end

	local keys = hg.orgFullKeys
	local payload = not hg_developer:GetBool() and hg.orgPick(org, keys) or org
	local force = org.owner.fullsend
	if force then org._sentFull = nil end
	if not force and not hg.orgNeedsSend(payload, org._sentFull, keys) then return end

	net.Start("organism_send", hg_unreliable_nets:GetBool())
	hg.orgNetHeader(org.owner, false)
	org._sentFull = hg.orgWritePacket(payload, org._sentFull, keys, force)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(false)
	net.WriteBool(true)
	net.WriteBool(false)
	if IsValid(ply) and ply:IsPlayer() then
		net.Send(ply)
	else
		net.Broadcast()
	end
	if org.owner == ply or not IsValid(ply) or not ply:IsPlayer() then
		org.owner.fullsend = nil
	end
end

local function send_bareinfo(org)
	if not IsValid(org.owner) then return end

	local keys = hg.orgBareKeys
	local payload = not hg_developer:GetBool() and hg.orgPick(org, keys) or org

	local rf = RecipientFilter()
	rf:AddPVS(org.owner:GetPos())
	if org.owner:IsPlayer() then rf:RemovePlayer(org.owner) end

	net.Start("organism_send", hg_unreliable_nets:GetBool())
	hg.orgNetHeader(org.owner, true)
	hg.orgWritePacket(payload, nil, keys, true)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.Send(rf)
end

hg.send_organism = send_organism
hg.send_bareinfo = send_bareinfo

local META = FindMetaTable("Player")
function META:IsBerserk()
	if !IsValid(self) then return false end
	if self:IsPlayer() and not self:Alive() then return false end

	local org = self.organism
	return org.berserkActive2 or false
end

function META:IsStimulated()
	if !IsValid(self) then return false end
	if self:IsPlayer() and not self:Alive() then return false end

	local org = self.organism
	return org.noradrenalineActive or false
end

local META2 = FindMetaTable("Entity")
function META2:IsBerserk()
	return false
end

function META2:IsStimulated()
	return false
end

local numerical = {
"Один",
"Два",
"Три",
"Четыре",
"Пять",
"Шесть",
"Семь",
"Восемь",
"Девять",
"Десять",
"Одиннадцать",
"Двенадцать",
"Тринадцать",
"Четырнадцать",
"Пятнадцать",
"Шестнадцать",
"Семнадцать",
"Восемнадцать",
"Девятнадцать",
"Двадцать"
}

hook.Add("HomigradDamage", "Berserk", function(ply, dmgInfo, hitgroup, ent)
	local attacker, victim = dmgInfo:GetAttacker(), ply
	if !attacker or !IsValid(attacker) or (IsValid(attacker) and !attacker:IsPlayer()) then
		attacker = ply:GetPhysicsAttacker()
	end

	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if attacker == victim then return end
	if !attacker:IsBerserk() then return end

	timer.Simple(0, function()
		if IsValid(attacker) and IsValid(victim) and not victim:Alive() then
			attacker.BerserkKills = (attacker.BerserkKills or 0) + 1
			attacker:NotifyBerserk(numerical[attacker.BerserkKills] or (attacker.BerserkKills .. "."))

			attacker.organism.berserk = attacker.organism.berserk + 0.5
		end
	end)
end)

hook.Add("Org Think", "Main", function(owner, org, timeValue)
	if not isentity(owner) or not IsValid(owner) then
		hg.organism.list[owner] = nil
		return
	end

	if owner:IsPlayer() and not owner:Alive() then return end

	local isPly = owner:IsPlayer()

	org.isPly = isPly

	if isPly or org.fakePlayer then
		if not org.fakePlayer then
			org.alive = owner:Alive()
		end
	else
		org.alive = false
	end
	
	org.needotrub = false
	org.needfake = false
	if isPly then
		org.ownerFake = org.FakeRagdoll and true
	else
		org.ownerFake = false
	end

	org.timeValue = timeValue
	org.incapacitated = false
	org.critical = false

	if isPly then
		module.stamina[2](owner, org, timeValue)
	end

	if isPly or org.fakePlayer then
		module.lungs[2](owner, org, timeValue)
	end

	if isPly then
		module.liver[2](owner, org, timeValue)
	end

	--module.blood[3](owner,org,timeValue)--arteria
	module.blood[2](owner, org, timeValue)
	local neckslit = false
	if org.arterialwounds then
		for i, wound in pairs(org.arterialwounds) do
			if wound[7] == "arteria" and wound[1] > 0 then
				neckslit = true
				break
			end
		end
	end
	org.neckslit = neckslit

	module.pain[2](owner, org, timeValue)
	if isPly then
		module.metabolism[2](owner, org, timeValue)
		module.random_events[2](owner, org, timeValue)
	end
	module.pulse[2](owner, org, timeValue)
	module.pepper[2](owner, org, timeValue)
	module.coma[2](owner, org, timeValue)

	if org.owner.PlayerClassName == "furry" then
		org.assimilated = 0
	end

	if org.owner.PlayerClassName != "furry" and org.furryinfected then
		org.assimilated = math.Approach(org.assimilated, 1, timeValue / 30 * org.pulse / 70)

		if org.assimilated == 1 then
			hg.Furrify(org.owner)

			org.furryinfected = false
		end
	else
		if (org.lightstun - CurTime()) <= 0 then
			org.assimilated = math.Approach(org.assimilated, 0, (timeValue / 60 * org.pulse / 70) * 6)
		end
	end

	if org.assimilated == 1 then
		org.assimilated = 0
		org.owner:SetPlayerClass("furry")
	end

	org.berserk = math.Approach(org.berserk, 0, timeValue / 60)
	org.noradrenaline = math.Approach(org.noradrenaline, 0, timeValue / 45)

	if org.berserk > 0 and !org.berserkActive then
		org.berserkActive = true

		owner.lastBerserkLaughSoundCD = CurTime() + 5

		timer.Simple(3.95, function()
			org.berserkActive2 = true
		end)
	elseif org.berserk <= 0 then
		org.berserkActive = false
		org.berserkActive2 = false
		owner.BerserkKills = nil
	end

	if org.noradrenaline > 0 and !org.noradrenalineActive then
		org.noradrenalineActive = true
	elseif org.noradrenaline <= 0 then
		org.noradrenalineActive = false
	end

	if (org.llegamputated or org.rlegamputated) and org.berserk <= 0.3 then
		org.needfake = true
	end

	if org.rarmamputated and org.larmamputated and owner:IsPlayer() then
		local hands = owner:GetWeapon("weapon_hands_sh")
		if owner:GetActiveWeapon() != hands then
			owner:SetActiveWeapon(hands)
		end
	end

	--[[if isPly then
		local aimed = false

		local entities = ents.FindInCone(owner:EyePos(), owner:GetAimVector(), 128, math.cos(math.rad(90)))
		for i, ent in ipairs(entities) do
			if !ent:IsPlayer() then continue end
			if ent == owner then continue end

			if ishgweapon(ent:GetActiveWeapon()) and ent:GetAimVector():Dot((ent:EyePos() - owner:EyePos()):GetNormalized()) < -0.95 then
				aimed = true
			end
		end

		if aimed then
			owner.aimed_at = owner.aimed_at or 0
			owner.aimed_at = math.Approach(owner.aimed_at, 1, timeValue / 5)
			org.fearadd = org.fearadd + timeValue * 2
		else
			owner.aimed_at = owner.aimed_at or 0
			owner.aimed_at = math.Approach(owner.aimed_at, 0, timeValue / 5)
		end
	end--]]
	--bullshit

	if org.otrub then
		org.uncon_timer = org.uncon_timer or 0
		org.uncon_timer = org.uncon_timer + timeValue
	else
		org.uncon_timer = 0
	end

	local just_went_uncon = not org.otrub and org.needotrub
	local just_woke_up = not org.needotrub and org.otrub and (org.uncon_timer or 0) > 6 and not org.coma
	if isPly and just_went_uncon then hook.Run("HG_OnOtrub", owner); hook.Run("PlayerDropWeapon", owner) end
	if isPly and just_woke_up then hook.Run("HG_OnWakeOtrub", owner) end

	org.canmove = (org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3) and not org.otrub
	org.canmovehead = (org.spine3 < hg.organism.fake_spine3) and not org.otrub
	
	if isPly then
		if not (org.canmove and org.canmovehead and (org.stun - CurTime()) < 0) then org.needfake = true end
		if (org.blood < 2700) then org.needfake = true end
	elseif owner:IsNPC() then
		org.needfake = false
		org.needotrub = false
		if org.llegamputated and org.rlegamputated
			and hg.organism.NpcIsOrganismZombie
			and hg.organism.NpcIsOrganismZombie(owner) then
			org.canmove = false
			org.legstrength = 0
		end
	end

	if org.neckslit and not org.otrub then org.needfake = true end

	local just_went_uncon = not org.otrub and org.needotrub

	if org.posturing then
		local ent = hg.GetCurrentCharacter(org.owner)
		if IsValid(ent) then
			local spineMat = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Spine"))
			if spineMat then
				local isRag = ent:IsRagdoll()
				org._postureAcc = (org._postureAcc or 0) + timeValue
				local tick = isRag and 0.18 or 0
				if not isRag or org._postureAcc >= tick then
					org._postureAcc = 0
					local force = (isRag and 85 or 500) * (isRag and (0.4 + 0.6 * math.sin(CurTime() * 1.4)) or 1)
					local down = -spineMat:GetAngles():Forward()
					local bones = {"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand"}
					for i = 1, #bones do
						local phys = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone(bones[i])))
						if IsValid(phys) then phys:ApplyForceCenter(down * force) end
					end
				end
			end
		end
	end

	if org.brain < 0.4 then
		local naturalHeal = org.thiamine > 0 and timeValue / 480 or timeValue / 1800
		-- full heal in ~30 minutes (really fast tho) -- Ну не идет столько раунд даже в каких-нибудь скраперсах ну какой даун это придумал
		-- 8 minutes with thiamine -- ДАЖЕ СТОЛЬКО НЕ ВСЕГДА ДЛИТСЯ

		org.thiamine = math.Approach(org.thiamine, 0, timeValue / 240)
		-- you'd need to give 1 thiamine each 4 minutes

		if org.liver < 1 then org.liver = math.Approach(org.liver, 0, naturalHeal) end
		if org.heart < 1 then org.heart = math.Approach(org.heart, 0, naturalHeal) end
		if org.stomach < 1 then org.stomach = math.Approach(org.stomach, 0, naturalHeal) end
		if org.intestines < 1 then org.intestines = math.Approach(org.intestines, 0, naturalHeal) end
		if org.lungsR[1] < 1 then org.lungsR[1] = math.Approach(org.lungsR[1], 0, naturalHeal) end
		if org.lungsL[1] < 1 then org.lungsL[1] = math.Approach(org.lungsL[1], 0, naturalHeal) end
	end

	if org.otrub and isPly and org.owner:Alive() then
		//org.owner:ScreenFade(SCREENFADE.PURGE, color_black, 0.5, 0)
		//org.owner:ConCommand("soundfade 100 99999")
	end

	if not org.otrub and isPly and org.owner:Alive() then
		--org.owner:ConCommand("soundfade 0 1")
	end

	if just_went_uncon then
		org.owner.fullsend = true
	end

	if org.brain > 0.05 then
		if math.random(600) < org.brain * 20 then
			org.needfake = true
		end
	end

	if org.neckslitSoundName and (org.otrub or org.needotrub) then
		if IsValid(org.neckslitSoundEnt) then
			org.neckslitSoundEnt:StopSound(org.neckslitSoundName)
		end
		if IsValid(owner) then
			owner:StopSound(org.neckslitSoundName)
		end
		org.neckslitSoundName = nil
		org.neckslitSoundEnt = nil
	end

	org.otrub = org.needotrub
	org.fake = org.needfake
	
	if org.needfake and owner:IsNPC() then
		org.needfake = false
	end

	if owner:IsPlayer() and (org.healthRegen or 0) < CurTime() then
		org.healthRegen = CurTime() + 30
		owner:SetHealth(math.min(owner:GetMaxHealth(), owner:Health() + math.max(1.5 - org.hurt, 0)))
	end

	org.health = owner:Health()
	local rag = owner:IsPlayer() and owner.FakeRagdoll or owner
	if IsValid(rag) and rag:IsRagdoll() and (not owner.lastFake or owner.lastFake == 0) then
		local vel = rag:GetVelocity():Length()
		local wantNone = vel > 200
		if owner:IsPlayer() and IsValid(owner.FakeRagdoll) and rag == owner.FakeRagdoll and vel < 150 then
			wantNone = false
		end
		if rag._hg_collNone ~= wantNone then
			rag._hg_collNone = wantNone
			rag:SetCollisionGroup(wantNone and COLLISION_GROUP_NONE or COLLISION_GROUP_WEAPON)
		end
	end
	if isPly then
		if org.otrub or org.fake then hg.Fake(owner,nil,true) end
		if not org.alive and owner:Alive() then owner:Kill() end
	end

	if not org.otrub and isPly then
		local mul = hg.likely_to_phrase(owner)

		if not org.likely_phrase then org.likely_phrase = 0 end

		org.likely_phrase = math.max(org.likely_phrase + math.Rand(0, mul) / 100, 0)
		//print(org.likely_phrase)
		if org.likely_phrase >= 1 and !hg.GetCurrentCharacter(owner):IsOnFire() then
			org.likely_phrase = 0

			local str = hg.get_status_message(owner)
			//print(str)
			-- (msg, delay, msgKey, showTime, func, clr)
			owner:Notify(str, 1, "phrase", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), 255))
		end
	end

	if !org.alive then org.otrub = true end

	if !org.alive then
		org.lungsfunction = false
		org.heartstop = true
	end

	time = CurTime()

	if IsValid(owner) then
		org.sendPlyTime = org.sendPlyTime or CurTime()
		if (org.sendPlyTime > time) and !just_went_uncon then return end
		org.sendPlyTime = CurTime() + 1 + (not isPly and 2 or 0)
		send_bareinfo(org)

		hg.organism.SyncWoundNetVars(org.owner, org)

		if isPly and owner:Alive() then
			send_organism(org, owner)
		end
	end
end)

hook.Add("Org Clear", "stroke", function(org)
	org.stroke = 0
	org.stroke_damage = 0
	org.stroke_nextblackout = 0
end)

hook.Add("Org Think", "stroke", function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() or not org.alive then
		org.stroke = math.max((org.stroke or 0) - timeValue * 0.08, 0)
		return
	end

	local hb = tonumber(org.heartbeat) or 0
	local pulse = tonumber(org.pulse) or 0
	local o2 = tonumber(org.o2 and org.o2[1]) or 30
	local blood = tonumber(org.blood) or 5000
	local shock = tonumber(org.shock) or 0
	local temp = tonumber(org.temperature) or 36.7

	local stress = 0
	stress = stress + math.Clamp((hb - 185) / 95, 0, 1) * 1.1
	stress = stress + math.Clamp((pulse - 165) / 70, 0, 1) * 0.9
	stress = stress + math.Clamp((12 - o2) / 12, 0, 1) * 1.4
	stress = stress + math.Clamp((3000 - blood) / 1500, 0, 1) * 0.9
	stress = stress + math.Clamp(shock / 60, 0, 1) * 0.6
	stress = stress + math.Clamp(math.abs(temp - 36.7) / 3.5, 0, 1) * 0.5
	if org.heartstop then stress = stress + 0.5 end

	org.stroke = org.stroke or 0
	local grow = stress > 0 and (timeValue / 16) * stress or 0
	local fall = timeValue / 30
	org.stroke = math.Clamp(org.stroke + grow - fall, 0, 1)

	if org.stroke < 0.2 then return end

	local sev = math.Remap(org.stroke, 0.2, 1, 0, 1)
	org.disorientation = math.Clamp((org.disorientation or 0) + timeValue * 0.12 * sev, 0, 1)

	local brainDmg = timeValue / (sev > 0.75 and 140 or 260) * sev
	org.brain = math.Clamp(org.brain + brainDmg, 0, 1)
	org.stroke_damage = (org.stroke_damage or 0) + brainDmg

	if org.stroke > 0.68 then
		org.incapacitated = true
	end

	if org.stroke > 0.8 and (org.stroke_nextblackout or 0) <= CurTime() then
		org.needotrub = true
		org.stroke_nextblackout = CurTime() + math.Rand(8, 16)
	end

	if org.stroke > 0.92 and math.random() < math.Clamp(timeValue * 0.08, 0, 0.2) then
		org.heartstop = true
	end
end, HOOK_LOW)

hook.Add("Org Think", "regenerationberserk", function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() then return end
	if !owner:IsBerserk() then return end
	//if org.heartstop then return end

	org.blood = math.Approach(org.blood, 5000, timeValue * 60)

	for i, wound in pairs(org.wounds) do
		wound[1] = math.max(wound[1] - timeValue * 10,0)
	end

	for i, wound in pairs(org.arterialwounds) do
		wound[1] = math.max(wound[1] - timeValue * 10,0)
	end

	org.internalBleed = math.max(org.internalBleed - timeValue * 10, 0)

	local regen = timeValue / 120 * org.berserk

	org.lleg = math.max(org.lleg - regen, 0)
	org.rleg = math.max(org.rleg - regen, 0)
	org.rarm = math.max(org.rarm - regen, 0)
	org.larm = math.max(org.larm - regen, 0)
	org.chest = math.max(org.chest - regen, 0)
	org.pelvis = math.max(org.pelvis - regen, 0)
	org.spine1 = math.max(org.spine1 - regen, 0)
	org.spine2 = math.max(org.spine2 - regen, 0)
	org.spine3 = math.max(org.spine3 - regen, 0)
	org.skull = math.max(org.skull - regen, 0)

	org.liver = math.max(org.liver - regen, 0)
	org.intestines = math.max(org.intestines - regen, 0)
	org.heart = math.max(org.heart - regen, 0)
	org.stomach = math.max(org.stomach - regen, 0)
	org.lungsR[1] = math.max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = math.max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = math.max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = math.max(org.lungsL[2] - regen, 0)
	org.brain = math.max(org.brain - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, timeValue * 10)
	org.painadd = math.Approach(org.painadd, 0, timeValue * 10)
	org.avgpain = math.Approach(org.avgpain, 0, timeValue * 10)
	org.shock = math.Approach(org.shock, 0, timeValue * 10)
	org.immobilization = math.Approach(org.immobilization, 0, timeValue * 10)
	org.disorientation = math.Approach(org.disorientation, 0, timeValue * 10)

	org.lungsfunction = true
	org.heartstop = false

	owner:SetRunSpeed(math.min(500, 400 + (25 * org.berserk)))
end)

hook.Add("Org Think", "regenerationnoradrenaline", function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() then return end
	if org.noradrenaline <= 0 then return end
	
	local regen = timeValue / 60 * org.noradrenaline

	org.lungsR[1] = math.max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = math.max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = math.max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = math.max(org.lungsL[2] - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, regen * 10)
	org.painadd = math.Approach(org.painadd, 0, regen * 10)
	org.avgpain = math.Approach(org.avgpain, 0, regen * 10)
	org.shock = math.Approach(org.shock, 0, regen * 10)
	org.immobilization = math.Approach(org.immobilization, 0, regen * 10)
	org.disorientation = math.Approach(org.disorientation, 0, regen * 10)
	org.adrenaline = math.Approach(org.adrenaline, 5, regen * 100)
	org.analgesia = math.Approach(org.analgesia, 1, regen * 10)

	if org.noradrenaline > 2 then
		org.brain = math.Approach(org.brain, 0.3, timeValue / 60)
	end

	org.pulse = math.Approach(org.pulse, 70, regen * 10)
	org.heartbeat = math.Approach(org.heartbeat, 220, regen * 10)
	--org.stamina.regen = math.Approach(org.stamina.regen, 1.2, regen * 10)

	org.lungsfunction = true
	org.heartstop = false
end)

concommand.Add("hg_organism_setvalue", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not args[3] then
		if isbool(ply.organism[args[1]]) then
			ply.organism[args[1]] = tonumber(args[2]) != 0
		else
			ply.organism[args[1]] = tonumber(args[2])
		end
	end

	if args[3] then
		for i,pl in pairs(player.GetListByName(args[3])) do
			if isbool(pl.organism[args[1]]) then
				pl.organism[args[1]] = tonumber(args[2]) != 0
			else
				pl.organism[args[1]] = tonumber(args[2])
			end
		end
	end
end)

concommand.Add("hg_organism_setvalue2", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	ply.organism[args[1]][tonumber(args[2])] = tonumber(args[3])
end)

concommand.Add("hg_organism_clear", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not args[1] then
		hg.organism.Clear(ply.organism)
	end

	if args[1] then
		for i,pl in pairs(player.GetListByName(args[1])) do
			hg.organism.Clear(pl.organism)
		end
	end
end)

hook.Add("SetupMove", "hg-speed", function(ply, mv) end) --mv:SetMaxClientSpeed(100) --mv:SetMaxSpeed(100)

hook.Add("StartCommand","hg_lol",function(ply,cmd)
	if ply.organism.otrub and ply:Alive() then
		cmd:ClearMovement()
	end
end)

hook.Add("PlayerDeath","next-respawn-full",function(ply)
	ply.fullsend = true
end)

hook.Add("HG_OnWakeOtrub", "afterOtrub", function( owner )
	owner.organism.after_otrub = true
	local str = hg.get_status_message(owner)
	owner.organism.after_otrub = nil
	//print(str)
	-- (msg, delay, msgKey, showTime, func, clr)
	timer.Simple(0.1,function()
		if not IsValid(owner) then return end
		owner:Notify(str, 1, "wake", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255)) )
	end)

	owner.organism.fearadd = owner.organism.fearadd + 5

	owner:SendLua("system.FlashWindow()")
end)

hook.Add("HG_OnOtrub", "fearful", function( plya )// ЧЕ
	local ent = hg.GetCurrentCharacter(plya)
	for i,ply in ipairs(ents.FindInSphere(ent:GetPos(),256)) do
		if not ply:IsPlayer() or not ply.organism or plya == ply then continue end

		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ent:GetPos()
		tr.filter = {ply,ent}
		if not util.TraceLine(tr).Hit then
			ply.organism.adrenalineAdd = ply.organism.adrenalineAdd + 0.3
			ply.organism.fearadd = ply.organism.fearadd + 0.3
		end
	end
end)

local unlucky_dislocations = {
	"Почему... Я не могу вправить эту ебанную кость...",
	"Пожалуйста... Почему это так сложно",
	"Просто... Встань на место",
	"Что-то хрустнуло... Надеюсь я не сделал хуже",
	"Я... Я смогу... Просто надо попытаться еще раз...",
}

local finally_fixed = {
	"Кость кажется встала на место",
	"Я СМОГ! Я ВПРАВИЛ ЕЁ!",
	"Наконец-то, я... Смог",
}

local function fixlimb(org, key, fixer)
	if math.random(100) > (97 + (fixer != org.owner and (fixer.organism and fixer.organism.pain or 0) or 0) - (org.analgesia * 50 + org.painkiller * 15) - (fixer != org.owner and 30 or 0) - (fixer.tries or 0) * 10 - (fixer.Profession == "doctor" and 100 or 0) - (org.owner == fixer and (IsValid(org.owner.FakeRagdoll) or (org.owner.Crouching and org.owner:Crouching())) and 10 or 0)) then
		org[key.."dislocation"] = false
		org.painadd = org.painadd + 5 * math.random(1, 3)
		org.fearadd = org.fearadd + 0.1

		org.owner:EmitSound("physics/flesh/flesh_impact_hard6.wav", 65)

		if fixer == org.owner and (fixer.tries or 0) > 3 and math.random(3) == 1 then
			fixer:Notify(finally_fixed[math.random(#finally_fixed)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end

		fixer.tries = 0
	else
		fixer.tries = (fixer.tries or 0) + 1
		org.painadd = org.painadd + 15 * math.random(1, 3)

		org.fearadd = org.fearadd + 0.3

		org.owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(7)..".wav", 65)
		
		if fixer.Profession != "doctor" and math.random(5) == 1 then
			local dmgInfo = DamageInfo()
			dmgInfo:SetDamage(50)
			dmgInfo:SetDamageType(DMG_CLUB)
			local fn = hg.organism.input_list[key.."down"] or hg.organism.input_list[key]
			if fn then
				fn(org.owner.organism, 1, 6, dmgInfo, 0, vector_up)
			end
		end

		if fixer == org.owner and fixer.tries > 3 and math.random(3) == 1 then
			fixer:Notify(unlucky_dislocations[math.random(#unlucky_dislocations)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end
	end
end

concommand.Add("hg_fixdislocation", function(ply, cmd, args)
	local fixer = ply

	if math.Round(tonumber(args[2])) == 1 then
		ply = hg.eyeTrace(fixer).Entity
	end

	if !IsValid(ply) or !ply.organism then return end

	ply = ply.organism.owner

	local org = ply.organism
	if !fixer:Alive() or !org or fixer.organism.otrub then return end
	if (fixer.tried_fixing_limb or 0) > CurTime() then return end
	if !fixer.organism.canmove or !fixer.organism.canmovehead or fixer.organism.pain > 60 then return end
	fixer.tried_fixing_limb = CurTime() + fixer.organism.pain / 30

	if math.Round(tonumber(args[1])) == 1 then
		if org.llegdislocation then
			fixlimb(org, "lleg", fixer)
		elseif org.rlegdislocation then
			fixlimb(org, "rleg", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 2 then
		if org.larmdislocation then
			fixlimb(org, "larm", fixer)
		elseif org.rarmdislocation then
			fixlimb(org, "rarm", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 3 then
		if org.jawdislocation then
			fixlimb(org, "jaw", fixer)
		end
	end
end)

hook.Add("OnEntityWaterLevelChanged", "ClearBlood", function(ent, old, new)
	if new >= 2 then
		if ent:IsOnFire() then ent:Extinguish() end
		ent:RemoveAllDecals()
	end
end)