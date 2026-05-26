if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Шприц диверсанта"
SWEP.Instructions = "Парализует жертву за несколько секунд. Нельзя говорить. Через минуту — шок и удушье. 3 заряда."
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
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/tfa_ins2/upgrades/phy_optic_eotech.mdl"
SWEP.Model = "models/weapons/w_models/w_jyringe_proj.mdl"
SWEP.MaxUses = 3

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_poisonneedle")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_poisonneedle"
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
SWEP.offsetVec = Vector(5, -1.5, -0.6)
SWEP.offsetAng = Angle(0, 0, 0)
SWEP.ModelScale = 0.5

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "UsesLeft")
	if SERVER then
		self:SetUsesLeft(self.MaxUses)
	end
end

function SWEP:DrawWorldModel()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.Model)
	local WorldModel = self.model
	local owner = self:GetOwner()
	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale or 1)
	if IsValid(owner) then
		local boneid = owner:LookupBone(((owner.organism and owner.organism.rarmamputated) or (owner.zmanipstart ~= nil and owner.zmanipseq == "interact" and not owner.organism.larmamputated)) and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")
		if not boneid then return end
		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end
		local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
	end
	WorldModel:DrawModel()
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

local injectBones = {
	["ValveBiped.Bip01_Spine"] = true,
	["ValveBiped.Bip01_Spine1"] = true,
	["ValveBiped.Bip01_Spine2"] = true,
	["ValveBiped.Bip01_Neck1"] = true,
}

function SWEP:CanInject(ent, bone)
	local matrix = ent:GetBoneMatrix(ent:TranslatePhysBoneToBone(bone))
	if not matrix then return false end
	local TrueVec = (self:GetOwner():GetPos() - ent:GetPos()):GetNormalized()
	local LookVec = ent:GetAngles():Forward()
	local DotProduct = LookVec:DotProduct(TrueVec)
	local ApproachAngle = (-math.deg(math.asin(DotProduct)) + 90)
	return ApproachAngle >= 90
end

if CLIENT then
	local colred = Color(190, 40, 40)
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		if LocalPlayer():InVehicle() then return end
		local tr = self:GetEyeTrace()
		local toScreen = tr.HitPos:ToScreen()
		local ply = tr.Entity
		if IsValid(ply) and (ply:IsPlayer() or ply:IsRagdoll()) and injectBones[ply:GetBoneName(ply:TranslatePhysBoneToBone(tr.PhysicsBone))] and self:CanInject(ply, tr.PhysicsBone) then
			draw.SimpleText("Inject (" .. self:GetUsesLeft() .. ")", "HomigradFont", toScreen.x + 3, toScreen.y + 27, color_black, TEXT_ALIGN_CENTER)
			draw.SimpleText("Inject (" .. self:GetUsesLeft() .. ")", "HomigradFont", toScreen.x, toScreen.y + 25, colred, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(195, 0, 0, 155)
			surface.DrawRect(toScreen.x - 2.5, toScreen.y - 2.5, 5, 5)
		else
			surface.SetDrawColor(255, 255, 255, 155)
			surface.DrawRect(toScreen.x - 2.5, toScreen.y - 2.5, 5, 5)
		end
	end
end

if SERVER then
	function SWEP:DoInject(victim)
		local owner = self:GetOwner()
		if not IsValid(victim) then return end
		victim = hg.RagdollOwner(victim) or victim
		if not victim:IsPlayer() or not victim:Alive() or not victim.organism then return end

		local org = victim.organism
		org.diversant_syringe = CurTime()
		org.diversant_syringe_stage = 0
		org.diversant_syringe_mute = true

		owner:EmitSound("snd_jack_hmcd_needleprick.wav", 30)
		self:SetUsesLeft(math.max(self:GetUsesLeft() - 1, 0))
		if self:GetUsesLeft() <= 0 then
			self:Remove()
		end
		owner:SelectWeapon("weapon_hands_sh")
	end

	hook.Add("Org Clear", "DiversantSyringeClear", function(org)
		org.diversant_syringe = nil
		org.diversant_syringe_stage = nil
		org.diversant_syringe_mute = nil
	end)

	hook.Add("Org Think", "DiversantSyringeThink", function(owner, org)
		if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
		if not org.diversant_syringe or not org.alive then return end
		local t = CurTime()
		local injected = org.diversant_syringe

		if org.diversant_syringe_stage == 0 and injected + 3.5 <= t then
			org.diversant_syringe_stage = 1
			org.incapacitated = true
			hg.LightStunPlayer(owner, 90)
			org.stun = math.max(org.stun or 0, t + 90)
		end

		if org.diversant_syringe_stage == 1 and injected + 60 <= t then
			org.diversant_syringe_stage = 2
			org.shock = (org.shock or 0) + 40
			org.o2.regen = 0
			owner:Notify("Не могу... дышать...", true, "diversant_syringe", 4)
		end
	end)

	hook.Add("HG_PlayerCanHearPlayersVoice", "DiversantSyringeMute", function(listener, speaker)
		if IsValid(speaker) and speaker.organism and speaker.organism.diversant_syringe_mute and speaker.organism.diversant_syringe_stage and speaker.organism.diversant_syringe_stage >= 1 then
			return false, false
		end
	end)

	hook.Add("CanListenOthers", "DiversantSyringeMuteChat", function(output, input, isChat)
		if IsValid(output) and output.organism and output.organism.diversant_syringe_mute and output.organism.diversant_syringe_stage and output.organism.diversant_syringe_stage >= 1 and isChat then
			return false
		end
	end)

	hook.Add("HG_PlayerSay", "DiversantSyringeMuteSay", function(ply, txt)
		if IsValid(ply) and ply.organism and ply.organism.diversant_syringe_mute and ply.organism.diversant_syringe_stage and ply.organism.diversant_syringe_stage >= 1 then
			txt[1] = ""
		end
	end)
end

function SWEP:PrimaryAttack()
	if SERVER then
		if self:GetUsesLeft() <= 0 then return end
		local tr = self:GetEyeTrace()
		local ent = tr.Entity
		if IsValid(ent) and (ent:IsPlayer() or ent:IsRagdoll()) and injectBones[ent:GetBoneName(ent:TranslatePhysBoneToBone(tr.PhysicsBone))] and self:CanInject(ent, tr.PhysicsBone) then
			self:DoInject(ent)
		end
	end
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
end
