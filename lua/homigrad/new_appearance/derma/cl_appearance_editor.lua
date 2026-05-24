hg.Appearance = hg.Appearance or {}
local A = hg.Appearance
local PANEL = {}

local c = {
	scr = Color(20, 20, 30, 200),
	grip = Color(70, 70, 90, 255),
	gripH = Color(100, 100, 130, 255),
	brd = Color(100, 100, 120, 200),
	txt = Color(255, 255, 255),
}

local prDir = "zcity/appearances/presets/"
local btnPad = ScreenScale(4)

local function ntf(msg, t, l)
	notification.AddLegacy(msg, t or NOTIFY_GENERIC, l or 3)
end

local function accNm(k, d)
	if k == "none" then return "Ничего" end
	return (d and d.name) or string.NiceName(k)
end

local mats = {}
local function getMat(p)
	if not p or p == "" then return end
	if mats[p] then return mats[p] end
	local m = Material(p)
	if m:IsError() then return end
	mats[p] = m
	return m
end

local function paintLbl(s, w, h)
	local font = s:GetFont()
	local text = s:GetText()
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	local totalW = tw + btnPad * 2

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

	draw.SimpleText(text, font, btnPad + offX, h / 2 + offY, s:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	if s:IsHovered() and math.random() > 0.7 then
		draw.SimpleText(text, font, btnPad + math.random(-5, 5), h / 2 + math.random(-2, 2), Color(0, 0, 0, math.random(50, 150)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	return true
end

local function wireLbl(btn, onClick)
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

local function svPr(nm, tbl)
	file.CreateDir(prDir)
	file.Write(prDir .. nm .. ".json", util.TableToJSON(tbl, true))
end

local function ldPr(nm)
	if not file.Exists(prDir .. nm .. ".json", "DATA") then return end
	return util.JSONToTable(file.Read(prDir .. nm .. ".json", "DATA"))
end

local function lsPr()
	file.CreateDir(prDir)
	local out = {}
	for _, f in ipairs(file.Find(prDir .. "*.json", "DATA") or {}) do
		out[#out + 1] = string.StripExtension(f)
	end
	return out
end

local function dlPr(nm)
	if file.Exists(prDir .. nm .. ".json", "DATA") then
		file.Delete(prDir .. nm .. ".json")
		return true
	end
end

A.SavePreset = svPr
A.LoadPreset = ldPr
A.GetPresetList = lsPr
A.DeletePreset = dlPr

local function defPr()
	file.CreateDir(prDir)
	if #lsPr() > 0 then return end

	local base = table.Copy(A.SkeletonAppearanceTable or {})
	base.AAttachments = {"none", "none", "none"}
	base.ABodygroups = {}
	base.AFacemap = "Default"

	local casual = table.Copy(base)
	casual.AName = "Гражданин"
	casual.AClothes = {main = "normal", pants = "normal", boots = "normal"}

	local winter = table.Copy(base)
	winter.AName = "Зимний"
	winter.AClothes = {main = "cold", pants = "cold", boots = "cold"}
	winter.ABodygroups = {LEGS = "Boots"}

	local sport = table.Copy(base)
	sport.AModel = "Мужчина 03"
	sport.AName = "Спортивный"
	sport.AClothes = {main = "casual", pants = "casual", boots = "golden_adidas"}
	sport.AColor = Color(40, 90, 200)

	svPr("Гражданин", casual)
	svPr("Зимний", winter)
	svPr("Спортивный", sport)
end

local didPrec = false
local function precMdl()
	if didPrec then return end
	didPrec = true
	timer.Simple(0.1, function()
		if A.PlayerModels then
			for _, t in pairs(A.PlayerModels) do
				for _, v in pairs(t) do
					if v.mdl then util.PrecacheModel(v.mdl) end
				end
			end
		end
		if hg.Accessories then
			for _, v in pairs(hg.Accessories) do
				if v.model then util.PrecacheModel(v.model) end
			end
		end
	end)
end

hook.Add("InitPostEntity", "HG_PrecacheAppearanceModels", function() timer.Simple(5, precMdl) end)
A.PrecacheModels = precMdl

local function mkScr(par)
	local scroll = vgui.Create("DScrollPanel", par)

	local sbar = scroll:GetVBar()
	sbar:SetWide(ScreenScale(4))
	sbar:SetHideButtons(true)

	function sbar:Paint(w, h)
		draw.RoundedBox(4, 0, 0, w, h, c.scr)
		surface.SetDrawColor(c.brd)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	function sbar.btnGrip:Paint(w, h)
		local col = self:IsHovered() and c.gripH or c.grip
		draw.RoundedBox(4, 2, 2, w - 4, h - 4, col)
		surface.SetDrawColor(c.brd)
		surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
	end

	return scroll
end

local popups = {}
local function regMn(m)
	if IsValid(m) then popups[#popups + 1] = m end
end

local function clsMn()
	for i = #popups, 1, -1 do
		if IsValid(popups[i]) then popups[i]:Remove() end
		popups[i] = nil
	end
end

local function killDim(par)
	if IsValid(par) and IsValid(par._popDim) then
		par._popDim:Remove()
	end
	if IsValid(par) then par._popDim = nil end
end

-- окошко поверх редактора, не на весь экран отдельным попапом
local function popShell(par, title, bw, bh)
	killDim(par)
	clsMn()

	local dim = vgui.Create("DPanel", par)
	dim:SetSize(par:GetWide(), par:GetTall())
	dim:SetPos(0, 0)
	dim:SetZPos(250)
	dim:SetMouseInputEnabled(true)
	par._popDim = dim
	regMn(dim)

	function dim:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 210)
		surface.DrawRect(0, 0, w, h)
	end

	local menu = vgui.Create("DPanel", dim)
	menu:SetSize(bw, bh)
	menu:Center()
	menu:SetZPos(1)
	menu:SetMouseInputEnabled(true)
	regMn(menu)

	function menu:Paint(w, h)
		surface.SetDrawColor(18, 18, 24, 250)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(35, 35, 45, 255)
		surface.DrawRect(0, 0, w, ScreenScale(14))
		surface.SetDrawColor(70, 70, 90, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(string.upper(title or ""), "ZCity_Veteran", ScreenScale(4), ScreenScale(7), Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	function menu:OnRemove()
		killDim(par)
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
	wireLbl(closeBtn, function() menu:Remove() end)

	return menu
end

function A.PurgePopups(par)
	clsMn()
	if IsValid(par) then killDim(par) end
end

local function mkList(par, title)
	local menu = popShell(par, title, ScreenScale(95), ScreenScale(58))

	local scroll = mkScr(menu)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(6), ScreenScale(16), ScreenScale(6), ScreenScale(6))
	menu.ScrollPanel = scroll

	function menu:AddOption(text, onClick)
		local btn = vgui.Create("DLabel", self.ScrollPanel)
		btn:SetText(text)
		btn:SetFont("ZCity_Veteran")
		btn:SetTextColor(Color(255, 255, 255))
		btn:SetContentAlignment(4)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, ScreenScale(3))
		btn:SizeToContents()
		btn:SetWide(btn:GetWide() + ScreenScale(6))
		btn:SetTall(math.max(ScreenScale(14), btn:GetTall()))
		btn.Paint = paintLbl
		wireLbl(btn, function()
			if onClick then onClick() end
			if IsValid(menu) then menu:Remove() end
		end)
	end

	function menu:AddPanel(pnl)
		pnl:SetParent(self.ScrollPanel)
		pnl:Dock(TOP)
		pnl:DockMargin(0, 0, 0, ScreenScale(4))
	end

	return menu
end

local function mkAcc(par, title)
	local menu = popShell(par, title, ScreenScale(105), ScreenScale(62))

	local scroll = mkScr(menu)
	scroll:Dock(FILL)
	scroll:DockMargin(ScreenScale(6), ScreenScale(16), ScreenScale(6), ScreenScale(6))

	local lay = vgui.Create("DIconLayout", scroll:GetCanvas())
	lay:Dock(TOP)
	lay:SetSpaceX(ScreenScale(4))
	lay:SetSpaceY(ScreenScale(4))
	menu.IconLayout = lay
	menu.ScrollPanel = scroll

	local icoSz = ScreenScale(28)

	function menu:AddAccessoryIcon(mdl, key, dat, onPick)
		local ic = vgui.Create("SpawnIcon", self.IconLayout)
		ic:SetSize(icoSz, icoSz)
		ic:SetModel(mdl or "models/error.mdl")
		ic:SetTooltip(accNm(key, dat))

		if dat and dat.skin and not isfunction(dat.skin) then
			timer.Simple(0, function()
				if IsValid(ic) and IsValid(ic.Icon) then
					ic.Icon:SetSkin(dat.skin)
				end
			end)
		end

		function ic:DoClick()
			if onPick then onPick(key) end
			surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
			menu:Remove()
		end

		self.IconLayout:InvalidateLayout(true)
	end

	function menu:AddNoneOption(onPick)
		local ic = vgui.Create("DPanel", self.IconLayout)
		ic:SetSize(icoSz, icoSz)

		function ic:Paint(w, h)
			surface.SetDrawColor(30, 30, 35, 230)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(120, 60, 60, 255)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("нет", "ZCity_Tiny", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		function ic:OnMousePressed(mc)
			if mc ~= MOUSE_LEFT then return end
			if onPick then onPick("none") end
			surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
			menu:Remove()
		end

		function ic:OnCursorEntered() self:SetCursor("hand") end
	end

	return menu
end

local function normTbl(tbl)
	if not istable(tbl) then return tbl end
	if A.NormalizeAppearance then A.NormalizeAppearance(tbl) end
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

	local baseSetVisible = self.SetVisible
	function self:SetVisible(vis)
		baseSetVisible(self, vis)
		if not vis then A.PurgePopups(self) end
	end

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

	self.AppearanceTable = self.AppearanceTable or A.LoadAppearanceFile(A.SelectedAppearance:GetString()) or A.GetRandomAppearance()
	normTbl(self.AppearanceTable)

	local function rstCam()
		if IsValid(main) then main.modelPosID = "All" end
	end

	local function onCls(m)
		function m:OnRemove() rstCam() end
	end

	local function curMdl()
		return A.PlayerModels[1][main.AppearanceTable.AModel] or A.PlayerModels[2][main.AppearanceTable.AModel]
	end

	local function popTxt(title, posID, build)
		main.modelPosID = posID
		clsMn()
		local menu = mkList(main, title)
		if build then build(menu) end
		onCls(menu)
	end

	local function isBootBg(nm)
		return nm == "Boots" or nm == "Boots Wider"
	end

	local function popBg(title, bgKey, posID, flt)
		popTxt(title, posID, function(menu)
			local mdl = curMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local sexTable = A.Bodygroups[bgKey] and A.Bodygroups[bgKey][mdl.sex and 2 or 1]
			if not sexTable or not next(sexTable) then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			local cur = main.AppearanceTable.ABodygroups and main.AppearanceTable.ABodygroups[bgKey]
			for name, _ in SortedPairs(sexTable) do
				if flt and not flt(name) then continue end
				local label = A.GetBodygroupLabel and A.GetBodygroupLabel(name) or name
				if cur == name then label = "• " .. label end
				menu:AddOption(label, function()
					main.AppearanceTable.ABodygroups = main.AppearanceTable.ABodygroups or {}
					main.AppearanceTable.ABodygroups[bgKey] = name
					surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
				end)
			end
		end)
	end

	local function clothRow(menu, key, matPath, slot, currentKey)
		local label = A.GetClothLabel and A.GetClothLabel(key) or key
		if currentKey == key then label = "• " .. label end

		local row = vgui.Create("DButton", menu.ScrollPanel)
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, ScreenScale(3))
		row:SetTall(ScreenScale(14))
		row:SetText("")
		row:SetFont("ZCity_Tiny")

		function row:Paint(w, h)
			local bg = self:IsHovered() and Color(55, 55, 70, 240) or Color(25, 25, 32, 220)
			surface.SetDrawColor(bg)
			surface.DrawRect(0, 0, w, h)

			local mat = getMat(matPath)
			if mat then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(mat)
				surface.DrawTexturedRect(ScreenScale(2), ScreenScale(1), ScreenScale(12), h - ScreenScale(2))
			end

			draw.SimpleText(label, "ZCity_Tiny", ScreenScale(16), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		function row:DoClick()
			main.AppearanceTable.AClothes = main.AppearanceTable.AClothes or {}
			main.AppearanceTable.AClothes[slot] = key
			surface.PlaySound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav")
			if IsValid(menu) then menu:Remove() end
		end
	end

	local function popCloth(title, slot, posID)
		popTxt(title, posID, function(menu)
			local mdl = curMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local clothes = A.Clothes[mdl.sex and 2 or 1]
			if not clothes then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			local cur = main.AppearanceTable.AClothes and main.AppearanceTable.AClothes[slot]
			for k, matPath in SortedPairs(clothes) do
				clothRow(menu, k, matPath, slot, cur)
			end
		end)
	end

	local mdlNm = self.AppearanceTable.AModel
	if istable(mdlNm) then mdlNm = nil end
	if isstring(mdlNm) then mdlNm = A.ResolveModelName(mdlNm) end
	self.AppearanceTable.AModel = mdlNm

	local tMdl = isstring(mdlNm) and (A.PlayerModels[1][mdlNm] or A.PlayerModels[2][mdlNm])
	if not tMdl then
		local fbTbl, fbNm = table.Random(A.PlayerModels[1]) -- value, key
		tMdl = fbTbl
		self.AppearanceTable.AModel = fbNm
		mdlNm = fbNm
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
	controls:SetZPos(40)
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
	presetControls:SetZPos(40)
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
		["Legs"] = 0.45,
		["Boots"] = 0.08,
		["Hands"] = 0.5,
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
		tMdl = A.PlayerModels[1][tbl.AModel] or A.PlayerModels[2][tbl.AModel]
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
			Entity:SetSubMaterial(slot, A.Clothes[tMdl.sex and 2 or 1][tbl.AClothes[k]] or A.Clothes[tMdl.sex and 2 or 1]["normal"])
			Entity:SetNWString("Colthes" .. k, tbl.AClothes[k])
		end

		for i = 1, #mats do
			if A.FacemapsSlots[mats[i]] and A.FacemapsSlots[mats[i]][tbl.AFacemap] then
				Entity:SetSubMaterial(i - 1, A.FacemapsSlots[mats[i]][tbl.AFacemap])
			end
		end

		local bodygroups = Entity:GetBodyGroups()
		tbl.ABodygroups = tbl.ABodygroups or {}
		for k, v in ipairs(bodygroups) do
			if not tbl.ABodygroups[v.name] then continue end
			for i = 0, #v.submodels do
				local b = v.submodels[i]
				if not A.Bodygroups[v.name] then continue end
				if not A.Bodygroups[v.name][tMdl.sex and 2 or 1] then continue end
				if not A.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]] then continue end
				if A.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]][1] != b then continue end
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

	local function mkBtn(text, func, parent)
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
		btn.Paint = paintLbl
		wireLbl(btn, func)
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
	modelSelector:SetText(tostring(main.AppearanceTable.AModel or mdlNm or "Мужчина 07"))
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
		local mdl = A.PlayerModels[1][str] or A.PlayerModels[2][str]
		if mdl then
			main.AppearanceTable.AName = A.GenerateRandomName(mdl.sex and 2 or 1)
			NameEntry:SetText(main.AppearanceTable.AName)
		end
	end

	local modelChoices = {}
	for k in pairs(A.PlayerModels[1]) do modelChoices[#modelChoices + 1] = k end
	for k in pairs(A.PlayerModels[2]) do modelChoices[#modelChoices + 1] = k end
	table.sort(modelChoices)
	for _, k in ipairs(modelChoices) do modelSelector:AddChoice(k) end

	local slotInfo = vgui.Create("DLabel", content)
	slotInfo:SetFont("ZCity_Tiny")
	slotInfo:SetTextColor(Color(200, 200, 200))
	slotInfo:Dock(TOP)
	slotInfo:DockMargin(0, 0, 0, ScreenScale(8))
	slotInfo:SetWrap(true)
	slotInfo:SetAutoStretchVertical(true)
	slotInfo.Think = function(s)
		if not main.AppearanceTable then return end
		local c = main.AppearanceTable.AClothes or {}
		local b = main.AppearanceTable.ABodygroups or {}
		local pantsLbl = A.GetClothLabel and A.GetClothLabel(c.pants or c.main or "?") or "?"
		local bootsLbl = A.GetClothLabel and A.GetClothLabel(c.boots or c.main or "?") or "?"
		local legsLbl = b.LEGS and (A.GetBodygroupLabel and A.GetBodygroupLabel(b.LEGS) or b.LEGS) or "дефолт"
		s:SetText(string.format("Штаны: %s | Обувь (текст.): %s | Ноги (модель): %s", pantsLbl, bootsLbl, legsLbl))
	end

	-- Hats
	mkBtn("ГОЛОВНОЙ УБОР", function()
		main.modelPosID = "Head"
		clsMn()

		local menu = mkAcc(main, "Головной убор")
		for k, v in pairs(hg.Accessories) do
			if v.disallowinappearance or (v.placement != "head" and v.placement != "ears") then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[1] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[1] = "none"
		end)

		onCls(menu)
	end)

	-- Face
	mkBtn("ЛИЦО", function()
		main.modelPosID = "Face"
		clsMn()

		local menu = mkAcc(main, "Лицо — аксессуар")
		for k, v in pairs(hg.Accessories) do
			if v.disallowinappearance or v.placement != "face" then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[2] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[2] = "none"
		end)

		onCls(menu)
	end)

	-- Body
	mkBtn("ТЕЛО", function()
		main.modelPosID = "Torso"
		clsMn()

		local menu = mkAcc(main, "Тело — аксессуар")
		for k, v in pairs(hg.Accessories) do
			if v.disallowinappearance or (v.placement != "torso" and v.placement != "spine") then continue end
			menu:AddAccessoryIcon(v.model, k, v, function(key)
				main.AppearanceTable.AAttachments[3] = key
			end)
		end

		menu:AddNoneOption(function()
			main.AppearanceTable.AAttachments[3] = "none"
		end)

		onCls(menu)
	end)

	mkBtn("ТОРС (модель)", function()
		popBg("Торс — модель", "TORSO", "Torso")
	end)

	mkBtn("ШТАНЫ (текстура)", function()
		popCloth("Штаны — текстура", "pants", "Legs")
	end)

	mkBtn("ОБУВЬ (текстура)", function()
		popCloth("Обувь — текстура", "boots", "Boots")
	end)

	mkBtn("НОГИ (модель)", function()
		popBg("Штаны / шорты — модель", "LEGS", "Legs", function(nm)
			return not isBootBg(nm)
		end)
	end)

	mkBtn("ОБУВЬ (модель)", function()
		popBg("Обувь — модель", "LEGS", "Boots", function(nm)
			return isBootBg(nm)
		end)
	end)

	mkBtn("ПЕРЧАТКИ", function()
		popBg("Перчатки", "HANDS", "Hands")
	end)

	mkBtn("ЛИЦО (текстура)", function()
		popTxt("Лицо (текстура)", "Face", function(menu)
			local mdl = curMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local facemapKey = A.FacemapsModels and A.FacemapsModels[mdl.mdl]
			local facemaps = facemapKey and A.FacemapsSlots and A.FacemapsSlots[facemapKey] or {}
			if not next(facemaps) then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			local curFace = main.AppearanceTable.AFacemap
			for k, _ in SortedPairs(facemaps) do
				local label = A.GetFacemapLabel and A.GetFacemapLabel(k) or k
				if curFace == k then label = "• " .. label end
				menu:AddOption(label, function()
					main.AppearanceTable.AFacemap = k
				end)
			end
		end)
	end)

	-- Jacket (main clothes)
	mkBtn("ВЕРХ", function()
		popTxt("Верх", "Torso", function(menu)
			local colorSelector = vgui.Create("DColorCombo")
			colorSelector:SetTall(ScreenScale(20))
			function colorSelector:OnValueChanged(clr)
				main.AppearanceTable.AColor = clr
			end
			colorSelector:SetColor(main.AppearanceTable.AColor)
			menu:AddPanel(colorSelector)

			local mdl = curMdl()
			if not mdl then
				menu:AddOption("Нет модели", function() end)
				return
			end

			local clothes = A.Clothes[mdl.sex and 2 or 1]
			if not clothes then
				menu:AddOption("Нет вариантов", function() end)
				return
			end

			local curMain = main.AppearanceTable.AClothes and main.AppearanceTable.AClothes.main
			for k, matPath in SortedPairs(clothes) do
				clothRow(menu, k, matPath, "main", curMain)
			end
		end)
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
	returnBtn.Paint = paintLbl
	wireLbl(returnBtn, function()
		A.PurgePopups(main)
		if main.Close then main:Close() end
	end)

	function main:OnRemove()
		clsMn()
		killDim(main)
	end

	local presetTitle = vgui.Create("DLabel", presetContent)
	presetTitle:Dock(TOP)
	presetTitle:DockMargin(0, 0, 0, ScreenScale(4))
	presetTitle:SetFont("ZCity_Tiny")
	presetTitle:SetTextColor(Color(220, 220, 220))
	presetTitle:SetText("ПРЕСЕТЫ")
	presetTitle:SizeToContents()

	local presetNameEntry = vgui.Create("DTextEntry", presetContent)
	presetNameEntry:Dock(TOP)
	presetNameEntry:SetTall(ScreenScale(20))
	presetNameEntry:DockMargin(0, 0, 0, ScreenScale(5))
	presetNameEntry:SetFont("ZCity_Tiny")
	presetNameEntry:SetPlaceholderText("Имя пресета...")

	presetNameEntry.Paint = function(s, w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 50)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		s:DrawTextEntryText(Color(255, 255, 255), Color(255, 0, 0), Color(255, 255, 255))
	end

	local function cleanNm(raw)
		local nm = string.Trim(raw or "")
		return string.gsub(nm, "[^%wА-Яа-яЁё%s_-]", "")
	end

	local prScr = vgui.Create("DScrollPanel", presetContent)
	prScr:Dock(FILL)
	prScr:DockMargin(0, ScreenScale(4), 0, 0)
	prScr:GetVBar():SetWide(0)

	local function refPr()
		local canvas = prScr:GetCanvas()
		for _, child in ipairs(canvas:GetChildren()) do
			child:Remove()
		end

		local presetList = lsPr()
		if #presetList == 0 then
			local empty = vgui.Create("DLabel", prScr)
			empty:Dock(TOP)
			empty:SetFont("ZCity_Tiny")
			empty:SetTextColor(Color(150, 150, 150))
			empty:SetText("Пока пусто")
			empty:SizeToContents()
			return
		end

		for _, presetName in ipairs(presetList) do
			local row = vgui.Create("DButton", prScr)
			row:Dock(TOP)
			row:DockMargin(0, 0, 0, ScreenScale(2))
			row:SetTall(ScreenScale(14))
			row:SetText(presetName)
			row:SetFont("ZCity_Tiny")
			row:SetTextColor(c.txt)

			function row:Paint(w, h)
				local hov = self:IsHovered()
				surface.SetDrawColor(hov and 200 or 0, hov and 220 or 0, hov and 220 or 0, hov and 255 or 150)
				surface.DrawRect(0, 0, w, h)
				self:SetTextColor(hov and Color(0, 0, 0) or c.txt)
			end

			function row:DoClick()
				local loaded = ldPr(presetName)
				if not loaded then
					surface.PlaySound("buttons/button10.wav")
					ntf("Не удалось загрузить пресет", NOTIFY_ERROR)
					return
				end
				main.AppearanceTable = normTbl(loaded)
				NameEntry:SetText(main.AppearanceTable.AName or "")
				modelSelector:SetText(tostring(main.AppearanceTable.AModel or "Мужчина 07"))
				presetNameEntry:SetText(presetName)
				surface.PlaySound("buttons/button14.wav")
				ntf("Загружен: " .. presetName)
			end

			function row:DoRightClick()
				if dlPr(presetName) then
					surface.PlaySound("buttons/button15.wav")
					ntf("Удалён: " .. presetName)
					refPr()
				end
			end
		end
	end

	mkBtn("СОХРАНИТЬ", function()
		local presetName = cleanNm(presetNameEntry:GetValue())
		if presetName == "" or utf8.len(presetName) < 2 then
			surface.PlaySound("buttons/button10.wav")
			ntf("Имя от 2 символов", NOTIFY_ERROR)
			return
		end

		local copy = table.Copy(main.AppearanceTable)
		normTbl(copy)
		svPr(presetName, copy)
		presetNameEntry:SetText(presetName)
		surface.PlaySound("buttons/button14.wav")
		ntf("Сохранено: " .. presetName)
		refPr()
	end, presetContent)

	defPr()
	refPr()

	returnBtn:MoveToFront()
	controls:MoveToFront()
	presetControls:MoveToFront()

	self:CallbackAppearance()
end

vgui.Register("ZAppearance", PANEL, "DFrame")
