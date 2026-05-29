SWEP.Base = "weapon_revolver2"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "RSh-12"
SWEP.Author = "KBP"
SWEP.Instructions = "Револьвер 12.7x55"
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.WorldModelFake = "models/weapons/arc9/darsu_eft/c_rsh12.mdl"
SWEP.FakeBodyGroups = "0111111000000"
SWEP.CustomAmmoInsertEvent = true

SWEP.FakePos = Vector(-20, 4, 7)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.FakeAttachment = "1"
SWEP.AttachmentPos = Vector(0, 0, 0)
SWEP.AttachmentAng = Angle(0, 0, 0)

SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "entities/eft_ash12_attachments/cyl.png"

SWEP.weight = 2.2
SWEP.punchmul = 14
SWEP.punchspeed = 0.55
SWEP.podkid = 5
SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 2

SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "12.7x55 mm"
SWEP.Primary.Damage = 70
SWEP.Primary.Force = 70
SWEP.Primary.Wait = 0.45
SWEP.Primary.Cone = 0
SWEP.Primary.Spread = 0
SWEP.ReloadTime = 4.5
SWEP.Penetration = 9
SWEP.Ergonomics = 0.85
SWEP.OpenBolt = true
SWEP.ShellEject = false
SWEP.CustomShell = "50cal"
SWEP.PPSMuzzleEffect = "muzzleflash_pistol_deagle"

SWEP.Primary.Sound = {"weapons/darsu_eft/rsh12/rsh_12_outdoor_close_oneshot.wav", 80, 95, 100}
SWEP.SupressedSound = {"weapons/darsu_eft/rsh12/rsh_12_outdoor_close_oneshot.wav", 70, 95, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/revolver/handling/revolver_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.DistSound = "m9/m9_dist.wav"

SWEP.LocalMuzzlePos = Vector(14, 0, 3)
SWEP.LocalMuzzleAng = Angle(0, 0, 0)
SWEP.ZoomPos = Vector(-3, 0, 5)
SWEP.HoldType = "revolver"
SWEP.AimHold = "revolver"
SWEP.UseCustomWorldModel = true
SWEP.WorldPos = Vector(5, -1.2, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.shouldntDrawHolstered = true

SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor4", Vector(0, 0, 0), {}},
		["mount"] = Vector(0.4, 0.7, 0),
	},
}

SWEP.AnimList = {
	["idle"] = "idle",
}

local DRUM = 5

function SWEP:CylIdx()
	return self:GetNWInt("drumroll", 0) % DRUM
end

function SWEP:CylIdxFire()
	return (self:GetNWInt("drumroll", 0) - 1) % DRUM
end

function SWEP:Rsh12Seq(name)
	if string.find(name, "__", 1, true) then return name end
	if string.find(name, "_insert", 1, true) then return name end
	if name == "sg_reload_end" or string.find(name, "fistful_end", 1, true) then return name end
	if string.find(name, "fire_da", 1, true) then return name end
	return name .. "__" .. self:CylIdx()
end

function SWEP:ShiftDrum(val, dry)
	val = math.Round(val % DRUM)
	if val == 0 then val = 1 end

	local drumCopy = table.Copy(self.Drum)
	for i = 1, #self.Drum do
		local nextval = i + val
		local setval = nextval < 1 and DRUM - nextval or nextval > DRUM and nextval - DRUM or nextval
		self.Drum[i] = drumCopy[setval]
	end

	local s = ""
	for i = 1, #self.Drum do s = s .. tostring(self.Drum[i]) .. " " end

	self:SetNWInt("drumroll", self:GetNWInt("drumroll", 0) + val)
	self:SetNWString("drum", s)
	if dry ~= nil then self:Rsh12FireAnim(dry) end
end

function SWEP:Rsh12FireAnim(dry)
	local r = self:CylIdxFire()
	local seq = dry and ("fire_da_dry__" .. r) or ("fire_da__" .. r)
	self:PlayAnim(seq, 0.32, false, function()
		if IsValid(self) and not self.reload then
			self:PlayAnim("idle", 1, not self.NoIdleLoop)
		end
	end)
end

function SWEP:PlayAnim(anim, data, cycling, callback, reverse, sendtoclient)
	local base = self.AnimList[anim] or anim
	anim = self:Rsh12Seq(base)
	return self.BaseClass.PlayAnim(self, anim, data, cycling, callback, reverse, sendtoclient)
end

function SWEP:Shoot(override)
	if not self:CanPrimaryAttack() then return false end
	if self:KeyDown(IN_USE) and not IsValid(self:GetOwner().FakeRagdoll) then return false end
	if not self:CanUse() then return false end
	if CLIENT and self:GetOwner() ~= LocalPlayer() and not override then return false end

	local primary = self.Primary
	if primary.Next > CurTime() then return false end
	if (primary.NextFire or 0) > CurTime() then return false end

	self.Drum = SERVER and self.Drum or CLIENT and self:GetDrum()

	if self.Drum[1] ~= 1 then
		self.LastPrimaryDryFire = CurTime()
		self:PrimaryShootEmpty()
		primary.Automatic = false
		self:ShiftDrum(1, true)
		self.shooanim = 1
		return false
	end

	self.Drum[1] = -1
	self:ShiftDrum(1, false)

	primary.Next = CurTime() + primary.Wait
	self:SetLastShootTime(CurTime())
	primary.Automatic = weapons.Get(self:GetClass()).Primary.Automatic
	self:PrimaryShoot()
	self:PrimaryShootPost()
end

function SWEP:InitializePost()
	self.Drum = {1, 1, 1, 1, 1}
	self.reloadCoolDown = 0
	if SERVER then self:SetNWInt("drumroll", 0) end
end

function SWEP:ReloadEnd()
	self.ReloadNext = CurTime() + self.ReloadCooldown
	self:Draw()
end

function SWEP:InsertAmmo(need)
	need = need or 1
	local owner = self:GetOwner()
	if not owner.GetAmmoCount then return end

	local primaryAmmo = self:GetPrimaryAmmoType()
	local reserve = owner:GetAmmoCount(primaryAmmo)
	if reserve <= 0 or self:Clip1() >= self:GetMaxClip1() then return end

	need = math.min(need, reserve, self:GetMaxClip1() - self:Clip1())

	for _ = 1, need do
		for i = 1, DRUM do
			if self.Drum[i] ~= 1 then
				self.Drum[i] = 1
				break
			end
		end
	end

	self:SetClip1(self:Clip1() + need)
	owner:SetAmmo(reserve - need, primaryAmmo)

	if SERVER then
		self:SetNWInt("rsh12_vis", self:Clip1())
		net.Start("hg_insertAmmo")
		net.WriteEntity(self)
		net.WriteInt(self:Clip1(), 10)
		net.Broadcast()
		self:SendDrum()
	end

	if CLIENT and IsValid(self:GetWM()) then
		self:Rsh12Bgs(self:GetWM(), self:Clip1())
	end
end

function SWEP:Rsh12ReloadEnd()
	local clip = math.Clamp(self:Clip1(), 1, DRUM)
	local endSeq = self._rshFistful and ("fistful_end_r" .. clip) or "sg_reload_end"

	self:SetNWInt("drumroll", 0)
	self:PlayAnim(endSeq, 1.15, false, function()
		self:SetNetVar("shootgunReload", 0)
		self.reload = nil
		if SERVER then self:SetNWInt("rsh12_vis", self:Clip1()) end
		self:PlayAnim("idle", 1, not self.NoIdleLoop)
	end, false, true)
end

function SWEP:Rsh12ReloadInsert()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if self._rshInsertIdx >= self._rshInsertMax then
		self:Rsh12ReloadEnd()
		return
	end

	if self:Clip1() >= self:GetMaxClip1() or owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then
		self:Rsh12ReloadEnd()
		return
	end

	self._rshInsertIdx = self._rshInsertIdx + 1
	local seq = self._rshFistful and ("fistful_insert" .. self._rshInsertIdx) or ("sg_reload_insert" .. self._rshInsertIdx)

	self:PlayAnim(seq, 0.9, false, function()
		self:InsertAmmo(1)

		if hg.KeyDown(owner, IN_RELOAD) and self:CanReload() then
			self:Rsh12ReloadInsert()
			return
		end

		self:Rsh12ReloadEnd()
	end, false, true)
end

function SWEP:Rsh12ReloadStart()
	local owner = self:GetOwner()
	if not IsValid(owner) or not self:CanReload() then return end

	local clip = self:Clip1()
	self._rshFistful = clip == 0
	self._rshInsertIdx = 0
	self._rshInsertMax = self._rshFistful and DRUM or (DRUM - clip)

	for i = 1, DRUM do
		self.Drum[i] = i <= clip and 1 or 0
	end

	if SERVER then
		self:SendDrum()
		self:SetNWInt("drumroll", 0)
	end

	self:SetNetVar("shootgunReload", CurTime() + 12)
	self.dwr_reverbDisable = true

	local startSeq
	if self._rshFistful then
		startSeq = "fistful_start5__0"
	else
		-- ARC9: sg_reload_start{N} — N = сколько уже в барабане, не сколько вставлять
		startSeq = "sg_reload_start" .. math.Clamp(clip, 1, 5) .. "__0"
	end

	if SERVER then self:SetNWInt("rsh12_vis", 0) end

	self:PlayAnim(startSeq, 1.75, false, function()
		self:Rsh12ReloadInsert()
	end, false, true)
end

function SWEP:Reload(time)
	if self:GetNetVar("shootgunReload", 0) > CurTime() then return end
	if self.reloadCoolDown and self.reloadCoolDown > CurTime() then return end
	if not self:CanReload() then return end
	if SERVER then self:Rsh12ReloadStart() end
end

function SWEP:CanPrimaryAttack()
	if self:GetNetVar("shootgunReload", 0) > CurTime() then return false end
	return weapons.Get("homigrad_base").CanPrimaryAttack(self)
end

function SWEP:Rsh12Bgs(wm, n)
	if not IsValid(wm) then return end
	wm:SetBodygroup(1, 1)
	wm:SetBodygroup(2, 1)
	n = math.Clamp(n or self:Clip1(), 0, DRUM)
	for i = 0, DRUM - 1 do
		wm:SetBodygroup(3 + i, n > i and 1 or 0)
	end
end

function SWEP:ModelCreated(model)
	self:Rsh12Bgs(model, self:Clip1())
end

function SWEP:PostFireBullet(bullet)
	SlipWeapon(self, bullet)
end

if CLIENT then
	function SWEP:DrawPost()
		local wm = self:GetWM()
		if not IsValid(wm) then return end
		self:Rsh12Bgs(wm)
	end
end
