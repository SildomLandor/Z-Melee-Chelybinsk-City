zb = zb or {}

local EndMenu = {}

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local function GetPalette()
	return {
		frameBG = Color(10, 10, 19, 235),
		frameBorder = Color(90, 90, 95, 120),
		panelBG = Color(8, 8, 16, 245),
		panelBorder = Color(255, 255, 255, 25),
		headerBG = Color(6, 6, 14, 250),
		headerBorder = Color(255, 255, 255, 18),
		headerHover = Color(255, 255, 255, 12),
		headerText = Color(200, 200, 200, 180),
		rowAlt = Color(255, 255, 255, 4),
		rowHover = Color(255, 255, 255, 15),
		rowSelected = Color(255, 255, 255, 22),
		rowBorder = Color(255, 255, 255, 8),
		rowAlive = Color(200, 200, 200, 255),
		rowDead = Color(160, 35, 35, 255),
		rowWinner = Color(217, 201, 99, 255),
		text = Color(200, 200, 200, 255),
		textDim = Color(160, 160, 165, 180),
		textMuted = Color(100, 100, 108, 140),
		textBlood = Color(180, 40, 35, 255),
		textTitle = Color(200, 200, 200, 255),
		titleRed = Color(140, 15, 12, 255),
		titleDark = Color(90, 8, 6, 255),
		titleShadow = Color(40, 4, 2, 200),
		accent = Color(200, 200, 200, 60),
		separator = Color(255, 255, 255, 12),
		scrollTrack = Color(255, 255, 255, 6),
		scrollGrip = Color(200, 200, 200, 60),
		scrollGripHov = Color(200, 200, 200, 100),
	}
end

local function StyleScrollbar(sbar, col)
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

local function FitText(font, text, maxW)
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxW then return text end
	local dots = "…"
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

function EndMenu.Close()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
	end
	hmcdEndMenu = nil
end

function EndMenu.Open(opts)
	opts = opts or {}
	EndMenu.Close()

	local col = GetPalette()
	local shakeX, shakeY = 0, 0
	local targetShakeX, targetShakeY = 0, 0
	local nextShake = 0
	local shakeStrength = 0.55
	local openTime = CurTime()

	local sizeX = math.floor(ScrW() / 2.5)
	local sizeY = math.floor(ScrH() / 1.2)
	local posX = math.floor(ScrW() / 1.3 - sizeX * 0.5)
	local posY = math.floor(ScrH() * 0.5 - sizeY * 0.5)
	local margin = ScreenScale(8)
	local topBarH = ScreenScaleH(52)
	local headerH = ScreenScaleH(22)
	local rowH = ScreenScaleH(30)
	local listY = topBarH + headerH + ScreenScaleH(4)
	local listH = sizeY - listY - margin

	local titleText = opts.title or "Конец раунда"
	local subtitle = opts.subtitle
	local filter = opts.filter or function(ply) return ply:Team() ~= TEAM_SPECTATOR end

	if opts.sound ~= false then
		surface.PlaySound(opts.sound or "ambient/alarms/warningbell1.wav")
	end

	local frame = vgui.Create("ZFrame")
	frame:SetPos(posX, posY)
	frame:SetSize(sizeX, sizeY)
	frame:MakePopup()
	frame:SetKeyboardInputEnabled(false)
	frame:ShowCloseButton(false)
	frame:SetColorBG(col.frameBG)
	frame:SetColorBR(col.frameBorder)
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.12, 0)

	function frame:OnClose()
		hmcdEndMenu = nil
	end

	hmcdEndMenu = frame

	frame.Think = function()
		local t = CurTime()
		if t >= nextShake then
			nextShake = t + 0.035
			targetShakeX = math.Rand(-shakeStrength, shakeStrength)
			targetShakeY = math.Rand(-shakeStrength * 0.6, shakeStrength * 0.6)
		end
		local rate = math.Clamp(FrameTime() * 22, 0, 1)
		shakeX = Lerp(rate, shakeX, targetShakeX)
		shakeY = Lerp(rate, shakeY, targetShakeY)
	end

	frame.PaintOver = function(self, w, h)
		local t = CurTime()
		local age = t - openTime

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

		surface.SetDrawColor(col.frameBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		surface.SetFont("ZC_MM_Title")
		local tw, th = surface.GetTextSize(titleText)
		local pulse = math.sin(t * 1.5) * 0.12 + 0.88
		local tx = w * 0.5 + shakeX
		local ty = ScreenScaleH(8) + shakeY
		draw.SimpleText(titleText, "ZC_MM_Title", tx + 2, ty + 2, col.titleShadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(titleText, "ZC_MM_Title", tx + 1, ty + 1, col.titleDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(titleText, "ZC_MM_Title", tx, ty, Color(col.titleRed.r * pulse, col.titleRed.g * pulse, col.titleRed.b * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		if isstring(subtitle) and subtitle ~= "" then
			local subY = ty + th + ScreenScaleH(2)
			draw.SimpleText(subtitle, "ZCity_Veteran", w * 0.5 - 30 + shakeX * 0.5, subY, opts.subtitleColor or col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end

		surface.SetDrawColor(col.separator)
		surface.DrawRect(margin, topBarH - 8, w - margin * 2, 1)

		--surface.SetFont("ZCity_Veteran")
		--surface.SetTextColor(col.textTitle)
		--surface.SetTextPos(margin + ScreenScale(2) + shakeX * 0.4, topBarH + ScreenScaleH(1) + shakeY * 0.3)
		--surface.DrawText("ИГРОКИ")

		local count = 0
		for _, ply in player.Iterator() do
			if filter(ply) then count = count + 1 end
		end
		--surface.SetFont("ZB_InterfaceSmall")
		--surface.SetTextColor(col.textMuted)
		--local cntStr = " [" .. count .. "]"
		--local ispW = surface.GetTextSize("ИГРОКИ")
		--surface.SetTextPos(margin + ScreenScale(2) + ispW + 4 + shakeX * 0.3, topBarH + ScreenScaleH(3) + shakeY * 0.3)
		--surface.DrawText(cntStr)

		if age > 0.5 and math.random() > 0.985 then
			surface.SetDrawColor(255, 255, 255, math.random(5, 18))
			surface.DrawRect(0, math.random(0, h), w, math.random(1, 3))
		end
	end

	local colHeader = vgui.Create("DPanel", frame)
	colHeader:SetPos(margin, topBarH + ScreenScaleH(2))
	colHeader:SetSize(sizeX - margin * 2, headerH)
	colHeader:SetZPos(50)
	colHeader.Paint = function(_, hw, hh)
		--surface.SetDrawColor(col.headerBG)
		--surface.DrawRect(0, 0, hw, hh)
		surface.SetDrawColor(col.headerBorder)
		surface.DrawRect(0, hh - 1, hw, 1)
		draw.SimpleText("Имя", "ZCity_Veteran", 8, hh * 0.5, col.headerText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("Убийства", "ZCity_Veteran", hw - 70, hh * 0.5, col.headerText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		--surface.SetDrawColor(col.separator)
		--surface.DrawRect(hw * 0.72, 4, 1, hh - 8)
	end

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:SetPos(margin, listY)
	scroll:SetSize(sizeX - margin * 2, listH)
	StyleScrollbar(scroll:GetVBar(), col)

	local players = {}
	for _, ply in player.Iterator() do
		if not filter(ply) then continue end
		players[#players + 1] = ply
	end

	table.sort(players, function(a, b)
		if not IsValid(a) then return false end
		if not IsValid(b) then return true end
		local fa, fb = a:Frags() or 0, b:Frags() or 0
		if fa ~= fb then return fa > fb end
		return (a:UserID() or 0) < (b:UserID() or 0)
	end)

	local rowStyle = opts.rowStyle

	for idx, ply in ipairs(players) do
		local row = vgui.Create("DButton", scroll)
		row:SetTall(rowH)
		row:Dock(TOP)
		row:SetText("")
		row:SetCursor("hand")

		local avatarSize = rowH - 6
		local avatar = vgui.Create("AvatarImage", row)
		avatar:SetMouseInputEnabled(false)
		avatar:SetPlayer(ply, 32)

		local wave = idx * 0.75

		row.Paint = function(self, rw, rh)
			if not IsValid(ply) then return end
			local t = CurTime()
			local wX = math.sin(t * 28 + wave) * shakeStrength * 0.25
			local wY = math.cos(t * 24 + wave) * shakeStrength * 0.2

			if idx % 2 == 0 then
				surface.SetDrawColor(col.rowAlt)
				surface.DrawRect(0, 0, rw, rh)
			end

			if self:IsHovered() then
				surface.SetDrawColor(col.rowHover)
				surface.DrawRect(0, 0, rw, rh)
				surface.SetDrawColor(col.accent)
				surface.DrawRect(0, rh - 1, rw, 1)
			end

			local style = rowStyle and rowStyle(ply) or nil
			local barCol = style and style.bar
			if not barCol then
				if style and style.winner then
					barCol = col.rowWinner
				elseif ply:Alive() then
					barCol = col.rowAlive
				else
					barCol = col.rowDead
				end
			end
			surface.SetDrawColor(barCol.r, barCol.g, barCol.b, 120)
			surface.DrawRect(0, 2, 2, rh - 4)

			surface.SetDrawColor(col.rowBorder)
			surface.DrawRect(0, rh - 1, rw, 1)

			local ax = 6 + wX
			avatar:SetPos(ax, 3 + wY)
			avatar:SetSize(avatarSize, avatarSize)

			local nameX = ax + avatarSize + 8
			local nameW = math.floor(rw * 0.72) - nameX
			local suffix = ""
			if opts.statusText then
				suffix = opts.statusText(ply) or ""
			elseif not ply:Alive() then
				suffix = " - мёртв"
			end

			local displayName = (ply:Name() or "???") .. suffix
			local nameCol = style and style.nameCol
			if not nameCol then
				if style and style.winner then
					nameCol = col.rowWinner
				elseif ply:Alive() then
					nameCol = col.text
				else
					nameCol = col.textBlood
				end
			end

			draw.SimpleText(FitText("ZCity_Veteran", displayName, nameW - 8), "ZCity_Veteran", nameX, rh * 0.5 + wY, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(tostring(ply:Frags() or 0), "ZCity_Veteran", rw * 0.9 + wX, rh * 0.5 + wY, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			surface.SetDrawColor(col.separator)
			surface.DrawRect(math.floor(rw * 0.8), 4, 1, rh - 8)
		end

		row.DoClick = function()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "ботов нельзя")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
	end

	return frame
end

zb.EndMenu = EndMenu

concommand.Add("zb_test_endmenu", function()
	local mode = CurrentRound and CurrentRound()
	local title = "Конец раунда"
	if mode and mode.PrintName then
		title = mode.PrintName
	elseif zb.CROUND then
		title = zb.CROUND
	end

	zb.EndMenu.Open({
		title = title,
		subtitle = "Предатели выиграли в этом раунде",
		subtitleColor = Color(217, 201, 99),
		sound = false,
		statusText = function(ply)
			if not ply:Alive() then return " - мёртв" end
			if ply == LocalPlayer() then return " - ты" end
			return ""
		end,
	})
end)
