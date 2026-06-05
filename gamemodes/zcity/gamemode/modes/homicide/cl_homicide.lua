local MODE = MODE
MODE.name = "hmcd"

--\\Local Functions
local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end
--//

MODE.TypeSounds = {
	["standard"] = {"snd_jack_hmcd_psycho.mp3","snd_jack_hmcd_shining.mp3"},
	["soe"] = "snd_jack_hmcd_disaster.mp3",
	["gunfreezone"] = "snd_jack_hmcd_panic.mp3" ,
	["suicidelunatic"] = "zbattle/jihadmode.mp3",
}

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

local function StoreTraitorWords(ply, w1, w2)
	MODE.TraitorWord = w1
	MODE.TraitorWordSecond = w2
	if not IsValid(ply) then return end
	ply.HMCD_TraitorWord = w1
	ply.HMCD_TraitorWordSecond = w2
end

net.Receive("HMCD_RoundStart", function()
	zb.EndMenu.Close()

	local lply = LocalPlayer()
	lply.role = false

	lply.isTraitor = net.ReadBool()
	lply.isGunner = net.ReadBool()
	MODE.Type = net.ReadString()
	local screen_time_is_default = net.ReadBool()
	lply.SubRole = net.ReadString()
	lply.MainTraitor = net.ReadBool()
	local w1 = net.ReadString()
	local w2 = net.ReadString()
	MODE.TraitorExpectedAmt = net.ReadUInt(MODE.TraitorExpectedAmtBits)
	StartTime = CurTime()
	MODE.TraitorsLocal = {}

	if lply.isTraitor then
		StoreTraitorWords(lply, w1, w2)
	else
		StoreTraitorWords(lply, "", "")
	end

	if(lply.isTraitor and screen_time_is_default)then
		if(MODE.TraitorExpectedAmt == 1)then
			chat.AddText("Вы один на задании.")
		else
			if(MODE.TraitorExpectedAmt == 2)then
				chat.AddText("У вас 1 сообщник.")
			else
				chat.AddText("Кроме вас ещё " .. MODE.TraitorExpectedAmt - 1 .. " предателей.")
			end

			chat.AddText("Кодовые слова: «" .. MODE.TraitorWord .. "» и «" .. MODE.TraitorWordSecond .. "».")
		end

		if(lply.MainTraitor)then
			if(MODE.TraitorExpectedAmt > 1)then
				chat.AddText("Имена предателей (видите только вы, главный предатель):")
			end

			local read_amt = math.max(0, MODE.TraitorExpectedAmt - 1)
			for key = 1, read_amt do
				local traitor_info = {net.ReadColor(false), net.ReadString()}

				if(MODE.TraitorExpectedAmt > 1)then
					MODE.TraitorsLocal[#MODE.TraitorsLocal + 1] = traitor_info
					chat.AddText(traitor_info[1], "\t" .. traitor_info[2])
				end
			end
		end
	end

	lply.Profession = net.ReadString()

	for i, ply in player.Iterator() do
		if ply == lply then continue end
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.HMCD_TraitorWord = nil
		ply.HMCD_TraitorWordSecond = nil
	end

	if(MODE.RoleChooseRoundTypes[MODE.Type] and !screen_time_is_default)then
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.RoleChooseRoundStartTime
	else
		MODE.DynamicFadeScreenEndTime = CurTime() + MODE.DefaultRoundStartTime
	end

	timer.Remove("HMCD_RoundRoleReveal")

	local function playRoundStartSound()
		if istable(MODE.TypeSounds[MODE.Type]) then
			surface.PlaySound(table.Random(MODE.TypeSounds[MODE.Type]))
		elseif MODE.TypeSounds[MODE.Type] then
			surface.PlaySound(MODE.TypeSounds[MODE.Type])
		end
	end

	if screen_time_is_default then
		MODE.RoleEndedChosingState = false
		timer.Create("HMCD_RoundRoleReveal", MODE.RoundPreludeTime or 1, 1, function()
			MODE.RoleEndedChosingState = true
			playRoundStartSound()
		end)
	else
		MODE.RoleEndedChosingState = false
	end

	fadeFX.shakeX = 0
	fadeFX.shakeY = 0
	fadeFX.targetShakeX = math.Rand(-2, 2)
	fadeFX.targetShakeY = math.Rand(-1.5, 1.5)
	fadeFX.nextShake = 0
end)

MODE.TypeNames = {
	["standard"] = "Стандарт",
	["soe"] = "Чрезвычайное положение",
	["gunfreezone"] = "Gun Free Zone",
	["suicidelunatic"] = "Suicide Lunatic",
}

surface.CreateFont("ZB_HomicideSmall", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_HomicideMedium", {
	font = font(),
	size = ScreenScale(15),
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_HomicideMediumLarge", {
	font = font(),
	size = ScreenScale(25),
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_HomicideLarge", {
	font = font(),
	size = ScreenScale(30),
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_HomicideHumongous", {
	font = font(),
	size = 255,
	weight = 400,
	extended = true,
	antialias = true
})

MODE.TypeObjectives = {}
MODE.TypeObjectives.soe = {
	traitor = {
		objective = "Снаряжение, яды и оружие в карманах. Убей всех.",
		name = "предатель",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Невиновный с охотничьим оружием. Найди и обезвредь предателя.",
		name = "невиновный",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "Держись рядом с людьми — так предателю сложнее.",
		name = "невиновный",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.standard = {
	traitor = {
		objective = "Снаряжение, яды и оружие в карманах. Убей всех.",
		name = "убийца",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Скрытое оружие. Помоги найти преступника быстрее.",
		name = "свидетель",
		color1 = Color(0,120,190),
		color2 = Color(158,0,190)
	},

	innocent = {
		objective = "На месте убийства. Будь осторожен.",
		name = "свидетель",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.gunfreezone = {
	traitor = {
		objective = "У тебя есть всё необходимое: предметы, яды, взрывчатка и оружие спрятаны по карманам. Убей здесь всех.",
		name = "Убийца",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Ты свидетель на месте убийства. Будь осторожен и внимателен — хотя тебя не убили, опасность всё ещё рядом.",
		name = "Свидетель",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Ты свидетель на месте убийства. Хотя убийство случилось не с тобой, лучше быть начеку.",
		name = "Свидетель",
		color1 = Color(0,120,190)
	},
}

MODE.TypeObjectives.suicidelunatic = {
	traitor = {
		objective = "Твои братья рассчитывают на тебя, брат, не подведи их ради высшей цели.",
		name = "Шахид",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},

	gunner = {
		objective = "Кто-то сошёл с ума и пошёл на всё — попытайся выжить любой ценой.",
		name = "Невиновный",
		color1 = Color(0,120,190)
	},

	innocent = {
		objective = "Кто-то сошёл с ума и пошёл на всё — попытайся выжить любой ценой.",
		name = "Невиновный",
		color1 = Color(0,120,190)
	},
}

function MODE:RenderScreenspaceEffects()
	local overlay = MODE.GetRoundFadeOverlay()
	if overlay <= 0 then return end

	zb.RemoveFade()
	UpdateFadeShake(overlay)
	PaintRoundFadeBG(overlay)
end

local handicap = {
	[1] = "You are handicapped: your right leg is broken.",
	[2] = "You are handicapped: you are suffering from severe obesity.",
	[3] = "You are handicapped: you are suffering from hemophilia.",
	[4] = "You are handicapped: you are physically incapacitated."
}

function MODE:HUDPaint()
	if not MODE.Type or not MODE.TypeObjectives[MODE.Type] then return end
	local lply = LocalPlayer()
	if not IsValid(lply) or lply:Team() == TEAM_SPECTATOR then return end

	if StartTime <= 0 then
		StartTime = zb.ROUND_BEGIN or CurTime()
	end

	local introLen = (MODE.DefaultRoundStartTime or 6) + (MODE.FadeScreenTime or 1.5)
	if CurTime() > StartTime + introLen + 2 then return end

	local sw, sh = ScrW(), ScrH()
	local overlay = MODE.GetRoundFadeOverlay()
	UpdateFadeShake(math.max(overlay, 0.35))

	local textFade = overlay > 0 and math.Clamp(overlay / 0.85, 0, 1) or math.Clamp((StartTime + introLen - CurTime()) / introLen, 0, 1)
	if textFade <= 0 then return end

	local titleStr = "Мокруха | " .. (MODE.TypeNames[MODE.Type] or "Неизвестно")
	local titleCol = Color(160, 0, 0, 255 * textFade)
	DrawFadeTitle(titleStr, sw * 0.5, sh * 0.1, titleCol, 255 * textFade)

	local Rolename = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.name ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.name ) or MODE.TypeObjectives[MODE.Type].innocent.name
	local ColorRole = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color1 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color1 ) or MODE.TypeObjectives[MODE.Type].innocent.color1
	ColorRole.a = 255 * textFade

	local color_role_innocent = MODE.TypeObjectives[MODE.Type].innocent.color1
	color_role_innocent.a = 255 * textFade

	local color_white_faded = Color(255, 255, 255, 255 * textFade)
	color_white_faded.a = 255 * textFade

	DrawFadeText("Вы - " .. Rolename, "ZCity_Veteran_big", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.25)

	local cur_y = sh * 0.5

	if(lply.SubRole and lply.SubRole != "")then
		cur_y = cur_y + ScreenScale(20)

		local subName = (hg.TraitorLoadout and hg.TraitorLoadout.GetSubRoleLabel(lply.SubRole))
			or (MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Name)
			or lply.SubRole
		DrawFadeText(subName, "ZCity_Veteran_big", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		DrawFadeText("Помощник", "ZCity_Veteran_big", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
	end

	if(lply.isTraitor)then
		cur_y = cur_y + ScreenScale(20)

		if(lply.MainTraitor)then
			MODE.TraitorsLocal = MODE.TraitorsLocal or {}

			if(#MODE.TraitorsLocal > 1)then
				DrawFadeText("Traitors list:", "ZCity_Veteran_big", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)

				for _, traitor_info in ipairs(MODE.TraitorsLocal) do
					local traitor_color = Color(traitor_info[1].r, traitor_info[1].g, traitor_info[1].b, 255 * textFade)
					cur_y = cur_y + ScreenScale(15)

					DrawFadeText(traitor_info[2], "ZCity_Veteran_big", sw * 0.5, cur_y, traitor_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.05)
				end
			end
		else
			DrawFadeText("Traitor secret words:", "ZCity_Veteran_big", sw * 0.5, cur_y, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)

			cur_y = cur_y + ScreenScale(15)

			DrawFadeText("\"" .. MODE.TraitorWord .. "\"", "ZCity_Veteran_big", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.15)

			cur_y = cur_y + ScreenScale(15)

			DrawFadeText("\"" .. MODE.TraitorWordSecond .. "\"", "ZCity_Veteran_big", sw * 0.5, cur_y, color_white_faded, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.15)
		end
	end

	if(lply.Profession and lply.Profession != "")then
		cur_y = cur_y + ScreenScale(20)

		DrawFadeText("Профессия: " .. ((MODE.Professions[lply.Profession] and MODE.Professions[lply.Profession].Name or lply.Profession) or lply.Profession), "ZCity_Veteran_big", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.05)
	end
	
	if(handicap[lply:GetLocalVar("karma_sickness", 0)])then
		cur_y = cur_y + ScreenScale(20)

		DrawFadeText(handicap[lply:GetLocalVar("karma_sickness", 0)], "ZCity_Veteran_big", sw * 0.5, cur_y, color_role_innocent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.05)
	end

	local Objective = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.objective ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.objective ) or MODE.TypeObjectives[MODE.Type].innocent.objective

	if(lply.SubRole and lply.SubRole != "")then
		local subObj = (hg.TraitorLoadout and hg.TraitorLoadout.GetSubRoleObjective(lply.SubRole))
			or (MODE.SubRoles[lply.SubRole] and MODE.SubRoles[lply.SubRole].Objective)
		if subObj then Objective = subObj end
	end

	if(!lply.MainTraitor and lply.isTraitor)then
		Objective = "Без снаряжения. Помоги другим предателям победить."
	end

	if(!MODE.RoleEndedChosingState)then
		Objective = "Раунд запускается..."
	end

	local ColorObj = ( lply.isTraitor and MODE.TypeObjectives[MODE.Type].traitor.color2 ) or ( lply.isGunner and MODE.TypeObjectives[MODE.Type].gunner.color2 ) or MODE.TypeObjectives[MODE.Type].innocent.color2 or Color(255,255,255)
	ColorObj.a = 255 * textFade
	DrawFadeText(Objective, "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.7 * 1.1)
end

net.Receive("HMCD(SetSubRole)", function(len, ply)
	lply.SubRole = net.ReadString()
end)

local traitorBar = Color(190, 0, 0)
local gunnerBar = Color(158, 0, 190)

local function ReadRoundEndRoster()
	local bits = MODE.TraitorExpectedAmtBits or 13
	local traitors, gunners = {}, {}
	local tAmt = net.ReadUInt(bits)

	for _ = 1, tAmt do
		local ent = net.ReadEntity()
		if IsValid(ent) then traitors[#traitors + 1] = ent end
	end

	local gAmt = net.ReadUInt(bits)
	for _ = 1, gAmt do
		local ent = net.ReadEntity()
		if IsValid(ent) then gunners[#gunners + 1] = ent end
	end

	return traitors, gunners
end

local function HomicideEndSubtitle(traitorSet)
	local aliveTraitors, aliveOthers = 0, 0

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end
		if traitorSet[ply] then
			aliveTraitors = aliveTraitors + 1
		else
			aliveOthers = aliveOthers + 1
		end
	end

	if aliveTraitors > 0 and aliveOthers == 0 then
		return "Победа предателей"
	end
	if aliveTraitors == 0 then
		return "Предатели нейтрализованы"
	end
	return "Раунд окончен"
end

net.Receive("hmcd_roundend", function()
	local traitors, gunners = ReadRoundEndRoster()
	local traitorSet, gunnerSet = {}, {}

	for _, ply in ipairs(traitors) do
		traitorSet[ply] = true
	end
	for _, ply in ipairs(gunners) do
		gunnerSet[ply] = true
	end

	zb.EndMenu.Open({
		title = "Мокруха | " .. (MODE.TypeNames[MODE.Type] or "Хомисайд"),
		subtitle = HomicideEndSubtitle(traitorSet),
		rowStyle = function(ply)
			if traitorSet[ply] then
				return { bar = traitorBar, nameCol = ply:Alive() and traitorBar or nil }
			end
			if gunnerSet[ply] then
				return { bar = gunnerBar }
			end
		end,
		statusText = function(ply)
			if traitorSet[ply] then
				return ply:Alive() and " — предатель" or " — предатель, мёртв"
			end
			if gunnerSet[ply] then
				return ply:Alive() and " — свидетель" or " — свидетель, мёртв"
			end
			if not ply:Alive() then return " — мёртв" end
			return ""
		end,
	})
end)

