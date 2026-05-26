if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Рация-приманка"
SWEP.Instructions = "ПКМ — положить на пол. Издаёт звуки рации для приманки."
SWEP.Category = "ZCity Other"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "normal"
SWEP.ViewModel = "models/cof/weapons/mobile/v_mobile.mdl"
SWEP.WorldModel = "models/cof/weapons/mobile/w_mobile.mdl"

if CLIENT then
	SWEP.WepSelectIcon = Material("cof/vgui/weapons/mobile/640_mobile_slot")
	SWEP.IconOverride = "materials/entities/weapon_cof_mobile.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 5
SWEP.SlotPos = 5
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1, 1.9)
SWEP.offsetAng = Angle(-2, 170, 15)

function SWEP:DrawWorldModel()
	if not IsValid(self:GetOwner()) then
		self:DrawModel()
	end
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:Think()
	self:SetHold(self.HoldType)
end

function SWEP:GetEyeTrace()
	return hg.eyeTrace(self:GetOwner())
end

if CLIENT then
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		local tr = self:GetEyeTrace()
		if not tr then return end
		local toScreen = tr.HitPos:ToScreen()
		draw.SimpleText("ПКМ — поставить приманку", "HomigradFontMedium", toScreen.x + 1, toScreen.y + 26, color_black, TEXT_ALIGN_CENTER)
		draw.SimpleText("ПКМ — поставить приманку", "HomigradFontMedium", toScreen.x, toScreen.y + 25, Color(190, 40, 40), TEXT_ALIGN_CENTER)
	end
end

if SERVER then
	function SWEP:PlaceDecoy()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end
		local tr = self:GetEyeTrace()
		if not tr or not tr.Hit then return end

		local ent = ents.Create("ent_traitor_decoy_radio")
		if not IsValid(ent) then return end
		ent:SetPos(tr.HitPos + tr.HitNormal * 2)
		ent:SetAngles(Angle(0, owner:EyeAngles().y, 0))
		ent:Spawn()
		ent:Activate()
		ent:SetOwner(owner)

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
		end

		owner:EmitSound("npc/footsteps/softshoe_generic6.wav", 45, math.random(95, 105), 0.4, CHAN_ITEM)
		self:Remove()
		owner:SelectWeapon("weapon_hands_sh")
	end
end

function SWEP:SecondaryAttack()
	if SERVER then
		self:PlaceDecoy()
	end
	self:SetNextSecondaryFire(CurTime() + 1)
end

function SWEP:PrimaryAttack()
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
end
