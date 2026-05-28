local MODE = MODE
MODE.name = "zombie"

local nextWaveAt = 0
local currentWave = 0
local totalWaves = 6
local roundStartSynced = 0

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

local intro = {
	objective = "Вокруг творится полный пиздец. Надо найти союзников и оружие",
	name = "Выживший",
	color1 = Color(80, 200, 80),
	color2 = Color(60, 160, 60),
}

net.Receive("zombie_start", function()
	nextWaveAt = 0
	currentWave = 0
	hg.DynaMusic:Start("black_mesa")
	zb.RemoveFade()
end)

net.Receive("zombie_newwave", function()
	currentWave = net.ReadInt(8)
	totalWaves = net.ReadInt(8)
	nextWaveAt = CurTime() + 8
end)

function MODE:RenderScreenspaceEffects()
	SyncRoundFade()
	local overlay = MODE.GetRoundFadeOverlay()
	if overlay <= 0 then return end

	zb.RemoveFade()
	UpdateFadeShake(overlay)
	PaintRoundFadeBG(overlay)
end

function MODE:HUDPaint()
	SyncRoundFade()

	local sw, sh = ScrW(), ScrH()

	local waveAt = nextWaveAt
	if currentWave == 0 and waveAt <= CurTime() then
		waveAt = zb.ROUND_START + 35
	end

	if waveAt > CurTime() then
		local t = waveAt - CurTime()
	end

	if not IsValid(lply) or not lply:Alive() or lply:Team() == TEAM_SPECTATOR then return end

	local introLen = (MODE.DefaultRoundStartTime or 6) + (MODE.FadeScreenTime or 1.5)
	if CurTime() > zb.ROUND_START + introLen + 2 then return end

	zb.RemoveFade()
	local overlay = MODE.GetRoundFadeOverlay()
	UpdateFadeShake(math.max(overlay, 0.35))

	local textFade = overlay > 0 and math.Clamp(overlay / 0.85, 0, 1) or math.Clamp((zb.ROUND_START + introLen - CurTime()) / introLen, 0, 1)
	if textFade <= 0 then return end

	DrawFadeTitle("Зомбари", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * textFade), 255 * textFade)

	local colRole = Color(intro.color1.r, intro.color1.g, intro.color1.b, 255 * textFade)
	DrawFadeText("Ты - " .. intro.name, "ZCity_Veteran_big", sw * 0.5, sh * 0.5, colRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.25)

	local colObj = Color(intro.color2.r, intro.color2.g, intro.color2.b, 255 * textFade)
	DrawFadeText(intro.objective, "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, colObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
end

net.Receive("zombie_roundend", function()
	local survived = net.ReadBool()
	zb.EndMenu.Open({
		sound = survived and "ambient/alarms/warningbell1.wav",
		statusText = function(ply)
			if not ply:Alive() then return " - мёртв" end
			return survived and " - выжил" or ""
		end,
	})
end)

function MODE:RoundStart()
	zb.EndMenu.Close()
end
