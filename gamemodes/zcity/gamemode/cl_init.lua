-- cl_init.lua
zb = zb or {}
include("shared.lua")
include("loader.lua")
if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Плавное движение в наблюдателях между игроками", 0, 1)
end

function CurrentRound()
    local name = zb.CROUND
    if not name or name == "" then return end
    local main = zb.GetMode and zb:GetMode(name) or name
    return zb.modes[main or name]
end

zb.ROUND_STATE = 0

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime", function()
    local time = net.ReadFloat()
    local time2 = net.ReadFloat()
    local time3 = net.ReadFloat()

    zb.ROUND_TIME = time
    zb.ROUND_START = time2
    zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
    if is3d2d then return end
    amount = amount or 5
    hg_potatopc = hg_potatopc or hg.ConVars.potatopc

    if hg_potatopc:GetBool() then
        surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    else
        surface.SetMaterial(blur)
        surface.SetDrawColor(0, 0, 0, alpha or 125)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
        local x, y = panel:LocalToScreen(0, 0)
        if blursettings and blursettings[1] == amount and blursettings[2] == passes then
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
            return
        end
        blursettings = {amount, passes}
        for i = -(passes or 0.2), 1, 0.2 do
            blur:SetFloat("$blur", i * amount)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        end
    end
end

BlurBackground = BlurBackground or hg.DrawBlur

zb.fade = zb.fade or 0
hook.Add("RenderScreenspaceEffects", "zb_fade", function()
    if zb.fade > 0 then
        zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)
        surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
        surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
    end
end)

zb.ROUND_STATE = 0

local function zbClientModeCleanup(rnd)
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply.isTraitor = false
        ply.isGunner = false
        ply.MainTraitor = false
        ply.HMCD_TraitorWord = nil
        ply.HMCD_TraitorWordSecond = nil
    end
    gui.EnableScreenClicker(false)
    if IsValid(TDM_OpenedBuyMenu) then
        TDM_OpenedBuyMenu:Remove()
        TDM_OpenedBuyMenu = nil
    end
    hook.Run("zbClientModeCleanup", rnd)
end

net.Receive("RoundInfo", function()
    local rnd = net.ReadString()
    local prev = zb.CROUND

    hook.Run("RoundInfoCalled", rnd)

    if prev and prev ~= rnd then
        zbClientModeCleanup(rnd)
    end

    if zb.CROUND ~= rnd then
        if hg.DynaMusic then
            hg.DynaMusic:Stop()
        end
    end

    zb.CROUND = rnd
    zb.CROUND_MAIN = zb:GetMode(rnd) or rnd

    zb.ROUND_STATE = net.ReadInt(4)

    if zb.ROUND_STATE == 0 then
        zb.fade = 7
        zbClientModeCleanup(rnd)
    end

    if zb.CROUND ~= "" then
        if CurrentRound() and zb.ROUND_STATE == 3 then
            if CurrentRound().EndRound then
                CurrentRound():EndRound()
            end
        elseif zb.ROUND_STATE == 1 then
            local mode = CurrentRound()
            if mode and mode.RoundStart then
                mode:RoundStart()
            end
        end
    end
end)

if IsValid(scoreBoardMenu) then
    scoreBoardMenu:Remove()
    scoreBoardMenu = nil
end

hook.Add("Player Disconnected", "retrymenu", function(data)
    if IsValid(scoreBoardMenu) then
        scoreBoardMenu:Remove()
        scoreBoardMenu = nil
    end
end)

local function ZB_CreateUIFonts()
    CreateFontFamily({ antialias = true }, {
        ZB_InterfaceSmall       = { size = ScreenScaleH(11) },
        ZB_InterfaceMedium      = { size = ScreenScaleH(13) },
        ZB_ScrappersMedium      = { size = ScreenScaleH(13) },
        ZB_InterfaceMediumLarge = { size = 35 },
        ZB_InterfaceLarge       = { size = ScreenScaleH(22) },
        ZB_InterfaceHumongous   = { size = 200 },
        ZB_ScoreboardHeader     = { size = ScreenScaleH(12), weight = 600 },
    })
end
ZB_CreateUIFonts()

-- свет от молнии
if CLIENT then
    net.Receive("PunishLightningEffect", function()
        local target = net.ReadEntity()
        if not IsValid(target) then return end
        local dlight = DynamicLight(target:EntIndex())
        if dlight then
            dlight.pos = target:GetPos()
            dlight.r = 126
            dlight.g = 139
            dlight.b = 212
            dlight.brightness = 1
            dlight.Decay = 1000
            dlight.Size = 500
            dlight.DieTime = CurTime() + 1
        end
    end)
end

local lightningMaterial = Material("sprites/lgtning")
net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
    if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20), math.Rand(-20,20), math.Rand(-20,20))
    end
    hook.Add("PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend(false)
    end)
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint(name, delay)
    return false
end

local snakeGameOpen = false
concommand.Add("zb_snake", function()
    if snakeGameOpen then
        print("[Snake Game] Игра уже запущена!")
        return
    end
    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    snakeGameOpen = true

    local gridSize = 20
    local gridWidth = 19
    local gridHeight = 19
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = { {x = 10, y = 10} }
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = { x = math.random(0, gridWidth - 1), y = math.random(0, gridHeight - 1) }
            validPosition = true
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false
                    break
                end
            end
            if validPosition then food = newFood end
        end
    end

    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

    local function moveSnake()
        if not gameRunning then return end
        local head = table.Copy(snake[1])
        if snakeDirection == "UP" then head.y = head.y - 1
        elseif snakeDirection == "DOWN" then head.y = head.y + 1
        elseif snakeDirection == "LEFT" then head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then head.x = head.x + 1
        end

        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then gameRunning = false end
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then gameRunning = false end
        end

        table.insert(snake, 1, head)
        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()
        else
            table.remove(snake)
        end
    end

    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()
    end

    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)
        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    function frame:OnKeyCodePressed(key)
        if key == KEY_W and snakeDirection ~= "DOWN" then snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then snakeDirection = "RIGHT"
        elseif key == KEY_R then resetGame() end
    end

    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then moveSnake() end
        snakePanel:InvalidateLayout(true)
    end)

    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false
        print("[Snake Game] Игра закрыта.")
    end

    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown", function(ply)
    if ply == LocalPlayer() then system.FlashWindow() end
end)