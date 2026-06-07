util.AddNetworkString("hg_piss")
util.AddNetworkString("piss_particles")
util.AddNetworkString("hg_poop")
util.AddNetworkString("poop_particles")

local pissClr = Color(255, 220, 50)
local happyMessages = {
    "теперь цветы будут расти быстрее)",
    "oooohhh.....",
    "так хорошо прямо сейчас))"
}

local poopClr = Color(139, 69, 19)
local poopMessages = {
    "уф, полегчало...",
    "минус пару килограмм)",
    "кажется, я очистил душу..."
}

-- Вычисление позиции паха (для мочи)
local function pelvisPos(ply)
    local ent = hg.GetCurrentCharacter(ply) or ply
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return ply:GetShootPos() end
    local matrix = ent:GetBoneMatrix(bone)
    if not matrix then return ply:GetShootPos() end
    return matrix:GetTranslation() + matrix:GetAngles():Forward() * 2 + matrix:GetAngles():Up() * -4
end

-- Вычисление позиции ануса (для каканья)
local function anusPos(ply)
    local ent = hg.GetCurrentCharacter(ply) or ply
    local bone = ent:LookupBone("ValveBiped.Bip01_Pelvis")
    if not bone then return ply:GetPos() + Vector(0, 0, 30) end
    local matrix = ent:GetBoneMatrix(bone)
    if not matrix then return ply:GetPos() + Vector(0, 0, 30) end
    return matrix:GetTranslation() + matrix:GetAngles():Forward() * -5 + matrix:GetAngles():Up() * -6
end

function hg.organism.Feed(org, isDrink)
    if not org then return end
    if isDrink then org.drank = true else org.ate = true end
end

local function canPiss(org)
    return org and org.ate and org.drank and not org.otrub
end

local function canPoop(org)
    return org and org.ate and not org.otrub
end

local function stopPiss(ply, spent)
    local org = ply.organism
    if spent and org then
        org.ate = false
        org.drank = false
    end
    ply.peeing = false
    ply:SetNWBool("peeing", false)
    ply.pissDuration = 0
    if ply.PissSound then
        ply.PissSound:Stop()
        ply.PissSound = nil
    end
    ply.nextHappyMsg = nil
end

local function stopPoop(ply, spent)
    local org = ply.organism
    if spent and org then
        org.ate = false
    end
    ply.pooping = false
    ply:SetNWBool("pooping", false)
    ply.poopDuration = 0
    if ply.PoopSound then
        ply.PoopSound:Stop()
        ply.PoopSound = nil
    end
    ply.nextPoopMsg = nil
end

local function tickPiss(ply)
    local org = ply.organism
    if not org or not ply:Alive() or not canPiss(org) then
        stopPiss(ply)
        return
    end

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

    if not ply.nextPissParticles or ply.nextPissParticles < CurTime() then
        ply.nextPissParticles = CurTime() + 0.06
        net.Start("piss_particles")
        net.WriteVector(pos)
        net.WriteVector(dir)
        net.WriteVector(tr.HitPos)
        net.WriteBool(tr.Hit)
        net.Broadcast()
    end

    if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity ~= ply then
        local vic = tr.Entity
        ply.vomitCooldown = ply.vomitCooldown or {}
        if not ply.vomitCooldown[vic] or ply.vomitCooldown[vic] < CurTime() then
            ply.vomitCooldown[vic] = CurTime() + 10
            vic:Notify("Фу, мерзкий ублюдок!", 10, "gey_piss_disgust", nil, nil, Color(100, 200, 100))
            if hg.organism.Vomit then hg.organism.Vomit(vic) end
        end
    end
end

local function tickPoop(ply)
    local org = ply.organism
    if not org or not ply:Alive() or not canPoop(org) then
        stopPoop(ply)
        return
    end

    ply.poopDuration = (ply.poopDuration or 0) + FrameTime()
    if ply.poopDuration >= 5 then
        stopPoop(ply, true)
        return
    end

    if not ply.PoopSound then
        ply.PoopSound = CreateSound(ply, "ambient/water/flux_provo.wav")
        ply.PoopSound:Play()
        ply.PoopSound:ChangeVolume(0.6, 0)
    end

    if not ply.nextPoopMsg or ply.nextPoopMsg < CurTime() then
        ply.nextPoopMsg = CurTime() + 10
        ply:Notify(poopMessages[math.random(#poopMessages)], 10, "poop_happy_" .. math.random(1, 1000), nil, nil, poopClr)
    end

    local pos = anusPos(ply)
    local dir = -ply:GetForward() + Vector(0, 0, -0.5)
    dir:Normalize()

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + dir * 64,
        filter = {ply, hg.GetCurrentCharacter(ply)}
    })

    if not ply.nextPoopParticles or ply.nextPoopParticles < CurTime() then
        ply.nextPoopParticles = CurTime() + 0.08
        net.Start("poop_particles")
        net.WriteVector(pos)
        net.WriteVector(dir)
        net.WriteVector(tr.HitPos)
        net.WriteBool(tr.Hit)
        net.Broadcast()
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

net.Receive("hg_poop", function(_, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local org = ply.organism
    if not org then return end

    if net.ReadBool() then
        if not canPoop(org) then
            if not ply.poopDeniedMsg or ply.poopDeniedMsg < CurTime() then
                ply.poopDeniedMsg = CurTime() + 3
                ply:Notify("Сначала надо что-нибудь съесть...", 3, "poop_need_food")
            end
            return
        end
        ply.pooping = true
        ply:SetNWBool("pooping", true)
        ply.poopDuration = 0
    else
        stopPoop(ply, ply.pooping)
    end
end)

hook.Add("Think", "hg_piss_poop_server", function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.peeing then tickPiss(ply) end
        if ply.pooping then tickPoop(ply) end
    end
end)

hook.Add("Org Clear", "hg_piss_poop", function(org)
    org.ate = false
    org.drank = false
end)

hook.Add("PlayerDeath", "hg_piss_poop_cleanup", function(ply)
    stopPiss(ply)
    stopPoop(ply)
end)

hook.Add("PlayerSpawn", "hg_piss_poop_cleanup", function(ply)
    stopPiss(ply)
    stopPoop(ply)
end)
