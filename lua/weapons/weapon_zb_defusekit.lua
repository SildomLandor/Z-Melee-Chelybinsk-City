if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Набор разминирования"
SWEP.Instructions = "Наведись на бомбу и зажми E"
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
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/props_lab/reciever01d.mdl"
SWEP.Slot = 5
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.WorkWithFake = true
SWEP.ModelScale = 0.45
SWEP.HandScale = 0.35
SWEP.offsetVec = Vector(3, -1, -1)
SWEP.offsetAng = Angle(0, 180, -90)
SWEP.DefuseTime = 15
SWEP.DefuseRange = 110
SWEP.DefuseAimDot = 0.82

if CLIENT then
	SWEP.IconOverride = "vgui/wep_jack_hmcd_c4_charge"
	SWEP.BounceWeaponIcon = false
end

local function a(e)
	return IsValid(e) and (e.active or e:GetNetVar("timer"))
end

local function b()
	if zb and a(zb.bomb) then return zb.bomb end
	for _, e in ipairs(ents.FindByClass("bomb")) do if a(e) then return e end end
end

local function k(p, n)
	return (hg and hg.KeyDown and hg.KeyDown(p, n)) or p:KeyDown(n)
end

function SWEP:SetHold(v)
	self:SetWeaponHoldType(v)
	self:SetHoldType(v)
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
end

function SWEP:Deploy()
	self:SetHold(self.HoldType)
	if SERVER then
		local p, e = self:GetOwner(), zb and zb.bomb
		if IsValid(p) and IsValid(e) and e.CloseBombPanel then e:CloseBombPanel(p) end
	end
	return true
end

function SWEP:CanDrop()
	return false
end

function SWEP:DrawWorldModel()
	self:DrawWorldModel2()
end

function SWEP:DrawWorldModel2()
	self.m = IsValid(self.m) and self.m or ClientsideModel(self.WorldModel)
	local m, o = self.m, self:GetOwner()
	m:SetNoDraw(true)
	local r = IsValid(o) and hg.GetCurrentCharacter(o) or o
	m:SetModelScale(IsValid(r) and (self.HandScale or 0.35) or (self.ModelScale or 0.45))
	if IsValid(r) then
		local i = r:LookupBone("ValveBiped.Bip01_R_Hand")
		if i then
			local x = r:GetBoneMatrix(i)
			if x then
				local p, g = LocalToWorld(self.offsetVec, self.offsetAng, x:GetTranslation(), x:GetAngles())
				m:SetPos(p)
				m:SetAngles(g)
				m:SetupBones()
				m:DrawModel()
				return
			end
		end
	end
	m:SetPos(self:GetPos())
	m:SetAngles(self:GetAngles())
	m:DrawModel()
end

function SWEP:GetBombTrace()
	local p = self:GetOwner()
	if not IsValid(p) or not p:Alive() then return end
	local e = b()
	if not e then return end
	local c = e:WorldSpaceCenter()
	local d = c - p:GetShootPos()
	local l = d:Length()
	if l > self.DefuseRange or p:GetAimVector():Dot(d / l) < self.DefuseAimDot then return end
	local t = util.TraceLine({start = p:GetShootPos(), endpos = c, filter = {p, e}, mask = MASK_SOLID})
	if t.Entity ~= e and t.Fraction < 0.98 and t.HitPos:DistToSqr(c) > 28 * 28 then return end
	return e
end

function SWEP:CanDefuse()
	local p = self:GetOwner()
	return IsValid(p) and p:Alive() and p:Team() == 1 and self:GetBombTrace()
end

function SWEP:S()
	local p = self:GetOwner()
	if IsValid(p) then p:SetNWFloat("ZB_Defuse", 0) end
	local e = self.DefuseBomb
	if IsValid(e) and e.Defuser == p then e.Defuser = nil end
	self.DefuseBomb, self.DefuseStart = nil, nil
end

function SWEP:F(e)
	local p = self:GetOwner()
	if not a(e) or (e.Defuser and e.Defuser ~= p) then return end
	e:DisableBomb()
	e:SetNetVar("knowncode", "******")
	if IsValid(p) then
		p:ChatPrint("Бомба обезврежена.")
		p:EmitSound("buttons/button3.wav", 70, 100, 1, CHAN_ITEM)
	end
	self:S()
end

function SWEP:Think()
	self:SetHold(self.HoldType)
	if CLIENT then return end
	local p = self:GetOwner()
	if not IsValid(p) then return end
	local e = self:GetBombTrace()
	if not (k(p, IN_USE) and e) then if self.DefuseBomb then self:S() end return end
	if IsValid(e.Defuser) and e.Defuser ~= p then self:S() return end
	if p:GetVelocity():LengthSqr() > 80 * 80 then self:S() return end
	if self.DefuseBomb ~= e then
		self:S()
		self.DefuseBomb, self.DefuseStart = e, CurTime()
		e.Defuser = p
	end
	local f = math.Clamp((CurTime() - (self.DefuseStart or CurTime())) / self.DefuseTime, 0, 1)
	p:SetNWFloat("ZB_Defuse", f)
	if f >= 1 then self:F(e) end
	if not self.NextBeep or self.NextBeep < CurTime() then
		self.NextBeep = CurTime() + 0.45
		p:EmitSound("buttons/blip1.wav", 55, 120 - f * 30, 0.6, CHAN_WEAPON)
	end
end

function SWEP:Holster()
	self:S()
	return true
end

function SWEP:OnRemove()
	self:S()
end

SWEP.StopDefuse = SWEP.S
SWEP.FinishDefuse = SWEP.F

if CLIENT then
	local u, v = Color(120, 0, 0, 220), Color(0, 0, 0, 162)
	local s, c, h = "E — начать разминирование", Color(155, 0, 0), "HomigradFontMedium"

	local function d(x, y)
		draw.SimpleText(s, h, x + 1, y + 1, Color(0, 0, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(s, h, x, y, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local function n(w)
		local e = w:GetBombTrace()
		if not e then return end
		local z = e:WorldSpaceCenter():ToScreen()
		d(z.visible and z.x or ScrW() * 0.5, z.visible and z.y + 22 or ScrH() * 0.7)
	end

	hook.Add("HUDPaint", "weapon_zb_defusekit_hint", function()
		local p = LocalPlayer()
		if not IsValid(p) or not p:Alive() or p:GetNWFloat("ZB_Defuse", 0) > 0 then return end
		local w = p:GetActiveWeapon()
		if IsValid(w) and w:GetClass() == "weapon_zb_defusekit" then n(w) end
	end)

	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		local f = self:GetOwner():GetNWFloat("ZB_Defuse", 0)
		if f <= 0 then return end
		local w, y = 220, ScrH() * 0.58
		local x = ScrW() * 0.5 - w * 0.5
		surface.SetDrawColor(v)
		surface.DrawRect(x - 2, y - 2, w + 4, 18)
		surface.SetDrawColor(u)
		surface.DrawRect(x, y, w * f, 14)
		draw.SimpleText("Разминирование", h, ScrW() * 0.5, y - 18, color_white, TEXT_ALIGN_CENTER)
	end
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

if SERVER then
	hook.Add("PlayerDeath", "zb_defusekit_stop", function(p)
		p:SetNWFloat("ZB_Defuse", 0)
		local e = zb and zb.bomb
		if IsValid(e) and e.Defuser == p then e.Defuser = nil end
	end)
end
