local PANEL = {}

local function drawMedal(w, h, scale)
    local s = math.min(w, h) * (scale or 1)
    local x, y = (w - s) * 0.5, (h - s) * 0.5
    surface.SetDrawColor(0, 0, 0, 140)
    surface.DrawRect(x + 4, y + 4, s, s)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(x, y, s, s)
end

function PANEL:Init()
    local col = zb.Experience.UI.col
    local pad = ScreenScale(6)
    local avH = ScreenScaleH(52)

    self.Avatar = vgui.Create("AvatarImage", self)
    self.Avatar:Dock(TOP)
    self.Avatar:DockMargin(pad, pad, pad, ScreenScaleH(4))
    self.Avatar:SetTall(avH)
    self.Avatar:SetMouseInputEnabled(false)

    self.Name = vgui.Create("DLabel", self)
    self.Name:Dock(TOP)
    self.Name:SetContentAlignment(5)
    self.Name:SetTall(ScreenScaleH(18))
    self.Name:SetFont("ZCity_Veteran")
    self.Name:SetTextColor(col.text)

    self.Medals = vgui.Create("DPanel", self)
    self.Medals:Dock(FILL)
    self.Medals:DockMargin(pad, ScreenScaleH(6), pad, ScreenScaleH(4))
    self.Medals.Paint = function(pnl, pw, ph)
        if not pnl.band or not pnl.medal then return end
        surface.SetMaterial(pnl.band.icon)
        drawMedal(pw, ph)
        surface.SetMaterial(pnl.medal.icon)
        drawMedal(pw, ph, 0.72)
    end

    self.Tier = vgui.Create("DLabel", self)
    self.Tier:Dock(BOTTOM)
    self.Tier:DockMargin(0, 0, 0, ScreenScaleH(2))
    self.Tier:SetContentAlignment(5)
    self.Tier:SetTall(ScreenScaleH(20))
    self.Tier:SetFont("ZCity_Veteran")
    self.Tier:SetTextColor(col.textBlood)

    self.Xp = vgui.Create("DLabel", self)
    self.Xp:Dock(BOTTOM)
    self.Xp:SetContentAlignment(5)
    self.Xp:SetTall(ScreenScaleH(16))
    self.Xp:SetFont("ZB_InterfaceSmall")
    self.Xp:SetTextColor(col.textDim)

    self.Skill = vgui.Create("DLabel", self)
    self.Skill:Dock(BOTTOM)
    self.Skill:SetContentAlignment(5)
    self.Skill:SetTall(ScreenScaleH(16))
    self.Skill:SetFont("ZB_InterfaceSmall")
    self.Skill:SetTextColor(col.textMuted)

    self.Paint = function(_, pw, ph)
        surface.SetDrawColor(col.panelBG)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(col.panelBorder)
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
        surface.SetDrawColor(col.separator)
        surface.DrawRect(pad, avH + ScreenScaleH(22), pw - pad * 2, 1)
    end
end

function PANEL:Pull()
    local ply = self.ply
    if not IsValid(ply) then return end
    local band, medal = ply:GetAwards()
    self.Medals.band = band
    self.Medals.medal = medal
    self.Tier:SetText(medal and medal.name or "—")
    self.Xp:SetText(math.floor(ply.exp or 0) .. " XP")
    self.Skill:SetText("Skill " .. math.Round(ply.skill or 0, 3))
end

function PANEL:SetPlayer(ply)
    self.ply = ply
    self.Avatar:SetPlayer(ply, 64)
    self.Name:SetText(ply:Nick())
    self:Pull()

    local last = ply.exp
    self.Think = function()
        if not IsValid(ply) then return end
        if ply.exp == last then return end
        last = ply.exp
        self:Pull()
    end
end

vgui.Register("ZB_ExpPanel", PANEL, "DPanel")
