local keyHeld = false
local emitter
local nextPissPart = 0

-- Настройки системы мочевого пузыря
local maxBladder = 100
local bladder = maxBladder
local depletionRate = 20  -- Сколько единиц тратится в секунду
local regenRate = 10      -- Скорость восстановления в секунду

-- Настройки цензуры
local pixelSize = 14       -- Размер одного пикселя (крупные кубики)
local censorRadius = 32   -- Радиус квадрата мозаики (область покрытия)

local function spawnPissParticle(emitter, pos, vel, dieTime)
    local part = emitter:Add("particle/water/waterdrop_001a", pos)
    if not part then return end
    part:SetVelocity(vel)
    part:SetDieTime(dieTime)
    part:SetStartAlpha(180)
    part:SetEndAlpha(0)
    part:SetStartSize(math.Rand(1.5, 3))
    part:SetEndSize(math.Rand(3, 5))
    part:SetColor(255, 220, 0)
    part:SetGravity(Vector(0, 0, -500))
    part:SetCollide(true)
    part:SetBounce(0)
    part:SetCollideCallback(function(prt, hitpos, hitnormal)
        if math.random(1, 4) == 1 then
            util.Decal("YellowBlood", hitpos + hitnormal * 5, hitpos - hitnormal * 5)
        end
        prt:SetVelocity(Vector(0, 0, -70))
        prt:SetGravity(Vector(0, 0, -50))
        prt:SetCollideCallback(function() end)
    end)
end

net.Receive("piss_particles", function()
    local startPos = net.ReadVector()
    local dir = net.ReadVector()
    local hitPos = net.ReadVector()
    local hit = net.ReadBool()

    local emitter = ParticleEmitter(startPos)
    if not emitter then return end

    local streamLen = startPos:Distance(hitPos)
    local numParticles = math.max(math.floor(streamLen / 20), 4) 

    for _ = 1, math.min(numParticles, 8) do
        local frac = math.Rand(0, 1)
        local ppos = startPos + dir * streamLen * frac
        spawnPissParticle(emitter, ppos, dir * 300 + VectorRand() * 15, math.Rand(1, 1.5))
    end

    if hit then
        for _ = 1, 2 do
            local splatPos = hitPos + VectorRand() * math.Rand(2, 6)
            local splatVel = (hitPos - startPos):GetNormalized() * math.Rand(50, 150) + VectorRand() * 30
            splatVel.z = math.Rand(20, 60)
            spawnPissParticle(emitter, splatPos, splatVel, math.Rand(0.3, 0.6))
        end
    end

    emitter:Finish()
end)

local function localPissFx(ply)
    if not IsValid(ply) then return end
    emitter = emitter or ParticleEmitter(ply:GetPos())
    local spawnPos = ply:EyePos() - Vector(0, 0, 30) + ply:GetAimVector() * 10
    emitter:SetPos(spawnPos)
    spawnPissParticle(emitter, spawnPos, ply:GetAimVector() * 300 + VectorRand() * 15, math.Rand(1, 1.5))
end

hook.Add("Think", "hg_piss_fx", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:GetNWBool("peeing") then
        if emitter then
            emitter:Finish()
            emitter = nil
        end
        bladder = math.min(maxBladder, bladder + regenRate * FrameTime())
        return
    end

    bladder = math.max(0, bladder - depletionRate * FrameTime())

    if CurTime() >= nextPissPart then
        localPissFx(ply)
        nextPissPart = CurTime() + 0.04
    end
end)

hook.Add("CreateMove", "hg_piss_key", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        if keyHeld then
            keyHeld = false
            net.Start("hg_piss")
            net.WriteBool(false)
            net.SendToServer()
        end
        return
    end

    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    local down = input.IsKeyDown(KEY_P)
    if down and bladder < 15 then down = false end
    if down == keyHeld then return end

    keyHeld = down
    net.Start("hg_piss")
    net.WriteBool(down)
    net.SendToServer()
end)

-- Общая функция генерации серой мозаики
local function drawCensorGrid(screenPos)
    local centerX = math.floor(screenPos.x / pixelSize) * pixelSize
    local centerY = math.floor(screenPos.y / pixelSize) * pixelSize
    local steps = math.floor(censorRadius / pixelSize)

    for x = -steps, steps do
        for y = -steps, steps do
            local drawX = centerX + (x * pixelSize)
            local drawY = centerY + (y * pixelSize)

            -- Цифровой шум
            math.randomseed(drawX * 5 + drawY * 7 + math.floor(CurTime() * 15))
            local gray = math.random(110, 150)

            surface.SetDrawColor(gray, gray, gray, 255)
            surface.DrawRect(drawX, drawY, pixelSize, pixelSize)
        end
    end
end

-- 1. Цензура для ДРУГИХ игроков (вид со стороны)
hook.Add("PostPlayerDraw", "hg_piss_pixel_censorship", function(ply)
    if not IsValid(ply) or not ply:GetNWBool("peeing") then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    local ent = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
    if not IsValid(ent) then ent = ply end
    
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return end
    
    -- Берем чистую позицию кости без учета её вращения
    local bonePos = ent:GetBonePosition(bone)
    if not bonePos then return end
    
    -- Смещаем строго по направлению тела игрока вперед и чуть-чуть вниз
    local worldPos = bonePos + ply:GetForward() * 6 - Vector(0, 0, 4)
    local screenPos = worldPos:ToScreen()

    if not screenPos.visible then return end

    cam.Start2D()
        drawCensorGrid(screenPos)
    cam.End2D()
end)

-- 2. Цензура для СЕБЯ от первого лица (когда смотришь вниз)
hook.Add("HUDPaint", "hg_piss_pixel_censorship_fp", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNWBool("peeing") then return end
    if ply:ShouldDrawLocalPlayer() then return end 

    -- Считаем точку паха от базового центра модели (GetPos), а не от глаз.
    -- Это гарантирует, что пиксели останутся на теле, даже если ты смотришь вверх или вбок.
    local bodyPos = ply:GetPos() + ply:GetForward() * 7 + Vector(0, 0, 34)
    local screenPos = bodyPos:ToScreen()

    if not screenPos.visible then return end

    drawCensorGrid(screenPos)
end)