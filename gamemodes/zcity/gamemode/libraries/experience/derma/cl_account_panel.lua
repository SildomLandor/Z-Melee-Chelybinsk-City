local PANEL = {}

local Statics = {
    {"Убийства", "Kills"},
    {"Суициды", "Suicides"},
    {"Смерти", "Deaths"},
}

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local col = {
    frameBG        = Color(10, 10, 19, 235),
    frameBorder    = Color(90, 90, 95, 120),
    panelBG        = Color(8, 8, 16, 245),
    panelBorder    = Color(255, 255, 255, 25),
    headerBG       = Color(6, 6, 14, 250),
    headerBorder   = Color(255, 255, 255, 18),
    text           = Color(200, 200, 200, 255),
    textDim        = Color(160, 160, 165, 180),
    textMuted      = Color(100, 100, 108, 140),
    textBlood      = Color(180, 40, 35, 255),
    accent         = Color(200, 200, 200, 60),
    accentDim      = Color(255, 255, 255, 15),
    separator      = Color(255, 255, 255, 12),
    rowAlt         = Color(255, 255, 255, 4),
    rowHover       = Color(255, 255, 255, 15),
    rowBorder      = Color(255, 255, 255, 8),
    scrollTrack    = Color(255, 255, 255, 6),
    scrollGrip     = Color(200, 200, 200, 60),
    scrollGripHov  = Color(200, 200, 200, 100),
    statLabel      = Color(140, 140, 148, 200),
    statValue      = Color(200, 200, 200, 255),
    tabActive      = Color(200, 200, 200, 255),
    tabInactive    = Color(100, 100, 108, 140),
    tabHover       = Color(160, 160, 165, 200),
    tabLine        = Color(180, 40, 35, 200),
    tabLineDim     = Color(255, 255, 255, 15),
}

local shakeStrength = 0.6
local shakeState = {
    x = 0, y = 0,
    targetX = 0, targetY = 0,
    nextSample = 0,
}

local function UpdateShake()
    local t = CurTime()
    if t >= shakeState.nextSample then
        shakeState.nextSample = t + 0.035
        shakeState.targetX = math.Rand(-shakeStrength, shakeStrength)
        shakeState.targetY = math.Rand(-shakeStrength * 0.6, shakeStrength * 0.6)
    end
    local rate = math.Clamp(FrameTime() * 22, 0, 1)
    shakeState.x = Lerp(rate, shakeState.x, shakeState.targetX)
    shakeState.y = Lerp(rate, shakeState.y, shakeState.targetY)
end

local function PaintVHSOverlay(w, h)
    if not NoiseMat:IsError() then
        surface.SetMaterial(NoiseMat)
        surface.SetDrawColor(255, 255, 255, 6)
        local noiseOffX = math.random(0, 512)
        local noiseOffY = math.random(0, 512)
        surface.DrawTexturedRectUV(0, 0, w, h,
            noiseOffX / 512, noiseOffY / 512,
            noiseOffX / 512 + w / 768, noiseOffY / 512 + h / 768)
    end

    for y = 0, h, 3 do
        surface.SetDrawColor(0, 0, 0, 12)
        surface.DrawRect(0, y, w, 1)
    end

    if math.random() > 0.985 then
        local glitchY = math.random(0, h)
        local glitchH = math.random(1, 3)
        surface.SetDrawColor(255, 255, 255, math.random(5, 18))
        surface.DrawRect(0, glitchY, w, glitchH)
    end
end

local function PaintFrameBG(self, w, h)
    surface.SetDrawColor(col.frameBG)
    surface.DrawRect(0, 0, w, h)
    PaintVHSOverlay(w, h)
    surface.SetDrawColor(col.frameBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local function StyleScrollbar(sbar)
    if not IsValid(sbar) then return end
    sbar:SetHideButtons(true)
    sbar.Paint = function(_, sw, sh)
        surface.SetDrawColor(col.scrollTrack)
        surface.DrawRect(0, 0, sw, sh)
    end
    sbar.btnGrip.Paint = function(self, sw, sh)
        local c = self:IsHovered() and col.scrollGripHov or col.scrollGrip
        surface.SetDrawColor(c)
        surface.DrawRect(2, 0, sw - 4, sh)
    end
end

local bloodDrips = {}
local function InitBloodDrips(w, h)
    bloodDrips = {}
    for i = 1, math.random(4, 7) do
        bloodDrips[i] = {
            x = math.random(0, w),
            w = math.random(1, 2),
            h = math.random(ScreenScaleH(8), ScreenScaleH(35)),
            alpha = math.random(6, 22),
            speed = math.Rand(0.15, 0.6),
            offset = math.Rand(0, math.pi * 2),
        }
    end
end

local function PaintBloodDrips(w, h)
    local t = CurTime()
    for _, drip in ipairs(bloodDrips) do
        local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
        local a = math.floor(drip.alpha * pulse)
        surface.SetDrawColor(100, 15, 12, a)
        surface.DrawRect(drip.x + shakeState.x, 0, drip.w, drip.h)
    end
end

function PANEL:Init()
    self:SetSize(ScrW() * 0.5, ScrH() * 0.6)
    self:Center()
    self:ShowCloseButton(false)
    self:SetTitle("")

    if self.SetColorBG then self:SetColorBG(col.frameBG) end
    if self.SetColorBR then self:SetColorBR(col.frameBorder) end

    self:SetAlpha(0)
    self:AlphaTo(255, 0.15, 0)

    InitBloodDrips(self:GetWide(), self:GetTall())

    self.openTime = CurTime()

    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetSize(ScreenScale(12), ScreenScale(12))
    closeBtn:SetText("")
    closeBtn:SetCursor("hand")
    closeBtn.Paint = function(btn, bw, bh)
        local t = CurTime()
        local wX = math.sin(t * 28 + 99) * shakeStrength * 0.2
        local wY = math.cos(t * 24 + 99) * shakeStrength * 0.15
        local hovered = btn:IsHovered()
        local tc = hovered and Color(255, 255, 255, 255) or col.textDim
        draw.SimpleText("✕", "ZCity_Veteran", bw * 0.5 + wX, bh * 0.5 + wY, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if hovered then
            surface.SetDrawColor(col.textBlood.r, col.textBlood.g, col.textBlood.b, 120)
            surface.DrawRect(2, bh - 2, bw - 4, 1)
        end
    end
    closeBtn.DoClick = function()
        if IsValid(self) then
            self:AlphaTo(0, 0.1, 0, function(_, pnl)
                if IsValid(pnl) then pnl:Remove() end
            end)
        end
    end
    self.CloseBtn = closeBtn

    local MInfo = vgui.Create("ZB_ExpPanel", self)
    MInfo:Dock(LEFT)
    MInfo:SetWide(math.floor(self:GetWide() * 0.35))
    MInfo:DockMargin(ScreenScale(3), ScreenScale(3), 0, ScreenScale(3))
    self.MainInfo = MInfo

    local rightArea = vgui.Create("DPanel", self)
    rightArea:Dock(FILL)
    rightArea:DockMargin(ScreenScale(3), ScreenScale(3), ScreenScale(3), ScreenScale(3))
    rightArea.Paint = function() end
    self.RightArea = rightArea

    local tabBar = vgui.Create("DPanel", rightArea)
    tabBar:Dock(TOP)
    tabBar:SetTall(ScreenScaleH(22))
    tabBar:DockMargin(0, 0, 0, 0)
    self.TabBar = tabBar

    self.ActiveTab = 1
    self.TabButtons = {}
    self.TabPanels = {}

    local tabs = {
        {name = "Статистика", icon = nil},
    }

    tabBar.Paint = function(_, tw, th)
        surface.SetDrawColor(col.headerBG)
        surface.DrawRect(0, 0, tw, th)
        surface.SetDrawColor(col.headerBorder)
        surface.DrawRect(0, th - 1, tw, 1)
    end

    for idx, tab in ipairs(tabs) do
        local tbtn = vgui.Create("DButton", tabBar)
        tbtn:Dock(LEFT)
        tbtn:SetWide(math.floor(ScreenScale(50)))
        tbtn:SetText("")
        tbtn:SetCursor("hand")
        local capturedIdx = idx
        tbtn.Paint = function(btn, bw, bh)
            UpdateShake()
            local t = CurTime()
            local wX = math.sin(t * 28 + capturedIdx * 2) * shakeStrength * 0.2
            local wY = math.cos(t * 24 + capturedIdx * 2) * shakeStrength * 0.15
            local isActive = (self.ActiveTab == capturedIdx)
            local hovered = btn:IsHovered()
            local tc
            if isActive then
                tc = col.tabActive
            elseif hovered then
                tc = col.tabHover
            else
                tc = col.tabInactive
            end
            draw.SimpleText(tab.name, "ZCity_Veteran", bw * 0.5 + wX, bh * 0.5 + wY, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if isActive then
                surface.SetDrawColor(col.tabLine)
                surface.DrawRect(4, bh - 2, bw - 8, 2)
            elseif hovered then
                surface.SetDrawColor(col.tabLineDim)
                surface.DrawRect(4, bh - 1, bw - 8, 1)
            end
        end
        tbtn.DoClick = function()
            self:SwitchTab(capturedIdx)
        end
        self.TabButtons[idx] = tbtn
    end

    local panel1 = vgui.Create("DScrollPanel", rightArea)
    panel1:Dock(FILL)
    panel1:DockMargin(0, ScreenScale(1), 0, 0)
    panel1.Paint = function(_, pw, ph)
        surface.SetDrawColor(col.panelBG)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(col.panelBorder)
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    end
    StyleScrollbar(panel1:GetVBar())
    self.StatPanel = panel1
    self.TabPanels[1] = panel1
end

function PANEL:SwitchTab(idx)
    self.ActiveTab = idx
    for i, pnl in pairs(self.TabPanels) do
        if IsValid(pnl) then
            pnl:SetVisible(i == idx)
        end
    end
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.CloseBtn) then
        self.CloseBtn:SetPos(w - self.CloseBtn:GetWide() - 4, 4)
    end
    if IsValid(self.MainInfo) then
        self.MainInfo:SetWide(math.floor(w * 0.35))
    end
end

function PANEL:SetPlayer(ply)
    if not IsValid(ply) then return end
    self.MainInfo:SetPlayer(ply)

    local canvas = self.StatPanel:GetCanvas()
    if not IsValid(canvas) then return end

    for _, child in ipairs(canvas:GetChildren()) do
        child:Remove()
    end

    local headerPanel = vgui.Create("DPanel", self.StatPanel)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(ScreenScaleH(20))
    headerPanel:DockMargin(0, 0, 0, 0)
    headerPanel.Paint = function(_, hw, hh)
        UpdateShake()
        local t = CurTime()
        local wX = math.sin(t * 28 + 5) * shakeStrength * 0.15
        local wY = math.cos(t * 24 + 5) * shakeStrength * 0.1
        surface.SetDrawColor(col.headerBG)
        surface.DrawRect(0, 0, hw, hh)
        draw.SimpleText("БОЕВАЯ СТАТИСТИКА", "ZCity_Veteran", ScreenScale(4) + wX, hh * 0.5 + wY, col.textBlood, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(col.separator)
        surface.DrawRect(0, hh - 1, hw, 1)
    end

    for i, stats in ipairs(Statics) do
        local rowPanel = vgui.Create("DPanel", self.StatPanel)
        rowPanel:Dock(TOP)
        rowPanel:SetTall(ScreenScaleH(20))
        rowPanel:DockMargin(0, 0, 0, 0)

        local capturedI = i
        local statName = stats[1]
        local statKey = stats[2]
        local statVal = ply:GetStatVal(statKey, 0)

        rowPanel.Paint = function(_, rw, rh)
            UpdateShake()
            local t = CurTime()
            local wX = math.sin(t * 28 + capturedI * 0.8) * shakeStrength * 0.2
            local wY = math.cos(t * 24 + capturedI * 0.8) * shakeStrength * 0.15

            if capturedI % 2 == 0 then
                surface.SetDrawColor(col.rowAlt)
                surface.DrawRect(0, 0, rw, rh)
            end

            surface.SetDrawColor(col.rowBorder)
            surface.DrawRect(0, rh - 1, rw, 1)

            draw.SimpleText(statName, "ZCity_Veteran", ScreenScale(6) + wX, rh * 0.5 + wY, col.statLabel, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(statVal), "ZCity_Veteran", rw - ScreenScale(6) + wX, rh * 0.5 + wY, col.statValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    local sepPanel = vgui.Create("DPanel", self.StatPanel)
    sepPanel:Dock(TOP)
    sepPanel:SetTall(ScreenScaleH(6))
    sepPanel:DockMargin(0, 0, 0, 0)
    sepPanel.Paint = function(_, sw, sh)
        surface.SetDrawColor(col.separator)
        surface.DrawRect(ScreenScale(2), sh * 0.5, sw - ScreenScale(4), 1)
    end

    local kdPanel = vgui.Create("DPanel", self.StatPanel)
    kdPanel:Dock(TOP)
    kdPanel:SetTall(ScreenScaleH(20))
    kdPanel:DockMargin(0, 0, 0, 0)
    kdPanel.Paint = function(_, rw, rh)
        UpdateShake()
        local t = CurTime()
        local wX = math.sin(t * 28 + 20) * shakeStrength * 0.2
        local wY = math.cos(t * 24 + 20) * shakeStrength * 0.15

        local kills = ply:GetStatVal("Kills", 0)
        local deaths = ply:GetStatVal("Deaths", 0)
        local kd = deaths > 0 and math.Round(kills / deaths, 2) or kills

        draw.SimpleText("K/D", "ZCity_Veteran", ScreenScale(6) + wX, rh * 0.5 + wY, col.statLabel, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local kdCol = kd >= 1 and Color(120, 200, 120, 220) or col.textBlood
        draw.SimpleText(tostring(kd), "ZCity_Veteran", rw - ScreenScale(6) + wX, rh * 0.5 + wY, kdCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

function PANEL:Update(ply)
    self:SetPlayer(ply)
end

function PANEL:Think()
    UpdateShake()
end

function PANEL:Paint(w, h)
    PaintFrameBG(self, w, h)
    PaintBloodDrips(w, h)
end

vgui.Register("ZB_AccountFrame", PANEL, "ZFrame")