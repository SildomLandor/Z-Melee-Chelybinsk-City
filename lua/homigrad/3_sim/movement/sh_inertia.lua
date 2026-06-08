
local math                  = math
local math_deg              = math.deg
local math_atan2            = math.atan2
local math_rad              = math.rad
local math_cos              = math.cos
local math_sin              = math.sin
local math_abs              = math.abs
local math_min              = math.min
local math_max              = math.max
local math_sqrt             = math.sqrt
local math_random           = math.random
local math_Round            = math.Round
local math_Clamp            = math.Clamp
local math_Approach         = math.Approach
local math_AngleDifference  = math.AngleDifference

local SysTime               = SysTime
local CurTime               = CurTime
local IsValid               = IsValid
local hook_Add              = hook.Add
local hook_Run              = hook.Run
local util_TraceLine        = util.TraceLine
local util_GetSurfaceData   = util.GetSurfaceData
local engine_ActiveGamemode = engine.ActiveGamemode
local Vector                = Vector
local Angle                 = Angle
local baseclass             = baseclass
local timer_Simple          = timer.Simple

local MOVETYPE_NOCLIP   = MOVETYPE_NOCLIP
local MOVETYPE_WALK     = MOVETYPE_WALK
local MOVETYPE_LADDER   = MOVETYPE_LADDER
local MOVETYPE_NONE     = MOVETYPE_NONE
local IN_JUMP           = IN_JUMP
local IN_DUCK           = IN_DUCK
local IN_SPEED          = IN_SPEED
local IN_FORWARD        = IN_FORWARD
local IN_BACK           = IN_BACK
local IN_WALK           = IN_WALK
local IN_ATTACK2        = IN_ATTACK2
local SERVER            = SERVER
local CLIENT            = CLIENT
local LocalPlayer       = LocalPlayer

local DEFAULT_JUMP_POWER    = 200
local DEFAULT_WALK_SPEED    = 190
local DEFAULT_RUN_SPEED     = 285

local vector_up  = vector_up  or Vector(0, 0, 1)
local angle_zero = angle_zero or Angle(0, 0, 0)
local vecZero    = Vector(0, 0, 0)
local vomitVPAng = Angle(1, 0, 0)

local hg_movement_stamina_debuff  = 0.45
local hg_inertiamul               = 0.4
local hg_inertiaenabled           = true
local hg_divejump                 = false
local hg_movement_speed_gain_mul  = 1
local hg_movement_speed_lose_mul  = 1


local function InputToWorldDir(fm, sm, yaw_deg)
	if fm == 0 and sm == 0 then return vecZero end
	local rad_yaw        = math_rad(yaw_deg)
	local rad_yaw_right  = rad_yaw + 1.5707963267949  -- math_rad(90) — константа
	local x = fm * math_cos(rad_yaw) - sm * math_cos(rad_yaw_right)
	local y = fm * math_sin(rad_yaw) - sm * math_sin(rad_yaw_right)
	local len = math_sqrt(x * x + y * y)
	if len < 0.0001 then return vecZero end
	return Vector(x / len, y / len, 0)
end

local function NormaliseAxis(v)
	if v > 0 then return 1
	elseif v < 0 then return -1
	else return 0 end
end

local function Vec2DLen(v)
	return math_sqrt(v.x * v.x + v.y * v.y)
end


-- slowCache[ply] = { nextUpdate, weightmul, class_mul, ... }
local slowCache = {}

hook_Add("PlayerDisconnected", "HG_InertiaCleanupCache", function(ply)
	slowCache[ply] = nil
end)

hook_Add("SetupMove", "HG(StartCommand)", function(ply, mv, cmd)

	local ct         = SysTime()
	local delta_time = ct - (ply.LastStartCommand or ct)
	ply.LastStartCommand = ct

	if not IsValid(ply) or not ply:Alive() then return end

	local org = ply.organism
	if not org or not org.brain then return end

	local isFakeRagdoll = IsValid(ply.FakeRagdoll)

	if not hg.RagdollCombatInUse(ply) and
	   (isFakeRagdoll or IsValid(ply:GetNWEntity("FakeRagdollOld"))) then

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
		hook_Run("HG_MovementCalc",   vecZero, 0, 1, ply, cmd, mv)
		hook_Run("HG_MovementCalc_2", { 1 },      ply, cmd, mv)
		return
	end

	if ply:InVehicle() then return end

	local isCrouching = ply:Crouching()

	local key_speed   = ply:KeyDown(IN_SPEED)
	local key_forward = ply:KeyDown(IN_FORWARD)
	local key_back    = ply:KeyDown(IN_BACK)

	local runnin = key_speed and not isCrouching and key_forward
	if not isFakeRagdoll and key_speed and not isCrouching and key_back then
		cmd:RemoveKey(IN_SPEED)
	end

	local brain_level = org.brain or 0
	local brain_mul   = 1
	if brain_level > 0.1 then
		brain_mul = math_abs(math_sin(CurTime() * 0.5))
	end

	local fm = NormaliseAxis(cmd:GetForwardMove()) * brain_mul
	local sm = NormaliseAxis(cmd:GetSideMove())    * brain_mul

	local slow_walking = ply:KeyDown(IN_WALK)
	local key_attack2 = ply:KeyDown(IN_ATTACK2)
	local aiming = false
	if key_attack2 then
		local wep = ply:GetActiveWeapon()
		aiming = IsValid(wep) and ishgweapon and ishgweapon(wep)
	end

	local walk_speed        = ply:GetWalkSpeed()
	local slow_walk_speed   = ply:GetSlowWalkSpeed()
	local crouch_walk_speed = ply:GetCrouchedWalkSpeed()

	local sc = slowCache[ply]
	if not sc then
		sc = {}
		slowCache[ply] = sc
	end

	local weightmul, weightmul_raw, class_mul
	if not sc.nextUpdate or ct > sc.nextUpdate then
		sc.nextUpdate = ct + 0.1

		weightmul_raw    = hg.CalculateWeight(ply, 140)
		sc.weightmul_raw = weightmul_raw
		local wm = weightmul_raw > 0.9 and 1 or weightmul_raw * 1.111
		weightmul = wm < 0.1 and 0.1 or wm
		sc.weightmul = weightmul

		class_mul     = ply:GetNWInt("SpeedGainClassMul", 1)
		sc.class_mul  = class_mul

		local c1 = ply:GetNetVar("carryent")
		local c2 = ply:GetNetVar("carryent2")
		sc.carry1      = c1
		sc.carry2      = c2
		sc.carry1valid = IsValid(c1)
		sc.carry2valid = IsValid(c2)
	else
		weightmul_raw = sc.weightmul_raw
		weightmul     = sc.weightmul
		class_mul     = sc.class_mul
	end

	ply.weightmul = weightmul_raw


	local tauntHolster = ply:GetNWBool("TauntHolsterWeapons", false)
	if tauntHolster then
		local hands = ply:GetWeapon("weapon_hands_sh")
		if IsValid(hands) then
			cmd:SelectWeapon(hands)
			if SERVER then ply:SelectWeapon(hands) end
		end
	end

	if brain_level > 0.05 then
		local t = CurTime()
		local brainadjust = math_Clamp((brain_level - 0.05) * math_sin(t + 10) * 20, -2, 2)
		if brainadjust > 1 and cmd:KeyDown(IN_JUMP) then
			cmd:RemoveKey(IN_JUMP) ; mv:RemoveKey(IN_JUMP)
			cmd:AddKey(IN_DUCK)    ; mv:AddKey(IN_DUCK)
		elseif brainadjust < -1 and cmd:KeyDown(IN_DUCK) then
			cmd:RemoveKey(IN_DUCK) ; mv:RemoveKey(IN_DUCK)
			cmd:AddKey(IN_JUMP)    ; mv:AddKey(IN_JUMP)
		end
	end

	local vomitTime = ply:GetNetVar("vomiting", 0)
	local curTime   = CurTime()
	if vomitTime > curTime then
		cmd:AddKey(IN_DUCK) ; mv:AddKey(IN_DUCK)
		if CLIENT and ply == LocalPlayer() then
			ViewPunch(vomitVPAng)
		end
	end

	local curSpeed   = ply.CurrentSpeed or walk_speed
	local curFricMul = ply.CurrentFrictionMul or 1

	ply.FrictionGainMul = 0.01
	ply.FrictionLoseMul = 0.2

	local sf_mul = org.superfighter and 5 or 1

	ply.SpeedGainMul      = (runnin and 175 or 65) * weightmul * sf_mul * class_mul * hg_movement_speed_gain_mul
	ply.SpeedLoseMul      = 10000 * hg_movement_speed_lose_mul
	ply.SpeedSharpLoseMul = runnin and 0.008 or 0.015

	local blend_base = runnin and 1200 or 780
	ply.InertiaBlend    = blend_base * weightmul * (org.superfighter and 100 or 1)
	ply.DuckingSlowdown = ply.DuckingSlowdown or 0

	local vel    = ply:GetVelocity()
	local velLen = vel:Length()
	hook_Run("HG_MovementCalc", vel, velLen, weightmul, ply, cmd, mv)

	local run_speed = ply:GetRunSpeed()
	local move_val  = ply.move or curSpeed
	local mul_tbl   = { move_val / run_speed }
	hook_Run("HG_MovementCalc_2", mul_tbl, ply, cmd, mv)

	local mul = mul_tbl[1]
	if mul < 0.01 then mul = 0.01 end
	if ply:GetNWBool("TauntStopMoving", false) then mul = mul * 0.01 end

	if runnin and velLen >= 10 then
		curSpeed = math_Approach(curSpeed, (ply.move or run_speed) * mul, delta_time * ply.SpeedGainMul)
	else
		local target_speed
		if isCrouching then
			target_speed = crouch_walk_speed
		elseif slow_walking or aiming then
			target_speed = slow_walk_speed
		else
			target_speed = walk_speed
		end
		curSpeed = math_Approach(curSpeed, target_speed * mul, delta_time * ply.SpeedLoseMul)
	end

	local lastVel    = ply.LastVelocity or vel
	local lastVelLen = ply.LastVelocityLen or velLen


	local direction_change
	if lastVel == vel and ply.LastChangeVelocity then
		direction_change = ply.LastChangeVelocity
	else
		local ang1 = math_deg(math_atan2(lastVel.y, lastVel.x))
		local ang2 = math_deg(math_atan2(vel.y,     vel.x))
		direction_change = math_abs(math_AngleDifference(ang1, ang2))
	end
	ply.LastChangeVelocity = direction_change

	local change_mul = math_abs(curSpeed - slow_walk_speed)
	curSpeed = math_Approach(
		curSpeed,
		slow_walk_speed * mul,
		delta_time * direction_change * change_mul * ply.SpeedSharpLoseMul * 50
	)

	ply.CurrentSpeed    = curSpeed
	ply.LastVelocity    = vel
	ply.LastVelocityLen = velLen

	local ply_angles  = cmd:GetViewAngles()
	local ply_yaw     = ply_angles.y
	local moveInertia = ply.MovementInertia or vel

	local movement_penalty = 1
	if fm < 0 then
		movement_penalty = runnin and 1.12 or 1.28
	end
	local penalised_speed = curSpeed / movement_penalty

	local inertia_to_norm = InputToWorldDir(fm, sm, ply_yaw)
	local inertia_to      = inertia_to_norm * penalised_speed

	local onGround   = ply:OnGround()
	local waterLevel = ply:WaterLevel()

	if not onGround and waterLevel < 1 and (fm ~= 0 or sm ~= 0) then
		local start_pos = ply:GetPos()
		local tr_hit = util_TraceLine({
			start  = start_pos,
			endpos = start_pos + inertia_to_norm * 50,
			filter = ply,
		}).Hit

		local air_penalty = tr_hit and 1 or 5
		penalised_speed   = curSpeed / air_penalty
		inertia_to        = inertia_to_norm * penalised_speed
	end

	local consciousness = org.consciousness or 1
	consciousness       = consciousness * math_Clamp((org.blood or 5000) / 4000, 0.5, 1)
	local consmul       = math_Clamp((consciousness - 1) * 4 + 1, 0.1, 1)

	curFricMul             = (runnin and 0.55 or 0.32) / hg_inertiamul
	ply.CurrentFrictionMul = curFricMul
	ply.InertiaBlend       = ply.InertiaBlend * curFricMul

	if not onGround then
		moveInertia = lastVel
	end

	local ib_dt       = delta_time * ply.InertiaBlend
	local new_inertia = Vector(
		math_Approach(moveInertia.x, inertia_to.x, ib_dt),
		math_Approach(moveInertia.y, inertia_to.y, ib_dt),
		math_Approach(moveInertia.z, inertia_to.z, ib_dt)
	)
	ply.MovementInertia = new_inertia

	local inertia_len = Vec2DLen(new_inertia)

	local angdiff     = math_deg(math_atan2(new_inertia.y, new_inertia.x)) - ply_yaw
	angdiff           = (angdiff + 180) % 360 - 180
	local rad_angdiff = math_rad(angdiff)

	local forward_move = math_cos(rad_angdiff)
	local side_move    = -math_sin(rad_angdiff)

	if CLIENT then
		local p_add = ply.MovementInertiaAddView or Angle(0, 0, 0)
		p_add.r = p_add.r + side_move          * delta_time * inertia_len * 0.03
		p_add.p = p_add.p + math_abs(side_move) * delta_time * inertia_len * 0.01
		ply.MovementInertiaAddView = p_add
	end

	local k = weightmul * math_Clamp(consmul, 0.7, 1)

	local temp = org.temperature
	if temp then
		k = k * math_Clamp(1 - (temp - 38) * 0.25, 0.5, 1)
		k = k * math_Clamp((temp - 35) * 0.25 + 1,  0.5, 1)
	end

	local stamina = org.stamina
	if stamina then
		k = k * math_Clamp(
			(stamina[1] or 240) / (stamina.max or 240),
			hg_movement_stamina_debuff, 1
		)
	end

	k = k * math_Clamp(5  / ((org.immobilization or 0) + 1), 0.25, 1)
	k = k * math_Clamp((org.blood or 0) / 5000, 0, 1)
	k = k * math_Clamp(10 / ((org.shock or 0) + 1), 0.25, 1)
	k = k * (math_min(math_Round(org.adrenaline or 0, 1) / 24, 0.3) + 1)

	local lleg_val = org.lleg or 1
	local rleg_val = org.rleg or 1
	local l_mult   = lleg_val < 0.5 and 1 or math_max(1 - lleg_val, 0.6)
	local r_mult   = rleg_val < 0.5 and 1 or math_max(1 - rleg_val, 0.6)
	k = k * math_Clamp(l_mult * r_mult * ((org.analgesia or 0) + 1), 0, 1)

	if org.llegdislocation then k = k * 0.75 end
	if org.rlegdislocation then k = k * 0.75 end
	if org.pelvis == 1     then k = k * 0.4  end

	local carry1       = sc.carry1
	local carry2       = sc.carry2
	local carry1valid  = sc.carry1valid
	local carry2valid  = sc.carry2valid

	if carry1valid or carry2valid then

		local cmass = ply:GetNetVar("carrymass", 0) + ply:GetNetVar("carrymass2", 0)
		k = k * math_Clamp(50 / math_max(cmass, 1), 0.5, 1)
	end

	k = k * math_Clamp(20 / ((org.pain or 0) + 1), 0.01, 1)

	local slwdwn = ply:GetNetVar("slowDown", 0)
	if slwdwn > 0 then
		k = k * math_Clamp((250 - slwdwn) / 250, 0.75, 1)
	end

	if k < 0.1 then k = 0.1 end


	if vomitTime > (curTime - 3) then
		k = k * 0.25
	end

	local carry_ent = (carry1valid and carry1) or (carry2valid and carry2)
	local rag       = hg.GetCurrentCharacter(ply)

	if carry_ent then
		local bon1   = ply:GetNetVar("carrybone", 0)
		local bon    = bon1 ~= 0 and bon1 or ply:GetNetVar("carrybone2", 0)
		local bone   = carry_ent:TranslatePhysBoneToBone(bon)
		local mat    = carry_ent:GetBoneMatrix(bone)
		local pos    = mat and mat:GetTranslation() or carry_ent:GetPos()
		local lpos   = ply:GetNetVar("carrypos") or ply:GetNetVar("carrypos2")

		if lpos then
			if not carry_ent:IsRagdoll() then
				pos = carry_ent:LocalToWorld(lpos)
			else
				pos = LocalToWorld(lpos, angle_zero, mat:GetTranslation(), mat:GetAngles())
			end
		end

		local eyetr     = hg.eyeTrace(ply)
		local distSqr   = pos:DistToSqr(eyetr.StartPos)
		local wep_hands = weapons and weapons.GetStored("weapon_hands_sh")
		local reachdist = (wep_hands and wep_hands.ReachDistance or 100) + 30

		if distSqr > reachdist * reachdist then
			local moving_to = InputToWorldDir(fm, sm, ply_yaw)
			local dir       = (pos - eyetr.StartPos):GetNormalized()
			k = k * math_max(moving_to:Dot(dir), 0)
		end
	end

	local move = run_speed * k  
	ply.move   = move

	if SERVER and not isFakeRagdoll then

		if inertia_len > 5 and runnin and ply == rag then
			local pmul = math_Clamp(inertia_len * 0.005, 0.5, 1) * 5 * (isCrouching and 0.01 or 1)
			if org.pelvis == 1                        then org.painadd = org.painadd + delta_time * pmul end
			if org.lleg   == 1 or org.llegdislocation then org.painadd = org.painadd + delta_time * pmul end
			if org.rleg   == 1 or org.rlegdislocation then org.painadd = org.painadd + delta_time * pmul end
		end

		local currentEyeAng = ply:EyeAngles()
		ply.eyeAnglesOld    = ply.eyeAnglesOld or currentEyeAng
		local cosine = currentEyeAng:Forward():Dot(ply.eyeAnglesOld:Forward())
		ply.eyeAnglesOld = currentEyeAng

		if velLen > 200 and cosine <= 0.99 then
			local ply_pos = ply:GetPos()
			local trace_res = util_TraceLine({
				start  = ply_pos,
				endpos = ply_pos - vector_up,
				filter = ply,
			})

			local surfProps = trace_res.SurfaceProps
			if surfProps then
				local surfData = util_GetSurfaceData(surfProps)
				if surfData and surfData.friction < 0.2 then
					local b_lcalf  = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_L_Calf"))
					local b_rcalf  = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_R_Calf"))
					local b_spine  = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
					local m_lcalf  = hg.IdealMassPlayer["ValveBiped.Bip01_L_Calf"]
					local m_rcalf  = hg.IdealMassPlayer["ValveBiped.Bip01_R_Calf"]
					local m_spine  = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]

					local slip_dir  = vel:GetNormalized() * 150
					local leg_force = slip_dir * 5 - vector_up * 2

					hg.AddForceRag(ply, b_spine, -slip_dir * 5 * m_spine, 0.5)
					hg.AddForceRag(ply, b_lcalf,  leg_force * m_lcalf,    0.5)
					hg.AddForceRag(ply, b_rcalf,  leg_force * m_rcalf,    0.5)

					timer_Simple(0, function()
						if IsValid(ply) then hg.StunPlayer(ply) end
					end)
				end
			end
		end
	end

	if hg_divejump then
		local t = CurTime()
		if ply:KeyPressed(IN_DUCK) then ply.lastInDuck = t end
		if ply:KeyPressed(IN_JUMP) then ply.lastInJump = t end

		if SERVER and ply == rag then
			local last_duck = ply.lastInDuck or 0
			local last_jump = ply.lastInJump or 0
			if (last_jump + 0.1 > t) and (last_duck + 0.1 > t) then
				local torso   = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
				local m_spine = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]
				local dive_dir = ply:GetAimVector()
				dive_dir.z    = 0
				hg.AddForceRag(ply, torso, dive_dir * 400 * m_spine, 0.5)
				hg.Fake(ply)
			end
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
	ply:SetMaxSpeed(inertia_len < 100 and 100 or inertia_len)  

	local jump_k = math_min(k, 1.1)
	if ply:GetNWBool("TauntStopMoving", false) then jump_k = 0 end
	ply:SetJumpPower(
		DEFAULT_JUMP_POWER * jump_k *
		(org.superfighter and 1.5 or 1) *
		(ply.JumpPowerMul or 1)
	)

	if CLIENT then
		local vp2    = (GetViewPunchAngles2 and GetViewPunchAngles2()) or angle_zero
		local vp3    = (GetViewPunchAngles3 and GetViewPunchAngles3()) or angle_zero
		local fwangs = math_rad(vp2.y + vp3.y)
		local c_fw   = math_cos(fwangs)
		local s_fw   = math_sin(fwangs)

		local calc_fw = forward_move * c_fw + side_move * s_fw
		local calc_sd = side_move    * c_fw + forward_move * s_fw

		cmd:SetForwardMove(calc_fw * inertia_len)
		cmd:SetSideMove(calc_sd   * inertia_len)
	end

	mv:SetForwardSpeed(forward_move * inertia_len)
	mv:SetSideSpeed(side_move       * inertia_len)
end)

hook_Add("PlayerSpawn", "RemoveSandboxJumpBoost", function(ply)
	if engine_ActiveGamemode() ~= "sandbox" then return end
	if not baseclass then return end

	local PLAYER = baseclass.Get("player_sandbox")
	if not PLAYER then return end

	PLAYER.FinishMove        = nil
	PLAYER.StartMove         = nil
	PLAYER.SlowWalkSpeed     = 100
	PLAYER.WalkSpeed         = DEFAULT_WALK_SPEED
	PLAYER.RunSpeed          = DEFAULT_RUN_SPEED
	PLAYER.CrouchedWalkSpeed = 0.4
	PLAYER.DuckSpeed         = 0.3
	PLAYER.UnDuckSpeed       = 0.3
	PLAYER.JumpPower         = DEFAULT_JUMP_POWER
end)

hook_Add("StartCommand", "HG_AntiGmodPVP", function(ply, cmd)
	local ducking   = cmd:KeyDown(IN_DUCK)
	ply.NowCrouched = ducking

	if ply.OldCrouched == nil then
		ply.OldCrouched = ducking
	end

	if not ply:OnGround()
	   and ply:WaterLevel() < 2
	   and ply:GetMoveType() == MOVETYPE_WALK
	   and ply.OldCrouched ~= ducking then
		cmd:AddKey(IN_DUCK)
	end

	ply.OldCrouched = ducking
end)
