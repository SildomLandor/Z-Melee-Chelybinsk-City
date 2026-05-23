hook.Add("OnNetVarSet", "Guilt", function(index, key, var)
	if key == "Karma" then
		Entity(index).Karma = var
	end
end)

function zb.GetLocalKarma()
	local ply = LocalPlayer()
	if not IsValid(ply) then return 100 end

	local k = ply.Karma
	if k == nil then
		local nv = ply:GetNetVar("Karma")
		if nv ~= nil then k = nv end
	end

	return math.Round(k or 100)
end

function zb.GetKarmaColor(karma, palette)
	palette = palette or {}
	if karma >= 100 then return palette.text or Color(200, 200, 200, 255) end
	if karma >= 70 then return palette.textDim or Color(160, 160, 165, 180) end
	if karma >= 50 then return Color(220, 180, 60, 200) end
	return palette.textBlood or Color(180, 40, 35, 255)
end

concommand.Add("hg_getkarma", function(ply)
	if not ply:IsAdmin() then return end
	net.Start("get_karma")
	net.SendToServer()
end)

net.Receive("get_karma", function()
	local tbl = net.ReadTable()
	local printTbl = "\nКарма игроков:\n"
	for id, karma in pairs(tbl) do
		local pl = Player(id)
		if IsValid(pl) then
			printTbl = printTbl .. "\t" .. pl:Name() .. ": " .. math.Round(karma, 2) .. "\n"
		end
	end
	LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, printTbl)
end)

concommand.Add("hg_guilt_menu", function()
	net.Start("open_guilt_menu")
	net.SendToServer()
end)

local OpenMenu

net.Receive("open_guilt_menu", function()
	OpenMenu(net.ReadTable())
end)

local col = {
	frameBG       = Color(10, 10, 19, 245),
	frameBorder   = Color(90, 90, 95, 120),
	panelBorder   = Color(255, 255, 255, 25),
	separator     = Color(255, 255, 255, 12),
	text          = Color(200, 200, 200, 255),
	textDim       = Color(160, 160, 165, 180),
	textMuted     = Color(100, 100, 108, 140),
	textBlood     = Color(180, 40, 35, 255),
	rowHover      = Color(255, 255, 255, 12),
	rowBorder     = Color(255, 255, 255, 8),
	btnHover      = Color(255, 255, 255, 15),
	btnBorder     = Color(255, 255, 255, 25),
	scrollTrack   = Color(255, 255, 255, 6),
	scrollGrip    = Color(200, 200, 200, 60),
	scrollGripHov = Color(200, 200, 200, 100),
}

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local bloodDrips = {}
for i = 1, math.random(4, 6) do
	bloodDrips[i] = {
		x = math.Rand(0, 1),
		w = math.random(1, 2),
		h = math.random(ScreenScaleH(8), ScreenScaleH(24)),
		alpha = math.random(8, 20),
		speed = math.Rand(0.15, 0.5),
		offset = math.Rand(0, math.pi * 2),
	}
end

local function paint_frame(x, y, w, h)
	draw.RoundedBox(0, x, y, w, h, col.frameBG)

	if not NoiseMat:IsError() then
		surface.SetMaterial(NoiseMat)
		surface.SetDrawColor(255, 255, 255, 6)
		local nx, ny = math.random(0, 512), math.random(0, 512)
		surface.DrawTexturedRectUV(x, y, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
	end

	for ly = y, y + h, 3 do
		surface.SetDrawColor(0, 0, 0, 12)
		surface.DrawRect(x, ly, w, 1)
	end

	local t = CurTime()
	for _, drip in ipairs(bloodDrips) do
		local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
		surface.SetDrawColor(100, 15, 12, math.floor(drip.alpha * pulse))
		surface.DrawRect(x + drip.x * w, y, drip.w, math.min(drip.h, h))
	end

	surface.SetDrawColor(col.frameBorder)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(col.panelBorder)
	surface.DrawOutlinedRect(x + 2, y + 2, w - 4, h - 4, 1)
end

local function paint_bloody_title(text, cx, cy)
	local font = "ZCity_Veteran"
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	local bx, by = cx - tw * 0.5, cy - th * 0.5
	local pulse = math.sin(CurTime() * 1.5) * 0.15 + 0.85

	draw.SimpleText(text, font, bx + 2, by + 2, Color(40, 4, 2, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx + 1, by + 1, Color(90, 8, 6, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx, by, Color(140 * pulse, 15 * pulse, 12 * pulse, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function fit_text(font, text, maxW)
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

local function style_scrollbar(sbar)
	if not IsValid(sbar) then return end
	sbar:SetHideButtons(true)
	sbar.Paint = function(_, sw, sh)
		surface.SetDrawColor(col.scrollTrack)
		surface.DrawRect(0, 0, sw, sh)
	end
	sbar.btnGrip.Paint = function(self, sw, sh)
		surface.SetDrawColor(self:IsHovered() and col.scrollGripHov or col.scrollGrip)
		surface.DrawRect(2, 0, sw - 4, sh)
	end
end

local function harmdone(harm)
	if harm >= 9 then return "убил вас"
	elseif harm >= 5 then return "почти убил вас"
	elseif harm >= 2 then return "серьёзно ранил вас"
	elseif harm >= 1 then return "сильно ранил вас"
	else return "ранил вас" end
end

local function close_guilt_menu()
	if IsValid(guiltMenu) then
		guiltMenu:Remove()
		guiltMenu = nil
	end
end

local showstuff = 0
local pressed

hook.Add("Player_Death", "karmacheck", function(ply)
	if ply ~= LocalPlayer() then return end
	showstuff = CurTime() + 5
end)

hook.Add("HUDPaint", "shownotification", function()
	if LocalPlayer():Alive() then return end
	if IsValid(guiltMenu) then return end

	if showstuff > CurTime() then
		local sw, sh = ScrW(), ScrH()
		local txt = "Нажми [F], чтобы открыть меню прощения"
		surface.SetFont("ZB_InterfaceSmall")
		local tw, th = surface.GetTextSize(txt)
		local pulse = math.sin(CurTime() * 3) * 0.2 + 0.8
		draw.SimpleText(txt, "ZB_InterfaceSmall", sw * 0.5 + 1, sh - ScreenScaleH(28) + 1, Color(0, 0, 0, 120 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(txt, "ZB_InterfaceSmall", sw * 0.5, sh - ScreenScaleH(28), Color(200, 200, 200, 220 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if input.IsKeyDown(KEY_F) and not gui.IsGameUIVisible() and not IsValid(vgui.GetKeyboardFocus()) then
		if not pressed then
			showstuff = 0
			RunConsoleCommand("hg_guilt_menu")
			pressed = true
		end
	else
		pressed = nil
	end
end)

OpenMenu = function(tbl)
	close_guilt_menu()

	local sw, sh = ScrW(), ScrH()
	local sizeX = math.Clamp(math.floor(sw * 0.44), 340, 560)
	local sizeY = math.Clamp(math.floor(sh * 0.52), 280, 520)
	local posX = math.floor(sw * 0.5 - sizeX * 0.5)
	local posY = math.floor(sh * 0.5 - sizeY * 0.5)
	local margin = ScreenScale(6)
	local headerH = ScreenScaleH(44)
	local footerH = ScreenScaleH(36)
	local rowH = ScreenScaleH(34)

	guiltMenu = vgui.Create("DPanel")
	guiltMenu:SetSize(sw, sh)
	guiltMenu:SetPos(0, 0)
	guiltMenu:MakePopup()
	guiltMenu:SetKeyboardInputEnabled(false)
	guiltMenu:SetAlpha(0)
	guiltMenu:AlphaTo(255, 0.12, 0)

	function guiltMenu:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(0, 0, w, h)
		paint_frame(posX, posY, sizeX, sizeY)
		paint_bloody_title("ПРОЩЕНИЕ", posX + sizeX * 0.5, posY + headerH * 0.45)

		surface.SetDrawColor(col.separator)
		surface.DrawRect(posX + margin, posY + headerH, sizeX - margin * 2, 1)

		surface.SetFont("ZB_InterfaceSmall")
		surface.SetTextColor(col.textMuted)
		local sub = "Вернуть карму обидчикам"
		local stw = surface.GetTextSize(sub)
		surface.SetTextPos(posX + sizeX * 0.5 - stw * 0.5, posY + headerH - ScreenScaleH(10))
		surface.DrawText(sub)
	end

	local frame = vgui.Create("DPanel", guiltMenu)
	frame:SetPos(posX, posY)
	frame:SetSize(sizeX, sizeY)
	frame.Paint = function() end

	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetPos(sizeX - margin - ScreenScale(28), margin)
	closeBtn:SetSize(ScreenScale(26), ScreenScaleH(18))
	closeBtn:SetText("")
	closeBtn.Paint = function(self, w, h)
		local hov = self:IsHovered()
		surface.SetDrawColor(hov and col.btnHover or Color(0, 0, 0, 0))
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(col.btnBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("×", "ZCity_Veteran", w * 0.5, h * 0.5 - 1, hov and col.textBlood or col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = close_guilt_menu

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:SetPos(margin, headerH + ScreenScaleH(4))
	scroll:SetSize(sizeX - margin * 2, sizeY - headerH - footerH - ScreenScaleH(6))
	style_scrollbar(scroll:GetVBar())

	local list = scroll:GetCanvas()
	local count = 0

	for ply, harm in pairs(tbl) do
		if not IsValid(ply) or harm <= 0.01 then continue end
		count = count + 1

		local name = ply:Name()
		local harmTxt = harmdone(harm)
		local karmaReturn = math.Round(harm, 1)
		local row = vgui.Create("DButton", list)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, ScreenScale(4))
		row:SetTall(rowH)
		row:SetText("")

		row.Paint = function(self, w, h)
			local hov = self:IsHovered()
			if hov then
				surface.SetDrawColor(col.rowHover)
				surface.DrawRect(0, 0, w, h)
			end
			surface.SetDrawColor(col.rowBorder)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			local pad = ScreenScale(8)
			local nameFont = "ZCity_Veteran"
			local subFont = "ZB_InterfaceSmall"
			local nameTxt = fit_text(nameFont, name, w - pad * 2)
			local subTxt = fit_text(subFont, harmTxt .. " · +" .. karmaReturn .. " кармы", w - pad * 2)

			draw.SimpleText(nameTxt, nameFont, pad, h * 0.35, col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(subTxt, subFont, pad, h * 0.72, col.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if hov then
				local act = fit_text(subFont, "простить", ScreenScale(52))
				draw.SimpleText(act, subFont, w - pad, h * 0.5, col.textBlood, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		row.DoClick = function()
			net.Start("forgive_player")
			net.WriteEntity(ply)
			net.SendToServer()
			tbl[ply] = nil
			OpenMenu(tbl)
		end
	end

	if count == 0 then
		local empty = vgui.Create("DPanel", list)
		empty:Dock(TOP)
		empty:SetTall(ScreenScaleH(80))
		empty.Paint = function(_, w, h)
			draw.SimpleText("Некого прощать", "ZCity_Veteran", w * 0.5, h * 0.4, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Никто не причинил вам вреда в этом раунде", "ZB_InterfaceSmall", w * 0.5, h * 0.65, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local hint = vgui.Create("DPanel", frame)
	hint:SetPos(margin, sizeY - footerH + ScreenScaleH(2))
	hint:SetSize(sizeX - margin * 2, footerH - ScreenScaleH(4))
	hint.Paint = function(_, w, h)
		surface.SetDrawColor(col.separator)
		surface.DrawRect(0, 0, w, 1)
		draw.SimpleText("Нажмите на игрока, чтобы простить", "ZB_InterfaceSmall", w * 0.5, h * 0.55, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end
