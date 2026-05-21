zb = zb or {}
zb.Experience = zb.Experience or {}

local EXP = zb.Experience

EXP.OpenedMenu = EXP.OpenedMenu or nil

local NoiseMat = Material("vgui/noisevhs")
if NoiseMat:IsError() then NoiseMat = Material("vgui/white") end

local col = {
    frameBG     = Color(10, 10, 19, 235),
    frameBorder = Color(90, 90, 95, 120),
    panelBG     = Color(8, 8, 16, 245),
    panelBorder = Color(255, 255, 255, 25),
    text        = Color(200, 200, 200, 255),
    textBlood   = Color(180, 40, 35, 255),
    separator   = Color(255, 255, 255, 12),
}

local shakeStrength = 0.6

local bloodDrips = {}
local function InitBloodDrips(w, h)
    bloodDrips = {}
    for i = 1, math.random(3, 5) do
        bloodDrips[i] = {
            x = math.random(0, w),
            w = math.random(1, 2),
            h = math.random(ScreenScaleH(6), ScreenScaleH(25)),
            alpha = math.random(6, 18),
            speed = math.Rand(0.15, 0.6),
            offset = math.Rand(0, math.pi * 2),
        }
    end
end

local function PaintMedalFrame(self, w, h)
    surface.SetDrawColor(col.frameBG)
    surface.DrawRect(0, 0, w, h)

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

    local t = CurTime()
    local sX = math.sin(t * 28) * shakeStrength * 0.2
    for _, drip in ipairs(bloodDrips) do
        local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
        local a = math.floor(drip.alpha * pulse)
        surface.SetDrawColor(100, 15, 12, a)
        surface.DrawRect(drip.x + sX, 0, drip.w, drip.h)
    end

    if math.random() > 0.985 then
        local glitchY = math.random(0, h)
        surface.SetDrawColor(255, 255, 255, math.random(5, 18))
        surface.DrawRect(0, glitchY, w, math.random(1, 3))
    end

    surface.SetDrawColor(col.frameBorder)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function EXP.Menu(ply)
    if IsValid(EXP.OpenedMenu) then
        EXP.OpenedMenu:Remove()
        EXP.OpenedMenu = nil
    end

    if not IsValid(ply) then return end

    EXP.OpenedMenu = vgui.Create("ZFrame")
    EXP.OpenedMenu:SetSize(ScrW() * 0.2, ScrH() * 0.5)
    EXP.OpenedMenu:Center()
    EXP.OpenedMenu:MakePopup()
    EXP.OpenedMenu:SetTitle("")
    EXP.OpenedMenu:ShowCloseButton(false)

    if EXP.OpenedMenu.SetColorBG then EXP.OpenedMenu:SetColorBG(col.frameBG) end
    if EXP.OpenedMenu.SetColorBR then EXP.OpenedMenu:SetColorBR(col.frameBorder) end

    EXP.OpenedMenu:SetAlpha(0)
    EXP.OpenedMenu:AlphaTo(255, 0.15, 0)

    InitBloodDrips(EXP.OpenedMenu:GetWide(), EXP.OpenedMenu:GetTall())

    local closeBtn = vgui.Create("DButton", EXP.OpenedMenu)
    closeBtn:SetSize(ScreenScale(12), ScreenScale(12))
    closeBtn:SetPos(EXP.OpenedMenu:GetWide() - ScreenScale(12) - 4, 4)
    closeBtn:SetText("")
    closeBtn:SetCursor("hand")
    closeBtn.Paint = function(btn, bw, bh)
        local t = CurTime()
        local wX = math.sin(t * 28 + 50) * shakeStrength * 0.2
        local wY = math.cos(t * 24 + 50) * shakeStrength * 0.15
        local hovered = btn:IsHovered()
        local tc = hovered and Color(255, 255, 255, 255) or Color(160, 160, 165, 180)
        draw.SimpleText("✕", "ZCity_Veteran", bw * 0.5 + wX, bh * 0.5 + wY, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if hovered then
            surface.SetDrawColor(180, 40, 35, 120)
            surface.DrawRect(2, bh - 2, bw - 4, 1)
        end
    end
    closeBtn.DoClick = function()
        if IsValid(EXP.OpenedMenu) then
            EXP.OpenedMenu:AlphaTo(0, 0.1, 0, function(_, pnl)
                if IsValid(pnl) then pnl:Remove() end
            end)
            EXP.OpenedMenu = nil
        end
    end

    local titlePanel = vgui.Create("DPanel", EXP.OpenedMenu)
    titlePanel:Dock(TOP)
    titlePanel:SetTall(ScreenScaleH(22))
    titlePanel.Paint = function(_, tw, th)
        local t = CurTime()
        local wX = math.sin(t * 28 + 7) * shakeStrength * 0.25
        local wY = math.cos(t * 24 + 7) * shakeStrength * 0.2
        local pulse = math.sin(t * 1.5) * 0.12 + 0.88
        draw.SimpleText("МЕДАЛЬ", "ZCity_Veteran", tw * 0.5 + wX, th * 0.5 + wY,
            Color(col.textBlood.r * pulse, col.textBlood.g * pulse, col.textBlood.b * pulse, 255),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(col.separator)
        surface.DrawRect(ScreenScale(2), th - 1, tw - ScreenScale(4), 1)
    end

    local ExpPanel = vgui.Create("ZB_ExpPanel", EXP.OpenedMenu)
    ExpPanel:Dock(FILL)
    ExpPanel:DockMargin(ScreenScale(2), 0, ScreenScale(2), ScreenScale(2))
    ExpPanel:SetPlayer(ply)
    EXP.OpenedMenu.Medal = ExpPanel

    function EXP.OpenedMenu:Paint(w, h)
        PaintMedalFrame(self, w, h)
    end
end

function EXP.OpenMenu(ply)
    if not IsValid(ply) then return end
    net.Start("zb_xp_get")
    net.WriteEntity(ply)
    net.SendToServer()
end

EXP.OpenedAccount = EXP.OpenedAccount or nil
local needCallback = false

net.Receive("zb_xp_get", function()
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    ply.skill = net.ReadFloat()
    ply.exp = net.ReadInt(19)

    if needCallback then
        if IsValid(EXP.OpenedAccount) then
            EXP.OpenedAccount:Remove()
            EXP.OpenedAccount = nil
        end

        EXP.OpenedAccount = vgui.Create("ZB_AccountFrame")
        local AcMenu = EXP.OpenedAccount
        AcMenu:MakePopup()
        AcMenu:SetPlayer(ply)
        AcMenu:SetTitle("")
        needCallback = false
    end
end)

function EXP.AccountMenu(ply)
    if not IsValid(ply) then return end
    needCallback = true
    EXP.OpenMenu(ply)
end