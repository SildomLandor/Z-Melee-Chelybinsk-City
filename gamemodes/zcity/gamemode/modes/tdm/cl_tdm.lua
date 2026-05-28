MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "swat4" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

hook.Add( "StartCommand", "TDM_DisallowMoveOrShoting", function( ply, mv )
	--; BLYAT NY NAXUA PISAT VSE V ODNY LINIY BLYAAA
	if (zb.CROUND == "tdm" or zb.CROUND == "cstrike") and (zb.ROUND_START or 0) + 20 > CurTime() then 
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
    local StartTime = zb.ROUND_START or CurTime()
	if StartTime + 7.5 < CurTime() then return end
    local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()
	if StartTime + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Нажмите F3 чтобы открыть магазин", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime( math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i" )
		draw.SimpleText( time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

    if StartTime + 20 < CurTime() then return end
	 
	if not lply:Alive() then return end
	zb.RemoveFade()
    local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
    draw.SimpleText("Мини игры | "..(self.PrintName or "Командный Бой"), "ZCity_Veteran_big", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("Вы - "..Rolename , "ZCity_Veteran", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function MODE:AddHudPaint()
end

net.Receive("tdm_roundend", function()
	zb.EndMenu.Open()
end)

function MODE:RoundStart()
	zb.EndMenu.Close()
end

TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil

local buyCol = {
	frameBG = Color(10, 10, 19, 245),
	frameBorder = Color(90, 90, 95, 120),
	panelBG = Color(8, 8, 16, 245),
	panelBorder = Color(255, 255, 255, 25),
	separator = Color(255, 255, 255, 12),
	text = Color(200, 200, 200, 255),
	textDim = Color(160, 160, 165, 180),
	textMuted = Color(100, 100, 108, 140),
	textMoney = Color(120, 200, 120, 255),
	textBlood = Color(180, 40, 35, 255),
	rowAlt = Color(255, 255, 255, 4),
	rowHover = Color(255, 255, 255, 15),
	rowBorder = Color(255, 255, 255, 8),
	tabActive = Color(140, 15, 12, 180),
	tabIdle = Color(255, 255, 255, 8),
	accent = Color(200, 200, 200, 60),
	scrollTrack = Color(255, 255, 255, 6),
	scrollGrip = Color(200, 200, 200, 60),
	scrollGripHov = Color(200, 200, 200, 100),
	titleRed = Color(140, 15, 12, 255),
	titleDark = Color(90, 8, 6, 255),
	titleShadow = Color(40, 4, 2, 200),
}

local buyNoiseMat = Material("vgui/noisevhs")
if buyNoiseMat:IsError() then buyNoiseMat = Material("vgui/white") end

local function buyFitText(font, text, maxW)
	if not text or maxW <= 0 then return "" end
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

local function buyStyleScrollbar(sbar, col)
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

local function buyTextBtn(parent, text, onClick, tipPrice)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn:SetCursor("hand")
	btn.tipPrice = tipPrice
	btn.Paint = function(self, bw, bh)
		local hovered = self:IsHovered()
		if hovered then
			surface.SetDrawColor(buyCol.rowHover)
			surface.DrawRect(0, 0, bw, bh)
			surface.SetDrawColor(buyCol.accent)
			surface.DrawRect(0, bh - 1, bw, 1)
		end
		draw.SimpleText(text, "ZCity_Veteran_small", bw * 0.5, bh * 0.5, hovered and buyCol.text or buyCol.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if hovered and self.tipPrice then
			local tipText = "$" .. self.tipPrice
			surface.SetFont("ZCity_Veteran_small")
			local tw, th = surface.GetTextSize(tipText)
			local padX, padY = ScreenScale(4), ScreenScaleH(2)
			local tipW, tipH = tw + padX * 2, th + padY * 2
			local tipX = bw * 0.5 - tipW * 0.5
			local tipY = bh + 1

			DisableClipping(true)
			surface.SetDrawColor(buyCol.frameBG)
			surface.DrawRect(tipX, tipY, tipW, tipH)
			surface.SetDrawColor(buyCol.panelBorder)
			surface.DrawOutlinedRect(tipX, tipY, tipW, tipH, 1)
			surface.SetDrawColor(buyCol.accent)
			surface.DrawRect(tipX + 1, tipY + 1, tipW - 2, 1)
			draw.SimpleText(tipText, "ZCity_Veteran_small", bw * 0.5, tipY + tipH * 0.5, buyCol.textMoney, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			DisableClipping(false)
		end
	end
	btn.DoClick = onClick
	return btn
end

local function buyAddItemRow(scroll, catName, itemName, item, rowIdx, buyItems)
	local weapon = weapons.GetStored(item.ItemClass)
	local ent = scripted_ents.GetStored(item.ItemClass)
	local rowH = ScreenScaleH(28)
	local iconH = ScreenScaleH(24)
	local iconW = ScreenScale(34)

	local row = vgui.Create("DPanel", scroll:GetCanvas())
	row:Dock(TOP)
	row:SetTall(rowH)
	row:DockMargin(0, 0, 0, 1)
	row.Paint = function(self, rw, rh)
		if rowIdx % 2 == 0 then
			surface.SetDrawColor(buyCol.rowAlt)
			surface.DrawRect(0, 0, rw, rh)
		end
		if self:IsHovered() then
			surface.SetDrawColor(buyCol.rowHover)
			surface.DrawRect(0, 0, rw, rh)
		end
		surface.SetDrawColor(buyCol.accent)
		surface.DrawRect(0, 2, 2, rh - 4)
		surface.SetDrawColor(buyCol.rowBorder)
		surface.DrawRect(0, rh - 1, rw, 1)
	end

	local iconSlot = vgui.Create("DPanel", row)
	iconSlot:SetPos(ScreenScale(4), (rowH - iconH) * 0.5)
	iconSlot:SetSize(iconW, iconH)
	iconSlot.Paint = function(_, iw, ih)
		surface.SetDrawColor(buyCol.panelBG)
		surface.DrawRect(0, 0, iw, ih)
		surface.SetDrawColor(buyCol.panelBorder)
		surface.DrawOutlinedRect(0, 0, iw, ih, 1)
	end

	local icon = vgui.Create("DImage", iconSlot)
	icon:Dock(FILL)
	icon:DockMargin(2, 2, 2, 2)
	icon:SetKeepAspect(true)
	local iconPath
	if weapon and ((weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName()) or weapon.IconOverride) then
		iconPath = (weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName() .. ".png") or weapon.IconOverride
	elseif ent and ent.t and ent.t.IconOverride then
		iconPath = ent.t.IconOverride
	end
	if iconPath then icon:SetImage(iconPath) end

	local textX = ScreenScale(4) + iconW + ScreenScale(6)
	local midY = rowH * 0.5

	local attBar
	local actions = vgui.Create("DPanel", row)
	actions:Dock(RIGHT)
	actions:SetWide(ScreenScale(96))
	actions:DockMargin(0, ScreenScaleH(4), ScreenScale(2), ScreenScaleH(4))
	actions.Paint = function() end

	local buyBtn = buyTextBtn(actions, "купить", function()
		net.Start("tdm_buyitem")
			net.WriteTable({ catName, itemName })
		net.SendToServer()
	end, item.Price)
	buyBtn:Dock(RIGHT)
	buyBtn:SetWide(ScreenScale(44))

	if weapon then
		local ammo = weapon.Primary.Ammo != "none" and weapon.Primary.Ammo or weapon.Ammo
			or (weapons.GetStored(weapon.Base) and weapons.GetStored(weapon.Base).Primary.Ammo)
		if ammo and hg.ammotypeshuy and hg.ammotypeshuy[ammo] then
			local ammoClass = "ent_ammo_" .. hg.ammotypeshuy[ammo].name
			local ammoName
			for name2, ammoItem in pairs(buyItems["Ammo"] or {}) do
				if istable(ammoItem) and ammoItem.ItemClass == ammoClass then
					ammoName = name2
					break
				end
			end
			if ammoName then
				local ammoPrice = ammoItem and ammoItem.Price
				local ammoBtn = buyTextBtn(actions, "патр.", function()
					net.Start("tdm_buyitem")
						net.WriteTable({ "Ammo", ammoName })
					net.SendToServer()
				end, ammoPrice)
				ammoBtn:Dock(RIGHT)
				ammoBtn:SetWide(ScreenScale(40))
			end
		end
	end

	if item.Attachments and #item.Attachments > 0 then
		local attSize = ScreenScaleH(22)
		attBar = vgui.Create("DPanel", row)
		attBar:Dock(RIGHT)
		attBar:SetWide(attSize * math.min(#item.Attachments, 4) + ScreenScale(2))
		attBar:DockMargin(0, (rowH - attSize) * 0.5, ScreenScale(4), (rowH - attSize) * 0.5)
		attBar.Paint = function() end
		for _, attachN in ipairs(item.Attachments) do
			local ico = hg.attachmentsIcons and hg.attachmentsIcons[attachN]
			if not ico then continue end
			local attBtn = vgui.Create("DImageButton", attBar)
			attBtn:Dock(LEFT)
			attBtn:SetWide(attSize)
			attBtn:DockMargin(0, 0, 1, 0)
			attBtn:SetImage(ico)
			attBtn:SetKeepAspect(true)
			attBtn.Paint = function(self, bw, bh)
				if self:IsHovered() then
					surface.SetDrawColor(buyCol.rowHover)
					surface.DrawRect(0, 0, bw, bh)
				end
				surface.SetDrawColor(buyCol.panelBorder)
				surface.DrawOutlinedRect(0, 0, bw, bh, 1)
			end
			attBtn.DoClick = function()
				net.Start("tdm_buyitem")
					net.WriteTable({ catName, itemName, attachN })
				net.SendToServer()
			end
		end
	end

	row.PaintOver = function(self, rw, rh)
		local rightW = (IsValid(actions) and actions:GetWide() or 0)
			+ (IsValid(attBar) and attBar:GetWide() or 0)
		local nameW = math.max(rw - textX - rightW - ScreenScale(6), ScreenScale(30))
		local nameDraw = buyFitText("ZCity_Veteran_small", itemName, nameW)
		draw.SimpleText(nameDraw, "ZCity_Veteran_small", textX, midY, buyCol.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

local function CloseBuyMenu()
	if IsValid(TDM_OpenedBuyMenu) then
		TDM_OpenedBuyMenu:Remove()
	end
	TDM_OpenedBuyMenu = nil
end

local function OpenBuyMenu()
	local buyItems = MODE.BuyItems
	if not buyItems then return end

	CloseBuyMenu()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local startTime = zb.ROUND_START or CurTime()
	if not ply:Alive() or startTime + 40 < CurTime() then return end

	local sw, sh = ScrW(), ScrH()
	local sizeX = math.Clamp(math.floor(sw * 0.46), 520, 820)
	local sizeY = math.Clamp(math.floor(sh * 0.78), 420, sh - ScreenScaleH(40))
	local posX = math.floor(sw * 0.5 - sizeX * 0.5)
	local posY = math.floor(sh * 0.5 - sizeY * 0.5)
	local margin = ScreenScale(6)
	local topBarH = ScreenScaleH(42)
	local tabBarH = ScreenScaleH(24)
	local footerH = ScreenScaleH(28)
	local listTop = topBarH + tabBarH + ScreenScaleH(6)
	local listH = sizeY - listTop - footerH - ScreenScaleH(4)

	local shakeX, shakeY = 0, 0
	local targetShakeX, targetShakeY = 0, 0
	local nextShake = 0
	local shakeStrength = 0.4
	local openTime = CurTime()

	local frame = vgui.Create("ZFrame")
	TDM_OpenedBuyMenu = frame
	frame:SetPos(posX, posY)
	frame:SetSize(sizeX, sizeY)
	frame:MakePopup()
	frame:SetKeyboardInputEnabled(true)
	frame:ShowCloseButton(false)
	frame:SetColorBG(buyCol.frameBG)
	frame:SetColorBR(buyCol.frameBorder)
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.12, 0)
	frame.OnRemove = function() TDM_OpenedBuyMenu = nil end
	frame.OnKeyCodePressed = function(_, key)
		if key == KEY_ESCAPE then CloseBuyMenu() end
	end

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
		if not buyNoiseMat:IsError() then
			surface.SetMaterial(buyNoiseMat)
			surface.SetDrawColor(255, 255, 255, 6)
			local nx, ny = math.random(0, 512), math.random(0, 512)
			surface.DrawTexturedRectUV(0, 0, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
		end
		for y = 0, h, 3 do
			surface.SetDrawColor(0, 0, 0, 12)
			surface.DrawRect(0, y, w, 1)
		end
		surface.SetDrawColor(buyCol.frameBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local cx = w * 0.5 + shakeX
		local ty = margin + shakeY
		draw.SimpleText("ЗАКУПКИ", "ZCity_Veteran", cx + 1, ty - 12, buyCol.titleDark, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("ЗАКУПКИ", "ZCity_Veteran", cx, ty - 12, buyCol.titleRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		surface.SetDrawColor(buyCol.separator)
		surface.DrawRect(margin, topBarH - 1, w - margin * 2, 1)
	end

	local categories = {}
	for catName in SortedPairsByMemberValue(buyItems, "Priority") do
		categories[#categories + 1] = catName
	end
	if #categories < 1 then return end

	local activeCat = categories[1]
	local tabBtns = {}

	local tabScroll = vgui.Create("DHorizontalScroller", frame)
	tabScroll:SetPos(margin, topBarH + ScreenScaleH(2))
	tabScroll:SetSize(sizeX - margin * 2, tabBarH)
	tabScroll:SetOverlap(-ScreenScale(1))
	tabScroll.Paint = function(_, tw, th)
		surface.SetDrawColor(buyCol.separator)
		surface.DrawRect(0, th - 1, tw, 1)
	end
	tabScroll.btnLeft:SetWide(0)
	tabScroll.btnRight:SetWide(0)
	tabScroll.btnLeft.Paint = function() end
	tabScroll.btnRight.Paint = function() end
	local hScrollerLayout = vgui.GetControlTable("DHorizontalScroller").PerformLayout
	function tabScroll:PerformLayout()
		hScrollerLayout(self)
		self.btnLeft:SetVisible(false)
		self.btnRight:SetVisible(false)
	end

	local contentHost = vgui.Create("DPanel", frame)
	contentHost:SetPos(margin, listTop)
	contentHost:SetSize(sizeX - margin * 2, listH)
	contentHost.Paint = function(_, pw, ph)
		--surface.SetDrawColor(buyCol.panelBG)
		--surface.DrawRect(0, 0, pw, ph)
		surface.SetDrawColor(buyCol.panelBorder)
		surface.DrawOutlinedRect(0, 0, pw, ph, 1)
	end

	local catPanels = {}
	local function showCategory(catName)
		activeCat = catName
		for name, pnl in pairs(catPanels) do
			if IsValid(pnl) then pnl:SetVisible(name == catName) end
		end
		for name, btn in pairs(tabBtns) do
			if IsValid(btn) then btn.active = (name == catName) end
		end
	end

	for _, catName in ipairs(categories) do
		surface.SetFont("ZCity_Veteran_small")
		local tabW = surface.GetTextSize(catName) + ScreenScale(10)
		local tabBtn = vgui.Create("DButton")
		tabBtn:SetSize(tabW, tabBarH - 2)
		tabBtn:SetText("")
		tabBtn.active = catName == activeCat
		tabBtn.Paint = function(self, bw, bh)
			if self.active then
				surface.SetDrawColor(buyCol.tabActive)
				surface.DrawRect(0, 0, bw, bh)
			elseif self:IsHovered() then
				surface.SetDrawColor(buyCol.tabIdle)
				surface.DrawRect(0, 0, bw, bh)
			end
			draw.SimpleText(catName, "ZCity_Veteran_small", bw * 0.5, bh * 0.5, self.active and buyCol.text or buyCol.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		tabBtn.DoClick = function() showCategory(catName) end
		tabScroll:AddPanel(tabBtn)
		tabBtns[catName] = tabBtn

		local scroll = vgui.Create("DScrollPanel", contentHost)
		scroll:Dock(FILL)
		scroll:SetVisible(catName == activeCat)
		scroll:DockMargin(ScreenScale(4), ScreenScale(4), ScreenScale(4), ScreenScale(4))
		scroll.Paint = function() end
		buyStyleScrollbar(scroll:GetVBar(), buyCol)
		catPanels[catName] = scroll

		local rowIdx = 0
		for itemName, item in pairs(buyItems[catName]) do
			if itemName == "Priority" or not istable(item) then continue end
			rowIdx = rowIdx + 1
			buyAddItemRow(scroll, catName, itemName, item, rowIdx, buyItems)
		end
	end

	local footer = vgui.Create("DPanel", frame)
	footer:SetPos(margin, sizeY - footerH)
	footer:SetSize(sizeX - margin * 2, footerH)
	footer.Paint = function(_, fw, fh)
		surface.SetDrawColor(buyCol.separator)
		surface.DrawRect(0, 0, fw, 1)
		local money = ply:GetNWInt("TDM_Money", 0)
		local left = "время: " .. string.FormattedTime(math.max(startTime + 40 - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(left, "ZCity_Veteran_small", ScreenScale(4), fh * 0.5, buyCol.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("$" .. money, "ZCity_Veteran", fw - ScreenScale(4), fh * 0.5, buyCol.textMoney, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	footer.Think = function()
		if not IsValid(ply) or not ply:Alive() or startTime + 40 < CurTime() then
			CloseBuyMenu()
		end
	end
end

net.Receive("tdm_open_buymenu", function()
	OpenBuyMenu()
end)

function zb.OpenBuyMenu()
	OpenBuyMenu()
end

hook.Add("zbOpenBuyMenu", "tdm", function()
	OpenBuyMenu()
end)