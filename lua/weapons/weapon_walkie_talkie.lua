if SERVER then
	AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Телефон"
SWEP.Instructions = "Холодное стекло в руке — мой единственный и самый жуткий свидетель"
SWEP.Category = "ZCity Other"
SWEP.Spawnable = false
SWEP.AdminOnly = false

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

SWEP.IdleHoldType = "normal"
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

SWEP.Frequency = 107.8

SWEP.ScreenPosOffset = Vector(4.08, -0.9, 3.5)
SWEP.ScreenAngleOffset = Angle(2, -11, 75)

local screenW, screenH = 230, 300
local screenScale = 0.007

function SWEP:BippSound(ent, pitch)
	ent:EmitSound("radio/voip_end_transmit_beep_0" .. math.random(1, 8) .. ".wav", 35, pitch or 100)
end

function SWEP:Deploy()
	if SERVER then
		self:SetHudFrequency(self.Frequency)
		self.isOn = self.isOn or false
		self:SetIsOn(self.isOn)
	end
	return true
end

function SWEP:RemoveCSModel()
	if CLIENT then
		if self.ClosePhoneMouse then self:ClosePhoneMouse() end
		if IsValid(self.phoneUI) then
			self.phoneUI:Remove()
			self.phoneUI = nil
		end
		if IsValid(self.model) then
			self.model:Remove()
			self.model = nil
		end
	end
end

function SWEP:Holster(wep)
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		self:BoneSet("l_upperarm", vector_origin, angle_zero)
		self:BoneSet("l_forearm", vector_origin, angle_zero)
		self:BoneSet("ValveBiped.Bip01_L_Hand", vector_origin, angle_zero)
	end

	self:RemoveCSModel()

	if SERVER and self.RemoveFake then
		self:RemoveFake()
	end

	return true
end

function SWEP:OnRemove()
	self:RemoveCSModel()
end

function SWEP:DrawWorldModel()
	if not IsValid(self:GetOwner()) then
		self:DrawWorldModel2()
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "HudFrequency")
	self:NetworkVar("Bool", 0, "IsOn")
end
local huy = Color(146, 146, 146)
local screen_fg = Color(0, 0, 0)
local screen_bg = Color(203, 208, 205)

if CLIENT then
	include("homigrad/!libraries/4_client/cl_3d2dvgui.lua")

	local phoneCamDist = 14
	local phoneCamFov = 26
	local phoneLookLimitP = 22
	local phoneLookLimitY = 32
	local phoneLookLag = 9

	surface.CreateFont("Walkie-Talkie_Fixed-Font", {
		font = "Ari-W9500",
		size = 64,
		weight = 600,
		outline = false
	})

	surface.CreateFont("Walkie-Talkie_Fixed-SmallFont", {
		font = "Ari-W9500",
		size = 50,
		weight = 600,
		outline = false
	})

	function SWEP:CreatePhoneUI()
		if IsValid(self.phoneUI) then return end

		local pnl = vgui.Create("DPanel")
		pnl:SetPos(-screenW / 2, -screenH / 12)
		pnl:SetSize(screenW, screenH)
		pnl:SetPaintBackground(false)

		local wep = self
		pnl.Paint = function(_, pw, ph)
			draw.RoundedBox(10, 0, 0, pw, ph, screen_bg)
			if not wep:GetIsOn() then return end

			draw.SimpleText("Телефон", "Walkie-Talkie_Fixed-Font", pw / 2 + 3, 24, screen_fg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local btn = vgui.Create("DButton", pnl)
		btn:SetSize(160, 44)
		btn:SetPos((screenW - 160) / 2, 200)
		btn:SetText("тест")
		btn:SetTextColor(Color(0, 0, 0))

		pnl.Think = function()
			if not IsValid(wep) or not IsValid(wep:GetOwner()) or wep:GetOwner():GetActiveWeapon() ~= wep or not wep:GetIsOn() then
				wep:ClosePhoneMouse()
			end
		end

		self.phoneUI = pnl
	end

	function SWEP:PhoneVirtPoint()
		local look = self.phoneLookSmooth or angle_zero
		local lx = screenW * 0.5 + (look.y / phoneLookLimitY) * (screenW * 0.42)
		local ly = screenH * 0.5 + (look.p / phoneLookLimitP) * (screenH * 0.35)
		return lx, ly
	end

	function SWEP:PhoneTryClick()
		local lx, ly = self:PhoneVirtPoint()
		local bx, by = (screenW - 160) / 2, 200
		if lx >= bx and lx <= bx + 160 and ly >= by and ly <= by + 44 then
			print("nazhato")
			return true
		end
		return false
	end

	function SWEP:OpenPhoneMouse()
		if self.phoneMouseMode or not self:GetIsOn() then return end
		self:CreatePhoneUI()
		self.phoneMouseMode = true
		self.phoneLookTarget = Angle()
		self.phoneLookSmooth = Angle()
		self.phoneMouseDX = 0
		self.phoneMouseDY = 0
		self.phoneAttackDown = false
		gui.EnableScreenClicker(false)
		if IsValid(self.phoneUI) then
			self.phoneUI:SetMouseInputEnabled(false)
		end
	end

	function SWEP:ClosePhoneMouse()
		if not self.phoneMouseMode then return end
		self.phoneMouseMode = false
		self.phoneAttackDown = false
		gui.EnableScreenClicker(false)
	end

	local function WalkiePhoneShouldCloseOnMove(wep, cmd)
		local owner = wep:GetOwner()
		if not IsValid(owner) or not owner:IsPlayer() then return false end
		if not owner:OnGround() then return true end
		if owner:IsTyping() or owner:IsFlagSet(FL_ANIMDUCKING) then return true end
		if owner:GetVelocity():LengthSqr() > 1000 then return true end
		if cmd then
			return cmd:KeyDown(IN_FORWARD) or cmd:KeyDown(IN_BACK) or cmd:KeyDown(IN_MOVELEFT) or cmd:KeyDown(IN_MOVERIGHT)
		end
		return false
	end

	local function WalkiePhoneCamWanted(wep, cmd)
		if not wep.phoneMouseMode or not wep:GetIsOn() then return false end
		return not WalkiePhoneShouldCloseOnMove(wep, cmd)
	end

	function SWEP:PhoneCamWanted(cmd)
		return WalkiePhoneCamWanted(self, cmd)
	end

	function SWEP:PhoneShouldCloseOnMove(cmd)
		return WalkiePhoneShouldCloseOnMove(self, cmd)
	end

	function SWEP:UpdatePhoneScreenTransform()
		local ply = self:GetOwner()
		if not IsValid(ply) then return end

		local owner = hg.GetCurrentCharacter(ply)
		if not IsValid(owner) then return end

		local boneid = owner:LookupBone("ValveBiped.Bip01_L_Hand")
		if not boneid then return end

		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end

		self.phoneScreenPos, self.phoneScreenAng = LocalToWorld(self.ScreenPosOffset, self.ScreenAngleOffset, matrix:GetTranslation(), matrix:GetAngles())
	end

	function SWEP:UpdatePhoneLook()
		if not WalkiePhoneCamWanted(self) then return end

		self.phoneLookTarget = self.phoneLookTarget or Angle()
		self.phoneLookSmooth = self.phoneLookSmooth or Angle()

		local dx, dy = self.phoneMouseDX or 0, self.phoneMouseDY or 0
		self.phoneMouseDX, self.phoneMouseDY = 0, 0

		if dx ~= 0 or dy ~= 0 then
			self.phoneLookTarget.y = math.Clamp(self.phoneLookTarget.y - dx * 0.06, -phoneLookLimitY, phoneLookLimitY)
			self.phoneLookTarget.p = math.Clamp(self.phoneLookTarget.p + dy * 0.06, -phoneLookLimitP, phoneLookLimitP)
		end

		self.phoneLookSmooth = LerpAngle(FrameTime() * phoneLookLag, self.phoneLookSmooth, self.phoneLookTarget)
	end

	function SWEP:Camera(eyePos, eyeAng, view, vellen)
		self:UpdatePhoneScreenTransform()
		if not self.phoneScreenPos or not self.phoneScreenAng then return end

		local want = WalkiePhoneCamWanted(self) and 1 or 0
		self.phoneCamLerp = Lerp(FrameTime() * 7, self.phoneCamLerp or 0, want)

		if self.phoneCamLerp < 0.001 and want == 0 then
			self.phoneLookTarget = angle_zero
			self.phoneLookSmooth = angle_zero
			return
		end

		self.phoneLookTarget = self.phoneLookTarget or angle_zero
		self.phoneLookSmooth = self.phoneLookSmooth or self.phoneLookTarget
		if want == 0 then
			self.phoneLookTarget = LerpAngle(FrameTime() * phoneLookLag, self.phoneLookTarget, angle_zero)
			self.phoneLookSmooth = LerpAngle(FrameTime() * phoneLookLag, self.phoneLookSmooth, angle_zero)
		end

		local normal = self.phoneScreenAng:Up()
		local focusPos = self.phoneScreenPos + self.phoneScreenAng:Forward() * (screenH * 0.35 * screenScale)
		local camPos = focusPos + normal * phoneCamDist
		local lookAng = (-normal):Angle()
		lookAng.r = lookAng.r + math.rad(180)
		lookAng:Add(self.phoneLookSmooth)

		local k = self.phoneCamLerp
		view.origin = LerpVector(k, eyePos, camPos)
		view.angles = LerpAngle(k, eyeAng, lookAng)
		view.fov = Lerp(k, view.fov, phoneCamFov)

		return view
	end

	hook.Add("Think", "weapon_walkie_talkie_phone_look", function()
		local wep = LocalPlayer():GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_walkie_talkie" then return end
		if wep.UpdatePhoneLook then
			wep:UpdatePhoneLook()
		end
	end)

	hook.Add("CreateMove", "weapon_walkie_talkie_phone_mouse", function(cmd)
		local wep = LocalPlayer():GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_walkie_talkie" or not WalkiePhoneCamWanted(wep, cmd) then return end

		wep.phoneMouseDX = cmd:GetMouseX()
		wep.phoneMouseDY = cmd:GetMouseY()
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)

		if cmd:KeyDown(IN_ATTACK) then
			if not wep.phoneAttackDown then
				wep.phoneAttackDown = true
				wep:PhoneTryClick()
			end
		else
			wep.phoneAttackDown = false
		end

		cmd:RemoveKey(IN_ATTACK)
		cmd:RemoveKey(IN_ATTACK2)
	end)

	hook.Add("HUDPaint", "weapon_walkie_talkie_phone_crosshair", function()
		local wep = LocalPlayer():GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "weapon_walkie_talkie" or not WalkiePhoneCamWanted(wep) then return end
		if (wep.phoneCamLerp or 0) < 0.15 then return end

		local size = 6
		local cx, cy = math.floor(ScrW() * 0.5), math.floor(ScrH() * 0.5)
		surface.SetDrawColor(huy)
		surface.DrawRect(cx - size / 2, cy - size / 2, size, size)
	end)
end

function SWEP:DrawWorldModel2()
	local ply = self:GetOwner()
	if IsValid(ply) and ply:GetActiveWeapon() ~= self then return end

	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local mdl = self.model
	local owner = hg.GetCurrentCharacter(ply)

	mdl:SetNoDraw(true)
	mdl:SetModelScale(self.ModelScale or 1)

	if IsValid(owner) then
		local boneid = owner:LookupBone("ValveBiped.Bip01_L_Hand")
		if not boneid then return end

		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end

		local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		mdl:SetPos(newPos)
		mdl:SetAngles(newAng)
		mdl:SetupBones()
		mdl:DrawModel()

		newPos, newAng = LocalToWorld(self.ScreenPosOffset, self.ScreenAngleOffset, matrix:GetTranslation(), matrix:GetAngles())

		if CLIENT and self:GetIsOn() then
			self:CreatePhoneUI()
			if IsValid(self.phoneUI) then
				vgui.Start3D2D(newPos, newAng, screenScale)
					self.phoneUI:Paint3D2D()
				vgui.End3D2D()
			end
		else
			cam.Start3D2D(newPos, newAng, screenScale)
				draw.RoundedBox(10, -screenW / 2, -screenH / 12, screenW, screenH, screen_bg)
			cam.End3D2D()
		end
	else
		mdl:SetPos(self:GetPos())
		mdl:SetAngles(self:GetAngles())
		mdl:DrawModel()
	end
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:BoneSet(lookup_name, vec, ang)
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end
	hg.bone.Set(owner, lookup_name, vec, ang, "walkietalkie", 0.01)
end

local handAng3 = Angle(35, 20, -15)
local handAng1, handAng2 = Angle(-60, 0, 0), Angle(-20, -115, -60)

function SWEP:Step()
	local owner = self:GetOwner()
	if not IsValid(owner) or owner:GetActiveWeapon() ~= self then return end

	if not owner:OnGround() or owner:GetVelocity():LengthSqr() > 1000 or owner:IsTyping() or owner:IsFlagSet(FL_ANIMDUCKING) then
		return
	end

	local on = self:GetIsOn()
	self:BoneSet("l_upperarm", vector_origin, on and handAng1 or angle_zero)
	self:BoneSet("l_forearm", vector_origin, on and handAng2 or angle_zero)
	self:BoneSet("ValveBiped.Bip01_L_Hand", vector_origin, on and handAng3 or angle_zero)
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.25)
	if CLIENT and IsValid(LocalPlayer()) and LocalPlayer():GetActiveWeapon() == self then
		self:OpenPhoneMouse()
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then
		self:ClosePhoneMouse()
	end
end

function SWEP:Reload()
	local owner = self:GetOwner()
	if not SERVER or (self.turnOnCD and self.turnOnCD >= CurTime()) then return end

	self.turnOnCD = CurTime() + 0.5
	self.isOn = not self.isOn
	self:SetIsOn(self.isOn)
	self:BippSound(owner)
	owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	if SERVER then
		self.isOn = false
	end
end

if SERVER then
	function SWEP:SetFakeGun(ent)
		self:SetNWEntity("fakeGun", ent)
		self.fakeGun = ent
	end

	function SWEP:RemoveFake()
		if not IsValid(self.fakeGun) then return end
		self.fakeGun:Remove()
		self:SetFakeGun()
	end

	SWEP.RHandPos = Vector(0, 0, 0)

	function SWEP:CreateFake(ragdoll)
		if IsValid(self:GetNWEntity("fakeGun")) then return end

		local ent = ents.Create("prop_physics")
		local lh = ragdoll:GetPhysicsObjectNum(5)
		local rh = ragdoll:GetPhysicsObjectNum(7)

		rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
		rh:SetAngles(self:GetOwner():EyeAngles() + Angle(0, 0, -90))
		lh:SetPos(rh:GetPos())

		ent:SetModel(self.WorldModel)
		ent:SetPos(rh:GetPos())
		ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
		ent:Spawn()

		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetOwner(ragdoll)
		ent:GetPhysicsObject():SetMass(0)
		ent:SetNoDraw(true)
		ent.dontPickup = true
		ent.fakeOwner = self

		ragdoll:DeleteOnRemove(ent)
		ragdoll.fakeGun = ent

		if IsValid(ragdoll.ConsRH) then
			ragdoll.ConsRH:Remove()
		end

		self:SetFakeGun(ent)
		ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)

		local vec = Vector(0, 0, 0)
		vec:Set(-self.RHandPos or vector_origin)
		vec:Rotate(ent:GetAngles())

		rh:SetPos(ent:GetPos() + vec)
	end

	function SWEP:RagdollFunc(pos, angles, ragdoll)
		shadowControl = shadowControl or hg.ShadowControl
		shadowControl(ragdoll, 5, 0.001, angles, 500, 30, pos, 500, 50)
	end
end
