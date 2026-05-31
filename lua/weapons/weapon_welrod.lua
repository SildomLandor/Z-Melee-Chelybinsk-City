SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Welrod Mk.I"
SWEP.Author = "British SOE"
SWEP.Instructions = "Пистолет с затворным механизмом и встроенным глушителем под патрон 9x19 мм Parabellum\n\nСкорость стрельбы 15 выстрелов в минуту (ручной затвор)\n\nРазработан для скрытых операций. Имеет магазин на 6 патронов, ручной затвор, несъемный глушитель и чрезвычайно тихий звук выстрела.\n\nНАЖМИТЕ R ПОСЛЕ КАЖДОГО ВЫСТРЕЛА ДЛЯ ПЕРЕЗАРЯДКИ ЗАТВОРА"
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_pist_p228.mdl"
SWEP.WorldModelFake = "models/weapons/arc9_doi/c_welrod.mdl"
SWEP.FakeBodyGroups = "11111"
SWEP.FakePos = Vector(-30, 5, 9.4)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(15,-2000000,3.2)
SWEP.AttachmentAng = Angle(0,0,140)
SWEP.FakeAttachment = 1

SWEP.StartAtt = {"supressor4"}
SWEP.FakeVPShouldUseHand = true
SWEP.stupidgun = true

SWEP.AnimList = {
    ["idle"] = "idle",
    ["reload"] = "base_reload",
    ["reload_empty"] = "base_reloadempty",
    ["cycle"] = "base_fire_end",
}

SWEP.MagModel = "models/weapons/upgrades/w_magazine_m45_8.mdl" 

SWEP.lmagpos = Vector(2.,0,0)
SWEP.lmagang = Angle(-10,0,0)
SWEP.lmagpos2 = Vector(0,-1.5,0.7)
SWEP.lmagang2 = Angle(0,0,0)

SWEP.AnimsEvents = {
    ["base_fire_end"] = {
        [0.0] = function(self)
            self:EmitSound("weapons/tfa_ins2/k98/m40a1_boltlatch.wav", 45, math.random(95, 105))
        end,
        [0.3] = function(self)
            self:RejectShell(self.ShellEject)
            self:EmitSound("weapons/tfa_ins2/k98/m40a1_boltlatch.wav", 45, math.random(95, 105))
        end,
        [0.6] = function(self)
            self:EmitSound("weapons/tfa_ins2/k98/m40a1_bolt_close.wav", 45, math.random(95, 105))
            self.drawBullet = true
        end
    }
}

SWEP.WepSelectIcon2 = Material("entities/arc9_doi_welrod.png")
SWEP.IconOverride = "entities/arc9_doi_welrod.png"

SWEP.CustomShell = "9x19"
SWEP.EjectPos = Vector(5,21,-2)
SWEP.EjectAng = Angle(-180,80,0)
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.weight = 1
SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_9mm"
SWEP.Primary.ClipSize = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 50
SWEP.Primary.Sound = {"weapons/welrod/1911_fire_silenced_close1.ogg", 65, 90, 100}
SWEP.SupressedSound = {"weapons/welrod/1911_fire_silenced_close1.ogg", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/makarov/handling/makarov_empty.wav", 75, 100, 105}
SWEP.Primary.Force = 50
SWEP.Primary.Wait = 0.3
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
SWEP.ZoomPos = Vector(-30, 2, 8)
SWEP.RHandPos = Vector(-13.5, 0, 4)
SWEP.LHandPos = false
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 1
SWEP.Penetration = 15
SWEP.WorldPos = Vector(13, -0.4, 3.55)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = false
SWEP.attPos = Vector(0, 0, -0.9)
SWEP.attAng = Angle(0.02, -0.7, 0)
SWEP.lengthSub = 25
SWEP.DistSound = "weapons/darsu_eft/m9a3/m9a3_fire_indoor_distant.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(-3, 0, -7)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true

SWEP.LocalMuzzlePos = Vector(-3.44,0.9,7.955)
SWEP.LocalMuzzleAng = Angle(0.7,-0.002,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.RHPos = Vector(16,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

function SWEP:ModelCreated(model)
    if CLIENT and self:GetWM() then
        self:GetWM():SetBodyGroups("01")
    end
end

function SWEP:InitializePost()
    self.drawBullet = true
end

SWEP.ShootAnimMul = 5

function SWEP:DrawPost()
    local wep = self:GetWeaponEntity()
    if CLIENT and IsValid(wep) then
        self.shooanim = LerpFT(0.4,self.shooanim or 0,(self:Clip1() > 0 or self.reload) and 0 or 2.2)
        wep:ManipulateBonePosition(96,Vector(0 ,0.8*self.shooanim ,0),false)
    end
end

function SWEP:CanPrimaryAttack()
    if not self.drawBullet then return false end
    return self.BaseClass.CanPrimaryAttack(self)
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if not self.drawBullet then return end
    if self:Clip1() <= 0 then
        self:EmitSound(self.Primary.SoundEmpty[1], self.Primary.SoundEmpty[2], self.Primary.SoundEmpty[3], self.Primary.SoundEmpty[4])
        return
    end
    
    self.BaseClass.PrimaryAttack(self)
    self.drawBullet = false
end

function SWEP:Reload()

    if self.drawBullet == false and self:Clip1() > 0 then
        self:PlayAnim(self.AnimList["cycle"] or "base_fire_end", 1.5, false, function()
            self.drawBullet = true
        end, false, true)
        self.Primary.Next = CurTime() + 1.5
        return
    end
    if self:Clip1() <= 0 then
        self:PlayAnim(self.AnimList["reload"] or "base_reload", 1.5, false, function()
            self:SetClip1(self.Primary.ClipSize)
            self.drawBullet = true
        end, false, true)
        self.Primary.Next = CurTime() + 2
        return
    end
end

SWEP.ReloadAnimLH = {
    Vector(0,0,0), Vector(0,0,0), Vector(-3,-1,-5), Vector(-12,1,-22),
    Vector(-12,1,-22), Vector(-12,1,-22), Vector(-12,1,-22), Vector(-2,-1,-3),
    "fastreload", Vector(0,0,0), "reloadend", "reloadend",
}
SWEP.ReloadAnimLHAng = {
    Angle(0,0,0), Angle(0,0,0), Angle(30,-10,0), Angle(60,-20,0),
    Angle(70,-40,0), Angle(90,-30,0), Angle(40,-20,0), Angle(0,0,0),
    Angle(0,0,0), Angle(0,0,0), Angle(0,0,0),
}
SWEP.ReloadAnimRH = {
    Vector(0,0,0), Vector(0,0,0), Vector(0,0,0), Vector(0,0,0),
    Vector(0,0,0), Vector(0,0,0), Vector(0,0,0), Vector(0,0,0),
    Vector(-2,0,0), Vector(-1,0,0), Vector(0,0,0)
}
SWEP.ReloadAnimRHAng = {
    Angle(0,0,0), Angle(0,0,0), Angle(0,0,0), Angle(0,0,0),
    Angle(0,0,0), Angle(0,0,0), Angle(0,0,0), Angle(0,0,0),
    Angle(0,0,0), Angle(0,0,0), Angle(15,2,20), Angle(15,2,20), Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
    Angle(0,0,0), Angle(5,15,15), Angle(-5,21,14), Angle(-5,21,14),
    Angle(5,20,13), Angle(5,22,13), Angle(1,22,13), Angle(1,21,13),
    Angle(2,22,12), Angle(-5,21,16), Angle(-5,22,14), Angle(-4,23,13),
    Angle(7,22,8), Angle(7,12,3), Angle(2,6,1), Angle(0,0,0)
}

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(4,4,15),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(-6,-15,-15),
	Angle(1,15,-45),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(0,0,0),
	Angle(0,0,0)
}