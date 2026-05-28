AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local releaseTraceDist = 88

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

local function playOpenVisual(trap, callback)
    if not IsValid(trap) or trap:HasVictim() then return end

    local openSeq = setSequenceSafe(trap, "Open")
    if not openSeq then
        setSequenceSafe(trap, "OpenIdle")
        if callback then callback() end
        return
    end

    timer.Simple(math.max(trap:SequenceDuration(openSeq), 0.05), function()
        if not IsValid(trap) or trap:HasVictim() then return end

        setSequenceSafe(trap, "OpenIdle")
        if callback then callback() end
    end)
end

local function getBonePos(ent, boneName)
    if not IsValid(ent) or not boneName then return end

    local bone = ent:LookupBone(boneName)
    if not bone then return end

    local pos = select(1, ent:GetBonePosition(bone))
    if isvector(pos) and not pos:IsZero() then
        return pos
    end

    local matrix = ent:GetBoneMatrix(bone)
    if matrix then
        return matrix:GetTranslation()
    end
end

local function chooseLimb(ply, trapPos)
    local org = ply.organism
    if not org then return end

    local char = PAT_BEARTRAP.GetCharacterEntity(ply)
    local leftPos = getBonePos(char, "ValveBiped.Bip01_L_Foot") or getBonePos(char, "ValveBiped.Bip01_L_Calf")
    local rightPos = getBonePos(char, "ValveBiped.Bip01_R_Foot") or getBonePos(char, "ValveBiped.Bip01_R_Calf")

    local chosen
    if isvector(leftPos) and isvector(rightPos) then
        chosen = leftPos:DistToSqr(trapPos) <= rightPos:DistToSqr(trapPos) and "lleg" or "rleg"
    else
        local localPos = char:WorldToLocal(trapPos)
        chosen = localPos.y >= 0 and "lleg" or "rleg"
    end

    local other = chosen == "lleg" and "rleg" or "lleg"
    if org[chosen .. "amputated"] and not org[other .. "amputated"] then
        chosen = other
    end

    return chosen
end

function PAT_BEARTRAP.PunishGrief(owner, victim)
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if not IsValid(victim) or not victim:IsPlayer() or victim == owner then return end

    owner.PAT_BeartrapKarmaCD = owner.PAT_BeartrapKarmaCD or {}
    local cdKey = victim:SteamID64()
    if owner.PAT_BeartrapKarmaCD[cdKey] and owner.PAT_BeartrapKarmaCD[cdKey] > CurTime() then return end
    owner.PAT_BeartrapKarmaCD[cdKey] = CurTime() + 8

    local pen = PAT_BEARTRAP.KarmaGriefPenalty or 50
    local maxK = (zb and zb.MaxKarma) or 120
    owner.Karma = math.Clamp((owner.Karma or 100) - pen, -60, maxK)
    owner:SetNetVar("Karma", owner.Karma)
    if owner.guilt_SetValue then owner:guilt_SetValue(owner.Karma) end

    if owner.Notify then
        owner:Notify("Капкан под ноги: -" .. pen .. " кармы.", 5, "pat_beartrap", 1, nil, Color(255, 80, 80))
    end
end

local function resolveVictim(ent)
    if not IsValid(ent) then return end
    if ent:IsPlayer() then return ent end
    if ent:IsRagdoll() and hg and hg.RagdollOwner then
        return hg.RagdollOwner(ent)
    end
end

local function legWoundBone(victim, limb)
    local calf = PAT_BEARTRAP.LimbCalf[limb]
    if not calf then return "ValveBiped.Bip01_L_Calf" end

    local skel = victim:LookupBone(calf)
    if not skel then return calf end

    return victim:GetBoneName(skel - 1) or calf
end

local function applyOrganismTrapDamage(victim, limb, heavy)
    local org = victim.organism
    if not org then return end

    org.painadd = org.painadd + (heavy and 30 or 20)
    org.shock = org.shock + (heavy and 12 or 8)
    org.fearadd = (org.fearadd or 0) + 0.2

    local bone = legWoundBone(victim, limb or "lleg")
    local amount = heavy and 28 or 14
    local count = heavy and 3 or 1

    for i = 1, count do
        hg.organism.AddWoundManual(
            victim,
            amount,
            Vector(6, math.Rand(-1.5, 1.5), 0),
            Angle(),
            bone,
            CurTime() + (heavy and math.Rand(0, 0.4) or 0)
        )
    end
end

local function applyClampWounds(victim, limb, trap)
    local org = victim.organism
    if not org or org[limb .. "amputated"] then return end

    applyOrganismTrapDamage(victim, limb, true)
end

local function bleedTick(victim, limb, trap)
    if not IsValid(victim) or not victim:Alive() or not victim.organism then return end
    if victim.organism[limb .. "amputated"] then return end

    applyOrganismTrapDamage(victim, limb, false)
end

local function clearPin(ply)
    if not IsValid(ply) then return end
    ply.PAT_BeartrapTrap = nil
    ply:SetNWEntity("PAT_Beartrap", NULL)
    ply:SetNWInt("PAT_BeartrapLimb", 0)
end

function ENT:ClearLegWeld()
    if IsValid(self.BeartrapWeld) then
        self.BeartrapWeld:Remove()
    end
    self.BeartrapWeld = nil
end

function ENT:UpdateLegWeld(victim, limb)
    local rag = IsValid(victim) and victim.FakeRagdoll or nil
    local physNum = PAT_BEARTRAP.LimbPhysNum[limb]

    if IsValid(rag) and physNum and hg and hg.realPhysNum then
        physNum = hg.realPhysNum(rag, physNum) or physNum
        if not IsValid(self.BeartrapWeld) then
            self.BeartrapWeld = constraint.Weld(rag, self, physNum, 0, 0, false, false)
        end
        return
    end

    self:ClearLegWeld()
end

local function playerReleasing(ply, trap)
    if not IsValid(ply) or not ply:Alive() or not IsValid(trap) then return false end
    if not ply:KeyDown(IN_WALK) or not ply:KeyDown(IN_USE) then return false end

    if trap:GetTrappedPlayer() == ply then
        return true
    end

    if IsValid(ply.FakeRagdoll) then return false end

    local tr = hg.eyeTrace and hg.eyeTrace(ply, releaseTraceDist) or ply:GetEyeTrace()
    return tr.Entity == trap
end

function ENT:Initialize()
    self:SetModel(PAT_BEARTRAP.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(true)
    self:SetTrigger(true)
    self:SetArmed(false)
    self:SetNextRearm(0)
    self:SetTrappedLimb(0)
    self.NextTrigger = 0
    self.LastVictim = nil
    self.LastVictimUntil = 0
    self.NextBleed = 0
    self.ReleaseHold = {}
    self.ScanRadius = 24

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end

    setSequenceSafe(self, "ClosedIdle")

    timer.Simple(0.6, function()
        if IsValid(self) and not self:HasVictim() then
            playOpenVisual(self, function()
                if IsValid(self) and not self:HasVictim() then
                    self:ArmTrap()
                end
            end)
        end
    end)
end

function ENT:CanTriggerVictim(victim)
    if not IsValid(victim) then return false end
    if not victim:IsPlayer() then return false end
    if not victim:Alive() then return false end
    if victim:GetMoveType() == MOVETYPE_NOCLIP then return false end
    if victim:GetObserverMode() ~= OBS_MODE_NONE then return false end
    if IsValid(victim.PAT_BeartrapTrap) then return false end
    if PAT_BEARTRAP.GetClosestLegDistanceSqr(victim, self:GetPos()) > PAT_BEARTRAP.LegRadiusSqr then return false end

    return true
end

function ENT:ArmTrap()
    if self:HasVictim() then return end
    self:SetArmed(true)
    self:SetNextRearm(0)
    setSequenceSafe(self, "OpenIdle")
end

function ENT:OpenTrap()
    if self:HasVictim() then return end
    self:SetArmed(false)
    playOpenVisual(self)
end

function ENT:CloseTrap()
    self:SetArmed(false)
    setSequenceSafe(self, "ClosedIdle")
end

function ENT:PinVictim(victim, limb)
    self:SetTrappedPlayer(victim)
    self:SetTrappedLimb(PAT_BEARTRAP.IdFromLimb(limb))
    victim.PAT_BeartrapTrap = self
    victim:SetNWEntity("PAT_Beartrap", self)
    victim:SetNWInt("PAT_BeartrapLimb", PAT_BEARTRAP.IdFromLimb(limb))
    self.NextBleed = CurTime() + PAT_BEARTRAP.BleedInterval

    if victim.organism then
        victim.organism.lightstun = math.min(victim.organism.lightstun or 0, CurTime())
        victim:SetLocalVar("stun", victim.organism.lightstun)
    end

    if not IsValid(victim.FakeRagdoll) then
        PAT_BEARTRAP.AlignVictimToTrap(victim, self, limb)
    end

    self:UpdateLegWeld(victim, limb)
end

function ENT:ReleaseVictim(opener)
    self:ClearLegWeld()
    self.BeartrapWasFake = nil

    local victim = self:GetTrappedPlayer()
    if IsValid(victim) then
        clearPin(victim)
        if victim.Notify then
            victim:Notify("Сука, ненавижу капканы . . .", 4, "pat_beartrap", 1, nil, Color(120, 220, 140))
        end
    end

    self:SetTrappedPlayer(NULL)
    self:SetTrappedLimb(0)
    self.ReleaseHold = {}
    self.NextBleed = 0
    self:OpenTrap()

    if opener and opener.Notify and opener ~= victim then
        --opener:Notify("Капкан открыт.", 3, "pat_beartrap", 1)
    end

    self:SetNextRearm(CurTime() + PAT_BEARTRAP.RearmTime)
    timer.Simple(PAT_BEARTRAP.RearmTime, function()
        if not IsValid(self) or self:HasVictim() then return end
        if self:GetNextRearm() > CurTime() then return end
        self:ArmTrap()
    end)
end

function ENT:TriggerVictim(victimEnt)
    local victim = resolveVictim(victimEnt)
    local owner = self:GetTrapOwner()

    self.NextTrigger = CurTime() + 0.75
    self.LastVictim = victim
    self.LastVictimUntil = CurTime() + 2.5
    self:CloseTrap()

    setSequenceSafe(self, "Snap")
    self:EmitSound(PAT_BEARTRAP.Sound, 75, 100)

    timer.Simple(0.18, function()
        if IsValid(self) then
            self:CloseTrap()
        end
    end)

    if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() or not victim.organism then
        if IsValid(victimEnt) then
            local dmg = DamageInfo()
            dmg:SetDamage(PAT_BEARTRAP.NPCDamage)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(IsValid(owner) and owner or self)
            dmg:SetInflictor(self)
            victimEnt:TakeDamageInfo(dmg)
        end

        return
    end

    local limb = chooseLimb(victim, self:GetPos())
    if not limb or victim.organism[limb .. "amputated"] then
        applyOrganismTrapDamage(victim, limb, true)
        return
    end

    applyClampWounds(victim, limb, self)
    self:PinVictim(victim, limb)

    if IsValid(owner) and owner ~= victim then
        PAT_BEARTRAP.PunishGrief(owner, victim)
    end
end

function ENT:TryRelease()
    if not self:HasVictim() then return end

    local need = PAT_BEARTRAP.ReleaseTime
    local hold = self.ReleaseHold

    for _, ply in ipairs(player.GetAll()) do
        if playerReleasing(ply, self) then
            hold[ply] = hold[ply] or CurTime()
            if CurTime() - hold[ply] >= need then
                self:ReleaseVictim(ply)
                return
            end
        else
            hold[ply] = nil
        end
    end
end

function ENT:MaintainVictim()
    local victim = self:GetTrappedPlayer()
    if not IsValid(victim) or not victim:Alive() or not victim.organism then
        self:ReleaseVictim()
        return
    end

    local limb = PAT_BEARTRAP.LimbFromId(self:GetTrappedLimb())
    if not limb or victim.organism[limb .. "amputated"] then
        self:ReleaseVictim()
        return
    end

    local inFake = IsValid(victim.FakeRagdoll)
    if self.BeartrapWasFake and not inFake then
        PAT_BEARTRAP.AlignVictimToTrap(victim, self, limb)
    end
    self.BeartrapWasFake = inFake

    self:UpdateLegWeld(victim, limb)

    if CurTime() >= self.NextBleed then
        self.NextBleed = CurTime() + PAT_BEARTRAP.BleedInterval
        bleedTick(victim, limb, self)
    end
end

function ENT:Touch(toucher)
    if not IsValid(self) or not self:GetArmed() or self:HasVictim() then return end
    if self.NextTrigger > CurTime() then return end
    if not IsValid(toucher) then return end

    local victim = resolveVictim(toucher)
    if IsValid(victim) and victim == self.LastVictim and self.LastVictimUntil > CurTime() then return end

    if IsValid(victim) then
        if not self:CanTriggerVictim(victim) then return end
        self:TriggerVictim(victim)
        return
    end

    if toucher:IsNPC() then
        self:TriggerVictim(toucher)
    end
end

function ENT:Think()
    if self:HasVictim() then
        self:MaintainVictim()
        self:TryRelease()
    elseif self:GetArmed() and self.NextTrigger <= CurTime() then
        for _, ent in ipairs(ents.FindInSphere(self:GetPos(), self.ScanRadius)) do
            if ent == self then continue end

            local victim = resolveVictim(ent)
            if IsValid(victim) then
                if victim ~= self.LastVictim or self.LastVictimUntil <= CurTime() then
                    if self:CanTriggerVictim(victim) then
                        self:TriggerVictim(victim)
                        break
                    end
                end
            elseif ent:IsNPC() then
                self:TriggerVictim(ent)
                break
            end
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:Use(act)
    if not IsValid(act) or not act:IsPlayer() then return end
    if self:HasVictim() then return end
    if act:HasWeapon("weapon_beartrap_homigrad") then return end

    act:Give("weapon_beartrap_homigrad")
    self:Remove()
end

hook.Add("SetupMove", "pat_beartrap_pin", function(ply, mv)
    local trap = ply.PAT_BeartrapTrap
    if not IsValid(trap) or not trap:HasVictim() or trap:GetTrappedPlayer() ~= ply then
        return
    end

    if IsValid(ply.FakeRagdoll) then return end

    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)

    local vel = mv:GetVelocity()
    mv:SetVelocity(Vector(0, 0, vel.z))

    local buttons = mv:GetButtons()
    buttons = bit.band(buttons, bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_JUMP))
    mv:SetButtons(buttons)
end)


local function dropTrapPin(ply)
    if not IsValid(ply) then return end
    local trap = ply.PAT_BeartrapTrap
    if IsValid(trap) then
        trap:ReleaseVictim()
    else
        clearPin(ply)
    end
end

hook.Add("PlayerDeath", "pat_beartrap", dropTrapPin)
hook.Add("PlayerDisconnected", "pat_beartrap", dropTrapPin)
