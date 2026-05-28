
if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "M-99"
SWEP.Instructions = "Эторфин (Immobilon или M99) — это полусинтетический опиоид, обладающий анальгетической активностью, примерно в 1000–3000 раз превышающей таковую у морфина.\nRMB ввести инъекцию другому человеку."
SWEP.Category = "Medicine"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/cof/weapons/syringe/w_syringe.mdl"
SWEP.Model = "models/cof/weapons/syringe/w_syringe.mdl"

if CLIENT then
	SWEP.WepSelectIcon = Material("cof/vgui/weapons/syringe/640_syringe_slot")
	SWEP.IconOverride = "cof/vgui/weapons/syringe/640_syringe_slot"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 3
SWEP.SlotPos = 4
SWEP.WorkWithFake = false
SWEP.offsetVec = Vector(2.8, -0.9, -1)
SWEP.offsetAng = Angle(-30, 30, 180)
SWEP.ModelScale = 0.5

if SERVER then
    function SWEP:OnRemove() end
end

function SWEP:DrawWorldModel()
	render.SetColorModulation(255,255,255)
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.Model)
	local WorldModel = self.model
	local owner = self:GetOwner()
	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale or 1)
	if IsValid(owner) then
		local offsetVec = self.offsetVec
		local offsetAng = self.offsetAng
		local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if not boneid then return end
		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end
		local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
	end

	WorldModel:DrawModel()
	render.SetColorModulation(1,1,1)
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:Think()
	self:SetHold(self.HoldType)
end

SWEP.traceLen = 5

function SWEP:GetEyeTrace()
	return hg.eyeTrace( self:GetOwner())
end

local caninjectbone = {
    ["ValveBiped.Bip01_Spine"] = true,
}

if CLIENT then
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		if LocalPlayer():InVehicle() then return end
        local tr = self:GetEyeTrace()
        local toScreen = tr.HitPos:ToScreen()
        if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsRagdoll()) and caninjectbone[tr.Entity:GetBoneName(tr.PhysicsBone)] then
            draw.SimpleText( "Вколоть (Быстро наступит потеря сознания.)", "DermaLarge", toScreen.x, toScreen.y+25, Color(255,0,0,255), TEXT_ALIGN_CENTER )
            surface.SetDrawColor(195,0,0,155)
            surface.DrawRect(toScreen.x-2.5, toScreen.y-2.5, 5, 5)
		elseif IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsRagdoll()) and not caninjectbone[tr.Entity:GetBoneName(tr.PhysicsBone)] then
            draw.SimpleText( "Вколоть (Медленно наступит потеря сознания.)", "DermaLarge", toScreen.x, toScreen.y+25, Color(255,0,0,255), TEXT_ALIGN_CENTER )
            surface.SetDrawColor(195,0,0,155)
            surface.DrawRect(toScreen.x-2.5, toScreen.y-2.5, 5, 5)
        end
	end
end

function SWEP:DoPoison(ply, fast)
    local org = ply.organism
    local Owner = self:GetOwner()

	if not fast then
		org.tranquilizer = 1
	else
		org.consciousness = 0
	end

    Owner:EmitSound("snd_jack_hmcd_needleprick.wav",30)

	self.Tries = self.Tries - 1
	if self.Tries <= 0 then
		self:Remove()
		Owner:SelectWeapon("weapon_hands_sh")
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	self.Tries = 1
end

function SWEP:PrimaryAttack()
	if SERVER then
        local tr = self:GetEyeTrace()

        if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsRagdoll()) then
            local ply = tr.Entity
            if IsValid(ply) then
                self:DoPoison(ply, caninjectbone[tr.Entity:GetBoneName(tr.PhysicsBone)] ~= nil and true or false)
            end
        end
	end
end

function SWEP:Reload()
end