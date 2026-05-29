hg.updates = hg.updates or {}
local cvPopup = CreateClientConVar("hg_updates_popup", "1", true, false, "Показывать панель изменений при заходе")
local cookieSeen = "hg_seen_version"

local colTitle = Color(220, 215, 210)
local colMeta = Color(140, 130, 125)
local colLine = Color(200, 195, 190)

local function ShouldShow()
	if not cvPopup:GetBool() then return false end
	return cookie.GetString(cookieSeen, "") ~= hg.updates.GetLatestVersion()
end

local function MarkSeen()
	cookie.Set(cookieSeen, hg.updates.GetLatestVersion())
end

local function Font(name, fallback)
	surface.SetFont(name)
	if select(2, surface.GetTextSize("A")) > 0 then return name end
	return fallback or "DermaDefault"
end

local LerpFT = LerpFT or function(speed, cur, target)
	return Lerp(FrameTime() * (speed or 1) * 60, cur or 0, target)
end

local function MakeEscMenuButton(parent, strTitle, onClick, minWide)
	local btn = vgui.Create("DLabel", parent)
	local baseTitle = strTitle

	btn:SetText(strTitle)
	btn:SetMouseInputEnabled(true)
	btn:SetCursor("hand")
	btn:SetFont(Font("ZCity_Veteran", "DermaLarge"))
	btn:SetContentAlignment(5)
	btn:SizeToContents()
	btn:SetWide(math.max(btn:GetWide() + ScreenScale(8), minWide or 0))
	btn:SetTall(math.max(ScreenScale(18), btn:GetTall()))

	function btn:DoClick()
		sound.PlayFile("sound/press.mp3", "noblock", function(station)
			if IsValid(station) then station:Play() end
		end)
		if onClick then onClick() end
	end

	function btn:OnMousePressed(mc)
		if mc == MOUSE_LEFT then self:DoClick() end
	end

	function btn:Think()
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, self:IsHovered() and 1 or 0)
		if self.HoverLerp < 0.01 then self.HoverLerp = 0 end
		if self.HoverLerp > 0.99 then self.HoverLerp = 1 end

		local v = self.HoverLerp
		local targetText = self:IsHovered() and string.upper(baseTitle) or baseTitle
		if self:GetText() == targetText then return end

		local ntxt = ""
		for i = 1, #baseTitle do
			local char = baseTitle:sub(i, i)
			ntxt = ntxt .. (i <= math.ceil(#baseTitle * v) and string.upper(char) or char)
		end
		self:SetText(ntxt)
	end

	function btn:Paint(w, h)
		local font = self:GetFont()
		local text = self:GetText()
		local cx = w * 0.5

		if self:IsHovered() then
			if not self.HoveredSoundPlayed then
				sound.PlayFile("sound/hover.ogg", "noblock", function(station)
					if IsValid(station) then station:Play() end
				end)
				self.HoveredSoundPlayed = true
			end

			local alpha = math.random() > 0.9 and math.random(50, 200) or 255
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawRect(0, 0, w, h)
			self:SetTextColor(Color(0, 0, 0, alpha))
		else
			self.HoveredSoundPlayed = false
			self:SetTextColor(color_white)
		end

		local offX, offY = 0, 0
		if math.random() > 0.9 then
			offX = math.random(-2, 2)
			offY = math.random(-2, 2)
		end

		draw.SimpleText(text, font, cx + offX, h / 2 + offY, self:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if self:IsHovered() and math.random() > 0.7 then
			draw.SimpleText(text, font, cx + math.random(-5, 5), h / 2 + math.random(-2, 2),
				Color(0, 0, 0, math.random(50, 150)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		return true
	end

	return btn
end

local function BuildScroll(parent)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(12, 8, 12, 8)

	local sbar = scroll:GetVBar()
	sbar:SetWide(6)
	sbar:SetHideButtons(true)
	function sbar:Paint(w, h)
		draw.RoundedBox(3, 0, 0, w, h, Color(25, 22, 22, 200))
	end
	function sbar.btnGrip:Paint(w, h)
		draw.RoundedBox(3, 1, 1, w - 2, h - 2, Color(90, 25, 20, 220))
	end

	return scroll
end

local function AddUpdateBlock(canvas, entry, fonts)
	local block = vgui.Create("DPanel", canvas)
	block:Dock(TOP)
	block:DockMargin(0, 0, 0, 16)
	block:SetPaintBackground(false)

	local title = vgui.Create("DLabel", block)
	title:SetFont(fonts.title)
	title:SetTextColor(colTitle)
	title:SetText(entry.title or "Обновление")
	title:Dock(TOP)
	title:SizeToContents()

	local meta = vgui.Create("DLabel", block)
	meta:SetFont(fonts.meta)
	meta:SetTextColor(colMeta)
	meta:SetText(string.format("%s  ·  %s", entry.version or "?", entry.date or ""))
	meta:Dock(TOP)
	meta:DockMargin(0, 4, 0, 8)
	meta:SizeToContents()

	for _, line in ipairs(entry.lines or {}) do
		local lbl = vgui.Create("DLabel", block)
		lbl:SetFont(fonts.body)
		lbl:SetTextColor(colLine)
		lbl:SetText("•  " .. line)
		lbl:SetWrap(true)
		lbl:SetAutoStretchVertical(true)
		lbl:Dock(TOP)
		lbl:DockMargin(4, 0, 0, 4)
	end

	function block:PerformLayout(w)
		for _, child in ipairs(self:GetChildren()) do
			if child.SetWide then child:SetWide(w - 8) end
		end
		self:SizeToChildren(false, true)
	end

	block:InvalidateLayout(true)
end

function hg.updates.OpenPanel(force)
	if not force and not ShouldShow() then return end
	if IsValid(hg.updates.panel) then
		hg.updates.panel:MakePopup()
		return
	end

	local list = hg.updates.updts
	if not list or #list == 0 then return end

	local fonts = {
		title = Font("ZCity_Medium", "DermaLarge"),
		meta = Font("ZCity_Small", "DermaDefault"),
		body = Font("ZCity_Tiny", "DermaDefault"),
	}

	local frame
	if vgui.GetControlTable("ZFrame") then
		frame = vgui.Create("ZFrame")
	else
		frame = vgui.Create("DFrame")
	end

	hg.updates.panel = frame
	frame:SetTitle("Последние изменения")
	frame:SetSize(math.min(ScrW() * 0.45, 640), math.min(ScrH() * 0.55, 520))
	frame:Center()
	frame:MakePopup()
	frame:SetDeleteOnClose(true)

	function frame:OnClose()
		MarkSeen()
		hg.updates.panel = nil
	end

	if frame.First then frame:First() end

	local scroll = BuildScroll(frame)
	local canvas = scroll:GetCanvas()

	for i = #list, 1, -1 do
		AddUpdateBlock(canvas, list[i], fonts)
	end

	local bottom = vgui.Create("DPanel", frame)
	bottom:Dock(BOTTOM)
	bottom:SetTall(math.max(ScreenScale(22), 40))
	bottom:SetPaintBackground(false)

	local closeWide = ScreenScale(120)
	local close = MakeEscMenuButton(bottom, "Понятно", function()
		if frame.Close then
			frame:Close()
		else
			frame:Remove()
		end
	end, closeWide)

	function bottom:PerformLayout(w, h)
		if not IsValid(close) then return end
		close:SetWide(math.max(closeWide, w * 0.55))
		close:SetPos((w - close:GetWide()) * 0.5, (h - close:GetTall()) * 0.5)
	end
end
hook.Add("InitPostEntity", "HG_Updates_OpenPanelOnSpawn", function()
	if ShouldShow() then
		timer.Simple(2, function()
			if ShouldShow() then
				hg.updates.OpenPanel()
			end
		end)
	end
end)

concommand.Add("hg_updates", function()
	hg.updates.OpenPanel(true)
end)
