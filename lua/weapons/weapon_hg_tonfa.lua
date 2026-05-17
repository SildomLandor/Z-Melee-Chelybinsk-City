if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Полиция Тонфа"
SWEP.Instructions = "Дубинка с боковой рукояткой, выдаваемая сотрудникам правоохранительных органов для борьбы с массовыми беспорядками и самообороны. Большой радиус действия и большой вес делают его эффективным инструментом для подавления подозреваемых. Тонфа обычно используется парами, по одному в каждой руке, чтобы блокировать и наносить удары противникам. Это важная часть арсенала полицейского и мощное оружие в умелых руках.\\n\\nЛКМ для атаки.\\nПКМ для блокировки."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tacint_melee/w_tonfa.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_hatchet.mdl"
SWEP.WorldModelExchange = "models/weapons/tacint_melee/w_tonfa.mdl"
SWEP.ViewModel = ""

SWEP.HoldType = "melee"

SWEP.HoldPos = Vector(-12,2,3)
SWEP.HoldAng = Angle(0,0,0)

SWEP.AttackTime = 0.45
SWEP.AnimTime1 = 1.45
SWEP.WaitTime1 = 1.15
SWEP.ViewPunch1 = Angle(0,-5,3)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-4)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(-1,-6,-8)
SWEP.weaponAng = Angle(0,0,-90)
SWEP.modelscale = 1.15

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 19
SWEP.DamageSecondary = 13

SWEP.PenetrationPrimary = 1
SWEP.PenetrationSecondary = 1

SWEP.MaxPenLen = 3

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 12
SWEP.StaminaSecondary = 8

SWEP.AttackLen1 = 40
SWEP.AttackLen2 = 30

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}


if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_zac_hmcd_policebaton")
	SWEP.IconOverride = "entities/tacrp_m_tonfa.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.AttackHit = "Plastic_Box.ImpactHard"
SWEP.Attack2Hit = "Plastic_Box.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "Plastic_Box.ImpactSoft"
SWEP.SwingSoundPitch = 115

SWEP.BlockTier = 4
SWEP.MeleeMaterial = "metal"
SWEP.BlockImpactSound = "Plastic_Box.ImpactHard"

SWEP.AttackPos = Vector(0,0,0)
--[[
function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    return true
end
]]

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:CustomBlockAnim(addPosLerp, addAngLerp)
    addPosLerp.z = addPosLerp.z + (self:GetBlocking() and -14 or 0)
    addPosLerp.x = addPosLerp.x + (self:GetBlocking() and 13.4 or 0)
    addPosLerp.y = addPosLerp.y + (self:GetBlocking() and -28 or 0)
    addAngLerp.r = addAngLerp.r + (self:GetBlocking() and -85 or 0)
    addAngLerp.y = addAngLerp.y + (self:GetBlocking() and 105 or 0)
    addAngLerp.x = addAngLerp.x + (self:GetBlocking() and 0 or 0)
    
    return true
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 85
SWEP.AttackRads2 = 0

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0