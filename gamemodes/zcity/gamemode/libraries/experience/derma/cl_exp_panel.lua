-- cl_exp_panel.lua
local PANEL = {}

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local col = {
	panelBG     = Color(8, 8, 16, 245),
	panelBorder = Color(255, 255, 255, 25),
	headerBG    = Color(6, 6, 14, 250),
	text        = Color(200, 200, 200, 255),
	textDim     = Color(160, 160, 165, 180),
	textMuted   = Color(100, 100, 108, 140),
	textBlood   = Color(180, 40, 35, 255),
	accent      = Color(200, 200, 200, 60),
	separator   = Color(255, 255, 255, 12),
	xpBarBG     = Color(255, 255, 255, 8),
	xpBarFill   = Color(180, 40, 35, 160),
	xpBarBorder = Color(255, 255, 255, 20),
	medalShadow = Color(0, 0, 0, 120),
}

local shakeStrength = 0.6

local function GetShake()
	local t = CurTime()
	return
		math.sin(t * 28) * shakeStrength * 0.2,
		math.cos(t * 24) * shakeStrength * 0.15
end

local function RenderMedalBox(w, h)
	if w > h then
		surface.SetDrawColor(col.medalShadow)
		surface.DrawTexturedRect((w / 2 - h / 2) + 3, 3, h, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(w / 2 - h / 2, 0, h, h)
	else
		surface.SetDrawColor(col.medalShadow)
		surface.DrawTexturedRect(3, (h / 2 - w / 2) + 3, w, w)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(0, h / 2 - w / 2, w, w)
	end
end

function PANEL:Init()
	self.Player = nil

	self.PlyLabel = vgui.Create("DPanel", self)
	self.PlyLabel:Dock(TOP)
	self.PlyLabel:SetTall(ScreenScaleH(28))
	self.PlyLabel:DockMargin(0, 0, 0, 0)
	self.PlyLabel.text = ""
	self.PlyLabel.Paint = function(lbl, lw, lh)
		surface.SetDrawColor(col.headerBG)
		surface.DrawRect(0, 0, lw, lh)

		local wX, wY = GetShake()
		local t = CurTime()
		local pulse = math.sin(t * 1.2) * 0.1 + 0.9

		draw.SimpleText(lbl.text, "ZCity_Veteran", lw * 0.5 + wX, lh * 0.5 + wY,
			Color(col.text.r * pulse, col.text.g * pulse, col.text.b * pulse, 255),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		surface.SetDrawColor(col.separator)
		surface.DrawRect(0, lh - 1, lw, 1)
	end
	self.PlyLabel.SetText = function(lbl, txt)
		lbl.text = txt
	end

	self.AvatarPanel = vgui.Create("DPanel", self)
	self.AvatarPanel:Dock(TOP)
	self.AvatarPanel:SetTall(ScreenScaleH(12))
	self.AvatarPanel:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), 0)
	self.AvatarPanel.Paint = function() end

	local avatarSize = ScreenScaleH(10)
	self.Avatar = vgui.Create("AvatarImage", self.AvatarPanel)
	self.Avatar:SetSize(avatarSize, avatarSize)

	self.AvatarPanel.PerformLayout = function(pnl, pw, ph)
		if IsValid(self.Avatar) then
			self.Avatar:SetPos(pw * 0.5 - avatarSize * 0.5, ph * 0.5 - avatarSize * 0.5)
		end
	end

	self.MedalPanel = vgui.Create("DPanel", self)
	self.MedalPanel:Dock(FILL)
	self.MedalPanel:DockMargin(ScreenScale(3), ScreenScale(2), ScreenScale(3), ScreenScale(1))
	self.MedalPanel.Band = nil
	self.MedalPanel.Medal = nil

	self.MedalPanel.Paint = function(mpnl, w, h)
		surface.SetDrawColor(col.panelBG)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(col.panelBorder)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		if not mpnl.Band or not mpnl.Medal then
			local wX, wY = GetShake()
			draw.SimpleText("Нет медали", "ZCity_Veteran", w * 0.5 + wX, h * 0.5 + wY, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		surface.SetMaterial(mpnl.Band.icon)
		RenderMedalBox(w, h)
		surface.SetMaterial(mpnl.Medal.icon)
		RenderMedalBox(w, h)
	end

	self.ExpPanel = vgui.Create("DPanel", self)
	self.ExpPanel:Dock(BOTTOM)
	self.ExpPanel:SetTall(ScreenScaleH(34))
	self.ExpPanel:DockMargin(0, 0, 0, 0)
	self.ExpPanel.ply = nil
	self.ExpPanel.Paint = function(epnl, ew, eh)
		surface.SetDrawColor(col.headerBG)
		surface.DrawRect(0, 0, ew, eh)
		surface.SetDrawColor(col.separator)
		surface.DrawRect(0, 0, ew, 1)

		local ply = epnl.ply
		if not IsValid(ply) then return end

		local wX, wY = GetShake()
		local t = CurTime()

		local xp = ply.exp or 0
		local skill = math.Round(ply.skill or 0, 3)

		local xpText = tostring(xp) .. " XP"
		draw.SimpleText(xpText, "ZCity_Veteran", ew * 0.5 + wX, eh * 0.3 + wY, col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local skillText = "Навык: " .. tostring(skill)
		local skillPulse = math.sin(t * 1.8) * 0.15 + 0.85
		draw.SimpleText(skillText, "ZB_InterfaceSmall", ew * 0.5 + wX * 0.7, eh * 0.7 + wY * 0.7,
			Color(col.textBlood.r * skillPulse, col.textBlood.g * skillPulse, col.textBlood.b * skillPulse, 220),
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function PANEL:SetPlayer(ply)
	self.Player = ply
	local Band, Medal = ply:GetAwards()

	self.MedalPanel.Band = Band
	self.MedalPanel.Medal = Medal
	self.PlyLabel:SetText(ply:Nick())
	self.ExpPanel.ply = ply

	if IsValid(self.Avatar) then
		self.Avatar:SetPlayer(ply, 64)
	end

	local oldexp = 0
	self.Think = function(selfPnl)
		if not IsValid(ply) then return end
		if ply.exp ~= oldexp then
			local b, m = ply:GetAwards()
			selfPnl.MedalPanel.Band = b
			selfPnl.MedalPanel.Medal = m
			oldexp = ply.exp
		end
	end
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(col.panelBG)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(col.panelBorder)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	if not NoiseMat:IsError() then
		surface.SetMaterial(NoiseMat)
		surface.SetDrawColor(255, 255, 255, 4)
		local noiseOffX = math.random(0, 512)
		local noiseOffY = math.random(0, 512)
		surface.DrawTexturedRectUV(0, 0, w, h,
			noiseOffX / 512, noiseOffY / 512,
			noiseOffX / 512 + w / 768, noiseOffY / 512 + h / 768)
	end

	for y = 0, h, 3 do
		surface.SetDrawColor(0, 0, 0, 8)
		surface.DrawRect(0, y, w, 1)
	end
end

vgui.Register("ZB_ExpPanel", PANEL, "DPanel")