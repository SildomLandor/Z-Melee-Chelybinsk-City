if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_tpik_base"
local sprayRange = CreateConVar("pepperspray_range", "190", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Effective range of the pepper spray")
local sprayCapacity = CreateConVar("pepperspray_capacity", "100", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Total spray amount")
local sprayDrain = CreateConVar("pepperspray_drain_per_tick", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Spray amount consumed per attack tick")
SWEP.PrintName = "Перцовый баллончик"
SWEP.Instructions = "Нелетальное средство самообороны. Вызывает временную слепоту и раздражение."
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.IconOverride = "entities/weapon_pepperspray_tpik.png"
if CLIENT then
    SWEP.WepSelectIcon = Material("entities/weapon_pepperspray_tpik.png")
    SWEP.WepSelectIcon2 = Material("entities/weapon_pepperspray_tpik.png")
end
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.ViewModel = "models/weapons/custom/v_pepperspray.mdl"
SWEP.WorldModel = "models/weapons/custom/pepperspray.mdl"
SWEP.WorldModelReal = "models/weapons/custom/v_pepperspray.mdl"
SWEP.WorldModelExchange = false
SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(0, 0, 0)
SWEP.HoldPos = Vector(-3.8, -6, 0)
SWEP.HoldAng = Angle(0, 0, 10)
SWEP.HoldType = "slam"
SWEP.modelscale = 1
SWEP.modelscale2 = 1
SWEP.AnimList = {
    ["deploy"] = { "draw", 1, false },
    ["idle"] = { "idle", 5, true },
    ["start_spray"] = { "startsh", 0.5, false },
    ["stop_spray"] = { "stopsh", 0.3, false },
    ["safety_off"] = { "safetyoff", 1, false },
    ["safety_on"] = { "safetyon", 1, false }
}
sound.Add({
    name = "PepperSpray.Loop",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 60,
    pitch = {95, 105},
    sound = "weapons/pepperspray/spray_loop.wav"
})
sound.Add({
    name = "PepperSpray.Shake",
    channel = CHAN_WEAPON,
    volume = 1.0,
    level = 60,
    pitch = {95, 105},
    sound = "weapons/pepperspray/shake.wav"
})

local function StopSpraying(self)
    if self.IsSpraying then
        self:PlayAnim("stop_spray")
    end
    if SERVER then
        self:SetNWBool("IsSpraying", false)
    end
    self.IsSpraying = false
    if CLIENT then
        if self.SpraySoundPatch then
            self.SpraySoundPatch:Stop()
            self.SpraySoundPatch = nil
        end
        self.SpraySoundOwner = nil
        self.WasSprayingCL = false
    end
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self.SprayAmount = self.SprayAmount or sprayCapacity:GetFloat()
    if owner:KeyDown(IN_ATTACK) then
        if self.SprayAmount <= 0 then
            StopSpraying(self)
            return
        end
        self:SetNextPrimaryFire(CurTime() + 0.05)
        if SERVER then
            self:SetNWBool("IsSpraying", true)
        end
        if not self.IsSpraying then
            self:PlayAnim("start_spray")
            self.IsSpraying = true
        end
        if SERVER then
            self.SprayAmount = math.max(self.SprayAmount - sprayDrain:GetFloat(), 0)
            local tr = util.TraceLine({
                start = owner:GetShootPos(),
                endpos = owner:GetShootPos() + owner:GetAimVector() * sprayRange:GetFloat(),
                filter = owner
            })
            local dist = tr.StartPos:Distance(tr.HitPos)
            if tr.Hit then
                local ent = tr.Entity
                local org = ent.organism or (ent:IsPlayer() and IsValid(ent.FakeRagdoll) and ent.FakeRagdoll.organism)
                if org then
                    local isFace = false
                    if tr.HitGroup == HITGROUP_HEAD then
                        isFace = true
                        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
                        if headBone then
                            local bonePos, boneAng = ent:GetBonePosition(headBone)
                            local hitPos = tr.HitPos
                            local localHitPos = (hitPos - bonePos):GetNormalized()
                            local dRight = localHitPos:Dot(boneAng:Right())
                            if dRight < 0.2 then isFace = true end
                        end
                    end
                    if isFace then
                        org.painadd = (org.painadd or 0) + 1.2
                        org.disorientation = math.min((org.disorientation or 0) + 2.5, 14)
                        if ent:IsPlayer() then
                            local curExposure = ent:GetNWFloat("PS_Exposure", 0)
                            ent:SetNWFloat("PS_Exposure", curExposure + 0.09)
                            ent:SetNWFloat("PS_LastHitTime", CurTime())
                            local curTint = ent:GetNWFloat("PS_LingeringTint", 0)
                            ent:SetNWFloat("PS_LingeringTint", math.min(curTint + 22, 100))
                        end
                    end
                    hg.send_bareinfo(org)
                end
            end
        end
    else
        StopSpraying(self)
    end
end
if CLIENT then
    local emitter
    local offX = CreateClientConVar("pepperspray_offset_x", "17", true, false, "Spray offset Forward")
    local offY = CreateClientConVar("pepperspray_offset_y", "3", true, false, "Spray offset Right")
    local offZ = CreateClientConVar("pepperspray_offset_z", "-6", true, false, "Spray offset Up")

    local function stopSpraySound(swep)
        if swep.SpraySoundPatch then
            swep.SpraySoundPatch:Stop()
            swep.SpraySoundPatch = nil
        end
        swep.SpraySoundOwner = nil
        swep.WasSprayingCL = false
    end

    local function shouldSpraySound(swep)
        local owner = swep:GetOwner()
        if not IsValid(owner) then return false end
        if owner == LocalPlayer() then
            return swep.IsSpraying and owner:KeyDown(IN_ATTACK)
        end
        return swep:GetNWBool("IsSpraying", false)
    end

    local function updateSpraySound(swep)
        if not shouldSpraySound(swep) then
            if swep.WasSprayingCL then stopSpraySound(swep) end
            return
        end

        local owner = swep:GetOwner()
        if not swep.SpraySoundPatch or swep.SpraySoundOwner ~= owner then
            stopSpraySound(swep)
            swep.SpraySoundPatch = CreateSound(owner, "PepperSpray.Loop")
            swep.SpraySoundOwner = owner
            if swep.SpraySoundPatch then
                swep.SpraySoundPatch:SetSoundLevel(65)
            end
        end

        if swep.SpraySoundPatch and not swep.SpraySoundPatch:IsPlaying() then
            swep.SpraySoundPatch:PlayEx(1, 100)
        end

        swep.WasSprayingCL = true
    end

    hook.Add("Think", "PepperSprayParticles", function()
        local anySpraying = false

        for _, swep in ipairs(ents.FindByClass("weapon_pepperspray_tpik")) do
            local spraying = swep:GetNWBool("IsSpraying", false)
            updateSpraySound(swep)

            if spraying then
                anySpraying = true

                local owner = swep:GetOwner()
                if not IsValid(owner) then continue end

                if not emitter then
                    emitter = ParticleEmitter(owner:GetPos())
                else
                    emitter:SetPos(owner:GetPos())
                end

                local aimang = owner:EyeAngles()
                local muzzle = owner:GetShootPos()
                    + aimang:Forward() * offX:GetFloat()
                    + aimang:Right() * offY:GetFloat()
                    + aimang:Up() * offZ:GetFloat()
                local dir = aimang:Forward()

                swep.NextParticle = swep.NextParticle or 0
                if swep.NextParticle < CurTime() then
                    swep.NextParticle = CurTime() + 0.03

                    local p = emitter:Add("effects/splash2", muzzle)
                    if p then
                        p:SetVelocity(dir * math.Rand(400, 600) + VectorRand() * 30)
                        p:SetDieTime(math.Rand(0.4, 0.6))
                        p:SetStartAlpha(180)
                        p:SetEndAlpha(0)
                        p:SetStartSize(math.Rand(1, 2))
                        p:SetEndSize(math.Rand(8, 12))
                        p:SetRoll(math.Rand(0, 360))
                        p:SetRollDelta(math.Rand(-5, 5))
                        p:SetColor(255, 150, 0)
                        p:SetAirResistance(150)
                        p:SetGravity(Vector(0, 0, -100))
                        p:SetLighting(false)
                    end

                    local trImpact = util.TraceLine({
                        start = muzzle,
                        endpos = muzzle + dir * sprayRange:GetFloat(),
                        filter = owner
                    })
                    if trImpact.Hit then
                        local hitP = emitter:Add("effects/splash2", trImpact.HitPos + trImpact.HitNormal * 2)
                        if hitP then
                            hitP:SetVelocity(trImpact.HitNormal * math.Rand(1, 3))
                            hitP:SetDieTime(math.Rand(0.6, 1))
                            hitP:SetStartAlpha(220)
                            hitP:SetEndAlpha(0)
                            hitP:SetStartSize(math.Rand(3, 5))
                            hitP:SetEndSize(math.Rand(5, 7))
                            hitP:SetRoll(math.Rand(0, 360))
                            hitP:SetColor(255, 130, 0)
                            hitP:SetGravity(Vector(0, 0, -5))
                        end
                    end
                end
            end
        end

        if not anySpraying and emitter then
            emitter:Finish()
            emitter = nil
        end
    end)
end
function SWEP:ThinkAdd()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if self.IsSpraying and not owner:KeyDown(IN_ATTACK) then
        StopSpraying(self)
    end
end
function SWEP:PreDrawViewModel(vm, wep, ply)
    if IsValid(ply) and (IsValid(ply.FakeRagdoll) or (ply.IsFirstPerson and not ply:IsFirstPerson())) then
        return true
    end
end
function SWEP:OnRemove()
    if CLIENT then
        if self.SpraySoundPatch then
            self.SpraySoundPatch:Stop()
            self.SpraySoundPatch = nil
        end
        self.SpraySoundOwner = nil
        self.WasSprayingCL = false
    end
end
function SWEP:SecondaryAttack()
end
function SWEP:Initialize()
    self:SetHold(self.HoldType)
    self.SprayAmount = sprayCapacity:GetFloat()
    self:InitAdd()
end
function SWEP:InitAdd()
end
