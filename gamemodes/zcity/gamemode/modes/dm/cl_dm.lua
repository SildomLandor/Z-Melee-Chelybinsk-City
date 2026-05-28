local MODE = MODE

local roundStartSynced = 0
local roundend = false

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

function MODE.GetRoundFadeOverlay(mode)
	mode = mode or CurrentRound()
	if not mode then return 0 end

	local diff = (mode.DynamicFadeScreenEndTime or 0) - CurTime()
	if diff <= 0 then return 0 end
	return math.min(diff / (mode.FadeScreenTime or 1.5), 1)
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

local function SyncRoundFade(mode)
	mode = mode or CurrentRound()
	if not mode then return end
	if roundStartSynced == zb.ROUND_START then return end
	roundStartSynced = zb.ROUND_START

	mode.DynamicFadeScreenEndTime = zb.ROUND_START + (mode.DefaultRoundStartTime or 6)
	fadeFX.shakeX = 0
	fadeFX.shakeY = 0
	fadeFX.targetShakeX = math.Rand(-2, 2)
	fadeFX.targetShakeY = math.Rand(-1.5, 1.5)
	fadeFX.nextShake = 0
end

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)

local fighterColor = Color(0, 120, 190)

net.Receive("dm_start", function()
	roundend = false
	hg.DynaMusic:Start("black_mesa_agressive")
	zb.RemoveFade()
	SyncRoundFade(CurrentRound())

	ZonePos = net.ReadVector()
	zonedistance = net.ReadFloat()

	surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
	sound.PlayFile("sound/ambient/energy/force_field_loop1.wav", "noblock", function(station)
		if not IsValid(station) then return end
		zb.SoundStation = station
		station:Play()
		station:EnableLooping(true)
		station:SetVolume(0)
	end)
end)

hook.Add("Think", "ZoneSoundThink", function()
	if not MODE.IsDMFamily(CurrentRound()) then return end
	local station = zb.SoundStation
	if not IsValid(station) then return end
	if deathmatch_nozone:GetBool() then return end
	local radius = MODE.GetZoneRadius()
	local volume = math.Clamp((LocalPlayer():GetPos():Distance(ZonePos) - radius) + 200, 0, 200) / 200
	station:SetVolume(volume)
end)

local mat = Material("hmcd_dmzone")

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if bSkybox or isDraw3DSkybox or deathmatch_nozone:GetBool() then return end
	local radius = MODE.GetZoneRadius()
	render.SetMaterial(mat)
	render.DrawSphere(ZonePos, -radius, 60, 60, color_white)
end

function MODE:RenderScreenspaceEffects()
	SyncRoundFade(self)
	local overlay = MODE.GetRoundFadeOverlay(self)
	if overlay <= 0 then return end

	zb.RemoveFade()
	UpdateFadeShake(overlay)
	PaintRoundFadeBG(overlay)
end

function MODE:HUDPaint()
	SyncRoundFade(self)

	if zb.ROUND_START + 20 > CurTime() then
		draw.SimpleText(string.FormattedTime(zb.ROUND_START + 20 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255, 55, 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if not lply:Alive() then return end

	local introLen = (self.DefaultRoundStartTime or 6) + (self.FadeScreenTime or 1.5)
	if CurTime() > zb.ROUND_START + introLen + 2 then return end

	zb.RemoveFade()
	local overlay = MODE.GetRoundFadeOverlay(self)
	UpdateFadeShake(math.max(overlay, 0.35))

	local textFade = overlay > 0 and math.Clamp(overlay / 0.85, 0, 1) or math.Clamp((zb.ROUND_START + introLen - CurTime()) / introLen, 0, 1)
	if textFade <= 0 then return end

	local accent = self.FighterColor or fighterColor

	DrawFadeTitle(self.IntroTitle or "Мини игры | Против всех", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * textFade), 255 * textFade)

	local colRole = Color(accent.r, accent.g, accent.b, 255 * textFade)
	DrawFadeText("Ты — " .. (self.FighterName or "Боец"), "ZCity_Veteran_big", sw * 0.5, sh * 0.5, colRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.25)

	local colObj = Color(accent.r, accent.g, accent.b, 255 * textFade)
	DrawFadeText(self.FighterObjective or "Убей всех.", "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, colObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
end

net.Receive("dm_end", function()
	local ent = net.ReadEntity()
	local most_violent_player = net.ReadEntity()

	if IsValid(most_violent_player) then
		most_violent_player.most_violent_player = true
	end

	local wonply = IsValid(ent) and ent or nil
	if IsValid(ent) then ent.won = true end

	zb.SoundStation = nil
	roundend = CurTime()

	if MODE.SoundStation and MODE.SoundStation:IsValid() then
		MODE.SoundStation:Stop()
		MODE.SoundStation = nil
	end

	local winnerName = IsValid(wonply) and wonply:GetPlayerName() or "Никто"
	zb.EndMenu.Open({
		subtitle = winnerName .. " победил!",
		subtitleColor = Color(217, 201, 99),
		statusText = function(ply)
			if ply.most_violent_player then return " — MVP" end
			if not ply:Alive() then return " — мёртв" end
			return ""
		end,
		rowStyle = function(ply)
			if ply.won or ply.most_violent_player then return { winner = true } end
			if ply:Alive() then return { bar = Color(0, 120, 190) } end
		end,
	})
end)

function MODE:RoundStart()
	for _, ply in player.Iterator() do
		ply.won = nil
		ply.most_violent_player = nil
	end
	zb.EndMenu.Close()
end
