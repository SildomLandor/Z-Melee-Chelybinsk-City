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

SWEP.ViewModel = ""
SWEP.FakeBodyGroups = "0"
SWEP.AttachmentPos = Vector(-1.5,-0.01,1.08)
SWEP.AttachmentAng = Angle(0,0,90)
SWEP.MagIndex = 53
SWEP.FakeAttachment = 1

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

if CLIENT then
	local vector_full = Vector(1, 1, 1)
	SWEP.FakeReloadEvents = {
		[0.35] = function( self ) 
			if self:Clip1() < 1 then
				hg.CreateMag( self, Vector(0,0,-50) )
				self:GetWM():ManipulateBoneScale(50, vector_origin)
				self:GetWM():ManipulateBoneScale(51, vector_origin)
				self:GetWM():ManipulateBoneScale(52, vector_origin)
			end
		end,
		[0.15] = function( self, timeMul )
			if self:Clip1() >= 1 then
				self:GetWM():ManipulateBoneScale(53, vector_full)
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 0.5 * timeMul)
			end
		end,
		[0.2] = function( self, timeMul )
			if self:Clip1() < 1 then
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 1.5 * timeMul)
			end
		end,
		[0.36] = function( self )
			if self:Clip1() >= 1 then
				self:GetWM():ManipulateBoneScale(50, vector_full)
				self:GetWM():ManipulateBoneScale(51, vector_full)
				self:GetWM():ManipulateBoneScale(52, vector_full)
			end
		end,
		[0.5] = function( self )
			if self:Clip1() < 1 then
				self:GetWM():ManipulateBoneScale(50, vector_full)
				self:GetWM():ManipulateBoneScale(51, vector_full)
				self:GetWM():ManipulateBoneScale(52, vector_full)
			end
		end,
		[0.8] = function( self, timeMul )
			if self:Clip1() >= 1 then
				self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 1*timeMul)
			end
		end,
		[0.9] = function( self ) 
			self:GetWM():ManipulateBoneScale(53, vector_origin)
		end,
		[1.2] = function( self ) 
			if self:Clip1() >= 1 then
			end
		end,
	}
end

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
SWEP.HoldType = "revolver"
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

SWEP.RHPos = Vector(16,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

SWEP.IsOpened = false

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
    
    self:PlayAnim("sign", 3.5, false)
    self.IsOpened = true
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