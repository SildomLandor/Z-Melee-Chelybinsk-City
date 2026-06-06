local render_GetViewSetup = render.GetViewSetup
local hook_Run = hook.Run
local hook_Add = hook.Add
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local math_Clamp = math.Clamp
local math_sin = math.sin
local math_cos = math.cos
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local math_Round = math.Round
local math_Rand = math.Rand
local math_ease_InExpo = math.ease.InExpo
local IsValid = IsValid
local CurTime = CurTime
local FrameTime = FrameTime
local LocalPlayer = LocalPlayer
local ScreenScale = ScreenScale
local ScrW = ScrW
local ScrH = ScrH
local Color = Color
local Vector = Vector
local Angle = Angle
local AngleRand = AngleRand
local VectorRand = VectorRand
local CreateClientConVar = CreateClientConVar
local CreateConVar = CreateConVar
local ConVarExists = ConVarExists
local STR_WEAPON = "Weapon"
local STR_MOTIONBLUREFFECT = "MotionBlurEffect"
local STR_CAMERA = "Camera"
local STR_MOTIONBLUR = "MotionBlur"
local STR_GETMOTIONBLURVALUES = "GetMotionBlurValues"
local STR_BODYCAMFONT = "BODYCAMFONT"
local STR_HUDPAINT = "HUDPaint"
local STR_HUDPAINT_DRAWABOX = "HUDPaint_DrawABox"
local STR_HG_ZOOM_P = "+hg_zoom"
local STR_HG_ZOOM_M = "-hg_zoom"
local STR_HG_ZOOM = "hg_zoom"
local STR_SHOULDDRAWLOCALPLAYER = "ShouldDrawLocalPlayer"
local STR_DRAWLOCALPLAYERALWAYS = "drawlocalplayeralways"
local STR_CALCVIEW = "CalcView"
local STR_HOMIGRAD_VIEW = "homigrad-view"
local STR_HG_INPUTMOUSEAPPLY = "HG.InputMouseApply"
local STR_FREEZETURNING = "FreezeTurning"
local STR_ALTLOOK_P = "+altlook"
local STR_ALTLOOK_M = "-altlook"
local STR_FLIPMOVE = "flipmove"
local STR_CREATEMOVE = "CreateMove"
local STR_ASDINVERT = "ASdInvert"
local STR_RENDERSCENE = "RenderScene"
local STR_JOPA = "jopa"
local STR_LOOKAWAY = "LookAway"
local STR_BONES = "Bones"
local STR_HEADTURNAWAY = "HeadTurnAway"
local STR_PREDRAWTRANSLUCENTRENDERABLES = "PreDrawTranslucentRenderables"
local STR_FPS_FOG = "FPS_Fog"
--

local whitelist = {
	weapon_physgun = true,
	gmod_tool = true,
	gmod_camera = true,
	weapon_crowbar = true,
	weapon_pistol = true,
	weapon_crossbow = true,
	gmod_smoothcamera = true,
	none = true
}

local vecZero, vecFull = Vector(0.001, 0.001, 0.001), Vector(1, 1, 1)
local compression = 12
local traceBuilder = {
	filter = nil,
	mins = -Vector(5, 5, 5),
	maxs = Vector(5, 5, 5),
	mask = MASK_SOLID,
	collisiongroup = COLLISION_GROUP_DEBRIS
}

local anglesYaw = Angle(0, 0, 0)
local vecVel = Vector(0, 0, 0)
local angVel = Angle(0, 0, 0)
local limit = 4
local sideMul = 5
local eyeAngL = Angle(0, 0, 0)

local hg_fov = ConVarExists("hg_fov") and GetConVar("hg_fov") or CreateClientConVar("hg_fov", "70", true, false, "Change first-person field of view", 75, 100)
local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro") or CreateClientConVar("hg_gopro", "0", true, false, "Toggle GoPro-like first-person camera view", 0, 1)

local oldview = render_GetViewSetup()
local breathing_amount = 0
local walk_amount = 0
local curTime = CurTime()
local curTime2 = CurTime()
local angfuk23 = Angle(0,0,0)
local vecdiff = Vector(0, 0, 0)
angle_difference_localvec = Vector(0, 0, 0)
angle_difference_localvec2 = Vector(0, 0, 0)
angle_difference = Angle(0, 0, 0)
angle_difference2 = Angle(0, 0, 0)
position_difference = Vector(0, 0, 0)
position_difference2 = Vector(0, 0, 0)
position_difference23 = Vector(0, 0, 0)
position_difference3 = Vector(0, 0, 0)

offsetView = offsetView or Angle(0, 0, 0)
camera_position_addition = Vector(0,0,0)
local swayAng = Angle(0, 0, 0)

local lply = lply
hook_Add(STR_CAMERA, STR_WEAPON, function(ply, ...)
	ply = ply or lply or LocalPlayer()
	if not IsValid(ply) then return end
	if not ply:Alive() and not IsValid(follow) then return end
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.Camera then return wep:Camera(...) end
end)

hook_Add(STR_MOTIONBLUR, STR_WEAPON, function(x,y,w,z)
	local client = lply or LocalPlayer()
	if not IsValid(client) then return end
	local wep = client:GetActiveWeapon()
	if IsValid(wep) and wep.Blur then return wep:Blur(x,y,w,z) end
end)

hook_Add(STR_GETMOTIONBLURVALUES, STR_MOTIONBLUREFFECT, function(x, y, w, z)
	local blur = hook_Run(STR_MOTIONBLUR, x, y, w, z)
	if blur then
		return blur[1], blur[2], blur[3], blur[4]
	end
end)

local TickInterval = engine.TickInterval
local lerpholdbreath = 1
local velocityAdd = Vector()
local velocityAddVel = Vector()
local walkLerped = 0
local walkTime = 0
local lerped_ang = Angle(0,0,0)

local math_pi = math.pi
local game_GetTimeScale = game.GetTimeScale
local ipairs = ipairs
local pairs = pairs
local next = next

function HGAddView(ply, origin, angles, velLen)
	if ply:Alive() then
		local ent = hg.GetCurrentCharacter(ply)
		local org = ply.organism or {}
		local pulse = org.pulse or 70
		local adrenaline = org.adrenaline or 0
		local temp = org.temperature or 36.6
		local o2 = org.o2 and org.o2[1] or 30
		local analgesia = org.analgesia or 0

		local wep = ply:GetActiveWeapon()
		local inSight = IsValid(wep) and wep.IsZoom and wep:IsZoom()

		local breathing_amount = math_sin((org.pulsethink or 0) + 0.8) * (math_max(((org.heartbeat or 0) / 120 - 1) * 0.05, 0) + math_Clamp((org.stamina and org.stamina[1] and (1 - math_min(1, org.stamina[1] / (org.stamina.max * 0.75))) or 1), 0, 0.5))

		camera_position_addition[1] = 0
		camera_position_addition[2] = 0
		camera_position_addition[3] = (math_sin(breathing_amount + math_pi)) * 0.5

		local spineBone = ply:LookupBone("ValveBiped.Bip01_Spine")
		if spineBone then
			local boneMat = ply:GetBoneMatrix(spineBone)
			if boneMat then
				local anga2 = boneMat:GetAngles()
				anga2:RotateAroundAxis(anga2:Right(), 90)
				camera_position_addition:Rotate(anga2)
				origin:Add(camera_position_addition)
			end
		end

		local ang = AngleRand(-0.1, 0.1) * math_Rand(0, math_min(adrenaline, 1))
		ang[1] = ang[1] + breathing_amount
		ang[3] = 0

		lerped_ang = LerpFT(0.2, lerped_ang, ang * math_max(org.recoilmul or 1, 0.1))

		local vel = ent:GetVelocity()
		local vellen = vel:Length()
		local vellenlerp = velocityAdd and velocityAdd:Length() or vellen
		
		walkLerped = LerpFT(0.1, walkLerped, ply:InVehicle() and 0 or vellenlerp * 100)
		local walk = math_Clamp(walkLerped / 100, 0, 1)
		
		walkTime = walkTime + walk * FrameTime() * 2 * game_GetTimeScale() * (ply:OnGround() and 1 or 0)
		velocityAddVel = LerpFT(0.9, velocityAddVel * 0.9, -vel * 0.1)
		velocityAdd = LerpFT(0.1, velocityAdd, velocityAddVel)
	
		if ply:IsSprinting() then
			walk = walk * 1
		end
	
		local huy = walkTime
		local x, y = math_cos(huy) * math_sin(huy) * walk, math_sin(huy) * walk
		local x2, y2 = math_cos(huy) * math_sin(huy) * walk + math_sin(huy + 0.25) * 0.25 * walk, math_sin(huy) * walk + math_cos(huy) * 0.25 * walk

		ViewPunch4(Angle(y2, x2, x2 * 50) * 0.0005 * (ishgweapon(wep) and 1.5 or 1))

		local music = hg.DynamicMusicV2.Player.GetTrack()
		if music then
			local layers = hg.DynamicMusicV2.Player.Layers
			local layerIdx = layers[1]
			local layer = layerIdx and layerIdx[2] or false

			if layer then
				local offset = music.Offset or 0
				local bpm = music.BPM or 140
				local intensity = 1 - ((layer:GetTime() - offset) / 60 * bpm)
				intensity = (intensity - math_Round(intensity)) % 1
				intensity = math_Clamp((intensity * 0.25 + 0.75), 0, 1)
				intensity = math_ease_InExpo(intensity)
			end
		end

		ply.xMove = x

		if ply.MovementInertiaAddView then
			local pInertia = ply.MovementInertiaAddView
			angles = angles + pInertia
			local fTime5 = FrameTime() * 5
			pInertia.r = Lerp(fTime5, pInertia.r, 0)
			pInertia.p = Lerp(fTime5, pInertia.p, 0)
		end
	else
		if ply.MovementInertiaAddView then
			local pInertia = ply.MovementInertiaAddView
			pInertia.r = 0
			pInertia.p = 0
		end
	end

	local ply_override, origin_override, angles_override = hook_Run("HGAddView", ply, origin, angles)
	if origin_override ~= nil then
		origin, angles = origin_override, angles_override
	end
	
	return origin, angles
end

hook_Add(STR_SHOULDDRAWLOCALPLAYER, STR_DRAWLOCALPLAYERALWAYS, function(ply)
end)

local materialsWheelDirve = {
	["dirt"] = true, ["sand"] = true, ["grass"] = true
}

LookX, LookY = 0, 0
local altlook = false
lerpfovadd = 0
local CalcView
local oldVechicleAng = Angle(0,0,0)
local viewOverride

local hg_thirdperson = ConVarExists("hg_thirdperson") and GetConVar("hg_thirdperson") or CreateConVar("hg_thirdperson", 0, FCVAR_REPLICATED, "Toggle third-person camera view", 0, 1)
local hg_legacycam = ConVarExists("hg_legacycam") and GetConVar("hg_legacycam") or CreateConVar("hg_legacycam", 0, FCVAR_REPLICATED, "Toggle legacy first-person camera view if hg_thirdperson is enabled", 0, 1)
local lerpasad = 0

hook.Remove(STR_CALCVIEW, "wac_air_calcview")
hook.Remove(STR_CREATEMOVE, "wac_cl_seatswitch_centerview")

local lerpaim = 1
local hg_leancam_mul = ConVarExists("hg_leancam_mul") and GetConVar("hg_leancam_mul") or CreateClientConVar("hg_leancam_mul", "7", true, false, "Multiply first-person camera view leaning angle", -10, 10)
zooming = false
lerpfovadd2 = 0

concommand.Add("+hg_zoom", function() zooming = true end)
concommand.Add("-hg_zoom", function() zooming = false end)
concommand.Add("hg_zoom", function() zooming = not zooming end)

surface.CreateFont(
	STR_BODYCAMFONT,
	{
		font = "Bahnschrift",
		size = ScreenScale(16),
		italic = true,
		weight = 1500
	}
)

local color_black = Color(0, 0, 0)
local color_white = color_white
local color_gopro1 = Color(0, 173, 255)
local color_gopro2 = Color(0, 70, 103)
local draw_DrawText = draw.DrawText
local draw_RoundedBox = draw.RoundedBox
local DrawBloom = DrawBloom
local DrawSharpen = DrawSharpen
local util_SharedRandom = util.SharedRandom

hook_Add(STR_HUDPAINT, STR_HUDPAINT_DRAWABOX, function()
	lply = IsValid(lply) and lply or LocalPlayer()
	if lply:Alive() and hg_gopro:GetBool() then
		local sW, sH = ScrW(), ScrH()
		local Text = "GoPro #" .. math_Round(util_SharedRandom(lply:SteamID(), 1000, 9999, 1), 0)
		local sW0905 = sW * 0.905
		local sH0035 = sH * 0.035
		draw_DrawText(Text, STR_BODYCAMFONT, sW0905 + 2, sH0035 + 2, color_black, TEXT_ALIGN_CENTER)
		draw_DrawText(Text, STR_BODYCAMFONT, sW0905, sH0035, color_white, TEXT_ALIGN_CENTER)
		
		local sW085 = sW * 0.85
		local sH0085 = sH * 0.085
		draw_RoundedBox(0, sW085, sH0085, 50, 28, color_gopro1)
		draw_RoundedBox(0, sW085 + 58, sH0085, 50, 28, color_gopro1)
		draw_RoundedBox(0, sW085 + 116, sH0085, 50, 28, color_gopro2)
		draw_RoundedBox(0, sW085 + 174, sH0085, 50, 28, color_white)
		
		local nameText = lply:GetName()
		local sH011 = sH * 0.11
		draw_DrawText(nameText, STR_BODYCAMFONT, sW0905 + 2, sH011 + 2, color_black, TEXT_ALIGN_CENTER)
		draw_DrawText(nameText, STR_BODYCAMFONT, sW0905, sH011, color_white, TEXT_ALIGN_CENTER)
		DrawBloom(0.8, 1, 9, 9, 1, 1.2, 0.8, 0.8, 1.2)
		DrawSharpen(0.2, 1.2)
	end
end)

function SpecCam(ply, vec, ang, fov, znear, zfar)
	if not ply:Alive() then return end
	local eye = ply:GetAttachment(ply:LookupAttachment("eyes"))
	if not eye then return end
	local ang1 = eye.Ang + Angle(5, 2, 0)
	local eyeAng = eye.Ang
	local org1 = eye.Pos + eyeAng:Up() * 6 + eyeAng:Forward() * -3 + eyeAng:Right() * 6.5

	return {
		origin = org1,
		angles = ang1,
		fov = 110,
		drawviewer = true,
		znear = 0.7
	}
end

local hg_coolcamera = ConVarExists("hg_coolcamera") and GetConVar("hg_coolcamera") or CreateConVar("hg_coolcamera", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Cool camera movement", 0, 5)
local vector_up = vector_up
local MASK_SOLID_BRUSHONLY = MASK_SOLID_BRUSHONLY
local VectorRand = VectorRand
local GetViewPunchAngles2 = GetViewPunchAngles2
local GetViewPunchAngles3 = GetViewPunchAngles3
local GetViewPunchAngles4 = GetViewPunchAngles4
local GetAllViewPunchAngles = GetAllViewPunchAngles
local GetViewPunchAngles = GetViewPunchAngles
local IsAimingNoScope = IsAimingNoScope
local ishgweapon = ishgweapon

CalcView = function(ply, origin, angles, fov, znear, zfar)
	if g_VR and g_VR.active then return end
	lply = IsValid(lply) and lply or LocalPlayer()
	local activeViewEnt = GetViewEntity()
	if activeViewEnt ~= (ply or lply) then return end

	local view = {
		["origin"] = origin,
		["angles"] = angles,
		["fov"] = fov,
		["znear"] = znear,
		["zfar"] = zfar,
		["drawviewer"] = false,
	}

	if drive.CalcView(ply, view) then return view end

	local rlEnt = hg.GetCurrentCharacter(ply)
	local pOrg = ply.organism
	local fovSub = 0
	if pOrg then
		fovSub = (((pOrg.immobilization or 0) / 4) - (pOrg.adrenaline or 0) * 5 - (pOrg.noradrenaline or 0) * 15)
	end
	
	local suicideSub = 0
	if ply.suiciding then
		local sTime = ply:GetNetVar("suicide_time", CurTime())
		if sTime < CurTime() then
			suicideSub = (1 - math_max(sTime + 8 - CurTime(), 0) / 8) * 20
		end
	end

	local sprintCond = (ply:IsSprinting() and rlEnt == ply and rlEnt:GetVelocity():LengthSqr() > 1500) and 10 or 0
	lerpfovadd = LerpFT(0.01, lerpfovadd, sprintCond - fovSub / 2 - suicideSub)
	lerpfovadd2 = LerpFT(0.1, lerpfovadd2, zooming and -25 or 0)
	fov = hg_fov:GetInt()
	
	if not IsValid(ply) then return end
	
	if lply.lean and math_abs(lply.lean) < 0.01 then
		oldlean = 0
		lean_lerp = 0
	end

	local vpang = GetViewPunchAngles2() + GetViewPunchAngles3()
	vpang[3] = 0

	if IsValid(follow) then
		return hg.CalcViewFake(ply, origin, angles, fov, znear, zfar)
	end
	ply.lockcamera = false

	if not ply:Alive() and not follow then
		return hook_Run("HG_CalcView", lply, origin, angles, fov, znear, zfar)
	end

	if not ply.LookupBone or not ply:LookupBone("ValveBiped.Bip01_Head1") then return end
	if not ply.GetAimVector then return end

	local firstPerson = activeViewEnt == lply
	local fova = {0}
	hook_Run("HG_CalcView", ply, origin, angles, fova, znear, zfar)
	
	if not firstPerson then return end
	
	local att = ply:GetAttachment(ply:LookupAttachment("eyes"))
	if not att then return end
	
	local tr, hullcheck, headm = hg.eyeTrace(ply, 10, ply, att.Ang)
	local eyePos = tr.StartPos
	local vehicle = ply:GetVehicle()
	local vehiclebase = ply.GetSimfphys and ply:GetSimfphys() or nil
	local BadSurfaceDrive = false
	local vel = ply:GetMoveType() ~= MOVETYPE_NOCLIP and ( ( ply:InVehicle() and -vehicle:GetVelocity() or -ply:GetVelocity()) / (ply:InVehicle() and (BadSurfaceDrive and 150 or 550) or 200)) or vector_origin

	if IsValid(vehicle) then
		if IsValid(vehiclebase) then
			vehicle = vehiclebase
		end
		
		local traceStruct = {
			start = vehicle:GetPos(),
			endpos = vehicle:GetPos() + vector_up * -75,
			mask = MASK_SOLID_BRUSHONLY
		}
		local trVeh = util_TraceLine(traceStruct)
		if materialsWheelDirve[util.GetSurfacePropName(trVeh.SurfaceProps)] then
			BadSurfaceDrive = true
		end
		
		local angPunch = vehicle:GetAngles()
		angPunch:Sub(oldVechicleAng)
		angPunch:Normalize()
		angPunch:Div(5)
		
		local PunchFinal = -angPunch
		ViewPunch2(PunchFinal)
		ViewPunch(PunchFinal)
		oldVechicleAng = vehicle:GetAngles()
		vel = vehicle:GetVelocity() / (BadSurfaceDrive and 350 or 550)
	end

	local velLen = vel:Length()
	ViewPunch(AngleRand(-1,1) * velLen / (BadSurfaceDrive and 5 or 50))

	if ply:InVehicle() or velLen > 2 then
		eyePos:Add(VectorRand() * ((velLen + (ply:InVehicle() and 0 or -2)) / (ply:InVehicle() and 50 or 10)))
	end
	
	hg.clamp(vel, limit)
	if ply:InVehicle() then
		angles = ply:GetAimVector():AngleEx(vehicle:GetUp())
	end
	
	hg.cam_things(ply, view, angles)
	
	if not RENDERSCENE then
		local HuyControl = (zb and zb.OverrideCalcView) and zb.OverrideCalcView(ply, origin, angles, fov, znear, zfar)
		if HuyControl ~= nil then
			return HuyControl
		end
	end

	if hg_thirdperson:GetBool() then
		local insideScope = IsAimingNoScope(ply)
		lerpaim = LerpFT(0.1, lerpaim, (not insideScope) and 1 or (hg_legacycam:GetBool() and 1 or 0))
		local pLean = ply.lean or 0
		local leanmul1 = ((pLean < 0 and pLean * 2.2 or 0) + 1)
		
		origin = origin + ((angles:Forward() * -30 + angles:Right() * 15 * leanmul1) * lerpaim)
		view = hook_Run(STR_CAMERA, ply, view.origin, view.angles, view, vector_origin) or view
		lerpasad = Lerp(0.1, lerpasad, ((insideScope or hg_legacycam:GetBool()) and 0.001 or 1))

		local pos = hg.eye(ply, 10, follow)
		local ang = ply:EyeAngles()
		
		local trThird = {
			start = pos,
			endpos = pos - ang:Forward() * 60 * lerpasad + ang:Right() * 15 * lerpasad,
			filter = {ply},
			mask = MASK_SOLID
		}

		view.origin = util_TraceLine(trThird).HitPos + ((trThird.endpos - trThird.start):GetNormalized() * -5)
		view.angles = angles
		view.drawviewer = true
		view.fov = 95 + lerpfovadd + lerpfovadd2
		return view
	end

	view.znear = 1
	view.zfar = zfar
	view.fov = math_Clamp(hg_fov:GetFloat(), 75, 100) + fova[1] + lerpfovadd + lerpfovadd2
	view.drawviewer = true
	view.origin = origin
	view.angles = angles

	result = hook_Run(STR_CAMERA, ply, eyePos, angles, view, velLen * 200)
	view.origin, view.angles = HGAddView(ply, view.origin, view.angles, velLen)
	realangle = realangle or lply:EyeAngles()

	if GetCoolCameraBool() then
		view.angles = realangle + GetViewPunchAngles() * 0.4 + vpang
		view.angles[3] = view.angles[3] - GetViewPunchAngles4()[3]
		angles = view.angles
	end

	view.angles:RotateAroundAxis(view.angles:Up(), -LookX)
	view.angles:RotateAroundAxis(view.angles:Right(), -LookY)

	if hg_gopro:GetBool() then
		local vpangs = GetAllViewPunchAngles()
		local anglegopro = Angle(0, vpangs[1], -vpangs[2])
		local cTime = CurTime()
		anglegopro[2] = anglegopro[2] + math_sin(cTime * 2) * math_cos(cTime) * 2
		anglegopro[1] = anglegopro[1] + math_cos(cTime) * math_sin(cTime * 1.25) * 3
		
		hg.bone.Set(ply, "head", vector_origin, anglegopro, "gopro")
		return SpecCam(ply, origin, angles, fov, znear, zfar)
	end

	if result == view then
		traceBuilder.start = origin
		traceBuilder.endpos = view.origin
		local trace = hg.hullCheck(ply:EyePos() - vector_up * 10, view.origin, ply)
		view.origin = trace.HitPos
		
		view.angles:Add(-vpang)
		view.angles[3] = view.angles[3] + GetViewPunchAngles4()[3]
		hook_Run("PostHGCalcView", ply, view)
		return view
	end

	view.origin = eyePos
	view.angles = angles
	view.angles:Add(-vpang)
	view.angles[3] = view.angles[3] + GetViewPunchAngles4()[3]

	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and whitelist[wep:GetClass()] then return end
	result = hook_Run("PostPostHGCalcView", ply, view)
	if result then return result end

	return view
end

local angleZero = Angle(0,0,0)
local angle_zero = angle_zero
local torsoOld
local eyeAnglesOld
local ftlerped = ftlerped

function hg.cam_things(ply, view, angles)
	local wep = ply:GetActiveWeapon()
	local eyeAngs = ply:EyeAngles()
	eyeAngs[3] = 0
	local oldviewa = oldview or view
	local ent = hg.GetCurrentCharacter(ply)
	
	local spineBone = ent:LookupBone("ValveBiped.Bip01_Spine")
	if not spineBone then return end
	local spineMatrix = ent:GetBoneMatrix(spineBone)
	if not spineMatrix then return end
	local torso = spineMatrix:GetAngles()
	
	if not ply:Alive() then oldviewa = view end
	
	eyeAnglesOld = eyeAnglesOld or eyeAngs
	torsoOld = torsoOld or torso
	
	local different, _ = WorldToLocal(eyeAngs:Forward(), angle_zero, eyeAnglesOld:Forward(), angle_zero)
	local different2, _ = WorldToLocal(torso:Forward(), angle_zero, torsoOld:Forward(), angle_zero)
	local _, localAng = WorldToLocal(vector_origin, eyeAngs, vector_origin, eyeAnglesOld)

	torsoOld = torso

	local fthuy = math_max(0.0001, ftlerped * 150 * game_GetTimeScale())
	
	angle_difference_localvec = LerpVectorFT(0.08, angle_difference_localvec, -different / fthuy)
	angle_difference_localvec2 = LerpVectorFT(0.08, angle_difference_localvec2, -different2 / fthuy)
	angle_difference = LerpAngleFT(0.08, angle_difference, localAng * 2 / fthuy)
	angle_difference2 = LerpAngleFT(0.1, angle_difference2, localAng * 2 / fthuy)
	
	local vela = -(ent:GetVelocity() / 50)
	position_difference = LerpVectorFT(0.15, position_difference, vela)
	position_difference2 = LerpVectorFT(0.05, position_difference2, vela)
	
	local eRight, eUp = ply:EyeAngles():Right(), ply:EyeAngles():Up()
	position_difference23 = eRight * math_Clamp(position_difference2:Dot(eRight), -4, 4) + eUp * math_Clamp(position_difference2:Dot(eUp), -4, 4)

	table.CopyFromTo(view, oldview)

	position_difference3[1] = 0
	position_difference3[3] = 0
	position_difference3[2] = position_difference:Dot(eyeAngs:Right())
	
	hg.clamp(position_difference, 2)
	hg.clamp(position_difference3, 5)
	hg.clamp(angle_difference_localvec, 10)
	hg.clamp(angle_difference, 10)
	hg.clamp(angle_difference2, 10)
	
	if not hg.KeyDown(ply, IN_SPEED) then
		offsetView[1] = math_Clamp(offsetView[1] - angle_difference2[1] / 18, -2, 2)
		offsetView[2] = math_Clamp(offsetView[2] - angle_difference2[2] / 18, -4, 4)
	end

	offsetView = LerpFT(0.001, offsetView, angleZero)
	eyeAnglesOld = eyeAngs
	
	angles[3] = angles[3] - angle_difference[2] * 0.5 - (lean_lerp or 0) * hg_leancam_mul:GetInt()
end

concommand.Add("+altlook", function() altlook = true end)
concommand.Add("-altlook", function() altlook = false end)

local MaxLookX, MinLookX = 55, -55 
local MaxLookY, MinLookY = 45, -45

hook_Add(STR_HG_INPUTMOUSEAPPLY, STR_FREEZETURNING, function(tbl)
	MaxLookX, MinLookX = hg.MaxLookX or MaxLookX, hg.MinLookX or MinLookX
	MaxLookY, MinLookY = hg.MaxLookY or MaxLookY, hg.MinLookY or MinLookY

	if not altlook then
		LookY = LerpFT(0.1, LookY, 0)
		if math_abs(LookY) <= 0.01 then LookY = 0 end
		LookX = LerpFT(0.1, LookX, 0)
		if math_abs(LookX) <= 0.01 then LookX = 0 end
	else
		lply = IsValid(lply) and lply or LocalPlayer()
		if lply:Alive() then
			LookX = math_Clamp(LookX + tbl.x * 0.015, MinLookX, MaxLookX)
			LookY = math_Clamp(LookY + tbl.y * 0.015, MinLookY, MaxLookY)
			tbl.x = 0
			tbl.y = 0
		end
	end
end)

hg.CalcView = CalcView
hook_Add(STR_CALCVIEW, STR_HOMIGRAD_VIEW, function(ply, origin, angles, fov, znear, zfar)
	local viewa = viewOverride
	viewOverride = nil
	return viewa or CalcView(ply, origin, angles, fov, znear, zfar)
end)

local render_RenderView = render.RenderView
local renderView = {
	x = 0,
	y = 0,
	drawhud = true,
	drawviewmodel = true,
	dopostprocess = true,
	drawmonitors = true,
	fov = 100
}

local fliprt = GetRenderTarget("fb_flipped", ScrW(), ScrH(), false)
local fliprtmat = CreateMaterial(
	"fliprtmat",
	"UnlitGeneric",
	{
		['$basetexture'] = fliprt,
		['$basetexturetransform'] = "center .5 .5 scale -1 1 rotate 0 translate 0 0",
	}
)

local invertCam = CreateClientConVar("hg_cheats", "0", false, false, "Toggle uselezz cheats", 0, 1)

hook_Add(STR_HG_INPUTMOUSEAPPLY, STR_ASDINVERT, function(tbl)
	if invertCam:GetBool() then
		tbl.x = -tbl.x
	end
end)

hook_Add(STR_CREATEMOVE, STR_FLIPMOVE, function(cmd)	
	if invertCam:GetBool() then
		cmd:SetSideMove(-cmd:GetSideMove())
	end
end)

local mapswithfog = {}
local zfar = mapswithfog[game.GetMap()] or 0
local map = game.GetMap()
local scrw, scrh = ScrW(), ScrH()
local entmeta = FindMetaTable("Entity")
local eyepos = entmeta.EyePos
local eyeangles = entmeta.EyeAngles

local function renderscene(pos, angle, fov)
	lply = IsValid(lply) and lply or LocalPlayer()
	
	pos = eyepos(lply)
	angle = eyeangles(lply)
	local view = CalcView(lply, pos, angle, fov)
	viewOverride = view
	
	local invert = invertCam:GetBool()
	RENDERSCENE = nil
	if not view then return end
	
	local oldrt
	if invert then
		oldrt = render.GetRenderTarget()
		render.SetRenderTarget(fliprt)
	end

	renderView.w = ScrW()
	renderView.h = ScrH()
	renderView.fov = fov
	renderView.origin = view.origin
	renderView.angles = view.angles
	if mapswithfog[map] then
		renderView.zfar = zfar
	end

	lply.norender = true
	if not isvector(view.origin) or not isangle(view.angles) then return end

	render_RenderView(renderView)
	lply.norender = nil
	
	if invert then
		render.SetRenderTarget(oldrt)
		fliprtmat:SetTexture("$basetexture", fliprt)
		render.SetMaterial(fliprtmat)
		render.DrawScreenQuad()
	end

	return true
end

hook_Add(STR_RENDERSCENE, STR_JOPA, renderscene)

local vector_zero = Vector(0,0,0)
net.Receive(STR_LOOKAWAY, function()
	local ply = net.ReadEntity()
	if not IsValid(ply) then return end
	local rX = net.ReadFloat()
	local rY = net.ReadFloat()
	ply.LookX1 = math_Clamp(rX, MinLookX, MaxLookX)
	ply.LookY1 = math_Clamp(rY, MinLookY, MaxLookY)
	ply.LastLookSend = CurTime()
end)

local angle_use = Angle(0,0,0)
hook_Add(STR_BONES, STR_HEADTURNAWAY, function(ply)
	local cTime = CurTime()
	lply = IsValid(lply) and lply or LocalPlayer()
	local isLocal = ply == lply

	if (ply.head_netsendtime or 0) < cTime and isLocal and (hg.IsChanged(LookX, "LookX") or hg.IsChanged(LookY, "LookY")) then
		ply.head_netsendtime = cTime + 0.1
		net.Start(STR_LOOKAWAY, true)
			net.WriteFloat(LookX)
			net.WriteFloat(LookY)
		net.SendToServer()
	end

	if not isLocal and ((ply.LastLookSend or 0) + 1) < cTime then
		ply.LookX = nil
		ply.LookY = nil
	end

	ply.LookX = Lerp(0.1, ply.LookX or 0, isLocal and LookX or ply.LookX1 or 0)
	ply.LookY = Lerp(0.1, ply.LookY or 0, isLocal and LookY or ply.LookY1 or 0)

	local angle = angle_use
	angle[2] = -(ply.LookY or 0) * 0.6
	angle[3] = -(ply.LookX or 0) * 0.6

	if not angle:IsEqualTol(angle_zero, 0.01) then
		hg.bone.Set(ply, "head", vector_origin, angle, "headturn")
	end
end)

local n = 35
local color = Color(render.GetFogColor())
local fogcolor = Color(render.GetFogColor())
local tbl = {}
local render_SetColorMaterial = render.SetColorMaterial
local render_DrawSphere = render.DrawSphere
local ColorAlpha = ColorAlpha

local function DrawFog(bDepth, bSkybox)
	if not mapswithfog[map] then return end

	render_SetColorMaterial()

	local view = render_GetViewSetup()
	local pos = view.origin
	zfar = LerpFT(0.005, zfar, not util.IsSkyboxVisibleFromPoint(pos) and 15000 or mapswithfog[map])

	local baseZFar = zfar - (mapswithfog[map] / 2.5)
	local step = mapswithfog[map] / 2.5
	for i = 1, n do
		tbl[i] = tbl[i] or ColorAlpha(color, (i / n) * 110)
		render_DrawSphere(pos, -(baseZFar + ((i - 1) * n)), 15, 15, tbl[i])
	end
end

hook_Add(STR_PREDRAWTRANSLUCENTRENDERABLES, STR_FPS_FOG, function(bDepth, bSkybox)
	DrawFog(bDepth, bSkybox)
end)