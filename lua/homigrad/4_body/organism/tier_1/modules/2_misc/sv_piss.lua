util.AddNetworkString("hg_piss")
util.AddNetworkString("piss_particles")

local pissClr = Color(255, 220, 50)
local happyMessages = {
    "теперь цветы будут расти быстрее)",
    "oooohhh.....",
    "так хорошо прямо сейчас))"
}

local function pelvisPos(ply)
    local ent = hg.GetCurrentCharacter(ply) or ply
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return ply:GetShootPos() end
    local matrix = ent:GetBoneMatrix(bone)
    if not matrix then return ply:GetShootPos() end
    return matrix:GetTranslation() + matrix:GetAngles():Forward() * 2 + matrix:GetAngles():Up() * -4
end

function hg.organism.Feed(org, isDrink)
    if not org then return end
    if isDrink then org.drank = true else org.ate = true end
end

local function canPiss(org)
    return org and org.ate and org.drank and not org.otrub
end

local function stopPiss(ply, spent)
    local org = ply.organism
    if spent and org then
        org.ate = false
        org.drank = false
    end

    ply.peeing = false
    ply:SetNWBool("peeing", false)
    ply.pissDuration = 0 -- Сброс таймера

    if ply.PissSound then
        ply.PissSound:Stop()
        ply.PissSound = nil
    end

    ply.nextHappyMsg = nil
end

local function tickPiss(ply)
    local org = ply.organism
    if not org or not ply:Alive() or not canPiss(org) then
        stopPiss(ply)
        return
    end

    -- Ограничение времени: принудительно останавливаем спустя 5 секунд непрерывного процесса
    ply.pissDuration = (ply.pissDuration or 0) + FrameTime()
    if ply.pissDuration >= 5 then
        stopPiss(ply, true)
        return
    end

    if not ply.PissSound then
        ply.PissSound = CreateSound(ply, "ambient/water/water_spray1.wav")
        ply.PissSound:Play()
        ply.PissSound:ChangeVolume(0.5, 0)
    end

    if not ply.nextHappyMsg or ply.nextHappyMsg < CurTime() then
        ply.nextHappyMsg = CurTime() + 10
        ply:Notify(happyMessages[math.random(#happyMessages)], 10, "gey_piss_happy" .. math.random(1, 1000), nil, nil, pissClr)
    end

    local pos = pelvisPos(ply)
    local dir = ply:GetAimVector()
    local tr = util.TraceLine({
        start = pos,
        endpos = pos + dir * 128,
        filter = {ply, hg.GetCurrentCharacter(ply)}
    })

    -- Оптимизация сети: отправляем пакеты в два раза реже (0.06 сек вместо 0.03).
    -- Это значительно снизит нагрузку на сервер/клиентов и уменьшит плотность частиц у других игроков.
    if not ply.nextPissParticles or ply.nextPissParticles < CurTime() then
        ply.nextPissParticles = CurTime() + 0.06
        net.Start("piss_particles")
        net.WriteVector(pos)
        net.WriteVector(dir)
        net.WriteVector(tr.HitPos)
        net.WriteBool(tr.Hit)
        net.Broadcast()
    end

    -- Убран серверный util.Decal. Клиент сам отлично создаёт брызги и декалы при коллизии частиц.
    -- Это убирает микрофризы сервера при падении капель на пропсы/стены.

    if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity ~= ply then
        local vic = tr.Entity
        ply.vomitCooldown = ply.vomitCooldown or {}
        if not ply.vomitCooldown[vic] or ply.vomitCooldown[vic] < CurTime() then
            ply.vomitCooldown[vic] = CurTime() + 10
            vic:Notify("Фу, мерзкий ублюдок!", 10, "gey_piss_disgust", nil, nil, Color(100, 200, 100))
            if hg.organism.VomitFluid then hg.organism.VomitFluid(vic) end
        end
    end
end

net.Receive("hg_piss", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local org = ply.organism
    if not org then return end

    if net.ReadBool() then
        if not canPiss(org) then
            if not ply.pissDeniedMsg or ply.pissDeniedMsg < CurTime() then
                ply.pissDeniedMsg = CurTime() + 3
                ply:Notify("Сначала надо поесть и попить...", 3, "piss_need_food")
            end
            return
        end

        ply.peeing = true
        ply:SetNWBool("peeing", true)
        ply.pissDuration = 0
    else
        stopPiss(ply, ply.peeing)
    end
end)

hook.Add("Think", "hg_piss", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.peeing then tickPiss(ply) end
    end
end)

hook.Add("Org Clear", "hg_piss", function(org)
    org.ate = false
    org.drank = false
end)

hook.Add("PlayerDeath", "hg_piss", function(ply)
    stopPiss(ply)
end)

hook.Add("PlayerSpawn", "hg_piss", function(ply)
    stopPiss(ply)
end)

hook.Add("PlayerDisconnected", "hg_piss", function(ply)
    stopPiss(ply)
end)