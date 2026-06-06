local MODE = MODE
MODE.NetSize_ChemicalResistanceBits = 8
local chemical_degrade_speeds = {
	["HCN"] = 1,
	["KCN"] = 0.5,
}

function MODE.SetChemicalToPlayer(ply, chemical_name, amt)
	ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}

	if amt <= 0 then
		ply.PassiveAbility_ChemicalAccumulation[chemical_name] = nil
	else
		ply.PassiveAbility_ChemicalAccumulation[chemical_name] = amt
	end
end

if SERVER then
	function MODE.AddChemicalToPlayer(ply, chemical_name, amount)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		local amt = (ply.PassiveAbility_ChemicalAccumulation[chemical_name] or 0) + amount
		ply.PassiveAbility_ChemicalAccumulation[chemical_name] = amt

		return amt
	end

	function MODE.DegradeChemicalsOfPlayer(ply)
		if not ply.PassiveAbility_ChemicalAccumulation then return end

		local dt = FrameTime()

		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			local speed = chemical_degrade_speeds[chemical_name]

			if speed then
				amt = amt - speed * dt

				if amt <= 0 then
					ply.PassiveAbility_ChemicalAccumulation[chemical_name] = nil
				else
					ply.PassiveAbility_ChemicalAccumulation[chemical_name] = amt
				end
			end
		end
	end

	AddChemicalToPlayer = MODE.AddChemicalToPlayer
	DegradeChemicalsOfPlayer = MODE.DegradeChemicalsOfPlayer
end

if CLIENT then
	SetChemicalToPlayer = MODE.SetChemicalToPlayer
end

MODE.DisarmReach = 90
MODE.NoDisarmWeapons = {
	["weapon_hands_sh"] = true,
}

--\\
function MODE.GetPlayerTraceToOtherVictim(ply, victim, dist)
	if(IsValid(victim))then
		local ragdoll = victim.FakeRagdoll or victim:GetNWEntity("RagdollDeath", victim.FakeRagdoll)
		
		if(IsValid(ragdoll))then
			--
		else
			ragdoll = victim
		end
		
		local bone_id = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
		
		if(bone_id)then
			local bone_matrix = ragdoll:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local ply_offset_normal = pos - ply:GetShootPos()
				local ply_aim_normal = ply:GetAimVector()
					
				ply_offset_normal:Normalize()
				ply_aim_normal:Normalize()
				
				local ang_diff = -(math.deg(math.acos(ply_aim_normal:DotProduct(-ply_offset_normal))) - 180)
				
				if(ang_diff < 80)then
					local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, ply_offset_normal, dist)
					
					if(IsValid(aim_ent))then
						return aim_ent, other_ply, trace
					else
						return MODE.GetPlayerTraceToOther(ply, dist)
					end
				else
					return MODE.GetPlayerTraceToOther(ply, dist)
				end
			end
		end
	end
end
--//

--\\Neck Break
function MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
	if(aim_ent:IsRagdoll())then
		local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Head1")
		
		if(bone_id)then
			local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local other_normal = -ang:Right()
				local ply_normal = pos - ply:GetShootPos()
				local dist_z = math.abs(pos.z - ply:GetShootPos().z)
				
				if(dist_z < 50) then
					ply_normal:Normalize()
					
					local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
					
					if(ang_diff < 100)then
						return true
					end
				end
			end
		end
	elseif(aim_ent:IsPlayer())then
		local other_angle = aim_ent:EyeAngles()[2]
		local ply_angle = (aim_ent:GetPos() - ply:GetPos()):Angle()[2] --ply:EyeAngles()[2]
		local ang_diff = math.abs(math.AngleDifference(other_angle, ply_angle))
		
		if(ang_diff < 100)then
			return true
		end
	end
	
	return false
end

function MODE.BreakOtherNeck(ply, other_ply, aim_ent)
	if(other_ply:Alive())then
		other_ply:Kill()
		other_ply:ViewPunch(Angle(0, 0, -10))
		
		aim_ent.organism.spine3 = 1
		
		aim_ent:EmitSound("neck_snap_01.wav", 60, 100, 1, CHAN_AUTO)

		timer.Simple(0.1, function()
			local ent = other_ply:GetNWEntity("RagdollDeath")

			if IsValid(ent) then
				ent:RemoveInternalConstraint(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1")))

				local spine = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))
				local head = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1"))

				local pspine = ent:GetPhysicsObjectNum(spine)
				local phead = ent:GetPhysicsObjectNum(head)

				local lpos, lang = WorldToLocal(phead:GetPos() + phead:GetAngles():Forward() * -2 + phead:GetAngles():Up() * -1.5, angle_zero, pspine:GetPos(), pspine:GetAngles())
                
				phead:SetPos(pspine:GetPos() + pspine:GetAngles():Forward() * 12.9 + pspine:GetAngles():Right() * -1)

				local cons = constraint.AdvBallsocket(ent, ent, spine, head, lpos, nil, 0, 0, -55, -90, -50, 55, 35, 50, 0, 0, 0, 0, 0)
			end
		end)
	end
end

function MODE.StartBreakingOtherNeck(ply, other_ply)
	ply.Ability_NeckBreak = {
		Victim = other_ply,
		Progress = 0,
	}
	other_ply.BeingVictimOfNeckBreak = true
	
	if(SERVER)then
		other_ply:ViewPunch(Angle(0, -10, -10))
		
		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(true)
		net.Send(other_ply)
		
		net.Start("HMCD_BreakingOtherNeck")
			net.WriteBool(true)
			net.WriteEntity(ply)
			net.WriteEntity(other_ply)
		net.SendPVS(ply:GetShootPos())
	end
end

function MODE.StopBreakingOtherNeck(ply)
	if(ply.Ability_NeckBreak and IsValid(ply.Ability_NeckBreak.Victim))then
		ply.Ability_NeckBreak.Victim.BeingVictimOfNeckBreak = false
	end
	
	if(SERVER and ply.Ability_NeckBreak and IsValid(ply.Ability_NeckBreak.Victim))then
		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(false)
		net.Send(ply.Ability_NeckBreak.Victim)

		net.Start("HMCD_BreakingOtherNeck")
			net.WriteBool(false)
			net.WriteEntity(ply)
		net.SendPVS(ply:GetShootPos())
	end
	
	ply.Ability_NeckBreak = nil
end

function MODE.ContinueBreakingOtherNeck(ply)
	local break_data = ply.Ability_NeckBreak
	local victim = break_data.Victim
	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOtherVictim(ply, victim)
	
	if(IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll()))then
		if(IsValid(victim) and victim:Alive() and MODE.CanPlayerBreakOtherNeck(ply, aim_ent) and other_ply == victim)then
			break_data.Progress = break_data.Progress + FrameTime() * 300
			
			if(break_data.Progress >= 100)then
				if(SERVER)then
					MODE.BreakOtherNeck(ply, break_data.Victim, aim_ent)
				end
				
				
				MODE.StopBreakingOtherNeck(ply)
			end
		else
			MODE.StopBreakingOtherNeck(ply)
		end
	else
		MODE.StopBreakingOtherNeck(ply)
	end
end

hook.Add("HG_MovementCalc_2", "HMCD_SubRole_Abilities", function(mul, ply, cmd)
	if ply.BeingVictimOfNeckBreak or ply.BeingVictimOfDisarmament or ply.BeingVictimOfThroatSlit
		or ply.Ability_SurgeonArteryCut then
		mul[1] = mul[1] * 0.3
	end
end)
--//

function MODE.IsTraitorDiversant(ply)
	if not IsValid(ply) then return false end
	return ply.SubRole == "traitor_diversant" or ply.SubRole == "traitor_diversant_soe"
end

MODE.SharpMeleeClasses = {
	["weapon_sogknife"] = true,
	["weapon_buck200knife"] = true,
	["weapon_fiberwire"] = true,
	["weapon_hg_axe"] = true,
	["weapon_hg_machete"] = true,
	["weapon_hg_crowbar"] = true,
	["weapon_hatchet"] = true,
	["weapon_tomahawk"] = true,
	["weapon_pocketknife"] = true,
	["weapon_hg_glassshard"] = true,
	["weapon_hg_glassshard_taped"] = true,
}

function MODE.PlyHasSharpWeapon(ply)
	if not IsValid(ply) then return false end
	local wep = ply:GetActiveWeapon()
	return MODE.IsSharpWeapon(wep)
end

function MODE.IsSharpWeapon(wep)
	if not IsValid(wep) then return false end
	if MODE.SharpMeleeClasses[wep:GetClass()] then return true end
	if wep.Base == "weapon_melee" and (wep.HoldType == "knife" or wep.DamageType == DMG_SLASH) then return true end
	return false
end

function MODE.GetStealableBackWeapon(victim)
	if not IsValid(victim) or not victim:Alive() then return end
	local active = victim:GetActiveWeapon()
	for _, wep in ipairs(victim:GetWeapons()) do
		if wep == active or wep.NoDrop then continue end
		local class = wep:GetClass()
		if class == "weapon_hands_sh" then continue end
		local swep = weapons.Get(class)
		if swep and swep.holsteredBone and not swep.shouldntDrawHolstered then
			return wep
		end
	end
end

function MODE.CanPlayerStealFromBack(ply, other_ply, aim_ent)
	if not IsValid(other_ply) or not other_ply:Alive() then return false end
	if not MODE.GetStealableBackWeapon(other_ply) then return false end
	return MODE.CanPlayerBreakOtherNeck(ply, aim_ent or other_ply)
end

function MODE.StealBackWeapon(ply, other_ply)
	local wep = MODE.GetStealableBackWeapon(other_ply)
	if not IsValid(wep) then return end
	other_ply:DropWeapon(wep, nil, ply:GetPos() + ply:GetAimVector() * 8)
	wep.DontEquipInstantly = true
	ply:PickupWeapon(wep, false)
	ply.noSound = true
	timer.Simple(0, function()
		if IsValid(ply) then ply.noSound = false end
	end)
end

--\\Throat Slit
function MODE.SlitOtherThroat(ply, other_ply, aim_ent)
	if not other_ply:Alive() then return end
	local dmgInfo = DamageInfo()
	dmgInfo:SetDamageType(DMG_SLASH)
	dmgInfo:SetAttacker(ply)
	dmgInfo:SetInflictor(ply:GetActiveWeapon() or ply)
	local ent = hg.GetCurrentCharacter(other_ply)
	if not IsValid(ent) then return end
	local ang = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Neck1"))
	if not ang then return end
	ang = ang:GetAngles()
	local _, slashAng = LocalToWorld(vector_origin, Angle(0, -60, 0), vector_origin, ang)
	if other_ply.organism and hg.organism and hg.organism.input_list and hg.organism.input_list.arteria then
		hg.organism.input_list.arteria(other_ply.organism, 0, 8, dmgInfo, nil, -slashAng:Forward())
	end
	for i = 1, 4 do
		hg.organism.AddWoundManual(other_ply, 40, VectorRand(-2, 2), slashAng, "ValveBiped.Bip01_Neck1", CurTime() + math.Rand(0, 1.5))
	end
	aim_ent:EmitSound("Flesh.ImpactHard", 45, math.random(95, 105), 0.6, CHAN_AUTO)
	hook.Run("HomigradDamage", other_ply, dmgInfo, HITGROUP_HEAD, ent, 12)
end

function MODE.StartSlittingOtherThroat(ply, other_ply)
	ply.Ability_ThroatSlit = {
		Victim = other_ply,
		Progress = 0,
	}
	other_ply.BeingVictimOfThroatSlit = true

	if SERVER then
		other_ply:ViewPunch(Angle(0, -8, -8))
		net.Start("HMCD_BeingVictimOfThroatSlit")
			net.WriteBool(true)
		net.Send(other_ply)
		net.Start("HMCD_SlittingOtherThroat")
			net.WriteBool(true)
			net.WriteEntity(ply)
			net.WriteEntity(other_ply)
		net.SendPVS(ply:GetShootPos())
	end
end

function MODE.StopSlittingOtherThroat(ply)
	if ply.Ability_ThroatSlit and IsValid(ply.Ability_ThroatSlit.Victim) then
		ply.Ability_ThroatSlit.Victim.BeingVictimOfThroatSlit = false
	end
	if SERVER and ply.Ability_ThroatSlit and IsValid(ply.Ability_ThroatSlit.Victim) then
		net.Start("HMCD_BeingVictimOfThroatSlit")
			net.WriteBool(false)
		net.Send(ply.Ability_ThroatSlit.Victim)
		net.Start("HMCD_SlittingOtherThroat")
			net.WriteBool(false)
			net.WriteEntity(ply)
		net.SendPVS(ply:GetShootPos())
	end
	ply.Ability_ThroatSlit = nil
end

function MODE.ContinueSlittingOtherThroat(ply)
	local data = ply.Ability_ThroatSlit
	if not data then return end
	local victim = data.Victim
	local aim_ent, other_ply = MODE.GetPlayerTraceToOtherVictim(ply, victim)
	if IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll()) then
		if IsValid(victim) and victim:Alive() and MODE.CanPlayerBreakOtherNeck(ply, aim_ent) and other_ply == victim and MODE.PlyHasSharpWeapon(ply) then
			data.Progress = data.Progress + FrameTime() * 350
			if data.Progress >= 100 then
				if SERVER then
					MODE.SlitOtherThroat(ply, victim, aim_ent)
				end
				MODE.StopSlittingOtherThroat(ply)
			end
		else
			MODE.StopSlittingOtherThroat(ply)
		end
	else
		MODE.StopSlittingOtherThroat(ply)
	end
end
--//

--\\Disarm
function MODE.CanPlayerDisarmOtherPly(ply, other_ply)
	--[[if(other_ply and IsValid(other_ply:GetActiveWeapon()))then
		if(MODE.NoDisarmWeapons[other_ply:GetActiveWeapon():GetClass()])then
			return false
		end
	else
		return false
	end--]]
	
	return true
end

function MODE.CanPlayerDisarmOther(ply, aim_ent)
	if(aim_ent:IsRagdoll())then
		local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Spine2")
		
		if(bone_id)then
			local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local other_normal = ang:Right()
				local ply_normal = pos - ply:GetShootPos()
				local dist_z = math.abs(pos.z - ply:GetShootPos().z)
				
				if(dist_z < 50) then
					ply_normal:Normalize()
					
					local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
					
					if(ang_diff < 90)then
						return 2
					else
						return 1.5
					end
				end
			end
		end
	elseif(aim_ent:IsPlayer())then
		local other_angle = aim_ent:EyeAngles()[2]
		local ply_angle = (aim_ent:GetPos() - ply:GetPos()):Angle()[2] --ply:EyeAngles()[2]
		local ang_diff = math.abs(math.AngleDifference(other_angle, ply_angle))
		
		if(ang_diff < 70)then
			return 2
		else
			return 1.5
		end
	end
	
	return false
end

function MODE.DisarmOther(ply, other_ply, aim_ent)
	if(other_ply:Alive())then
		local weapon = other_ply:GetActiveWeapon()

		if(IsValid(weapon) and !weapon.NoDrop)then
			other_ply:DropWeapon(weapon)
			ply:PickupWeapon(weapon, false)
		end

		hg.LightStunPlayer(other_ply)
		timer.Simple(0,function()
			local rag = hg.GetCurrentCharacter(other_ply)
			if IsValid(rag) and rag ~= other_ply then
				local bon = rag:LookupBone("ValveBiped.Bip01_Head1")
				local physnum = rag:TranslateBoneToPhysBone(bon)
				local phys = rag:GetPhysicsObjectNum(physnum)
				local dist = 25--phys:GetPos():Distance(ply:EyePos())
				
				hg.SetCarryEnt2(ply, rag, bon, phys:GetMass(), Vector(-2,0,0), ply:GetAimVector() * dist + ply:EyeAngles():Up() * 5 + ply:EyeAngles():Right() * -5 + ply:GetShootPos(), ply:EyeAngles() + Angle(-90, 90, 0))
			end
		end)
	end
end

function MODE.StartDisarmingOther(ply, other_ply)
	ply.Ability_Disarm = {
		Victim = other_ply,
		Progress = 0,
	}
	other_ply.BeingVictimOfDisarmament = true
	
	if(SERVER)then
		-- other_ply:ViewPunch(Angle(0, -10, -10))
		
		net.Start("HMCD_BeingVictimOfDisarmament")
			net.WriteBool(true)
		net.Send(other_ply)
		
		net.Start("HMCD_DisarmingOther")
			net.WriteBool(true)
			net.WriteEntity(other_ply)
		net.Send(ply)
	end
end

function MODE.StopDisarmingOther(ply)
	if(ply.Ability_Disarm and IsValid(ply.Ability_Disarm.Victim))then
		ply.Ability_Disarm.Victim.BeingVictimOfDisarmament = false
	end
	
	if(SERVER and ply.Ability_Disarm and IsValid(ply.Ability_Disarm.Victim))then
		net.Start("HMCD_BeingVictimOfDisarmament")
			net.WriteBool(false)
		net.Send(ply.Ability_Disarm.Victim)

		net.Start("HMCD_DisarmingOther")
			net.WriteBool(false)
		net.Send(ply)
	end
	
	ply.Ability_Disarm = nil
end

function MODE.ContinueDisarmingOther(ply)
	local ability_data = ply.Ability_Disarm
	local victim = ability_data.Victim
	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOtherVictim(ply, victim, MODE.DisarmReach)
	
	if(IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll()))then
		local disarm_strength = MODE.CanPlayerDisarmOther(ply, aim_ent)
		
		if(IsValid(victim) and victim:Alive() and disarm_strength and other_ply == victim and MODE.CanPlayerDisarmOtherPly(ply, other_ply))then
			ability_data.Progress = ability_data.Progress + FrameTime() * 250 * disarm_strength
			
			if(ability_data.Progress >= 100)then
				if(SERVER)then
					MODE.DisarmOther(ply, victim, aim_ent)
				end
				
				
				MODE.StopDisarmingOther(ply)
			end
		else
			MODE.StopDisarmingOther(ply)
		end
	else
		MODE.StopDisarmingOther(ply)
	end
end

hook.Add("PlayerSwitchWeapon", "HMCD_SubRole_Abilities", function(ply)
	if(ply.BeingVictimOfDisarmament)then
		return true
	end
end)
--//

--\\Surgeon
function MODE.SurgeonWantsSharpCut(ply, wep)
	if not IsValid(ply) or not IsValid(wep) then return false end
	if wep:GetClass() == "weapon_scalpel" then return true end
	return MODE.IsSharpWeapon(wep)
end

MODE.SurgeonReach = 90
MODE.SurgeonCutCloseDist = 80
MODE.SurgeonArteryPickDist = 50
MODE.SurgeonOrganViewRadius = 500
MODE.SurgeonOrganViewDuration = 15
MODE.SurgeonOrganViewCooldown = 300
MODE.SurgeonArteryCutSpeed = 220

function MODE.SurgeonOrganViewCDLeft(ply)
	if not IsValid(ply) then return 0 end
	return math.max(0, (ply.SurgeonOrganViewCDUntil or 0) - CurTime())
end

function MODE.SurgeonOrganViewActive(ply)
	return IsValid(ply) and ply.SurgeonOrganViewUntil and ply.SurgeonOrganViewUntil > CurTime()
end

function MODE.FormatSurgeonTime(seconds)
	seconds = math.ceil(seconds)
	return math.floor(seconds / 60) .. ":" .. string.format("%02d", seconds % 60)
end

function MODE.SurgeonCanReachTarget(ply, aim_ent, other_ply, dist)
	if not IsValid(other_ply) or not other_ply:Alive() then return false end
	if not MODE.SurgeonCanSeeTarget(ply, other_ply) then return false end

	dist = dist or MODE.SurgeonReach
	local _, traced_ply = MODE.GetPlayerTraceToOther(ply, nil, dist)
	return IsValid(traced_ply) and traced_ply == other_ply
end

function MODE.SurgeonIsVulnerableOrgan(name)
	if not name then return false end
	return name == "arteria" or string.find(name, "artery", 1, true) ~= nil
end

function MODE.SurgeonGetEyeTrace(ply, dist)
	dist = dist or MODE.SurgeonReach
	return hg.eyeTrace and hg.eyeTrace(ply, dist)
end

function MODE.SurgeonTraceOnVictim(trace, other_ply, ent)
	if not trace or not IsValid(trace.Entity) then return false end
	ent = ent or hg.GetCurrentCharacter(other_ply)
	if not IsValid(ent) then return false end

	local hit_ent = trace.Entity
	if hit_ent == ent or hit_ent == other_ply then return true end
	if hit_ent:IsRagdoll() and IsValid(hit_ent.ply) and hit_ent.ply == other_ply then return true end

	return false
end

function MODE.SurgeonCloseToTarget(ply, other_ply)
	if not IsValid(other_ply) or not other_ply:Alive() then return false end
	if not MODE.SurgeonCanSeeTarget(ply, other_ply) then return false end

	local ent = hg.GetCurrentCharacter(other_ply) or other_ply
	if not IsValid(ent) then return false end

	local close = MODE.SurgeonCutCloseDist
	return ply:GetPos():DistToSqr(ent:GetPos()) <= close * close
end

function MODE.SurgeonGetOrganBoxes(other_ply)
	local ent = hg.GetCurrentCharacter(other_ply)
	if not IsValid(ent) or not hg.organism or not hg.organism.GetHitBoxOrgans then return end

	local organs = hg.organism.GetHitBoxOrgans(ent:GetModel(), ent)
	if not organs then return end

	local boxs = hg.organism.ShootMatrix(ent, organs, other_ply)
	if not boxs then return end

	return ent, organs, boxs
end

function MODE.SurgeonNearestArteryToPoint(organs, boxs, hit_pos, max_dist)
	if not hit_pos or not organs or not boxs then return end

	max_dist = max_dist or MODE.SurgeonArteryPickDist
	local max_d_sqr = max_dist * max_dist
	local best_name, best_bone, best_d

	for i = 1, #boxs do
		local box = boxs[i]
		if not box[6] then continue end

		local organ = organs[box[6]] and organs[box[6]][box[7]]
		if not organ or not MODE.SurgeonIsVulnerableOrgan(organ[1]) then continue end

		local d = box[1]:DistToSqr(hit_pos)
		if d <= max_d_sqr and (not best_d or d < best_d) then
			best_d = d
			best_name = organ[1]
			best_bone = box[6]
		end
	end

	return best_name, best_bone
end

function MODE.SurgeonCanSeeTarget(ply, other_ply)
	if not IsValid(ply) or not IsValid(other_ply) or not other_ply:Alive() then return false end
	if CLIENT and (other_ply.NotSeen or other_ply.shouldTransmit == false) then return false end

	local ent = hg.GetCurrentCharacter(other_ply)
	if not IsValid(ent) then return false end

	local filter = {ply, ent, other_ply}
	local rag = hg.RagdollOwner and hg.RagdollOwner(ent)
	if IsValid(rag) then filter[#filter + 1] = rag end

	return hg.isVisible(ply:GetShootPos(), ent:WorldSpaceCenter(), filter, MASK_VISIBLE)
end

function MODE.SurgeonCanTouchTarget(ply, aim_ent, other_ply)
	if not IsValid(other_ply) or not other_ply:Alive() then return false end
	if not MODE.SurgeonCanSeeTarget(ply, other_ply) then return false end
	return MODE.CanPlayerDisarmOther(ply, aim_ent) or MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
end

function MODE.SurgeonTraceArtery(ply, other_ply)
	if not IsValid(other_ply) or not other_ply:Alive() then return end

	local ent, organs, boxs = MODE.SurgeonGetOrganBoxes(other_ply)
	if not ent then return end

	local trace = MODE.SurgeonGetEyeTrace(ply, MODE.SurgeonReach)

	if trace and trace.HitPos and MODE.SurgeonTraceOnVictim(trace, other_ply, ent) then
		local name, bone = MODE.SurgeonNearestArteryToPoint(organs, boxs, trace.HitPos, MODE.SurgeonArteryPickDist)
		if name then return name, bone, ent, trace.HitPos end
	end
end

function MODE.SurgeonCanShowCutHint(ply, other_ply, aim_ent)
	if not IsValid(other_ply) or other_ply == ply or not other_ply:Alive() then return false end
	if not MODE.SurgeonWantsSharpCut(ply, ply:GetActiveWeapon()) then return false end
	if not MODE.SurgeonCloseToTarget(ply, other_ply) then return false end

	local cut = ply.Ability_SurgeonArteryCut
	if cut and cut.Victim == other_ply then return true end

	local trace = MODE.SurgeonGetEyeTrace(ply, MODE.SurgeonReach)
	return trace and MODE.SurgeonTraceOnVictim(trace, other_ply) or MODE.SurgeonCanReachTarget(ply, aim_ent, other_ply)
end

local surgeon_artery_sizes = {
	arteria = 14,
	rarmartery = 6,
	larmartery = 6,
	rlegartery = 9,
	llegartery = 9,
	spineartery = 10,
}

local surgeon_artery_bones = {
	arteria = "ValveBiped.Bip01_Neck1",
	larmartery = "ValveBiped.Bip01_L_UpperArm",
	rarmartery = "ValveBiped.Bip01_R_UpperArm",
	llegartery = "ValveBiped.Bip01_L_Thigh",
	rlegartery = "ValveBiped.Bip01_R_Thigh",
	spineartery = "ValveBiped.Bip01_Spine2",
}

function MODE.SurgeonApplyArterialBleed(org, owner, artery, bone_name, hit_pos, dir, dmgInfo)
	if not org or not IsValid(owner) or org[artery] == 1 then return false end
	if org[string.Replace(artery, "artery", "") .. "amputated"] then return false end

	local char = hg.GetCurrentCharacter(owner) or owner
	if not IsValid(char) then return false end

	local bone = char:LookupBone(bone_name)
	if not bone then
		bone_name = surgeon_artery_bones[artery] or bone_name
		bone = char:LookupBone(bone_name)
	end
	if not bone then return false end

	local bonePos, boneAng = char:GetBonePosition(bone)
	if not bonePos then return false end

	local localPos = WorldToLocal(hit_pos, angle_zero, bonePos, boneAng)
	local _, dirAng = WorldToLocal(vector_origin, dir:Angle(), vector_origin, boneAng)
	local bleed_dir = dirAng:Forward()

	org.arterialwounds = org.arterialwounds or {}
	org[artery] = 1
	org.painadd = (org.painadd or 0) + 8

	table.insert(org.arterialwounds, {
		surgeon_artery_sizes[artery] or 6,
		localPos,
		angle_zero,
		bone_name,
		CurTime(),
		bleed_dir * 100,
		artery,
	})

	if artery == "arteria" then
		org.neckslit = true
		org.needfake = true
		if org.isPly and not org.otrub and owner.Notify then
			owner:Notify("Я чувствую, как кровь хлещет из шеи...", true, "arteria", 0)
		end
		if hg.AddHarmToAttacker and dmgInfo then
			hg.AddHarmToAttacker(dmgInfo, 15, "Carotid artery punctured harm")
		end
		if IsValid(char) and not org.otrub and not org.needotrub then
			char:EmitSound("neckslit.ogg", 70, 100, 1, CHAN_AUTO)
		end
		timer.Simple(0, function()
			if not IsValid(owner) then return end
			if owner:IsPlayer() and owner:Alive() and hg.Fake then
				hg.Fake(owner, nil, true, true)
			end
			local rag = hg.GetCurrentCharacter(owner)
			if IsValid(rag) and not org.otrub and not org.needotrub then
				local snd = (ThatPlyIsFemale and ThatPlyIsFemale(owner)) and "femaleneck.mp3" or "maleneck.mp3"
				rag:EmitSound(snd, 70, 100, 1, CHAN_VOICE)
				org.neckslitSoundName = snd
				org.neckslitSoundEnt = rag
			end
		end)
	elseif hg.AddHarmToAttacker and dmgInfo then
		hg.AddHarmToAttacker(dmgInfo, 4, "Artery cut harm")
	end

	return true
end

function MODE.SurgeonCutArtery(ply, other_ply, cut_name, cut_bone, cut_hit_pos)
	if CLIENT then return end
	if not IsValid(other_ply) or not other_ply:Alive() or not other_ply.organism then return end

	local wep = ply:GetActiveWeapon()
	if not MODE.SurgeonWantsSharpCut(ply, wep) then return end

	local ent = hg.GetCurrentCharacter(other_ply)
	if not IsValid(ent) then return end

	local org = other_ply.organism
	cut_name = cut_name or "arteria"
	cut_bone = cut_bone or "ValveBiped.Bip01_Neck1"
	cut_hit_pos = cut_hit_pos or ent:WorldSpaceCenter()

	local dir = cut_hit_pos - ply:GetShootPos()
	if dir:LengthSqr() < 1 then
		dir = ply:GetAimVector()
	else
		dir:Normalize()
	end

	local dmgInfo = DamageInfo()
	dmgInfo:SetDamageType(DMG_SLASH)
	dmgInfo:SetDamage(8)
	dmgInfo:SetAttacker(ply)
	dmgInfo:SetInflictor(IsValid(wep) and wep or ply)

	if not MODE.SurgeonApplyArterialBleed(org, other_ply, cut_name, cut_bone, cut_hit_pos, dir, dmgInfo) then
		return
	end

	if hg.organism.SyncWoundNetVars then
		hg.organism.SyncWoundNetVars(other_ply, org)
	end

	ent:EmitSound("Flesh.ImpactHard", 45, math.random(95, 105), 0.6, CHAN_AUTO)
	hook.Run("HomigradDamage", other_ply, dmgInfo, HITGROUP_GENERIC, ent, 8)
end

function MODE.StartSurgeonArteryCut(ply, other_ply)
	if not MODE.SurgeonCloseToTarget(ply, other_ply) then return false end

	local cut_name, cut_bone, _, cut_hit_pos = MODE.SurgeonTraceArtery(ply, other_ply)
	if not cut_name then return false end

	ply.Ability_SurgeonArteryCut = {
		Victim = other_ply,
		Progress = 0,
		StartTime = CurTime(),
		CutName = cut_name,
		CutBone = cut_bone,
		CutHitPos = cut_hit_pos,
	}

	if SERVER then
		net.Start("HMCD_SurgeonArteryCutting")
			net.WriteBool(true)
			net.WriteEntity(other_ply)
		net.Send(ply)
	end

	return true
end

function MODE.StopSurgeonArteryCut(ply)
	if SERVER then
		net.Start("HMCD_SurgeonArteryCutting")
			net.WriteBool(false)
		net.Send(ply)
	end
	ply.Ability_SurgeonArteryCut = nil
end

function MODE.ContinueSurgeonArteryCut(ply)
	local data = ply.Ability_SurgeonArteryCut
	if not data then return end

	local victim = data.Victim
	if not IsValid(victim) or not victim:Alive() then
		MODE.StopSurgeonArteryCut(ply)
		return
	end

	local wep = ply:GetActiveWeapon()
	if not data.CutName then
		local cut_name, cut_bone, _, cut_hit_pos = MODE.SurgeonTraceArtery(ply, victim)
		if cut_name then
			data.CutName = cut_name
			data.CutBone = cut_bone
			data.CutHitPos = cut_hit_pos
		end
	end

	if MODE.SurgeonCloseToTarget(ply, victim) and MODE.SurgeonWantsSharpCut(ply, wep) and data.CutName then
		data.Progress = data.Progress + FrameTime() * MODE.SurgeonArteryCutSpeed
		if data.Progress >= 100 then
			if SERVER then
				MODE.SurgeonCutArtery(ply, victim, data.CutName, data.CutBone, data.CutHitPos)
			end
			MODE.StopSurgeonArteryCut(ply)
		end
	else
		MODE.StopSurgeonArteryCut(ply)
	end
end
--//