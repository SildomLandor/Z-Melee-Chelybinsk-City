hook.Add("OnNetVarSet", "Guilt", function(index, key, var)
	if key ~= "Karma" then return end
	local ent = Entity(index)
	if IsValid(ent) then ent.Karma = var end
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

concommand.Add("hg_getkarma", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:IsAdmin() then return end
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

local col = {
	frameBG       = Color(10, 10, 19, 245),
	frameBorder   = Color(90, 90, 95, 120),
	panelBG       = Color(8, 8, 16, 245),
	panelBorder   = Color(255, 255, 255, 25),
	separator     = Color(255, 255, 255, 12),
	text          = Color(200, 200, 200, 255),
	textDim       = Color(160, 160, 165, 180),
	textMuted     = Color(100, 100, 108, 140),
	textBlood     = Color(180, 40, 35, 255),
	rowAlt        = Color(255, 255, 255, 4),
	rowHover      = Color(255, 255, 255, 15),
	rowBorder     = Color(255, 255, 255, 8),
	accent        = Color(200, 200, 200, 60),
	scrollTrack   = Color(255, 255, 255, 6),
	scrollGrip    = Color(200, 200, 200, 60),
	scrollGripHov = Color(200, 200, 200, 100),
}

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local guiltOverlay, guiltMenu

local function entryHarm(data)
	if istable(data) then return data.harm or 0 end
	return tonumber(data) or 0
end

local function entryKarma(data)
	if istable(data) then return data.karma or 0 end
	return tonumber(data) or 0
end

local function fitText(font, text, maxW)
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

local function harmLabel(harm)
	if harm >= 9 then return "убил вас"
	elseif harm >= 5 then return "почти убил"
	elseif harm >= 2 then return "серьёзно ранил"
	elseif harm >= 1 then return "сильно ранил"
	else return "ранил" end
end

local function styleScrollbar(sbar)
	if not IsValid(sbar) then return end
	sbar:SetHideButtons(true)
	sbar.Paint = function(_, sw, sh)
		surface.SetDrawColor(col.scrollTrack)
		surface.DrawRect(0, 0, sw, sh)
	end
	if IsValid(sbar.btnGrip) then
		sbar.btnGrip.Paint = function(self, sw, sh)
			surface.SetDrawColor(self:IsHovered() and col.scrollGripHov or col.scrollGrip)
			surface.DrawRect(2, 0, sw - 4, sh)
		end
	end
end

local function close_guilt_menu()
	if IsValid(guiltOverlay) then
		guiltOverlay:Remove()
	end
	guiltOverlay = nil
	guiltMenu = nil
	gui.EnableScreenClicker(false)
end

local function guiltRowsFromPayload(tbl)
	local rows = {}
	for _, row in ipairs(tbl or {}) do
		if not istable(row) then continue end
		local ply = Entity(row.ent or 0)
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		local data = { harm = row.harm, karma = row.karma }
		if entryHarm(data) > 0.01 or entryKarma(data) > 0.01 then
			rows[#rows + 1] = { ply = ply, data = data }
		end
	end
	return rows
end

local function guiltHasEntries(tbl)
	return #guiltRowsFromPayload(tbl) > 0
end

net.Receive("open_guilt_menu", function()
	local tbl = net.ReadTable() or {}
	if guiltHasEntries(tbl) then
		OpenMenu(tbl)
	elseif IsValid(guiltOverlay) then
		close_guilt_menu()
	else
		OpenMenu(tbl)
	end
end)

local showstuff = 0
local pressed

hook.Add("Player_Death", "karmacheck", function(ply)
	if ply ~= LocalPlayer() then return end
	showstuff = CurTime() + 5
end)

hook.Add("HUDPaint", "shownotification", function()
	local lply = LocalPlayer()
	if not IsValid(lply) or lply:Alive() then return end
	if IsValid(guiltOverlay) then return end

	if showstuff > CurTime() then
		local sw, sh = ScrW(), ScrH()
		local txt = "Нажми [F], чтобы открыть меню прощения"
		local pulse = math.sin(CurTime() * 3) * 0.2 + 0.8
		draw.SimpleText(txt, "ZCity_Veteran", sw * 0.5 + 1, sh - ScreenScaleH(28) + 1, Color(0, 0, 0, 120 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(txt, "ZCity_Veteran", sw * 0.5, sh - ScreenScaleH(28), Color(200, 200, 200, 220 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
	local sizeX = math.Clamp(math.floor(sw * 0.44), 340, 720)
	local sizeY = math.Clamp(math.floor(sh * 0.48), 260, 460)
	local posX = math.floor(sw * 0.5 - sizeX * 0.5)
	local posY = math.floor(sh * 0.44 - sizeY * 0.5)

	local margin = ScreenScale(6)
	local topBarH = ScreenScaleH(34)
	local footerH = ScreenScaleH(26)
	local rowH = ScreenScaleH(34)
	local listTop = topBarH + ScreenScaleH(4)
	local listH = math.max(sizeY - listTop - footerH - ScreenScaleH(4), ScreenScaleH(60))

	local bloodDrips = {}
	for i = 1, math.random(4, 64) do
		bloodDrips[i] = {
			x = math.random(0, sizeX),
			w = math.random(1, 2),
			h = math.random(ScreenScaleH(8), ScreenScaleH(28)),
			alpha = math.random(8, 20),
			speed = math.Rand(0.15, 0.5),
			offset = math.Rand(0, math.pi * 2),
		}
	end

	local shakeX, shakeY = 0, 0
	local targetShakeX, targetShakeY = 0, 0
	local nextShakeSample = 0
	local shakeStrength = 0.4

	guiltOverlay = vgui.Create("DPanel")
	guiltOverlay:SetSize(sw, sh)
	guiltOverlay:SetPos(0, 0)
	guiltOverlay:SetMouseInputEnabled(true)
	guiltOverlay:SetKeyboardInputEnabled(true)
	guiltOverlay:MakePopup()
	gui.EnableScreenClicker(true)
	guiltOverlay:SetAlpha(0)
	guiltOverlay:AlphaTo(255, 0.12, 0)
	guiltOverlay.OnRemove = function()
		gui.EnableScreenClicker(false)
	end
	guiltOverlay.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 165)
		surface.DrawRect(0, 0, w, h)
	end
	guiltOverlay.OnKeyCodePressed = function(_, key)
		if key == KEY_ESCAPE then close_guilt_menu() end
	end
	guiltOverlay.OnMousePressed = function(self, code)
		if code ~= MOUSE_LEFT then return end
		close_guilt_menu()
	end

	guiltMenu = vgui.Create("DPanel", guiltOverlay)
	guiltMenu:SetPos(posX, posY)
	guiltMenu:SetSize(sizeX, sizeY)
	guiltMenu:SetMouseInputEnabled(true)
	guiltMenu.OnMousePressed = function() end
	guiltMenu.Paint = function(_, w, h)
		surface.SetDrawColor(col.frameBG)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(col.frameBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	guiltMenu.Think = function()
		local t = CurTime()
		if t >= nextShakeSample then
			nextShakeSample = t + 0.035
			targetShakeX = math.Rand(-shakeStrength, shakeStrength)
			targetShakeY = math.Rand(-shakeStrength * 0.6, shakeStrength * 0.6)
		end
		local lerpRate = math.Clamp(FrameTime() * 22, 0, 1)
		shakeX = Lerp(lerpRate, shakeX, targetShakeX)
		shakeY = Lerp(lerpRate, shakeY, targetShakeY)
	end

	guiltMenu.PaintOver = function(self, w, h)
		local t = CurTime()

		if not NoiseMat:IsError() then
			surface.SetMaterial(NoiseMat)
			surface.SetDrawColor(255, 255, 255, 6)
			local nx, ny = math.random(0, 512), math.random(0, 512)
			surface.DrawTexturedRectUV(0, 0, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
		end

		for y = 0, h, 3 do
			surface.SetDrawColor(0, 0, 0, 12)
			surface.DrawRect(0, y, w, 1)
		end

		for _, drip in ipairs(bloodDrips) do
			local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
			surface.SetDrawColor(125, 4, 0, math.floor(drip.alpha * pulse))
			surface.DrawRect(drip.x + shakeX, 0, drip.w, drip.h)
		end

		local title = "ПРОЩЕНИЕ"
		local cx = w * 0.5 + shakeX
		local ty = margin + shakeY
		draw.SimpleText(title, "ZCity_Veteran", cx + 1, ty - 15, Color(90, 8, 6, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(title, "ZCity_Veteran", cx, ty -15, Color(140, 15, 12, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		surface.SetDrawColor(col.separator)
		surface.DrawRect(margin, topBarH - 1, w - margin * 2, 1)
		surface.DrawRect(margin, listTop - ScreenScaleH(2), w - margin * 2, 1)
	end

	local listPanel = vgui.Create("DScrollPanel", guiltMenu)
	listPanel:SetPos(margin, listTop)
	listPanel:SetSize(sizeX - margin * 2, listH)
	listPanel.Paint = function(_, pw, ph)
	end
	styleScrollbar(listPanel:GetVBar())

	local rows = guiltRowsFromPayload(tbl)
	table.sort(rows, function(a, b) return entryHarm(a.data) > entryHarm(b.data) end)

	local count = 0
	for i, rowData in ipairs(rows) do
		local ply = rowData.ply
		local data = rowData.data
		if not IsValid(ply) then continue end

		local harm = entryHarm(data)
		local karmaBack = math.Round(entryKarma(data), 1)
		if harm <= 0.01 and karmaBack <= 0.01 then continue end
		count = count + 1

		local row = vgui.Create("DButton", listPanel:GetCanvas())
		row:Dock(TOP)
		row:SetTall(rowH)
		row:SetText("")

		local avSize = rowH - 8
		local avatar = vgui.Create("AvatarImage", row)
		avatar:SetMouseInputEnabled(false)
		avatar:SetPlayer(ply, 32)

		row.Paint = function(self, rw, rh)
			if i % 2 == 0 then
				surface.SetDrawColor(col.rowAlt)
				surface.DrawRect(0, 0, rw, rh)
			end
			if self:IsHovered() then
				surface.SetDrawColor(col.rowHover)
				surface.DrawRect(0, 0, rw, rh)
				surface.SetDrawColor(col.accent)
				surface.DrawRect(0, rh - 1, rw, 1)
			end
			surface.SetDrawColor(col.rowBorder)
			surface.DrawRect(0, rh - 1, rw, 1)

			local pad = ScreenScale(6)
			local textX = pad + avSize + ScreenScale(6)
			avatar:SetPos(pad, 4)
			avatar:SetSize(avSize, avSize)

			local midW = rw - textX - pad
			if self:IsHovered() then midW = midW - ScreenScale(52) end

			draw.SimpleText(fitText("ZCity_Veteran", ply:Name(), midW), "ZCity_Veteran", textX, rh * 0.32, col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(fitText("ZCity_Veteran", harmLabel(harm) .. " · +" .. karmaBack .. " кармы", midW), "ZCity_Veteran", textX, rh * 0.72, col.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if self:IsHovered() then
				draw.SimpleText("простить", "ZCity_Veteran", rw - pad, rh * 0.5, col.textBlood, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		row.DoClick = function()
			net.Start("forgive_player")
			net.WriteEntity(ply)
			net.SendToServer()
		end
	end

	if count == 0 then
		local empty = vgui.Create("DPanel", listPanel:GetCanvas())
		empty:Dock(TOP)
		empty:SetTall(ScreenScaleH(72))
		empty.Paint = function(_, ew, eh)
			draw.SimpleText("Некого прощать", "ZCity_Veteran", ew * 0.5, eh * 0.4, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			--draw.SimpleText("никто не причинил вам вреда", "ZCity_Veteran_small", ew * 0.5, eh * 0.65, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local footer = vgui.Create("DPanel", guiltMenu)
	footer:SetPos(margin, sizeY - footerH)
	footer:SetSize(sizeX - margin * 2, footerH)
	footer.Paint = function(_, fw, fh)
		surface.SetDrawColor(col.separator)
		surface.DrawRect(0, 0, fw, 1)
		draw.SimpleText("клик - простить / фон - закрыть", "ZCity_Veteran_small", fw * 0.5, fh * 0.45, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end
