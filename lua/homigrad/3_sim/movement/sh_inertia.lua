local math = math
local math_deg = math.deg
local math_atan2 = math.atan2
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local math_Approach = math.Approach
local math_AngleDifference = math.AngleDifference
local math_min = math.min
local math_max = math.max
local math_Clamp = math.Clamp
local math_abs = math.abs
local math_Round = math.Round
local math_sqrt = math.sqrt
local math_random = math.random
local SysTime = SysTime
local CurTime = CurTime
local IsValid = IsValid
local hook_Add = hook.Add
local hook_Run = hook.Run
local util_TraceLine = util.TraceLine
local util_GetSurfaceData = util.GetSurfaceData
local engine_ActiveGamemode = engine.ActiveGamemode
local Vector = Vector
local Angle = Angle
local baseclass = baseclass
local vector_up = vector_up or Vector(0, 0, 1)
local angle_zero = angle_zero or Angle(0, 0, 0)
local timer_Simple = timer.Simple
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local MOVETYPE_WALK = MOVETYPE_WALK
local MOVETYPE_LADDER = MOVETYPE_LADDER
local MOVETYPE_NONE = MOVETYPE_NONE
local IN_JUMP = IN_JUMP
local IN_DUCK = IN_DUCK
local IN_SPEED = IN_SPEED
local IN_FORWARD = IN_FORWARD
local IN_BACK = IN_BACK
local IN_WALK = IN_WALK
local IN_ATTACK2 = IN_ATTACK2
local DEFAULT_JUMP_POWER = 200
local SERVER = SERVER
local CLIENT = CLIENT
local LocalPlayer = LocalPlayer

local function calc_forward_side_moves_to_vector2d(fm, sm, ply_angles)
	local ply_angle = ply_angles.y
	local rad1 = math_rad(ply_angle)
	local rad2 = math_rad(ply_angle + 90)
	local vec = Vector(fm * math_cos(rad1) - sm * math_cos(rad2), fm * math_sin(rad1) - sm * math_sin(rad2), 0)
	vec:Normalize()
	return vec
end

local hg_movement_stamina_debuff = 0.45
local hg_inertiamul = 0.4
local hg_inertiaenabled = true
local hg_divejump = false
local hg_movement_speed_gain_mul = 1
local hg_movement_speed_lose_mul = 1

local vomitVPAng = Angle(1, 0, 0)
local vecZero = Vector(0, 0, 0)

hook_Add("SetupMove", "HG(StartCommand)", function(ply, mv, cmd)
	local ct = SysTime()
	local delta_time = ct - (ply.LastStartCommand or ct)
	ply.LastStartCommand = ct

	if not IsValid(ply) or not ply:Alive() then return end

	local org = ply.organism
	if not org or not org.brain then return end

	local isFakeRagdoll = IsValid(ply.FakeRagdoll)
	if not hg.RagdollCombatInUse(ply) and (isFakeRagdoll or IsValid(ply:GetNWEntity("FakeRagdollOld"))) then
		if isFakeRagdoll then
			cmd:SetForwardMove(0)
			cmd:SetSideMove(0)
			mv:SetForwardSpeed(0)
			mv:SetSideSpeed(0)
		end
		
		mv:SetForwardSpeed(math_min(mv:GetForwardSpeed(), 50))
		mv:SetSideSpeed(math_min(mv:GetSideSpeed(), 50))
		
		cmd:RemoveKey(IN_JUMP)
		mv:RemoveKey(IN_JUMP)
		cmd:AddKey(IN_DUCK)
		mv:AddKey(IN_DUCK)
		
		if ply.MovementInertia then
			ply.MovementInertia:Zero()
		end
	end

	if not hg_inertiaenabled then return end

	local moveType = ply:GetMoveType()
	if moveType == MOVETYPE_NOCLIP then
		hook_Run("HG_MovementCalc", vecZero, 0, 1, ply, cmd, mv)
		hook_Run("HG_MovementCalc_2", {1}, ply, cmd, mv)
		return
	end

	if ply:InVehicle() then return end

	local isCrouching = ply:Crouching()
	local runnin = ply:KeyDown(IN_SPEED) and not isCrouching and ply:KeyDown(IN_FORWARD)

	if not isFakeRagdoll and ply:KeyDown(IN_SPEED) and not isCrouching and ply:KeyDown(IN_BACK) then
		cmd:RemoveKey(IN_SPEED)
	end

	local wep = ply:GetActiveWeapon()
	local vel = ply:GetVelocity()
	local velLen = vel:Length()
	
	local brain_mul = 1
	if org.brain > 0.1 then
		brain_mul = math_sin(CurTime() * 0.5)
	end
	
	local fm = cmd:GetForwardMove() * brain_mul
	local sm = cmd:GetSideMove() * brain_mul

	local slow_walking = ply:KeyDown(IN_WALK)
	local aiming = ply:KeyDown(IN_ATTACK2) and IsValid(wep) and ishgweapon and ishgweapon(wep)
	local walk_speed = ply:GetWalkSpeed()
	local slow_walk_speed = ply:GetSlowWalkSpeed()
	local crouch_walk_speed = ply:GetCrouchedWalkSpeed()
	
	local weightmul = hg.CalculateWeight(ply, 140)
	ply.weightmul = weightmul
	weightmul = math_max(weightmul > 0.9 and 1 or weightmul * 1.11111111111, 0.1)

	if ply:GetNWBool("TauntHolsterWeapons", false) then
		local hands = ply:GetWeapon("weapon_hands_sh")
		if IsValid(hands) then
			cmd:SelectWeapon(hands)
			if SERVER then ply:SelectWeapon(hands) end
		end
	end

	if org.brain > 0.05 then
		local brainadjust = math_Clamp((org.brain - 0.05) * math_sin(CurTime() + 10) * 20, -2, 2)
		if brainadjust > 1 and cmd:KeyDown(IN_JUMP) then
			cmd:RemoveKey(IN_JUMP)
			cmd:AddKey(IN_DUCK)
			mv:RemoveKey(IN_JUMP)
			mv:AddKey(IN_DUCK)
		elseif brainadjust < -1 and cmd:KeyDown(IN_DUCK) then
			cmd:RemoveKey(IN_DUCK)
			cmd:AddKey(IN_JUMP)
			mv:RemoveKey(IN_DUCK)
			mv:AddKey(IN_JUMP)
		end
	end

	if ply:GetNetVar("vomiting", 0) > CurTime() then
		cmd:AddKey(IN_DUCK)
		mv:AddKey(IN_DUCK)
		if CLIENT and ply == LocalPlayer() then ViewPunch(vomitVPAng) end
	end

	local curSpeed = ply.CurrentSpeed or walk_speed
	local curFricMul = ply.CurrentFrictionMul or 1
	ply.FrictionGainMul = 0.01
	ply.FrictionLoseMul = 0.2

	local sf_mul = org.superfighter and 5 or 1
	local class_mul = ply:GetNWInt("SpeedGainClassMul", 1)
	ply.SpeedGainMul = (runnin and 175 or 65) * weightmul * sf_mul * class_mul * hg_movement_speed_gain_mul
	ply.SpeedLoseMul = 10000 * hg_movement_speed_lose_mul
	ply.SpeedSharpLoseMul = runnin and 0.008 or 0.015
	
	local blend_base = runnin and 1200 or 780
	ply.InertiaBlend = blend_base * weightmul * (org.superfighter and 100 or 1)
	ply.DuckingSlowdown = ply.DuckingSlowdown or 0

	hook_Run("HG_MovementCalc", vel, velLen, weightmul, ply, cmd, mv)

	local run_speed = ply:GetRunSpeed()
	local move_val = ply.move or curSpeed
	local mul_tbl = { move_val / run_speed }
	
	hook_Run("HG_MovementCalc_2", mul_tbl, ply, cmd, mv)

	local mul = math_max(mul_tbl[1], 0.01)
	if ply:GetNWBool("TauntStopMoving", false) then mul = mul * 0.01 end

	if runnin and velLen >= 10 then
		curSpeed = math_Approach(curSpeed, (ply.move or run_speed) * mul, delta_time * ply.SpeedGainMul)
	else
		local target_speed = walk_speed
		if isCrouching then target_speed = crouch_walk_speed
		elseif slow_walking or aiming then target_speed = slow_walk_speed end
		curSpeed = math_Approach(curSpeed, target_speed * mul, delta_time * ply.SpeedLoseMul)
	end

	local lastVel = ply.LastVelocity or vel
	local vel1 = math_max(velLen, 1)
	local vel2 = math_max(ply.LastVelocityLen or velLen, 1)

	local ang1 = math_deg(math_atan2(lastVel.y, lastVel.x))
	local ang2 = math_deg(math_atan2(vel.y, vel.x))
	local change = math_abs(math_AngleDifference(ang1, ang2))

	if lastVel == vel and ply.LastChangeVelocity then
		change = ply.LastChangeVelocity
	end

	local change_mul = math_abs(curSpeed - slow_walk_speed)
	ply.LastChangeVelocity = change
	
	curSpeed = math_Approach(curSpeed, slow_walk_speed * mul, delta_time * change * change_mul * ply.SpeedSharpLoseMul * 50)
	
	ply.CurrentSpeed = curSpeed
	ply.LastVelocity = vel
	ply.LastVelocityLen = velLen

	local ply_angles = cmd:GetViewAngles()
	local moveInertia = ply.MovementInertia or vel

	local fm_abs = math_abs(fm ~= 0 and fm or 1)
	local sm_abs = math_abs(sm ~= 0 and sm or 1)
	fm = fm / fm_abs
	sm = sm / sm_abs
	
	local movement_penalty = 1
	if fm < 0 then
		movement_penalty = runnin and 1.12 or 1.28
	end
	curSpeed = curSpeed / movement_penalty

	local inertia_to_norm = calc_forward_side_moves_to_vector2d(fm, sm, ply_angles)
	local inertia_to = inertia_to_norm * curSpeed

	local water_level = ply:WaterLevel()
	if not ply:OnGround() and water_level < 1 and (fm ~= 0 or sm ~= 0) then
		local start_pos = ply:GetPos()
		local tr_data = {
			start = start_pos,
			endpos = start_pos + inertia_to_norm * 50,
			filter = ply
		}
		if util_TraceLine(tr_data).Hit then
			movement_penalty = 1
		else
			movement_penalty = 5
		end
		curSpeed = curSpeed / movement_penalty
		inertia_to = inertia_to_norm * curSpeed
	end

	local consciousness = org.consciousness or 1
	consciousness = consciousness * math_Clamp((org.blood or 5000) / 4000, 0.5, 1)
	local consmul = math_Clamp((consciousness - 1) * 4 + 1, 0.1, 1)

	curFricMul = (runnin and 0.55 or 0.32) / hg_inertiamul
	ply.CurrentFrictionMul = curFricMul
	ply.InertiaBlend = ply.InertiaBlend * curFricMul

	if not ply:OnGround() then
		moveInertia = lastVel
	end

	local ib_dt = delta_time * ply.InertiaBlend
	local new_inertia = Vector(
		math_Approach(moveInertia.x, inertia_to.x, ib_dt),
		math_Approach(moveInertia.y, inertia_to.y, ib_dt),
		math_Approach(moveInertia.z, inertia_to.z, ib_dt)
	)
	ply.MovementInertia = new_inertia

	local inertia_len = math_sqrt(new_inertia.x * new_inertia.x + new_inertia.y * new_inertia.y)

	local angdiff = math_deg(math_atan2(new_inertia.y, new_inertia.x)) - ply_angles.y
	angdiff = (angdiff + 180) % 360 - 180
	local rad_angdiff = math_rad(angdiff)
	
	local forward_move = math_cos(rad_angdiff)
	local side_move = -math_sin(rad_angdiff)

	if CLIENT then
		local p_add = ply.MovementInertiaAddView or Angle(0, 0, 0)
		p_add.r = p_add.r + side_move * delta_time * inertia_len * 0.03
		p_add.p = p_add.p + math_abs(side_move) * delta_time * inertia_len * 0.01
		ply.MovementInertiaAddView = p_add
	end

	local move = ply:GetRunSpeed()
	local k = weightmul * math_Clamp(consmul, 0.7, 1)
	
	local temp = org.temperature
	if temp then
		k = k * math_Clamp(1 - (temp - 38) * 0.25, 0.5, 1)
		k = k * math_Clamp((temp - 35) * 0.25 + 1, 0.5, 1)
	end
	
	local stamina = org.stamina
	if stamina then
		k = k * math_Clamp((stamina[1] or 240) / (stamina.max or 240), hg_movement_stamina_debuff, 1)
	end
	
	k = k * math_Clamp(5 / ((org.immobilization or 0) + 1), 0.25, 1)
	k = k * math_Clamp((org.blood or 0) / 5000, 0, 1)
	k = k * math_Clamp(10 / ((org.shock or 0) + 1), 0.25, 1)
	k = k * (math_min(math_Round(org.adrenaline or 0, 1) / 24, 0.3) + 1)
	
	local lleg_val = org.lleg or 1
	local rleg_val = org.rleg or 1
	local l_mult = (lleg_val >= 0.5 and math_max(1 - lleg_val, 0.6) or 1)
	local r_mult = (rleg_val >= 0.5 and math_max(1 - rleg_val, 0.6) or 1)
	
	k = k * math_Clamp(l_mult * r_mult * ((org.analgesia or 0) + 1), 0, 1)
	
	if org.llegdislocation then k = k * 0.75 end
	if org.rlegdislocation then k = k * 0.75 end
	if org.pelvis == 1 then k = k * 0.4 end
	
	local carry1 = ply:GetNetVar("carryent")
	local carry2 = ply:GetNetVar("carryent2")
	if IsValid(carry1) or IsValid(carry2) then
		local cmass = ply:GetNetVar("carrymass", 0) + ply:GetNetVar("carrymass2", 0)
		k = k * math_Clamp(50 / math_max(cmass, 1), 0.5, 1)
	end
	
	k = k * math_Clamp(20 / ((org.pain or 0) + 1), 0.01, 1)

	local slwdwn = ply:GetNetVar("slowDown", 0)
	if slwdwn > 0 then
		k = k * math_Clamp((250 - slwdwn) / 250, 0.75, 1)
	end

	k = math_max(k, 0.1)

	if ply:GetNetVar("vomiting", 0) > (CurTime() - 3) then
		k = k * 0.25
	end

	local carry_ent = IsValid(carry1) and carry1 or (IsValid(carry2) and carry2)
	local rag = hg.GetCurrentCharacter(ply)

	if SERVER and inertia_len > 5 and runnin and ply == rag then
		local pmul = math_Clamp(inertia_len * 0.005, 0.5, 1) * 5 * (isCrouching and 0.01 or 1)
		local ft = delta_time
		if org.pelvis == 1 then org.painadd = org.painadd + ft * pmul end
		if org.lleg == 1 or org.llegdislocation then org.painadd = org.painadd + ft * pmul end
		if org.rleg == 1 or org.rlegdislocation then org.painadd = org.painadd + ft * pmul end
	end

	if carry_ent then
		local bon1 = ply:GetNetVar("carrybone", 0)
		local bon = bon1 ~= 0 and bon1 or ply:GetNetVar("carrybone2", 0)
		local bone = carry_ent:TranslatePhysBoneToBone(bon)
		local mat = carry_ent:GetBoneMatrix(bone)
		local pos = mat and mat:GetTranslation() or carry_ent:GetPos()
		local lpos = ply:GetNetVar("carrypos") or ply:GetNetVar("carrypos2")

		if lpos then
			if not carry_ent:IsRagdoll() then
				pos = carry_ent:LocalToWorld(lpos)
			else
				pos = LocalToWorld(lpos, angle_zero, mat:GetTranslation(), mat:GetAngles())
			end
		end

		local eyetr = hg.eyeTrace(ply)
		local distSqr = pos:DistToSqr(eyetr.StartPos)
		local wep_hands = weapons and weapons.GetStored("weapon_hands_sh")
		local reachdist = (wep_hands and wep_hands.ReachDistance or 100) + 30
		
		if distSqr > reachdist * reachdist then
			local moving_to = calc_forward_side_moves_to_vector2d(fm, sm, ply_angles)
			local dir = pos - eyetr.StartPos
			dir:Normalize()
			k = k * moving_to:Dot(dir)
		end
	end

	move = move * k
	ply.move = move

	if SERVER and not isFakeRagdoll then
		local currentEyeAng = ply:EyeAngles()
		ply.eyeAnglesOld = ply.eyeAnglesOld or currentEyeAng
		local cosine = currentEyeAng:Forward():Dot(ply.eyeAnglesOld:Forward())
		ply.eyeAnglesOld = currentEyeAng

		if velLen > 200 and (math_random(150) == 1 or cosine <= 0.99) then
			local ply_pos = ply:GetPos()
			local tr = {
				start = ply_pos,
				endpos = ply_pos - vector_up,
				filter = ply
			}
			local trace_res = util_TraceLine(tr)
			
			local surfProps = trace_res.SurfaceProps
			if surfProps then
				local surfData = util_GetSurfaceData(surfProps)
				if surfData and surfData.friction < 0.2 then
					local b1 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_L_Calf"))
					local phys1 = hg.IdealMassPlayer["ValveBiped.Bip01_L_Calf"]
					local b2 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_R_Calf"))
					local phys2 = hg.IdealMassPlayer["ValveBiped.Bip01_R_Calf"]
					local torso = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
					local phystorso = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]
					
					local force = vel:GetNormalized() * 150
					hg.AddForceRag(ply, torso, -force * 5 * phystorso, 0.5)
					
					local force_leg = (force * 5 - vector_up * 2)
					hg.AddForceRag(ply, b1, force_leg * phys1, 0.5)
					hg.AddForceRag(ply, b2, force_leg * phys2, 0.5)
					
					timer_Simple(0, function()
						if IsValid(ply) then hg.StunPlayer(ply) end
					end)
				end
			end
		end
	end

	if hg_divejump then
		local time = CurTime()
		ply.lastInDuck = ply:KeyPressed(IN_DUCK) and time or (ply.lastInDuck or 0)
		ply.lastInJump = ply:KeyPressed(IN_JUMP) and time or (ply.lastInJump or 0)
		if SERVER and rag == ply and (ply.lastInJump + 0.1 > time) and (ply.lastInDuck + 0.1 > time) then
			local force = ply:GetAimVector() * 400
			force.z = 0
			local torso = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
			local phystorso = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]
			hg.AddForceRag(ply, torso, force * phystorso, 0.5)
			hg.Fake(ply)
		end
	end

	if moveType == MOVETYPE_LADDER or moveType == MOVETYPE_NONE then
		inertia_len = 100
	end

	if org.noradrenaline and org.noradrenaline > 0 and inertia_len > 0 then
		inertia_len = inertia_len + 50 * math_Round(org.noradrenaline, 1)
	end
	
	mv:SetMaxSpeed(inertia_len)
	mv:SetMaxClientSpeed(inertia_len)
	ply:SetMaxSpeed(math_max(100, inertia_len))
	
	local jump_k = math_min(k, 1.1)
	if ply:GetNWBool("TauntStopMoving", false) then jump_k = 0 end
	ply:SetJumpPower(DEFAULT_JUMP_POWER * jump_k * (org.superfighter and 1.5 or 1) * (ply.JumpPowerMul or 1))

	if CLIENT then
		local vp2 = GetViewPunchAngles2 and GetViewPunchAngles2() or angle_zero
		local vp3 = GetViewPunchAngles3 and GetViewPunchAngles3() or angle_zero
		local fwangs = math_rad(vp2.y + vp3.y)
		
		local c_fw = math_cos(fwangs)
		local s_fw = math_sin(fwangs)
		
		local calc_fw = forward_move * c_fw + side_move * s_fw
		local calc_sd = side_move * c_fw + forward_move * s_fw

		cmd:SetForwardMove(calc_fw * inertia_len)
		cmd:SetSideMove(calc_sd * inertia_len)
	end

	if hg_inertiaenabled then
		mv:SetForwardSpeed(forward_move * inertia_len)
		mv:SetSideSpeed(side_move * inertia_len)
	end
end)

hook_Add("PlayerSpawn", "RemoveSandboxJumpBoost", function(ply)
	if engine_ActiveGamemode() ~= "sandbox" then return end
	if not baseclass then return end
	
	local PLAYER = baseclass.Get("player_sandbox")
	if PLAYER then
		PLAYER.FinishMove           = nil
		PLAYER.StartMove            = nil
		PLAYER.SlowWalkSpeed        = 100
		PLAYER.WalkSpeed            = 190
		PLAYER.RunSpeed             = 285
		PLAYER.CrouchedWalkSpeed    = 0.4
		PLAYER.DuckSpeed            = 0.3
		PLAYER.UnDuckSpeed          = 0.3
		PLAYER.JumpPower            = 200
	end
end)

hook_Add("StartCommand", "HG_AntiGmodPVP", function(ply, cmd)
	local ducking = cmd:KeyDown(IN_DUCK)
	ply.NowCrouched = ducking
	
	if ply.OldCrouched == nil then ply.OldCrouched = ducking end

	if not ply:OnGround() and ply:WaterLevel() < 2 and ply:GetMoveType() == MOVETYPE_WALK and ply.OldCrouched ~= ducking then
		cmd:AddKey(IN_DUCK)
	end

	ply.OldCrouched = ducking
end)