local hullscale = Vector(0,0,0)

spect = nil
prevspect = nil
viewmode = 1

local keydownattack = false
local keydownattack2 = false
local keydownreload = false

local function GetSpectTarget(ply)
    if IsValid(spect) then return spect end
    ply = ply or LocalPlayer()
    return IsValid(ply) and ply:GetNWEntity("spect") or NULL
end

local function GetSpectViewmode(ply)
    if viewmode then return viewmode end
    ply = ply or LocalPlayer()
    return IsValid(ply) and ply:GetNWInt("viewmode", 1) or 1
end

local function ResetSpectCam(ply, target, mode)
    if not IsValid(ply) then return end
    ply.spectLastPos = nil
    ply.spectLastAng = nil
    ply.spectCacheId = IsValid(target) and target:EntIndex() or nil
    ply.spectCacheMode = mode
end

net.Receive("ZB_SpectatePlayer", function(len)
    spect = net.ReadEntity()
    prevspect = net.ReadEntity()
    viewmode = net.ReadInt(4)

    local lply = LocalPlayer()
    ResetSpectCam(lply, spect, viewmode)

    lply:SetHull(-hullscale, hullscale)
    lply:SetHullDuck(-hullscale, hullscale)

    if viewmode == 3 then
        lply:SetMoveType(MOVETYPE_NOCLIP)
    elseif lply:GetMoveType() == MOVETYPE_NOCLIP then
        lply:SetMoveType(MOVETYPE_WALK)
    end
end)

hook.Add("PlayerDeath", "zb_spect_reset_cache", function(ply)
    if ply ~= LocalPlayer() then return end
    spect = nil
    viewmode = 1
    ResetSpectCam(ply, nil, 1)
end)

hook.Add("HUDPaint", "zb_spectator_hud", function()
    if LocalPlayer():Alive() then return end
    local spectEnt = GetSpectTarget()
    if not IsValid(spectEnt) then return end
    if GetSpectViewmode() == 3 then return end

    surface.SetFont("HomigradFont")
    surface.SetTextColor(255, 255, 255, 255)
    local txt = "Игрок: " .. spectEnt:Name()
    local w, h = surface.GetTextSize(txt)
    surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
    surface.DrawText(txt)
    local txt = "Имя: " .. spectEnt:GetPlayerName()
    local w, h = surface.GetTextSize(txt)
    surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
    surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zb_spectator_view", function(ply, pos, angles, fov)
    local specPly = IsValid(ply) and ply or LocalPlayer()
    if not IsValid(specPly) then return end

    if specPly:Alive() then
        specPly.spectLastPos = nil
        specPly.spectLastAng = nil
        specPly:SetObserverMode(OBS_MODE_NONE)
        return
    end

    -- Обработка клавиш для смены цели/режима
    if specPly:KeyDown(IN_ATTACK) then
        if not keydownattack then
            keydownattack = true
            net.Start("ZB_ChooseSpecPly")
            net.WriteInt(IN_ATTACK, 32)
            net.SendToServer()
        end
    else
        keydownattack = false
    end

    if specPly:KeyDown(IN_ATTACK2) then
        if not keydownattack2 then
            keydownattack2 = true
            net.Start("ZB_ChooseSpecPly")
            net.WriteInt(IN_ATTACK2, 32)
            net.SendToServer()
        end
    else
        keydownattack2 = false
    end

    if specPly:KeyDown(IN_RELOAD) then
        if not keydownreload then
            keydownreload = true
            net.Start("ZB_ChooseSpecPly")
            net.WriteInt(IN_RELOAD, 32)
            net.SendToServer()
        end
    else
        keydownreload = false
    end

    local spectEnt = GetSpectTarget(specPly)
    if not IsValid(spectEnt) then return end

    local curViewmode = GetSpectViewmode(specPly)
    local spectId = spectEnt:EntIndex()

    if specPly.spectCacheId ~= spectId or specPly.spectCacheMode ~= curViewmode then
        ResetSpectCam(specPly, spectEnt, curViewmode)
    end

    if curViewmode == 3 then
        if specPly:GetMoveType() ~= MOVETYPE_NOCLIP then
            specPly:SetMoveType(MOVETYPE_NOCLIP)
        end
        specPly:SetObserverMode(OBS_MODE_ROAMING)
        return
    end

    if specPly:GetMoveType() == MOVETYPE_NOCLIP then
        specPly:SetMoveType(MOVETYPE_WALK)
    end

    specPly:SetPos(spectEnt:GetPos())

    local ent = hg.GetCurrentCharacter(spectEnt)
    if not IsValid(ent) then ent = spectEnt end

    local ang

    if curViewmode == 1 then
        local eyeTr = hg.eyeTrace(spectEnt, 10, ent, spectEnt:EyeAngles())
        if eyeTr and eyeTr.StartPos then
            pos = eyeTr.StartPos
        else
            local attid = ent:LookupAttachment("eyes")
            local att = attid and attid > 0 and ent:GetAttachment(attid)
            pos = att and att.Pos or spectEnt:EyePos()
        end
        ang = spectEnt:EyeAngles()
    else
        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
        local bon = headBone and ent:GetBoneMatrix(headBone)

        if not bon then
            local eyePos = ent:EyePos()
            if eyePos and eyePos ~= vector_origin then
                pos = eyePos
                ang = ent:EyeAngles()
            else
                pos = ent:GetPos() + Vector(0, 0, 64)
                ang = ent:GetAngles()
            end
        else
            pos, ang = bon:GetTranslation(), bon:GetAngles()
        end

        local eyeAng = specPly:EyeAngles()
        local tr = {}
        tr.start = pos
        tr.endpos = pos + eyeAng:Forward() * -120
        tr.filter = {ent, specPly, spectEnt}
        tr.mins = Vector(-4, -4, -4)
        tr.maxs = Vector(4, 4, 4)
        tr = util.TraceHull(tr)

        pos = tr.HitPos + eyeAng:Forward() * 8
        ang = eyeAng
    end

    ang[3] = 0

    local view
    local hg_newspectate = GetConVar("hg_newspectate")
    if curViewmode ~= 1 and hg_newspectate and hg_newspectate:GetBool() then
        if not specPly.spectLastPos then
            specPly.spectLastPos = pos
            specPly.spectLastAng = ang
        end

        local lerpFactor = FrameTime() * 10
        specPly.spectLastPos = LerpVector(lerpFactor, specPly.spectLastPos, pos)
        specPly.spectLastAng = LerpAngle(lerpFactor, specPly.spectLastAng, ang)

        view = {
            origin = specPly.spectLastPos,
            angles = specPly.spectLastAng,
            fov = fov,
            drawviewer = false,
        }
    else
        view = {
            origin = pos,
            angles = ang,
            fov = fov,
        }
    end

    return view
end)