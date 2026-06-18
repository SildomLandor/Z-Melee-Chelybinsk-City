if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Мачете"
SWEP.Instructions = "Мачете — это широкое лезвие, используемое либо в качестве сельскохозяйственного орувая, похожего на топор, либо в бою, как нож с длинным лезвием.\n\nЛКМ для атаки (Зажмите для СИЛЬНОГО удара).\nПКМ, чтобы блокировать."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/melee/w_ws_pamachete.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_machete.mdl"
SWEP.WorldModelExchange = "models/weapons/melee/w_ws_pamachete.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(20, 1, -27)
SWEP.SuicideAng = Angle(-90, -180, 90)
SWEP.SuicideCutVec = Vector(3, -6, 0)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "weapons/knife/knife_hit1.wav"
SWEP.CanSuicide = true
SWEP.SuicideWT = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.NoHolster = true
SWEP.shouldntDrawHolstered = false
SWEP.holsteredBone = "ValveBiped.Bip01_spine2"
SWEP.holsteredPos = Vector(15, -3.2, 3)
SWEP.holsteredAng = Angle(30, 180, -90)
SWEP.DeployRHPos = Vector(15, -3.2, 3)
SWEP.DeployRHAng = Angle(0, 0, 0)

SWEP.HoldType = "melee"
SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-15,4,-2)
SWEP.HoldAng = Angle(-2,0,-4)

SWEP.AttackTime = 0.5
SWEP.AnimTime1 = 1.75
SWEP.WaitTime1 = 1.35
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.15
SWEP.AnimTime2 = 0.7
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(1,2,-2)

SWEP.ViewPunchDiv = -50

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,5,0)
SWEP.weaponAng = Angle(90,0,0)

SWEP.DamagePrimary = 29
SWEP.DamageSecondary = 3
SWEP.BleedMultiplier = 1.25
SWEP.PainMultiplier = 1.15

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 0

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 0

SWEP.StaminaPrimary = 28
SWEP.StaminaSecondary = 10

SWEP.AttackLen1 = 50
SWEP.AttackLen2 = 35
SWEP.weight = 1.35

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
    SWEP.WepSelectIcon = Material("entities/zcity/machete.png")
    SWEP.IconOverride = "entities/zcity/machete.png"
    SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "weapons/knife/knife_hit1.wav"
SWEP.Attack2HitFlesh = "physics/flesh/flesh_impact_hard1.wav"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"
SWEP.SwingSound = "machete/macheteswing1.ogg"
SWEP.HitFleshExtra = {
    "machete/machetehit1.ogg",
    "machete/machetehit2.ogg",
    "machete/machetehit3.ogg",
    "machete/machetehit4.ogg",
    "machete/machetehit5.ogg",
    "machete/machetehit6.ogg",
}
SWEP.HitFleshExtraPitch = 75
SWEP.ArteryChance = 1
SWEP.SwingSoundPitch = 85

SWEP.BlockTier = 4
SWEP.MeleeMaterial = "metal"
SWEP.BlockImpactSound = "physics/metal/metal_solid_impact_bullet1.wav"

SWEP.AttackPos = Vector(0,0,0)

-- Переменные замаха
SWEP.IsCharging = false
SWEP.ChargeStart = 0
SWEP.IsHeavyAttack = false

-- Вывод надписи сверху экрана при доставании оружия
function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():PrintMessage(HUD_PRINTCENTER, "МАЧЕТЕ: Удерживайте ЛКМ для СИЛЬНОГО УДАРА!")
    end

    self.IsCharging = false
    self.IsHeavyAttack = false

    if self.BaseClass and self.BaseClass.Deploy then
        return self.BaseClass.Deploy(self)
    end
    return true
end

function SWEP:CanSecondaryAttack()
    local owner = self:GetOwner()
    if owner.organism and owner.organism.larmamputated then return end

    self.DamageType = DMG_CLUB
    self.AttackHit = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.Attack2Hit = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.Attack2HitFlesh = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.setlh = true
    self.HoldType = "duel"
    timer.Simple(0.5,function()
        if IsValid(self) then
            self.setlh = false
            self.HoldType = "slam"
        end
    end)
    return false
end

function SWEP:CanPrimaryAttack()
    if self.IsHeavyAttack then
        self.DamageType = DMG_SLASH
        self.AttackHit = "weapons/knife/knife_hit1.wav"
        self.Attack2Hit = "weapons/knife/knife_hit1.wav"
        self.AttackHitFlesh = "physics/flesh/flesh_squish_hard1.wav" -- Хрустящий звук разрыва плоти
        self.ViewPunch1 = Angle(5, 3, -3)
    else
        self.DamageType = DMG_SLASH
        self.AttackHit = "snd_jack_hmcd_knifehit.wav"
        self.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
        self.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
        self.ViewPunch1 = Angle(1, 2, 0)
    end
    return true
end

-- Перехват кнопки ЛКМ для накопления силы
function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    
    if not self.IsCharging then
        self.IsCharging = true
        self.ChargeStart = CurTime()
    end
end

-- Отслеживание зажатия кнопки в Think
function SWEP:Think()
    if self.BaseClass and self.BaseClass.Think then
        self.BaseClass.Think(self)
    end

    if self.IsCharging then
        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:Alive() then
            self.IsCharging = false
            return
        end

        local holdTime = CurTime() - self.ChargeStart

        -- Если отпустили кнопку или удерживают дольше максимальных 1.5 секунд (авто-удар)
        if not owner:KeyDown(IN_ATTACK) or holdTime >= 1.5 then
            self.IsCharging = false
            
            if holdTime >= 1.0 then
                -- СИЛЬНЫЙ УДАР (удерживали дольше 1 секунды)
                self.IsHeavyAttack = true
                self.DamagePrimary = 75  -- Огромный рубящий урон
                self.AttackLen1 = 65     -- Увеличенная дистанция (выпад вперед)
                self.StaminaPrimary = 45 -- Тратит больше стамины
                
                if self.BaseClass and self.BaseClass.PrimaryAttack then
                    self.BaseClass.PrimaryAttack(self)
                end
            else
                -- ОБЫЧНЫЙ УДАР (быстрый клик)
                self.IsHeavyAttack = false
                self.DamagePrimary = 29
                self.AttackLen1 = 50
                self.StaminaPrimary = 28
                
                if self.BaseClass and self.BaseClass.PrimaryAttack then
                    self.BaseClass.PrimaryAttack(self)
                end
            end
        end
    end
end

-- Логика расчленения ног и вывода текста сверху экрана
function SWEP:PrimaryAttackAdd(ent, trace)
    if not IsValid(ent) then return end
    
    if self.IsHeavyAttack then
        if SERVER then
            -- Отбрасывание тела от сильного удара
            if ent:IsPlayer() or ent:IsNPC() then 
                ent:SetVelocity(trace.Normal * 160 * (ent:IsNPC() and 35 or 5)) 
            end
            local phys = ent:GetPhysicsObjectNum(trace.PhysicsBone or 0)
            if IsValid(phys) then
                phys:ApplyForceOffset(trace.Normal * 100 * 100, trace.HitPos)
            end
            
            -- Проверяем попадание по игроку и отрываем ногу
            if ent:IsPlayer() then
                local hitgroup = trace.HitGroup
                
                if hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
                    local isLeft = (hitgroup == HITGROUP_LEFTLEG)
                    local boneName = isLeft and "ValveBiped.Bip01_L_Thigh" or "ValveBiped.Bip01_R_Thigh"
                    local boneIdx = ent:LookupBone(boneName)
                    
                    -- 1. Физическое (визуальное) отрывание ноги на модельке игрока
                    if boneIdx then
                        ent:ManipulateBoneScale(boneIdx, Vector(0, 0, 0)) -- Сжимаем ногу в 0, она исчезает
                    end
                    
                    -- 2. Спавн крови и кусков мяса (гибов) на месте удара
                    local effectdata = EffectData()
                    effectdata:SetOrigin(trace.HitPos)
                    effectdata:SetScale(10)
                    util.Effect("BloodImpact", effectdata)
                    
                    for i = 1, 6 do
                        local gib = ents.Create("prop_physics")
                        if IsValid(gib) then
                            gib:SetModel("models/gibs/hgibs.mdl") -- Дефолтные куски плоти HL2
                            gib:SetPos(trace.HitPos + VectorRand() * 4)
                            gib:Spawn()
                            local gPhys = gib:GetPhysicsObject()
                            if IsValid(gPhys) then
                                gPhys:VelocityInitiateEntity(trace.Normal * 150 + VectorRand() * 120)
                            end
                            SafeRemoveEntityDelayed(gib, 8) -- Удаляем мясо через 8 сек
                        end
                    end
                    
                    -- Звуки сочного разрыва суставов
                    ent:EmitSound("physics/flesh/flesh_break1.wav", 95, 80)
                    ent:EmitSound("ambient/levels/canals/toxic_slime_sizzle1.wav", 85, 95)
                    
                    -- 3. Вывод сообщений СВЕРХУ ЭКРАНА для обоих игроков
                    local legText = isLeft and "ЛЕВУЮ" or "ПРАВУЮ"
                    ent:PrintMessage(HUD_PRINTCENTER, "ВАМ ОТОРВАЛО " .. legText .. " НОГУ!")
                    if IsValid(self:GetOwner()) then
                        self:GetOwner():PrintMessage(HUD_PRINTCENTER, "ВЫ ОТОРВАЛИ ЕМУ " .. legText .. " НОГУ!")
                    end
                    
                    -- 4. Интеграция с твоей медицинской системой (organism)
                    if ent.organism then
                        if isLeft then
                            ent.organism.llegamputated = true
                        else
                            ent.organism.rlegamputated = true
                        end
                        if ent.SyncOrganism then ent:SyncOrganism() end
                    end
                    
                    -- Шоковое замедление из-за потери конечности
                    ent:SetWalkSpeed(ent:GetWalkSpeed() * 0.35)
                    ent:SetRunSpeed(ent:GetRunSpeed() * 0.35)
                    
                elseif hitgroup == HITGROUP_HEAD then
                    -- Бонус: Сильный удар мачете в голову — мгновенное обезглавливание/смерть
                    ent:PrintMessage(HUD_PRINTCENTER, "ВАС ОБЕЗГЛАВИЛИ!")
                    if IsValid(self:GetOwner()) then
                        self:GetOwner():PrintMessage(HUD_PRINTCENTER, "ВЫ СНЕСЛИ ЕМУ ГОЛОВУ!")
                    end
                    
                    local dmg = DamageInfo()
                    dmg:SetDamage(ent:Health() * 5)
                    dmg:SetDamageType(DMG_SLASH)
                    dmg:SetAttacker(self:GetOwner())
                    dmg:SetInflictor(self)
                    ent:TakeDamageInfo(dmg)
                end
            end
        end
    end
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.05

SWEP.AttackRads = 65
SWEP.AttackRads2 = 35

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = true
SWEP.MultiDmg2 = false

function SWEP:SecondaryAttackAdd(ent, trace)
    if trace.Entity:IsPlayer() or trace.Entity:IsNPC() then trace.Entity:SetVelocity(trace.Normal * 70 * (trace.Entity:IsNPC() and 35 or 5)) end
    local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

    if IsValid(phys) then
        phys:ApplyForceOffset(trace.Normal * 42 * 100,trace.HitPos)
    end
end

SWEP.MinSensivity = 0.25