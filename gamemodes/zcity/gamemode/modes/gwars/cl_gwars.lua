local MODE = MODE
MODE.name = "gwars"

local playstart
local ended
local roundStartSynced = 0

local MusicVolume = GetConVar("snd_musicvolume")

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
	shakeMul = (shakeMul or 1) * 0.425
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

local function SyncRoundFade()
	if roundStartSynced == zb.ROUND_START then return end
	roundStartSynced = zb.ROUND_START

	MODE.DynamicFadeScreenEndTime = zb.ROUND_START + (MODE.DefaultRoundStartTime or 6)
	fadeFX.shakeX = 0
	fadeFX.shakeY = 0
	fadeFX.targetShakeX = math.Rand(-2, 2)
	fadeFX.targetShakeY = math.Rand(-1.5, 1.5)
	fadeFX.nextShake = 0
end

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if not IsValid(station) then return end
		GWARS_LoopStation = station
		station:SetVolume(1 * MusicVolume:GetFloat())
		station:EnableLooping(true)
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if not IsValid(station) then return end
		GWARS_LoopStation2 = station
		station:SetVolume(1 * MusicVolume:GetFloat())
		station:EnableLooping(true)
	end)
end)

local teams = {
	[0] = {
		objective = "Убей всех из Grove Street.",
		name = "бандит Bloodz",
		color1 = Color(180, 0, 0),
		color2 = Color(180, 0, 0),
	},
	[1] = {
		objective = "Убей всех из Bloodz.",
		name = "бандит Grove",
		color1 = Color(0, 180, 0),
		color2 = Color(0, 180, 0),
	},
}

local lerpsnd = 0.3

function MODE:RenderScreenspaceEffects()
	SyncRoundFade()
	local overlay = MODE.GetRoundFadeOverlay()
	if overlay <= 0 then return end

	zb.RemoveFade()
	UpdateFadeShake(overlay)
	PaintRoundFadeBG(overlay)
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	extended = true,
	weight = 650,
	antialias = true,
	italic = false,
})

function MODE:HUDPaint()
	SyncRoundFade()

	local sw, sh = ScrW(), ScrH()
	local timeBeforeSWAT = zb.ROUND_START - CurTime() + 120

	if timeBeforeSWAT > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeSWAT, "%02i:%02i:%02i")
		local suffix = " до прибытия СОБР"
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w, _ = surface.GetTextSize(time)
		local w2, _ = surface.GetTextSize("11:11:11" .. suffix)
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + w, sh * 0.05)
		surface.DrawText(suffix)
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if not IsValid(station) then return end
				station:SetVolume(0.3 * MusicVolume:GetFloat())
				station:Play()
			end)
			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, not ended and (lply:Alive() and lply.organism and not lply.organism.otrub and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeSWAT <= 0 and 2 or 0), 0, 1) or 0.3) or 0)

		if zb.ROUND_START + 12 < CurTime() and IsValid(GWARS_LoopStation) then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
			GWARS_LoopStation:Play()
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(0)
				GWARS_LoopStation2:Play()
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

	if not IsValid(lply) or not lply:Alive() or lply:Team() == TEAM_SPECTATOR then return end

	local introLen = (MODE.DefaultRoundStartTime or 6) + (MODE.FadeScreenTime or 1.5)
	if CurTime() > zb.ROUND_START + introLen + 2 then return end

	zb.RemoveFade()
	local overlay = MODE.GetRoundFadeOverlay()
	UpdateFadeShake(math.max(overlay, 0.35))

	local textFade = overlay > 0 and math.Clamp(overlay / 0.85, 0, 1) or math.Clamp((zb.ROUND_START + introLen - CurTime()) / introLen, 0, 1)
	if textFade <= 0 then return end

	local teamInfo = teams[lply:Team()]
	if not teamInfo then return end

	DrawFadeTitle("Война банд", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * textFade), 255 * textFade)

	local colRole = Color(teamInfo.color1.r, teamInfo.color1.g, teamInfo.color1.b, 255 * textFade)
	DrawFadeText("Ты - " .. teamInfo.name, "ZCity_Veteran_big", sw * 0.5, sh * 0.5, colRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.25)

	local colObj = Color(teamInfo.color2.r, teamInfo.color2.g, teamInfo.color2.b, 255 * textFade)
	DrawFadeText(teamInfo.objective, "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, colObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
end

net.Receive("gwars_roundend", function()
	zb.EndMenu.Open()
end)

function MODE:RoundStart()
	zb.EndMenu.Close()
end
