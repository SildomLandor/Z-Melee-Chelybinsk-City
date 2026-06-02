SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Heineken Beer"
SWEP.Author = "Heineken"
SWEP.Instructions = "RMB - open | LMB - drink. It's just a beer, right?"
SWEP.Category = "ZCity Medicine"
SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.WorldModel = "models/casual/food/w_heineken.mdl"
SWEP.WorldModelFake = "models/casual/food/c_heineken.mdl"

SWEP.FakePos = Vector(-10, 5, 5)
SWEP.FakeAng = Angle(0, 0, 0)

SWEP.ChugFakePosOffset = Vector(7, 0, 2)
SWEP.ChugFakeAngOffset = Angle(0, 0, 0)
SWEP.ChugHandPosOffset = Vector(0, 0, 0)
SWEP.ChugHandAngOffset = Angle(0, 0, 0)

SWEP.ViewModel = ""
SWEP.FakeBodyGroups = "0"
SWEP.AttachmentPos = Vector(-1.5,-0.01,1.08)
SWEP.AttachmentAng = Angle(0,0,90)
SWEP.FakeAttachment = 1
SWEP.CapBones = {50, 51, 52, 53}

SWEP.FakeVPShouldUseHand = true
SWEP.AnimList = {
    ["idle"] = "idle",
    ["reload"] = "reload1",
    ["reload_empty"] = "reload_empty1",
    ["chug"] = "chug",
    ["sign"] = "fire"
}

SWEP.FakeReloadSounds = {
	[0.2] = "weapons/universal/uni_pistol_draw_01.wav",
	[0.3] = "zcitysnd/sound/weapons/m9/handling/m9_magout.wav",
	[0.8] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.9] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
	[0.95] = "weapons/universal/uni_pistol_holster.wav",
	[1.02] = "weapons/universal/uni_crawl_l_02.wav"
}

SWEP.FakeEmptyReloadSounds = {
	[0.15] = "weapons/universal/uni_crawl_l_03.wav",
	[0.22] = "weapons/tfa_ins2/usp_tactical/magrelease.wav",
	[0.3] = "weapons/tfa_ins2/usp_tactical/magout.wav",
	[0.37] = "weapons/universal/uni_pistol_draw_01.wav",
	[0.41] = "weapons/universal/uni_crawl_l_05.wav",
	[0.6] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.8] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
	[1] = "weapons/tfa_ins2/usp_match/usp_match_boltrelease.wav",
}

SWEP.MagModel = "models/weapons/upgrades/w_magazine_m45_8.mdl" 
SWEP.lmagpos = Vector(2.,0,0)
SWEP.lmagang = Angle(-10,0,0)
SWEP.lmagpos2 = Vector(0,-1.5,0.7)
SWEP.lmagang2 = Angle(0,0,0)

local capVecShow = Vector(1, 1, 1)
local capNameNeedles = {"cap", "lid", "top", "ring", "tab", "крыш"}

local function capNameMatch(name)
	if not name or name == "__INVALIDBONE__" then return false end
	local l = name:lower()
	for i = 1, #capNameNeedles do
		if l:find(capNameNeedles[i], 1, true) then return true end
	end
	return false
end

function SWEP:BeerCapOnModel(mdl, show)
	if not IsValid(mdl) then return end
	local scale = show and capVecShow or vector_origin

	for i = 0, mdl:GetBoneCount() - 1 do
		if capNameMatch(mdl:GetBoneName(i)) then
			mdl:ManipulateBoneScale(i, scale)
		end
	end

	for i = 1, #(self.CapBones or {}) do
		mdl:ManipulateBoneScale(self.CapBones[i], scale)
	end

	for bg = 0, mdl:GetNumBodyGroups() - 1 do
		local bgName = mdl:GetBodygroupName(bg)
		if bgName and capNameMatch(bgName) then
			mdl:SetBodygroup(bg, show and 0 or 1)
		end
	end
end

function SWEP:BeerCapVisible(show)
	self:BeerCapOnModel(self.worldModel, show)
	if CLIENT then
		self:BeerCapOnModel(self:GetWM(), show)
	end
end

function SWEP:BeerCapRemove()
	if SERVER then self:SetNWBool("BeerCapOff", true) end
	self:BeerCapVisible(false)
end

function SWEP:ModelCreated(mdl)
	self:BeerCapOnModel(mdl, not self:GetNWBool("BeerCapOff", false))
end

local BEER_OPEN_ANIM_TIME = 3.5
local BEER_CAP_REMOVE_AT = 0.70

SWEP.AnimsEvents = {
	["sign"] = {
		[BEER_CAP_REMOVE_AT] = function(self) self:BeerCapRemove() end,
	},
	["fire"] = {
		[BEER_CAP_REMOVE_AT] = function(self) self:BeerCapRemove() end,
	},
}

SWEP.WepSelectIcon2 = Material("vgui/entities/heineken")
SWEP.IconOverride = "vgui/entities/heineken"

SWEP.CustomShell = "9x19"
SWEP.EjectPos = Vector(5,21,-2)
SWEP.EjectAng = Angle(-180,80,0)
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.weight = 1

SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_9mm"
SWEP.Primary.ClipSize = 0
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 25
SWEP.Primary.Sound = {"weapons/darsu_eft/57/fiveseven_fire_distant.ogg", 75, 90, 100}
SWEP.SupressedSound = {"darsu_eft/m9a3/m9a3_fire_close_indoor_silenced.wav", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/makarov/handling/makarov_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 25
SWEP.Primary.Wait = PISTOLS_WAIT
SWEP.ReloadTime = 4
SWEP.ReloadSoundes = {
	"none", "none",
	"weapons/tfa_ins2/usp_tactical/magout.wav",
	"weapons/tfa_ins2/browninghp/magin.wav",
	"pwb/weapons/fnp45/sliderelease.wav",
	"none", "none", "none"
}
SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "normal"
SWEP.ZoomPos = Vector(-30, 0.7, 7.4)
SWEP.RHandPos = Vector(-13.5, 0, 4)
SWEP.LHandPos = false
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 1
SWEP.Penetration = 7
SWEP.WorldPos = Vector(-10, 3, -1)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, -0.9)
SWEP.attAng = Angle(0.02, -0.7, 0)
SWEP.lengthSub = 25
SWEP.DistSound = "weapons/darsu_eft/m9a3/m9a3_fire_indoor_distant.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(-3, 0, -7)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor4", Vector(0,0,0), {}},
		[2] = {"supressor6", Vector(0,0,0), {}},
		[3] = {"supressor3", Vector(0,0,0), {}},
		["mount"] = Vector(1.1,0.2,0),
	},
	underbarrel = {
		["mount"] = Vector(14, -0.35, 0.2),
		["mountAngle"] = Angle(0, 0, 0),
		["mountType"] = "picatinny_small"
	},
}

SWEP.LocalMuzzlePos = Vector(-3.44,0.9,7.955)
SWEP.LocalMuzzleAng = Angle(0.7,-0.002,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.RHPos = Vector(10,-5,2)
SWEP.RHAng = Angle(0,-5,90)

SWEP.IsOpened = false

local function BeerLeftHandActive(self)
	return self.seq == "fire" and CurTime() < (self.animtime or 0)
end

local function BeerIsChugging(self)
	return self.seq == "chug" and CurTime() < (self.animtime or 0)
end

function SWEP:IsPistolHoldType()
	return false
end

function SWEP:PosAngChanges(ply, desiredPos, desiredAng, bNoAdditional, closeanim, dtime)
	local pos, ang = self.BaseClass.PosAngChanges(self, ply, desiredPos, desiredAng, bNoAdditional, closeanim, dtime)
	self.setlhik = BeerLeftHandActive(self)
	if BeerIsChugging(self) then
		self.AdditionalPos2 = self.AdditionalPos2 + (self.ChugHandPosOffset or vector_origin)
		self.AdditionalAng2 = self.AdditionalAng2 + (self.ChugHandAngOffset or angle_zero)
	end
	return pos, ang
end

function SWEP:WorldModel_Transform(bNoApply, bNoAdditional, model)
	if not BeerIsChugging(self) then
		return self.BaseClass.WorldModel_Transform(self, bNoApply, bNoAdditional, model)
	end

	local fp, fa = self.FakePos, self.FakeAng
	self.FakePos = fp + (self.ChugFakePosOffset or vector_origin)
	self.FakeAng = fa + (self.ChugFakeAngOffset or angle_zero)
	local r1, r2, r3, r4 = self.BaseClass.WorldModel_Transform(self, bNoApply, bNoAdditional, model)
	self.FakePos, self.FakeAng = fp, fa
	return r1, r2, r3, r4
end

function SWEP:SetHandPos(noset)
	self.setlhik = BeerLeftHandActive(self)
	self.BaseClass.SetHandPos(self, noset)
	if not self.setlhik then self.lhandik = false end
end

local function GiveBottleInHands(wep, owner)
    if not IsValid(wep) or not IsValid(owner) then return end

    owner:Give("weapon_hg_bottle")
    local bottle = owner:GetWeapon("weapon_hg_bottle")
    if not IsValid(bottle) then return end

    owner:SelectWeapon("weapon_hg_bottle")
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    if self.IsOpened then return end
    
    self:PlayAnim("sign", BEER_OPEN_ANIM_TIME, false)
    self.IsOpened = true
    local wep = self
    timer.Simple(BEER_OPEN_ANIM_TIME * BEER_CAP_REMOVE_AT, function()
        if IsValid(wep) and wep.IsOpened then wep:BeerCapRemove() end
    end)
    self:SetNextSecondaryFire(CurTime() + 2.5)
    self:EmitSound("food/beer_opendrink.wav", 75, 100, 1)
    
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then owner:ViewPunch(Angle(-0.5, math.random(-1, 1), 0)) end
    end
end

local phrasesalco = {
    "Фух, как хорошо!",
    "Сразу полегчало.",
    "Отлично зашло!",
    "Вот это жизнь!",
    "Свежее пиво - лучшее лекарство.",
    "Вот теперь можно жить.",
    "Эх, хорошо пошло!"
}

function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    if not self.IsOpened then
        self:SetNextPrimaryFire(CurTime() + 0.25)
        return
    end
    
    self:PlayAnim("chug", 7, false)
    self:SetNextPrimaryFire(CurTime() + 3)
    
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            local org = owner.organism
            if org then
                if hg and hg.organism and hg.organism.AddAlcohol then
                    hg.organism.AddAlcohol(org, 0.38)
                else
                    org.alcohol = math.min((org.alcohol or 0) + 0.38, 4)
                    org.alcoholRecentDose = CurTime()
                end
                owner:EmitSound("food/beer_drink1.wav", 60, math.random(95, 105))
                owner:Notify(phrasesalco[math.random(1, #phrasesalco)], 3)
            end
            
            timer.Simple(4, function()
                if IsValid(self) and IsValid(owner) then
                    GiveBottleInHands(self, owner)
                    self:Remove()
                end
            end)
        end
    end
    
    self.IsOpened = false
end

function SWEP:Holster()
    self.IsOpened = false
    if SERVER then self:SetNWBool("BeerCapOff", false) end
    self:BeerCapVisible(true)
    return true
end

function SWEP:SetZoom(state)
end

function SWEP:Camera(eyePos, eyeAng, view)
	if hg and hg.DrawWorldModel then
		hg.DrawWorldModel(self, true)
	end

	view.origin = eyePos
	view.angles = eyeAng
	return view
end