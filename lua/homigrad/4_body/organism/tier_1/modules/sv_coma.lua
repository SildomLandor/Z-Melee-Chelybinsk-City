local min, max, Clamp, Approach, Rand = math.min, math.max, math.Clamp, math.Approach, math.Rand

hg.organism.module.coma = {}
local module = hg.organism.module.coma

local function gcs(org)
	local eye = org.coma and 1 or (org.otrub and 2 or 4)
	local verbal = org.coma and 1 or Clamp(math.floor(5 - org.brain * 4 - org.shock / 25), 1, 5)
	local motor = Clamp(math.floor(6 - (org.lleg + org.rleg + org.larm + org.rarm) * 1.2 - (org.spine2 >= 0.5 and 2 or 0)), 1, 6)
	return Clamp(eye + verbal + motor, 3, 15)
end

function hg.organism.EnterComa(org, cause)
	if not org or org.coma then return end
	org.coma = true
	org.coma_depth = max(org.coma_depth or 0, 0.35)
	org.coma_time = 0
	org.coma_cause = cause or "unknown"
	org.coma_pre = 0
	org.needotrub = true
	org.consciousness = min(org.consciousness or 0, 0.03)
	org.posturing = (org.brain or 0) > 0.45
	org.incapacitated = true
	org.critical = true
	org.coma_gcs = gcs(org)
	if org.isPly and IsValid(org.owner) then
		org.owner.fullsend = true
		local msg = cause == "brain" and "Can't think... can't wake up..." or cause == "anoxia" and "Air... nowhere..." or "Sinking deeper..."
		org.owner:Notify(msg, 6, "coma", 0)
		hook.Run("HG_OnComa", org.owner, cause)
	end
end

function hg.organism.ExitComa(org, soft)
	if not org or not org.coma then return end
	org.coma = false
	org.coma_depth = soft and (org.coma_depth * 0.5) or 0
	org.coma_cause = nil
	org.posturing = false
	org.coma_after = CurTime() + (soft and 20 or 45)
	org.disorientation = max(org.disorientation or 0, soft and 4 or 7)
	org.consciousness = Clamp((org.consciousness or 0) + 0.25, 0.15, 0.45)
	org.coma_gcs = gcs(org)
	if org.isPly and IsValid(org.owner) then
		org.owner.fullsend = true
		hook.Run("HG_OnWakeComa", org.owner, soft)
	end
end

module[1] = function(org)
	org.coma = false
	org.coma_depth = 0
	org.coma_time = 0
	org.coma_pre = 0
	org.coma_cause = nil
	org.coma_gcs = 15
	org.coma_after = 0
	org.coma_breath = 0
	org.coma_reflex = 0
	org.coma_flicker = 0
	org.coma_otrub_time = 0
end

local function comaRisk(org)
	local brain = org.brain or 0
	local o2 = org.o2 and org.o2[1] or 30
	local score = 0
	if org.otrub then score = score + 1 end
	if brain > 0.45 then score = score + brain * 3 end
	if o2 < 10 then score = score + (10 - o2) * 0.15 end
	if (org.consciousness or 1) < 0.08 then score = score + 2 end
	if org.heartstop then score = score + 3 end
	if (org.tranquilizer or 0) > 1.2 and brain > 0.25 then score = score + 1.5 end
	if (org.blood or 5000) < 2600 then score = score + 0.8 end
	return score
end

local function canRecover(org)
	if org.heartstop or not org.alive then return false end
	if (org.brain or 0) > 0.62 then return false end
	if (org.o2 and org.o2[1] or 30) < 8 then return false end
	if (org.blood or 0) < 2600 then return false end
	if (org.pulse or 0) < 12 then return false end
	if (org.spine2 or 0) >= hg.organism.fake_spine2 then return false end
	if (org.spine3 or 0) >= hg.organism.fake_spine3 then return false end
	local minTime = 35 + (org.coma_depth or 0) * 140
	if (org.coma_time or 0) < minTime then return false end
	if (org.coma_depth or 0) > 0.22 then return false end
	return true
end

local function tryEnterComa(owner, org, timeValue)
	if org.coma then return end

	if not org.otrub then
		org.coma_pre = 0
		org.coma_otrub_time = 0
		return
	end

	org.coma_otrub_time = (org.coma_otrub_time or 0) + timeValue
	local risk = comaRisk(org)
	org.coma_pre = Approach(org.coma_pre or 0, risk > 2 and 1 or 0, timeValue / (risk > 4 and 8 or 22))

	local brain = org.brain or 0
	if brain >= 0.72 then
		hg.organism.EnterComa(org, "brain")
		return
	end

	if org.coma_pre >= 1 and org.coma_otrub_time > 14 then
		hg.organism.EnterComa(org, risk > 5 and "anoxia" or "prolonged")
	end
end

local function comaReflex(owner, org)
	local ent = hg.GetCurrentCharacter(owner)
	if not IsValid(ent) then return end

	local bones = {
		"ValveBiped.Bip01_R_Hand",
		"ValveBiped.Bip01_L_Hand",
		"ValveBiped.Bip01_R_Foot",
		"ValveBiped.Bip01_L_Foot",
	}
	local bone = bones[math.random(#bones)]
	local physBone = ent:TranslateBoneToPhysBone(ent:LookupBone(bone))
	local phys = physBone and ent:GetPhysicsObjectNum(physBone)
	if not IsValid(phys) then return end

	local spine = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Spine"))
	local dir = IsValid(spine) and spine:GetAngles():Up() or Vector(0, 0, 1)
	phys:ApplyForceCenter(dir * Rand(180, 420) + VectorRand() * 40)

	if org.isPly and math.random(3) == 1 then
		ent:EmitSound("snds_jack_hmcd_breathing/" .. (ThatPlyIsFemale(ent) and "f" or "m") .. math.random(4) .. ".wav", 50, 90, 0.35)
	end
end

module[2] = function(owner, org, timeValue)
	if not org.alive then
		if org.coma then org.coma = false end
		return
	end

	tryEnterComa(owner, org, timeValue)

	if org.coma_after and org.coma_after > CurTime() then
		org.disorientation = max(org.disorientation or 0, 3 + (org.coma_after - CurTime()) / 15)
	end

	if not org.coma then return end

	org.coma_time = (org.coma_time or 0) + timeValue
	org.needotrub = true
	org.incapacitated = true
	org.critical = (org.brain or 0) > 0.35 or (org.coma_depth or 0) > 0.5

	local brain = org.brain or 0
	local o2 = org.o2 and org.o2[1] or 30
	local worsening = brain > 0.5 or o2 < 9 or (org.blood or 5000) < 2800 or org.heartstop

	if worsening then
		org.coma_depth = Approach(org.coma_depth or 0, 1, timeValue / 200)
	else
		org.coma_depth = Approach(org.coma_depth or 0, 0, timeValue / 90)
	end

	org.coma_depth = Clamp(org.coma_depth, 0.15, 1)
	org.consciousness = min(org.consciousness or 0, 0.01 + (1 - org.coma_depth) * 0.05)
	org.posturing = brain > 0.42 or org.coma_depth > 0.7
	org.disorientation = max(org.disorientation or 0, 6)

	org.coma_gcs = gcs(org)

	org.coma_breath = (org.coma_breath or 0) + timeValue
	local cheyne = o2 < 12 and math.sin(org.coma_breath * 0.11) or math.sin(org.coma_breath * 0.35)
	local breath = cheyne * (o2 < 12 and 14 or 6) + math.sin(org.coma_breath * 0.08) * 3
	if not org.heartstop and org.heartbeat then
		org.heartbeat = max(org.heartbeat + breath, 10)
	end

	org.coma_reflex = (org.coma_reflex or 0) - timeValue
	if org.coma_reflex <= 0 then
		org.coma_reflex = Rand(25, 70)
		if math.random() < 0.55 + org.coma_depth * 0.25 then
			comaReflex(owner, org)
		end
	end

	if org.coma_flicker > 0 then
		org.coma_flicker = org.coma_flicker - timeValue
		org.consciousness = min(org.consciousness + 0.04, 0.12)
	else
		org.coma_flicker = (org.coma_flicker or 0) - timeValue
	end

	if math.random(800) < 1 + brain * 12 and org.coma_flicker <= 0 then
		org.coma_flicker = 0.35
		org.coma_depth = max(org.coma_depth - 0.03, 0.12)
	end

	if canRecover(org) and comaRisk(org) < 2.2 then
		hg.organism.ExitComa(org)
		org.needotrub = false
	else
		org.needotrub = true
	end
end

hook.Add("HomigradDamage", "ComaBrainTrauma", function(ply, dmgInfo, hitgroup)
	local org = ply.organism
	if not org or org.coma then return end
	if hitgroup ~= HITGROUP_HEAD and hitgroup ~= 1 then return end
	if dmgInfo:GetDamage() < 25 then return end
	org.coma_pre = min((org.coma_pre or 0) + dmgInfo:GetDamage() / 120, 1)
	if org.brain and org.brain > 0.55 and org.otrub then
		timer.Simple(0, function()
			if IsValid(ply) and ply.organism and ply.organism.otrub and not ply.organism.coma then
				hg.organism.EnterComa(ply.organism, "trauma")
			end
		end)
	end
end)
