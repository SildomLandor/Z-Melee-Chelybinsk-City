if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Бинты"
SWEP.Instructions = "Комок марлевой повязки поможет остановить легкое кровотечение. Посколью повязка находится не в упаковке, вероятность того, что она стерилизована, мала. ПКМ, чтобы использовать его на ком-то другом."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/bandages.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_bandage")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_bandage.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.ScrappersSlot = "Medicine"

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -3.5, 0)
SWEP.offsetAng = Angle(90, 90, 0)

local hg_healanims = CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

modelshuy = modelshuy or {}

function SWEP:DrawWorldModel()
	if not IsValid(self:GetOwner()) then
		self:DrawWorldModel2()
	end
end

function SWEP:DrawWorldModel2(nodraw)
	if self.Color then
		render.SetColorModulation(self.Color.r/255,self.Color.g/255,self.Color.b/255)
	end

	local mdl = self.Model or self.WorldModel
	modelshuy[mdl] = IsValid(modelshuy[mdl]) and modelshuy[mdl] or ClientsideModel(mdl)
	modelshuy[mdl]:SetNoDraw(true)
	local WorldModel = modelshuy[mdl]
	local owner = self:GetOwner()
	owner = hg.GetCurrentCharacter(owner)
	if not IsValid(WorldModel) then return end

	for i = 1, #self:GetBodyGroups() do
		WorldModel:SetBodygroup(i, self:GetBodygroup(i))
	end

	if self.ModelScale then
		WorldModel:SetModelScale(self.ModelScale or 1)
	end
	if self.Color then
		WorldModel:SetColor(self.Color or color_white)
	end
	
	if IsValid(owner) then
		local offsetVec = self.offsetVec
		local offsetAng = self.offsetAng
		local boneid = owner:LookupBone(((owner.organism and owner.organism.rarmamputated) or (owner.zmanipstart ~= nil and owner.zmanipseq == "interact" and owner.organism and not owner.organism.larmamputated)) and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")
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

	WorldModel:SetupBones()

	if self.AfterDrawModel then
		self:AfterDrawModel(WorldModel,nodraw)
	end
	
	if not nodraw then WorldModel:DrawModel() end

	if self.Color then
		render.SetColorModulation(1,1,1)
	end
end

function SWEP:OnRemove()
	if SERVER then return end
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float",0,"Holding")
	if self.SetupDataTablesAdd then
		self:SetupDataTablesAdd()
	end
end

local bone, name
function SWEP:BoneSet(lookup_name, vec, ang)
	local owner = self:GetOwner()
    if IsValid(owner) and !owner:IsPlayer() then return end
	hg.bone.Set(owner, lookup_name, vec, ang, "bandage", 0.01)
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	local aimvec = self:GetOwner():GetAimVector()
	local hold = self:GetHolding()
	if owner.zmanipstart ~= nil and owner.organism and not owner.organism.larmamputated then return end
	self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 4, -30 + hold / 2 + 20 * aimvec[3], 5 - hold / 3.5))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 10, -hold / 2.5, 35 -hold/1.5))
end

SWEP.usetime = 2
local math = math

local function NormalizeModeValues(wep, values)
	local fallback = {}
	for i, def in ipairs(wep.modeValuesdef or {}) do
		fallback[i] = istable(def) and def[1] or def
	end
	if fallback[1] == nil then fallback[1] = 0 end

	if isnumber(values) then
		if #fallback > 1 then return fallback end
		fallback[1] = values
		return fallback
	end

	if not istable(values) then return fallback end

	for i = 1, #fallback do
		local val = values[i]
		if val == nil then
			values[i] = fallback[i]
		elseif istable(val) then
			values[i] = tonumber(val[1]) or fallback[i]
		else
			values[i] = tonumber(val) or fallback[i]
		end
	end
	return values
end

local function IsGradualInject(wep, mode)
	mode = mode or wep.mode or 1
	local def = wep.modeValuesdef and wep.modeValuesdef[mode]
	return istable(def) and def[2] == true
end

function SWEP:Think()
	self:SetHold(self.HoldType)

	if self:GetClass() == "weapon_bandage_sh" then
		self.ModelScale = math.Clamp(self.modeValues[1] / (self.modeValuesdef[1][1] * 0.8), 0.5, 1)
	end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local decay = not owner:KeyDown(IN_ATTACK)
	if CLIENT and hg.MouseMinigame and hg.MouseMinigame:IsActive() then
		local session = hg.MouseMinigame.ActiveSession
		if session and session.weapon == self then
			decay = false
		end
	end

	if decay and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end

	--[[if self.modeValuesdef[self.mode][2] then
		local time = CurTime()
		local ply = self:GetOwner()
		local entownr = hg.GetCurrentCharacter(ply)

		if not self.attack and ply:KeyPressed(IN_ATTACK) then
			self.startedheal = CurTime()
			self.healsubject = ply
			self.attack = 1
		end

		if self.attack == 1 and ply:KeyReleased(IN_ATTACK) then
			self.endheal = CurTime()
		end

		if not self.attack and ply:KeyPressed(IN_ATTACK2) then
			self.startedheal = CurTime()
			self.healsubject = hg.eyeTrace(self:GetOwner()).Entity
			self.attack = 2
		end

		if self.attack == 2 and ply:KeyReleased(IN_ATTACK2) then
			self.endheal = CurTime()
		end

		if self.startheal and (self.endheal or (self.startheal + self.usetime <= CurTime())) then
			self.endheal = self.endheal or self.startheal + self.usetime
			local usedmuch = (self.endheal - self.startheal) / self.usetime

			self:Heal(self.healsubject, self.mode, usedmuch)
			self.startheal = nil 
			self.endheal = nil 
			self.attack = nil 
			self.healsubject = nil
		end
	end--]]
end

function SWEP:CanUseOn(target)
	if self.CanHeal then
		return self:CanHeal(target) ~= false
	end
	if hg.WeaponUsesBandageCheck and hg.WeaponUsesBandageCheck(self) then
		return hg.CanBandage(target)
	end
	return true
end

function SWEP:DoBandageUse(attackType, target, fromMinigame)
	if CLIENT then return false end

	local owner = self:GetOwner()
	if not IsValid(owner) then return false end

	local ent

	if attackType == 2 then
		if IsValid(self:GetNWEntity("fakeGun")) then return false end

		ent = target
		if not IsValid(ent) then
			ent = hg.ResolveBandageOtherTarget and hg.ResolveBandageOtherTarget(owner)
		end

		if not IsValid(ent) then return false end
		if hg.IsSameBandageSubject and hg.IsSameBandageSubject(ent, owner) then return false end

		self.healbuddy = ent
	else
		ent = hg.GetBandageSelfEnt and hg.GetBandageSelfEnt(owner) or (hg.GetCurrentCharacter(owner) or owner)
		self.healbuddy = ent
	end

	local buddy = hg.GetBandageBleedEnt and hg.GetBandageBleedEnt(self.healbuddy) or (hg.GetCurrentCharacter(self.healbuddy) or self.healbuddy)
	if not self:CanUseOn(buddy) then
		owner:ChatPrint(hg.BandageRefuseChatMsg(owner, buddy))
		return false
	end

	self.modeValues = NormalizeModeValues(self, self.modeValues)

	if hg_healanims:GetBool() and not fromMinigame and self.UsesBandageCheck == false and not IsGradualInject(self) then
		self:SetHolding(100)
	end

	local healEnt = IsValid(buddy) and buddy or self.healbuddy
	local done = self:Heal(healEnt, self.mode, nil, fromMinigame)

	if fromMinigame then
		self:SetHolding(0)
	end

	if done and self.PostHeal then
		self:PostHeal(self.healbuddy, self.mode)
	end

	if self.net_cooldown2 < CurTime() then
		self:SetNetVar("modeValues", table.Copy(self.modeValues))
	end

	return done
end

SWEP.net_cooldown2 = 0
function SWEP:PrimaryAttack()
	if SERVER then
		if hg.WeaponUsesBandageCheck and hg.WeaponUsesBandageCheck(self) then return end
		self.healbuddy = self:GetOwner()
		local done = self:Heal(self.healbuddy, self.mode)

		if done and self.PostHeal then
			self:PostHeal(self.healbuddy, self.mode)
		end

		if self.net_cooldown2 < CurTime() then
			self:SetNetVar("modeValues", table.Copy(self.modeValues))
		end
	end
end

if CLIENT then
	local colWhite = Color(255, 255, 255, 255)
	local colGray = Color(200, 200, 200, 200)
	local lerpthing = 1
	local colBrown = Color(40,40,40)
	SWEP.showstats = true
	SWEP.ofsV = Vector(10,-2,1)
	SWEP.ofsA = Angle(-90,-40,270)
	local vector_one = Vector(1,1,1)
	function SWEP:DrawHUD()
		local owner = self:GetOwner()
		if !owner:IsPlayer() then return end
		if GetViewEntity() ~= owner then return end
		if owner:InVehicle() then return end

		self:DrawWorldModel2(true)
		local mdl = modelshuy[self.Model or self.WorldModel]
		if not IsValid(mdl) then return end

		local Tr = hg.eyeTrace(owner)
		if !Tr then return end
		local Size = math.max(math.min(1 - Tr.Fraction, 0.5), 0.1)
		local x, y = Tr.HitPos:ToScreen().x, Tr.HitPos:ToScreen().y
		if Tr.Hit then
			lerpthing = Lerp(0.1, lerpthing, 1)
			colWhite.a = 255 * Size
			surface.SetDrawColor(colGray)
			draw.NoTexture()
			surface.SetDrawColor(colWhite)
			draw.NoTexture()
			surface.DrawRect(x - 25 * lerpthing, y - 2.5, 50 * lerpthing, 5)
			surface.DrawRect(x - 2.5, y - 25 * lerpthing, 5, 50 * lerpthing)
			local col = Tr.Entity:GetPlayerColor():ToColor()
			local coloutline = (col.r < 50 and col.g < 50 and col.b < 50) and Color(255,255,255) or Color(0,0,0)
			coloutline.a = 255 * Size * 2
			draw.DrawText(Tr.Entity:IsPlayer() and Tr.Entity:GetPlayerName() or Tr.Entity:IsRagdoll() and Tr.Entity:GetPlayerName() or "", "HomigradFontLarge", x + 1, y + 31, coloutline, TEXT_ALIGN_CENTER)
			draw.DrawText(Tr.Entity:IsPlayer() and Tr.Entity:GetPlayerName() or Tr.Entity:IsRagdoll() and Tr.Entity:GetPlayerName() or "", "HomigradFontLarge", x, y + 30, col, TEXT_ALIGN_CENTER)
		end
		local modeValues = self:GetNetVar("modeValues", self.modeValues)
		if istable(modeValues) then
			modeValues = NormalizeModeValues(self, modeValues)
			self.modeValues = modeValues
		end
		if self.showstats and istable(modeValues) then
			render.PushFilterMag(TEXFILTER.LINEAR)
			render.PushFilterMin(TEXFILTER.LINEAR)
			local m = Matrix()
			m:Translate(Vector(ScrW() / 2-ScreenScale(60), ScrH() / 2 + ScreenScaleH(125), 0))
			m:Scale(vector_one * 0.5)

			cam.PushModelMatrix(m, true)
				for i, val in ipairs(modeValues) do
					local def = self.modeValuesdef and self.modeValuesdef[i]
					local max = istable(def) and def[1] or def
					if not max or max <= 0 then continue end
					val = tonumber(istable(val) and val[1] or val) or 0
					local pct = math.Clamp(math.Round(val / max * 100), 0, 100)
					local bx,by = 0, i * ScrH() / 20
					local reveal = 1
					colBrown.a = reveal * 185
					draw.RoundedBox(2, bx, by, bx + ScreenScale(210) + ScrW() / 10, ScrH() / 25, colBrown)
					local txt = string.NiceName(tostring(self.modeNames[i]))
					colBrown.a = reveal * 255
					draw.SimpleTextOutlined(txt, "ZCity_Small", bx, by, Color(255,i == self.mode and 0 or 255,i == self.mode and 0 or 255, 255 * reveal), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1.5, colBrown)
					surface.SetDrawColor(0,100,0,255 * reveal)
					surface.DrawRect(bx + ScreenScale(210), by, ScrW() / 10 * pct / 100, ScrH() / 25)
					surface.SetDrawColor(0,0,0,255 * reveal)
					surface.DrawOutlinedRect(bx + ScreenScale(210), by, ScrW() / 10, ScrH() / 25, 4)
				end
			cam.PopModelMatrix()

			render.PopFilterMag()
			render.PopFilterMin()
		end
	end
end

SWEP.mode = 1
SWEP.modes = 1
SWEP.modeNames = {
	[1] = "перевязка",
}

function SWEP:InitializeAdd()
	self.ModelScale = 0.9
end

SWEP.DeploySnd = "physics/body/body_medium_impact_soft5.wav"
SWEP.HolsterSnd = ""
SWEP.FallSnd = "physics/body/body_medium_impact_soft5.wav"

if CLIENT then
	SWEP.HowToUseInstructions = "<font=ZCity_Tiny>"..string.upper( (input.LookupBinding("+use") or "BIND YOUR +USE KEY PLEASE. WRITE \"bind e +use\" IN CONSOLE FOR THE LOVE OF GOD") ).." to pickup</font>"
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)

	self.modeValues = {
		[1] = 40,
	}

	if CLIENT then
		self.HudHintMarkup = markup.Parse("<font=ZCity_Tiny>".. self.PrintName .."</font>\n<font=ZCity_SuperTiny><colour=125,125,125>".. self.HowToUseInstructions .."</colour></font>", 450)
	end

	util.PrecacheSound(self.DeploySnd)
	util.PrecacheSound(self.HolsterSnd)
	util.PrecacheSound(self.FallSnd)
	util.PrecacheSound("snd_jack_hmcd_needleprick.wav")
	
	self:AddCallback("PhysicsCollide",function(ent,data)
		if data.Speed > 200 then
			ent:EmitSound(self.FallSnd or self.DeploySnd,65,math.random(90,110))
		end
	end)

	self:InitializeAdd()
end

SWEP.modeValuesdef = {
	[1] = {40,true},
}

function SWEP:GetInfo()
	if not IsValid(self) then
		local modevalues = {}
		for i,val in ipairs(self.modeValuesdef) do
			modevalues[i] = istable(val) and val[1] or val
		end
		return modevalues
	end
	return self.modeValues
end

function SWEP:SetInfo(info)
	info = NormalizeModeValues(self, info)
	self:SetNetVar("modeValues", table.Copy(info))
	self.modeValues = info
end

function SWEP:SecondaryAttack()
	if SERVER then
		if hg.WeaponUsesBandageCheck and hg.WeaponUsesBandageCheck(self) then return end
		if IsValid(self:GetNWEntity("fakeGun")) then return end
		local owner = self:GetOwner()
		local ent = hg.ResolveBandageOtherTarget and hg.ResolveBandageOtherTarget(owner)
		self.healbuddy = ent
		if not IsValid(self.healbuddy) then return end

		local done = self:Heal(self.healbuddy, self.mode)
		if done and self.PostHeal then
			self:PostHeal(self.healbuddy, self.mode)
		end

		if self.net_cooldown2 < CurTime() then
			self:SetNetVar("modeValues", table.Copy(self.modeValues))
		end
	end
end

if SERVER then
	util.AddNetworkString("select_mode")
else
	net.Receive("select_mode",function()
		net.ReadEntity().mode = net.ReadInt(4)
	end)
end

function SWEP:Reload()
	if SERVER and self:GetOwner():KeyPressed(IN_RELOAD) and #self.modeValuesdef > 1 then
		self.mode = ((self.mode + 1) > self.modes) and 1 or (self.mode + 1)
		--self:GetOwner():ChatPrint("You have chosen the " .. self.modeNames[self.mode] .. " mode")
		net.Start("select_mode")
		net.WriteEntity(self)
		net.WriteInt(self.mode,4)
		net.Broadcast()
	end
end
if CLIENT then
	hook.Add("OnNetVarSet","bandage-net-var",function(index,key,var)
		if key == "modeValues" then
			local ent = Entity(index)
			if not IsValid(ent) then return end

			ent.modeValues = NormalizeModeValues(ent, var)
		end
	end)
end

local function PhysCallback(ent, data)
	if data.DeltaTime < 0.2 then return end
	ent:EmitSound(Sound(ent.FallSnd))
end

local ents_Create, gamemod, clr_garbage = ents.Create, engine.ActiveGamemode(), Color(200, 200, 200)
local gibRemoveTime = 60
function SWEP:SpawnGarbage(mdl_custom, skin_custom, snd_custom, clr_custom, bgs_custom)
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local boneid
	if IsValid(owner) then
		if owner:IsPlayer() then
			local chr = hg.GetCurrentCharacter(owner)
			boneid = chr:LookupBone(((owner.organism and owner.organism.rarmamputated) or (owner.zmanipstart ~= nil and owner.zmanipseq == "interact" and owner.organism and not owner.organism.larmamputated)) and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")
		else
			boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand") or 1
		end
	end

	if not boneid then return end
	local matrix = owner:GetBoneMatrix(boneid)
	if not matrix then return end

	local ent = ents_Create("prop_physics")
	ent:SetModel(Model((mdl_custom and mdl_custom ~= "" and mdl_custom ~= nil and isstring(mdl_custom)) and mdl_custom or self.WorldModel))

	if skin_custom and skin_custom ~= nil and isnumber(skin_custom) then
		ent:SetSkin(skin_custom or 0)
	end

	ent:SetPos(matrix:GetTranslation())
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetAngles(AngleRand(-180, 180))
	ent:Activate()
	ent:Spawn()
	ent:SetOwner(owner)
	ent.FallSnd = Sound((snd_custom and snd_custom ~= nil) and snd_custom or self.FallSnd)

	if clr_custom and clr_custom ~= nil and IsColor(clr_custom) then
		ent:SetColor(clr_custom)
	else
		ent:SetColor(clr_garbage)
	end

	if bgs_custom and bgs_custom ~= nil and isstring(bgs_custom) then
		ent:SetBodyGroups(bgs_custom)
	end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(self:GetVelocity() + (owner:GetAimVector() * 200) + VectorRand(-50, 50))
		phys:AddAngleVelocity(VectorRand(-100, 100))
	end

	ent:AddCallback("PhysicsCollide", PhysCallback)

	if zb.CROUND and zb.CROUND ~= "hmcd" or gamemod == "sandbox" then
		ent:DrawShadow(false)
		ent:SetModelScale(0.5, gibRemoveTime)
		SafeRemoveEntityDelayed(ent, gibRemoveTime)
	end
end

-- WoundTBL = {dmgBlood / 2, localPos, localAng, bone, time}
SWEP.ShouldDeleteOnFullUse = true
if SERVER then
	local function orgHasActiveWounds(org)
		for _, wound in pairs(org.wounds or {}) do
			if istable(wound) and (tonumber(wound[1]) or 0) > 0 then return true end
		end
		return false
	end

	local function orgHasTreatableInjury(org)
		if not org then return false end
		if orgHasActiveWounds(org) then return true end
		return org.lleg == 1 or org.rleg == 1 or org.skull >= 0.6 or org.chest == 1 or org.rarm == 1 or org.larm == 1
	end

	local function orgWoundOwner(ent, org)
		if IsValid(org.owner) then return org.owner end
		if IsValid(ent) and ent:IsPlayer() then return ent end
		if IsValid(ent) and ent:IsRagdoll() and hg.RagdollOwner then return hg.RagdollOwner(ent) end
	end

	local function markInjuryBandaged(store, injury)
		local bones = {
			lleg = { "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_L_Calf" },
			rleg = { "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Calf" },
			larm = { "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm" },
			rarm = { "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm" },
		}
		local list = bones[injury]
		if not list then return end
		store.bandaged_limbs = store.bandaged_limbs or {}
		for i = 1, #list do
			store.bandaged_limbs[list[i]] = true
		end
	end

	local function bandageStore(ent, org)
		if IsValid(org.owner) and org.owner:IsPlayer() then return org.owner end
		return ent
	end

	function SWEP:Bandage(ent, bone)
		local org = ent.organism
		local owner = self:GetOwner()
		if not org then return end
		local store = bandageStore(ent, org)

		org.wounds = org.wounds or {}
		org.bleed = org.bleed or 0
		
		-- Если растрелять труп а потом его взорвать гранатой, после перевязать - крашнет сервер why?
		if self.modeValues[1] <= 0 or not orgHasTreatableInjury(org) then return end
		if orgHasActiveWounds(org) then
			table.sort(org.wounds, function(a, b) return (a[1] or 0) > (b[1] or 0) end)
		end
		
		local done = false
		local bandaged = false
		
		if not bone then
			while self.modeValues[1] > 0 and orgHasActiveWounds(org) do
				table.sort(org.wounds, function(a, b) return (a[1] or 0) > (b[1] or 0) end)

				local wound = org.wounds[1]
				if not wound then break end
				local biggestWound = wound[1]
				if not biggestWound or biggestWound <= 0 then
					table.remove(org.wounds, 1)
					continue
				end

				local spent = math.min(self.modeValues[1], biggestWound)
				local healedWound = biggestWound - spent
				org.bleed = math.max(org.bleed - spent, 0)
				org.wounds[1][1] = healedWound
				self.modeValues[1] = self.modeValues[1] - spent

				if spent > 0 then
					bandaged = true
				end

				store.bandaged_limbs = store.bandaged_limbs or {}
				local bone_name = wound[4]
				if bone_name and not store.bandaged_limbs[bone_name] then
					store.bandaged_limbs[bone_name] = true
					done = true
				end

				if healedWound <= 0 then
					table.remove(org.wounds, 1)
				end
			end
		else
			local bonewounds = {}
			
			for i, tbl in pairs(org.wounds) do
				if not istable(tbl) or not tbl[4] then continue end
				local boneid = ent:LookupBone(tbl[4])
				if not boneid then continue end
				if ent:GetBoneName(boneid) == bone then
					table.insert(bonewounds, i)
				end
			end
			
			while self.modeValues[1] > 0 and #bonewounds > 0 do
				local woundIdx = bonewounds[1]
				local wound = org.wounds[woundIdx]
				if not wound then
					table.remove(bonewounds, 1)
					continue
				end

				local biggestWound = wound[1]
				if not biggestWound or biggestWound <= 0 then
					table.remove(org.wounds, woundIdx)
					table.remove(bonewounds, 1)
					continue
				end

				local spent = math.min(self.modeValues[1], biggestWound)
				local healedWound = biggestWound - spent
				org.bleed = math.max(org.bleed - spent, 0)
				wound[1] = healedWound
				self.modeValues[1] = self.modeValues[1] - spent
				org.pain = math.max(org.pain - spent / 4, 0)

				if spent > 0 then
					bandaged = true
				end

				store.bandaged_limbs = store.bandaged_limbs or {}
				local boneid = wound[4] and ent:LookupBone(wound[4])
				local bone_name = boneid and ent:GetBoneName(boneid)
				if bone_name and not store.bandaged_limbs[bone_name] then
					store.bandaged_limbs[bone_name] = true
					done = true
				end

				if healedWound <= 0 then
					table.remove(org.wounds, woundIdx)
					table.remove(bonewounds, 1)
				end
			end
		end
		local woundOwner = orgWoundOwner(ent, org)
		if IsValid(woundOwner) and woundOwner.organism then
			hg.organism.SyncWoundNetVars(woundOwner, org)
		end

		local who = (self:GetOwner() == org.owner) and "You" or ((owner.Profession == "doctor") and "A doctor" or "Someone")
		local mul = ((owner.Profession == "doctor") and 0.2 or 1)
		local amt = 25 * mul
		if org.skull >= 0.6 and self.modeValues[1] >= amt then
			org.skull = 0.59
			self.modeValues[1] = self.modeValues[1] - amt
			org.bandagedskull = true
			org.pain = math.max(org.pain - 7, 0)
			done = true
		end

		if org.chest == 1 and self.modeValues[1] >= amt then
			org.chest = org.chest - 0.05
			self.modeValues[1] = self.modeValues[1] - amt
			org.avgpain = math.max(org.avgpain - 7, 0)
			done = true
		end

		if org.lleg == 1 and self.modeValues[1] >= amt and !org.llegamputated then
			org.lleg = org.lleg - 0.05
			self.modeValues[1] = self.modeValues[1] - amt
			org.avgpain = math.max(org.avgpain - 7, 0)
			markInjuryBandaged(store, "lleg")
			done = true
		end

		if org.rleg == 1 and self.modeValues[1] >= amt and !org.rlegamputated then
			org.rleg = org.rleg - 0.05
			self.modeValues[1] = self.modeValues[1] - amt
			org.avgpain = math.max(org.avgpain - 7, 0)
			markInjuryBandaged(store, "rleg")
			done = true
		end

		if org.rarm == 1 and self.modeValues[1] >= amt and !org.rarmamputated then
			org.rarm = org.rarm - 0.05
			self.modeValues[1] = self.modeValues[1] - amt
			org.avgpain = math.max(org.avgpain - 7, 0)
			markInjuryBandaged(store, "rarm")
			done = true
		end

		if org.larm == 1 and self.modeValues[1] >= amt and !org.larmamputated then
			org.larm = org.larm - 0.05
			self.modeValues[1] = self.modeValues[1] - amt
			org.avgpain = math.max(org.avgpain - 7, 0)
			markInjuryBandaged(store, "larm")
			done = true
		end

		if done then
			owner:EmitSound("snd_jack_hmcd_bandage.wav", 60, math.random(95, 105))

			if self.poisoned2 then
				org.poison4 = CurTime()

				self.poisoned2 = nil
			end
		end

		if next(store.bandaged_limbs or {}) then
			hg.SyncBandagedLimbsNet(store)
		end
		timer.Create("bandage_limbs"..store:EntIndex(),0.1,1,function()
			if not IsValid(store) then return end
			hg.SyncBandagedLimbsNet(store)
		end)

		return done
	end

	function SWEP:Heal(ent, mode, bone, fromMinigame)
		if ent:IsNPC() then
			self:NPCHeal(ent, 0.15, "snd_jack_hmcd_bandage.wav")
		end

		local org = ent.organism
		if not org then return end
	
		local owner = self:GetOwner()
		if not fromMinigame and ent == hg.GetCurrentCharacter(owner) and hg_healanims:GetBool() then
			self:SetHolding(math.min(self:GetHolding() + 10, 100))

			if self:GetHolding() < 100 then return end
		end

		local done = self:Bandage(ent, bone)
		if self.modeValues[1] <= 0 and self.ShouldDeleteOnFullUse then
			owner:SelectWeapon("weapon_hands_sh")
			self:Remove()
		end
		
		return done
	end
	
	function SWEP:PostHeal(ent, mode)
		local org = ent.organism
		
		if(org and IsValid(org.owner))then
			local organism_owner = org.owner
			
			if(organism_owner.SubRole == "traitor_chemist")then
				if(self.FoodModelsKCNNeutralizers and self.FoodModelsKCNNeutralizers[self:GetModel()])then
					self.ConsumePoisoned_KCN = math.max(self.ConsumePoisoned_KCN or 0 - self.FoodModelsKCNNeutralizers[self:GetModel()], 0)
				end
				
				if((self.ConsumePoisoned_KCN or 0) > 0)then
					local ply_kcn_accumulated = AddChemicalToPlayer(organism_owner, "KCN", 50 * (self.ConsumePoisoned_KCN or 0))
					
					if(ply_kcn_accumulated > 100)then
						self:PoisonKCNOrganism(org)
					end
					
					NetworkChemicalResistanceOfPlayer(organism_owner)
					
					organism_owner.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			else
				if(self.FoodModelsKCNNeutralizers and self.FoodModelsKCNNeutralizers[self:GetModel()])then
					self.ConsumePoisoned_KCN = math.max(self.ConsumePoisoned_KCN or 0 - self.FoodModelsKCNNeutralizers[self:GetModel()], 0)
				end
				
				if((self.ConsumePoisoned_KCN or 0) > 0)then
					self:PoisonKCNOrganism(org)
				end
			end
		end
	end
	
	function SWEP:PoisonKCNOrganism(org)
		if(org and self.ConsumePoisoned_KCN)then
			org.Poison_KCN = org.Poison_KCN or {}
			org.Poison_KCN.StartTime = org.Poison_KCN.StartTime or CurTime()
			org.Poison_KCN.Potency = (org.Poison_KCN.Potency or 0) + self.ConsumePoisoned_KCN
			self.ConsumePoisoned_KCN = nil
		end
	end

	function SWEP:SetFakeGun(ent)
		self:SetNWEntity("fakeGun", ent)
		self.fakeGun = ent
	end

	function SWEP:RemoveFake()
		if not IsValid(self.fakeGun) then return end
		self.fakeGun:Remove()
		self:SetFakeGun()
	end

	local function GetPhysBoneNum(ent,string)
		if not IsValid(ent) then return 7 end
		return ent:TranslateBoneToPhysBone(ent:LookupBone(string))
	end
	
	function SWEP:CreateFake(ragdoll)
		if IsValid(self:GetNWEntity("fakeGun")) then return end
		local ent = ents.Create("prop_physics")
		local physbonelh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_L_Hand")
		local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
		local lh = ragdoll:GetPhysicsObjectNum(physbonelh)
		local rh = ragdoll:GetPhysicsObjectNum(physbonerh)
		--rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
		--rh:SetAngles(self:GetOwner():EyeAngles() + Angle(0, 0, -90))
		--lh:SetPos(rh:GetPos())
		ent:SetModel(self.WorldModel)
		ent:SetPos(rh:GetPos())
		ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetOwner(ragdoll)
		ent:GetPhysicsObject():SetMass(0)
		ent:SetModel(self.Model or self.WorldModel)
		ent:SetNoDraw(true)
		ent.dontPickup = true
		ent.fakeOwner = self
		ragdoll:DeleteOnRemove(ent)
		ragdoll.fakeGun = ent
		if IsValid(ragdoll.ConsRH) then ragdoll.ConsRH:Remove() end
		self:SetFakeGun(ent)
		ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)
		local vec = Vector(0, 0, 0)
		vec:Set(self.RHandPos or vector_origin)
		vec:Rotate(ent:GetAngles())
		--rh:SetPos(ent:GetPos() + vec)
		constraint.Weld( ragdoll, ent, physbonerh, 0, 0, false, false )
	end

	function SWEP:RagdollFunc(pos, angles, ragdoll)
		local physbonelh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_L_Hand")
		local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
		shadowControl = shadowControl or hg.ShadowControl
		local fakeGun = ragdoll.fakeGun
		pos:Add(angles:Forward() * 20)
		--shadowControl(fakeGun, 0, 0.001, angles, 100, 90, pos, 1000, 900)
		angles:RotateAroundAxis(angles:Forward(), 180)
		shadowControl(ragdoll, 7, 0.001, angles, 500, 30, pos, 500, 50)
	end
end


hg.TourniquetGuys = hg.TourniquetGuys or {}

if SERVER then
	util.AddNetworkString("send_tourniquets")
	local tourniqet_bones = {
		["ValveBiped.Bip01_L_UpperArm"] = {
			["ValveBiped.Bip01_L_Forearm"] = true,
			["ValveBiped.Bip01_L_Hand"] = true
		},
		["ValveBiped.Bip01_L_Forearm"] = {
			["ValveBiped.Bip01_L_Hand"] = true
		},

		["ValveBiped.Bip01_R_UpperArm"] = {
			["ValveBiped.Bip01_R_Forearm"] = true,
			["ValveBiped.Bip01_R_Hand"] = true
		},
		["ValveBiped.Bip01_R_Forearm"] = {
			["ValveBiped.Bip01_R_Hand"] = true
		},

		["ValveBiped.Bip01_L_Thigh"] = {
			["ValveBiped.Bip01_L_Calf"] = true,
			["ValveBiped.Bip01_L_Foot"] = true
		},
		["ValveBiped.Bip01_L_Calf"] = {
			["ValveBiped.Bip01_L_Foot"] = true
		},

		["ValveBiped.Bip01_R_Thigh"] = {
			["ValveBiped.Bip01_R_Calf"] = true,
			["ValveBiped.Bip01_R_Foot"] = true
		},
		["ValveBiped.Bip01_R_Calf"] = {
			["ValveBiped.Bip01_R_Foot"] = true
		},
	}
	function SWEP:Tourniquet(ent, bone)
		local org = ent.organism
		if not org then return end
		if #org.arterialwounds > 0 then
			local ent = org.isPly and org.owner or ent
			ent.tourniquets = ent.tourniquets or {}

			local pw
			local bonewounds = {}
			if not bone then
				for i,wound in pairs(org.arterialwounds) do
					if wound[7] != "arteria" then 
						pw = i 
						for i1,tbl in pairs(org.wounds) do
							if !tbl or !tbl[4] or !ent:LookupBone(tbl[4]) then continue end
							local bonename = ent:GetBoneName(ent:LookupBone(tbl[4]))
							local sec_bonename = ent:GetBoneName(ent:LookupBone(wound[4]))
							--print(1,bonename,sec_bonename)
							if bonename == sec_bonename or (tourniqet_bones[sec_bonename] and tourniqet_bones[sec_bonename][bonename]) then
								--print(2,bonename,sec_bonename)
								table.insert(bonewounds,i1)
							end
						end
						--PrintTable(bonewounds)
					break end
				end
				
			else
				for i,wound in pairs(org.arterialwounds) do
					if ent:GetBoneName(ent:LookupBone(wound[4])) == bone then pw = i break end
				end
				for i,tbl in pairs(org.wounds) do
					local bonename = ent:GetBoneName(ent:LookupBone(tbl[4]))
					if bonename == bone or (tourniqet_bones[bone] and tourniqet_bones[bone][bonename]) then
						table.insert(bonewounds,i)
					end
				end
			end		
			pw = pw or math.random(#org.arterialwounds)

			local wound = org.arterialwounds[pw]
			if not wound then return false end
			
			ent.tourniquets[#ent.tourniquets + 1] = {wound[2], wound[3], wound[4]}
			org[wound[7]] = 0

			if wound[7] == "arteria" then org.o2.regen = 0 end

			table.remove(org.arterialwounds,pw)

			org.owner:SetNetVar("arterialwounds",org.arterialwounds)

			for i = 1, #bonewounds do
				if org.wounds[bonewounds[i]] then
					--print(org.wounds[bonewounds[i]], bonewounds[i])
					org.wounds[bonewounds[i]][1] = 0
				end
			end
			for i = 1, #bonewounds do
				if org.wounds[bonewounds[i]] then
					table.remove(org.wounds, bonewounds[i])
				end
			end

			hg.organism.SyncWoundNetVars(org.owner, org)

			ent:SetNetVar("Tourniquets",ent.tourniquets)
			if IsValid(ent.FakeRagdoll) then
				ent.FakeRagdoll:SetNetVar("Tourniquets",ent.tourniquets)
			end
			
			if not table.HasValue(hg.TourniquetGuys,ent) then
				table.insert(hg.TourniquetGuys,ent)
			end

			for i,ent in ipairs(hg.TourniquetGuys) do
				if not IsValid(ent) or not ent.tourniquets or table.IsEmpty(ent.tourniquets) then table.remove(hg.TourniquetGuys,i) end
			end

			SetNetVar("TourniquetGuys",hg.TourniquetGuys)

			self:GetOwner():EmitSound("snd_jack_hmcd_bandage.wav", 65, math.random(95, 105))
			return true
		end
	end

	hook.Add("Player Spawn", "remove-tourniquets", function(ply)
		if OverrideSpawn then return end
		ply:SetNetVar("Tourniquets",{})
		ply.tourniquets = {}
	end)

	hook.Add("Player_Death", "remove-tourniquetshuy", function(ply)
		if IsValid(ply.FakeRagdoll) then
			ply.FakeRagdoll.tourniquets = table.Copy(ply.tourniquets)
			ply.FakeRagdoll:SetNetVar("Tourniquets",ply.FakeRagdoll.tourniquets)
		end
		ply:SetNetVar("Tourniquets",{})
		ply.tourniquets = {}
	end)

	local function collectBandagedLimbs(ply, ragdoll)
		local limbs = ply.bandaged_limbs
		if not istable(limbs) or not next(limbs) then
			limbs = ply:GetNetVar("bandaged_limbs")
		end
		if (not istable(limbs) or not next(limbs)) and IsValid(ragdoll) then
			limbs = ragdoll.bandaged_limbs
			if not istable(limbs) or not next(limbs) then
				limbs = ragdoll:GetNetVar("bandaged_limbs")
			end
		end
		if not istable(limbs) or not next(limbs) then return end
		return table.Copy(limbs)
	end

	local function applyBandagesToCorpse(ply, ragdoll, limbs)
		if not IsValid(ragdoll) or not istable(limbs) or not next(limbs) then return end
		ragdoll.bandaged_limbs = limbs
		hg.SyncBandagedLimbsNet(ragdoll)
		if IsValid(ply) then
			ply.bandaged_limbs = {}
			ply:SetNetVar("bandaged_limbs", {})
		end
	end

	local function deathCorpseRagdoll(ply)
		if IsValid(ply.RagdollDeath) then return ply.RagdollDeath end
		local rag = ply:GetNWEntity("RagdollDeath")
		if IsValid(rag) then return rag end
		if IsValid(ply.FakeRagdoll) then return ply.FakeRagdoll end
	end

	hook.Add("Player Spawn", "remove-bandages", function(ply)
		if OverrideSpawn then return end
		ply.deathBandagedLimbs = nil
		ply:SetNetVar("bandaged_limbs",{})
		ply.bandaged_limbs = {}
	end)

	hook.Add("Player_Death", "remove-bandageshuy", function(ply)
		local ragdoll = deathCorpseRagdoll(ply)
		ply.deathBandagedLimbs = collectBandagedLimbs(ply, ragdoll)
		if ply.deathBandagedLimbs and IsValid(ragdoll) then
			applyBandagesToCorpse(ply, ragdoll, ply.deathBandagedLimbs)
		else
			ply:SetNetVar("bandaged_limbs", {})
			ply.bandaged_limbs = {}
		end
	end)

	hook.Add("RagdollDeath", "bandages-death-corpse", function(ply, ragdoll)
		if not IsValid(ply) or not IsValid(ragdoll) then return end
		local limbs = ply.deathBandagedLimbs or collectBandagedLimbs(ply, ragdoll)
		if limbs then
			applyBandagesToCorpse(ply, ragdoll, limbs)
		end
		ply.deathBandagedLimbs = nil
	end)

	hook.Add("Fake", "rtourniquetsss", function(ply,ragdoll)
		if not IsValid(ragdoll) then return end	
		
		ragdoll.tourniquets = table.Copy(ply.tourniquets)
		ply:SetNetVar("Tourniquets",ply.tourniquets)
		ragdoll:SetNetVar("Tourniquets",ragdoll.tourniquets)
	end)

else
	local boneScale = {
		["ValveBiped.Bip01_Head1"] = 1,
		["ValveBiped.Bip01_Neck1"] = 0.8,
		["ValveBiped.Bip01_L_UpperArm"] = 0.9,
		["ValveBiped.Bip01_L_Forearm"] = 0.8,
		["ValveBiped.Bip01_R_UpperArm"] = 0.9,
		["ValveBiped.Bip01_R_Forearm"] = 0.8,
		["ValveBiped.Bip01_L_Thigh"] = 1.4,
		["ValveBiped.Bip01_L_Calf"] = 1.1,
		["ValveBiped.Bip01_R_Thigh"] = 1.2,
		["ValveBiped.Bip01_R_Calf"] = 1.2,
	}

	local boneOffset = {
		["ValveBiped.Bip01_Neck1"] = {Vector(0, -1.5, -2), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_UpperArm"] = {Vector(5, -0.5, -3.2), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(5, -0.1, -2.8), Angle(90, 90, 90)},
		["ValveBiped.Bip01_R_UpperArm"] = {Vector(7, -0.1, -1.5), Angle(90, 90, 90)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(5, -0.2, -1.5), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_Thigh"] = {Vector(13, 0, -4.2), Angle(90, -90, 90)},
		["ValveBiped.Bip01_L_Calf"] = {Vector(5, 0.2, -3.2), Angle(90, -90, 90)},
		["ValveBiped.Bip01_R_Thigh"] = {Vector(13, -0.3, -2.6), Angle(90, -90, 90)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(5, 0.3, -3.1), Angle(90, -90, 90)},
	}

	local function remove_tourniquets(ent)
		if not ent.tourniquetsM then return end
		
		for i,model in pairs(ent.tourniquetsM) do
			if IsValid(model) then
				model:Remove()
				ent.tourniquetsM[i] = nil
			end
		end
	end

	hook.Add("OnNetVarSet","tourniquetnisser",function(index, key, var)
		if not IsValid(Entity(index)) then return end
		if key == "Tourniquets" then
			local ent = Entity(index)
			
			remove_tourniquets(ent)
			
			ent.tourniquets = var
			
			ent:CallOnRemove("remove_tourniquets",function()
				remove_tourniquets(ent)
			end)
		end
	end)

	hook.Add("Fake","gsdgsdgsdgsdsdgTURNIKET",function(ply,ragdoll)
		remove_tourniquets(ply)
		if IsValid(ragdoll) then
			remove_tourniquets(ragdoll)
		end
	end)

	hook.Add("Player_Death","huyhuyhuyFuckyou",function(ply)
		remove_tourniquets(ply)
	end)

	--hook.Add("PostDrawPlayerRagdoll", "draw_tourniquets", function(ent,ply)
	function hg.RenderTourniquets(ent, ply)
		if !ply.tourniquets or !next(ply.tourniquets) then return end
		for i, wound in ipairs(ply.tourniquets) do
			ply.tourniquetsM = ply.tourniquetsM or {}
			ply.tourniquetsM[i] = IsValid(ply.tourniquetsM[i]) and ply.tourniquetsM[i] or ClientsideModel("models/tourniquet/tourniquet_put.mdl")
			local model = ply.tourniquetsM[i]
			model:SetNoDraw(true)

			if not IsValid(model) then return end
			
			local matrix = ent:GetBoneMatrix(ent:LookupBone(wound[3]))
			if not matrix then
				model:SetNoDraw(true)
				return
			end
			
			local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
			
			local tourniquetOffset = -wound[1]:GetNegated()
			tourniquetOffset[2] = 0
			tourniquetOffset[3] = 0
			tourniquetOffset[1] = 0

			if not boneOffset[ent:GetBoneName(ent:LookupBone(wound[3]))] then continue end

			local offset = boneOffset[ent:GetBoneName(ent:LookupBone(wound[3]))][1] + tourniquetOffset
			local offset2 = boneOffset[ent:GetBoneName(ent:LookupBone(wound[3]))][2]
			local pos, ang = LocalToWorld(offset, offset2, bonePos, boneAng)
			model:SetRenderOrigin(pos)
			model:SetRenderAngles(ang)
			model:SetModelScale(boneScale[ent:GetBoneName(ent:LookupBone(wound[3]))])
			model:SetupBones()
			model:DrawModel()
		end
	end
	--end)

	

	local function BandageOwner(ent, ply)
		if IsValid(ply) and ply:IsPlayer() then return ply end
		if IsValid(ent) and ent:IsPlayer() then return ent end
		if IsValid(ent) and IsValid(ent.ply) and ent.ply:IsPlayer() then return ent.ply end
		if IsValid(ent) and hg.RagdollOwner then
			local owner = hg.RagdollOwner(ent)
			if IsValid(owner) then return owner end
		end
		return ent
	end

	function remove_bandages(ent)
		if not IsValid(ent) then return end
		local owner = ent:IsPlayer() and ent or ent.ply
		if IsValid(owner) and IsValid(owner.bandagesModel) then
			owner.bandagesModel:Remove()
			owner.bandagesModel = nil
		end
		if IsValid(ent.bandagesModel) then
			ent.bandagesModel:Remove()
			ent.bandagesModel = nil
		end
	end
	hg.RemoveBandageVisual = remove_bandages

	function hg.ClientApplyBandagedLimbs(ent, limbs)
		if not IsValid(ent) then return end
		limbs = istable(limbs) and limbs or {}

		local owner = BandageOwner(ent, ent.ply)
		remove_bandages(ent)
		if IsValid(owner) and owner ~= ent then remove_bandages(owner) end

		ent.bandaged_limbs = limbs
		if IsValid(owner) then owner.bandaged_limbs = limbs end
		if not next(limbs) then return end

		local cleanup = IsValid(owner) and owner or ent
		cleanup:CallOnRemove("remove_bandages", function()
			remove_bandages(ent)
			if IsValid(owner) then remove_bandages(owner) end
		end)
	end

	net.Receive("hg_bandage_limbs_sync", function()
		local ent = net.ReadEntity()
		local limbs = net.ReadTable()
		if not IsValid(ent) then return end
		hg.ClientApplyBandagedLimbs(ent, limbs)
	end)

	hook.Add("OnNetVarSet", "bandage_netvar", function(index, key, var)
		if key ~= "bandaged_limbs" then return end
		local ent = Entity(index)
		if not IsValid(ent) then return end
		if ent:IsPlayer() and hg.PlyInFake and hg.PlyInFake(ent) then
			ent.bandaged_limbs = {}
			remove_bandages(ent)
			return
		end
		hg.ClientApplyBandagedLimbs(ent, istable(var) and var or {})
	end)

	local BadagesModelMale = "models/distac/newbandage.mdl"
	local BadagesModelFemale = "models/distac/newbandage_f.mdl"
	util.PrecacheModel(BadagesModelMale)
	util.PrecacheModel(BadagesModelFemale)
	local BodyGroupsMale = {
		["ValveBiped.Bip01_Pelvis"] = "belly",
		["ValveBiped.Bip01_Spine"] = "groin",
		["ValveBiped.Bip01_Spine1"] = "belly",
		["ValveBiped.Bip01_Spine2"] = "Chest",
		["ValveBiped.Bip01_L_UpperArm"] = "HandUpLeft",
		["ValveBiped.Bip01_L_Forearm"] = "HandDownLeft",
		["ValveBiped.Bip01_L_Hand"] = "HandLeft",
		["ValveBiped.Bip01_R_UpperArm"] = "HandUpRight",
		["ValveBiped.Bip01_R_Forearm"] = "HandDownRight",
		["ValveBiped.Bip01_R_Hand"] = "HandRight",
		["ValveBiped.Bip01_L_Thigh"] = "LegUpLeft",
		["ValveBiped.Bip01_L_Calf"] = "LegDownLeft",
		["ValveBiped.Bip01_R_Thigh"] = "LegUpRught",
		["ValveBiped.Bip01_R_Calf"] = "LegDownRught",
	}

	local BodyGroupsFemale = {
		["ValveBiped.Bip01_Pelvis"] = "belly-f",
		["ValveBiped.Bip01_Spine"] = "groin-f",
		["ValveBiped.Bip01_Spine1"] = "belly-f",
		["ValveBiped.Bip01_Spine2"] = "Chest-f",
		["ValveBiped.Bip01_L_UpperArm"] = "HandUpLeft-f",
		["ValveBiped.Bip01_L_Forearm"] = "HandDownLeft-f",
		["ValveBiped.Bip01_L_Hand"] = "HandLeft-f",
		["ValveBiped.Bip01_R_UpperArm"] = "HandUpRight-f",
		["ValveBiped.Bip01_R_Forearm"] = "HandDownRight-f",
		["ValveBiped.Bip01_R_Hand"] = "HandRight-f",
		["ValveBiped.Bip01_L_Thigh"] = "LegUpLeft-f",
		["ValveBiped.Bip01_L_Calf"] = "LegDownLeft-f",
		["ValveBiped.Bip01_R_Thigh"] = "LegUpRught-f",
		["ValveBiped.Bip01_R_Calf"] = "LegDownRught-f",
	}

	local function GetBandagedLimbs(ent, ply)
		if ent.bandaged_limbs and next(ent.bandaged_limbs) then return ent.bandaged_limbs end

		local limbs = ent.GetNetVar and ent:GetNetVar("bandaged_limbs")
		if istable(limbs) and next(limbs) then
			ent.bandaged_limbs = limbs
			return limbs
		end

		if IsValid(ply) and ply ~= ent and ply.GetNetVar then
			limbs = ply:GetNetVar("bandaged_limbs")
			if istable(limbs) and next(limbs) then
				ply.bandaged_limbs = limbs
				return limbs
			end
		end
	end

	local function limbsSignature(limbs)
		local keys = {}
		for k in pairs(limbs) do keys[#keys + 1] = k end
		table.sort(keys)
		return table.concat(keys, "\n")
	end

	local function applyBandageBodygroups(model, ent, limbs, bodyMap, dontmakehands)
		for _, bgName in pairs(bodyMap) do
			local bg = model:FindBodygroupByName(bgName)
			if bg >= 0 then model:SetBodygroup(bg, 0) end
		end

		local pending = false
		for k in pairs(limbs) do
			if dontmakehands and (k == "ValveBiped.Bip01_L_Hand" or k == "ValveBiped.Bip01_R_Hand") then continue end
			local bgName = bodyMap[k]
			if not bgName then continue end
			local bg = model:FindBodygroupByName(bgName)
			if bg < 0 then
				pending = true
			else
				model:SetBodygroup(bg, 1)
			end
		end

		for bone in pairs(hg.amputatedlimbs2 or {}) do
			local children = hg.get_children(ent, bone)
			children[#children + 1] = bone

			for i = 1, #children do
				local childBone = children[i]
				if limbs[childBone] and ent.organism and ent.organism[hg.amputatedlimbs2[childBone] .. "amputated"] then
					local bg = model:FindBodygroupByName(bodyMap[childBone] or "")
					if bg >= 0 then model:SetBodygroup(bg, 0) end
				end
			end
		end

		return pending
	end

	--hook.Add("PostDrawPlayerRagdoll", "draw_bandages", function(ent,ply)
	function hg.RenderBandages(ent, ply)
		if not IsValid(ent) then return end
		ply = IsValid(ply) and ply or ent
		local owner = BandageOwner(ent, ply)

		local limbs = GetBandagedLimbs(ent, owner)
		if not limbs or not next(limbs) then return end

		local fem = ThatPlyIsFemale(owner:IsPlayer() and owner or ent)
		local modelPath = fem and BadagesModelFemale or BadagesModelMale

		if not IsValid(owner.bandagesModel) then
			owner.bandagesModel = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)
			owner.bandagesModel:SetNoDraw(true)
			owner:CallOnRemove("removebandages", function()
				remove_bandages(owner)
			end)
		end

		local model = owner.bandagesModel
		model:SetNoDraw(true)

		if model:GetModel() ~= modelPath then
			model:SetModel(modelPath)
			model.BandagedLimbsSig = nil
		end

		if model:GetParent() ~= ent then
			model:SetParent(ent)
			model:AddEffects(EF_BONEMERGE)
			model.BandagedLimbsSig = nil
		end

		local entModel = ent:GetModel()
		if entModel then
			local parts = string.Split(string.sub(entModel, 1, -5), "/")
			local mdl = parts[#parts]
			if mdl then
				local flex = model:GetFlexIDByName(mdl)
				if flex then model:SetFlexWeight(flex, 1) end
			end
		end

		local dontmakehands = not hg.Appearance.FuckYouModels[1][ent:GetModel()] and not hg.Appearance.FuckYouModels[2][ent:GetModel()]
		local bodyMap = fem and BodyGroupsFemale or BodyGroupsMale
		local sig = limbsSignature(limbs)

		if model.BandagedLimbsSig ~= sig then
			local pending = applyBandageBodygroups(model, ent, limbs, bodyMap, dontmakehands)
			if not pending then
				model.BandagedLimbsSig = sig
			end
		end

		model:SetupBones()
		model:DrawModel()
	end
	--end)

	hook.Add("Fake", "bandages-setfake-cl", function(ply, ragdoll)
		if not IsValid(ply) then return end
		remove_bandages(ply)
		if not IsValid(ragdoll) then return end
		local limbs = ply.bandaged_limbs
		if (not limbs or not next(limbs)) and ply.GetNetVar then
			limbs = ply:GetNetVar("bandaged_limbs")
		end
		if istable(limbs) and next(limbs) then
			hg.ClientApplyBandagedLimbs(ragdoll, table.Copy(limbs))
		end
	end)

	hook.Add("FakeUp", "bandages-on-getup-cl", function(ply, ragdoll)
		if not IsValid(ply) then return end
		if IsValid(ragdoll) then remove_bandages(ragdoll) end
		local limbs = ply.bandaged_limbs
		if (not limbs or not next(limbs)) and ply.GetNetVar then
			limbs = ply:GetNetVar("bandaged_limbs")
		end
		hg.ClientApplyBandagedLimbs(ply, istable(limbs) and limbs or {})
	end)

	hook.Add("RagdollEntityCreated", "bandages-death-corpse-cl", function(ply, ragdoll, key)
		if key ~= "RagdollDeath" or not IsValid(ragdoll) then return end
		local limbs = ragdoll.bandaged_limbs
		if not istable(limbs) or not next(limbs) then
			limbs = ragdoll:GetNetVar("bandaged_limbs")
		end
		if (not istable(limbs) or not next(limbs)) and IsValid(ply) then
			limbs = ply.bandaged_limbs
			if not istable(limbs) or not next(limbs) then
				limbs = ply:GetNetVar("bandaged_limbs")
			end
		end
		if istable(limbs) and next(limbs) then
			hg.ClientApplyBandagedLimbs(ragdoll, table.Copy(limbs))
		end
		if IsValid(ply) then remove_bandages(ply) end
	end)
end

function SWEP:IsLocal()
	return CLIENT and self:GetOwner() == LocalPlayer()
end

function SWEP:Holster(wep)
	if not IsValid(wep) or wep == self then return true end

	if SERVER or CLIENT and self:IsLocal() then
		self:EmitSound(self.HolsterSnd,50)
	end

	return true
end

function SWEP:NPCHeal(npc, mul, snd)
	if not npc then
		npc = self:GetOwner()
	end

	if npc:IsNPC() then
		self:SetHold("melee")
		if not mul then
			mul = 0.3
		end
		npc:SetHealth(math.Clamp(npc:Health() + (npc:GetMaxHealth() * 1 * mul), 0, npc:GetMaxHealth() * math.Clamp(2 * mul, 2, 100)))
		npc:EmitSound(snd or "snd_jack_hmcd_bandage.wav", 75, math.random(95, 105))

		if SERVER then
			self:Remove()
		end
	end
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:NPCHeal(owner, 0.15, "snd_jack_hmcd_bandage.wav")
	end
end

function SWEP:Deploy()
	if SERVER or CLIENT and self:IsLocal() then
		self:EmitSound(self.DeploySnd, 50, math.random(90, 110))
	end

	if self.DeployAdd then self:DeployAdd() end

	return true
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCRestTimes()
	return 0.1, 0.1
end