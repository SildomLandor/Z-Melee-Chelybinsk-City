local function LegKickFreeze(ply, cmd, mv, mul)
    if ply:GetNWFloat("InLegKick", 0) <= CurTime() then return end

    cmd:SetForwardMove(0)
    cmd:SetSideMove(0)
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    cmd:RemoveKey(IN_FORWARD)
    cmd:RemoveKey(IN_BACK)
    cmd:RemoveKey(IN_MOVELEFT)
    cmd:RemoveKey(IN_MOVERIGHT)
    cmd:RemoveKey(IN_SPEED)
    cmd:RemoveKey(IN_JUMP)

    ply.MovementInertia = vector_origin
    ply.LastVelocity = vector_origin
    ply.LastVelocityLen = 0
    ply.CurrentSpeed = 0
    mul[1] = 0
end

hook.Add("HG_MovementCalc_2", "HG-LegKickAnim", function(mul, ply, cmd, mv)
    LegKickFreeze(ply, cmd, mv, mul)
end)

hook.Add("FinishMove", "HG-LegKickStop", function(ply, mv)
    if ply:GetNWFloat("InLegKick", 0) <= CurTime() then return end
    local vel = mv:GetVelocity()
    if vel:Length2D() < 8 then return end
    mv:SetVelocity(Vector(0, 0, vel.z))
end)

hook.Add("hg_AdjustMouseSensitivity", "HG-LegKickAnim", function(ply)
    if ply:GetNWFloat("InLegKick", 0) > CurTime() then
        return math.min(math.max(0.02, 1 - (ply:GetNWFloat("InLegKick", 0) - CurTime()) * 2), 1)
    end
end)
