if SERVER then
    AddCSLuaFile()

    local files = {
        "materials/vgui/weapon_beartrap_homigrad.png",
        "materials/vgui/weapon_beartrap_homigrad.vmt",
        "materials/models/freeman/beartrap_diffuse.vtf",
        "materials/models/freeman/beartrap_specular.vtf",
        "materials/models/freeman/trap_dif.vmt",
        "sound/beartrap.wav",
        "models/stiffy360/beartrap.dx80.vtx",
        "models/stiffy360/beartrap.dx90.vtx",
        "models/stiffy360/beartrap.mdl",
        "models/stiffy360/beartrap.phy",
        "models/stiffy360/beartrap.sw.vtx",
        "models/stiffy360/beartrap.vvd",
        "models/stiffy360/beartrap.xbox.vtx",
        "models/stiffy360/c_beartrap.dx80.vtx",
        "models/stiffy360/c_beartrap.dx90.vtx",
        "models/stiffy360/c_beartrap.mdl",
        "models/stiffy360/c_beartrap.sw.vtx",
        "models/stiffy360/c_beartrap.vvd",
        "models/stiffy360/c_beartrap.xbox.vtx"
    }

    for _, path in ipairs(files) do
        resource.AddFile(path)
    end
end

PAT_BEARTRAP = PAT_BEARTRAP or {}
PAT_BEARTRAP.Model = "models/stiffy360/beartrap.mdl"
PAT_BEARTRAP.ViewModel = "models/stiffy360/c_beartrap.mdl"
PAT_BEARTRAP.Sound = Sound("beartrap.wav")
PAT_BEARTRAP.RearmTime = 3.5
PAT_BEARTRAP.ReleaseTime = 3
PAT_BEARTRAP.BleedInterval = 1.4
PAT_BEARTRAP.NPCDamage = 65
PAT_BEARTRAP.LegRadiusSqr = 22 * 22
PAT_BEARTRAP.KarmaGriefPenalty = 50

PAT_BEARTRAP.LimbById = { [1] = "lleg", [2] = "rleg" }
PAT_BEARTRAP.LimbId = { lleg = 1, rleg = 2 }
PAT_BEARTRAP.LimbPhysNum = { lleg = 13, rleg = 14 }
PAT_BEARTRAP.LimbCalf = {
    lleg = "ValveBiped.Bip01_L_Calf",
    rleg = "ValveBiped.Bip01_R_Calf",
}

PAT_BEARTRAP.ClampLocal = Vector(1.5, 0, 4)

PAT_BEARTRAP.LimbBones = {
    lleg = {
        thigh = "ValveBiped.Bip01_L_Thigh",
        calf = "ValveBiped.Bip01_L_Calf",
        foot = "ValveBiped.Bip01_L_Foot",
    },
    rleg = {
        thigh = "ValveBiped.Bip01_R_Thigh",
        calf = "ValveBiped.Bip01_R_Calf",
        foot = "ValveBiped.Bip01_R_Foot",
    },
}

PAT_BEARTRAP.LegPose = {
    lleg = {
        thigh = Angle(28, 8, -6),
        calf = Angle(-78, 4, 0),
        foot = Angle(42, -6, 0),
    },
    rleg = {
        thigh = Angle(28, -8, 6),
        calf = Angle(-78, -4, 0),
        foot = Angle(42, 6, 0),
    },
}

function PAT_BEARTRAP.GetClampPos(trap)
    return trap:LocalToWorld(PAT_BEARTRAP.ClampLocal)
end

function PAT_BEARTRAP.AlignVictimToTrap(victim, trap, limb)
    if not IsValid(victim) or not IsValid(trap) or not limb then return end

    local bones = PAT_BEARTRAP.LimbBones[limb]
    if not bones then return end

    local footID = victim:LookupBone(bones.foot)
    if not footID then return end

    local footPos = select(1, victim:GetBonePosition(footID))
    if not isvector(footPos) then return end

    local clampPos = PAT_BEARTRAP.GetClampPos(trap)
    local away = -trap:GetForward()
    away.z = 0

    if away:LengthSqr() < 0.01 then
        away = trap:GetRight()
        away.z = 0
    end

    away:Normalize()
    victim:SetAngles(Angle(0, away:Angle().y, 0))

    footPos = select(1, victim:GetBonePosition(footID)) or footPos
    local fix = clampPos - footPos
    fix.z = 0

    victim:SetPos(victim:GetPos() + fix)
end

function PAT_BEARTRAP.ApplyLegPose(ply, limb, dtime)
    if not IsValid(ply) or not hg or not hg.bone then return end

    local bones = PAT_BEARTRAP.LimbBones[limb]
    local pose = PAT_BEARTRAP.LegPose[limb]
    if not bones or not pose then return end

    local lerp = 0.25
    hg.bone.Set(ply, bones.thigh, vector_origin, pose.thigh, "beartrap", lerp, dtime)
    hg.bone.Set(ply, bones.calf, vector_origin, pose.calf, "beartrap", lerp, dtime)
    hg.bone.Set(ply, bones.foot, vector_origin, pose.foot, "beartrap", lerp, dtime)
end

function PAT_BEARTRAP.ResetLegPose(ply)
    if not IsValid(ply) then return end

    for _, limb in pairs(PAT_BEARTRAP.LimbBones) do
        for _, boneName in pairs(limb) do
            local boneID = ply:LookupBone(boneName)
            if boneID then
                ply:ManipulateBoneAngles(boneID, angle_zero, false)
                ply:ManipulateBonePosition(boneID, vector_origin, false)

                if ply.manipulated and ply.manipulated[boneID] and ply.manipulated[boneID].layers then
                    ply.manipulated[boneID].layers.beartrap = nil
                end
            end
        end
    end
end

function PAT_BEARTRAP.LimbFromId(id)
    return PAT_BEARTRAP.LimbById[id or 0]
end

function PAT_BEARTRAP.IdFromLimb(limb)
    return PAT_BEARTRAP.LimbId[limb] or 0
end

local function beartrapBonePos(ent, boneName)
    if not IsValid(ent) or not boneName then return end

    local bone = ent:LookupBone(boneName)
    if not bone then return end

    local pos = select(1, ent:GetBonePosition(bone))
    if isvector(pos) and not pos:IsZero() then return pos end

    local matrix = ent:GetBoneMatrix(bone)
    if matrix then return matrix:GetTranslation() end
end

function PAT_BEARTRAP.GetClosestLegDistanceSqr(ply, trapPos)
    local char = PAT_BEARTRAP.GetCharacterEntity(ply)
    if not IsValid(char) then return math.huge end

    local leftPos = beartrapBonePos(char, "ValveBiped.Bip01_L_Foot") or beartrapBonePos(char, "ValveBiped.Bip01_L_Calf")
    local rightPos = beartrapBonePos(char, "ValveBiped.Bip01_R_Foot") or beartrapBonePos(char, "ValveBiped.Bip01_R_Calf")
    local best = math.huge

    if isvector(leftPos) then best = math.min(best, leftPos:DistToSqr(trapPos)) end
    if isvector(rightPos) then best = math.min(best, rightPos:DistToSqr(trapPos)) end
    if best < math.huge then return best end

    local nearest = char:NearestPoint(trapPos)
    return isvector(nearest) and nearest:DistToSqr(trapPos) or math.huge
end

function PAT_BEARTRAP.GetCharacterEntity(ent)
    if not IsValid(ent) then return end

    if ent:IsPlayer() then
        if hg and hg.GetCurrentCharacter then
            return hg.GetCurrentCharacter(ent) or ent
        end

        return IsValid(ent.FakeRagdoll) and ent.FakeRagdoll or ent
    end

    if ent:IsRagdoll() and hg and hg.RagdollOwner then
        local owner = hg.RagdollOwner(ent)
        if IsValid(owner) then
            return PAT_BEARTRAP.GetCharacterEntity(owner)
        end
    end

    return ent
end

