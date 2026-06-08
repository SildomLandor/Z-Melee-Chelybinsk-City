SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Nailgun"
SWEP.Author = "Various American manufacturers"
SWEP.Instructions = "An industrial nailgun, not very useful, but it's better than nothing."
SWEP.Category = "Weapons - Other"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"
SWEP.WorldModelFake = "models/weapons/nail_gun/c_smg1.mdl"

-- НАСТРОЙКА МОДЕЛИ ГВОЗДЯ
SWEP.NailModel = "models/crossbow_bolt.mdl"

SWEP.FakePos = Vector(-11, 4.5, 8.0)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0.5,-1.2,-6.5)
SWEP.AttachmentAng = Angle(0,0,0)

SWEP.FakeVPShouldUseHand = false
SWEP.podkid = 0

SWEP.IsPistol = true

SWEP.AnimList = {
    ["idle"] = "idle",
    ["reload"] = "reload",
    ["reload_empty"] = "reload",
}

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 60

local function UpdateVisualBullets(mdl,count)
    if not IsValid(mdl) then return end
    for i = 0, 13 do
        local boneid = 52 + i
        mdl:ManipulateBoneScale(boneid,i <= count and Vector(1,1,1) or Vector(0,0,0))
    end
end

SWEP.FakeReloadSounds = {
    [0.18] = "weapons/universal/uni_crawl_l_03.wav",
    [0.35] = "weapons/makarov/makarov_magrelease.wav",
    [0.4] = "weapons/arccw_ur/deagle/unjam.ogg",
    [0.55] = "weapons/newakm/akmm_magout_rattle.wav",
    [0.85] = "weapons/arccw_ur/deagle/rack1.ogg",
    [0.8] = "weapons/ak47/ak47_magout_rattle.wav",
    [0.93] = "weapons/universal/uni_crawl_l_04.wav",
}

SWEP.FakeEmptyReloadSounds = {
    [0.18] = "weapons/universal/uni_crawl_l_03.wav",
    [0.35] = "weapons/makarov/makarov_magrelease.wav",
    [0.4] = "weapons/arccw_ur/deagle/unjam.ogg",
    [0.55] = "weapons/newakm/akmm_magout_rattle.wav",
    [0.85] = "weapons/arccw_ur/deagle/rack1.ogg",
    [0.8] = "weapons/ak47/ak47_magout_rattle.wav",
    [0.93] = "weapons/universal/uni_crawl_l_04.wav",
}

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(-10,0,0)
SWEP.lmagpos2 = Vector(0,3.5,0.3)
SWEP.lmagang2 = Angle(0,0,-110)

SWEP.GunCamPos = Vector(2.2,-17,-3)
SWEP.GunCamAng = Angle(180,0,-90)

SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"

if CLIENT then
    SWEP.FakeReloadEvents = {
        [0.55] = function(self) UpdateVisualBullets(self:GetWM(),15) end
    }
end

SWEP.FakeMagDropBone = "glock_mag"
SWEP.WepSelectIcon2 = Material("vgui/inventory/nailgun.png")
SWEP.WepSelectIcon2box = false
SWEP.IconOverride = "vgui/inventory/nailgun.png"
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 2
SWEP.ShellEject = ""
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Nails" 
SWEP.Primary.Cone = 0.02
SWEP.Primary.Damage = 50 
SWEP.Primary.Force = 15  
SWEP.Primary.Wait = 0.20 

SWEP.Primary.Sound = "Weapon_Pistol.Single" 

SWEP.ReloadTime = 4
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(0, 0.7317, 7.0238)
SWEP.RHandPos = Vector(0,0,0)
SWEP.LHandPos = Vector(13,0,0)
SWEP.Ergonomics = 0.95
SWEP.WorldPos = Vector(0,-1,-1)
SWEP.WorldAng = Angle(2, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(-6.55,2.2,-2.1)
SWEP.attAng = Angle(-90,0,0)
SWEP.lengthSub = 25
SWEP.DistSound = ""
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, -3, 2)
SWEP.holsteredAng = Angle(0, 20, 30)

SWEP.OpenBolt = true
SWEP.handsAng = Angle(-5, -1, 0)

SWEP.ReloadSound = "weapons/crossbow/reload1.wav"
SWEP.ReloadSoundes = {
    "none",
    "weapons/tfa_hl2r/crossbow/crossbow_deploy.wav",
    "none", 
    "weapons/tfa_hl2r/crossbow/bolt_load2.wav",
    "none",
    "weapons/tfa_hl2r/ar2/weapon_movement1.wav",
    "none",
    "none",
    "none"
}
SWEP.AnimShootMul = 0
SWEP.AnimShootHandMul = 1
SWEP.addSprayMul = 1

SWEP.Penetration = 0
SWEP.weight = 2.5
SWEP.shouldntDrawHolstered = true

function SWEP:Shoot(override)
    if not self:CanPrimaryAttack() then return false end
    if not self:CanUse() then return false end
    if self:Clip1() == 0 then return end
    
    local primary = self.Primary
    if not self.drawBullet then
        self.LastPrimaryDryFire = CurTime()
        self:PrimaryShootEmpty()
        primary.Automatic = false
        return false
    end
    
    local owner = self:GetOwner()
    if primary.Next > CurTime() then return false end
    if (primary.NextFire or 0) > CurTime() then return false end
    
    primary.Next = CurTime() + primary.Wait
    self:SetLastShootTime(CurTime())
    primary.Automatic = weapons.Get(self:GetClass()).Primary.Automatic
    
    local tr, pos, ang = self:GetTrace(true)
    
    if SERVER then
        local point = pos
        if IsValid(owner) then
            local dist
            dist, point = util.DistanceToLine(pos, pos - ang:Forward() * 50, owner:EyePos())
        end

        local bullet = {}
        bullet.Pos = point
        bullet.Dir = ang:Forward()
        bullet.Speed = 450 
        bullet.Damage = self.Primary.Damage
        bullet.Force = self.Primary.Force
        bullet.AmmoType = "9x19" 
        bullet.Attacker = owner.suiciding and Entity(0) or owner
        bullet.IgnoreEntity = not owner.suiciding and (owner.InVehicle and owner:InVehicle() and owner:GetVehicle() or hg.GetCurrentCharacter(owner)) or nil
        bullet.Size = 0.1 
        bullet.TracerName = "Tracer"
        bullet.Penetration = 0

        hg.PhysBullet.CreateBullet(bullet)

        local traceRes = util.TraceLine({
            start = point,
            endpos = point + ang:Forward() * 400,
            filter = {owner, self}
        })

        if traceRes.Hit and not traceRes.HitSky then
            local hitEnt = traceRes.Entity
            local hitPos = traceRes.HitPos

            -- СПАВН ГВОЗДЕЙ
            if IsValid(hitEnt) and (hitEnt:IsPlayer() or hitEnt:IsNPC()) and hitEnt:Health() > 0 and hitEnt:GetPhysicsObjectCount() <= 1 then
                local nail = ents.Create("prop_dynamic")
                if IsValid(nail) then
                    nail:SetModel(self.NailModel)
                    nail:SetPos(hitPos - ang:Forward() * 1) 
                    nail:SetAngles(ang:Forward():Angle())
                    nail:SetModelScale(0.4, 0)
                    
                    local boneName = "__invalid__"
                    if hitEnt.TranslatePhysBoneToBone then
                        local physBoneIdx = hitEnt:TranslatePhysBoneToBone(traceRes.PhysicsBone or 0)
                        boneName = hitEnt:GetBoneName(physBoneIdx)
                    end
                    
                    local boneIdx = hitEnt:LookupBone(boneName) or -1
                    if boneIdx ~= -1 then
                        nail:SetParent(hitEnt, boneIdx)
                    else
                        nail:SetParent(hitEnt)
                    end
                    
                    nail:Spawn()
                    SafeRemoveEntityDelayed(nail, 60)

                    -- ИСПРАВЛЕНО: Полное удаление гвоздя при переходе игрока в регдолл
                    if hitEnt:IsPlayer() then
                        local ply = hitEnt
                        local hookID = "NailTrack_" .. nail:EntIndex()
                        
                        hook.Add("Think", hookID, function()
                            if not IsValid(nail) then 
                                hook.Remove("Think", hookID)
                                return 
                            end
                            if not IsValid(ply) then 
                                hook.Remove("Think", hookID)
                                return 
                            end
                            
                            -- Ищем регдолл в любых вариациях сборок Homigrad
                            local ragdoll = ply.ragdoll or ply.fakeRagdoll or (ply.GetNWEntity and ply:GetNWEntity("Ragdoll"))
                            if IsValid(ragdoll) then
                                nail:Remove()
                                hook.Remove("Think", hookID)
                            end
                        end)
                    end
                end
            elseif IsValid(hitEnt) and (hitEnt:GetPhysicsObjectCount() > 1 or hitEnt:GetClass() == "prop_ragdoll") then
                local nail = ents.Create("prop_physics")
                if IsValid(nail) then
                    nail:SetModel(self.NailModel)
                    nail:SetPos(hitPos - ang:Forward() * 1)
                    nail:SetAngles(ang:Forward():Angle())
                    nail:SetModelScale(0.4, 0)
                    nail:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) 
                    nail:Spawn()
                    
                    local nailPhys = nail:GetPhysicsObject()
                    if IsValid(nailPhys) then
                        nailPhys:Wake()
                    end
                    
                    constraint.Weld(nail, hitEnt, 0, traceRes.PhysicsBone or 0, 0, true, false)
                    SafeRemoveEntityDelayed(nail, 60)
                end
            else
                local nail = ents.Create("prop_dynamic")
                if IsValid(nail) then
                    nail:SetModel(self.NailModel)
                    nail:SetPos(hitPos - ang:Forward() * 1)
                    nail:SetAngles(ang:Forward():Angle())
                    nail:SetModelScale(0.4, 0)
                    
                    if IsValid(hitEnt) and hitEnt ~= game.GetWorld() then
                        nail:SetParent(hitEnt)
                    else
                        nail:SetParent(game.GetWorld())
                    end
                    
                    nail:Spawn()
                    SafeRemoveEntityDelayed(nail, 60)
                end
            end

            -- СИСТЕМА ПРИБИВАНИЯ КОСТЕЙ К ОКРУЖЕНИЮ
            if IsValid(hitEnt) and hitEnt ~= game.GetWorld() and not (hitEnt:IsPlayer() and hitEnt:Health() > 0 and hitEnt:GetPhysicsObjectCount() <= 1) then
                local wallTrace = util.TraceLine({
                    start = hitPos,
                    endpos = hitPos + ang:Forward() * 55, 
                    filter = {owner, self, hitEnt}
                })

                if wallTrace.Hit and not wallTrace.HitSky then
                    local wallEnt = wallTrace.Entity
                    if not IsValid(wallEnt) then wallEnt = game.GetWorld() end

                    if wallEnt ~= hitEnt then
                        local bone1 = traceRes.PhysicsBone or 0
                        local bone2 = wallTrace.PhysicsBone or 0
                        
                        constraint.Weld(hitEnt, wallEnt, bone1, bone2, 9000, false, false)
                        sound.Play("snd_jack_hmcd_hammerhit.wav", hitPos, 65, math.random(120, 140))
                    end
                end
            end
        end
    end

    self:EmitSound("Weapon_Pistol.Single", 75, math.random(135, 145), 1.0, CHAN_WEAPON)

    self:PrimarySpread()
    self:TakePrimaryAmmo(1)
    
    UpdateVisualBullets(self:GetWM(), self:Clip1())
end

if CLIENT then
    function SWEP:ReloadStart()
        if not self or not IsValid(self:GetOwner()) then return end
        hook.Run("HGReloading", self)
    end
end

SWEP.NoWINCHESTERFIRE = true

function SWEP:AnimHoldPost(model)
end

SWEP.LocalMuzzlePos = Vector(11.5,0.7,5.0)
SWEP.LocalMuzzleAng = Angle(3.3,-0.05,0)
SWEP.WeaponEyeAngles = Angle(-2,0,0)

SWEP.CanSuicide = true

SWEP.RHPos = Vector(5.5,-7.5,4)
SWEP.RHAng = Angle(0,-5,90)

SWEP.LHPos = Vector(14,-1,-5)
SWEP.LHAng = Angle(-90,-90,-90)

local finger1 = Angle(-15,0,5)
local finger2 = Angle(-15,45,-5)

SWEP.ReloadAnimLH = {
    Vector(0,0,0),
    Vector(-7,10,-10),
    Vector(-2,-5,0),
    Vector(1,-9,5),
    Vector(1,-7,0),
    "reloadend",
    Vector(-4,-1,0),
    Vector(0,0,0),
    Vector(0,0,0)
}
SWEP.ReloadAnimLHAng = {
    Angle(0,0,0),
    Angle(-180,180,0),
    Angle(-180,180,-45),
    Angle(-180,180,15),
    Angle(-185,185,15),
    Angle(-2,5,0),
    Angle(0,0,0),
}

SWEP.ReloadAnimRH = {
    Vector(0,0,0)
}
SWEP.ReloadAnimRHAng = {
    Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
    Angle(0,0,0),
    Angle(-5,16,1),
    Angle(-3,14,2),
    Angle(12,15,-1),
    Angle(-5,14,0),
    Angle(0,16,0),
    Angle(0,-2,-2),
    Angle(0,0,0),
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