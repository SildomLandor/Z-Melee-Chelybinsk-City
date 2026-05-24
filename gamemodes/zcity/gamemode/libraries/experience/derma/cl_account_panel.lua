local PANEL = {}

local stats = {
    {"Убийства", "Kills"},
    {"Самоубийства", "Suicides"},
    {"Смерти", "Deaths"},
}

local function paintBox(col, w, h)
    surface.SetDrawColor(col.panelBG)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(col.panelBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function PANEL:Init()
    local col = zb.Experience.UI.col
    local ui = zb.Experience.UI

    local w, h = math.floor(ScrW() * 0.52), math.floor(ScrH() * 0.62)
    self:SetPos(math.floor(ScrW() * 0.5 - w * 0.5), math.floor(ScrH() * 0.5 - h * 0.5))
    self:SetSize(w, h)
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetColorBG(col.frameBG)
    self:SetColorBR(col.frameBorder)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.15, 0)
    self:CreateHorrorCloseButton()

    local m = ScreenScale(8)
    local topH = ScreenScaleH(36)
    local sectH = ScreenScaleH(20)
    local gap = ScreenScale(5)
    local leftW = math.floor((w - m * 2 - gap) * 0.36)
    local rightX = m + leftW + gap
    local rightW = w - rightX - m
    local bodyY = topH + sectH + ScreenScaleH(4)
    local bodyH = h - bodyY - m - ScreenScaleH(28)

    self.m, self.topH, self.sectH = m, topH, sectH
    self.leftW, self.rightX, self.rightW = leftW, rightX, rightW

    local left = vgui.Create("DPanel", self)
    left:SetPos(m, bodyY)
    left:SetSize(leftW, bodyH)
    left.Paint = function(_, pw, ph) paintBox(col, pw, ph) end

    self.Medal = vgui.Create("ZB_ExpPanel", left)
    self.Medal:Dock(FILL)

    local right = vgui.Create("DPanel", self)
    right:SetPos(rightX, bodyY)
    right:SetSize(rightW, bodyH)
    right.Paint = function(_, pw, ph) paintBox(col, pw, ph) end

    self.StatList = vgui.Create("DScrollPanel", right)
    self.StatList:Dock(FILL)
    self.StatList:DockMargin(2, 2, 2, 2)
    self.StatList.Paint = function() end
    ui.StyleScrollbar(self.StatList:GetVBar())

    local steam = vgui.Create("DButton", self)
    steam:SetText("")
    steam:SetPos(m + 2, h - ScreenScaleH(26))
    steam:SetSize(ScreenScale(120), ScreenScaleH(18))
    steam:SetCursor("hand")
    steam.Paint = function(s, bw, bh)
        local hov = s:IsHovered()
        draw.SimpleText("Steam профиль", "ZCity_Veteran", 0, bh * 0.5, hov and col.text or col.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if hov then
            surface.SetDrawColor(col.accent)
            surface.DrawRect(0, bh - 1, bw, 1)
        end
    end
    steam.DoClick = function()
        if not IsValid(self.ply) or self.ply:IsBot() then return end
        gui.OpenURL("https://steamcommunity.com/profiles/" .. self.ply:SteamID64())
    end

    self.ShakeX, self.ShakeY = 0, 0
    self.ShakeTX, self.ShakeTY = 0, 0
    self.ShakeNext = 0
    local shakeAmp = 0.45

    self.Drips = {}
    for i = 1, math.random(4, 7) do
        self.Drips[i] = {
            x = math.random(0, w),
            w = math.random(1, 2),
            h = math.random(ScreenScaleH(8), ScreenScaleH(32)),
            a = math.random(6, 22),
            spd = math.Rand(0.15, 0.55),
            ph = math.Rand(0, math.pi * 2),
        }
    end

    self.Think = function(me)
        local t = CurTime()
        if t >= me.ShakeNext then
            me.ShakeNext = t + 0.04
            me.ShakeTX = math.Rand(-shakeAmp, shakeAmp)
            me.ShakeTY = math.Rand(-shakeAmp * 0.6, shakeAmp * 0.6)
        end
        local k = math.Clamp(FrameTime() * 22, 0, 1)
        me.ShakeX = Lerp(k, me.ShakeX, me.ShakeTX)
        me.ShakeY = Lerp(k, me.ShakeY, me.ShakeTY)
    end
end

function PANEL:PaintOver(w, h)
    local col = zb.Experience.UI.col
    local m, topH, sectH = self.m, self.topH, self.sectH
    local leftW, rightX, rightW = self.leftW, self.rightX, self.rightW
    local t = CurTime()
    local sx, sy = self.ShakeX, self.ShakeY

    zb.Experience.UI.PaintNoiseOverlay(w, h, col, 6)

    for _, d in ipairs(self.Drips) do
        local pulse = math.sin(t * d.spd + d.ph) * 0.3 + 0.7
        surface.SetDrawColor(100, 15, 12, math.floor(d.a * pulse))
        surface.DrawRect(d.x + sx, 0, d.w, d.h)
    end

    surface.SetFont("ZCity_Veteran")
    local nick = IsValid(self.ply) and self.ply:Nick() or "—"
    local title = "Статистика: " .. nick
    local tw = surface.GetTextSize(title)
    local tx, ty = w * 0.5 - tw * 0.5 + sx, ScreenScaleH(6) + sy
    surface.SetTextColor(col.textTitle)
    surface.SetTextPos(tx, ty)
    surface.DrawText(title)

    surface.SetDrawColor(col.separator)
    surface.DrawRect(m, topH - 1, w - m * 2, 1)

    local sectY = topH + ScreenScaleH(1)
    surface.SetFont("ZCity_Veteran")
    surface.SetTextColor(col.textTitle)
    surface.SetTextPos(m + ScreenScale(2) + sx * 0.4, sectY + sy * 0.3)
    surface.DrawText("НАГРАДЫ")
    surface.SetTextPos(rightX + ScreenScale(2) + sx * 0.4, sectY + sy * 0.3)
    --surface.DrawText("СТАТИСТИКА")

    local sepY = sectY + sectH - 2
    surface.SetDrawColor(col.accent)
    surface.DrawRect(m, sepY, leftW, 1)
    surface.SetDrawColor(col.accentDim)
    surface.DrawRect(rightX, sepY, rightW, 1)

    surface.SetDrawColor(col.separator)
    surface.DrawRect(m, h - ScreenScaleH(30), w - m * 2, 1)

    if math.random() > 0.985 then
        surface.SetDrawColor(255, 255, 255, math.random(5, 16))
        surface.DrawRect(0, math.random(0, h), w, math.random(1, 2))
    end
end

function PANEL:SetPlayer(ply)
    self.ply = ply
    self.Medal:SetPlayer(ply)

    self.StatList:Clear()
    local col = zb.Experience.UI.col
    local rowH = ScreenScaleH(26)
    local frame = self

    for _, row in ipairs(stats) do
        local lbl, key = row[1], row[2]
        local pnl = vgui.Create("DPanel", self.StatList)
        pnl:Dock(TOP)
        pnl:SetTall(rowH)
        pnl.Paint = function(_, rw, rh)
            local val = 0
            if IsValid(frame.ply) then val = frame.ply:GetStatVal(key, 0) end
            draw.SimpleText(lbl, "ZCity_Veteran", ScreenScale(8), rh * 0.5, col.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(val), "ZCity_Veteran", rw - ScreenScale(8), rh * 0.5, col.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(col.separator)
            surface.DrawRect(ScreenScale(6), rh - 1, rw - ScreenScale(12), 1)
        end
    end
end

function PANEL:Update(ply)
    if IsValid(self.Medal) then self.Medal:Pull() end
end

vgui.Register("ZB_AccountFrame", PANEL, "ZFrame")
