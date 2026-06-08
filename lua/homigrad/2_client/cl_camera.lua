local R = {
	GetViewSetup     = render.GetViewSetup,
	RenderView       = render.RenderView,
	SetColorMaterial = render.SetColorMaterial,
	DrawSphere       = render.DrawSphere,
	GetRenderTarget  = render.GetRenderTarget,
	SetRenderTarget  = render.SetRenderTarget,
	SetMaterial      = render.SetMaterial,
	DrawScreenQuad   = render.DrawScreenQuad
}

local M = {
	Clamp      = math.Clamp,
	sin        = math.sin,
	cos        = math.cos,
	max        = math.max,
	min        = math.min,
	abs        = math.abs,
	Round      = math.Round,
	Rand       = math.Rand,
	ease_InExpo = math.ease.InExpo,
	pi         = math.pi
}

local U = {
	TraceLine          = util.TraceLine,
	GetSurfacePropName = util.GetSurfacePropName,
	IsSkyboxVisible    = util.IsSkyboxVisibleFromPoint,
	SharedRandom       = util.SharedRandom
}

local N = {
	Start         = net.Start,
	Receive       = net.Receive,
	WriteFloat    = net.WriteFloat,
	SendToServer  = net.SendToServer,
	ReadEntity    = net.ReadEntity,
	ReadFloat     = net.ReadFloat
}

local D = {
	CreateFont = surface.CreateFont,
	DrawText   = draw.DrawText,
	RoundedBox = draw.RoundedBox,
	Bloom      = DrawBloom,
	Sharpen    = DrawSharpen
}

local hook_Run                 = hook.Run
local hook_Add                 = hook.Add
local hook_Remove              = hook.Remove
local IsValid                  = IsValid
local CurTime                  = CurTime
local FrameTime                = FrameTime
local LocalPlayer              = LocalPlayer
local ScreenScale              = ScreenScale
local ScrW                     = ScrW
local ScrH                     = ScrH
local Color                    = Color
local ColorAlpha               = ColorAlpha
local Vector                   = Vector
local Angle                    = Angle
local AngleRand                = AngleRand
local VectorRand               = VectorRand
local Lerp                     = Lerp
local LerpFT                   = LerpFT
local LerpVectorFT             = LerpVectorFT
local LerpAngleFT              = LerpAngleFT
local WorldToLocal             = WorldToLocal
local LocalToWorld             = LocalToWorld
local isvector                 = isvector
local isangle                  = isangle
local ipairs                   = ipairs
local pairs                    = pairs
local next                     = next
local type                     = type
local CreateClientConVar       = CreateClientConVar
local CreateConVar             = CreateConVar
local ConVarExists             = ConVarExists
local GetViewEntity            = GetViewEntity
local game_GetTimeScale        = game.GetTimeScale

local STR_WEAPON                        = "Weapon"
local STR_MOTIONBLUREFFECT              = "MotionBlurEffect"
local STR_CAMERA                        = "Camera"
local STR_MOTIONBLUR                    = "MotionBlur"
local STR_GETMOTIONBLURVALUES           = "GetMotionBlurValues"
local STR_BODYCAMFONT                   = "BODYCAMFONT"
local STR_HUDPAINT                      = "HUDPaint"
local STR_HUDPAINT_DRAWABOX             = "HUDPaint_DrawABox"
local STR_SHOULDDRAWLOCALPLAYER         = "ShouldDrawLocalPlayer"
local STR_DRAWLOCALPLAYERALWAYS         = "drawlocalplayeralways"
local STR_CALCVIEW                      = "CalcView"
local STR_HOMIGRAD_VIEW                 = "homigrad-view"
local STR_HG_INPUTMOUSEAPPLY            = "HG.InputMouseApply"
local STR_FREEZETURNING                 = "FreezeTurning"
local STR_FLIPMOVE                      = "flipmove"
local STR_CREATEMOVE                    = "CreateMove"
local STR_ASDINVERT                     = "ASdInvert"
local STR_RENDERSCENE                   = "RenderScene"
local STR_JOPA                          = "jopa"
local STR_LOOKAWAY                      = "LookAway"
local STR_BONES                         = "Bones"
local STR_HEADTURNAWAY                  = "HeadTurnAway"
local STR_PREDRAWTRANSLUCENTRENDERABLES = "PreDrawTranslucentRenderables"
local STR_FPS_FOG                       = "FPS_Fog"
local STR_SPINE                         = "ValveBiped.Bip01_Spine"
local STR_HEAD                          = "ValveBiped.Bip01_Head1"
local STR_EYES                          = "eyes"
local STR_HEAD_BONE                     = "head"
local STR_GOPRO                         = "gopro"
local STR_HEADTURN                      = "headturn"
local STR_POSTFIX                       = "PostHGCalcView"
local STR_POSTPOSTFIX                   = "PostPostHGCalcView"
local STR_HGCALCVIEW                    = "HG_CalcView"
local STR_HGADDVIEW                     = "HGAddView"
local STR_WEAPON_HANDS                  = "weapon_hands_sh"

local whitelist = {
	weapon_physgun   = true, gmod_tool        = true,
	gmod_camera      = true, weapon_crowbar   = true,
	weapon_pistol    = true, weapon_crossbow  = true,
	gmod_smoothcamera = true, none            = true,
}

local materialsWheelDrive = { dirt = true, sand = true, grass = true }

local entmeta          = FindMetaTable("Entity")
local plymeta          = FindMetaTable("Player") or entmeta

local ply_EyeAngles    = entmeta.EyeAngles
local ply_EyePos       = entmeta.EyePos
local ply_GetVelocity  = entmeta.GetVelocity
local ply_GetBoneMatrix = entmeta.GetBoneMatrix
local ply_LookupBone   = entmeta.LookupBone
local ply_Alive        = plymeta.Alive or entmeta.Alive
local ply_InVehicle    = plymeta.InVehicle or entmeta.InVehicle
local ply_OnGround     = entmeta.OnGround
local ply_IsSprinting  = plymeta.IsSprinting or function(p) return p:KeyDown(IN_SPEED) end
local ply_Crouching    = plymeta.Crouching or entmeta.Crouching
local ply_GetVehicle   = plymeta.GetVehicle or entmeta.GetVehicle
local ply_GetMoveType  = entmeta.GetMoveType
local ply_GetNetVar    = entmeta.GetNetVar
local ply_GetName      = entmeta.GetName
local ply_SteamID      = plymeta.SteamID or entmeta.SteamID
local ply_GetActiveWeapon = plymeta.GetActiveWeapon or entmeta.GetActiveWeapon
local ply_GetAttachment   = entmeta.GetAttachment
local ply_LookupAttachment = entmeta.LookupAttachment
local ply_GetAngles    = entmeta.GetAngles
local ply_GetAimVector = entmeta.GetAimVector
local ply_GetPos       = entmeta.GetPos

local vecZero     = Vector(0.001, 0.001, 0.001)
local vecFull     = Vector(1, 1, 1)
local vec_origin  = vector_origin
local vec_up      = vector_up
local ang_zero    = Angle(0, 0, 0)
local angle_zero  = angle_zero
local MASK_SOL    = MASK_SOLID
local MASK_SOLBR  = MASK_SOLID_BRUSHONLY
local MOVETYPE_NC = MOVETYPE_NOCLIP
local IN_SPEED_K  = IN_SPEED

local compression = 12
local limit       = 4

local traceBuilder = {
	filter = nil, mins = -Vector(5,5,5), maxs = Vector(5,5,5),
	mask = MASK_SOL, collisiongroup = COLLISION_GROUP_DEBRIS,
}
local traceVehicle = { start = Vector(), endpos = Vector(), mask = MASK_SOLBR }
local traceThird   = { start = Vector(), endpos = Vector(), filter = nil, mask = MASK_SOL }

local hg_fov = ConVarExists("hg_fov") and GetConVar("hg_fov")
	or CreateClientConVar("hg_fov", "70", true, false, "Change first-person field of view", 75, 100)
local hg_gopro = ConVarExists("hg_gopro") and GetConVar("hg_gopro")
	or CreateClientConVar("hg_gopro", "0", true, false, "Toggle GoPro-like first-person camera view", 0, 1)
local hg_thirdperson = ConVarExists("hg_thirdperson") and GetConVar("hg_thirdperson")
	or CreateConVar("hg_thirdperson", 0, FCVAR_REPLICATED, "Toggle third-person camera view", 0, 1)
local hg_legacycam = ConVarExists("hg_legacycam") and GetConVar("hg_legacycam")
	or CreateConVar("hg_legacycam", 0, FCVAR_REPLICATED, "Toggle legacy first-person camera view if hg_thirdperson is enabled", 0, 1)
local hg_leancam_mul = ConVarExists("hg_leancam_mul") and GetConVar("hg_leancam_mul")
	or CreateClientConVar("hg_leancam_mul", "7", true, false, "Multiply first-person camera view leaning angle", -10, 10)
local hg_coolcamera = ConVarExists("hg_coolcamera") and GetConVar("hg_coolcamera")
	or CreateConVar("hg_coolcamera", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Cool camera movement", 0, 5)
local invertCam = CreateClientConVar("hg_cheats", "0", false, false, "Toggle uselezz cheats", 0, 1)

local oldview         = R.GetViewSetup()
local angfuk23        = Angle(0,0,0)
local vecdiff         = Vector(0,0,0)
angle_difference_localvec  = Vector(0,0,0)
angle_difference_localvec2 = Vector(0,0,0)
angle_difference  = Angle(0,0,0)
angle_difference2 = Angle(0,0,0)
position_difference   = Vector(0,0,0)
position_difference2  = Vector(0,0,0)
position_difference23 = Vector(0,0,0)
position_difference3  = Vector(0,0,0)
offsetView            = offsetView or Angle(0,0,0)
camera_position_addition = Vector(0,0,0)

local lply
local lerpholdbreath  = 1
local velocityAdd     = Vector()
local velocityAddVel  = Vector()
local walkLerped      = 0
local walkTime        = 0
local lerped_ang      = Angle(0,0,0)
local swayAng         = Angle(0,0,0)
local anglesYaw       = Angle(0,0,0)
local eyeAngL         = Angle(0,0,0)
local torsoOld
local eyeAnglesOld
local ftlerped        = ftlerped
local angleZero       = Angle(0,0,0)

LookX, LookY = 0, 0
local altlook        = false
lerpfovadd           = 0
lerpfovadd2          = 0
zooming              = false
local lerpasad       = 0
local lerpaim        = 1
local oldVechicleAng = Angle(0,0,0)
local viewOverride
local CalcView

local GetViewPunchAngles  = GetViewPunchAngles
local GetViewPunchAngles2 = GetViewPunchAngles2
local GetViewPunchAngles3 = GetViewPunchAngles3
local GetViewPunchAngles4 = GetViewPunchAngles4
local GetAllViewPunchAngles = GetAllViewPunchAngles
local IsAimingNoScope     = IsAimingNoScope
local ishgweapon          = ishgweapon

local MaxLookX, MinLookX = 55, -55
local MaxLookY, MinLookY = 45, -45

local color_black  = Color(0,0,0)
local color_white  = color_white
local color_gopro1 = Color(0,173,255)
local color_gopro2 = Color(0,70,103)

local map            = game.GetMap()
local mapswithfog    = {}
local zfar_fog       = mapswithfog[map] or 0
local scrw, scrh     = ScrW(), ScrH()

local renderView = {
	x=0, y=0, drawhud=true, drawviewmodel=true,
	dopostprocess=true, drawmonitors=true, fov=100,
	w=scrw, h=scrh,
}

local fliprt    = GetRenderTarget("fb_flipped", scrw, scrh, false)
local fliprtmat = CreateMaterial("fliprtmat","UnlitGeneric",{
	['$basetexture'] = fliprt,
	['$basetexturetransform'] = "center .5 .5 scale -1 1 rotate 0 translate 0 0",
})

local fogN            = 35
local fogcolor        = Color(render.GetFogColor())
local fogSphereColors = {}
for i = 1, fogN do fogSphereColors[i] = ColorAlpha(fogcolor, (i/fogN)*110) end
local fogSphereRadii  = {}
local fogRadiiZfar    = -1
local fogSkyboxVis    = true
local fogSkyboxNext   = 0
local fogBaseZFar     = 0

D.CreateFont(STR_BODYCAMFONT, {
	font="Bahnschrift", size=ScreenScale(16), italic=true, weight=1500,
})

hook_Add(STR_CAMERA, STR_WEAPON, function(ply, ...)
	ply = ply or lply or LocalPlayer()
	if not IsValid(ply) then return end
	if not ply_Alive(ply) and not IsValid(follow) then return end
	local wep = ply_GetActiveWeapon(ply)
	if IsValid(wep) and wep.Camera then return wep:Camera(...) end
end)

hook_Add(STR_MOTIONBLUR, STR_WEAPON, function(x,y,w,z)
	local c = lply or LocalPlayer()
	if not IsValid(c) then return end
	local wep = ply_GetActiveWeapon(c)
	if IsValid(wep) and wep.Blur then return wep:Blur(x,y,w,z) end
end)

hook_Add(STR_GETMOTIONBLURVALUES, STR_MOTIONBLUREFFECT, function(x,y,w,z)
	local b = hook_Run(STR_MOTIONBLUR, x,y,w,z)
	if b then return b[1],b[2],b[3],b[4] end
end)

hook_Add(STR_SHOULDDRAWLOCALPLAYER, STR_DRAWLOCALPLAYERALWAYS, function() end)

hook_Add(STR_HUDPAINT, STR_HUDPAINT_DRAWABOX, function()
	lply = IsValid(lply) and lply or LocalPlayer()
	if not (ply_Alive(lply) and hg_gopro:GetBool()) then return end
	local sW, sH   = ScrW(), ScrH()
	local sW0905   = sW * 0.905
	local sH0035   = sH * 0.035
	local Text     = "GoPro #" .. M.Round(U.SharedRandom(ply_SteamID(lply), 1000, 9999, 1), 0)
	D.DrawText(Text, STR_BODYCAMFONT, sW0905+2, sH0035+2, color_black, TEXT_ALIGN_CENTER)
	D.DrawText(Text, STR_BODYCAMFONT, sW0905,   sH0035,   color_white, TEXT_ALIGN_CENTER)
	local sW085  = sW * 0.85
	local sH0085 = sH * 0.085
	D.RoundedBox(0, sW085,     sH0085, 50, 28, color_gopro1)
	D.RoundedBox(0, sW085+58,  sH0085, 50, 28, color_gopro1)
	D.RoundedBox(0, sW085+116, sH0085, 50, 28, color_gopro2)
	D.RoundedBox(0, sW085+174, sH0085, 50, 28, color_white)
	local nameText = ply_GetName(lply)
	local sH011    = sH * 0.11
	D.DrawText(nameText, STR_BODYCAMFONT, sW0905+2, sH011+2, color_black, TEXT_ALIGN_CENTER)
	D.DrawText(nameText, STR_BODYCAMFONT, sW0905,   sH011,   color_white, TEXT_ALIGN_CENTER)
	D.Bloom(0.8, 1, 9, 9, 1, 1.2, 0.8, 0.8, 1.2)
	D.Sharpen(0.2, 1.2)
end)

local specAngAdd = Angle(5,2,0)
function SpecCam(ply)
	if not ply_Alive(ply) then return end
	local eye = ply_GetAttachment(ply, ply_LookupAttachment(ply, STR_EYES))
	if not eye then return end
	local ea  = eye.Ang
	return {
		origin    = eye.Pos + ea:Up()*6 + ea:Forward()*-3 + ea:Right()*6.5,
		angles    = ea + specAngAdd,
		fov       = 110, drawviewer = true, znear = 0.7,
	}
end

function HGAddView(ply, origin, angles, velLen)
	if not ply_Alive(ply) then
		if ply.MovementInertiaAddView then
			local pi = ply.MovementInertiaAddView
			pi.r = 0 ; pi.p = 0
		end
		local _,oo,ao = hook_Run(STR_HGADDVIEW, ply, origin, angles)
		if oo ~= nil then return oo, ao end
		return origin, angles
	end

	local ent      = hg.GetCurrentCharacter(ply)
	local org      = ply.organism or {}
	local adrenaline = org.adrenaline or 0
	local stamina  = org.stamina
	local heartbeat = org.heartbeat or 0
	local pulsethink = org.pulsethink or 0
	local recoilmul  = org.recoilmul or 1
	local stam_ratio = (stamina and stamina[1])
		and (1 - M.min(1, stamina[1] / ((stamina.max or 240) * 0.75)))
		or 1

	local breath = M.sin(pulsethink + 0.8) * (
		M.max((heartbeat/120 - 1) * 0.05, 0) +
		M.Clamp(stam_ratio, 0, 0.5)
	)

	camera_position_addition[1] = 0
	camera_position_addition[2] = 0
	camera_position_addition[3] = M.sin(breath + M.pi) * 0.5

	local spineBone = ply_LookupBone(ply, STR_SPINE)
	if spineBone then
		local boneMat = ply_GetBoneMatrix(ply, spineBone)
		if boneMat then
			local a2 = boneMat:GetAngles()
			a2:RotateAroundAxis(a2:Right(), 90)
			camera_position_addition:Rotate(a2)
			origin:Add(camera_position_addition)
		end
	end

	local ang  = AngleRand(-0.1, 0.1) * M.Rand(0, M.min(adrenaline, 1))
	ang[1]     = ang[1] + breath
	ang[3]     = 0
	local rmul = recoilmul < 0.1 and 0.1 or recoilmul
	lerped_ang = LerpFT(0.2, lerped_ang, ang * rmul)

	local vel        = ply_GetVelocity(ent)
	local vellen     = vel:Length()
	local vellenlerp = velocityAdd:Length()
	local inVeh      = ply_InVehicle(ply)

	walkLerped  = LerpFT(0.1, walkLerped, inVeh and 0 or vellenlerp * 100)
	local walk  = walkLerped > 100 and 1 or (walkLerped < 0 and 0 or walkLerped * 0.01)
	walkTime    = walkTime + walk * FrameTime() * 2 * game_GetTimeScale() * (ply_OnGround(ply) and 1 or 0)
	velocityAddVel = LerpFT(0.9, velocityAddVel * 0.9, -vel * 0.1)
	velocityAdd    = LerpFT(0.1, velocityAdd, velocityAddVel)

	local huy = walkTime
	local ch  = M.cos(huy)
	local sh  = M.sin(huy)
	local x   = ch * sh * walk
	local y   = sh * walk
	local wep = ply_GetActiveWeapon(ply)
	local wm  = (IsValid(wep) and ishgweapon(wep)) and 0.00075 or 0.0005
	ViewPunch4(Angle(
		y  * ch * 0.25 * walk + sh * walk,
		x  + M.sin(huy + 0.25) * 0.25 * walk,
		(x + M.sin(huy + 0.25) * 0.25 * walk) * 50
	) * wm)

	local music = hg.DynamicMusicV2.Player.GetTrack()
	if music then
		local li  = hg.DynamicMusicV2.Player.Layers
		local l0  = li[1]
		local layer = l0 and l0[2]
		if layer then
			local bpm = music.BPM or 140
			local t   = (layer:GetTime() - (music.Offset or 0)) / 60 * bpm
			local intensity = M.Clamp(((t - M.Round(t))%1)*0.25+0.75, 0, 1)
			M.ease_InExpo(intensity)
		end
	end

	ply.xMove = x

	if ply.MovementInertiaAddView then
		local pi   = ply.MovementInertiaAddView
		angles     = angles + pi
		local ft5  = FrameTime() * 5
		pi.r = Lerp(ft5, pi.r, 0)
		pi.p = Lerp(ft5, pi.p, 0)
	end

	local _,oo,ao = hook_Run(STR_HGADDVIEW, ply, origin, angles)
	if oo ~= nil then return oo, ao end
	return origin, angles
end

function hg.cam_things(ply, view, angles)
	local eyeAngs = ply_EyeAngles(ply)
	eyeAngs[3]    = 0
	local ent     = hg.GetCurrentCharacter(ply)

	local spineBone = ply_LookupBone(ent, STR_SPINE)
	if not spineBone then return end
	local spineMatrix = ply_GetBoneMatrix(ent, spineBone)
	if not spineMatrix then return end
	local torso = spineMatrix:GetAngles()

	if not ply_Alive(ply) then oldview = view end

	eyeAnglesOld = eyeAnglesOld or eyeAngs
	torsoOld     = torsoOld or torso

	local efwd  = eyeAngs:Forward()
	local eofwd = eyeAnglesOld:Forward()
	local tfwd  = torso:Forward()
	local tofwd = torsoOld:Forward()

	local different,  _ = WorldToLocal(efwd,  angle_zero, eofwd, angle_zero)
	local different2, _ = WorldToLocal(tfwd,  angle_zero, tofwd, angle_zero)
	local _, localAng   = WorldToLocal(vec_origin, eyeAngs, vec_origin, eyeAnglesOld)

	torsoOld = torso

	local ts   = game_GetTimeScale()
	local ft   = ftlerped or FrameTime()
	local fthuy = ft * 150 * ts
	if fthuy < 0.0001 then fthuy = 0.0001 end
	local inv  = 1 / fthuy
	local la2  = localAng * (2 * inv)

	angle_difference_localvec  = LerpVectorFT(0.08, angle_difference_localvec,  -different  * inv)
	angle_difference_localvec2 = LerpVectorFT(0.08, angle_difference_localvec2, -different2 * inv)
	angle_difference           = LerpAngleFT(0.08, angle_difference,  la2)
	angle_difference2          = LerpAngleFT(0.1,  angle_difference2, la2)

	local vela = -(ply_GetVelocity(ent) * 0.02)
	position_difference  = LerpVectorFT(0.15, position_difference,  vela)
	position_difference2 = LerpVectorFT(0.05, position_difference2, vela)

	local eRight = eyeAngs:Right()
	local eUp    = eyeAngs:Up()
	local d2r    = position_difference2:Dot(eRight)
	local d2u    = position_difference2:Dot(eUp)
	if d2r > 4 then d2r = 4 elseif d2r < -4 then d2r = -4 end
	if d2u > 4 then d2u = 4 elseif d2u < -4 then d2u = -4 end
	position_difference23 = eRight * d2r + eUp * d2u

	table.CopyFromTo(view, oldview)

	position_difference3[1] = 0
	position_difference3[3] = 0
	position_difference3[2] = position_difference:Dot(eRight)

	hg.clamp(position_difference,  2)
	hg.clamp(position_difference3, 5)
	hg.clamp(angle_difference_localvec, 10)
	hg.clamp(angle_difference,  10)
	hg.clamp(angle_difference2, 10)

	if not hg.KeyDown(ply, IN_SPEED_K) then
		local ad21 = angle_difference2[1] * 0.05556
		local ad22 = angle_difference2[2] * 0.05556
		local ov1  = offsetView[1] - ad21
		local ov2  = offsetView[2] - ad22
		offsetView[1] = ov1 > 2 and 2 or (ov1 < -2 and -2 or ov1)
		offsetView[2] = ov2 > 4 and 4 or (ov2 < -4 and -4 or ov2)
	end

	offsetView    = LerpFT(0.001, offsetView, angleZero)
	eyeAnglesOld  = eyeAngs

	angles[3] = angles[3] - angle_difference[2] * 0.5 - (lean_lerp or 0) * hg_leancam_mul:GetInt()
end

CalcView = function(ply, origin, angles, fov, znear, zfar)
	if g_VR and g_VR.active then return end
	lply = IsValid(lply) and lply or LocalPlayer()
	local ave = GetViewEntity()
	if ave ~= (ply or lply) then return end

	local view = {
		origin=origin, angles=angles, fov=fov,
		znear=znear,   zfar=zfar,    drawviewer=false,
	}

	if drive.CalcView(ply, view) then return view end

	local rlEnt = hg.GetCurrentCharacter(ply)
	local pOrg  = ply.organism
	local fovSub = 0
	if pOrg then
		fovSub = (pOrg.immobilization or 0)*0.25
			- (pOrg.adrenaline or 0)*5
			- (pOrg.noradrenaline or 0)*15
	end

	local suicideSub = 0
	if ply.suiciding then
		local ct    = CurTime()
		local sTime = ply_GetNetVar(ply, "suicide_time", ct)
		if sTime < ct then
			local rem = sTime + 8 - ct
			suicideSub = (1 - (rem > 0 and rem or 0) * 0.125) * 20
		end
	end

	local sprintCond = 0
	if ply_IsSprinting(ply) and rlEnt == ply and ply_GetVelocity(rlEnt):LengthSqr() > 1500 then
		sprintCond = 10
	end

	lerpfovadd  = LerpFT(0.01,  lerpfovadd,  sprintCond - fovSub*0.5 - suicideSub)
	lerpfovadd2 = LerpFT(0.1,   lerpfovadd2, zooming and -25 or 0)
	fov         = hg_fov:GetInt()

	if not IsValid(ply) then return end

	local plyLean = lply.lean
	if plyLean and M.abs(plyLean) < 0.01 then
		oldlean = 0 ; lean_lerp = 0
	end

	local vp2    = GetViewPunchAngles2()
	local vp3    = GetViewPunchAngles3()
	local vpang  = vp2 + vp3
	vpang[3]     = 0

	if IsValid(follow) then
		return hg.CalcViewFake(ply, origin, angles, fov, znear, zfar)
	end
	ply.lockcamera = false

	if not ply_Alive(ply) and not follow then
		return hook_Run(STR_HGCALCVIEW, lply, origin, angles, fov, znear, zfar)
	end

	if not ply.LookupBone or not ply_LookupBone(ply, STR_HEAD) then return end
	if not ply.GetAimVector then return end

	local firstPerson = ave == lply
	local fova        = {0}
	hook_Run(STR_HGCALCVIEW, ply, origin, angles, fova, znear, zfar)
	if not firstPerson then return end

	local attIdx = ply_LookupAttachment(ply, STR_EYES)
	local att    = ply_GetAttachment(ply, attIdx)
	if not att then return end

	local tr, _, _ = hg.eyeTrace(ply, 10, ply, att.Ang)
	local eyePos   = tr.StartPos
	local inVeh    = ply_InVehicle(ply)
	local vehicle  = ply_GetVehicle(ply)
	local vehiclebase = ply.GetSimfphys and ply:GetSimfphys() or nil
	local BadSurf  = false

	local vel
	if ply_GetMoveType(ply) == MOVETYPE_NC then
		vel = vec_origin
	elseif inVeh then
		vel = -ply_GetVelocity(vehicle) * (1/550)
	else
		vel = -ply_GetVelocity(ply) * (1/200)
	end

	if IsValid(vehicle) then
		if IsValid(vehiclebase) then vehicle = vehiclebase end

		local vp = ply_GetPos(vehicle)
		traceVehicle.start[1]  = vp[1] ; traceVehicle.start[2]  = vp[2] ; traceVehicle.start[3]  = vp[3]
		traceVehicle.endpos[1] = vp[1] ; traceVehicle.endpos[2] = vp[2] ; traceVehicle.endpos[3] = vp[3]-75
		local trV = U.TraceLine(traceVehicle)
		if materialsWheelDrive[U.GetSurfacePropName(trV.SurfaceProps)] then
			BadSurf = true
			vel = -ply_GetVelocity(vehicle) * (1/(BadSurf and 150 or 550))
		end

		local angPunch = ply_GetAngles(vehicle)
		angPunch:Sub(oldVechicleAng)
		angPunch:Normalize()
		angPunch:Div(5)
		local PF = -angPunch
		ViewPunch2(PF) ; ViewPunch(PF)
		oldVechicleAng = ply_GetAngles(vehicle)
		vel = ply_GetVelocity(vehicle) * (1/(BadSurf and 350 or 550))
	end

	local velLen = vel:Length()
	ViewPunch(AngleRand(-1,1) * velLen * (1/(BadSurf and 5 or 50)))

	if inVeh or velLen > 2 then
		local add = (velLen + (inVeh and 0 or -2)) * (1/(inVeh and 50 or 10))
		eyePos:Add(VectorRand() * add)
	end

	hg.clamp(vel, limit)
	if inVeh then
		angles = ply_GetAimVector(ply):AngleEx(vehicle:GetUp())
	end

	hg.cam_things(ply, view, angles)

	if not RENDERSCENE then
		local HC = (zb and zb.OverrideCalcView) and zb.OverrideCalcView(ply, origin, angles, fov, znear, zfar)
		if HC ~= nil then return HC end
	end

	if hg_thirdperson:GetBool() then
		local insideScope = IsAimingNoScope(ply)
		local legacyOn    = hg_legacycam:GetBool()
		lerpaim  = LerpFT(0.1, lerpaim, (not insideScope) and 1 or (legacyOn and 1 or 0))
		local pLean  = ply.lean or 0
		local leanm1 = (pLean < 0 and pLean*2.2 or 0) + 1

		origin = origin + (angles:Forward()*-30 + angles:Right()*15*leanm1) * lerpaim
		view   = hook_Run(STR_CAMERA, ply, view.origin, view.angles, view, vec_origin) or view
		lerpasad = Lerp(0.1, lerpasad, (insideScope or legacyOn) and 0.001 or 1)

		local pos3 = hg.eye(ply, 10, follow)
		local ang3 = ply_EyeAngles(ply)
		local te   = pos3 - ang3:Forward()*60*lerpasad + ang3:Right()*15*lerpasad
		traceThird.start  = pos3
		traceThird.endpos = te
		traceThird.filter = {ply}
		local td = (te - pos3):GetNormalized()
		view.origin    = U.TraceLine(traceThird).HitPos + td*-5
		view.angles    = angles
		view.drawviewer = true
		view.fov       = 95 + lerpfovadd + lerpfovadd2
		return view
	end

	view.znear = 1
	view.zfar  = zfar
	view.fov   = M.Clamp(hg_fov:GetFloat(), 75, 100) + fova[1] + lerpfovadd + lerpfovadd2
	view.drawviewer = true
	view.origin = origin
	view.angles = angles

	result = hook_Run(STR_CAMERA, ply, eyePos, angles, view, velLen*200)
	view.origin, view.angles = HGAddView(ply, view.origin, view.angles, velLen)
	realangle = realangle or ply_EyeAngles(lply)

	if GetCoolCameraBool() then
		view.angles    = realangle + GetViewPunchAngles()*0.4 + vpang
		view.angles[3] = view.angles[3] - GetViewPunchAngles4()[3]
		angles         = view.angles
	end

	view.angles:RotateAroundAxis(view.angles:Up(),    -LookX)
	view.angles:RotateAroundAxis(view.angles:Right(),  -LookY)

	if hg_gopro:GetBool() then
		local vpa    = GetAllViewPunchAngles()
		local ag     = Angle(0, vpa[1], -vpa[2])
		local ct2    = CurTime()
		local sct2   = M.sin(ct2*2)
		local cct2   = M.cos(ct2)
		ag[2] = ag[2] + sct2 * cct2 * 2
		ag[1] = ag[1] + cct2 * M.sin(ct2*1.25) * 3
		hg.bone.Set(ply, STR_HEAD_BONE, vec_origin, ag, STR_GOPRO)
		return SpecCam(ply)
	end

	local vp4z = GetViewPunchAngles4()[3]

	if result == view then
		local trace = hg.hullCheck(ply_EyePos(ply) - vec_up*10, view.origin, ply)
		view.origin    = trace.HitPos
		view.angles:Add(-vpang)
		view.angles[3] = view.angles[3] + vp4z
		hook_Run(STR_POSTFIX, ply, view)
		return view
	end

	view.origin = eyePos
	view.angles = angles
	view.angles:Add(-vpang)
	view.angles[3] = view.angles[3] + vp4z

	local wep2 = ply_GetActiveWeapon(ply)
	if IsValid(wep2) and whitelist[wep2:GetClass()] then return end
	local r2 = hook_Run(STR_POSTPOSTFIX, ply, view)
	if r2 then return r2 end
	return view
end

hook_Remove(STR_CALCVIEW, "wac_air_calcview")
hook_Remove(STR_CREATEMOVE, "wac_cl_seatswitch_centerview")

concommand.Add("+hg_zoom",  function() zooming = true      end)
concommand.Add("-hg_zoom",  function() zooming = false     end)
concommand.Add("hg_zoom",   function() zooming = not zooming end)
concommand.Add("+altlook",  function() altlook = true      end)
concommand.Add("-altlook",  function() altlook = false     end)

hook_Add(STR_HG_INPUTMOUSEAPPLY, STR_FREEZETURNING, function(tbl)
	MaxLookX, MinLookX = hg.MaxLookX or MaxLookX, hg.MinLookX or MinLookX
	MaxLookY, MinLookY = hg.MaxLookY or MaxLookY, hg.MinLookY or MinLookY
	if not altlook then
		LookY = LerpFT(0.1, LookY, 0) ; if M.abs(LookY) <= 0.01 then LookY = 0 end
		LookX = LerpFT(0.1, LookX, 0) ; if M.abs(LookX) <= 0.01 then LookX = 0 end
	else
		lply = IsValid(lply) and lply or LocalPlayer()
		if ply_Alive(lply) then
			local dx, dy = tbl.x * 0.015, tbl.y * 0.015
			local nx = LookX + dx ; LookX = nx > MaxLookX and MaxLookX or (nx < MinLookX and MinLookX or nx)
			local ny = LookY + dy ; LookY = ny > MaxLookY and MaxLookY or (ny < MinLookY and MinLookY or ny)
			tbl.x = 0 ; tbl.y = 0
		end
	end
end)

hook_Add(STR_HG_INPUTMOUSEAPPLY, STR_ASDINVERT, function(tbl)
	if invertCam:GetBool() then tbl.x = -tbl.x end
end)

hook_Add(STR_CREATEMOVE, STR_FLIPMOVE, function(cmd)
	if invertCam:GetBool() then cmd:SetSideMove(-cmd:GetSideMove()) end
end)

hg.CalcView = CalcView
hook_Add(STR_CALCVIEW, STR_HOMIGRAD_VIEW, function(ply, origin, angles, fov, znear, zfar)
	local va = viewOverride ; viewOverride = nil
	return va or CalcView(ply, origin, angles, fov, znear, zfar)
end)

local function renderscene(pos, angle, fov)
	lply = IsValid(lply) and lply or LocalPlayer()
	pos   = ply_EyePos(lply)
	angle = ply_EyeAngles(lply)
	local view = CalcView(lply, pos, angle, fov)
	viewOverride = view
	local invert = invertCam:GetBool()
	RENDERSCENE   = nil
	if not view then return end

	local oldrt
	if invert then
		oldrt = R.GetRenderTarget()
		R.SetRenderTarget(fliprt)
	end

	renderView.fov     = fov
	renderView.origin  = view.origin
	renderView.angles  = view.angles
	if mapswithfog[map] then renderView.zfar = zfar_fog end

	lply.norender = true
	if isvector(view.origin) and isangle(view.angles) then
		R.RenderView(renderView)
	end
	lply.norender = nil

	if invert then
		R.SetRenderTarget(oldrt)
		fliprtmat:SetTexture("$basetexture", fliprt)
		R.SetMaterial(fliprtmat)
		R.DrawScreenQuad()
	end
	return true
end

hook_Add(STR_RENDERSCENE, STR_JOPA, renderscene)

N.Receive(STR_LOOKAWAY, function()
	local ply = N.ReadEntity()
	if not IsValid(ply) then return end
	local rX = N.ReadFloat()
	local rY = N.ReadFloat()
	ply.LookX1       = rX > MaxLookX and MaxLookX or (rX < MinLookX and MinLookX or rX)
	ply.LookY1       = rY > MaxLookY and MaxLookY or (rY < MinLookY and MinLookY or rY)
	ply.LastLookSend = CurTime()
end)

local angle_use = Angle(0,0,0)
hook_Add(STR_BONES, STR_HEADTURNAWAY, function(ply)
	local ct     = CurTime()
	lply         = IsValid(lply) and lply or LocalPlayer()
	local isLocal = ply == lply

	if isLocal and (ply.head_netsendtime or 0) < ct
		and (hg.IsChanged(LookX,"LookX") or hg.IsChanged(LookY,"LookY")) then
		ply.head_netsendtime = ct + 0.1
		N.Start(STR_LOOKAWAY, true)
			N.WriteFloat(LookX)
			N.WriteFloat(LookY)
		N.SendToServer()
	end

	if not isLocal and ((ply.LastLookSend or 0)+1) < ct then
		ply.LookX = nil ; ply.LookY = nil
	end

	local tX = isLocal and LookX or (ply.LookX1 or 0)
	local tY = isLocal and LookY or (ply.LookY1 or 0)
	ply.LookX = Lerp(0.1, ply.LookX or 0, tX)
	ply.LookY = Lerp(0.1, ply.LookY or 0, tY)

	angle_use[2] = -(ply.LookY or 0) * 0.6
	angle_use[3] = -(ply.LookX or 0) * 0.6

	if not angle_use:IsEqualTol(angle_zero, 0.01) then
		hg.bone.Set(ply, STR_HEAD_BONE, vec_origin, angle_use, STR_HEADTURN)
	end
end)

local function DrawFog()
	local mapFog = mapswithfog[map]
	if not mapFog then return end

	local view   = R.GetViewSetup()
	local pos    = view.origin
	local ct     = CurTime()

	if ct >= fogSkyboxNext then
		fogSkyboxNext = ct + 0.25
		fogSkyboxVis  = U.IsSkyboxVisible(pos)
	end

	local target = fogSkyboxVis and mapFog or 15000
	zfar_fog     = LerpFT(0.005, zfar_fog, target)

	if M.abs(zfar_fog - fogRadiiZfar) > 1 then
		fogRadiiZfar = zfar_fog
		fogBaseZFar  = zfar_fog - mapFog * 0.4
		local step   = fogN
		for i = 1, fogN do
			fogSphereRadii[i] = -(fogBaseZFar + (i-1)*step)
		end
	end

	R.SetColorMaterial()
	local r = fogSphereRadii
	local c = fogSphereColors
	for i = 1, fogN do
		R.DrawSphere(pos, r[i], 15, 15, c[i])
	end
end

hook_Add(STR_PREDRAWTRANSLUCENTRENDERABLES, STR_FPS_FOG, DrawFog)