hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance
local PANEL = {}

local colors = {}
colors.secondary = Color(25, 25, 35, 195)
colors.mainText = Color(255, 255, 255, 255)
colors.selectionBG = Color(20, 130, 25, 225)
colors.presetBG = Color(35, 35, 45, 220)
colors.presetBorder = Color(80, 80, 100, 255)
colors.presetHover = Color(50, 50, 65, 240)
colors.scrollbarBG = Color(20, 20, 30, 200)
colors.scrollbarGrip = Color(70, 70, 90, 255)
colors.scrollbarGripHover = Color(100, 100, 130, 255)
colors.scrollbarBorder = Color(100, 100, 120, 200)

local presetsDir = "zcity/appearances/presets/"
local menuBtnPadding = ScreenScale(4)

local function PaintMenuLabel(s, w, h)
	local font = s:GetFont()
	local text = s:GetText()
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	local totalW = tw + menuBtnPadding * 2

	if s:IsHovered() then
		if not s.HoveredSoundPlayed then
			sound.PlayFile("sound/hover.ogg", "noblock", function(station) if IsValid(station) then station:Play() end end)
			s.HoveredSoundPlayed = true
		end

		local alpha = 255
		if math.random() > 0.9 then alpha = math.random(50, 200) end

		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(0, 0, totalW, h)
		s:SetTextColor(Color(0, 0, 0, alpha))
	else
		s.HoveredSoundPlayed = false
		s:SetTextColor(Color(255, 255, 255))
	end

	local offX, offY = 0, 0
	if math.random() > 0.9 then
		offX = math.random(-2, 2)
		offY = math.random(-2, 2)
	end

	draw.SimpleText(text, font, menuBtnPadding + offX, h / 2 + offY, s:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	if s:IsHovered() and math.random() > 0.7 then
		draw.SimpleText(text, font, menuBtnPadding + math.random(-5, 5), h / 2 + math.random(-2, 2), Color(0, 0, 0, math.random(50, 150)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	return true
end

local function WireMenuLabel(btn, onClick)
	btn:SetMouseInputEnabled(true)
	btn:SetCursor("hand")

	function btn:DoClick()
		sound.PlayFile("sound/press.mp3", "noblock", function(station) if IsValid(station) then station:Play() end end)
		if onClick then onClick() end
	end

	function btn:OnMousePressed(mc)
		if mc == MOUSE_LEFT then self:DoClick() end
	end
end

local function SavePreset(strName, tblAppearance)
	file.CreateDir(presetsDir)
	file.Write(presetsDir .. strName .. ".json", util.TableToJSON(tblAppearance, true))
end

local function LoadPreset(strName)
	if not file.Exists(presetsDir .. strName .. ".json", "DATA") then return nil end
	return util.JSONToTable(file.Read(presetsDir .. strName .. ".json", "DATA"))
end

local function GetPresetList()
	file.CreateDir(presetsDir)
	local files = file.Find(presetsDir .. "*.json", "DATA")
	local presets = {}
	for _, f in ipairs(files or {}) do
		table.insert(presets, string.StripExtension(f))
	end
	return presets
end

local function DeletePreset(strName)
	if file.Exists(presetsDir .. strName .. ".json", "DATA") then
		file.Delete(presetsDir .. strName .. ".json")
		return true
	end
	return false
end

hg.Appearance.SavePreset = SavePreset
hg.Appearance.LoadPreset = LoadPreset
hg.Appearance.GetPresetList = GetPresetList
hg.Appearance.DeletePreset = DeletePreset

local modelsPrecached = false
local function PrecacheAccessoryModels()
	if modelsPrecached then return end
	modelsPrecached = true

	timer.Simple(0.1, function()
		if APmodule.PlayerModels then
			for _, sexModels in pairs(APmodule.PlayerModels) do
				for _, modelData in pairs(sexModels) do
					if modelData.mdl then
						util.PrecacheModel(modelData.mdl)
					end
				end
			end
		end

		if hg.Accessories then
			for _, accessory in pairs(hg.Accessories) do
				if accessory.model then
					util.PrecacheModel(accessory.model)
				end
			end
		end
	end)
end

hook.Add("InitPostEntity", "HG_PrecacheAppearanceModels", function()
	timer.Simple(5, PrecacheAccessoryModels)
end)

hg.Appearance.PrecacheModels = PrecacheAccessoryModels

local function CreateStyledScrollPanel(parent)
	local scroll = vgui.Create("DScrollPanel", parent)

	local sbar = scroll:GetVBar()
	sbar:SetWide(ScreenScale(4))
	sbar:SetHideButtons(true)

	function sbar:Paint(w, h)
		draw.RoundedBox(4, 0, 0, w, h, colors.scrollbarBG)
		surface.SetDrawColor(colors.scrollbarBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function sbar.btnGrip:Paint(w, h)
		local col = self:IsHovered() and colors.scrollbarGripHover or colors.scrollbarGrip
		draw.RoundedBox(4, 2, 2, w - 4, h - 4, col)
		surface.SetDrawColor(colors.scrollbarBorder)
		surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
	end

	return scroll
end

local clr_ico, clr_menu = Color(30, 30, 40, 255), Color(15, 15, 20, 250)
local openMenus = {}
local function RegisterOpenMenu(menu)
    if not IsValid(menu) then return end
    table.insert(openMenus, menu)
end
local function CloseAllOpenMenus()
    for i = #openMenus, 1, -1 do
        local m = openMenus[i]
        if IsValid(m) then
            if m.Close then m:Close() else m:Remove() end
        end
        table.remove(openMenus, i)
    end
end

local function AddDropdownOption(drop, scroll, text, onClick)
	local btn = vgui.Create("DLabel", scroll:GetCanvas())
	btn:SetText(text)
	btn:SetFont("ZCity_Veteran")
	btn:SetTextColor(Color(255, 255, 255))
	btn:SetContentAlignment(4)
	btn:Dock(TOP)
	btn:DockMargin(0, 0, 0, ScreenScale(3))
	btn:SizeToContents()
	btn:SetWide(math.max(btn:GetWide() + ScreenScale(8), drop:GetWide() - ScreenScale(8)))
	btn:SetTall(math.max(ScreenScale(16), btn:GetTall()))
	btn.Paint = PaintMenuLabel
	WireMenuLabel(btn, function()
		if onClick then onClick() end
		if IsValid(drop) then drop:Close() end
	end)
	scroll:InvalidateLayout(true)
	return btn
end

local function CreateAnchorDropdown(parent, anchor, wide, maxTall, build, openUp)
	CloseAllOpenMenus()

	local drop = vgui.Create("DPanel", parent)
	local ax, ay = anchor:LocalToScreen(0, 0)
	local px, py = parent:LocalToScreen(0, 0)
	local anchorTall = anchor:GetTall()

	drop:SetPos(ax - px, ay - py + (openUp and -maxTall or anchorTall + ScreenScale(2)))
	drop:SetWide(wide or anchor:GetWide())
	drop:SetTall(0)
	drop:SetZPos(110)
	drop:SetMouseInputEnabled(true)
	drop.TargetTall = maxTall
	drop.OpenFrac = 0
	drop.Closing = false
	drop.Anchor = anchor
	drop.OpenUp = openUp
	drop._openedAt = SysTime()

	function drop:Paint(w, h)
		surface.SetDrawColor(10, 10, 10, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(40, 40, 40, 220)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function drop:Close()
		self.Closing = true
	end

	function drop:Think()
		local target = self.Closing and 0 or 1
		self.OpenFrac = Lerp(FrameTime() * 12, self.OpenFrac, target)
		local tall = math.max(1, self.TargetTall * self.OpenFrac)
		self:SetTall(tall)

		if IsValid(self.Anchor) then
			local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
			local px2, py2 = parent:LocalToScreen(0, 0)
			if self.OpenUp then
				self:SetPos(ax2 - px2, ay2 - py2 - tall - ScreenScale(2))
			else
				self:SetPos(ax2 - px2, ay2 - py2 + self.Anchor:GetTall() + ScreenScale(2))
			end
		end

		if self.Closing and self.OpenFrac < 0.02 then
			self:Remove()
			return
		end

		if self.Closing or SysTime() - self._openedAt < 0.15 then return end
		if not input.IsMouseDown(MOUSE_LEFT) then return end

		local mx, my = gui.MouseX(), gui.MouseY()
		local dx, dy = self:LocalToScreen(0, 0)
		local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
		local aw, ah = self.Anchor:GetSize()

		local inDrop = mx >= dx and mx <= dx + self:GetWide() and my >= dy and my <= dy + self:GetTall()
		local inAnchor = mx >= ax2 and mx <= ax2 + aw and my >= ay2 and my <= ay2 + ah
		if not inDrop and not inAnchor then self:Close() end
	end

	local scroll = CreateStyledScrollPanel(drop)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(4), ScreenScale(4), ScreenScale(4), ScreenScale(4))
	drop.Scroll = scroll

	if build then build(drop, scroll) end

	timer.Simple(0, function()
		if not IsValid(drop) or not IsValid(scroll) then return end
		local canvas = scroll:GetCanvas()
		local contentH = (IsValid(canvas) and canvas:GetTall() or 0) + ScreenScale(8)
		drop.TargetTall = math.min(maxTall, math.max(ScreenScale(20), contentH))

		if IsValid(anchor) then
			local ax2, ay2 = anchor:LocalToScreen(0, 0)
			local px2, py2 = parent:LocalToScreen(0, 0)
			if drop.OpenUp then
				drop:SetPos(ax2 - px2, ay2 - py2 - drop.TargetTall - ScreenScale(2))
			else
				drop:SetPos(ax2 - px2, ay2 - py2 + anchor:GetTall() + ScreenScale(2))
			end
		end
	end)

	RegisterOpenMenu(drop)
	drop:MoveToFront()
	return drop
end

local function CreateSlideSidePanel(parent, anchor, wide, maxTall, build, onClose, panelX, panelY)
	if not IsValid(anchor) then return end
	CloseAllOpenMenus()

	anchor.BaseX = anchor.BaseX or anchor:GetPos()
	anchor.BaseY = anchor.BaseY or select(2, anchor:GetPos())
	local gap = ScreenScale(6)

	local panel = vgui.Create("DPanel", parent)
	panel:SetPos(panelX or anchor.BaseX, panelY or anchor.BaseY)
	panel:SetWide(0)
	panel:SetTall(maxTall)
	panel:SetZPos(55)
	panel:SetMouseInputEnabled(true)
	panel.TargetWide = wide
	panel.OpenFrac = 0
	panel.Closing = false
	panel.Anchor = anchor
	panel.BaseX = panelX or anchor.BaseX
	panel.BaseY = panelY or anchor.BaseY
	panel.Gap = gap
	panel._openedAt = SysTime()

	function panel:Paint(w, h)
		surface.SetDrawColor(12, 12, 12, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(45, 45, 45, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function panel:Close()
		self.Closing = true
	end

	function panel:Think()
		local target = self.Closing and 0 or 1
		self.OpenFrac = Lerp(FrameTime() * 12, self.OpenFrac, target)
		local curWide = math.max(1, self.TargetWide * self.OpenFrac)
		self:SetWide(curWide)
		self:SetPos(self.BaseX, self.BaseY)

		if IsValid(self.Anchor) then
			self.Anchor:SetPos(self.BaseX + curWide + self.Gap * self.OpenFrac, self.Anchor.BaseY)
			self.Anchor:MoveToFront()
		end

		if self.Closing and self.OpenFrac < 0.02 then
			self:Remove()
			return
		end

		if self.Closing or SysTime() - self._openedAt < 0.15 then return end
		if not input.IsMouseDown(MOUSE_LEFT) then return end

		local mx, my = gui.MouseX(), gui.MouseY()
		local dx, dy = self:LocalToScreen(0, 0)
		local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
		local aw, ah = self.Anchor:GetSize()

		local inPanel = mx >= dx and mx <= dx + self:GetWide() and my >= dy and my <= dy + self:GetTall()
		local inAnchor = mx >= ax2 and mx <= ax2 + aw and my >= ay2 and my <= ay2 + ah
		if not inPanel and not inAnchor then self:Close() end
	end

	local scroll = CreateStyledScrollPanel(panel)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(4), ScreenScale(4), ScreenScale(4), ScreenScale(4))
	scroll.Paint = function(s, w, h)
		surface.SetDrawColor(12, 12, 12, 255)
		surface.DrawRect(0, 0, w, h)
	end
	panel.Scroll = scroll

	if build then build(panel, scroll) end

	function panel:OnRemove()
		if IsValid(anchor) then
			anchor:SetPos(anchor.BaseX, anchor.BaseY)
			anchor.SlidePanel = nil
		end
		if onClose then onClose() end
	end

	RegisterOpenMenu(panel)
	anchor.SlidePanel = panel
	panel:MoveToFront()
	anchor:MoveToFront()
	return panel
end

local function CreateSlideSidePanelRight(parent, anchor, wide, maxTall, build, onClose, panelRightX, panelY)
	if not IsValid(anchor) then return end
	CloseAllOpenMenus()

	anchor.BaseX = anchor.BaseX or anchor:GetPos()
	anchor.BaseY = anchor.BaseY or select(2, anchor:GetPos())
	local gap = ScreenScale(6)

	local panel = vgui.Create("DPanel", parent)
	panel:SetPos((panelRightX or (anchor.BaseX + anchor:GetWide())) - 1, panelY or anchor.BaseY)
	panel:SetWide(0)
	panel:SetTall(maxTall)
	panel:SetZPos(55)
	panel:SetMouseInputEnabled(true)
	panel.TargetWide = wide
	panel.OpenFrac = 0
	panel.Closing = false
	panel.Anchor = anchor
	panel.BaseRightX = panelRightX or (anchor.BaseX + anchor:GetWide())
	panel.BaseY = panelY or anchor.BaseY
	panel.Gap = gap
	panel._openedAt = SysTime()

	function panel:Paint(w, h)
		surface.SetDrawColor(12, 12, 12, 255)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(45, 45, 45, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function panel:Close()
		self.Closing = true
	end

	function panel:Think()
		local target = self.Closing and 0 or 1
		self.OpenFrac = Lerp(FrameTime() * 12, self.OpenFrac, target)
		local curWide = math.max(1, self.TargetWide * self.OpenFrac)
		self:SetWide(curWide)
		self:SetPos(self.BaseRightX - curWide, self.BaseY)

		if IsValid(self.Anchor) then
			self.Anchor:SetPos(self.BaseRightX - curWide - self.Gap * self.OpenFrac - self.Anchor:GetWide(), self.Anchor.BaseY)
			self.Anchor:MoveToFront()
		end

		if self.Closing and self.OpenFrac < 0.02 then
			self:Remove()
			return
		end

		if self.Closing or SysTime() - self._openedAt < 0.15 then return end
		if not input.IsMouseDown(MOUSE_LEFT) then return end

		local mx, my = gui.MouseX(), gui.MouseY()
		local dx, dy = self:LocalToScreen(0, 0)
		local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
		local aw, ah = self.Anchor:GetSize()

		local inPanel = mx >= dx and mx <= dx + self:GetWide() and my >= dy and my <= dy + self:GetTall()
		local inAnchor = mx >= ax2 and mx <= ax2 + aw and my >= ay2 and my <= ay2 + ah
		if not inPanel and not inAnchor then self:Close() end
	end

	local scroll = CreateStyledScrollPanel(panel)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(4), ScreenScale(4), ScreenScale(4), ScreenScale(4))
	scroll.Paint = function(s, w, h)
		surface.SetDrawColor(12, 12, 12, 255)
		surface.DrawRect(0, 0, w, h)
	end
	panel.Scroll = scroll

	if build then build(panel, scroll) end

	function panel:OnRemove()
		if IsValid(anchor) then
			anchor:SetPos(anchor.BaseX, anchor.BaseY)
			anchor.SlidePanel = nil
		end
		if onClose then onClose() end
	end

	RegisterOpenMenu(panel)
	anchor.SlidePanel = panel
	panel:MoveToFront()
	anchor:MoveToFront()
	return panel
end

local function CreateStyledListMenu(title)
    local menu = vgui.Create("DPanel")
    menu:SetSize(ScrW() * 0.75, ScrH() * 0.75)
    menu:Center()
    menu:MakePopup()
    RegisterOpenMenu(menu)

    function menu:Paint(w, h)
        surface.SetDrawColor(10, 10, 10, 230)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(25, 25, 25, 230)
        surface.DrawRect(0, 0, w, ScreenScale(16))
        surface.SetDrawColor(40, 40, 40, 220)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(string.upper(title or ""), "ZCity_Veteran", ScreenScale(4), ScreenScale(8), Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DLabel", menu)
    closeBtn:SetSize(ScreenScale(12), ScreenScale(12))
    closeBtn:SetPos(menu:GetWide() - ScreenScale(12), 0)
    closeBtn:SetText("X")
    closeBtn:SetFont("ZCity_Tiny")
    closeBtn:SetTextColor(Color(200, 200, 200))
    closeBtn:SetContentAlignment(5)
    closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(0, 0, w, h)
            s:SetTextColor(Color(255, 255, 255))
        else
            s:SetTextColor(Color(200, 200, 200))
        end
        draw.SimpleText("X", s:GetFont(), w / 2, h / 2, s:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end
    WireMenuLabel(closeBtn, function() menu:Remove() end)

    local scroll = CreateStyledScrollPanel(menu)
    scroll:Dock(FILL)
    scroll:DockMargin(ScreenScale(10), ScreenScale(16), ScreenScale(10), ScreenScale(10))
    scroll:SetMouseInputEnabled(true)
    menu.ScrollPanel = scroll

    function menu:AddOption(text, onClick)
        local btn = vgui.Create("DLabel", self.ScrollPanel)
        btn:SetText(text)
        btn:SetFont("ZCity_Veteran")
        btn:SetTextColor(Color(255, 255, 255))
        btn:SetContentAlignment(4)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, ScreenScale(4))
        btn:SizeToContents()
        btn:SetWide(btn:GetWide() + ScreenScale(8))
        btn:SetTall(math.max(ScreenScale(16), btn:GetTall()))
        btn.Paint = PaintMenuLabel
        WireMenuLabel(btn, function()
            if onClick then onClick() end
            if IsValid(menu) then menu:Remove() end
        end)
        return btn
    end

    function menu:AddPanel(pnl)
        pnl:SetParent(self.ScrollPanel)
        pnl:Dock(TOP)
        pnl:DockMargin(0, 0, 0, ScreenScale(6))
    end

    return menu
end

local function CreateStyledAccessoryMenu(parent, title)
	local menu = vgui.Create("DPanel")
	menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	menu:Center()
	menu:MakePopup()
	menu.IsOpen = true

	function menu:Paint(w, h)
		surface.SetDrawColor(10, 10, 10, 230)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(25, 25, 25, 230)
		surface.DrawRect(0, 0, w, ScreenScale(16))
		surface.SetDrawColor(40, 40, 40, 220)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(string.upper(title or ""), "ZCity_Veteran", ScreenScale(4), ScreenScale(8), Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local closeBtn = vgui.Create("DLabel", menu)
	closeBtn:SetSize(ScreenScale(12), ScreenScale(12))
	closeBtn:SetPos(menu:GetWide() - ScreenScale(12), 0)
	closeBtn:SetText("X")
	closeBtn:SetFont("ZCity_Tiny")
	closeBtn:SetTextColor(Color(200, 200, 200))
	closeBtn:SetContentAlignment(5)
	closeBtn.Paint = function(s, w, h)
		if s:IsHovered() then
			surface.SetDrawColor(255, 0, 0, 255)
			surface.DrawRect(0, 0, w, h)
			s:SetTextColor(Color(255, 255, 255))
		else
			s:SetTextColor(Color(200, 200, 200))
		end
		draw.SimpleText("X", s:GetFont(), w / 2, h / 2, s:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return true
	end
	WireMenuLabel(closeBtn, function() menu:Remove() end)

	local scroll = CreateStyledScrollPanel(menu)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(10), ScreenScale(16), ScreenScale(10), ScreenScale(10))

	local iconLayout = vgui.Create("DIconLayout", scroll:GetCanvas())
	iconLayout:Dock(TOP)
	local spaceX = ScreenScale(5)
	local spaceY = ScreenScale(5)
	iconLayout:SetSpaceX(spaceX)
	iconLayout:SetSpaceY(spaceY)
	iconLayout:SetLayoutDir(LEFT)
	iconLayout:SetWide(scroll:GetCanvas():GetWide())

	function iconLayout:PerformLayout()
		local wide = self:GetWide()
		local x = 0
		local y = 0
		local rowH = 0
		for _, pnl in ipairs(self:GetChildren()) do
			if not IsValid(pnl) or not pnl:IsVisible() then continue end
			local w, h = pnl:GetSize()
			if x + w > wide and x > 0 then
				x = 0
				y = y + rowH + spaceY
				rowH = 0
			end
			pnl:SetPos(x, y)
			x = x + w + spaceX
			if h > rowH then rowH = h end
		end
		self:SetTall(y + rowH)
	end

	function scroll:PerformLayout()
		DScrollPanel.PerformLayout(self)
		local vbar = self:GetVBar()
		local wide = self:GetWide()
		if IsValid(vbar) then wide = wide - vbar:GetWide() end
		iconLayout:SetWide(wide)
		iconLayout:InvalidateLayout(true)
		iconLayout:PerformLayout()
	end

	function menu:PerformLayout()
		local vbar = scroll:GetVBar()
		local wide = scroll:GetWide()
		if IsValid(vbar) then wide = wide - vbar:GetWide() end
		iconLayout:SetWide(wide)
		iconLayout:InvalidateLayout(true)
		iconLayout:PerformLayout()
	end

	menu.IconLayout = iconLayout
	menu.ScrollPanel = scroll

	function menu:AddAccessoryIcon(model, accessorKey, accessoryData, onSelect)
		local ico = vgui.Create("DPanel", self.IconLayout)
		local icoSize = ScreenScale(42)
		ico:SetSize(icoSize, icoSize)
		ico.Accessor = accessorKey
		ico.bIsHovered = false
		ico:SetMouseInputEnabled(true)

		local spawnIcon = vgui.Create("DModelPanel", ico)
		spawnIcon:Dock(FILL)
		spawnIcon:DockMargin(1, 1, 1, 1)
		spawnIcon:SetModel(model or "models/error.mdl")
		spawnIcon:SetTooltip(string.NiceName(accessoryData and accessoryData.name or accessorKey))
		spawnIcon:SetFOV(15)
		spawnIcon:SetLookAt(accessoryData.vpos or Vector(0, 0, 0))

		function spawnIcon:PreDrawModel(ent)
			if accessoryData.bSetColor then
				local colorDraw = accessoryData.vecColorOveride or (lply.GetPlayerColor and lply:GetPlayerColor() or lply:GetNWVector("PlayerColor", Vector(1, 1, 1)))
				render.SetColorModulation(colorDraw[1], colorDraw[2], colorDraw[3])
			end
		end

		function spawnIcon:PostDrawModel(ent)
			if accessoryData.bSetColor then
				render.SetColorModulation(1, 1, 1)
			end
		end

		timer.Simple(0, function()
			if IsValid(spawnIcon) and IsValid(spawnIcon.Entity) then
				spawnIcon.Entity:SetSkin((isfunction(accessoryData.skin) and accessoryData.skin()) or (accessoryData.skin or 0))
				spawnIcon.Entity:SetBodyGroups(accessoryData.bodygroups or "0000000")
				if accessoryData.SubMat then
					spawnIcon.Entity:SetSubMaterial(0, accessoryData.SubMat)
				end
			end
		end)

		function spawnIcon:DoClick()
			if onSelect then onSelect(accessorKey) end
			surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
			menu:Remove()
		end

		function ico:OnMousePressed(mc)
			if mc == MOUSE_LEFT then spawnIcon:DoClick() end
		end

		function ico:OnCursorEntered()
			self:SetCursor("hand")
		end

		function ico:Paint(w, h)
			if self.bIsHovered then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawOutlinedRect(0, 0, w, h, 2)
				surface.SetDrawColor(40, 40, 40, 200)
				surface.DrawRect(2, 2, w - 4, h - 4)
			else
				surface.SetDrawColor(60, 60, 60, 200)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				surface.SetDrawColor(20, 20, 20, 150)
				surface.DrawRect(1, 1, w - 2, h - 2)
			end
		end

		function ico:Think()
			self.bIsHovered = vgui.GetHoveredPanel() == self or vgui.GetHoveredPanel() == spawnIcon
		end

		self.IconLayout:InvalidateLayout(true)
		self.IconLayout:SizeToChildren(false, true)
		self.ScrollPanel:InvalidateLayout(true)

		return ico
	end

	function menu:AddNoneOption(onSelect)
		local ico = vgui.Create("DPanel", self.IconLayout)
		local icoSize = ScreenScale(50)
		ico:SetSize(icoSize, icoSize)
		ico.Accessor = "none"
		ico.bIsHovered = false

		function ico:Paint(w, h)
			if self.bIsHovered then
				surface.SetDrawColor(255, 50, 50, 255)
				surface.DrawOutlinedRect(0, 0, w, h, 2)
			else
				surface.SetDrawColor(100, 100, 100, 255)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end

			draw.SimpleText("NONE", "ZCity_Tiny", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		function ico:Think()
			self.bIsHovered = vgui.GetHoveredPanel() == self
		end

		function ico:OnMousePressed(mc)
			if mc == MOUSE_LEFT then
				if onSelect then onSelect("none") end
				surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
				menu:Remove()
			end
		end

		function ico:OnCursorEntered()
			self:SetCursor("hand")
		end

		self.IconLayout:InvalidateLayout(true)
		self.IconLayout:SizeToChildren(false, true)
		self.ScrollPanel:InvalidateLayout(true)

		return ico
	end

	menu.Close = function() menu:Remove() end

	RegisterOpenMenu(menu)
	return menu
end

local function NormalizeAppearanceTable(tbl)
	tbl.AAttachments = tbl.AAttachments or {}
	for i = 1, 3 do
		if not tbl.AAttachments[i] or tbl.AAttachments[i] == "" then
			tbl.AAttachments[i] = "none"
		end
	end

	tbl.AClothes = tbl.AClothes or {main = "normal", pants = "normal", boots = "normal"}
	tbl.ABodygroups = tbl.ABodygroups or {}
	tbl.AFacemap = tbl.AFacemap or "Default"

	if tbl.AColor and not IsColor(tbl.AColor) then
		tbl.AColor = Color(tbl.AColor.r or 180, tbl.AColor.g or 0, tbl.AColor.b or 0, tbl.AColor.a or 255)
	end

	tbl.AColor = tbl.AColor or Color(180, 0, 0)
	if hg.Appearance.FixAppearanceNameSex then hg.Appearance.FixAppearanceNameSex(tbl) end
	return tbl
end

function PANEL:SetAppearance(tAppearance)
	self.AppearanceTable = tAppearance
end

function PANEL:CallbackAppearance()
end

function PANEL:Init()
	self:SetTitle("")
	self:ShowCloseButton(false)
	self:SetDraggable(false)
	self:SetSizable(false)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	if self.PostInit then
		timer.Simple(0, function()
			if IsValid(self) then
				self:PostInit()
			end
		end)
	end
end

local sizeX, sizeY = ScrW() * 1, ScrH() * 1

function PANEL:Paint(w, h)
end

function PANEL:PostInit()
	local main = self
	self:SetDraggable(false)
	self.modelPosID = "All"

	self.AppearanceTable = self.AppearanceTable or hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString()) or APmodule.GetRandomAppearance()
	NormalizeAppearanceTable(self.AppearanceTable)

	local function resetModelPos()
		if IsValid(main) then main.modelPosID = "All" end
	end

	local function bindMenuClose(menu)
		function menu:OnRemove()
			resetModelPos()
		end
	end

	local function getCurMdl()
		return APmodule.PlayerModels[1][main.AppearanceTable.AModel] or APmodule.PlayerModels[2][main.AppearanceTable.AModel]
	end

	local tMdl = APmodule.PlayerModels[1][self.AppearanceTable.AModel] or APmodule.PlayerModels[2][self.AppearanceTable.AModel]
	if not tMdl then
		local fallbackMdl, fallbackName = table.Random(APmodule.PlayerModels[1])
		tMdl = fallbackMdl
		self.AppearanceTable.AModel = fallbackName
	end

	local NameEntry, modelBtn

	local function PaintTextEntry(s, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		s:DrawTextEntryText(Color(255, 255, 255), Color(255, 0, 0), Color(255, 255, 255))
	end

	local function OpenModelDropdown()
		if IsValid(main.ModelDropdown) then
			main.ModelDropdown:Close()
			main.ModelDropdown = nil
			return
		end

		main.ModelDropdown = CreateAnchorDropdown(main, modelBtn, ScreenScale(150), ScreenScale(220), function(drop, scroll)
			local seen = {}
			local function addModels(sexIdx)
				for k in SortedPairs(APmodule.PlayerModels[sexIdx]) do
					local mdl = APmodule.PlayerModels[sexIdx][k]
					if seen[mdl.mdl] then continue end
					seen[mdl.mdl] = true
					AddDropdownOption(drop, scroll, k, function()
						main.AppearanceTable.AModel = k
						main.AppearanceTable.AName = APmodule.GenerateRandomName(mdl.sex and 2 or 1)
						main.AppearanceTable.AFacemap = "Default"
						if IsValid(NameEntry) then NameEntry:SetText(main.AppearanceTable.AName) end
						if IsValid(modelBtn) then
							modelBtn:SetText(k)
							modelBtn:SizeToContents()
							modelBtn:SetWide(modelBtn:GetWide() + ScreenScale(10))
						end
						main.ModelDropdown = nil
					end)
				end
			end
			addModels(1)
			addModels(2)
		end)

		function main.ModelDropdown:OnRemove()
			main.ModelDropdown = nil
		end
	end

	local function OpenPresetSavePopup(anchor)
		if not IsValid(anchor) then return end

		if IsValid(main.PresetSavePopup) then
			main.PresetSavePopup:Close()
			main.PresetSavePopup = nil
			return
		end

		CloseAllOpenMenus()

		local wide = ScreenScale(130)
		local targetTall = ScreenScale(54)
		local popup = vgui.Create("DPanel", main)
		local ax, ay = anchor:LocalToScreen(0, 0)
		local px, py = main:LocalToScreen(0, 0)

		popup:SetPos(ax - px, ay - py - targetTall - ScreenScale(2))
		popup:SetWide(wide)
		popup:SetTall(0)
		popup:SetZPos(110)
		popup:SetMouseInputEnabled(true)
		popup.TargetTall = targetTall
		popup.OpenFrac = 0
		popup.Closing = false
		popup.Anchor = anchor
		popup._openedAt = SysTime()

		function popup:Paint(w, h)
			surface.SetDrawColor(10, 10, 10, 240)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(40, 40, 40, 220)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end

		function popup:Close()
			self.Closing = true
		end

		function popup:Think()
			local target = self.Closing and 0 or 1
			self.OpenFrac = Lerp(FrameTime() * 12, self.OpenFrac, target)
			local tall = math.max(1, self.TargetTall * self.OpenFrac)
			self:SetTall(tall)

			if IsValid(self.Anchor) then
				local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
				local px2, py2 = main:LocalToScreen(0, 0)
				self:SetPos(ax2 - px2, ay2 - py2 - tall - ScreenScale(2))
			end

			if self.Closing and self.OpenFrac < 0.02 then
				self:Remove()
				return
			end

			if self.Closing or SysTime() - self._openedAt < 0.15 then return end
			if not input.IsMouseDown(MOUSE_LEFT) then return end

			local mx, my = gui.MouseX(), gui.MouseY()
			local dx, dy = self:LocalToScreen(0, 0)
			local ax2, ay2 = self.Anchor:LocalToScreen(0, 0)
			local aw, ah = self.Anchor:GetSize()
			local inPopup = mx >= dx and mx <= dx + self:GetWide() and my >= dy and my <= dy + self:GetTall()
			local inAnchor = mx >= ax2 and mx <= ax2 + aw and my >= ay2 and my <= ay2 + ah
			if not inPopup and not inAnchor then self:Close() end
		end

		local entry = vgui.Create("DTextEntry", popup)
		entry:Dock(TOP)
		entry:DockMargin(ScreenScale(6), ScreenScale(6), ScreenScale(6), ScreenScale(4))
		entry:SetTall(ScreenScale(22))
		entry:SetFont("ZCity_Tiny")
		entry:SetPlaceholderText("имя пресета")
		entry:SetMouseInputEnabled(true)
		entry:SetKeyboardInputEnabled(true)
		entry.Paint = PaintTextEntry

		local function doSave()
			local presetName = string.Trim(entry:GetValue())
			if presetName == "" or #presetName < 2 then
				surface.PlaySound("buttons/button10.wav")
				notification.AddLegacy("Введи имя пресета (мин. 2 символа)", NOTIFY_ERROR, 3)
				return
			end

			presetName = string.gsub(presetName, "[^%w%s_-]", "")
			SavePreset(presetName, main.AppearanceTable)
			surface.PlaySound("buttons/button14.wav")
			notification.AddLegacy("Пресет «" .. presetName .. "» сохранён", NOTIFY_GENERIC, 3)
			popup:Close()
			main.PresetSavePopup = nil
		end

		entry.OnEnter = doSave
		entry.OnMousePressed = function(s, mc)
			if mc == MOUSE_LEFT then
				s:RequestFocus()
				if main.IsEmbedded then main:MakePopup() end
			end
		end

		local confirmBtn = vgui.Create("DLabel", popup)
		confirmBtn:SetText("Сохранить")
		confirmBtn:SetFont("ZCity_Veteran")
		confirmBtn:SetTextColor(Color(255, 255, 255))
		confirmBtn:SetContentAlignment(5)
		confirmBtn:Dock(TOP)
		confirmBtn:DockMargin(ScreenScale(6), 0, ScreenScale(6), ScreenScale(6))
		confirmBtn:SetTall(ScreenScale(18))
		confirmBtn.Paint = PaintMenuLabel
		WireMenuLabel(confirmBtn, doSave)

		function popup:OnRemove()
			main.PresetSavePopup = nil
		end

		RegisterOpenMenu(popup)
		main.PresetSavePopup = popup
		popup:MoveToFront()

		timer.Simple(0, function()
			if not IsValid(entry) then return end
			entry:RequestFocus()
			if main.IsEmbedded then main:MakePopup() end
		end)
	end

	local function OpenPresetLoadDropdown(anchor)
		if IsValid(main.PresetDropdown) then
			main.PresetDropdown:Close()
			main.PresetDropdown = nil
			return
		end

		local presetList = GetPresetList()
		if #presetList == 0 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy("Нет сохранённых пресетов", NOTIFY_ERROR, 3)
			return
		end

		main.PresetDropdown = CreateAnchorDropdown(main, anchor, ScreenScale(130), ScreenScale(180), function(drop, scroll)
			for _, presetName in ipairs(presetList) do
				AddDropdownOption(drop, scroll, presetName, function()
					local loadedPreset = LoadPreset(presetName)
					if not loadedPreset then
						surface.PlaySound("buttons/button10.wav")
						notification.AddLegacy("Не удалось загрузить пресет", NOTIFY_ERROR, 3)
						return
					end

					main.AppearanceTable = NormalizeAppearanceTable(loadedPreset)
					if IsValid(NameEntry) then NameEntry:SetText(main.AppearanceTable.AName or "") end
					if IsValid(modelBtn) then
						modelBtn:SetText(loadedPreset.AModel or "Male 01")
						modelBtn:SizeToContents()
						modelBtn:SetWide(modelBtn:GetWide() + ScreenScale(10))
					end
					surface.PlaySound("buttons/button14.wav")
					notification.AddLegacy("Пресет «" .. presetName .. "» загружен", NOTIFY_GENERIC, 3)
					main.PresetDropdown = nil
				end)
			end
		end, true)

		function main.PresetDropdown:OnRemove()
			main.PresetDropdown = nil
		end
	end

	local function OpenPresetDeleteDropdown(anchor)
		if IsValid(main.PresetDeleteDropdown) then
			main.PresetDeleteDropdown:Close()
			main.PresetDeleteDropdown = nil
			return
		end

		local presetList = GetPresetList()
		if #presetList == 0 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy("Нет сохранённых пресетов", NOTIFY_ERROR, 3)
			return
		end

		main.PresetDeleteDropdown = CreateAnchorDropdown(main, anchor, ScreenScale(130), ScreenScale(180), function(drop, scroll)
			for _, presetName in ipairs(presetList) do
				AddDropdownOption(drop, scroll, "✕ " .. presetName, function()
					if DeletePreset(presetName) then
						surface.PlaySound("buttons/button14.wav")
						notification.AddLegacy("Пресет «" .. presetName .. "» удалён", NOTIFY_GENERIC, 3)
					else
						surface.PlaySound("buttons/button10.wav")
						notification.AddLegacy("Не удалось удалить пресет", NOTIFY_ERROR, 3)
					end
					main.PresetDeleteDropdown = nil
				end)
			end
		end, true)

		function main.PresetDeleteDropdown:OnRemove()
			main.PresetDeleteDropdown = nil
		end
	end

	local topBar = vgui.Create("DPanel", self)
	topBar:SetPos(0, 0)
	topBar:SetSize(ScrW(), ScreenScale(36))
	topBar:SetZPos(100)
	topBar:SetMouseInputEnabled(true)
	topBar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(0, 0, w, h)
	end

	NameEntry = vgui.Create("DTextEntry", topBar)
	NameEntry:SetWide(ScreenScale(110))
	NameEntry:SetTall(ScreenScale(22))
	NameEntry:SetFont("ZCity_Veteran")
	NameEntry:SetText(main.AppearanceTable.AName)
	NameEntry:SetPos(ScreenScale(20), ScreenScale(7))
	NameEntry:SetZPos(101)
	NameEntry:SetMouseInputEnabled(true)
	NameEntry:SetKeyboardInputEnabled(true)
	NameEntry.OnChange = function(s) main.AppearanceTable.AName = s:GetValue() end
	NameEntry.OnMousePressed = function(s, mc)
		if mc == MOUSE_LEFT then
			s:RequestFocus()
			if main.IsEmbedded then main:MakePopup() end
		end
	end
	NameEntry.Paint = PaintTextEntry

	modelBtn = vgui.Create("DLabel", topBar)
	modelBtn:SetText(main.AppearanceTable.AModel or "?")
	modelBtn:SetFont("ZCity_Veteran")
	modelBtn:SetTextColor(Color(255, 255, 255))
	modelBtn:SetContentAlignment(4)
	modelBtn:SizeToContents()
	modelBtn:SetWide(modelBtn:GetWide() + ScreenScale(10))
	modelBtn:SetTall(ScreenScale(22))
	modelBtn:SetPos(ScreenScale(140), ScreenScale(7))
	modelBtn:SetZPos(101)
	modelBtn.Paint = PaintMenuLabel
	WireMenuLabel(modelBtn, OpenModelDropdown)

	local viewer = vgui.Create("DModelPanel", self)
	viewer:Dock(FILL)
	viewer:SetZPos(0)
	viewer:SetMouseInputEnabled(false)
	viewer:SetKeyboardInputEnabled(false)
	viewer:SetModel(util.IsValidModel(tostring(tMdl.mdl)) and tostring(tMdl.mdl) or "models/player/group01/female_01.mdl")
	viewer:SetFOV(60)
	viewer:SetLookAng(Angle(11, 180, 0))
	viewer:SetCamPos(Vector(75, 0, 65))
	viewer:SetDirectionalLight(BOX_RIGHT, Color(255, 0, 0))
	viewer:SetDirectionalLight(BOX_LEFT, Color(125, 155, 255))
	viewer:SetDirectionalLight(BOX_FRONT, Color(160, 160, 160))
	viewer:SetDirectionalLight(BOX_BACK, Color(0, 0, 0))
	viewer:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
	viewer:SetDirectionalLight(BOX_BOTTOM, Color(0, 0, 0))
	viewer:SetAmbientLight(Color(255, 0, 0, 255))

	function viewer:OnMouseWheeled(delta)
		self.SmoothFOVDelta = self:GetFOV() - delta * 5
	end

	local offsets = {
		["All"] = 1,
		["Head"] = 1.15,
		["Face"] = 1.1,
		["Torso"] = 0.9,
		["Legs"] = 0.4,
		["Boots"] = 0.1,
		["Hands"] = 0.5
	}

	function viewer:Think()
		if not IsValid(main) then return end
		self.SmoothFOV = LerpFT(0.05, self.SmoothFOV or self:GetFOV(), main.modelPosID == "All" and 60 or 45)
		self.LookAngles = LerpFT(0.05, self.LookAngles or 11, main.modelPosID == "All" and 11 or 0)
		self:SetFOV(self.SmoothFOV)
		self:SetLookAng(Angle(self.LookAngles, 180, 0))
		self.OffsetY = LerpFT(0.1, self.OffsetY or 0, offsets[main.modelPosID] or 1)
	end

	local funpos1x
	local funpos3x

	function viewer:LayoutEntity(Entity)
		if not IsValid(main) then return end
		local lookX, lookY = input.GetCursorPos()
		lookX = lookX / sizeX - 0.5
		lookY = lookY / sizeY - 0.5
		Entity.Angles = Entity.Angles or Angle(0, 0, 0)
		Entity.Angles = LerpAngle(FrameTime() * 5, Entity.Angles, Angle(lookY * 2, (self.Rotate and -179 or 0) - lookX * 75, 0))
		local tbl = main.AppearanceTable
		tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel]
		if not tMdl then return end

		local clr = tbl.AColor or Color(180, 0, 0)
		Entity:SetNWVector("PlayerColor", Vector(clr.r / 255, clr.g / 255, clr.b / 255))
		Entity:SetAngles(Entity.Angles)
		Entity:SetSequence(Entity:LookupSequence("idle_suitcase"))
		Entity:SetSubMaterial()
		self:SetCamPos(Vector(75, 0, 65 * (self.OffsetY or 1)))

		if Entity:GetModel() != tMdl.mdl then
			Entity:SetModel(tMdl.mdl)
			self:SetModel(tMdl.mdl)
			tbl.AFacemap = "Default"
		end

		local mats = Entity:GetMaterials()
		for k, v in pairs(tMdl.submatSlots) do
			local slot = 1
			for i = 1, #mats do
				if mats[i] == v then slot = i - 1 break end
			end
			Entity:SetSubMaterial(slot, hg.Appearance.Clothes[tMdl.sex and 2 or 1][tbl.AClothes[k]] or hg.Appearance.Clothes[tMdl.sex and 2 or 1]["normal"])
			Entity:SetNWString("Colthes" .. k, tbl.AClothes[k])
		end

		for i = 1, #mats do
			if hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap] then
				Entity:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap])
			end
		end

		local bodygroups = Entity:GetBodyGroups()
		tbl.ABodygroups = tbl.ABodygroups or {}
		for k, v in ipairs(bodygroups) do
			if not tbl.ABodygroups[v.name] then continue end
			for i = 0, #v.submodels do
				local b = v.submodels[i]
				if not hg.Appearance.Bodygroups[v.name] then continue end
				if not hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1] then continue end
				if not hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]] then continue end
				if hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]][1] != b then continue end
				Entity:SetBodygroup(k - 1, i)
			end
		end

		if IsValid(Entity) and Entity:LookupBone("ValveBiped.Bip01_Head1") then
			funpos1x = lookX * 75
			funpos3x = -lookX * 75
		end
	end

	function viewer:PostDrawModel(Entity)
		if not IsValid(main) then return end
		local tbl = main.AppearanceTable
		for k, attach in ipairs(tbl.AAttachments) do
			if attach and attach ~= "" and attach ~= "none" and hg.Accessories[attach] then
				DrawAccesories(Entity, Entity, attach, hg.Accessories[attach], false, true)
			end
		end
		Entity:SetupBones()
	end

	function viewer.Entity:GetPlayerColor() return end

	local function CreateBodyBtn(text, relX, relY, alignRight, func)
		local btn = vgui.Create("DLabel", main)
		btn:SetText(text)
		btn:SetFont("ZCity_Veteran")
		btn:SetTextColor(Color(255, 255, 255))
		btn:SetContentAlignment(alignRight and 6 or 4)
		btn:SizeToContents()
		btn:SetWide(btn:GetWide() + ScreenScale(10))
		btn:SetTall(math.max(ScreenScale(18), btn:GetTall()))
		btn:SetPos(relX * ScrW() - (alignRight and btn:GetWide() or 0), relY * ScrH())
		btn:SetZPos(50)
		btn.BaseX, btn.BaseY = btn:GetPos()
		btn.Paint = PaintMenuLabel
		WireMenuLabel(btn, function()
			if func then func(btn) end
		end)
		return btn
	end

	local function OpenAccessorySlidePanel(anchor, posID, placements, slot)
		if not IsValid(anchor) then return end

		if IsValid(anchor.SlidePanel) then
			anchor.SlidePanel:Close()
			return
		end

		main.modelPosID = posID

		CreateSlideSidePanel(main, anchor, ScreenScale(155), ScreenScale(220), function(pnl, scroll)
			AddDropdownOption(pnl, scroll, "Нет", function()
				main.AppearanceTable.AAttachments[slot] = "none"
			end)

			for k, v in SortedPairs(hg.Accessories) do
				if not v.placement or not table.HasValue(placements, v.placement) then continue end
				if not v.model then continue end
				AddDropdownOption(pnl, scroll, v.name or string.NiceName(k), function()
					main.AppearanceTable.AAttachments[slot] = k
					surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
				end)
			end
		end, function()
			main.modelPosID = "All"
		end, main.LeftSlidePanelX, main.LeftSlidePanelY)
	end

	local function OpenTorsoSlidePanel(anchor)
		if not IsValid(anchor) then return end

		if IsValid(anchor.SlidePanel) then
			anchor.SlidePanel:Close()
			return
		end

		main.modelPosID = "Torso"

		CreateSlideSidePanel(main, anchor, ScreenScale(155), ScreenScale(260), function(pnl, scroll)
			local colorSelector = vgui.Create("DColorCombo", scroll:GetCanvas())
			colorSelector:SetTall(ScreenScale(20))
			colorSelector:Dock(TOP)
			colorSelector:DockMargin(0, 0, 0, ScreenScale(6))
			function colorSelector:OnValueChanged(clr)
				main.AppearanceTable.AColor = clr
			end
			colorSelector:SetColor(main.AppearanceTable.AColor)

			local mdl = getCurMdl()
			if mdl then
				local clothes = hg.Appearance.Clothes[mdl.sex and 2 or 1]
				if clothes then
					for k in SortedPairs(clothes) do
						local clothName = string.NiceName(string.Replace(k, "_", " "))
						AddDropdownOption(pnl, scroll, clothName, function()
							main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
							main.AppearanceTable.AClothes.main = k
						end)
					end
				end
			end

			local sexTable = mdl and hg.Appearance.Bodygroups.TORSO and hg.Appearance.Bodygroups.TORSO[mdl.sex and 2 or 1]
			if sexTable and next(sexTable) then
				for name in SortedPairs(sexTable) do
					AddDropdownOption(pnl, scroll, name, function()
						main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
						main.AppearanceTable.ABodygroups.TORSO = name
					end)
				end
			end
		end, function()
			main.modelPosID = "All"
		end, main.LeftSlidePanelX, main.LeftSlidePanelY)
	end

	local function OpenRightSlidePanel(anchor, posID, maxTall, build)
		if not IsValid(anchor) then return end

		if IsValid(anchor.SlidePanel) then
			anchor.SlidePanel:Close()
			return
		end

		main.modelPosID = posID

		CreateSlideSidePanelRight(main, anchor, ScreenScale(155), maxTall or ScreenScale(220), build, function()
			main.modelPosID = "All"
		end, main.RightSlidePanelRightX, main.RightSlidePanelY)
	end

	local function OpenFacemapSlidePanel(anchor)
		OpenRightSlidePanel(anchor, "Face", ScreenScale(220), function(pnl, scroll)
			local mdl = getCurMdl()
			if not mdl then
				AddDropdownOption(pnl, scroll, "Нет модели", function() end)
				return
			end

			local facemapKey = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[mdl.mdl]
			local facemaps = facemapKey and hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[facemapKey] or {}
			if not next(facemaps) then
				AddDropdownOption(pnl, scroll, "Нет вариантов", function() end)
				return
			end

			for k in SortedPairs(facemaps) do
				AddDropdownOption(pnl, scroll, k, function()
					main.AppearanceTable.AFacemap = k
				end)
			end
		end)
	end

	local function OpenBodygroupSlidePanel(anchor, bgKey, posID)
		OpenRightSlidePanel(anchor, posID, ScreenScale(220), function(pnl, scroll)
			local mdl = getCurMdl()
			if not mdl then
				AddDropdownOption(pnl, scroll, "Нет модели", function() end)
				return
			end

			local sexTable = hg.Appearance.Bodygroups[bgKey] and hg.Appearance.Bodygroups[bgKey][mdl.sex and 2 or 1]
			if not sexTable or not next(sexTable) then
				AddDropdownOption(pnl, scroll, "Нет вариантов", function() end)
				return
			end

			for name in SortedPairs(sexTable) do
				AddDropdownOption(pnl, scroll, name, function()
					main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
					main.AppearanceTable.ABodygroups[bgKey] = name
				end)
			end
		end)
	end

	local function OpenLegsSlidePanel(anchor)
		OpenRightSlidePanel(anchor, "Legs", ScreenScale(220), function(pnl, scroll)
			local mdl = getCurMdl()
			if mdl then
				local clothes = hg.Appearance.Clothes[mdl.sex and 2 or 1]
				if clothes then
					for k in SortedPairs(clothes) do
						local clothName = string.NiceName(string.Replace(k, "_", " "))
						AddDropdownOption(pnl, scroll, clothName, function()
							main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
							main.AppearanceTable.AClothes.pants = k
						end)
					end
				end
			end

			local sexTable = mdl and hg.Appearance.Bodygroups.LEGS and hg.Appearance.Bodygroups.LEGS[mdl.sex and 2 or 1]
			if sexTable and next(sexTable) then
				for name in SortedPairs(sexTable) do
					AddDropdownOption(pnl, scroll, name, function()
						main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
						main.AppearanceTable.ABodygroups.LEGS = name
					end)
				end
			end
		end)
	end

	local function OpenClothesSlidePanel(anchor, slot, posID)
		OpenRightSlidePanel(anchor, posID, ScreenScale(220), function(pnl, scroll)
			local mdl = getCurMdl()
			if not mdl then
				AddDropdownOption(pnl, scroll, "Нет модели", function() end)
				return
			end

			local clothes = hg.Appearance.Clothes[mdl.sex and 2 or 1]
			if not clothes then
				AddDropdownOption(pnl, scroll, "Нет вариантов", function() end)
				return
			end

			for k in SortedPairs(clothes) do
				local clothName = string.NiceName(string.Replace(k, "_", " "))
				AddDropdownOption(pnl, scroll, clothName, function()
					main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
					main.AppearanceTable.AClothes[slot] = k
				end)
			end
		end)
	end

	local function OpenAccessoryMenu(title, posID, placements, slot)
		main.modelPosID = posID
		CloseAllOpenMenus()

		local menu = CreateStyledAccessoryMenu(nil, title)
		for k, v in pairs(hg.Accessories) do
			if not v.placement or not table.HasValue(placements, v.placement) then continue end
			if not HasAccessToAccessory(k, v) then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[slot] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[slot] = "none"
		end)

		bindMenuClose(menu)
	end

	-- Left side
	local headBtn = CreateBodyBtn("ГОЛОВНОЙ УБОР", 0.06, 0.14, false, function(anchor)
		OpenAccessorySlidePanel(anchor, "Head", {"head", "ears"}, 1)
	end)
	main.LeftSlidePanelX = headBtn.BaseX
	main.LeftSlidePanelY = headBtn.BaseY

	CreateBodyBtn("ЛИЦО", 0.06, 0.28, false, function(anchor)
		OpenAccessorySlidePanel(anchor, "Face", {"face"}, 2)
	end)

	CreateBodyBtn("ТЕЛО", 0.06, 0.44, false, function(anchor)
		OpenAccessorySlidePanel(anchor, "Torso", {"torso", "spine"}, 3)
	end)

	CreateBodyBtn("ТОРС", 0.06, 0.58, false, OpenTorsoSlidePanel)

	-- Right side
	local faceTexBtn = CreateBodyBtn("ТЕКСТУРА ЛИЦА", 0.94, 0.22, true, OpenFacemapSlidePanel)
	main.RightSlidePanelRightX = faceTexBtn.BaseX + faceTexBtn:GetWide()
	main.RightSlidePanelY = faceTexBtn.BaseY

	CreateBodyBtn("ПЕРЧАТКИ", 0.94, 0.38, true, function(anchor)
		OpenBodygroupSlidePanel(anchor, "HANDS", "Hands")
	end)

	CreateBodyBtn("НОГИ", 0.94, 0.54, true, OpenLegsSlidePanel)

	CreateBodyBtn("ОБУВЬ", 0.94, 0.70, true, function(anchor)
		OpenClothesSlidePanel(anchor, "boots", "Boots")
	end)

	-- Exit
	local returnBtn = CreateBodyBtn("ВЫЙТИ", 0.06, 0.88, false, function()
		CloseAllOpenMenus()
		if main.Close then main:Close() end
	end)
	returnBtn:SetZPos(30)

	function main:OnRemove()
		CloseAllOpenMenus()
	end

	-- Пресеты — нижняя панель поверх всего
	local bottomBar = vgui.Create("DPanel", self)
	bottomBar:SetSize(ScreenScale(200), ScreenScale(36))
	bottomBar:SetPos(ScrW() - ScreenScale(210), ScrH() - ScreenScale(44))
	bottomBar:SetZPos(100)
	bottomBar:SetMouseInputEnabled(true)
	bottomBar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(0, 0, w, h)
	end

	local function CreateBarBtn(text, x, func)
		local btn = vgui.Create("DLabel", bottomBar)
		btn:SetText(text)
		btn:SetFont("ZCity_Veteran")
		btn:SetTextColor(Color(255, 255, 255))
		btn:SetContentAlignment(5)
		btn:SetPos(x, ScreenScale(7))
		btn:SizeToContents()
		btn:SetWide(btn:GetWide() + ScreenScale(8))
		btn:SetTall(ScreenScale(22))
		btn:SetZPos(101)
		btn.Paint = PaintMenuLabel
		WireMenuLabel(btn, function()
			if func then func(btn) end
		end)
		return btn
	end

	CreateBarBtn("СОХРАНИТЬ", ScreenScale(8), function(anchor)
		OpenPresetSavePopup(anchor)
	end)

	CreateBarBtn("ЗАГРУЗИТЬ", ScreenScale(72), function(anchor)
		OpenPresetLoadDropdown(anchor)
	end)

	CreateBarBtn("УДАЛИТЬ", ScreenScale(136), function(anchor)
		OpenPresetDeleteDropdown(anchor)
	end)

	topBar:MoveToFront()
	NameEntry:MoveToFront()
	modelBtn:MoveToFront()
	bottomBar:MoveToFront()

	self:CallbackAppearance()
end

vgui.Register("ZAppearance", PANEL, "DFrame")
