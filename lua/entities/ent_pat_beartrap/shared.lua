ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Bear Trap"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Armed")
    self:NetworkVar("Entity", 0, "TrapOwner")
    self:NetworkVar("Entity", 1, "TrappedPlayer")
    self:NetworkVar("Int", 0, "TrappedLimb")
    self:NetworkVar("Float", 0, "NextRearm")

    if CLIENT then
        self:NetworkVarNotify("TrappedPlayer", self.OnTrappedPlayerChanged)
    end
end

function ENT:HasVictim()
    return IsValid(self:GetTrappedPlayer())
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end
