hg.organism.module.pepper = {}
local module = hg.organism.module.pepper

local CurTime = CurTime
local max = math.max

module[1] = function(org)
    org.disorientation = 0
    org.lastPepperHit = 0
end

module[2] = function(owner, org, timeValue)
    if not IsValid(owner) or not owner:IsPlayer() then return end

    if org.disorientation and org.disorientation > 0 then
        org.disorientation = max(org.disorientation - timeValue * 0.3, 0)
    end

    local exposure = owner:GetNWFloat("PS_Exposure", 0)
    local blindEnd = owner:GetNWFloat("PS_BlindEndTime", 0)
    local recovStart = owner:GetNWFloat("PS_RecoveryStart", 0)
    local tint = owner:GetNWFloat("PS_LingeringTint", 0)

    if exposure > 0 then
        owner:SetNWFloat("PS_Exposure", max(exposure - timeValue * 0.04, 0))
    end

    if blindEnd > 0 and CurTime() >= blindEnd then
        owner:SetNWFloat("PS_BlindEndTime", 0)
        owner:SetNWFloat("PS_RecoveryStart", CurTime())
    end

    if recovStart > 0 and CurTime() - recovStart > 5 then
        owner:SetNWFloat("PS_RecoveryStart", 0)
    end

    if tint > 0 then
        owner:SetNWFloat("PS_LingeringTint", max(tint - timeValue * 5, 0))
    end

    local lastHit = org.lastPepperHit or 0
    if org.disorientation >= 10 and blindEnd == 0 and recovStart == 0 and CurTime() - lastHit < 5 then
        owner:SetNWFloat("PS_BlindEndTime", CurTime() + 4)
    end
end
