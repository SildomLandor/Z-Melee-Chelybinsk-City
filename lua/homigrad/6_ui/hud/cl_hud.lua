local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = true,
	["CHudDamageIndicator"] = true,
	["CHudGeiger"] = true,
	["CHudSquadStatus"] = true,
	["CHudTrain"] = true,
	["CHudZoom"] = true,
	["CHudSuitPower"] = true,
	["CHUDQuickInfo"] = true,
	["CHudHistoryResource"] = true,
}

local gordon_hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = true,
	["CHudSuitPower"] = true,
}

hook.Add("HUDShouldDraw", "homigrad", function(name)
	if hide[name] or lply.PlayerClassName and lply.PlayerClassName == "Gordon" and gordon_hide[name] then
		return false
	end
end)
hook.Add("HUDDrawTargetID", "homigrad", function()
	return false
end)

hook.Add("DrawDeathNotice", "homigrad", function()
	return false
end)

hook.Add("HUDWeaponPickedUp", "HidePickedStuff", function(wep)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDAmmoPickedUp", "HidePickedStuff", function(ammoname, amt)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDItemPickedUp", "HidePickedStuff", function(itemname)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDDrawPickupHistory", "HidePickedStuff", function()
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

local function ZB_CreateUIFonts()
	CreateFontFamily({
    weight  = 1100,
    outline = false,
}, {
    HomigradFont              = { size = ScreenScale(10) },
    ScoreboardPlayer          = { size = ScreenScale(7) },
    HomigradFontBig           = { size = ScreenScale(12), shadow = true },
    HomigradFontMedium        = { size = ScreenScale(8) },
    HomigradFontLarge         = { size = ScreenScale(15) },
    HomigradFontGigantoNormous= { size = ScreenScale(25), shadow = false },
    HomigradFontSmall         = { size = 17 },
    HomigradFontVSmall        = { size = 12, weight = 400 },
    ZCity_Veteran             = { size = ScreenScale(8), weight = 700, antialias = true },
})
end
ZB_CreateUIFonts()
local w, h

hook.Add("HUDPaint", "homigrad-dev", function()
	if engine.ActiveGamemode() ~= "sandbox" then return end
	w, h = ScrW(), ScrH()
end)

function draw.CirclePart(x, y, radius, seg, parts, pos)
	local cir = {}
	table.insert(cir, {
		x = x,
		y = y,
		u = 0.5,
		v = 0.5
	})
	for i = 0, seg do
		local a = math.rad((i / seg) * -360 / parts - pos * 360 / parts) + math.pi
		table.insert(cir, {
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + 0.5,
			v = math.cos(a) / 2 + 0.5
		})
	end
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	surface.DrawPoly(cir)
	render.PopFilterMin()
end

function draw.CirclePartRing(x, y, rInner, rOuter, seg, parts, pos, gapDeg)
	gapDeg = gapDeg or 3
	local poly = {}
	local totalDeg = 360 / parts
	local startDeg = pos * totalDeg + gapDeg * 0.5
	local endDeg   = (pos + 1) * totalDeg - gapDeg * 0.5
	local startR = math.rad(startDeg - 90)
	local endR   = math.rad(endDeg   - 90)
	for i = 0, seg do
		local a = startR + (endR - startR) * (i / seg)
		poly[#poly + 1] = {
			x = x + math.cos(a) * rOuter,
			y = y + math.sin(a) * rOuter,
			u = 0.5, v = 0.5
		}
	end
	for i = seg, 0, -1 do
		local a = startR + (endR - startR) * (i / seg)
		poly[#poly + 1] = {
			x = x + math.cos(a) * rInner,
			y = y + math.sin(a) * rInner,
			u = 0.5, v = 0.5
		}
	end
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	surface.DrawPoly(poly)
	render.PopFilterMin()
end

function draw.CirclePartRingOutline(x, y, rInner, rOuter, seg, parts, pos, gapDeg)
	gapDeg = gapDeg or 3
	local totalDeg = 360 / parts
	local startDeg = pos * totalDeg + gapDeg * 0.5
	local endDeg   = (pos + 1) * totalDeg - gapDeg * 0.5
	local startR = math.rad(startDeg - 90)
	local endR   = math.rad(endDeg   - 90)
	local lastX, lastY
	for i = 0, seg do
		local a = startR + (endR - startR) * (i / seg)
		local cx = x + math.cos(a) * rOuter
		local cy = y + math.sin(a) * rOuter
		if lastX then surface.DrawLine(lastX, lastY, cx, cy) end
		lastX, lastY = cx, cy
	end
	local inEndX = x + math.cos(endR) * rInner
	local inEndY = y + math.sin(endR) * rInner
	surface.DrawLine(lastX, lastY, inEndX, inEndY)
	lastX, lastY = inEndX, inEndY
	for i = seg, 0, -1 do
		local a = startR + (endR - startR) * (i / seg)
		local cx = x + math.cos(a) * rInner
		local cy = y + math.sin(a) * rInner
		if lastX then surface.DrawLine(lastX, lastY, cx, cy) end
		lastX, lastY = cx, cy
	end
	local outStartX = x + math.cos(startR) * rOuter
	local outStartY = y + math.sin(startR) * rOuter
	surface.DrawLine(lastX, lastY, outStartX, outStartY)
end

if IsValid(MENUPANELHUYHUY) then
	MENUPANELHUYHUY:Remove()
	MENUPANELHUYHUY = nil
end

hg.radialOptions = hg.radialOptions or {}

local colSegBase        = Color(8,   2,   2,   160)
local colSegHover       = Color(28,  6,   6,   210)
local colBorderBase     = Color(120, 120, 120, 80)
local colBorderHover    = Color(180, 180, 180, 220)
local colTextBase       = Color(190, 160, 160, 170)
local colTextHover      = Color(240, 215, 215, 255)
local colWhiteTransparent = Color(140, 30, 30, 90)
local colWhite          = Color(210, 185, 185, 255)
local colTransparent    = Color(0, 0, 0, 0)
local colOption         = Color(40, 0, 55, 152)

local RAD_INNER_FRAC = 0

local matHuy = Material("vgui/white")
local vecXY = Vector(0, 0)
local vecDown = Vector(0, 1)
local isMouseIntersecting = false
local isMouseOnRadial = false
local current_option = 1
local current_option_select = 1
local hook_Run = hook.Run

local incoentCol = Color(128,0,0)
local taitorCol = Color(155,0,0)

local menuPanel

local colBack = Color(0,0,0)
local surface, draw, hook, IsColor, IsValid, math, input = surface, draw, hook, IsColor, IsValid, math, input

local function CollectRadialOptions()
	table.Empty(hg.radialOptions)
	local keyDown = lply.KeyDown
	function lply:KeyDown(key)
		if key == IN_WALK then return true end
		return keyDown(self, key)
	end
	for _, func in SortedPairs(hook.GetTable()["radialOptions"]) do
		func()
	end
	lply.KeyDown = keyDown
end

local function CreateRadialMenu(options_arg, bAutoClose)
	local sizeX, sizeY = ScrW(), ScrH()
	hg.radialOptions = {}
	local paining = lply.organism and lply.organism.pain and (lply.organism.pain > 100 or lply.organism.brain > 0.2) or false
	
	if !options_arg then
		CollectRadialOptions()
	end

	local options1 = options_arg or hg.radialOptions

	hg.radialOptions = options1
	
	if IsValid(MENUPANELHUYHUY) then
		MENUPANELHUYHUY:Remove()
		MENUPANELHUYHUY = nil
	end

	local scrH, scrW = ScrH(), ScrW()

	MENUPANELHUYHUY = vgui.Create("DPanel")
	menuPanel = MENUPANELHUYHUY
	menuPanel:SetPos(scrW / 2 - sizeX / 2, scrH / 2 - sizeY / 2)
	menuPanel:SetSize(sizeX, sizeY)
	menuPanel:MakePopup()
	menuPanel:SetKeyBoardInputEnabled(false)
	menuPanel:SetAlpha(0)
	menuPanel:AlphaTo(255,0.2)
	menuPanel.bAutoClose = bAutoClose
	if !options_arg then input.SetCursorPos(sizeX / 2, sizeY / 2) end

	function menuPanel:Close()
		if not IsValid(menuPanel) then return end
		menuPanel:AlphaTo(0,0.1,0,function()
			if IsValid(menuPanel) then
				menuPanel:Remove()
				menuPanel = nil
			end
		end)
	end

	local thinkwait = 0
	if !options_arg then
		menuPanel.Think = function()
			if menuPanel:GetAlpha() < 255 then return end
			if thinkwait > CurTime() then return end
			thinkwait = CurTime() + 0.25
			CollectRadialOptions()
		end
	end
	
	local sizePan = 0
	local optionSelected = {}
	menuPanel.Paint = function(self, w, h)
		local mx, my = input.GetCursorPos()
		local cx, cy = w / 2, h / 2
		local dx = mx - sizeX / 2
		local dy = my - sizeY / 2
		vecXY.x = dx
		vecXY.y = dy
		local deg = (vecXY:GetNormalized() - vecDown):Angle()
		deg = math.NormalizeAngle((deg[2] - 180) * 2) + 180

		local options = {}
		if paining then
			options[#options + 1] = {function() RunConsoleCommand("hg_phrase") end, ""}
		else
			options = options1
		end

		sizePan = LerpFT(menuPanel:GetAlpha() > 100 and 0.05 or 0.25, sizePan, (menuPanel:GetAlpha() / 255))
		local viewLerp = Lerp(math.ease.OutExpo(sizePan), 0, 1)
		local panAlpha = menuPanel:GetAlpha() / 255

		local rOuter   = scrH * (options_arg ~= nil and 0.4 or 0.45) * viewLerp
		local rInner   = scrH * RAD_INNER_FRAC * viewLerp
		local sqrt     = math.sqrt(dx ^ 2 + dy ^ 2)
		local partDeg  = 360 / math.max(#options, 1)

		isMouseOnRadial = sqrt <= rOuter and sqrt > 2
		for num, option in ipairs(options) do
			local idx = num - 1
			isMouseIntersecting = isMouseOnRadial and deg > idx * partDeg and deg < (idx + 1) * partDeg
			if isMouseIntersecting then current_option = num end
			optionSelected[idx] = optionSelected[idx] or 0
			optionSelected[idx] = LerpFT(0.1, optionSelected[idx], isMouseIntersecting and 1 or 0)
		end

		local radialFont = options_arg and "ZCity_Veteran" or "ZCity_Veteran"
		for num, option in ipairs(options) do
			local idx = num - 1
			local sel = optionSelected[idx]

			local segColBase = colSegBase
			local segColHover = colSegHover
			if option[6] and IsColor(option[6]) then
				segColBase = option[6]
				if option[7] and IsColor(option[7]) then
					segColHover = option[7]
				else
					segColHover = Color(
						math.min(segColBase.r + 40, 255),
						math.min(segColBase.g + 40, 255),
						math.min(segColBase.b + 40, 255),
						segColBase.a
					)
				end
			end

			if option[3] then
				local segA = math.floor(Lerp(sel, segColBase.a, segColHover.a) * panAlpha)
				surface.SetMaterial(matHuy)
				surface.SetDrawColor(
					math.floor(Lerp(sel, segColBase.r, segColHover.r)),
					math.floor(Lerp(sel, segColBase.g, segColHover.g)),
					math.floor(Lerp(sel, segColBase.b, segColHover.b)),
					segA
				)
				draw.CirclePartRing(cx, cy, rInner, rOuter, 40, #options, idx, 3)

				local count = #option[4]
				local selectedPart = count - (math.floor((rOuter - sqrt) / (rOuter / count)))
				current_option_select = selectedPart
				for i, opt in pairs(option[4]) do
					local selected = selectedPart == i
					surface.SetMaterial(matHuy)
					if selected and isMouseIntersecting then
						surface.SetDrawColor(colWhiteTransparent.r, colWhiteTransparent.g, colWhiteTransparent.b, math.floor(colWhiteTransparent.a * panAlpha))
					else
						surface.SetDrawColor(0, 0, 0, 0)
					end
					local rA = rInner + (rOuter - rInner) * ((i - 1) / count)
					local rB = rInner + (rOuter - rInner) * (i / count)
					draw.CirclePartRing(cx, cy, rA, rB, 40, #options, idx, 3)

					local midDeg = idx * (360 / #options) + (360 / #options) / 2
					local midA = math.rad(midDeg - 90)
					local tRad = rInner + (rOuter - rInner) * (i / count - 0.5 / count)
					if paining then
						math.randomseed(math.Round(CurTime() / 5 + idx + i, 0))
						opt = ""
						math.randomseed(os.time())
					end
					draw.DrawText(opt, radialFont,
						scrW / 2 + math.cos(midA) * tRad,
						scrH / 2 + math.sin(midA) * tRad,
						Color(colWhite.r, colWhite.g, colWhite.b, math.floor(colWhite.a * panAlpha)),
						TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				continue
			end

			local hoverR = rOuter * (1 + 0.05 * sel)
			surface.SetMaterial(matHuy)
			surface.SetDrawColor(
				math.floor(Lerp(sel, segColBase.r, segColHover.r)),
				math.floor(Lerp(sel, segColBase.g, segColHover.g)),
				math.floor(Lerp(sel, segColBase.b, segColHover.b)),
				math.floor(Lerp(sel, segColBase.a, segColHover.a) * panAlpha)
			)
			draw.CirclePartRing(cx, cy, rInner, hoverR, 40, #options, idx, 3)

			surface.SetDrawColor(
				math.floor(Lerp(sel, colBorderBase.r, colBorderHover.r)),
				math.floor(Lerp(sel, colBorderBase.g, colBorderHover.g)),
				math.floor(Lerp(sel, colBorderBase.b, colBorderHover.b)),
				math.floor(Lerp(sel, colBorderBase.a, colBorderHover.a) * panAlpha)
			)
			draw.CirclePartRingOutline(cx, cy, rInner, hoverR, 40, #options, idx, 3)

			if sel > 0.05 then
				surface.SetDrawColor(
					math.floor(Lerp(sel, colBorderBase.r, colBorderHover.r)),
					math.floor(Lerp(sel, colBorderBase.g, colBorderHover.g)),
					math.floor(Lerp(sel, colBorderBase.b, colBorderHover.b)),
					math.floor(Lerp(sel, 0, 80) * panAlpha)
				)
				draw.CirclePartRingOutline(cx, cy, rInner - 1, hoverR + 1, 40, #options, idx, 3)
				draw.CirclePartRingOutline(cx, cy, rInner + 1, hoverR - 1, 40, #options, idx, 3)
			end

			if option[5] then
				local midDeg = idx * (360 / #options) + (360 / #options) / 2
				local midA = math.rad(midDeg - 90)
				local tRad = rInner + (hoverR - rInner) * 0.58

				surface.SetMaterial(option[5])
				surface.SetDrawColor(color_white)
				local sizeW = scrW / 2 + math.cos(midA) * tRad - scrW * 0.05
				local sizeH = scrH / 2 + math.sin(midA) * tRad - scrW * 0.05
				surface.DrawTexturedRect(sizeW, sizeH, scrW * 0.1, scrH * 0.1)
			else
				local midDeg = idx * (360 / #options) + (360 / #options) / 2
				local midA = math.rad(midDeg - 90)
				local tRad = rInner + (hoverR - rInner) * 0.58

				local txt = option[2]
				if paining then
					math.randomseed(math.Round(CurTime() / 5 + idx, 0))
					txt = hg.get_status_message(lply) or ""
					math.randomseed(os.time())
				end

				local mainTxt = txt
				local subTxt = nil
				if txt and string.find(txt, "\n") then
					local nl = string.find(txt, "\n")
					mainTxt = string.sub(txt, 1, nl - 1)
					subTxt  = string.sub(txt, nl + 1)
				end

				local tx = scrW / 2 + math.cos(midA) * tRad
				local ty = scrH / 2 + math.sin(midA) * tRad

				local flashRed = 0
				if sel > 0 then
					flashRed = (math.sin(CurTime() * 10) * 0.5 + 0.5) * sel
				end

				local textColR = math.floor(Lerp(flashRed, Lerp(sel, colTextBase.r, colTextHover.r), 255))
				local textColG = math.floor(Lerp(flashRed, Lerp(sel, colTextBase.g, colTextHover.g), 0))
				local textColB = math.floor(Lerp(flashRed, Lerp(sel, colTextBase.b, colTextHover.b), 0))

				draw.DrawText(mainTxt, radialFont, tx, subTxt and ty - 12 or ty,
					Color(
						textColR,
						textColG,
						textColB,
						math.floor(Lerp(sel, colTextBase.a, colTextHover.a) * panAlpha)
					), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if subTxt then
					draw.DrawText(subTxt, radialFont, tx, ty + 28,
						Color(
							textColR,
							textColG,
							textColB,
							math.floor(Lerp(sel, colTextBase.a, colTextHover.a) * panAlpha * 0.7)
						), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end

			if idx == 0 and not paining then
				draw.SimpleText(lply:GetPlayerName(), "HomigradFontGigantoNormous",
					scrW * 0.0215 * viewLerp, scrH * 0.042, colBack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText((lply.role and lply.role.name) or "", "HomigradFontGigantoNormous",
					scrW * 0.0215 * viewLerp, scrH * 0.098, colBack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				local col = lply:GetPlayerColor():ToColor()
				draw.SimpleText(lply:GetPlayerName(), "HomigradFontGigantoNormous",
					scrW * 0.02 * viewLerp, scrH * 0.04, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText((lply.role and lply.role.name) or "", "HomigradFontGigantoNormous",
					scrW * 0.02 * viewLerp, scrH * 0.095,
					lply.role and lply.role.color or incoentCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end
end

local function PressRadialMenu(mouseClick)
	local options = hg.radialOptions
	hook_Run("RadialMenuPressed")

	local needed_mouseclick
	if IsValid(menuPanel) and options[current_option] and isMouseOnRadial then
		local func = options[current_option][1]
		if isfunction(func) then needed_mouseclick = func(mouseClick, current_option_select) end
	end

	if needed_mouseclick != -1 and IsValid(menuPanel) and mouseClick != (needed_mouseclick or 2) and not menuPanel.bAutoClose then
		menuPanel:Close()
	end
end

hg.CreateRadialMenu = CreateRadialMenu
hg.PressRadialMenu = PressRadialMenu

local firstTime = true
local firstTime2 = true
local firstTime3 = true
local firstTime4 = true
local firstTime5 = true
local firstTime6 = true

hook.Add("HG_OnOtrub", "resetshit", function(ply)
	if ply == lply then
		hook_Run("RadialMenuPressed")

		if IsValid(menuPanel) then
			menuPanel:Close()
		end
	end
end)

hook.Add("PlayerBindPress", "PlayerBindPressExample2huy", function(ply, bind, pressed)
	if string.find(bind, "+menu") then
		if (lply.organism and lply.organism.otrub) then
			return (bind == "+menu") or nil
		end

		if (bind == "+menu") then
			if pressed and !IsValid(MENUPANELHUYHUY) then
				CreateRadialMenu()
			else
				PressRadialMenu(1)
			end
		else
			if lply:IsAdmin() then return end
		end

		return true
	end
end)

hook.Add("Think", "hg-radial-menu", function()
	if (lply.organism and lply.organism.otrub) then
		if IsValid(menuPanel) then
			hook_Run("RadialMenuPressed")
			menuPanel:Close()
		end
		return
	end

	if (engine.ActiveGamemode() ~= "sandbox" and input.IsKeyDown(KEY_Q)) or (engine.ActiveGamemode() == "sandbox" and input.IsKeyDown(KEY_C)) then
		if firstTime then
			firstTime = false
		end
		firstTime4 = true
	else
		if firstTime4 then
			firstTime4 = false
		end
		firstTime = true
	end

	if input.IsMouseDown(MOUSE_LEFT) then
		if firstTime2 then
			firstTime2 = false
		end
		firstTime3 = true
	else
		if firstTime3 then
			firstTime3 = false
			PressRadialMenu(1)
		end
		firstTime2 = true
	end

	if input.IsMouseDown(MOUSE_RIGHT) then
		if firstTime5 then
			firstTime5 = false
		end
		firstTime6 = true
	else
		if firstTime6 then
			firstTime6 = false
			PressRadialMenu(2)
		end
		firstTime5 = true
	end

	-- Auto-open inventory when self-inspection (admire) starts
	if lply ~= nil and lply:GetNWBool("mcd_admiring", false) and not lply.__CaseInvOpenedByAdmire then
		lply.__CaseInvOpenedByAdmire = true -- prevent repeated opens while already admiring
		RunConsoleCommand("case_open")
	elseif lply ~= nil and not lply:GetNWBool("mcd_admiring", false) then
		lply.__CaseInvOpenedByAdmire = nil -- reset flag so next admire re-opens
	end
end)

local function dropWeapon()
	RunConsoleCommand("drop")
end

local function suicide()
	RunConsoleCommand("suicide")
end

local function shovePlayer()
	RunConsoleCommand("hg_shove")
end

hook.Add("radialOptions", "77", function()
	local organism = lply.organism or {}
	if not organism.otrub and IsValid(lply:GetActiveWeapon()) and lply:GetActiveWeapon():GetClass() ~= "weapon_hands_sh" then
		local tbl = {dropWeapon, "Бросить оружие"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

hook.Add("radialOptions", "88", function()
	local organism = lply.organism or {}
	if not organism.otrub and hg.CanStartSuicide(lply) then
		local tbl = {suicide, "Смерть"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

hook.Add("radialOptions", "89", function()
	local organism = lply.organism or {}
	local wep = lply:GetActiveWeapon()
	if not lply:Alive() then return end
	if organism.otrub then return end
	if not IsValid(wep) or wep:GetClass() ~= "weapon_hands_sh" then return end
	local tr = hg.eyeTrace(lply, 90)
	if not tr or not IsValid(tr.Entity) then return end
	local ent = tr.Entity
	local isHuman = (ent:IsPlayer() and ent ~= lply and ent:Alive()) or ent:IsNPC()
	local class = ent:GetClass()
	local isProp = class == "prop_physics" or class == "prop_physics_multiplayer"
	if not isHuman and not isProp then return end
	hg.radialOptions[#hg.radialOptions + 1] = {shovePlayer, "Толкнуть"}
end)

hook.Add("radialOptions", "Afflictions", function()
	local ply = LocalPlayer()
	local organism = ply.organism or {}
	if ply:Alive() and not organism.otrub and hg.GetCurrentCharacter(ply) == ply then
		local tbl = {function()
			if ply:GetNWBool("mcd_admiring", false) then
				RunConsoleCommand("mcd_admire", "cancel")
			else
				RunConsoleCommand("mcd_admire")
			end
		end, ply:GetNWBool("mcd_admiring", false) and "Закончить осмотр" or "Осмотреть себя"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

local randomGestures = {
	{"Привет", function() RunConsoleCommand("hg_hand_gesture", "ofges_hello") end},
	{"Подожди", function() RunConsoleCommand("hg_hand_gesture", "ofges_wait") end},
	{"Вперёд", function() RunConsoleCommand("hg_hand_gesture", "ofges_omw") end},
	{"Ко мне", function() RunConsoleCommand("hg_hand_gesture", "ofges_help") end},
	{"Осторожно", function() RunConsoleCommand("hg_hand_gesture", "ofges_danger") end},
	{"Указать", function() RunConsoleCommand("hg_hand_gesture", "point") end},
	{"Палец вверх", function() RunConsoleCommand("hg_hand_gesture", "thumb_up") end},
	{"Пошёл ты", function() RunConsoleCommand("hg_hand_gesture", "fuckyou") end},
	{"Перегруппировка", function() RunConsoleCommand("hg_hand_gesture", "ofges_regroup") end},
}

concommand.Add("hg_randomgesture",function()
	randomGesture()
end)

hook.Add("radialOptions", "7", function()
	local ply = LocalPlayer()
	local organism = ply.organism or {}
	if ply:Alive() and not organism.otrub and hg.GetCurrentCharacter(ply) == ply then
		if ply.GetPlayerClass and ply:GetPlayerClass() and ply:GetPlayerClass().CanUseGestures ~= nil and not ply:GetPlayerClass().CanUseGestures then return end
		local tbl = {function(mouseClick)
			if mouseClick == 1 then
				RunConsoleCommand("act", randomGestures[math.random(#randomGestures)])
				if (ply.NextFoley or 0) < CurTime() then
					ply:EmitSound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav", 55)
					ply.NextFoley = CurTime() + 1
				end
			else
				local commands = {}
				for i, str in ipairs(randomGestures) do
					commands[i] = {
						[1] = function()
							if istable(str) then
								str[2]()
							else
								RunConsoleCommand("act", str)
								if (ply.NextFoley or 0) < CurTime() then
									ply:EmitSound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav", 55)
									ply.NextFoley = CurTime() + 1
								end
							end
						end,
						[2] = string.NiceName(istable(str) and str[1] or str)
					}
				end
				CreateRadialMenu(commands)
			end
		end, "Жест\nПКМ - Меню"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

local healthModel
local blinkModel
local whiteMat = Material("models/debug/debugwhite")
local statusCircleMat = Material("sef_icons/statuseffectcircle.png", "smooth")
local statusIconCache = {}

local IND_SIZE_BASE = 120
local IND_SIZE_MAX = 170
local BACKDROP_OFFSET_X = -20
local BACKDROP_OFFSET_Y = 37
local ICONS_SCREEN_EDGE_MARGIN = 20
local ICONS_SCREEN_MARGIN_Y = 18
local PULSE_DURATION = 8
local BLINK_SCALE = Vector(1.05, 1.05, 1.05)
local BLINK_DURATION = 5
local FRACTURE_BLINK_SPEED = 10
local POS_VISIBLE_X = 0
local POS_HIDDEN_X = -400

local currentX = nil
local pulseStartTime = 0
local limbStates = {}
local boneCache = {}
local lastLifeState = nil
local iconsVisibility = 0
local iconsAppearTime = 0
local iconsTargetVisible = false
local cachedAfflictionIcons = {}

local limbBones = {
	lleg = "ValveBiped.Bip01_L_Thigh",
	rleg = "ValveBiped.Bip01_R_Thigh",
	larm = "ValveBiped.Bip01_L_UpperArm",
	rarm = "ValveBiped.Bip01_R_UpperArm"
}

local amputationBones = {
	lleg = "ValveBiped.Bip01_L_Calf",
	rleg = "ValveBiped.Bip01_R_Calf",
	larm = "ValveBiped.Bip01_L_Forearm",
	rarm = "ValveBiped.Bip01_R_Forearm"
}

local function ScreenScaleFixed(size)
	return size * (ScrH() / 480)
end

local function ScaleBoneAndChildren(ent, boneID, scale)
	ent:ManipulateBoneScale(boneID, scale)
	local children = ent:GetChildBones(boneID)
	for _, child in ipairs(children) do
		ScaleBoneAndChildren(ent, child, scale)
	end
end

local function InitBlinkModel(ent)
	ent:SetupBones()
	for i = 0, ent:GetBoneCount() - 1 do
		ent:ManipulateBoneScale(i, Vector(0, 0, 0))
	end
end

local function ResetModels(ply)
	if IsValid(healthModel) then
		if healthModel.accessories then
			for _, v in pairs(healthModel.accessories) do
				if IsValid(v) then v:Remove() end
			end
		end
		healthModel:Remove()
	end
	if IsValid(blinkModel) then
		blinkModel:Remove()
	end
	healthModel = nil
	blinkModel = nil
	limbStates = {}
	pulseStartTime = 0
	iconsVisibility = 0
	iconsAppearTime = 0
	iconsTargetVisible = false
	cachedAfflictionIcons = {}
end

local function DrawHealthAccessories(healthModel, ply)
	local accessories = ply:GetNetVar("Accessories")
	if not accessories then
		if healthModel.accessories then
			for k, v in pairs(healthModel.accessories) do
				if IsValid(v) then v:Remove() end
			end
			healthModel.accessories = nil
		end
		return
	end
	
	healthModel.accessories = healthModel.accessories or {}
	local accList = istable(accessories) and accessories or {accessories}
	local currentAccs = {}
	for _, accName in pairs(accList) do
		currentAccs[accName] = true
		local accessData = hg.Accessories[accName]
		if not accessData then continue end
		if accessData.norender then continue end

		if accessData.allowedSteamIDs then
			local steamID = ply:SteamID()
			local hasAccess = false
			for _, allowedID in ipairs(accessData.allowedSteamIDs) do
				if steamID == allowedID then
					hasAccess = true
					break
				end
			end
			if not hasAccess then continue end
		end
		
		local model = healthModel.accessories[accName]
		local isFemale = false
		if hg.Appearance.FuckYouModels and hg.Appearance.FuckYouModels[2][healthModel:GetModel()] then
			isFemale = true
		end
		
		if not IsValid(model) then
			local modelPath = isFemale and accessData.femmodel or accessData.model
			if not modelPath then continue end
			
			model = ClientsideModel(modelPath, RENDERGROUP_OTHER)
			model:SetNoDraw(true)
			model:SetModelScale(accessData[isFemale and "fempos" or "malepos"][3])
			
			local skin = accessData.skin
			if isfunction(skin) then skin = skin(healthModel) end
			model:SetSkin(skin or 0)
			model:SetBodyGroups(accessData.bodygroups or "")
			
			if accessData.bonemerge then
				model:AddEffects(EF_BONEMERGE)
			end
			
			if accessData.bSetColor then
				local col = ply:GetPlayerColor() or Vector(1,1,1)
				model:SetColor(col:ToColor())
			end
			
			if accessData.SubMat then
				model:SetSubMaterial(0, accessData.SubMat)
			end
			healthModel.accessories[accName] = model
		end
		
		local boneName = accessData.bone
		local bone = healthModel:LookupBone(boneName)
		if bone then
			local matrix = healthModel:GetBoneMatrix(bone)
			if matrix then
				local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
				local posData = accessData[isFemale and "fempos" or "malepos"]
				local localPos, localAng = posData[1], posData[2]
				local pos, ang = LocalToWorld(localPos, localAng, bonePos, boneAng)
				model:SetRenderOrigin(pos)
				model:SetRenderAngles(ang)
				if model:GetParent() ~= healthModel then
					model:SetParent(healthModel, bone)
				end
				model:DrawModel()
			end
		end
	end
	for name, model in pairs(healthModel.accessories) do
		if not currentAccs[name] then
			if IsValid(model) then model:Remove() end
			healthModel.accessories[name] = nil
		end
	end
end

local function GetOrgValueNumber(value)
	if type(value) == "number" then return value end
	if type(value) == "table" then
		if type(value[1]) == "number" then return value[1] end
		if type(value.cur) == "number" then return value.cur end
		if type(value.value) == "number" then return value.value end
	end
	return 0
end

local function GetStatusIcon(iconName)
	local cached = statusIconCache[iconName]
	if cached ~= nil then
		return cached or nil
	end
	local mat = Material("sef_icons/" .. iconName .. ".png", "smooth")
	if mat:IsError() then
		statusIconCache[iconName] = false
		return nil
	end
	statusIconCache[iconName] = mat
	return mat
end

local function CollectAfflictionIcons(ply, org)
	local icons = {}
	local seen = {}
	local function add(iconName, severity)
		severity = math.Clamp(severity or 0.5, 0.05, 1)
		if seen[iconName] then
			seen[iconName].severity = math.max(seen[iconName].severity, severity)
			return
		end
		local mat = GetStatusIcon(iconName)
		if not mat then return end
		local entry = {mat = mat, severity = severity}
		seen[iconName] = entry
		icons[#icons + 1] = entry
	end

	if not org then
		return icons
	end

	local wounds = ply.wounds or ply:GetNetVar("wounds")
	local arterialwounds = ply.arterialwounds or ply:GetNetVar("arterialwounds")
	local woundsCount = istable(wounds) and #wounds or 0
	local arterialCount = istable(arterialwounds) and #arterialwounds or 0

	if woundsCount > 0 then
		add("open-wound", math.min(1, woundsCount / 6))
	end
	if arterialCount > 0 then
		add("deepwound", math.min(1, 0.7 + arterialCount * 0.2))
	end
	local bleed = GetOrgValueNumber(org.bleed)
	if bleed > 0 then
		add("bleed", math.min(1, bleed / 8))
	end
	local hasBrokenLimb = (org.lleg and org.lleg >= 1) or (org.rleg and org.rleg >= 1) or (org.larm and org.larm >= 1) or (org.rarm and org.rarm >= 1)
	local hasDislocation = org.llegdislocation or org.rlegdislocation or org.larmdislocation or org.rarmdislocation or org.jawdislocation
	local hasAmputation = org.llegamputated or org.rlegamputated or org.larmamputated or org.rarmamputated or org.headamputated
	if hasBrokenLimb or hasDislocation or hasAmputation then
		local sev = hasAmputation and 1 or (hasDislocation and 0.65 or 0.5)
		add("vuln", sev)
	end
	local concussion = GetOrgValueNumber(org.concussion)
	if concussion > 0 then
		add("concussion", math.min(1, concussion))
	end
	if org.blindness then
		add("blind", 0.7)
	end
	local assimilated = GetOrgValueNumber(org.assimilated)
	if assimilated > 0 then
		add("wither", math.min(1, assimilated))
	end
	if org.incapacitated then
		add("incap", 1)
	end
	if org.berserkActive2 then
		add("bloodlust", 0.45)
	end
	if org.noradrenalineActive then
		add("haste", 0.45)
	end
	local despair = GetOrgValueNumber(org.despair)
	if despair > 0.25 then
		add("anagenthasdied", math.min(1, despair))
	end
	if org.critical then
		add("warning", 1)
	end
	if (not org.canmove) or GetOrgValueNumber(org.immobilization) > 0 then
		add("hindered", 0.65)
	end
	if GetOrgValueNumber(org.pain) > 60 or GetOrgValueNumber(org.shock) > 0.5 then
		add("stunned", math.min(1, math.max(GetOrgValueNumber(org.pain) / 120, GetOrgValueNumber(org.shock))))
	end
	if GetOrgValueNumber(org.CO) > 0.1 then
		add("poison-gas", math.min(1, GetOrgValueNumber(org.CO) / 4))
	end
	local o2 = GetOrgValueNumber(org.o2)
	if o2 > 0 and o2 < 20 then
		add("exhaust", math.min(1, (20 - o2) / 20))
	end
	local temperature = GetOrgValueNumber(org.temperature)
	if temperature > 39 then
		add("discharge", math.min(1, (temperature - 39) / 2))
	elseif temperature > 0 and temperature < 34.5 then
		add("frozen", math.min(1, (34.5 - temperature) / 3))
	end
	return icons
end

local function DrawAfflictionIcons(iconEntries, centerX, bottomY, visibility, appearTime, timeNow)
	if not iconEntries or #iconEntries == 0 or visibility <= 0.01 then return end

	local iconSize = math.max(math.floor(ScreenScaleFixed(26)), 18)
	local bgSize = math.max(math.floor(iconSize * 1.35), iconSize + 8)
	local spacing = math.max(math.floor(ScreenScaleFixed(2)), 1)
	local horizontalSpace = ScrW() - ScreenScaleFixed(ICONS_SCREEN_EDGE_MARGIN) * 2
	local maxPerRow = math.max(1, math.floor((horizontalSpace + spacing) / (bgSize + spacing)))
	local rows = math.ceil(#iconEntries / maxPerRow)
	local appearFrac = math.Clamp((timeNow - (appearTime or timeNow)) / 0.35, 0, 1)
	local shakeMul = (1 - appearFrac) * visibility
	local baseAlpha = math.floor(255 * visibility)

	for row = 1, rows do
		local rowStart = (row - 1) * maxPerRow + 1
		local rowCount = math.min(maxPerRow, #iconEntries - rowStart + 1)
		local rowWidth = rowCount * bgSize + (rowCount - 1) * spacing
		local x = centerX - rowWidth * 0.5
		local y = bottomY - row * bgSize - (row - 1) * spacing
		if y < 0 then
			break
		end
		for col = 1, rowCount do
			local idx = rowStart + col - 1
			local entry = iconEntries[idx]
			local severity = entry.severity or 0.5
			local pulse = 1 + math.sin(timeNow * (4 + severity * 9) + idx * 1.4) * (0.05 + severity * 0.08) * visibility
			local shakeAmp = ScreenScaleFixed(2 + severity * 2) * shakeMul
			local shakeX = math.sin(timeNow * (95 + idx * 7)) * shakeAmp
			local shakeY = math.cos(timeNow * (110 + idx * 9)) * shakeAmp
			local drawX = x + (col - 1) * (bgSize + spacing)
			local drawY = y
			local centerDrawX = drawX + bgSize * 0.5 + shakeX
			local centerDrawY = drawY + bgSize * 0.5 + shakeY
			local bgDrawSize = bgSize * pulse
			local iconDrawSize = iconSize * pulse
			local bgAlpha = math.floor((160 + severity * 95) * visibility)

			surface.SetMaterial(statusCircleMat)
			surface.SetDrawColor(8, 8, 8, bgAlpha)
			surface.DrawTexturedRect(centerDrawX - bgDrawSize * 0.5, centerDrawY - bgDrawSize * 0.5, bgDrawSize, bgDrawSize)

			surface.SetMaterial(entry.mat)
			surface.SetDrawColor(255, 255, 255, baseAlpha)
			surface.DrawTexturedRect(centerDrawX - iconDrawSize * 0.5, centerDrawY - iconDrawSize * 0.5, iconDrawSize, iconDrawSize)
		end
	end
end

hook.Add("HUDPaint", "HG_HealthIndicator", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	local alive = ply:Alive()
	if lastLifeState ~= alive then
		ResetModels(ply)
		lastLifeState = alive
	end
	
	if not alive then return end
	if gui.IsGameUIVisible() then return end
	
	if not IsValid(healthModel) then
		healthModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
		healthModel:SetNoDraw(true)
		healthModel:SetIK(false)
		local seq = healthModel:LookupSequence("idle_suitcase")
		if seq then
			healthModel:SetSequence(seq)
			healthModel:SetCycle(0)
		end
	end
	
	if not IsValid(blinkModel) then
		blinkModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
		blinkModel:SetNoDraw(true)
		blinkModel:SetIK(false)
		local seq = blinkModel:LookupSequence("idle_suitcase")
		if seq then
			blinkModel:SetSequence(seq)
			blinkModel:SetCycle(0)
		end
		InitBlinkModel(blinkModel)
	end

	if healthModel:GetModel() ~= ply:GetModel() then
		healthModel:SetModel(ply:GetModel())
		blinkModel:SetModel(ply:GetModel())
		local seq = healthModel:LookupSequence("idle_suitcase")
		if seq then
			healthModel:SetSequence(seq)
			healthModel:SetCycle(0)
		end
		local seq2 = blinkModel:LookupSequence("idle_suitcase")
		if seq2 then
			blinkModel:SetSequence(seq2)
			blinkModel:SetCycle(0)
		end
		InitBlinkModel(blinkModel)
		limbStates = {}
		if healthModel.accessories then
			for _, v in pairs(healthModel.accessories) do
				if IsValid(v) then v:Remove() end
			end
			healthModel.accessories = nil
		end
	end

	local consciousness = 1
	local otrub = false
	local org = ply.organism
	
	if org then
		if org.consciousness then consciousness = org.consciousness end
		if org.otrub then otrub = org.otrub end
	end
	
	local time = CurTime()
	local admiring = ply:GetNWBool("mcd_admiring", false) and not ply.mcd_admire_local_cancel
	local shouldShowIndicator = admiring and not otrub

	if org then
		for limb, boneName in pairs(limbBones) do
			local isAmputated = org[limb .. "amputated"]
			local isBroken = (org[limb] and org[limb] >= 1)
			local isDislocated = org[limb .. "dislocation"]
			
			if not limbStates[limb] then
				limbStates[limb] = {
					amputated = false,
					blinking = false,
					blinkEnd = 0,
					fractured = false
				}
			end
			
			local state = limbStates[limb]
			local ampBoneName = amputationBones[limb] or boneName
			
			if state.amputated and not isAmputated then
				state.amputated = false
				state.blinking = false
				local boneID = healthModel:LookupBone(ampBoneName)
				if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
				local blinkBoneID = blinkModel:LookupBone(ampBoneName)
				if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
			end
			
			if state.fractured and not (isBroken or isDislocated) then
				state.fractured = false
				if not state.amputated then
					local blinkBoneID = blinkModel:LookupBone(boneName)
					if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
					local boneID = healthModel:LookupBone(boneName)
					if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
				end
			end

			if isAmputated then
				if state.fractured then
					 state.fractured = false
					 local blinkBoneID = blinkModel:LookupBone(boneName)
					 if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
					 local boneID = healthModel:LookupBone(boneName)
					 if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
				end
				if not state.amputated then
					state.amputated = true
					state.blinking = true
					state.blinkEnd = time + BLINK_DURATION
					pulseStartTime = time
					local boneID = healthModel:LookupBone(ampBoneName)
					if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
					local blinkBoneID = blinkModel:LookupBone(ampBoneName)
					if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
				end
				if state.blinking and time > state.blinkEnd then
					state.blinking = false
					local blinkBoneID = blinkModel:LookupBone(ampBoneName)
					if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
				end
			elseif (isBroken or isDislocated) then
				if not state.fractured then
					state.fractured = true
					pulseStartTime = time
					local blinkBoneID = blinkModel:LookupBone(boneName)
					if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
					local boneID = healthModel:LookupBone(boneName)
					if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
				end
			end
		end
	end

	local targetX = shouldShowIndicator and POS_VISIBLE_X or POS_HIDDEN_X
	local targetXScaled = ScreenScaleFixed(targetX)
	if not currentX then currentX = ScreenScaleFixed(POS_HIDDEN_X) end
	currentX = Lerp(FrameTime() * 2, currentX, targetXScaled)
	local size = IND_SIZE_BASE
	local w, h = ScreenScaleFixed(size), ScreenScaleFixed(size)
	local y = ScrH() - h - ScreenScaleFixed(20)
	local camPos = Vector(95, 0, 65)
	local lookAng = Angle(11, 180, 0)

	local renderX = currentX
	local SILHOUETTE_OFFSET_X = -15
	local SILHOUETTE_OFFSET_Y = 15
	local viewX = renderX + ScreenScaleFixed(SILHOUETTE_OFFSET_X)
	local viewY = y + ScreenScaleFixed(SILHOUETTE_OFFSET_Y)
	local modelOffset = Vector(0, 0, 0)
	local backdropX = currentX + ScreenScaleFixed(BACKDROP_OFFSET_X)
	local backdropY = y + ScreenScaleFixed(BACKDROP_OFFSET_Y)
	local backdropW = w * 0.92
	local backdropH = h * 0.92
	draw.RoundedBox(6, backdropX, backdropY, backdropW, backdropH, Color(0, 0, 0, 90))
	surface.SetDrawColor(120, 120, 120, 170)
	surface.DrawOutlinedRect(backdropX, backdropY, backdropW, backdropH, 1)
	if shouldShowIndicator then
		cachedAfflictionIcons = CollectAfflictionIcons(ply, org)
		if not iconsTargetVisible then
			iconsAppearTime = time
		end
	end

	iconsVisibility = Lerp(FrameTime() * 10, iconsVisibility, shouldShowIndicator and 1 or 0)
	iconsTargetVisible = shouldShowIndicator

	if iconsVisibility > 0.01 and #cachedAfflictionIcons > 0 then
		local iconsX = ScrW() * 0.5
		local iconsBottom = ScrH() - ScreenScaleFixed(ICONS_SCREEN_MARGIN_Y)
		DrawAfflictionIcons(cachedAfflictionIcons, iconsX, iconsBottom, iconsVisibility, iconsAppearTime, time)
	elseif not shouldShowIndicator and iconsVisibility <= 0.01 then
		cachedAfflictionIcons = {}
	end
	local camRenderX = viewX
	if camRenderX < 0 then
		local dist = camPos.x
		local fov = 50
		local visibleHeight = 2 * dist * math.tan(math.rad(fov) / 2)
		local unitsPerPixel = visibleHeight / h
		local pixelShift = camRenderX
		local unitShift = pixelShift * unitsPerPixel
		modelOffset = Vector(0, unitShift, 0)
		camRenderX = 0
	end

	cam.Start3D(camPos, lookAng, 50, camRenderX, viewY, w, h)
		render.SuppressEngineLighting(true)
		render.MaterialOverride(whiteMat)
		local col = math.Clamp(consciousness, 0, 1)
		render.SetColorModulation(col, col, col)
		healthModel:SetPos(modelOffset)
		healthModel:SetAngles(Angle(0, 0, 0))
		for i = 0, ply:GetNumBodyGroups() - 1 do
			healthModel:SetBodygroup(i, ply:GetBodygroup(i))
		end
		healthModel:SetSkin(ply:GetSkin())
		healthModel:SetupBones()
		healthModel:DrawModel()
		DrawHealthAccessories(healthModel, ply)
		
		local hasAmputationBlink = false
		local hasFractureBlink = false
		for _, state in pairs(limbStates) do
			if state.blinking then hasAmputationBlink = true end
			if state.fractured then hasFractureBlink = true end
		end
		
		if hasAmputationBlink then
			local val = (math.sin(time * 10) + 1) / 2
			render.SetColorModulation(val, 0, 0)
			if hasFractureBlink then
				for l, s in pairs(limbStates) do
					if s.fractured then
						local bID = blinkModel:LookupBone(limbBones[l])
						if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
					end
				end
			end
			blinkModel:SetPos(modelOffset)
			blinkModel:SetAngles(Angle(0, 0, 0))
			blinkModel:SetupBones()
			blinkModel:DrawModel()
			if hasFractureBlink then
				for l, s in pairs(limbStates) do
					if s.fractured then
						local bID = blinkModel:LookupBone(limbBones[l])
						if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
					end
				end
			end
		end
		
		if hasFractureBlink then
			local val = (math.sin(time * FRACTURE_BLINK_SPEED) + 1) / 2
			render.SetColorModulation(val, 0, 0)
			if hasAmputationBlink then
				for l, s in pairs(limbStates) do
					if s.blinking then
						local ampBoneName = amputationBones[l] or limbBones[l]
						local bID = blinkModel:LookupBone(ampBoneName)
						if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
					end
				end
			end
			blinkModel:SetPos(modelOffset)
			blinkModel:SetAngles(Angle(0, 0, 0))
			blinkModel:SetupBones()
			blinkModel:DrawModel()
			if hasAmputationBlink then
				for l, s in pairs(limbStates) do
					if s.blinking then
						local ampBoneName = amputationBones[l] or limbBones[l]
						local bID = blinkModel:LookupBone(ampBoneName)
						if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
					end
				end
			end
		end
		render.MaterialOverride(nil)
		render.SetColorModulation(1, 1, 1)
		render.SuppressEngineLighting(false)
	cam.End3D()
end)

hook.Add("OnRemove", "HG_CleanupHealthIndicator", function() if IsValid(healthModel) then healthModel:Remove() end if IsValid(blinkModel) then blinkModel:Remove() end end)

local observe_state = {
	active = false,
	stage = 1,
	stage_start = 0,
	target = nil,
	data_target = nil,
	last_health = 0,
	last_hurt = 0,
	last_painadd = 0,
	was_alive = true,
	require_admire_reset = false
}
local observe_parts = {"Arms", "Torso", "Legs"}
local observe_stage_time = 4.5
local observe_text_delay = 1.8
local observe_type_speed = 28
local observe_line_color = Color(0, 0, 0, 255)
local observe_box_color = Color(0, 0, 0, 220)
local observe_text_color = Color(255, 255, 255, 255)
local observe_line_screen = 50
local observe_line_screen_up = 22
local observe_font = "ZCity_Veteran"

local observe_bone_sets = {
	Arms = {
		{
			label = "Левая рука",
			bones = {"ValveBiped.Bip01_L_Forearm"},
			side = -1,
			offset = 12,
			fracture_keys = {"larm"},
			dis_key = "larmdislocation",
			hitgroups = {[HITGROUP_LEFTARM] = true}
		},
		{
			label = "Правая рука",
			bones = {"ValveBiped.Bip01_R_Forearm"},
			side = 1,
			offset = 12,
			fracture_keys = {"rarm"},
			dis_key = "rarmdislocation",
			hitgroups = {[HITGROUP_RIGHTARM] = true}
		}
	},
	Torso = {
		{
			label = "Туловище",
			bones = {"ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Pelvis"},
			side = 1,
			offset = 12,
			fracture_keys = {"chest", "spine1", "spine2", "spine3", "pelvis", "brokenribs"},
			hitgroups = {
				[HITGROUP_CHEST] = true,
				[HITGROUP_STOMACH] = true,
				[HITGROUP_GENERIC] = true
			}
		}
	},
	Legs = {
		{
			label = "Левая нога",
			bones = {"ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_L_Foot"},
			side = -1,
			fracture_keys = {"lleg"},
			dis_key = "llegdislocation",
			hitgroups = {[HITGROUP_LEFTLEG] = true}
		},
		{
			label = "Правая нога",
			bones = {"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Foot"},
			side = 1,
			fracture_keys = {"rleg"},
			dis_key = "rlegdislocation",
			hitgroups = {[HITGROUP_RIGHTLEG] = true}
		}
	}
}

local function get_observe_target(ply, admiring)
	local fake = (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll) or (IsValid(ply:GetNWEntity("FakeRagdoll")) and ply:GetNWEntity("FakeRagdoll"))
	if IsValid(fake) then
		return fake, ply
	end
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.CarryEnt and IsValid(wep.CarryEnt) then
		if wep.CarryEnt:IsRagdoll() then
			local owner = hg.RagdollOwner(wep.CarryEnt)
			return wep.CarryEnt, (IsValid(owner) and owner or wep.CarryEnt)
		end
		if wep.CarryEnt:IsPlayer() then
			return wep.CarryEnt, wep.CarryEnt
		end
	end
	local carry = ply:GetNetVar("carryent")
	if IsValid(carry) then
		if carry:IsRagdoll() then
			local owner = hg.RagdollOwner(carry)
			return carry, (IsValid(owner) and owner or carry)
		end
		if carry:IsPlayer() then
			if IsValid(carry.FakeRagdoll) then
				return carry.FakeRagdoll, carry
			end
			return carry, carry
		end
	end
	local tr = hg.eyeTrace(ply, 120)
	if tr and IsValid(tr.Entity) then
		local ent = tr.Entity
		if ent:IsRagdoll() then
			local owner = hg.RagdollOwner(ent)
			return ent, (IsValid(owner) and owner or ent)
		end
		if ent:IsPlayer() then
			if IsValid(ent.FakeRagdoll) then
				return ent.FakeRagdoll, ent
			end
			return ent, ent
		end
	end
	if admiring then
		return ply, ply
	end
end

local function get_hitgroup(ent, bone)
	if not bone then return end
	if not hg or not hg.bonetohitgroup then return end
	local bonename = bone
	if isnumber(bone) and IsValid(ent) then
		bonename = ent:GetBoneName(bone)
	end
	return bonename and hg.bonetohitgroup[bonename] or nil
end

local function count_wounds_for_groups(ent, wounds, groups)
	local count = 0
	if wounds then
		for i = 1, #wounds do
			local bone = wounds[i][4]
			local hitgroup = get_hitgroup(ent, bone)
			if hitgroup and groups[hitgroup] then
				count = count + 1
			end
		end
	end
	return count
end

local function count_arterial_for_groups(ent, arterialwounds, groups)
	local count = 0
	if arterialwounds then
		for i = 1, #arterialwounds do
			local bone = arterialwounds[i][4]
			local hitgroup = get_hitgroup(ent, bone)
			if hitgroup and groups[hitgroup] then
				count = count + 1
			end
		end
	end
	return count
end

local function has_fracture(org, keys)
	for i = 1, #keys do
		local key = keys[i]
		if key == "brokenribs" then
			if org.brokenribs and org.brokenribs > 0 then
				return true
			end
		else
			local v = org[key]
			if v then
				local threshold = 1
				if hg and hg.organism then
					local fake_key = hg.organism["fake_" .. key]
					if fake_key then
						threshold = fake_key
					end
				end
				if v >= threshold then
					return true
				end
			end
		end
	end
	return false
end

local function get_bleeding_label(count)
	if count <= 0 then return nil end
	if count == 1 then return "Слабое кровотечение" end
	if count <= 3 then return "Кровотечение" end
	return "Сильное кровотечение"
end

local function get_bone_pos(ent, bones)
	ent:SetupBones()
	for i = 1, #bones do
		local id = ent:LookupBone(bones[i])
		if id then
			local pos = ent:GetBonePosition(id)
			if isvector(pos) then
				return pos
			end
		end
	end
	local center = ent:OBBCenter()
	if isvector(center) then
		return ent:LocalToWorld(center)
	end
end

local function build_observe_text(entry, ent)
	if not IsValid(ent) then
		return entry.label .. ": Нет цели"
	end
	local org = ent.organism or ent.new_organism or {}
	local wounds = ent.wounds or ent:GetNetVar("wounds") or {}
	local arterialwounds = ent.arterialwounds or ent:GetNetVar("arterialwounds") or {}
	if not ent.organism and not ent.new_organism then
		return entry.label .. ": Нет данных"
	end
	local fracture = has_fracture(org, entry.fracture_keys or {})
	local dislocation = entry.dis_key and (org[entry.dis_key] or false) or false
	local woundcount = count_wounds_for_groups(ent, wounds, entry.hitgroups or {})
	local arterialcount = count_arterial_for_groups(ent, arterialwounds, entry.hitgroups or {})
	if not fracture and not dislocation and woundcount <= 0 and arterialcount <= 0 then
		return entry.label .. ": Всё в порядке."
	end
	local parts = {}
	if fracture then parts[#parts + 1] = "Перелом" end
	if dislocation then parts[#parts + 1] = "Вывих" end
	local bleeding = get_bleeding_label(woundcount)
	if bleeding then parts[#parts + 1] = bleeding end
	if arterialcount > 0 then parts[#parts + 1] = "Артериальное кровотечение" end
	return entry.label .. ": " .. table.concat(parts, ", ")
end

hook.Add("HUDPaint", "mcd_admire_observe", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local alive = ply:Alive() and ply:Health() > 0 and not (ply.organism and ply.organism.alive == false) and not IsValid(ply:GetNWEntity("spect"))
	local view_ent = GetViewEntity()
	local function reset_observe(require_reset)
		observe_state.active = false
		observe_state.target = nil
		observe_state.data_target = nil
		observe_state.stage = 1
		observe_state.stage_start = 0
		observe_state.last_health = 0
		observe_state.last_hurt = 0
		observe_state.last_painadd = 0
		if require_reset then
			observe_state.require_admire_reset = true
			ply.mcd_admire_local_cancel = true
			if ply:GetNWBool("mcd_admiring", false) then
				RunConsoleCommand("mcd_admire", "cancel")
			end
		end
	end
	if observe_state.was_alive and not alive then
		reset_observe(true)
	end
	if not observe_state.was_alive and alive then
		reset_observe(false)
	end
	observe_state.was_alive = alive
	if not alive then
		reset_observe(false)
		return
	end
	if view_ent ~= ply then
		reset_observe(true)
		return
	end
	local in_fake = IsValid(ply.FakeRagdoll) or IsValid(ply:GetNWEntity("FakeRagdoll")) or IsValid(ply:GetNWEntity("FakeRagdollOld")) or IsValid(ply:GetNWEntity("RagdollDeath")) or IsValid(ply.RagdollDeath)
	if in_fake then
		reset_observe(true)
		return
	end
	if not ply:OnGround() then
		reset_observe(true)
		return
	end
	local org = ply.organism or ply.new_organism
	local hurt = org and org.hurt or 0
	local painadd = org and org.painadd or 0
	if observe_state.last_painadd and painadd > observe_state.last_painadd + 0.01 then
		reset_observe(true)
		observe_state.last_painadd = painadd
		return
	end
	observe_state.last_painadd = painadd
	if observe_state.last_hurt and hurt > observe_state.last_hurt + 0.01 then
		reset_observe(true)
		observe_state.last_hurt = hurt
		return
	end
	observe_state.last_hurt = hurt
	local health = ply:Health()
	if observe_state.last_health and health < observe_state.last_health then
		reset_observe(true)
		observe_state.last_health = health
		return
	end
	observe_state.last_health = health
	local admiring = ply:GetNWBool("mcd_admiring", false)
	if observe_state.require_admire_reset then
		if admiring then return end
		observe_state.require_admire_reset = false
		ply.mcd_admire_local_cancel = false
	end
	if not admiring then
		observe_state.active = false
		observe_state.target = nil
		observe_state.data_target = nil
		ply.mcd_admire_local_cancel = false
		return
	end
	local draw_ent, data_ent = get_observe_target(ply, admiring)
	if not admiring and not IsValid(draw_ent) then
		observe_state.active = false
		observe_state.target = nil
		observe_state.data_target = nil
		return
	end

	if observe_state.target ~= draw_ent or not observe_state.active then
		observe_state.active = true
		observe_state.target = draw_ent
		observe_state.data_target = data_ent
		observe_state.stage = 1
		observe_state.stage_start = CurTime()
		observe_state.last_health = ply:Health()
	end

	local elapsed = CurTime() - observe_state.stage_start
	if elapsed >= observe_stage_time then
		observe_state.stage = observe_state.stage + 1
		if observe_state.stage > #observe_parts then
			observe_state.stage = 1
		end
		observe_state.stage_start = CurTime()
		elapsed = 0
	end

	local part = observe_parts[observe_state.stage]
	local entries = observe_bone_sets[part]
	if not entries or not IsValid(draw_ent) then return end
	local t = math.Clamp(elapsed / observe_stage_time, 0, 1)
	local fade = t <= 0.5 and (t * 2) or ((1 - t) * 2)
	local fade_alpha = math.Clamp(fade, 0, 1)
	if fade_alpha <= 0 then return end

	local offscreen_count = 0
	for i = 1, #entries do
		local entry = entries[i]
		local bone_pos = get_bone_pos(draw_ent, entry.bones)
		if bone_pos then
			if entry.offset and entry.offset ~= 0 then
				bone_pos = bone_pos + draw_ent:GetForward() * entry.offset
			end
			local screen = bone_pos:ToScreen()
			local is_offscreen = not screen.visible or screen.x < 0 or screen.x > ScrW() or screen.y < 0 or screen.y > ScrH()

			local end_x, end_y
			if is_offscreen then
				offscreen_count = offscreen_count + 1
				end_x = ScrW() * 0.5
				end_y = ScrH() - 20 - (offscreen_count * 40)
			else
				end_x = screen.x + observe_line_screen * (entry.side or 1)
				end_y = screen.y - observe_line_screen_up
				surface.SetDrawColor(observe_line_color.r, observe_line_color.g, observe_line_color.b, math.floor(255 * fade_alpha))
				surface.DrawLine(screen.x, screen.y, end_x, end_y)
			end

			local full_text
			local type_elapsed
			if elapsed < observe_text_delay then
				full_text = entry.label .. ": Осмотр..."
				type_elapsed = elapsed
			else
				full_text = build_observe_text(entry, observe_state.data_target or draw_ent)
				type_elapsed = elapsed - observe_text_delay
			end
			local max_chars = math.floor(type_elapsed * observe_type_speed)
			local text = string.sub(full_text, 1, math.Clamp(max_chars, 0, #full_text))

			surface.SetFont(observe_font)
			local tw, th = surface.GetTextSize(text)
			local pad = 6
			local box_w = tw + pad * 2
			local box_h = th + pad * 2
			local box_x = end_x - box_w * 0.5
			local box_y = end_y - box_h * 0.5
			draw.RoundedBox(0, box_x, box_y, box_w, box_h, Color(observe_box_color.r, observe_box_color.g, observe_box_color.b, math.floor(observe_box_color.a * fade_alpha)))
			draw.SimpleText(text, observe_font, end_x, end_y, Color(observe_text_color.r, observe_text_color.g, observe_text_color.b, math.floor(observe_text_color.a * fade_alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end)

hook.Add("HUDPaint","Identifier",function()
	if lply.organism and lply.organism.otrub then return end
	if !lply:Alive() then return end
	if lply:GetNetVar("disappearance", nil) then return end
	
	local trace = hg.eyeTrace(lply)
	if not trace then return end

	local Size = math.max(math.min(1 - trace.Fraction, 1), 0.1)
	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y

	if trace.Hit and (trace.Entity:IsRagdoll() or trace.Entity:IsPlayer()) then
		if trace.Entity.PlayerClassName == "sc_infiltrator" then return end
		if trace.Entity:GetNetVar("disappearance", nil) then return end

		draw.NoTexture()
		local col = trace.Entity:GetPlayerColor():ToColor()
		col.a = 255 * Size * 1.5
		local coloutline = (col.r < 50 and col.g < 50 and col.b < 50) and Color(100,100,100) or Color(0,0,0)
		coloutline.a = 255 * Size * 1
		draw.DrawText(trace.Entity:GetPlayerName() or "", "ZCity_Veteran", x + 1, y + 31, coloutline, TEXT_ALIGN_CENTER)
		draw.DrawText(trace.Entity:GetPlayerName() or "", "ZCity_Veteran", x, y + 30, col, TEXT_ALIGN_CENTER)
	end
end)

local hint
local hg_hints = ConVarExists("hg_hints") and GetConVar("hg_hints") or CreateClientConVar("hg_hints", "1", true, false, "Toggle UI hints")
local HintBackgroundColor = Color(0, 0, 0, 200)

hook.Add("HUDPaint","EntHints",function()
	if not hg_hints:GetBool() then return end
	if lply.organism and lply.organism.otrub then return end
	if !lply:Alive() then return end
	local trace = hg.eyeTrace(lply)
	if not trace then return end

	HintBackgroundColor.a = LerpFT(0.1, HintBackgroundColor.a, (IsValid(trace.Entity) and trace.Entity.HudHintMarkup) and 200 or 0)
	hg.BasicHudHint(trace.Entity, trace, hint)
end)

function hg.BasicHudHint(ent, trace)
	hint = (IsValid(ent) and ent.HudHintMarkup) or hint
	if not hint then return end

	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
	y = y + 145 + -45
	draw.RoundedBox(2, x - hint:GetWidth() / 2 - 2.5, y - 2.5, hint:GetWidth() + 5, hint:GetHeight() + 5, HintBackgroundColor)
	hint:Draw(x, y, TEXT_ALIGN_CENTER, nil, 175 * (HintBackgroundColor.a / 200), TEXT_ALIGN_CENTER)

	if ent.AdditionalInfoFunc then
		local str = ent.AdditionalInfoFunc()
		local w, h = surface.GetTextSize(str)
		surface.SetFont("ZCity_Veteran_small")
		surface.SetTextColor(color_white)
		surface.SetTextPos(x - w * 0.69, y + hint:GetHeight() + h)
		surface.DrawText(str)
	end
end

