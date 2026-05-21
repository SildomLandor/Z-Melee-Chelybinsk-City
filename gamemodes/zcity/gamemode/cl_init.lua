zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode = nil,nil,1
local hullscale = Vector(0,0,0)
net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)

	timer.Simple(0.1,function()
		-- LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
		end
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	// old blur
	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	--surface.SetMaterial(blur2)
	--surface.SetDrawColor(color_white)
	--local x, y = panel:LocalToScreen(0, 0)
--
	--// those are currently hardcoded cuz it would be too much of a hassle to change this
	--blur2:SetFloat("$c0_x", (amount or 5) * 2500) // density
	--blur2:SetFloat("$c0_y", (passes or 0.2) * 2000) // noise (inverted)
	--blur2:SetFloat("$c0_z", 1) // blending
--
	--render.UpdateScreenEffectTexture()
	--surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())

	-- surface.SetDrawColor(0, 0, 0, alpha or 125)
	-- surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local spect = lply:GetNWEntity("spect",spect)
		if not IsValid(spect) then return end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			return
		else
			lply:SetPos(spect:GetPos())
		end
		
		local ent = hg.GetCurrentCharacter(spect)
		if not IsValid(ent) then return end
		
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		local bon = ent:GetBoneMatrix(headBone)
		
		if not bon then 
			local eyePos = ent:EyePos()
			if eyePos and eyePos ~= vector_origin then
				pos = eyePos
				ang = ent:EyeAngles()
			else
				pos = ent:GetPos() + Vector(0, 0, 64)
				ang = ent:GetAngles()
			end
		else
			pos, ang = bon:GetTranslation(), bon:GetAngles()
		end

		local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()
		
		local tr = {}
		tr.start = pos
		tr.endpos = pos + eyeAng:Forward() * -120
		tr.filter = {ent, lply, spect}
		tr.mins = Vector(-4, -4, -4)
		tr.maxs = Vector(4, 4, 4)
		tr = util.TraceHull(tr)

		if viewmode == 2 then
			pos = tr.HitPos + eyeAng:Forward() * 8
			ang = eyeAng
		elseif viewmode == 1 then
			if ent ~= spect and IsValid(ent) then
				local eyeAtt = ent:GetAttachment(ent:LookupAttachment("eyes"))
				if eyeAtt then
					ang = eyeAtt.Ang
				else
					ang = spect:EyeAngles()
				end
			else
				ang = spect:EyeAngles()
			end
			pos = pos + spect:EyeAngles():Forward() * 8
		else
			pos = eyePos
			ang = eyeAng
		end
		
		ang[3] = 0
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() and zb.ROUND_STATE == 3 then
			if CurrentRound().EndRound then
				CurrentRound():EndRound()
			end
		elseif zb.ROUND_STATE == 1 then
			if CurrentRound().RoundStart then
				CurrentRound():RoundStart()
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true
})

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end

	//PrintTable(hg.playerInfo)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local ply = Player(data.userid)
	if IsValid(ply) and ply.SetMuted and hg.playerInfo and hg.playerInfo[data.networkid] then
		ply:SetMuted(hg.playerInfo[data.networkid][1])
		ply:SetVoiceVolumeScale(hg.playerInfo[data.networkid][2])
	end
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end//compatibility with old json

				if hg.playerInfo[ply:SteamID()] then
					ply:SetMuted(hg.playerInfo[ply:SteamID()][1])
					ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
				end
			end	
		end
	end
end)

local colGray = Color(122,122,122,255)
local colBlue = Color(130,10,10)
local colBlueUp = Color(160,30,30)
local col = Color(255,255,255,255)

local colSpect1 = Color(75,75,75,255)
local colSpect2 = Color(85,85,85,255)

local colorBG = Color(55,55,55,255)
local colorBGBlacky = Color(40,40,40,255)

hg.muteall = false
hg.mutespect = false

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if hg.muteall || hg.mutespect then return end
		
		self:SetChecked(not ply:IsMuted())
		ply:SetMuted( not ply:IsMuted() )
		selfa:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end ) -- get your stupid one line ass outta here

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 255, 0, 0 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end

local function GetVoiceIconPath(ply)
	return ply:IsMuted() and "icon16/sound_mute.png" or "icon16/sound.png"
end

local function SetSoundButtonIcon(button, ply)
	if not IsValid(button) or not IsValid(ply) then return end
	local icon = GetVoiceIconPath(ply)
	if button.SetImage then
		button:SetImage(icon)
		return
	end
	if button.SetIcon then
		button:SetIcon(icon)
		return
	end
	if button.SetMaterial then
		button:SetMaterial(Material(icon))
	end
end

local function OpenPlayerSoundSettings(selfa, ply)
	local Menu = DermaMenu()
	
	if not hg.playerInfo[ply:SteamID()] or not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption( "Mute", function(self)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect and not ply:Alive()) then return end
		
		local muted = not ply:IsMuted()
		ply:SetMuted(muted)
		self:SetChecked(muted)
		SetSoundButtonIcon(selfa, ply)
		addToPlayerInfo(ply, muted, hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1)
	end ) -- get your stupid one line ass outta here

	mute:SetIsCheckable( true )
	mute:SetChecked( ply:IsMuted() )
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY( 0.5 )
	volumeSlider:SetTrapInside( true )
	volumeSlider:SetSlideX(hg.playerInfo[ply:SteamID()][2]) 
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect && !ply:Alive()) then return end
		hg.playerInfo[ply:SteamID()][2] = x
		ply:SetVoiceVolumeScale(hg.playerInfo[ply:SteamID()][2])
		addToPlayerInfo(ply, ply:IsMuted(), hg.playerInfo[ply:SteamID()][2])
	end

	function volumeSlider:Paint(w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0 ) )
		draw.RoundedBox( 0, 0, 0, w*self:GetSlideX(), h, Color( 255, 0, 0 ) )
		draw.DrawText( ( math.Round( 100*self:GetSlideX(), 0 ) ).."%", "DermaDefault", w/2, h/4, color_white, TEXT_ALIGN_CENTER )
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end

hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end

	//ply:SetMuted(ply.oldmutedspect)
	ply:SetVoiceVolumeScale(!hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)
	//ply.oldmutedspect = nil

	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end

	//ply.oldmutedspect = ply:IsMuted()
	//ply:SetMuted(hg.mutespect)
	ply:SetVoiceVolumeScale(0)
	//if IsValid(ply.soundButton) then
		//ply.soundButton:SetImage(not ply:IsMuted() && "icon16/sound.png" || "icon16/sound_mute.png")
	//end
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
	Dynamic = 0

	local col = {
		frameBG        = Color(10, 10, 19, 235),
		frameBorder    = Color(90, 90, 95, 120),
		panelBG        = Color(8, 8, 16, 245),
		panelBorder    = Color(255, 255, 255, 25),
		headerBG       = Color(6, 6, 14, 250),
		headerBorder   = Color(255, 255, 255, 18),
		headerHover    = Color(255, 255, 255, 12),
		headerText     = Color(200, 200, 200, 180),
		rowBG          = Color(255, 255, 255, 0),
		rowAlt         = Color(255, 255, 255, 4),
		rowHover       = Color(255, 255, 255, 15),
		rowSelected    = Color(255, 255, 255, 22),
		rowBorder      = Color(255, 255, 255, 8),
		rowAlive       = Color(200, 200, 200, 255),
		rowDead        = Color(160, 35, 35, 255),
		text           = Color(200, 200, 200, 255),
		textDim        = Color(160, 160, 165, 180),
		textMuted      = Color(100, 100, 108, 140),
		textBlood      = Color(180, 40, 35, 255),
		textTitle      = Color(200, 200, 200, 255),
		accent         = Color(200, 200, 200, 60),
		accentDim      = Color(255, 255, 255, 15),
		separator      = Color(255, 255, 255, 12),
		scrollTrack    = Color(255, 255, 255, 6),
		scrollGrip     = Color(200, 200, 200, 60),
		scrollGripHov  = Color(200, 200, 200, 100),
		btnBG          = Color(0, 0, 0, 0),
		btnBorder      = Color(255, 255, 255, 25),
		btnHover       = Color(255, 255, 255, 15),
		btnActive      = Color(200, 200, 200, 80),
		btnInactive    = Color(160, 35, 35, 80),
	}

	local NoiseMat = Material("vgui/noisevhs")
	if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

	local sizeX = math.floor(ScrW() * 0.74)
	local sizeY = math.floor(ScrH() * 0.82)
	local leaderboardOffsetY = ScreenScaleH(14)
	local posX = math.floor(ScrW() * 0.5 - sizeX * 0.5)
	local posY = math.floor(ScrH() * 0.5 - sizeY * 0.5 + leaderboardOffsetY)

	local margin = ScreenScale(5)
	local topBarH = ScreenScaleH(38)
	local columnHeaderH = ScreenScaleH(16)
	local sectionLabelH = ScreenScaleH(18)
	local bottomBarH = ScreenScaleH(26)
	local panelGap = ScreenScale(4)

	local leftPanelX = margin
	local leftPanelW = math.floor((sizeX - margin * 2 - panelGap) * 0.64)
	local rightPanelX = leftPanelX + leftPanelW + panelGap
	local rightPanelW = sizeX - rightPanelX - margin

	local listTopY = topBarH + sectionLabelH + columnHeaderH
	local listH = sizeY - listTopY - bottomBarH - ScreenScaleH(4)
	local rowH = ScreenScaleH(24)

	scoreBoardMenu = vgui.Create("ZFrame")
	scoreBoardMenu:SetPos(posX, posY)
	scoreBoardMenu:SetSize(sizeX, sizeY)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled(false)
	scoreBoardMenu:ShowCloseButton(false)
	scoreBoardMenu:SetColorBG(col.frameBG)
	scoreBoardMenu:SetColorBR(col.frameBorder)
	scoreBoardMenu:SetAlpha(0)
	scoreBoardMenu:AlphaTo(255, 0.15, 0)

	local lastHash = ""
	local selectedSteamID = nil
	local tick = 0
	local openTime = CurTime()

	local shakeX, shakeY = 0, 0
	local targetShakeX, targetShakeY = 0, 0
	local nextShakeSample = 0
	local shakeStrength = 0.6

	local bloodDrips = {}
	for i = 1, math.random(6, 10) do
		bloodDrips[i] = {
			x = math.random(0, sizeX),
			w = math.random(1, 2),
			h = math.random(ScreenScaleH(10), ScreenScaleH(45)),
			alpha = math.random(8, 30),
			speed = math.Rand(0.15, 0.6),
			offset = math.Rand(0, math.pi * 2),
		}
	end

	local titleFont = "ZC_MM_Title"
	local titleText = "Челябинск"
	surface.SetFont(titleFont)
	local titleW, titleH = surface.GetTextSize(titleText)
	local titleColor = Color(140, 15, 12, 255)
	local titleColorDark = Color(90, 8, 6, 255)
	local titleShadowColor = Color(40, 4, 2, 200)

	local titleCharPositions = {}
	do
		surface.SetFont(titleFont)
		local accW = 0
		local i = 1
		for _, code in utf8.codes(titleText) do
			local ch = utf8.char(code)
			local chW = surface.GetTextSize(ch)
			titleCharPositions[i] = {
				x = accW,
				w = chW,
				cx = accW + chW * 0.5
			}
			accW = accW + chW
			i = i + 1
		end
	end

	local dripChars = {
		{ char = 1, xfrac = 0.85, delay = 1.5 },
		{ char = 3, xfrac = 0.5, delay = 0.8 },
		{ char = 4, xfrac = 0.1, delay = 2.2 },
		{ char = 5, xfrac = 0.9, delay = 0.3 },
		{ char = 6, xfrac = 0.5, delay = 3.0 },
		{ char = 7, xfrac = 0.15, delay = 1.1 },
		{ char = 7, xfrac = 0.85, delay = 4.0 },
	}

	local titleDrips = {}
	for _, src in ipairs(dripChars) do
		local charInfo = titleCharPositions[src.char]
		if not charInfo then continue end
		local dripX = charInfo.x + charInfo.w * src.xfrac
		local drip = {
			localX = dripX,
			width = math.Rand(1.5, 3.5),
			maxLength = math.Rand(ScreenScaleH(20), ScreenScaleH(80)),
			speed = math.Rand(8, 25),
			delay = src.delay,
			currentLength = 0,
			started = false,
			dropSize = math.Rand(2, 4.5),
			dropSpeed = math.Rand(15, 40),
			dropFallen = false,
			dropY = 0,
			dropAlpha = 255,
			alpha = math.random(160, 240),
			wobble = math.Rand(0, math.pi * 2),
			branches = {},
		}
		if math.random() > 0.5 then
			for b = 1, math.random(1, 2) do
				table.insert(drip.branches, {
					startFrac = math.Rand(0.2, 0.7),
					angle = math.Rand(-0.4, 0.4),
					length = math.Rand(ScreenScaleH(5), ScreenScaleH(20)),
					width = math.Rand(0.8, 1.5),
					alpha = math.random(80, 160),
				})
			end
		end
		table.insert(titleDrips, drip)
	end

	local titleBloodSpots = {}
	for i = 1, math.random(3, 6) do
		table.insert(titleBloodSpots, {
			x = math.Rand(-titleW * 0.05, titleW * 1.05),
			y = math.Rand(-titleH * 0.3, titleH * 0.3),
			size = math.Rand(2, 6),
			alpha = math.random(20, 60),
		})
	end

	local titleStartTime = CurTime()

	local function PaintBloodyTitle(w, h)
		local t = CurTime()
		local age = t - titleStartTime

		DisableClipping(true)

		local baseX = w * 0.5 - titleW * 0.5 + shakeX * 1.5
		local baseY = -ScreenScaleH(33) - leaderboardOffsetY + shakeY * 1.5

		for _, drip in ipairs(titleDrips) do
			if age < drip.delay then continue end
			drip.started = true
			local dripAge = age - drip.delay
			local dripX = baseX + drip.localX + 25
			local dripStartY = baseY + titleH - ScreenScaleH(10)

			if drip.currentLength < drip.maxLength then
				drip.currentLength = math.min(drip.currentLength + drip.speed * FrameTime(), drip.maxLength)
			end

			local len = drip.currentLength
			if len <= 0 then continue end

			local wobbleX = math.sin(t * 0.8 + drip.wobble) * 0.5
			local segments = math.max(math.floor(len / 3), 1)

			for s = 0, segments do
				local frac = s / segments
				local sy = dripStartY + len * frac
				local segAlpha = drip.alpha * (1 - frac * 0.6)
				local segWidth = drip.width * (1 - frac * 0.3)
				local r = Lerp(frac, 140, 70)
				local g = Lerp(frac, 15, 5)
				local b = Lerp(frac, 12, 4)
				surface.SetDrawColor(r, g, b, segAlpha)
				surface.DrawRect(dripX - segWidth * 0.5 + wobbleX * frac, sy, segWidth, 3)
			end

			local bulgeW = drip.width * 1.8
			local bulgeH = math.min(4, len * 0.3)
			surface.SetDrawColor(140, 18, 14, drip.alpha * 0.8)
			surface.DrawRect(dripX - bulgeW * 0.5, dripStartY - 1, bulgeW, bulgeH)


			if drip.dropFallen then
				drip.dropY = drip.dropY + drip.dropSpeed * FrameTime()
				drip.dropAlpha = math.max(drip.dropAlpha - 80 * FrameTime(), 0)
				if drip.dropAlpha > 0 then
					local ds = drip.dropSize * 0.8
					surface.SetDrawColor(120, 10, 8, drip.dropAlpha)
					for dy = -ds, ds, 0.5 do
						local radius = math.sqrt(math.max(ds * ds - dy * dy, 0)) * 0.6
						surface.DrawRect(dripX - radius + wobbleX, drip.dropY + dy * 1.5, radius * 2, 1)
					end
				end
				if drip.dropAlpha <= 0 then
					drip.dropFallen = false
					drip.dropAlpha = 255
					drip.dropY = 0
					drip.currentLength = drip.maxLength * math.Rand(0.7, 0.95)
					drip.delay = age + math.Rand(3, 8)
				end
			end

			for _, branch in ipairs(drip.branches) do
				local branchStartY = dripStartY + len * branch.startFrac
				if drip.currentLength < drip.maxLength * branch.startFrac then continue end
				local branchLen = branch.length * math.min((drip.currentLength - drip.maxLength * branch.startFrac) / (drip.maxLength * 0.3), 1)
				for bs = 0, math.floor(branchLen / 2) do
					local bfrac = bs / math.max(math.floor(branchLen / 2), 1)
					local bx = dripX + branch.angle * branchLen * bfrac + wobbleX * 0.5
					local by = branchStartY + branchLen * bfrac
					local ba = branch.alpha * (1 - bfrac * 0.7)
					surface.SetDrawColor(100, 10, 8, ba)
					surface.DrawRect(bx - branch.width * 0.5, by, branch.width, 2)
				end
			end
		end

		for _, spot in ipairs(titleBloodSpots) do
			surface.SetDrawColor(120, 12, 10, spot.alpha)
			local s = spot.size
			for dy = -s, s, 0.8 do
				local radius = math.sqrt(math.max(s * s - dy * dy, 0))
				radius = radius * (0.85 + math.sin(dy * 2.5) * 0.15)
				surface.DrawRect(baseX + spot.x - radius, baseY + titleH * 0.5 + spot.y + dy, radius * 2, 1)
			end
		end

		surface.SetFont(titleFont)
		surface.SetTextColor(titleShadowColor)
		surface.SetTextPos(baseX + 3, baseY + 3)
		surface.DrawText(titleText)

		surface.SetTextColor(titleColorDark)
		surface.SetTextPos(baseX + 1, baseY + 1)
		surface.DrawText(titleText)

		local pulse = math.sin(t * 1.5) * 0.15 + 0.85
		surface.SetTextColor(titleColor.r * pulse, titleColor.g * pulse, titleColor.b * pulse, 255)
		surface.SetTextPos(baseX, baseY)
		surface.DrawText(titleText)

		local glossAlpha = (math.sin(t * 0.7) * 0.3 + 0.7) * 35
		surface.SetTextColor(255, 80, 60, glossAlpha)
		surface.SetTextPos(baseX, baseY - 1)
		surface.DrawText(titleText)

		if math.random() > 0.97 then
			surface.SetTextColor(180, 20, 15, math.random(20, 50))
			surface.SetTextPos(baseX + math.random(-4, 4), baseY + math.random(-2, 2))
			surface.DrawText(titleText)
		end

		if math.random() > 0.92 then
			surface.SetTextColor(200, 0, 0, 15)
			surface.SetTextPos(baseX + 2, baseY)
			surface.DrawText(titleText)
		end

		DisableClipping(false)
	end

	local function FitText(font, text, maxW)
		if not text or maxW <= 0 then return "" end
		surface.SetFont(font)
		if surface.GetTextSize(text) <= maxW then return text end
		local dots = "..."
		local dotsW = surface.GetTextSize(dots)
		if dotsW >= maxW then return "" end
		local lo, hi = 0, #text
		while lo < hi do
			local mid = math.floor((lo + hi + 1) * 0.5)
			if surface.GetTextSize(string.sub(text, 1, mid) .. dots) <= maxW then
				lo = mid
			else
				hi = mid - 1
			end
		end
		return string.sub(text, 1, lo) .. dots
	end

	local function StyleScrollbar(sbar)
		if not IsValid(sbar) then return end
		sbar:SetHideButtons(true)
		sbar.Paint = function(_, sw, sh)
			surface.SetDrawColor(col.scrollTrack)
			surface.DrawRect(0, 0, sw, sh)
		end
		sbar.btnGrip.Paint = function(self, sw, sh)
			local c = self:IsHovered() and col.scrollGripHov or col.scrollGrip
			surface.SetDrawColor(c)
			surface.DrawRect(2, 0, sw - 4, sh)
		end
	end

	local function PlayersHash()
		local parts = {}
		for _, ply in player.Iterator() do
			parts[#parts + 1] = ply:SteamID() .. ply:Team() .. tostring(ply:Alive()) .. ply:Frags() .. ply:Ping()
		end
		return table.concat(parts, "|")
	end

	local disappearance = lply:GetNetVar("disappearance", nil)

	scoreBoardMenu.Think = function(self)
		local t = CurTime()
		if t >= nextShakeSample then
			nextShakeSample = t + 0.035
			targetShakeX = math.Rand(-shakeStrength, shakeStrength)
			targetShakeY = math.Rand(-shakeStrength * 0.6, shakeStrength * 0.6)
		end
		local lerpRate = math.Clamp(FrameTime() * 22, 0, 1)
		shakeX = Lerp(lerpRate, shakeX, targetShakeX)
		shakeY = Lerp(lerpRate, shakeY, targetShakeY)

		if t >= (self.nextRefresh or 0) then
			self.nextRefresh = t + 0.5
			local newHash = PlayersHash()
			if newHash ~= lastHash then
				lastHash = newHash
				self:RebuildRows()
			end
		end
	end

	scoreBoardMenu.PaintOver = function(self, w, h)
		local t = CurTime()

		if not NoiseMat:IsError() then
			surface.SetMaterial(NoiseMat)
			surface.SetDrawColor(255, 255, 255, 6)
			local noiseOffX = math.random(0, 512)
			local noiseOffY = math.random(0, 512)
			surface.DrawTexturedRectUV(0, 0, w, h, noiseOffX / 512, noiseOffY / 512, noiseOffX / 512 + w / 768, noiseOffY / 512 + h / 768)
		end

		for y = 0, h, 3 do
			surface.SetDrawColor(0, 0, 0, 12)
			surface.DrawRect(0, y, w, 1)
		end

		for _, drip in ipairs(bloodDrips) do
			local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
			local a = math.floor(drip.alpha * pulse)
			surface.SetDrawColor(100, 15, 12, a)
			surface.DrawRect(drip.x + shakeX, 0, drip.w, drip.h)
		end

		surface.SetDrawColor(col.frameBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		PaintBloodyTitle(w, h)

		surface.SetDrawColor(col.separator)
		surface.DrawRect(margin, topBarH - 1, w - margin * 2, 1)

		surface.SetFont("ZCity_Veteran")
		surface.SetTextColor(col.textTitle)
		local srvX = margin + ScreenScale(2)
		local srvY = ScreenScaleH(5) + shakeY * 0.5
		surface.SetTextPos(srvX + shakeX * 0.5, srvY)
		surface.DrawText("meleecity")

		surface.SetFont("ZB_InterfaceSmall")
		surface.SetTextColor(col.textMuted)
		local subY = srvY + ScreenScaleH(13)
		surface.SetTextPos(srvX + shakeX * 0.3, subY)
		surface.DrawText(hg.Version .. " | " .. (game.GetMap() or "unknown"))

		tick = math.Round(LerpFT(0.1, tick, 1 / engine.ServerFrameTime()))
		surface.SetFont("ZCity_Veteran")
		local tickText = tick .. " tick"
		local tickTW = surface.GetTextSize(tickText)
		local tickCol = tick >= 60 and col.textDim or (tick >= 30 and Color(220, 180, 60, 200) or col.textBlood)
		surface.SetTextColor(tickCol)
		surface.SetTextPos(w - margin - tickTW - ScreenScale(2) + shakeX - 50, srvY)
		surface.DrawText(tickText)

		karma = 0
		surface.SetFont("ZCity_Veteran")
		karmtxt = 'Карма: ' .. karma
		local karmCol = col.textBlood
		surface.SetTextColor(karmCol)
		surface.SetTextPos(w - margin - tickTW - ScreenScale(2) + shakeX * 0.5, srvY)
		surface.DrawText(karmtxt)

		local totalPlayers = #player.GetAll()
		local maxPlayers = game.MaxPlayers()
		local countText = totalPlayers .. "/" .. maxPlayers
		surface.SetFont("ZB_InterfaceSmall")
		local countW = surface.GetTextSize(countText)
		surface.SetTextColor(col.textMuted)
		surface.SetTextPos(w - margin - countW - ScreenScale(2) + shakeX * 0.3, subY)
		surface.DrawText(countText)

		local sectionY = topBarH + ScreenScaleH(1)
		local labelShakeX = math.sin(t * 28 + 1) * shakeStrength * 0.3
		local labelShakeY = math.cos(t * 24 + 1) * shakeStrength * 0.25

		surface.SetFont("ZCity_Veteran")
		surface.SetTextColor(col.textTitle)
		surface.SetTextPos(leftPanelX + ScreenScale(3) + labelShakeX, sectionY - 3 + labelShakeY)
		surface.DrawText("ИСПЫТУЕМЫЕ")

		local activeCount = 0
		local specCount = 0
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then
				specCount = specCount + 1
			else
				activeCount = activeCount + 1
			end
		end

		surface.SetFont("ZCity_Veteran")
		local ispW = surface.GetTextSize("ИСПЫТУЕМЫЕ")
		surface.SetFont("ZB_InterfaceSmall")
		surface.SetTextColor(col.textMuted)
		surface.SetTextPos(leftPanelX + ScreenScale(3) + ispW + 4 + labelShakeX, sectionY + 1 + labelShakeY)
		surface.DrawText(" [" .. activeCount .. "]")

		local labelShakeX2 = math.sin(t * 28 + 3) * shakeStrength * 0.3
		local labelShakeY2 = math.cos(t * 24 + 3) * shakeStrength * 0.25

		surface.SetFont("ZCity_Veteran")
		local specLabel = "НАБЛЮДАТЕЛИ"
		local specLW = surface.GetTextSize(specLabel)
		surface.SetTextColor(col.textDim)
		surface.SetTextPos(rightPanelX + rightPanelW - specLW - ScreenScale(3) + labelShakeX2, sectionY - 3 + labelShakeY2)
		surface.DrawText(specLabel)

		surface.SetFont("ZB_InterfaceSmall")
		surface.SetTextColor(col.textMuted)
		surface.SetTextPos(rightPanelX + rightPanelW + 4 - ScreenScale(3) + labelShakeX2, sectionY + 1 + labelShakeY2)
		surface.DrawText(" [" .. specCount .. "]")

		local sepY = sectionY + sectionLabelH - 2
		surface.SetDrawColor(col.accent)
		surface.DrawRect(leftPanelX, sepY, leftPanelW, 1)
		surface.SetDrawColor(col.accentDim)
		surface.DrawRect(rightPanelX, sepY, rightPanelW, 1)

		if math.random() > 0.985 then
			local glitchY = math.random(0, h)
			local glitchH = math.random(1, 3)
			surface.SetDrawColor(255, 255, 255, math.random(5, 18))
			surface.DrawRect(0, glitchY, w, glitchH)
		end
	end

	local playerSort = { key = "frags", desc = true }
	local spectatorSort = { key = "name", desc = false }

	local function SortPlayers(list, sortState)
		table.sort(list, function(a, b)
			local av, bv
			if sortState.key == "name" then
				av = string.lower(a:Name() or "")
				bv = string.lower(b:Name() or "")
			elseif sortState.key == "ping" then
				av = a:Ping()
				bv = b:Ping()
			elseif sortState.key == "xp" then
				av = math.floor(a.exp or 0)
				bv = math.floor(b.exp or 0)
			else
				av = a:Frags()
				bv = b:Frags()
			end
			if av == bv then return a:UserID() < b:UserID() end
			return sortState.desc and av > bv or av < bv
		end)
	end

	local function CreateColumnHeader(px, py, pw, columns, sortState, onSort)
		local header = vgui.Create("DPanel", scoreBoardMenu)
		header:SetPos(px, py)
		header:SetSize(pw, columnHeaderH)
		header:SetZPos(100)
		header.Paint = function(_, hw, hh)
			surface.SetDrawColor(col.headerBG)
			surface.DrawRect(0, 0, hw, hh)
			surface.SetDrawColor(col.headerBorder)
			surface.DrawRect(0, hh - 1, hw, 1)
		end
		local curX = 0
		for idx, c in ipairs(columns) do
			local colW = math.floor(pw * c.frac)
			local btn = vgui.Create("DButton", header)
			btn:SetPos(curX, 0)
			btn:SetSize(colW, columnHeaderH)
			btn:SetText("")
			btn:SetCursor("hand")
			local capturedIdx = idx
			btn.Paint = function(self, bw, bh)
				if self:IsHovered() then
					surface.SetDrawColor(col.headerHover)
					surface.DrawRect(0, 0, bw, bh)
				end
				local arrow = ""
				if sortState.key == c.key then
					arrow = sortState.desc and " ▼" or " ▲"
				end
				local align = c.align or TEXT_ALIGN_LEFT
				local tx = align == TEXT_ALIGN_CENTER and bw * 0.5 or (align == TEXT_ALIGN_RIGHT and bw - 6 or 6)
				draw.SimpleText(c.label .. arrow, "ZB_InterfaceSmall", tx, bh * 0.5, col.headerText, align, TEXT_ALIGN_CENTER)
				if capturedIdx > 1 then
					surface.SetDrawColor(col.separator)
					surface.DrawRect(0, 3, 1, bh - 6)
				end
			end
			btn.DoClick = function()
				if sortState.key == c.key then
					sortState.desc = not sortState.desc
				else
					sortState.key = c.key
					sortState.desc = c.defaultDesc or false
				end
				onSort()
			end
			curX = curX + colW
		end
		return header
	end

	local function CreateListPanel(x, y, w, h)
		local pnl = vgui.Create("DScrollPanel", scoreBoardMenu)
		pnl:SetPos(x, y)
		pnl:SetSize(w, h)
		pnl.Paint = function(_, pw, ph)
			surface.SetDrawColor(col.panelBG)
			surface.DrawRect(0, 0, pw, ph)
			surface.SetDrawColor(col.panelBorder)
			surface.DrawOutlinedRect(0, 0, pw, ph, 1)
		end
		StyleScrollbar(pnl:GetVBar())
		return pnl
	end

	local playerListPanel = CreateListPanel(leftPanelX, listTopY, leftPanelW, listH)
	local spectatorListPanel = CreateListPanel(rightPanelX, listTopY, rightPanelW, listH)

	local playerColumns = {
		{ key = "name",  label = "Имя",      frac = 0.50, align = TEXT_ALIGN_LEFT },
		{ key = "frags", label = "Убийства", frac = 0.16, align = TEXT_ALIGN_CENTER, defaultDesc = true },
		{ key = "xp",   label = "XP",       frac = 0.14, align = TEXT_ALIGN_CENTER, defaultDesc = true },
		{ key = "ping", label = "Пинг",     frac = 0.10, align = TEXT_ALIGN_CENTER },
	}

	local spectatorColumns = {
		{ key = "name", label = "Имя",  frac = 0.65, align = TEXT_ALIGN_LEFT },
		{ key = "ping", label = "Пинг", frac = 0.20, align = TEXT_ALIGN_CENTER },
	}

	local function RebuildRows() end

	local colHeaderY = topBarH + sectionLabelH
	CreateColumnHeader(leftPanelX, colHeaderY, leftPanelW, playerColumns, playerSort, function() RebuildRows() end)
	CreateColumnHeader(rightPanelX, colHeaderY, rightPanelW, spectatorColumns, spectatorSort, function() RebuildRows() end)

	local function AddPlayerRow(parent, ply, rowIndex, isSpectator)
		local row = vgui.Create("DButton", parent)
		row:SetTall(rowH)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, 0)
		row:SetText("")
		row:SetCursor("hand")

		local avatarSize = rowH - 6
		local avatar = vgui.Create("AvatarImage", row)
		avatar:SetMouseInputEnabled(false)

		local soundButton = vgui.Create("DImageButton", row)
		soundButton:Dock(RIGHT)
		soundButton:SetWide(ScreenScale(10))
		soundButton:DockMargin(4, 4, 6, 4)
		SetSoundButtonIcon(soundButton, ply)
		soundButton.DoClick = function(self)
			OpenPlayerSoundSettings(self, ply)
		end
		ply.soundButton = soundButton

		local rowWaveOffset = rowIndex * 0.75

		row.Paint = function(self, rw, rh)
			if not IsValid(ply) then return end
			local t = CurTime()
			local waveX = math.sin(t * 28 + rowWaveOffset) * shakeStrength * 0.25
			local waveY = math.cos(t * 24 + rowWaveOffset) * shakeStrength * 0.2

			if rowIndex % 2 == 0 then
				surface.SetDrawColor(col.rowAlt)
				surface.DrawRect(0, 0, rw, rh)
			end

			if selectedSteamID == ply:SteamID() then
				surface.SetDrawColor(col.rowSelected)
				surface.DrawRect(0, 0, rw, rh)
			elseif self:IsHovered() then
				surface.SetDrawColor(col.rowHover)
				surface.DrawRect(0, 0, rw, rh)
				surface.SetDrawColor(col.accent)
				surface.DrawRect(0, rh - 1, rw, 1)
			end

			if not isSpectator then
				local statusCol = ply:Alive() and col.rowAlive or col.rowDead
				surface.SetDrawColor(statusCol.r, statusCol.g, statusCol.b, 120)
				surface.DrawRect(0, 2, 2, rh - 4)
			end

			surface.SetDrawColor(col.rowBorder)
			surface.DrawRect(0, rh - 1, rw, 1)

			local avatarX = 6
			local nameX = avatarX + avatarSize + 8

			avatar:SetPos(avatarX + waveX, 3 + waveY)
			avatar:SetSize(avatarSize, avatarSize)
			avatar:SetPlayer(ply, 32)

			if isSpectator then
				local nameW = math.floor(rw * 0.65) - nameX
				local pingX = math.floor(rw * 0.65)
				local pingW = math.floor(rw * 0.20)
				local displayName = ply:Name() or "Unknown"
				local fitted = FitText("ZCity_Veteran", displayName, nameW - 8)
				draw.SimpleText(fitted, "ZCity_Veteran", nameX + waveX, rh * 0.5 + waveY, col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(tostring(ply:Ping()) .. "ms", "ZCity_Veteran", pingX + pingW * 0.5 + waveX, rh * 0.5 + waveY, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				local nameW = math.floor(rw * 0.50) - nameX
				local fragsX = math.floor(rw * 0.50)
				local fragsW = math.floor(rw * 0.16)
				local xpX = fragsX + fragsW
				local xpW = math.floor(rw * 0.14)
				local pingX = xpX + xpW
				local pingW = math.floor(rw * 0.10)

				local displayName = ply:Name() or "Unknown"
				local appearanceName = ply:GetNWString("PlayerName", "")
				if not LocalPlayer():Alive() and appearanceName ~= "" then
					displayName = displayName .. " (" .. appearanceName .. ")"
				end
				local fitted = FitText("ZCity_Veteran", displayName, nameW - 8)
				local nameCol = ply:Alive() and col.text or col.textBlood
				draw.SimpleText(fitted, "ZCity_Veteran", nameX + waveX, rh * 0.5 + waveY, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(tostring(ply:Frags()), "ZCity_Veteran", fragsX + fragsW * 0.5 + waveX, rh * 0.5 + waveY, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(tostring(math.floor(ply.exp or 0)), "ZCity_Veteran", xpX + xpW * 0.5 + waveX, rh * 0.5 + waveY, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				local p = ply:Ping()
				local pingCol = p < 80 and col.textDim or (p < 150 and Color(220, 180, 60, 200) or col.textBlood)
				draw.SimpleText(tostring(p), "ZCity_Veteran", pingX + pingW * 0.5 + waveX, rh * 0.5 + waveY, pingCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				for _, cx in ipairs({ fragsX, xpX, pingX }) do
					surface.SetDrawColor(col.separator)
					surface.DrawRect(cx, 4, 1, rh - 8)
				end
			end
		end

		row.DoClick = function()
			selectedSteamID = ply:SteamID()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "Нет, ты не можешь")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		row.DoRightClick = function()
			local Menu = DermaMenu()
			Menu:AddOption("Профиль", function()
				zb.Experience.AccountMenu(ply)
			end):SetIcon("icon16/user.png")
			Menu:AddOption("Копировать SteamID", function()
				SetClipboardText(ply:SteamID())
			end):SetIcon("icon16/page_copy.png")
			Menu:Open()
		end
	end

	local bottomY = sizeY - bottomBarH - ScreenScaleH(1)

	local bottomSep = vgui.Create("DPanel", scoreBoardMenu)
	bottomSep:SetPos(margin, bottomY - 2)
	bottomSep:SetSize(sizeX - margin * 2, 1)
	bottomSep.Paint = function(_, sw, sh)
		surface.SetDrawColor(col.separator)
		surface.DrawRect(0, 0, sw, sh)
	end

	local function CreateMenuButton(parent, x, y, text, isToggle, getState, onClick)
		local btn = vgui.Create("DButton", parent)
		btn:SetText("")
		btn:SetZPos(1500)
		btn:SetCursor("hand")
		surface.SetFont("ZCity_Veteran")
		local tw, th = surface.GetTextSize(text)
		local btnW = tw + ScreenScale(8)
		local btnH = math.max(ScreenScaleH(15), th + 6)
		btn:SetPos(x, y)
		btn:SetSize(btnW, btnH)
		local btnIdx = math.random(1, 100)
		btn.Paint = function(self, bw, bh)
			local t = CurTime()
			local hovered = self:IsHovered()
			local active = isToggle and getState and getState()
			local wX = math.sin(t * 28 + btnIdx * 0.75) * shakeStrength * 0.3
			local wY = math.cos(t * 24 + btnIdx * 0.65) * shakeStrength * 0.25
			local textCol = col.text
			if isToggle then
				textCol = active and Color(180, 220, 180, 255) or col.textDim
			end
			if hovered then
				textCol = Color(255, 255, 255, 255)
			end
			draw.SimpleText(text, "ZCity_Veteran", bw * 0.5 + wX, bh * 0.5 + wY, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			if hovered then
				surface.SetDrawColor(col.accent)
				surface.DrawRect(4, bh - 2, bw - 8, 1)
			end
			if isToggle then
				local dotCol = active and Color(120, 200, 120, 200) or Color(160, 50, 50, 150)
				surface.SetDrawColor(dotCol)
				surface.DrawRect(2 + wX, bh * 0.5 - 2 + wY, 4, 4)
			end
		end
		btn.DoClick = function()
			if onClick then onClick() end
		end
		return btn
	end

	local muteBtnY = bottomY + ScreenScaleH(3)
	local curBtnX = leftPanelX + ScreenScale(1)

	local muteAllBtn = CreateMenuButton(scoreBoardMenu, curBtnX, muteBtnY, "Заглушить всех", true,
		function() return hg.muteall end,
		function()
			hg.muteall = not hg.muteall
			for _, ply in player.Iterator() do
				if hg.muteall then
					ply:SetVoiceVolumeScale(0)
				else
					local vol = (not hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0
					ply:SetVoiceVolumeScale(vol)
				end
			end
		end
	)

	curBtnX = curBtnX + muteAllBtn:GetWide() + ScreenScale(4)

	CreateMenuButton(scoreBoardMenu, curBtnX, muteBtnY, "Заглушить наблюдателей", true,
		function() return hg.mutespect end,
		function()
			hg.mutespect = not hg.mutespect
			for _, ply in player.Iterator() do
				if ply:Alive() then continue end
				if hg.mutespect then
					ply:SetVoiceVolumeScale(0)
				else
					local vol = not hg.muteall and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0
					ply:SetVoiceVolumeScale(vol)
				end
			end
		end
	)

	local isSpectator = LocalPlayer():Team() == TEAM_SPECTATOR
	local actionText = isSpectator and "Играть" or "Наблюдать"
	surface.SetFont("ZCity_Veteran")
	local actionTW = surface.GetTextSize(actionText)
	local actionBtnW = actionTW + ScreenScale(8)
	local actionX = rightPanelX + rightPanelW - actionBtnW - ScreenScale(1)

	CreateMenuButton(scoreBoardMenu, actionX, muteBtnY, actionText, false, nil,
		function()
			net.Start("ZB_SpecMode")
			net.WriteBool(isSpectator and false or true)
			net.SendToServer()
			if IsValid(scoreBoardMenu) then
				scoreBoardMenu:Remove()
				scoreBoardMenu = nil
			end
		end
	)

	local function ClearRows(panel)
		local canvas = panel:GetCanvas()
		if not IsValid(canvas) then return end
		for _, child in ipairs(canvas:GetChildren()) do
			child:Remove()
		end
	end

	RebuildRows = function()
		if not IsValid(scoreBoardMenu) then return end
		local active = {}
		local specs = {}
		for _, ply in player.Iterator() do
			if CurrentRound().name == "fear" and not ply:Alive() then continue end
			if disappearance and ply ~= lply then continue end
			if ply:Team() == TEAM_SPECTATOR then
				specs[#specs + 1] = ply
			else
				active[#active + 1] = ply
			end
		end
		SortPlayers(active, playerSort)
		SortPlayers(specs, spectatorSort)
		local pScroll = playerListPanel:GetVBar():GetScroll()
		local sScroll = spectatorListPanel:GetVBar():GetScroll()
		ClearRows(playerListPanel)
		ClearRows(spectatorListPanel)
		for i, ply in ipairs(active) do
			AddPlayerRow(playerListPanel:GetCanvas(), ply, i, false)
		end
		for i, ply in ipairs(specs) do
			AddPlayerRow(spectatorListPanel:GetCanvas(), ply, i, true)
		end
		playerListPanel:GetVBar():SetScroll(pScroll)
		spectatorListPanel:GetVBar():SetScroll(sScroll)
	end

	scoreBoardMenu.RebuildRows = RebuildRows
	RebuildRows()
	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:Close()
		scoreBoardMenu = nil
	end
end
local AdminShowVoiceChat = CreateClientConVar("zb_admin_show_voicechat","0",false,false,"Show voicechat panels for admins",0,1)
hook.Add("PlayerStartVoice", "showVoicePanels", function(ply)
	if !IsValid(ply) then return end
	if LocalPlayer():IsAdmin() and AdminShowVoiceChat:GetBool() then return end

	local other_alive = (ply:Alive() and LocalPlayer() != ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))

	return other_alive or nil
end)

-- свет от молнии а саму молнию я не сделал skill issue
if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

/*  -- а кстати зачем здесь нэт, это же можно было на клиенте полностью сделать...
	if CLIENT then
		net.Receive("PluvCommand", function()
			local specialSteamID = "STEAM_0:1:81850653" 
			local playerSteamID = LocalPlayer():SteamID() 

			local imageURLs = {"https://sadsalat.github.io/salatis/music/boof.gif", "https://i.ibb.co/drt1Lks/KtvCLSs.webp", "https://media.tenor.com/kG4PmVvJuRIAAAAC/rain-world-rain-world-saint.gif"} 
			local soundURLs = {"https://sadsalat.github.io/salatis/music/sus-rock.mp3", "https://sadsalat.github.io/salatis/music/tiktok-raaaah-scream.mp3", "https://sadsalat.github.io/salatis/music/sus-rock.mp3"} 

			local chosenImage = imageURLs[math.random(#imageURLs)]
			local chosenSound = soundURLs[math.random(#soundURLs)]

			sound.PlayURL(chosenSound, "", function(station)
				if IsValid(station) then
					station:Play()
				else
					print("Unable to play the sound.")
				end
			end)

			local html = vgui.Create("HTML")
			html:OpenURL(chosenImage)
			html:SetSize(ScrW(), ScrH())
			html:Center()
			html:MakePopup()

			timer.Simple(3, function()
				if IsValid(html) then
					html:Remove()
				end
			end)
		end)
	end
*/

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function() -- вот как здесь!
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

  
    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

        
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            
            if validPosition then
                food = newFood
            end
        end
    end

    
    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

  
    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

   
    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

       
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

       
        table.insert(snake, 1, head)


        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            
            table.remove(snake)
        end
    end


    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end


    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    function frame:OnKeyCodePressed(key) -- ФУРИ МУВ теперь понятно почему лагает змейка
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end


    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)


    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Игра закрыта.") -- НЕ РАБОТАЕТ
    end


    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)
