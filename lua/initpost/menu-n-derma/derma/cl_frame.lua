local PANEL = {}

local THEME = {
    bg_deep = Color(8, 8, 10, 250),
    bg_overlay = Color(15, 12, 12, 240),
    blood_dark = Color(80, 10, 10, 180),
    blood_light = Color(120, 20, 15, 100),
    dirty_white = Color(200, 195, 190, 255),
    static_color = Color(255, 255, 255, 30),
    vignette = Color(0, 0, 0, 150),
    scratch_color = Color(40, 35, 35, 80)
}

local horrorParticles = {}
local staticNoise = {}
local scratches = {}
local bloodSplatters = {}
local glitchIntensity = 0
local vignetteFlicker = 0
local filmGrain = 0

local function LerpFT(scale, from, to)
    return Lerp(FrameTime() * scale, from, to)
end

local function InitHorrorEffects()
    horrorParticles = {}
    for i = 1, 60 do
        table.insert(horrorParticles, {
            x = math.random(0, 100),
            y = math.random(0, 100),
            speed = math.random(2, 8) / 100,
            size = math.random(1, 2),
            alpha = math.random(10, 40),
            sway = math.random(-50, 50) / 100
        })
    end
    
    scratches = {}
    for i = 1, 15 do
        table.insert(scratches, {
            x = math.random(0, 100),
            y = math.random(0, 100),
            length = math.random(50, 200),
            angle = math.random(0, 360),
            thickness = math.random(1, 3),
            alpha = math.random(20, 60)
        })
    end
    
    bloodSplatters = {}
    for i = 1, 8 do
        table.insert(bloodSplatters, {
            x = math.random(0, 100),
            y = math.random(0, 100),
            radius = math.random(10, 40),
            alpha = math.random(30, 80),
            drips = {}
        })
        
        for j = 1, math.random(2, 5) do
            table.insert(bloodSplatters[i].drips, {
                offsetX = math.random(-10, 10),
                length = math.random(20, 60),
                width = math.random(1, 3)
            })
        end
    end
end

local function DrawStaticNoise(x, y, w, h, intensity)
    surface.SetDrawColor(255, 255, 255, intensity)
    for i = 1, math.ceil(w * h / 800) do
        local px = x + math.random(0, w)
        local py = y + math.random(0, h)
        local size = math.random(1, 3)
        surface.DrawRect(px, py, size, size)
    end
end

local function DrawScratches(x, y, w, h, scratches)
    for _, scratch in ipairs(scratches) do
        local sx = x + (scratch.x / 100) * w
        local sy = y + (scratch.y / 100) * h
        local endX = sx + math.cos(math.rad(scratch.angle)) * scratch.length
        local endY = sy + math.sin(math.rad(scratch.angle)) * scratch.length
        
        surface.SetDrawColor(THEME.scratch_color.r, THEME.scratch_color.g, THEME.scratch_color.b, scratch.alpha)
        for i = 0, scratch.thickness do
            surface.DrawLine(sx + i, sy, endX + i, endY)
        end
    end
end

local function DrawBloodSplatters(x, y, w, h, splatters)
    for _, splatter in ipairs(splatters) do
        local cx = x + (splatter.x / 100) * w
        local cy = y + (splatter.y / 100) * h
        
        draw.NoTexture()
        surface.SetDrawColor(THEME.blood_dark.r, THEME.blood_dark.g, THEME.blood_dark.b, splatter.alpha)
        
        local segments = 20
        for i = 0, segments do
            local angle1 = (i / segments) * math.pi * 2
            local angle2 = ((i + 1) / segments) * math.pi * 2
            local r = splatter.radius * (0.8 + math.random() * 0.4)
            
            surface.DrawPoly({
                {x = cx, y = cy},
                {x = cx + math.cos(angle1) * r, y = cy + math.sin(angle1) * r},
                {x = cx + math.cos(angle2) * r, y = cy + math.sin(angle2) * r}
            })
        end
        
        for _, drip in ipairs(splatter.drips) do
            local dx = cx + drip.offsetX
            surface.SetDrawColor(THEME.blood_dark.r, THEME.blood_dark.g, THEME.blood_dark.b, splatter.alpha * 0.8)
            surface.DrawRect(dx, cy, drip.width, drip.length)
        end
    end
end

local function DrawVignette(x, y, w, h, intensity)
    local steps = 8
    for i = 1, steps do
        local offset = (i / steps) * (w * 0.2)
        local alpha = (i / steps) * intensity
        surface.SetDrawColor(0, 0, 0, alpha)
        surface.DrawOutlinedRect(x + offset, y + offset, w - offset * 2, h - offset * 2, offset)
    end
end

function PANEL:Init()
    self.Itensens = {}
    self:SetAlpha(0)
    self:SetTitle("")
    self:ShowCloseButton(false)

    self.DrawBorder = true
    self.BorderRadius = 0

    self.ColorBG = Color(THEME.bg_deep.r, THEME.bg_deep.g, THEME.bg_deep.b, THEME.bg_deep.a)
    self.ColorBR = Color(THEME.blood_dark.r, THEME.blood_dark.g, THEME.blood_dark.b)
    self.BlurStrengh = 3

    self.AnimAlpha = 0
    self.TargetAlpha = 1
    self.StartTime = SysTime()
    self.Shake = {x = 0, y = 0}

    InitHorrorEffects()

    timer.Simple(0, function()
        if IsValid(self) then
            self:First()
            self:CreateHorrorCloseButton()
        end
    end)
end

function PANEL:Paint(w, h)
    local ct = SysTime()
    
    self.AnimAlpha = LerpFT(3, self.AnimAlpha, self.TargetAlpha)
    
    if math.random() > 0.98 then
        self.Shake.x = math.random(-3, 3)
        self.Shake.y = math.random(-3, 3)
    else
        self.Shake.x = LerpFT(10, self.Shake.x, 0)
        self.Shake.y = LerpFT(10, self.Shake.y, 0)
    end
    
    local offsetX = self.Shake.x
    local offsetY = self.Shake.y

    draw.RoundedBox(0, offsetX, offsetY, w, h, self.ColorBG)
    
    surface.SetDrawColor(THEME.bg_overlay.r, THEME.bg_overlay.g, THEME.bg_overlay.b, THEME.bg_overlay.a * self.AnimAlpha)
    surface.DrawRect(offsetX, offsetY, w, h)
    
    if self.BlurStrengh > 0 then
        hg.DrawBlur(self, self.BlurStrengh * self.AnimAlpha)
    end
    
    DrawBloodSplatters(offsetX, offsetY, w, h, bloodSplatters)
    DrawScratches(offsetX, offsetY, w, h, scratches)
    
    for _, particle in ipairs(horrorParticles) do
        particle.y = particle.y + particle.speed
        particle.x = particle.x + particle.sway * math.sin(ct * 2 + particle.y)
        
        if particle.y > 100 then 
            particle.y = 0
            particle.x = math.random(0, 100)
        end
        
        local px = offsetX + (particle.x / 100) * w
        local py = offsetY + (particle.y / 100) * h
        
        surface.SetDrawColor(THEME.dirty_white.r, THEME.dirty_white.g, THEME.dirty_white.b, particle.alpha * self.AnimAlpha)
        surface.DrawRect(px, py, particle.size, particle.size)
    end
    
    if math.random() > 0.95 then
        glitchIntensity = math.random(10, 40)
    else
        glitchIntensity = LerpFT(20, glitchIntensity, 0)
    end
    
    if glitchIntensity > 0 then
        DrawStaticNoise(offsetX, offsetY, w, h, glitchIntensity * self.AnimAlpha)
    end
    
    filmGrain = math.random(5, 15)
    DrawStaticNoise(offsetX, offsetY, w, h, filmGrain * self.AnimAlpha)
    
    if math.random() > 0.97 then
        vignetteFlicker = math.random(100, 180)
    else
        vignetteFlicker = LerpFT(5, vignetteFlicker, 120)
    end
    DrawVignette(offsetX, offsetY, w, h, vignetteFlicker * self.AnimAlpha)
    
    if self.DrawBorder then
        surface.SetDrawColor(self.ColorBR.r, self.ColorBR.g, self.ColorBR.b, 200 * self.AnimAlpha)
        
        for i = 0, w, 20 do
            if math.random() > 0.3 then
                local len = math.random(10, 25)
                surface.DrawRect(offsetX + i, offsetY, len, 2)
            end
        end
        
        for i = 0, w, 20 do
            if math.random() > 0.3 then
                local len = math.random(10, 25)
                surface.DrawRect(offsetX + i, offsetY + h - 2, len, 2)
            end
        end
        
        for i = 0, h, 20 do
            if math.random() > 0.3 then
                local len = math.random(10, 25)
                surface.DrawRect(offsetX, offsetY + i, 2, len)
            end
        end
        
        for i = 0, h, 20 do
            if math.random() > 0.3 then
                local len = math.random(10, 25)
                surface.DrawRect(offsetX + w - 2, offsetY + i, 2, len)
            end
        end
    end
    
    if math.random() > 0.985 then
        local glitchHeight = math.random(2, 8)
        local glitchY = math.random(0, h - glitchHeight)
        surface.SetDrawColor(self.ColorBR.r, self.ColorBR.g, self.ColorBR.b, 150 * self.AnimAlpha)
        surface.DrawRect(offsetX, offsetY + glitchY, w, glitchHeight)
        
        surface.SetDrawColor(255, 0, 0, 80 * self.AnimAlpha)
        surface.DrawRect(offsetX - 3, offsetY + glitchY, w, glitchHeight)
        surface.SetDrawColor(0, 255, 255, 80 * self.AnimAlpha)
        surface.DrawRect(offsetX + 3, offsetY + glitchY, w, glitchHeight)
    end
end

function PANEL:SetBorder(bDraw)
    self.DrawBorder = bDraw
end

function PANEL:SetColorBG(cColor)
    self.ColorBG = cColor
end

function PANEL:SetColorBR(cColor)
    self.ColorBR = cColor
end

function PANEL:SetBlurStrengh(floatVal)
    self.BlurStrengh = floatVal
end

function PANEL:CreateHorrorCloseButton()
    self.CloseBtn = vgui.Create("DButton", self)
    self.CloseBtn:SetSize(32, 32)
    self.CloseBtn:SetPos(self:GetWide() - 40, 8)
    self.CloseBtn:SetText("")
    

    local closeWimg = wimg.Simple("https://i.ibb.co.com/Wv16J1Vk/close.png", "smooth")
    
    self.CloseBtn.NormalColor = Color(200, 195, 190, 200)
    self.CloseBtn.HoverColor = Color(120, 20, 15, 255)
    self.CloseBtn.CurrentColor = Color(200, 195, 190, 200)
    self.CloseBtn.HoverLerp = 0
    self.CloseBtn.ScaleLerp = 0
    self.CloseBtn.Glitch = 0
    
    self.CloseBtn.Think = function(btn)
        if IsValid(self) then
            btn:SetPos(self:GetWide() - 40, 8)
        end
        
        local target = btn:IsHovered() and 1 or 0
        btn.HoverLerp = LerpFT(8, btn.HoverLerp, target)
        btn.ScaleLerp = LerpFT(8, btn.ScaleLerp, target)
        
        if math.random() > 0.95 then
            btn.Glitch = 0.8
        else
            btn.Glitch = LerpFT(15, btn.Glitch, 0)
        end
        
        btn.CurrentColor = Color(
            Lerp(btn.HoverLerp, btn.NormalColor.r, btn.HoverColor.r),
            Lerp(btn.HoverLerp, btn.NormalColor.g, btn.HoverColor.g),
            Lerp(btn.HoverLerp, btn.NormalColor.b, btn.HoverColor.b),
            Lerp(btn.HoverLerp, btn.NormalColor.a, btn.HoverColor.a)
        )
    end
    
    self.CloseBtn.Paint = function(btn, w, h)
        local centerX, centerY = w / 2, h / 2
        
        local shakeX = btn.HoverLerp > 0 and math.random(-2, 2) * btn.HoverLerp or 0
        local shakeY = btn.HoverLerp > 0 and math.random(-2, 2) * btn.HoverLerp or 0
        
        local hoverScale = Lerp(btn.ScaleLerp, 1, 1.1)
        local iconSize = 24 * hoverScale
        local iconX = centerX - iconSize / 2 + shakeX
        local iconY = centerY - iconSize / 2 + shakeY
        
        closeWimg:Draw(iconX, iconY, iconSize, iconSize, btn.CurrentColor)
        
        if btn.HoverLerp > 0 then
        closeWimg:Draw(iconX - 8, iconY - 8, iconSize + 16, iconSize + 16, Color(btn.HoverColor.r, btn.HoverColor.g, btn.HoverColor.b, 40 * btn.HoverLerp))
        end
        
        if btn.Glitch > 0 then
        closeWimg:Draw(iconX + 2, iconY, iconSize, iconSize, Color(255, 255, 255, 100 * btn.Glitch))
        end
    end
    
    self.CloseBtn.DoClick = function()
        self:Close()
    end
end

function PANEL:First()
    self.AnimAlpha = 0
    self.TargetAlpha = 1
    self.StartTime = SysTime()
    
    self:AlphaTo(255, 0.5, 0, nil)

    if self.PostInit then
        self:PostInit()
    end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    
    self.TargetAlpha = 0
    
    for i = 1, 5 do
        timer.Simple(i * 0.05, function()
            if IsValid(self) then
                glitchIntensity = 100
            end
        end)
    end
    
    self:AlphaTo(0, 0.5, 0, function()
        if IsValid(self) then
            if self.OnClose then 
                self:OnClose() 
            end
            self:Remove()
        end
    end)
    
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register("ZFrame", PANEL, "DFrame")

local PANEL = {}

local THEME = {
    bg_normal = Color(15, 12, 12, 240),
    bg_hover = Color(25, 20, 20, 250),
    blood = Color(120, 20, 15),
    text = Color(200, 195, 190, 255),
    static = Color(255, 255, 255)
}

local function LerpFT(scale, from, to)
    return Lerp(FrameTime() * scale, from, to)
end

local function DrawDirtyCorners(x, y, w, h, color, size)
    surface.SetDrawColor(color)
    
    for corner = 1, 4 do
        local cx, cy
        local dirX, dirY
        
        if corner == 1 then
            cx, cy = x, y
            dirX, dirY = 1, 1
        elseif corner == 2 then
            cx, cy = x + w, y
            dirX, dirY = -1, 1
        elseif corner == 3 then
            cx, cy = x, y + h
            dirX, dirY = 1, -1
        else
            cx, cy = x + w, y + h
            dirX, dirY = -1, -1
        end
        
        for i = 0, size, 3 do
            if math.random() > 0.3 then
                surface.DrawRect(cx + dirX * i, cy, math.random(2, 5) * dirX, 2)
                surface.DrawRect(cx, cy + dirY * i, 2, math.random(2, 5) * dirY)
            end
        end
    end
end

function PANEL:Init()
    self:SetText("")
    self:SetSize(200, 50)
    
    self.HoverLerp = 0
    self.PressLerp = 0
    self.StaticNoise = 0
    self.Distortion = 0
    
    self.ButtonText = ""
    self.TextFont = "DermaDefault"
    self.AccentColor = Color(THEME.blood.r, THEME.blood.g, THEME.blood.b)
    self.TextColor = Color(THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a)
    self.CornerSize = 12
    
    self.BlurStrength = 3
end

function PANEL:Think()
    local isHovered = self:IsHovered()
    local isPressed = self:IsDown()
    
    self.HoverLerp = LerpFT(6, self.HoverLerp, isHovered and 1 or 0)
    self.PressLerp = LerpFT(15, self.PressLerp, isPressed and 1 or 0)
    
    if math.random() > 0.95 then
        self.StaticNoise = math.random(10, 30)
    else
        self.StaticNoise = LerpFT(20, self.StaticNoise, 0)
    end
    
    if isHovered and math.random() > 0.9 then
        self.Distortion = math.random(1, 3)
    else
        self.Distortion = LerpFT(10, self.Distortion, 0)
    end
end

function PANEL:Paint(w, h)
    local distortX = math.random(-self.Distortion, self.Distortion)
    local distortY = math.random(-self.Distortion, self.Distortion)
    
    if self.BlurStrength > 0 then
        hg.DrawBlur(self, self.BlurStrength)
    end
    
    local bgColor = Color(
        Lerp(self.HoverLerp, THEME.bg_normal.r, THEME.bg_hover.r),
        Lerp(self.HoverLerp, THEME.bg_normal.g, THEME.bg_hover.g),
        Lerp(self.HoverLerp, THEME.bg_normal.b, THEME.bg_hover.b),
        Lerp(self.HoverLerp, THEME.bg_normal.a, THEME.bg_hover.a)
    )
    
    draw.RoundedBox(0, distortX, distortY, w, h, bgColor)
    
    surface.SetDrawColor(0, 0, 0, 30)
    for i = 1, 50 do
        surface.DrawRect(math.random(0, w), math.random(0, h), math.random(1, 3), 1)
    end
    
    local bloodLineHeight = 3
    local bloodAlpha = 80 + self.HoverLerp * 120
    surface.SetDrawColor(self.AccentColor.r, self.AccentColor.g, self.AccentColor.b, bloodAlpha)
    
    for i = 0, w, 5 do
        if math.random() > 0.2 then
            local lineHeight = bloodLineHeight + math.random(-1, 2)
            surface.DrawRect(i, h - lineHeight, 5, lineHeight)
        end
    end
    
    if self.HoverLerp > 0 then
        for i = 1, 8 do
            local x = math.random(0, w)
            local dripLength = math.random(10, 25) * self.HoverLerp
            surface.SetDrawColor(self.AccentColor.r, self.AccentColor.g, self.AccentColor.b, 60 * self.HoverLerp)
            surface.DrawRect(x, h - bloodLineHeight, 2, -dripLength)
        end
    end
    
    DrawDirtyCorners(0, 0, w, h, 
        Color(self.AccentColor.r, self.AccentColor.g, self.AccentColor.b, 100 + self.HoverLerp * 100), 
        self.CornerSize)
    
    if self.StaticNoise > 0 then
        surface.SetDrawColor(255, 255, 255, self.StaticNoise)
        for i = 1, 20 do
            surface.DrawRect(math.random(0, w), math.random(0, h), math.random(1, 2), math.random(1, 2))
        end
    end
    
    surface.SetFont(self.TextFont)
    local textW, textH = surface.GetTextSize(self.ButtonText)
    local textX = (w - textW) / 2
    local textY = (h - textH) / 2
    
    if self.HoverLerp > 0 then
        textX = textX + math.random(-2, 2) * self.HoverLerp
        textY = textY + math.random(-1, 1) * self.HoverLerp
    end
    
    for i = 1, 3 do
        draw.SimpleText(self.ButtonText, self.TextFont, textX + i, textY + i, 
            Color(0, 0, 0, 100 - i * 30))
    end
    
    local textAlpha = 200 + self.HoverLerp * 55
    draw.SimpleText(self.ButtonText, self.TextFont, textX, textY, 
        Color(self.TextColor.r, self.TextColor.g, self.TextColor.b, textAlpha))
    
    if self.HoverLerp > 0 and math.random() > 0.9 then
        draw.SimpleText(self.ButtonText, self.TextFont, textX - 2, textY, 
            Color(255, 0, 0, 100 * self.HoverLerp))
        draw.SimpleText(self.ButtonText, self.TextFont, textX + 2, textY, 
            Color(0, 255, 255, 100 * self.HoverLerp))
    end
    
    if self.PressLerp > 0 then
        surface.SetDrawColor(0, 0, 0, 60 * self.PressLerp)
        surface.DrawRect(0, 0, w, h)
    end
    
    if math.random() > 0.97 then
        surface.SetDrawColor(80, 75, 75, 40)
        surface.DrawLine(0, math.random(0, h), w, math.random(0, h))
    end
end

function PANEL:SetButtonText(text)
    self.ButtonText = text or "BUTTON"
end

function PANEL:SetTextFont(font)
    self.TextFont = font or "DermaDefault"
end

function PANEL:SetAccentColor(color)
    self.AccentColor = color
end

function PANEL:SetTextColor(color)
    self.TextColor = color
end

function PANEL:SetCornerSize(size)
    self.CornerSize = size or 12
end

function PANEL:SetBlurStrength(strength)
    self.BlurStrength = strength or 3
end

function PANEL:SetStyle(styleName)
    if styleName == "blood" then
        self.AccentColor = Color(120, 20, 15)
    elseif styleName == "decay" then
        self.AccentColor = Color(60, 80, 50)
    elseif styleName == "ash" then
        self.AccentColor = Color(100, 100, 100)
    elseif styleName == "rust" then
        self.AccentColor = Color(140, 70, 40)
    elseif styleName == "void" then
        self.AccentColor = Color(20, 10, 30)
    end
end

vgui.Register("ZButton", PANEL, "DButton")