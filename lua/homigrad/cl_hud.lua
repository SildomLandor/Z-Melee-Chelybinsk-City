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
	--if not IsValid(lply) or not lply:Alive() then return end
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end

	--[[if not IsValid(wep) then return end
	if not wep.GetPrintName then return end
	
	lply:Notify("+ " .. wep:GetPrintName(), 0)]]

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

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

--atlaschat.coolvetica
surface.CreateFont("HomigradFont", {
	font = font(),
	size = ScreenScale(10),
	weight = 1100,
	outline = false
})

surface.CreateFont("ScoreboardPlayer", {
	font = font(),
	size = ScreenScale(7),
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontBig", {
	font = font(),
	size = ScreenScale(12),
	weight = 1100,
	outline = false,
	shadow = true
})

surface.CreateFont("HomigradFontMedium", {
	font = font(),
	size = ScreenScale(8),
	weight = 1100,
	outline = false,
})

surface.CreateFont("HomigradFontLarge", {
	font = font(),
	size = ScreenScale(15),
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontGigantoNormous", {
	font = font(),
	size = ScreenScale(25),
	weight = 1100,
	outline = false,
	shadow = false
})

surface.CreateFont("HomigradFontSmall", {
	font = font(),
	size = 17,
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontVSmall", {
	font = font(),
	size = 12,
	weight = 400,
	outline = false
})

surface.CreateFont("ZCity_Veteran", {
	font = font(),
	size = ScreenScale(8),
	weight = 700,
	outline = false,
	antialias = true
})

local w, h

hook.Add("HUDPaint", "homigrad-dev", function()
	if engine.ActiveGamemode() ~= "sandbox" then return end
	w, h = ScrW(), ScrH()
end)

--draw.SimpleText(lply:Health(),"HomigradFontBig",100,h - 50,white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
		--draw.DrawText("asd","HomigradFontBig",x + math.sin(a) * radius,y + math.cos(a) * radius)
	end

	--local a = math.rad(0)
	--table.insert(cir, {x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5})
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	surface.DrawPoly(cir)
	render.PopFilterMin()
end

-- Ring segment with gaps between sections
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

-- Delicacy Reworked style colours
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
local function CreateRadialMenu(options_arg, bAutoClose)
	local sizeX, sizeY = ScrW(), ScrH()
	hg.radialOptions = {}
	local paining = lply.organism and lply.organism.pain and (lply.organism.pain > 100 or lply.organism.brain > 0.2) or false
	
	if !options_arg then
		local functions = hook.GetTable()["radialOptions"]
		for i, func in SortedPairs(functions) do
			func()
		end
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
			table.Empty(hg.radialOptions)
			local functions = hook.GetTable()["radialOptions"]
			
			for i, func in SortedPairs(functions) do
				func()
			end
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

		-- resolve hover before drawing (avoids early return inside loop)
		isMouseOnRadial = sqrt <= rOuter and sqrt > 2
		for num, option in ipairs(options) do
			local idx = num - 1
			isMouseIntersecting = isMouseOnRadial and deg > idx * partDeg and deg < (idx + 1) * partDeg
			if isMouseIntersecting then current_option = num end
			optionSelected[idx] = optionSelected[idx] or 0
			optionSelected[idx] = LerpFT(0.1, optionSelected[idx], isMouseIntersecting and 1 or 0)
		end

		-- draw segments
		local radialFont = options_arg and "HomigradFont" or "ZCity_Veteran"
		for num, option in ipairs(options) do
			local idx = num - 1
			local sel = optionSelected[idx]

			-- custom colour support (option[6] = base, option[7] = hover)
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
				-- sub-variant segment (multi-ring)
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

			-- normal segment background (expands on hover)
			local hoverR = rOuter * (1 + 0.05 * sel)
			surface.SetMaterial(matHuy)
			surface.SetDrawColor(
				math.floor(Lerp(sel, segColBase.r, segColHover.r)),
				math.floor(Lerp(sel, segColBase.g, segColHover.g)),
				math.floor(Lerp(sel, segColBase.b, segColHover.b)),
				math.floor(Lerp(sel, segColBase.a, segColHover.a) * panAlpha)
			)
			draw.CirclePartRing(cx, cy, rInner, hoverR, 40, #options, idx, 3)

			-- thin border along outer edge
			surface.SetDrawColor(
				math.floor(Lerp(sel, colBorderBase.r, colBorderHover.r)),
				math.floor(Lerp(sel, colBorderBase.g, colBorderHover.g)),
				math.floor(Lerp(sel, colBorderBase.b, colBorderHover.b)),
				math.floor(Lerp(sel, colBorderBase.a, colBorderHover.a) * panAlpha)
			)
			draw.CirclePartRingOutline(cx, cy, rInner, hoverR, 40, #options, idx, 3)

			-- "shine" effect when hovered
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

			-- icon or text
			if option[5] then
				-- icon
				local midDeg = idx * (360 / #options) + (360 / #options) / 2
				local midA = math.rad(midDeg - 90)
				local tRad = rInner + (hoverR - rInner) * 0.58

				surface.SetMaterial(option[5])
				surface.SetDrawColor(color_white)
				local sizeW = scrW / 2 + math.cos(midA) * tRad - scrW * 0.05
				local sizeH = scrH / 2 + math.sin(midA) * tRad - scrW * 0.05
				surface.DrawTexturedRect(sizeW, sizeH, scrW * 0.1, scrH * 0.1)
			else
				-- text
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

			-- player name and role, drawn once in first segment
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
	--print(options[current_option][1])
	--[[if lply.organism and lply.organism.pain and lply.organism.pain > 100 then
		hook_Run("RadialMenuPressed")

		if IsValid(menuPanel) then
			menuPanel:Close()
		end

		return
	end--]]

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

-- first time?..

hook.Add("HG_OnOtrub", "resetshit", function(ply)
	if ply == lply then
		hook_Run("RadialMenuPressed")

		if IsValid(menuPanel) then
			menuPanel:Close()
		end
	end
end)

hook.Add( "PlayerBindPress", "PlayerBindPressExample2huy", function( ply, bind, pressed )
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
			--CreateRadialMenu()
		end

		firstTime4 = true
	else
		if firstTime4 then
			firstTime4 = false
			--PressRadialMenu()
		end

		firstTime = true
	end

	if input.IsMouseDown(MOUSE_LEFT) then
		if firstTime2 then
			firstTime2 = false
			--print("pressed")
		end

		firstTime3 = true
	else
		if firstTime3 then
			firstTime3 = false
			--print("released")
			PressRadialMenu(1)
		end

		firstTime2 = true
	end

	if input.IsMouseDown(MOUSE_RIGHT) then
		if firstTime5 then
			firstTime5 = false
			--print("pressed")
		end

		firstTime6 = true
	else
		if firstTime6 then
			firstTime6 = false
			--print("released")
			PressRadialMenu(2)
		end

		firstTime5 = true
	end
end)

local function dropWeapon()
	RunConsoleCommand("drop")
end

local function suicide()
	RunConsoleCommand("suicide")
end

hook.Add("radialOptions", "77", function()
	local organism = lply.organism or {}
	if not organism.otrub and IsValid(lply:GetActiveWeapon()) and lply:GetActiveWeapon():GetClass() ~= "weapon_hands_sh" then
		local tbl = {dropWeapon, "Бросить Оружие"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

hook.Add("radialOptions", "88", function()
	local organism = lply.organism or {}
	if not organism.otrub and IsValid(lply:GetActiveWeapon()) and lply:GetActiveWeapon():GetClass() ~= "weapon_hands_sh" then
		local tbl = {suicide, "Смерть"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

hook.Add("radialOptions", "Afflictions", function()
    local ply = LocalPlayer()
    local organism = ply.organism or {}

    if ply:Alive() and not organism.otrub and hg.GetCurrentCharacter(ply) == ply then
        local tbl = {function()
            RunConsoleCommand("mcd_admire")
        end, "Осмотреть себя"}
        hg.radialOptions[#hg.radialOptions + 1] = tbl
    end
end)

local randomGestures = {
	"wave",
	"salute",
	"halt",
	"group",
	"forward",
	"disagree",
	--"agree",
	"becon",
	{"point", function() RunConsoleCommand("hg_hand_gesture", "point") end},
	{"fuck you", function() RunConsoleCommand("hg_hand_gesture", "fuckyou") end},
	{"thumb_up", function() RunConsoleCommand("hg_hand_gesture" , "thumb_up") end},
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
		end, "Do Gesture\nRMB - Menu"}
        hg.radialOptions[#hg.radialOptions + 1] = tbl
    end
end)

local font_size = 50
surface.CreateFont("HG_font", {
	font = "Arial",
	extended = false,
	size = font_size,
	weight = 500,
	outline = true
})

local CurTime = CurTime

local vector_one = Vector( 1, 1, 1 )

local function CopyRight( text, font, x, y, color, ang, scale )
	--render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	--render.PushFilterMin( TEXFILTER.ANISOTROPIC )

	local m = Matrix()
	m:Translate( Vector( x, y, 0 ) )
	m:Rotate( Angle( 0, ang, 0 ) )
	m:Scale( vector_one * ( scale or 1 ) )

	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )

	m:Translate( Vector( -(w / 2)-25, -h / 2, 0 ) )

	cam.PushModelMatrix( m, true )
		draw.RoundedBox(5,0,2,w+52,h+2,Color(0,0,0))
		draw.RoundedBox(5,0,2,w+50,h,Color(255,0,0))
		draw.DrawText( text, font, 25, 0, color )	
	cam.PopModelMatrix()

	--render.PopFilterMag()
	--render.PopFilterMin()
end

--hook.Add("HUDPaint","homigrad-copyright",function()
	--local i = 1
	--CopyRight("ЖДИ ДОКС ЖДИ СВАТ","HomigradFontBig",ScrW()/2 +(math.cos(CurTime()*1)*15*i),ScrH()/2+(math.sin(CurTime()*1)*55*i)+15,Color(255,255,255),math.cos(CurTime()*1)*1,2+math.sin(CurTime()*1)*0.5)
--end)

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

		draw.DrawText(trace.Entity:GetPlayerName() or "", "HomigradFontLarge", x + 1, y + 31, coloutline, TEXT_ALIGN_CENTER)

		draw.DrawText(trace.Entity:GetPlayerName() or "", "HomigradFontLarge", x, y + 30, col, TEXT_ALIGN_CENTER)
	end
end)

--sound.PlayURL("https://cdn.discordapp.com/attachments/1254022273661145108/1257385761414582382/pon_pon_016eb317d_1.mp4?ex=66882bbe&is=6686da3e&hm=429f0e4427bdc9d80673d3bfa2eccf48221ae5572ec508fb7699274c2c7041ef&","",function() end)

function scare()
	-- hook.Add("RenderScreenspaceEffects","Scare",function()
		-- for i = 1, 5 do
		-- CopyRight("Плывиски","HomigradFontBig",ScrW()/2 +(math.cos(CurTime()*1)*15*i),ScrH()/2+(math.sin(CurTime()*1)*55*i)+15,Color(255,255,255),math.cos(CurTime()*1)*1,2+math.sin(CurTime()*1)*0.5)
		-- end
	-- end)
	-- for i = 1, 15 do
		-- sound.PlayURL("https://cdn.discordapp.com/attachments/1254022273661145108/1257385761414582382/pon_pon_016eb317d_1.mp4?ex=66882bbe&is=6686da3e&hm=429f0e4427bdc9d80673d3bfa2eccf48221ae5572ec508fb7699274c2c7041ef&","",function() end)
	-- end
end

local hint
local hg_hints = ConVarExists("hg_hints") and GetConVar("hg_hints") or CreateClientConVar("hg_hints", "1", true, false, "Toggle UI hints")

local HintBackgroundColor = Color( 0, 0, 0, 200 )

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
		surface.SetFont("ZCity_Tiny")
		surface.SetTextColor(color_white)
		surface.SetTextPos(x - w * 0.5, y + hint:GetHeight() + h)
		surface.DrawText(str)
	end
end

local leg = Material("zbattle/medical/broken_bone.png", "")

local white = Color(255, 255, 255, 255)
local bkg = Color(43, 30, 30)
hook.Add("HUDPaint","afflictionlist",function()
	--[[if lply.organism and lply.organism.otrub then return end
	if !lply:Alive() then return end
	
	local org = lply.organism

	if org.lleg >= 0.99 then
		local w, h = 200, 200

		local ent = hg.GetCurrentCharacter(lply)
		local lkp = ent:LookupBone("ValveBiped.Bip01_R_Thigh")
		local matrix = ent:GetBoneMatrix(lkp)

		if matrix then
			local pos = matrix:GetTranslation() + matrix:GetForward() * ent:BoneLength(lkp + 1) * 0.5
			local scrpos = pos:ToScreen()

			surface.SetMaterial(leg)
			surface.SetDrawColor(white)
			--surface.DrawRect(sw / 2 - w / 2, sh / 2 - h / 2, w, h)
			surface.SetDrawColor(white)
			surface.DrawTexturedRect(scrpos.x - w / 2, scrpos.y - h / 2, w, h)
		end
	end--]]
end)

-- Now playable :steamhappy:
-- No. fuc kyouy
if game.SinglePlayer() then
	hook.Add("HUDPaint","Exit the singleplayer",function()
		draw.SimpleText("Z-City is not meant to be played in singleplayer, in map selection menu change SINGLEPLAYER (green button top right corner) to 2 players or any.", "HomigradFontMedium", ScrW() / 2,ScrH() / 2, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("A lot of stuff won't work and we won't provide any fixes to singleplayer EVER", "HomigradFontMedium", ScrW() / 2,ScrH() * 7 / 12, nil,TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end)
end