MODE.name = "gwars"
local MODE = MODE

local playstart
local ended

local MusicVolume = GetConVar("snd_musicvolume")

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation2 = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	//music_themes/ghetto_loop.wav
	//music_themes/ghetto_start.wav
	
end)

local teams = {
	[0] = {
		objective = "Убейте зелёных ниггеров",
		name = "Член Блудз",
		color1 = Color(180, 0, 0),
		color2 = Color(180, 0, 0)
	},
	[1] = {
		objective = "Убейте красных ниггеров",
		name = "Члег Грув",
		color1 = Color(0, 180, 0),
		color2 = Color(0, 180, 0)
	},
}
local lerpsnd = 0.3
function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift", 
	size = ScreenScale(12), 
	extended = true, 
	weight = 650,
	antialias = true,
	italic = false
})

function MODE:HUDPaint()
	//if !lply.organism or !lply.organism.fear then return end

	local timeBeforeSWAT = (zb.ROUND_START - CurTime() + 120)
	if timeBeforeSWAT > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeSWAT, "%02i:%02i:%02i")
		local text = "00:00:00"
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w, h = surface.GetTextSize(text)
		local w2, h2 = surface.GetTextSize("11:11:11 До прибытия СОБР")
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + w, sh * 0.05)
		surface.DrawText("До прибытия СОБР")
		//draw.SimpleText(" left before SWAT arrives!", "timer_Font2", sw * 0.432, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		//draw.SimpleText(time, "timer_Font2", sw * 0.36, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0.3 * MusicVolume:GetFloat())
					station:Play()
				end
			end)

			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, !ended and (lply:Alive() and lply.organism and !lply.organism.otrub and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeSWAT <= 0 and 2 or 0), 0, 1) or 0.3) or 0)
		
		if zb.ROUND_START + 12 < CurTime() then
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
				GWARS_LoopStation:Play()
				
				if IsValid(GWARS_LoopStation2) then
					GWARS_LoopStation2:SetVolume(0)
					GWARS_LoopStation2:Play()
				end
			end
		end

		if IsValid(GWARS_LoopStation) and GWARS_LoopStation:GetState() == GMOD_CHANNEL_PLAYING then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
		end
	
		if timeBeforeSWAT <= 0 then
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(lerpsnd * MusicVolume:GetFloat())
			end
			
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(0)
			end
		end
	end
end
	local StartTime = 0
local fadeFX = {
	noiseMat = Material("vgui/noisevhs"),
	shakeX = 0,
	shakeY = 0,
	targetShakeX = 0,
	targetShakeY = 0,
	nextShake = 0,
}

if fadeFX.noiseMat:IsError() then
	fadeFX.noiseMat = Material("vgui/white")
end

function MODE.GetRoundFadeOverlay()
	local diff = (MODE.DynamicFadeScreenEndTime or 0) - CurTime()
	if diff <= 0 then return 0 end
	return math.min(diff / (MODE.FadeScreenTime or 1.5), 1)
end

local function UpdateFadeShake(intensity)
	intensity = math.Clamp(intensity, 0, 1)
	if intensity <= 0.01 then
		local calm = math.Clamp(FrameTime() * 10, 0, 1)
		fadeFX.shakeX = Lerp(calm, fadeFX.shakeX, 0)
		fadeFX.shakeY = Lerp(calm, fadeFX.shakeY, 0)
		return
	end

	local t = CurTime()
	if t >= fadeFX.nextShake then
		fadeFX.nextShake = t + 0.035
		local s = 0.55 + intensity * 2.2
		fadeFX.targetShakeX = math.Rand(-s, s)
		fadeFX.targetShakeY = math.Rand(-s * 0.65, s * 0.65)
	end

	local rate = math.Clamp(FrameTime() * 22, 0, 1)
	fadeFX.shakeX = Lerp(rate, fadeFX.shakeX, fadeFX.targetShakeX)
	fadeFX.shakeY = Lerp(rate, fadeFX.shakeY, fadeFX.targetShakeY)
end

local function PaintRoundFadeBG(overlay)
	local w, h = ScrW(), ScrH()
	local a = math.floor(255 * overlay)

	draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 19, a))

	local mat = fadeFX.noiseMat
	if not mat:IsError() then
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, math.floor(10 + 14 * overlay))
		local nx, ny = math.random(0, 512), math.random(0, 512)
		surface.DrawTexturedRectUV(0, 0, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
	end

	for y = 0, h, 3 do
		surface.SetDrawColor(0, 0, 0, math.floor(8 + 10 * overlay))
		surface.DrawRect(0, y, w, 1)
	end

	if math.random() > 0.55 then
		surface.SetDrawColor(180, 20, 15, math.floor(6 * overlay))
		surface.DrawRect(math.random(0, w), math.random(0, h), math.random(w * 0.2, w * 0.5), 1)
	end

	surface.SetDrawColor(90, 90, 95, math.floor(40 * overlay))
	surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local function DrawFadeText(text, font, cx, cy, col, ax, ay, shakeMul)
	shakeMul = shakeMul or 1
	shakeMul = shakeMul * 0.425
	local sx = fadeFX.shakeX * shakeMul
	local sy = fadeFX.shakeY * shakeMul

	if shakeMul >= 0.8 and math.random() > 0.93 then
		sx = sx + math.random(-1, 1)
		sy = sy + math.random(-1, 1)
	end

	draw.SimpleText(text, font, cx + sx, cy + sy, col, ax, ay)
end

local function DrawFadeTitle(text, cx, cy, col, alpha)
	local font = "ZCity_Veteran_big"
	local sx = fadeFX.shakeX * 0.85
	local sy = fadeFX.shakeY * 0.85

	if math.random() > 0.96 then
		sx = sx + math.random(-2, 2)
		sy = sy + math.random(-1, 1)
	end

	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	local bx, by = cx + sx - tw * 0.5, cy + sy - th * 0.5
	local pulse = math.sin(CurTime() * 1.5) * 0.15 + 0.85

	draw.SimpleText(text, font, bx + 2, by + 2, Color(40, 4, 2, alpha * 0.75), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx + 1, by + 1, Color(90, 8, 6, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx, by, Color(col.r * pulse, col.g * pulse, col.b * pulse, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	if math.random() > 0.985 then
		draw.SimpleText(text, font, bx + math.random(-1, 1), by + math.random(-1, 1), Color(180, 20, 15, alpha * 0.45), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

local CreateEndMenu
net.Receive("gwars_roundend", function()
	ended = true
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local colorBG = Color(55, 55, 55, 255)
local colorBGBlacky = Color(40, 40, 40, 255)
local blurMat = Material("pp/blurscreen")
local Dynamic = 0
BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")
	surface.PlaySound("ambient/alarms/warningbell1.wav")
	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	--hmcdEndMenu:SetBackgroundColor(colGray)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	
	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	-- PLAYERS
	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)
			local col = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			local col = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")
			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(col.r, col.g, col.b, col.a)
			local lengthX, lengthY = surface.GetTextSize(ply:Frags() or "He quited...")
			surface.SetTextPos(w - lengthX - 15, h / 2 - lengthY / 2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end

			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end
	return true
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end