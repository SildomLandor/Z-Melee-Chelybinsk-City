local holding = false
local holdingPoop = false
local emitter
local poopEmitter
local nextPissPart = 0
local nextPoopPart = 0

-- Таблица для хранения кастомных коричневых пятен на полу
local poopStains = {}

-- Динамическое создание материала в памяти (100% защита от эмо-текстур)
local poopMat = CreateMaterial("hg_poop_puddle_perfect_mat", "UnlitGeneric", {
    ["$basetexture"] = "particle/water/waterdrop_001a", 
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
    ["$translucent"] = "1",
    ["$nocull"] = "1"
})

-- Настройки систем запасов организма
local maxBladder = 100
local bladder = maxBladder
local depletionRate = 20
local regenRate = 10

local maxBowel = 100
local bowel = maxBowel
local poopDepletionRate = 20
local poopRegenRate = 10

-- Настройки серой цензуры (крупные кубики)
local pixelSize = 14       
local censorRadius = 32   

local poopPixelSize = 14
local poopCensorRadius = 35

-- Спавн частиц мочи
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

-- Спавн частиц каках
local function spawnPoopParticle(emitter, pos, vel, dieTime)
    local part = emitter:Add("particle/water/waterdrop_001a", pos)
    if not part then return end
    part:SetVelocity(vel)
    part:SetDieTime(dieTime)
    part:SetStartAlpha(230) 
    part:SetEndAlpha(0)
    part:SetStartSize(math.Rand(5, 8))   -- Слегка увеличили летящие частицы
    part:SetEndSize(math.Rand(8, 12))   -- Чтобы в воздухе тоже выглядело крупнее
    part:SetColor(90, 55, 20) 
    part:SetGravity(Vector(0, 0, -600))
    part:SetCollide(true)
    part:SetBounce(0)
    part:SetCollideCallback(function(prt, hitpos, hitnormal)
        -- Увеличили шанс спавна пятна для большей плотности лужи
        if math.random(1, 2) == 1 then
            local tooClose = false
            for i = 1, #poopStains do
                -- Дистанция уменьшена со 144 до 25 (5 в квадрате), чтобы они ложились кучно в одну точку
                if poopStains[i].pos:DistToSqr(hitpos) < 25 then 
                    tooClose = true
                    break
                end
            end
            
            if not tooClose then
                table.insert(poopStains, {
                    pos = hitpos + hitnormal * 0.2, 
                    normal = hitnormal,
                    size = math.Rand(30, 45), -- Текстуры стали ЖИРНЕЕ (было 16-26)
                    dieTime = CurTime() + 25 
                })
            end
            
            -- Подняли лимит до 200, так как из-за кучности их создается больше
            if #poopStains > 200 then table.remove(poopStains, 1) end
        end
        prt:SetVelocity(Vector(0, 0, -20))
        prt:SetGravity(Vector(0, 0, -10))
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

net.Receive("poop_particles", function()
    local startPos = net.ReadVector()
    local dir = net.ReadVector()
    local hitPos = net.ReadVector()
    local hit = net.ReadBool()

    local emitter = ParticleEmitter(startPos)
    if not emitter then return end

    local streamLen = startPos:Distance(hitPos)
    local numParticles = math.max(math.floor(streamLen / 15), 3)

    for _ = 1, math.min(numParticles, 6) do
        local frac = math.Rand(0, 1)
        local ppos = startPos + dir * streamLen * frac
        spawnPoopParticle(emitter, ppos, dir * 100 + VectorRand() * 10, math.Rand(0.8, 1.2))
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

local function localPoopFx(ply)
    if not IsValid(ply) then return end
    poopEmitter = poopEmitter or ParticleEmitter(ply:GetPos())
    local spawnPos = ply:GetPos() + ply:GetForward() * -8 + Vector(0, 0, 32)
    poopEmitter:SetPos(spawnPos)
    spawnPoopParticle(poopEmitter, spawnPos, -ply:GetForward() * 120 + VectorRand() * 15, math.Rand(0.8, 1.2))
end

hook.Add("Think", "hg_piss_poop_fx", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Моча
    if not ply:GetNWBool("peeing") then
        if emitter then emitter:Finish() emitter = nil end
        bladder = math.min(maxBladder, bladder + regenRate * FrameTime())
    else
        bladder = math.max(0, bladder - depletionRate * FrameTime())
        if bladder <= 0 and holding then
            holding = false
            net.Start("hg_piss")
            net.WriteBool(false)
            net.SendToServer()
        end
        if CurTime() >= nextPissPart then
            localPissFx(ply)
            nextPissPart = CurTime() + 0.04
        end
    end

    -- Каканье
    if not ply:GetNWBool("pooping") then
        if poopEmitter then poopEmitter:Finish() poopEmitter = nil end
        bowel = math.min(maxBowel, bowel + poopRegenRate * FrameTime())
    else
        bowel = math.max(0, bowel - poopDepletionRate * FrameTime())
        if bowel <= 0 and holdingPoop then
            holdingPoop = false
            net.Start("hg_poop")
            net.WriteBool(false)
            net.SendToServer()
        end
        if CurTime() >= nextPoopPart then
            localPoopFx(ply)
            nextPoopPart = CurTime() + 0.05
        end
    end
end)

hook.Add("CreateMove", "hg_piss_key", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        if holding then
            holding = false
            net.Start("hg_piss")
            net.WriteBool(false)
            net.SendToServer()
        end
        return
    end

    if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    local down = input.IsKeyDown(KEY_P)

    if down and not holding and bladder < 15 then
        down = false
    end

    if down == holding then return end
    holding = down

    net.Start("hg_piss")
    net.WriteBool(down)
    net.SendToServer()
end)

-- РЕНДЕРИНГ КОРИЧНЕВЫХ СЛЕДОВ НА ПОЛУ
hook.Add("PostDrawOpaqueRenderables", "hg_draw_poop_stains", function()
    local curTime = CurTime()
    
    render.SetMaterial(poopMat)
    
    for i = #poopStains, 1, -1 do
        local stain = poopStains[i]
        
        if curTime > stain.dieTime then
            table.remove(poopStains, i)
        else
            local alpha = 240
            local timeLeft = stain.dieTime - curTime 
            
            if timeLeft < 5 then
                alpha = (timeLeft / 5) * 240
            end
            
            render.DrawQuadEasy(stain.pos, stain.normal, stain.size, stain.size, Color(70, 40, 15, alpha), 0)
        end
    end
end)

-- Отрисовка серой мозаики цензуры
local function drawCensorGrid(screenPos, size, radius)
    local centerX = math.floor(screenPos.x / size) * size
    local centerY = math.floor(screenPos.y / size) * size
    local steps = math.floor(radius / size)

    for x = -steps, steps do
        for y = -steps, steps do
            local drawX = centerX + (x * size)
            local drawY = centerY + (y * size)

            math.randomseed(drawX * 5 + drawY * 7 + math.floor(CurTime() * 15))
            local gray = math.random(100, 150)

            surface.SetDrawColor(gray, gray, gray, 255)
            surface.DrawRect(drawX, drawY, size, size)
        end
    end
end

-- 1. Цензура МОЧИ (со стороны)
hook.Add("PostPlayerDraw", "hg_piss_pixel_censorship", function(ply)
    if not IsValid(ply) or not ply:GetNWBool("peeing") then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    local ent = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
    if not IsValid(ent) then ent = ply end
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return end
    
    local bonePos = ent:GetBonePosition(bone)
    if not bonePos then return end
    
    local worldPos = bonePos + ply:GetForward() * 6 - Vector(0, 0, 4)
    local screenPos = worldPos:ToScreen()
    if not screenPos.visible then return end

    cam.Start2D() drawCensorGrid(screenPos, pixelSize, censorRadius) cam.End2D()
end)

-- 2. Цензура МОЧИ (1-е лицо)
hook.Add("HUDPaint", "hg_piss_pixel_censorship_fp", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNWBool("peeing") then return end
    if ply:ShouldDrawLocalPlayer() then return end 

    local bodyPos = ply:GetPos() + ply:GetForward() * 7 + Vector(0, 0, 34)
    local screenPos = bodyPos:ToScreen()
    if not screenPos.visible then return end

    drawCensorGrid(screenPos, pixelSize, censorRadius)
end)

-- 3. Цензура ЗАДА (со стороны)
hook.Add("PostPlayerDraw", "hg_poop_censorship", function(ply)
    if not IsValid(ply) or not ply:GetNWBool("pooping") then return end
    if ply == LocalPlayer() and not ply:ShouldDrawLocalPlayer() then return end

    local ent = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
    if not IsValid(ent) then ent = ply end
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return end
    
    local bonePos = ent:GetBonePosition(bone)
    if not bonePos then return end

    local worldPos = bonePos - ply:GetForward() * 6 - Vector(0, 0, 4)
    local screenPos = worldPos:ToScreen()
    if not screenPos.visible then return end

    cam.Start2D() drawCensorGrid(screenPos, poopPixelSize, poopCensorRadius) cam.End2D()
end)

-- 4. Цензура ЗАДА (1-е лицо)
hook.Add("HUDPaint", "hg_poop_censorship_fp", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:GetNWBool("pooping") then return end
    if ply:ShouldDrawLocalPlayer() then return end

    local bodyPos = ply:GetPos() - ply:GetForward() * 8 + Vector(0, 0, 32)
    local screenPos = bodyPos:ToScreen()
    if not screenPos.visible then return end

    drawCensorGrid(screenPos, poopPixelSize, poopCensorRadius)
end)

-- Команды управления
concommand.Add("+hg_poop", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end
    if bowel < 15 then return end 
    
    holdingPoop = true
    net.Start("hg_poop")
    net.WriteBool(true)
    net.SendToServer()
end)

concommand.Add("-hg_poop", function()
    if not holdingPoop then return end
    holdingPoop = false
    net.Start("hg_poop")
    net.WriteBool(false)
    net.SendToServer()
end)