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
            m:Remove()
        end
        table.remove(openMenus, i)
    end
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

	local function OpenStyledTextMenu(title, posID, build)
		main.modelPosID = posID
		CloseAllOpenMenus()
		local menu = CreateStyledListMenu(title)
		if build then build(menu) end
		bindMenuClose(menu)
	end

	local function OpenBodygroupMenu(title, bgKey, posID)
		OpenStyledTextMenu(title, posID, function(menu)
			local mdl = getCurMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local sexTable = hg.Appearance.Bodygroups[bgKey] and hg.Appearance.Bodygroups[bgKey][mdl.sex and 2 or 1]
			if not sexTable or not next(sexTable) then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			for name, _ in SortedPairs(sexTable) do
				menu:AddOption(name, function()
					main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
					main.AppearanceTable.ABodygroups[bgKey] = name
				end)
			end
		end)
	end

	local function OpenClothesMenu(title, slot, posID)
		OpenStyledTextMenu(title, posID, function(menu)
			local mdl = getCurMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local clothes = hg.Appearance.Clothes[mdl.sex and 2 or 1]
			if not clothes then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			for k, _ in SortedPairs(clothes) do
				local clothName = string.NiceName(string.Replace(k, "_", " "))
				menu:AddOption(clothName, function()
					main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
					main.AppearanceTable.AClothes[slot] = k
				end)
			end
		end)
	end

	local tMdl = APmodule.PlayerModels[1][self.AppearanceTable.AModel] or APmodule.PlayerModels[2][self.AppearanceTable.AModel]
	if not tMdl then
		local fallbackName, fallbackMdl = table.Random(APmodule.PlayerModels[1])
		tMdl = fallbackMdl
		self.AppearanceTable.AModel = fallbackName
	end

	-- Fullscreen Model Viewer
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

	-- Controls Container (Left Side)
	local controls = vgui.Create("DPanel", self)
	local controlsTop = ScreenScale(60)
	controls:SetSize(ScreenScale(140), ScrH() - controlsTop)
	controls:SetPos(ScreenScale(20), controlsTop)
	controls:SetZPos(20)
	controls:SetMouseInputEnabled(true)
	controls.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(0, 0, w, h)
	end

	local content = vgui.Create("DScrollPanel", controls)
	content:Dock(FILL)
	content:DockMargin(0, ScreenScale(20), 0, ScreenScale(40))
	content:SetMouseInputEnabled(true)
	local sbar = content:GetVBar()
	sbar:SetWide(0)

	-- Preset Controls (Right Side)
	local presetControls = vgui.Create("DPanel", self)
	presetControls:SetSize(ScreenScale(140), ScrH() - controlsTop)
	presetControls:SetPos(ScrW() - ScreenScale(160), controlsTop)
	presetControls:SetZPos(20)
	presetControls:SetMouseInputEnabled(true)
	presetControls.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 170)
		surface.DrawRect(0, 0, w, h)
	end

	local presetContent = vgui.Create("DScrollPanel", presetControls)
	presetContent:Dock(FILL)
	presetContent:DockMargin(0, ScreenScale(20), 0, ScreenScale(40))
	presetContent:SetMouseInputEnabled(true)
	local psbar = presetContent:GetVBar()
	psbar:SetWide(0)

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

	local function CreateControlBtn(text, func, parent)
		local btn = vgui.Create("DLabel", parent or content)
		btn:SetText(text)
		btn:SetFont("ZCity_Veteran")
		btn:SetTextColor(Color(255, 255, 255))
		btn:SetContentAlignment(4)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, ScreenScale(6))
		btn:SizeToContents()
		btn:SetWide(btn:GetWide() + ScreenScale(8))
		btn:SetTall(math.max(ScreenScale(18), btn:GetTall()))
		btn.Paint = PaintMenuLabel
		WireMenuLabel(btn, func)
		return btn
	end

	-- Name
	local NameEntry = vgui.Create("DTextEntry", content)
	NameEntry:SetTall(ScreenScale(25))
	NameEntry:SetFont("ZCity_Veteran")
	NameEntry:SetText(main.AppearanceTable.AName)
	NameEntry:Dock(TOP)
	NameEntry:DockMargin(0, 0, 0, ScreenScale(15))
	NameEntry.OnChange = function(s) main.AppearanceTable.AName = s:GetValue() end
	NameEntry.Paint = function(s, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		s:DrawTextEntryText(Color(255, 255, 255), Color(255, 0, 0), Color(255, 255, 255))
	end

	-- Model Selector
	local modelSelector = vgui.Create("DComboBox", content)
	modelSelector:SetTall(ScreenScale(25))
	modelSelector:SetFont("ZCity_Veteran")
	modelSelector:SetText(main.AppearanceTable.AModel)
	modelSelector:Dock(TOP)
	modelSelector:DockMargin(0, 0, 0, ScreenScale(15))
	modelSelector:SetContentAlignment(4)
	modelSelector.Paint = function(s, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function modelSelector:OnSelect(i, str)
		main.AppearanceTable.AModel = str
		local mdl = APmodule.PlayerModels[1][str] or APmodule.PlayerModels[2][str]
		if mdl then
			main.AppearanceTable.AName = APmodule.GenerateRandomName(mdl.sex and 2 or 1)
			NameEntry:SetText(main.AppearanceTable.AName)
		end
	end

	for k, v in pairs(APmodule.PlayerModels[1]) do modelSelector:AddChoice(k) end
	for k, v in pairs(APmodule.PlayerModels[2]) do modelSelector:AddChoice(k) end

	-- Hats
	CreateControlBtn("ГОЛОВНОЙ УБОР", function()
		main.modelPosID = "Head"
		CloseAllOpenMenus()

		local menu = CreateStyledAccessoryMenu(nil, "Select Hat")
		for k, v in pairs(hg.Accessories) do
			if v.placement != "head" and v.placement != "ears" then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[1] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[1] = "none"
		end)

		bindMenuClose(menu)
	end)

	-- Face
	CreateControlBtn("ЛИЦО", function()
		main.modelPosID = "Face"
		CloseAllOpenMenus()

		local menu = CreateStyledAccessoryMenu(nil, "Select Face Accessory")
		for k, v in pairs(hg.Accessories) do
			if v.placement != "face" then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[2] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[2] = "none"
		end)

		bindMenuClose(menu)
	end)

	-- Body
	CreateControlBtn("ТЕЛО", function()
		main.modelPosID = "Torso"
		CloseAllOpenMenus()

		local menu = CreateStyledAccessoryMenu(nil, "Select Body Accessory")
		for k, v in pairs(hg.Accessories) do
			if v.placement != "torso" and v.placement != "spine" then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[3] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[3] = "none"
		end)

		bindMenuClose(menu)
	end)

	-- Torso Bodygroup
	CreateControlBtn("ТОРС", function()
		OpenBodygroupMenu("Торс", "TORSO", "Torso")
	end)

	-- Legs/Boots Bodygroup
	CreateControlBtn("НОГИ", function()
		OpenBodygroupMenu("Ноги", "LEGS", "Legs")
	end)

	-- Gloves (HANDS Bodygroup)
	CreateControlBtn("ПЕРЧАТКИ", function()
		OpenBodygroupMenu("Перчатки", "HANDS", "Hands")
	end)

	-- Facemap
	CreateControlBtn("ЛИЦО (текстура)", function()
		OpenStyledTextMenu("Лицо (текстура)", "Face", function(menu)
			local mdl = getCurMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local facemapKey = hg.Appearance.FacemapsModels and hg.Appearance.FacemapsModels[mdl.mdl]
			local facemaps = facemapKey and hg.Appearance.FacemapsSlots and hg.Appearance.FacemapsSlots[facemapKey] or {}
			if not next(facemaps) then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			for k, _ in SortedPairs(facemaps) do
				menu:AddOption(k, function()
					main.AppearanceTable.AFacemap = k
				end)
			end
		end)
	end)

	-- Jacket (main clothes)
	CreateControlBtn("ВЕРХ", function()
		OpenStyledTextMenu("Верх", "Torso", function(menu)
			local colorSelector = vgui.Create("DColorCombo")
			colorSelector:SetTall(ScreenScale(20))
			function colorSelector:OnValueChanged(clr)
				main.AppearanceTable.AColor = clr
			end
			colorSelector:SetColor(main.AppearanceTable.AColor)
			menu:AddPanel(colorSelector)

			local mdl = getCurMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local clothes = hg.Appearance.Clothes[mdl.sex and 2 or 1]
			if not clothes then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			for k, _ in SortedPairs(clothes) do
				local clothName = string.NiceName(string.Replace(k, "_", " "))
				menu:AddOption(clothName, function()
					main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
					main.AppearanceTable.AClothes.main = k
				end)
			end
		end)
	end)

	-- Pants
	CreateControlBtn("НИЗ", function()
		OpenClothesMenu("Низ", "pants", "Legs")
	end)

	-- Boots
	CreateControlBtn("ОБУВЬ", function()
		OpenClothesMenu("Обувь", "boots", "Boots")
	end)

	-- Spacer
	local spacer = vgui.Create("DPanel", content)
	spacer:SetTall(ScreenScale(20))
	spacer:Dock(TOP)
	spacer.Paint = function() end

	-- Return Button
	local returnBtn = vgui.Create("DLabel", self)
	returnBtn:SetText("назад")
	returnBtn:SetFont("ZCity_Veteran")
	returnBtn:SetTextColor(Color(255, 255, 255))
	returnBtn:SetContentAlignment(4)
	returnBtn:SizeToContents()
	returnBtn:SetWide(returnBtn:GetWide() + ScreenScale(8))
	returnBtn:SetTall(math.max(ScreenScale(18), returnBtn:GetTall()))
	returnBtn:SetPos(ScreenScale(20), ScrH() - ScreenScale(40))
	returnBtn:SetZPos(30)
	returnBtn.Paint = PaintMenuLabel
	WireMenuLabel(returnBtn, function()
		CloseAllOpenMenus()
		if main.Close then main:Close() end
	end)

	function main:OnRemove()
		CloseAllOpenMenus()
	end

	-- Presets (Right Side)
	local presetNameEntry = vgui.Create("DTextEntry", presetContent)
	presetNameEntry:Dock(TOP)
	presetNameEntry:SetTall(ScreenScale(20))
	presetNameEntry:DockMargin(0, 0, 0, ScreenScale(5))
	presetNameEntry:SetFont("ZCity_Tiny")
	presetNameEntry:SetPlaceholderText("Введи имя...")

	presetNameEntry.Paint = function(s, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		s:DrawTextEntryText(Color(255, 255, 255), Color(255, 0, 0), Color(255, 255, 255))
	end

	CreateControlBtn("SAVE PRESET", function()
		local presetName = presetNameEntry:GetValue()
		if presetName == "" or #presetName < 2 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy("Enter a preset name (min 2 chars)", NOTIFY_ERROR, 3)
			return
		end

		presetName = string.gsub(presetName, "[^%w%s_-]", "")
		SavePreset(presetName, main.AppearanceTable)
		surface.PlaySound("buttons/button14.wav")
		notification.AddLegacy("Preset '" .. presetName .. "' saved!", NOTIFY_GENERIC, 3)
	end, presetContent)

	CreateControlBtn("LOAD PRESET", function()
		local presetList = GetPresetList()
		if #presetList == 0 then
			surface.PlaySound("buttons/button10.wav")
			notification.AddLegacy("No presets saved yet!", NOTIFY_ERROR, 3)
			return
		end

		local presetMenu = vgui.Create("DFrame")
		presetMenu:SetTitle("Load Preset")
		presetMenu:SetSize(ScreenScale(120), ScreenScale(100))
		presetMenu:Center()
		presetMenu:MakePopup()
		presetMenu:SetDraggable(false)

		function presetMenu:Paint(w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 28, 250))
			surface.SetDrawColor(colors.presetBorder)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
		end

		local scroll = CreateStyledScrollPanel(presetMenu)
		scroll:Dock(FILL)
		scroll:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), ScreenScale(2))

		for _, presetName in ipairs(presetList) do
			local presetBtn = vgui.Create("DButton", scroll)
			presetBtn:Dock(TOP)
			presetBtn:DockMargin(2, 2, 2, 0)
			presetBtn:SetTall(ScreenScale(14))
			presetBtn:SetFont("ZCity_Tiny")
			presetBtn:SetText(presetName)
			presetBtn:SetTextColor(colors.mainText)

			function presetBtn:Paint(w, h)
				if self:IsHovered() then
					surface.SetDrawColor(200, 220, 220, 255)
					surface.DrawRect(0, 0, w, h)
					self:SetTextColor(Color(0, 0, 0))
				else
					surface.SetDrawColor(0, 0, 0, 150)
					surface.DrawRect(0, 0, w, h)
					self:SetTextColor(colors.mainText)
				end
			end

			function presetBtn:DoClick()
				local loadedPreset = LoadPreset(presetName)
				if loadedPreset then
					main.AppearanceTable = NormalizeAppearanceTable(loadedPreset)
					NameEntry:SetText(loadedPreset.AName or "")
					modelSelector:SetText(loadedPreset.AModel or "Male 01")
					presetNameEntry:SetText(presetName)
					surface.PlaySound("buttons/button14.wav")
					notification.AddLegacy("Preset '" .. presetName .. "' loaded!", NOTIFY_GENERIC, 3)
				else
					surface.PlaySound("buttons/button10.wav")
					notification.AddLegacy("Failed to load preset!", NOTIFY_ERROR, 3)
				end

				presetMenu:Close()
			end
		end
	end, presetContent)

	returnBtn:MoveToFront()
	controls:MoveToFront()
	presetControls:MoveToFront()

	self:CallbackAppearance()
end

vgui.Register("ZAppearance", PANEL, "DFrame")
