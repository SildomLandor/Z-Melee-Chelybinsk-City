include("shared.lua")

local holdStart

local function setSequenceSafe(ent, sequenceName)
    local sequence = ent:LookupSequence(sequenceName)
    if sequence and sequence >= 0 then
        ent:SetSequence(sequence)
        ent:SetCycle(0)
        ent:SetPlaybackRate(1)
        ent:ResetSequenceInfo()
        return sequence
    end
end

local function playOpenVisual(trap)
    if not IsValid(trap) or trap:HasVictim() then return end

    local openSeq = setSequenceSafe(trap, "Open")
    if not openSeq then
        setSequenceSafe(trap, "OpenIdle")
        return
    end

    timer.Simple(math.max(trap:SequenceDuration(openSeq), 0.05), function()
        if not IsValid(trap) or trap:HasVictim() then return end
        setSequenceSafe(trap, "OpenIdle")
    end)
end

function ENT:OnTrappedPlayerChanged(name, old, new)
    if IsValid(old) and not IsValid(new) then
        playOpenVisual(self)
    end
end

local function getMyTrap(ply)
    ply = ply or LocalPlayer()
    if not IsValid(ply) then return end

    local trap = ply:GetNWEntity("PAT_Beartrap")
    if not IsValid(trap) or not trap:HasVictim() or trap:GetTrappedPlayer() ~= ply then
        return
    end

    return trap
end

local function holdingRelease()
    local ply = LocalPlayer()
    return IsValid(ply) and ply:KeyDown(IN_WALK) and ply:KeyDown(IN_USE)
end

function ENT:Draw()
    self:DrawModel()
end

hook.Add("Player Think", "pat_beartrap_legpose", function(ply, time, dtime)
    if not IsValid(ply) or not ply:Alive() then return end

    local trap = ply:GetNWEntity("PAT_Beartrap")
    if not IsValid(trap) or not trap:HasVictim() or trap:GetTrappedPlayer() ~= ply then
        if ply.PAT_BeartrapPoseActive then
            PAT_BEARTRAP.ResetLegPose(ply)
            if IsValid(ply.FakeRagdoll) then
                PAT_BEARTRAP.ResetLegPose(ply.FakeRagdoll)
            end
            ply.PAT_BeartrapPoseActive = nil
        end
        return
    end

    ply.PAT_BeartrapPoseActive = true
    local limb = PAT_BEARTRAP.LimbFromId(ply:GetNWInt("PAT_BeartrapLimb", 0))
    if not limb then return end

    local poseEnt = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    if poseEnt ~= ply then
        PAT_BEARTRAP.ResetLegPose(ply)
    end

    PAT_BEARTRAP.ApplyLegPose(poseEnt, limb, dtime)
end)

hook.Add("HUDPaint", "pat_beartrap_release", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local trap = getMyTrap(ply)
    if not IsValid(trap) then
        holdStart = nil
        return
    end

    --local limb = PAT_BEARTRAP.LimbFromId(ply:GetNWInt("PAT_BeartrapLimb", 0))
    --local side = limb == "rleg" and "правой" or "левой"
    local hint = "Alt+E — открыть капкан"

    draw.SimpleText(hint, "ZCity_Veteran", ScrW() * 0.5, ScrH() * 0.58, Color(190, 180, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if not holdingRelease() then
        holdStart = nil
        return
    end

    holdStart = holdStart or CurTime()
    local need = PAT_BEARTRAP and PAT_BEARTRAP.ReleaseTime or 3
    local frac = math.Clamp((CurTime() - holdStart) / need, 0, 1)

    local w, h = 180, 9
    local x, y = ScrW() * 0.5 - w * 0.5, ScrH() * 0.62

    surface.SetDrawColor(15, 15, 15, 215)
    surface.DrawRect(x - 1, y - 1, w + 2, h + 2)

    surface.SetDrawColor(40, 40, 44, 220)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(52, 30, 38, 220)
    surface.DrawRect(x, y, math.max(1, w * frac), h)
end)
