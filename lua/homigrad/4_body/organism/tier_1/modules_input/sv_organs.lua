--local Organism = hg.organism
local function isCrush(dmgInfo)
	return not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_BLAST)
end

local function damageOrgan(org, dmg, dmgInfo, key)
	local prot = math.max(0.3 - org[key],0)
	local oldval = org[key]
	org[key] = math.Round(math.min(org[key] + dmg * (isCrush(dmgInfo) and 1 or 3), 1), 3)
	
	//local damage = org[key] - oldval
	//dmgInfo:SetDamage(dmgInfo:GetDamage() + (damage * 5))

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 0 or prot
end

local input_list = hg.organism.input_list
input_list.heart = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.heart

	local result = damageOrgan(org, dmg * 0.3, dmgInfo, "heart")

	hg.AddHarmToAttacker(dmgInfo, (org.heart - oldDmg) * 10, "Heart damage harm")
	
	org.shock = org.shock + dmg * 20
	org.internalBleed = org.internalBleed + (org.heart - oldDmg) * 10

	return result
end

input_list.liver = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.liver
	local prot = math.max(0.3 - org.liver,0)
	
	hg.AddHarmToAttacker(dmgInfo, (org.liver - oldDmg) * 3, "Liver damage harm")
	
	org.shock = org.shock + dmg * 20
	org.painadd = org.painadd + dmg * 35
	
	org.liver = math.min(org.liver + dmg, 1)
	local harmed = (org.liver - oldDmg)
	if org.analgesia < 0.4 and harmed >= 0.2 then
		timer.Simple(0, function()
			if harmed > 0 then -- wtf? whatever
				hg.StunPlayer(org.owner,2)
			else
				hg.LightStunPlayer(org.owner,2)
			end
		end)
	end

	org.internalBleed = org.internalBleed + harmed * 4
	
	dmgInfo:ScaleDamage(0.8)

	return 0
end

input_list.stomach = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.stomach

	local result = damageOrgan(org, dmg, dmgInfo, "stomach")

	hg.AddHarmToAttacker(dmgInfo, (org.stomach - oldDmg) * 2, "Stomach damage harm")
	
	org.internalBleed = org.internalBleed + (org.stomach - oldDmg) * 2
	return result
end

input_list.intestines = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.intestines

	local result = damageOrgan(org, dmg, dmgInfo, "intestines")

	hg.AddHarmToAttacker(dmgInfo, (org.intestines - oldDmg) * 2, "Intestines damage harm")

	org.internalBleed = org.internalBleed + (org.intestines - oldDmg) * 2
	return result
end

input_list.brain = function(org, bone, dmg, dmgInfo)
	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 50 end
	local oldDmg = org.brain
	local result = damageOrgan(org, dmg * 1, dmgInfo, "brain")

	if (org.brain - oldDmg) > 0 then hg.stopBrainfuckOnRagdoll(org) end

	hg.AddHarmToAttacker(dmgInfo, (org.brain - oldDmg) * 15, "Brain damage harm")

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
		local dmgPos = dmgInfo:GetDamagePosition()
		local dirCool = dmgInfo:GetDamageForce():GetNormalized()

		local effdata = EffectData()
		effdata:SetOrigin(dmgPos)
		effdata:SetRadius(dmg / 10)
		effdata:SetMagnitude(dmg / 10)
		effdata:SetScale(1)
		util.Effect("BloodImpact",effdata)

		local ent = hg.GetCurrentCharacter(org.owner)
		
		if !ent.organism.SpawnedBrainChunks and math.random(5) == 1 then
			SpawnMeatGore(ent, dmgPos + dirCool * 5, 3, dirCool * 1000, 0.4)
			ent.organism.SpawnedBrainChunks = true
		end
	end

	if org.brain >= 0.01 and (org.brain - oldDmg) > 0.01 and math.random(3) == 1 then
		org.shock = 70

		timer.Simple(0.1, function()
			if not IsValid(org.owner) then return end
			local rag = hg.GetCurrentCharacter(org.owner)
			if IsValid(rag) and rag:IsRagdoll() then
				hg.stopBrainfuckOnRagdoll(org)
				return
			end
			hg.applyFencingToPlayer(org.owner, org)
		end)
	end

	org.consciousness = math.Approach(org.consciousness, 0, dmg * 3)
	
	org.disorientation = org.disorientation + dmg * 1
	org.shock = org.shock + dmg * 3
	org.painadd = org.painadd + dmg * 10
	return result
end

local angZero = Angle(0, 0, 0)
local vecZero = Vector(0, 0, 0)
local function getlocalshit(ent, bone, dmgInfo, dir, hit)
	if IsValid(ent) and bone then
		ent = hg.GetCurrentCharacter(ent) or ent
		local bonePos, boneAng = ent:GetBonePosition(bone)
		local dmgPos = not isbool(hit) and hit or bonePos
		
		local localPos, localAng = WorldToLocal(dmgPos, angZero, bonePos, boneAng)
		local _, dir2 = WorldToLocal(vecZero, dir:Angle(), vecZero, boneAng)
		dir2 = dir2:Forward()
		return localPos, localAng, dir2
	end
end

local arterySize = {
	["arteria"] = 14,
	["rarmartery"] = 6,
	["larmartery"] = 6,
	["rlegartery"] = 9,
	["llegartery"] = 9,
	["spineartery"] = 10,
}

local arteryMessages = {
	"Я чувствую, как кровь хлещет из шеи...",
	"Моя шея.. она... из нее льяется кровь.",
	"Пиздец, шея и кровь...",
	"У меня кровь хлещет из шеи!"
}

local function hitArtery(artery, org, dmg, dmgInfo, boneindex, dir, hit)
	if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end
	
	local wep = dmgInfo:GetInflictor()
	local chance = (IsValid(wep) and wep.ArteryChance) or 0
	if dmgInfo:IsDamageType(DMG_SLASH) then
		local baseChance = (dmg < 2) and 0.2 or 1.0
		local totalChance = baseChance + chance
		if totalChance < 1 and math.random() > totalChance then return end
	end
	
	org.painadd = org.painadd + dmg * 1
	if org[artery] == 1 then return 0 end
	if org[string.Replace(artery, "artery", "").."amputated"] then return end
	local owner = org.owner

	if artery ~= "arteria" then
		hg.AddHarmToAttacker(dmgInfo, 4, "Random artery punctured harm")//((1 - org[artery]) - math.max((1 - org[artery]) - dmg,0)) / 4
	else
		if org.isPly and not org.otrub then
			org.owner:Notify(table.Random(arteryMessages), true, "arteria", 0)
		end
		
		hg.AddHarmToAttacker(dmgInfo, 15, "Carotid artery punctured harm")
		org.neckslit = true
		org.needfake = true
		
		local ent = hg.GetCurrentCharacter(owner)
		if IsValid(ent) and not org.otrub and not org.needotrub and (owner:IsPlayer() and owner:Alive() or not owner:IsPlayer()) then
			ent:EmitSound("neckslit.ogg", 70, 100, 1, CHAN_AUTO)
		end
		
		local snd = (ThatPlyIsFemale and ThatPlyIsFemale(owner)) and "femaleneck.mp3" or "maleneck.mp3"
		timer.Simple(0, function()
			if IsValid(owner) then
				if owner:IsPlayer() and owner:Alive() then
					hg.Fake(owner, nil, true, true)
				end
				local rag = hg.GetCurrentCharacter(owner)
				if IsValid(rag) and not org.otrub and not org.needotrub and (owner:IsPlayer() and owner:Alive() or not owner:IsPlayer()) then
					rag:EmitSound(snd, 70, 100, 1, CHAN_VOICE)
					org.neckslitSoundName = snd
					org.neckslitSoundEnt = rag
				end
			end
		end)
	end

	org[artery] = math.min(org[artery] + 1, 1)

	local bonea = owner:LookupBone(boneindex)
	local localPos, localAng, dir2 = getlocalshit(owner, bonea, dmgInfo, dir, hit)
	table.insert(org.arterialwounds, {arterySize[artery], localPos, localAng, boneindex, CurTime(), dir2 * 100, artery})
	owner:SetNetVar("arterialwounds", org.arterialwounds)
	--if IsValid(owner:GetNWEntity("RagdollDeath")) then owner:GetNWEntity("RagdollDeath"):SetNetVar("wounds",org.arterialwounds) end
	return 0
end

input_list.arteria = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	return hitArtery("arteria", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
end

input_list.rarmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rarmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.larmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("larmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.rlegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rlegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.llegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("llegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.spineartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return 0 end--hitArtery("spineartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.lungsL = function(org, bone, dmg, dmgInfo)
	local prot = math.max(0.3 - org.lungsL[1],0)
	local oldval = org.lungsL[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung left damage harm")

	org.lungsL[1] = math.min(org.lungsL[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsL[2] = math.min(org.lungsL[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsL[1] - oldval) * 2
	
	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.lungsR = function(org, bone, dmg, dmgInfo)
	local oldval = org.lungsR[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung right damage harm")

	org.lungsR[1] = math.min(org.lungsR[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsR[2] = math.min(org.lungsR[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsR[1] - oldval) * 2

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

local eye_lost_msg = {
	["eyeL"] = {
		"Я не вижу ничего левым глазом...",
		"Мой левый глаз... Я не вижу...",
		"Всё слева просто исчезло...",
	},
	["eyeR"] = {
		"Я не вижу ничего правым глазом...",
		"Мой правый глаз... Я не вижу...",
		"Всё справа просто исчезло...",
	},
}

local eye_stab_msg = {
	["eyeL"] = {
		"Меня проткали в левый глаз...",
		"Что-то вонзилось мне в левый глаз!",
		"Левый глаз... он...",
	},
	["eyeR"] = {
		"Меня проткали в правый глаз...",
		"Что-то вонзилось мне в правый глаз!",
		"Правый глаз... он...",
	},
}

local function damageEye(org, dmg, dmgInfo, key)
	local old = org[key]
	local pierce = dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH)
	local result = damageOrgan(org, dmg * (pierce and 2.5 or 1.5), dmgInfo, key)
	local harmed = org[key] - old
	if harmed <= 0 then return result end

	hg.AddHarmToAttacker(dmgInfo, harmed * 8, key .. " damage harm")

	org.painadd = org.painadd + dmg * 25
	org.shock = org.shock + dmg * 15
	org.disorientation = org.disorientation + harmed * 2

	if org[key] >= 0.85 and old < 0.85 and org.isPly then
		local msgs = dmgInfo:IsDamageType(DMG_SLASH) and eye_stab_msg[key] or eye_lost_msg[key]
		org.owner:Notify(msgs[math.random(#msgs)], true, key, 2)
	end

	if pierce and org[key] >= 0.4 and math.random(4) == 1 then
		org.brain = math.min(org.brain + harmed * 0.12, 1)
	end

	if (org.eyeL or 0) >= 1 and (org.eyeR or 0) >= 1 then
		org.blindness = 1
	end

	if dmg > 0.12 and org.isPly then
		timer.Simple(0, function()
			if IsValid(org.owner) then hg.LightStunPlayer(org.owner, 0.5 + dmg) end
		end)
	end

	return result
end

local function handsFistDmg(dmgInfo)
	if not dmgInfo:IsDamageType(DMG_CLUB) then return false end
	local inf = dmgInfo:GetInflictor()
	if not IsValid(inf) then
		local att = dmgInfo:GetAttacker()
		if IsValid(att) and att:IsPlayer() then inf = att:GetActiveWeapon() end
	end
	return IsValid(inf) and inf:GetClass() == "weapon_hands_sh"
end

local function faceMaskBlocksEye(org)
	local owner = org.owner
	if not IsValid(owner) or not owner.armors or not owner.armors.face then return false end
	if not hg.armor or not hg.armor.face then return false end
	local face = hg.armor.face[owner.armors.face]
	return face and (face.protection or 0) >= 4
end

local function pickEyeSide(org, dmgInfo, boneindex, hit)
	local owner = org.owner
	local ent = IsValid(owner) and (hg.GetCurrentCharacter(owner) or owner)
	if not IsValid(ent) then return end

	local boneName = boneindex or "ValveBiped.Bip01_Head1"
	local bone = ent:LookupBone(boneName)
	if not bone then return end

	local bonePos, boneAng = ent:GetBonePosition(bone)
	if not bonePos then return end

	local dmgPos = isvector(hit) and hit or dmgInfo:GetDamagePosition()
	local localPos = WorldToLocal(dmgPos, angZero, bonePos, boneAng)

	if localPos.z > 0.35 then return "eyeR" end
	if localPos.z < -0.35 then return "eyeL" end
end

function hg.organism.TryHeadEyeHit(org, dmg, dmgInfo, boneindex, hit)
	if not dmgInfo or not dmgInfo.IsDamageType then return end
	local pierce = dmgInfo:IsDamageType(DMG_SLASH)
	local fist = handsFistDmg(dmgInfo)
	if not pierce and not fist then return end
	if dmg < (pierce and 0.04 or 0.06) then return end
	if org._hgHeadEyeRoll == CurTime() then return end
	org._hgHeadEyeRoll = CurTime()
	if faceMaskBlocksEye(org) then return end

	local pool = {}
	if (org.eyeL or 0) < 0.85 then pool[#pool + 1] = "eyeL" end
	if (org.eyeR or 0) < 0.85 then pool[#pool + 1] = "eyeR" end
	if #pool == 0 then return end

	local chance, eyeDmg
	if pierce then
		chance = math.Clamp(dmg * 0.55 + 0.22, 0.35, 0.88)
		eyeDmg = math.Clamp(dmg * 1.85 + 0.55, 0.65, 1.35)
	else
		chance = math.Clamp(dmg * 0.4 + 0.1, 0.15, 0.6)
		eyeDmg = math.Clamp(dmg * 1.35 + 0.4, 0.5, 1.2)
	end
	if math.random() > chance then return end

	local key = pickEyeSide(org, dmgInfo, boneindex, hit)
	if not key or (org[key] or 0) >= 0.85 then
		key = pool[math.random(#pool)]
	end

	damageEye(org, eyeDmg, dmgInfo, key)
end

hg.organism.TryFistPopEye = hg.organism.TryHeadEyeHit
hg.organism.tfpeye = hg.organism.TryHeadEyeHit

input_list.eyeL = function(org, bone, dmg, dmgInfo)
	return damageEye(org, dmg, dmgInfo, "eyeL")
end

input_list.eyeR = function(org, bone, dmg, dmgInfo)
	return damageEye(org, dmg, dmgInfo, "eyeR")
end

input_list.trachea = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.trachea

	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 5 end

	local result = damageOrgan(org, dmg * 2, dmgInfo, "trachea")

	hg.AddHarmToAttacker(dmgInfo, (org.trachea - oldDmg) * 8, "Trachea damage harm")

	//org.internalBleed = org.internalBleed + dmg * 2

	return result
end

hook.Add("HomigradDamage", "HG_HeadEyeHit", function(ply, dmgInfo, hitgroup, ent)
	if hitgroup ~= HITGROUP_HEAD then return end
	local org = IsValid(ent) and ent.organism
	if not org or org.superfighter then return end
	hg.organism.TryHeadEyeHit(org, dmgInfo:GetDamage() / 25, dmgInfo)
end)