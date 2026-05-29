if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Бомба"
SWEP.Instructions = "ЛКМ - положить бомбу"
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
SWEP.WorldModel = "models/jmod/explosives/bombs/c4/w_c4_planted.mdl"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_c4_charge")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_c4_charge"
	SWEP.BounceWeaponIcon = false
end

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.WorkWithFake = true
SWEP.ModelScale = 0.5
SWEP.HandScale = 0.28
SWEP.offsetVec = Vector(5, -1, -0.6)
SWEP.offsetAng = Angle(0, 180, -90)

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:ApplyScale()
	self:SetModelScale(self.ModelScale, 0)
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	if SERVER then
		self:ApplyScale()
	end
end

function SWEP:OnDrop()
	if SERVER then
		self:ApplyScale()
	end
end

function SWEP:Think()
	self:SetHold(self.HoldType)
end

function SWEP:DrawWorldModel()
	self:DrawWorldModel2()
end

function SWEP:DrawWorldModel2()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local mdl = self.model
	mdl:SetNoDraw(true)
	local owner = self:GetOwner()
	local renderGuy = IsValid(owner) and hg.GetCurrentCharacter(owner) or owner
	local scale = IsValid(renderGuy) and (self.HandScale or 0.28) or (self.ModelScale or 0.5)
	mdl:SetModelScale(scale)

	if IsValid(renderGuy) then
		local boneid = renderGuy:LookupBone("ValveBiped.Bip01_R_Hand")
		if not boneid then return end
		local matrix = renderGuy:GetBoneMatrix(boneid)
		if not matrix then return end

		local pos, ang = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		mdl:SetPos(pos)
		mdl:SetAngles(ang)
		mdl:SetupBones()
	else
		mdl:SetPos(self:GetPos())
		mdl:SetAngles(self:GetAngles())
	end

	mdl:DrawModel()
end

function SWEP:GetEyeTrace()
	return hg.eyeTrace(self:GetOwner())
end

function SWEP:CanPlant()
	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:Alive() then return false end
	if IsValid(zb.bomb) then return false end

	local tr = self:GetEyeTrace()
	if not tr or not tr.Hit then return false end
	if ply:GetShootPos():DistToSqr(tr.HitPos) > 90 * 90 then return false end
	if tr.HitNormal.z < 0.55 then return false end

	return true, tr
end

if CLIENT then
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end

		local ok, tr = self:CanPlant()
		if not ok then return end

		local scr = tr.HitPos:ToScreen()
		if not scr.visible then return end

		draw.SimpleText("ЛКМ — положить", "HomigradFontMedium", scr.x + 1, scr.y + 26, color_black, TEXT_ALIGN_CENTER)
		draw.SimpleText("ЛКМ — положить", "HomigradFontMedium", scr.x, scr.y + 25, Color(190, 40, 40), TEXT_ALIGN_CENTER)
	end
end

local plantHullMins = Vector(-5, -5, -1)
local plantHullMaxs = Vector(5, 5, 7)

local function bombSpawnPos(tr, filter)
	local nrm = tr.HitNormal
	local pos = tr.HitPos

	local flush = util.TraceHull({
		start = pos + nrm * 14,
		endpos = pos + nrm * 0.6,
		mins = plantHullMins,
		maxs = plantHullMaxs,
		filter = filter,
		mask = MASK_SOLID,
	})
	if flush.Hit then
		pos = flush.HitPos + flush.HitNormal * 0.9
		nrm = flush.HitNormal
	end

	if nrm.z > 0.65 then
		for i = 0, 7 do
			local dir = Vector(math.cos(math.rad(i * 45)), math.sin(math.rad(i * 45)), 0)
			local from = pos + Vector(0, 0, 5)
			local wall = util.TraceLine({
				start = from,
				endpos = from + dir * 20,
				filter = filter,
				mask = MASK_SOLID,
			})
			if wall.Hit then
				pos = pos - dir * (20 - from:Distance(wall.HitPos) + 6)
			end
		end
	end

	return pos, nrm
end

local function SpawnBomb(ply, hitPos, hitNormal)
	local ent = ents.Create("bomb")
	if not IsValid(ent) then return end

	ent.PlantNormal = hitNormal
	ent:SetPos(hitPos)
	ent:Spawn()
	ent.PlantNormal = hitNormal

	local round = CurrentRound and CurrentRound()
	if round then
		ent.tbl = round
	end

	zb.bomb = ent
	ply.bomb = ent

	net.Start("bomb_look")
	net.WriteEntity(ent)
	net.Send(ply)

	return ent
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.6)
	if CLIENT then return end

	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:Alive() then return end
	if IsValid(zb.bomb) then
		ply:ChatPrint("Бомба уже в раунде.")
		return
	end

	local tr = util.TraceHull({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 90,
		filter = ply,
		mins = plantHullMins,
		maxs = plantHullMaxs,
		mask = MASK_SOLID
	})

	if not tr.Hit or tr.HitNormal.z < 0.55 then
		ply:ChatPrint("Смотри на пол рядом с собой.")
		return
	end

	local pos, nrm = bombSpawnPos(tr, ply)
	local ent = SpawnBomb(ply, pos, nrm)
	if not IsValid(ent) then return end

	ply:EmitSound("snd_jack_hmcd_bombrig.wav", 60, 100, 1, CHAN_ITEM)
	ply:SelectWeapon("weapon_hands_sh")
	self:Remove()
end

function SWEP:SecondaryAttack()
	self:PrimaryAttack()
end
