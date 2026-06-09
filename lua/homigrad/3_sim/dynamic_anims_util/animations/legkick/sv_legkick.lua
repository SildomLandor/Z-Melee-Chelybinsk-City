local PLAYER = FindMetaTable("Player")

local function PlyGrounded(ply)
    if ply:IsOnGround() then return true end
    local tr = util.TraceLine({
        start = ply:GetPos() + ply:OBBCenter(),
        endpos = ply:GetPos() + ply:OBBCenter() - Vector(0, 0, 14),
        filter = ply,
    })
    return tr.Hit
end

local function LegKickFreeze(ply, cmd, mv, mul)
    if ply:GetNWFloat("InLegKick", 0) <= CurTime() then return end

    cmd:SetForwardMove(0)
    cmd:SetSideMove(0)
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    cmd:RemoveKey(IN_FORWARD)
    cmd:RemoveKey(IN_BACK)
    cmd:RemoveKey(IN_MOVELEFT)
    cmd:RemoveKey(IN_MOVERIGHT)
    cmd:RemoveKey(IN_SPEED)
    cmd:RemoveKey(IN_JUMP)

    ply.MovementInertia = vector_origin
    ply.LastVelocity = vector_origin
    ply.LastVelocityLen = 0
    ply.CurrentSpeed = 0
    if mul then mul[1] = 0 end
end

hook.Add("HG_MovementCalc_2", "HG-LegKickStop", function(mul, ply, cmd, mv)
    LegKickFreeze(ply, cmd, mv, mul)
end)

hook.Add("FinishMove", "HG-LegKickStop", function(ply, mv)
    if ply:GetNWFloat("InLegKick", 0) <= CurTime() then return end
    if not PlyGrounded(ply) then return end
    local vel = mv:GetVelocity()
    mv:SetVelocity(Vector(0, 0, vel.z))
end)

-- Функция физического пинка, когда игрок лежит в регдолле
function PLAYER:RagdollKick(rag)
    if self:GetNWFloat("InLegKick", 0) > CurTime() then return end
    
    local org = self.organism
    if org and org.stamina then
        -- Если стамины слишком мало, не даем ударить лежа
        if org.stamina[1] < 15 then 
            self:Notify("Недостаточно сил для удара!", 1, "УСТАЛОСТЬ", 0)
            return 
        end
        -- Тратим стамину (25 единиц, с учетом супербойца меньше)
        local staminaCost = 25
        org.stamina.subadd = org.stamina.subadd + staminaCost / (org.superfighter and 2 or 1)
    end

    -- Ставим задержку (кулдаун) на следующий удар (0.9 секунды)
    local kickEnd = CurTime() + 0.9
    self.InLegKick = kickEnd
    self:SetNWFloat("InLegKick", kickEnd)
    
    local boneIdx = rag:LookupBone("ValveBiped.Bip01_R_Foot")
    if not boneIdx then return end
    local phys = rag:GetPhysicsObjectNum(rag:TranslatePhysBoneToBone(boneIdx))
    
    if IsValid(phys) then
        local dir = self:EyeAngles():Forward()
        
        -- Звук замаха одежды перед ударом
        self:EmitSound("player/clothes_generic_foley_0" .. math.random(1,5) .. ".wav", 65)

        -- Эффект группировки: сначала подтягиваем таз, а через микро-таймер толкаем ногу
        local pelvis = rag:GetPhysicsObjectNum(rag:TranslatePhysBoneToBone(rag:LookupBone("ValveBiped.Bip01_Pelvis")))
        if IsValid(pelvis) then
            pelvis:ApplyForceOffset(-dir * 8000, rag:GetBonePosition(rag:LookupBone("ValveBiped.Bip01_Pelvis")))
        end

        timer.Simple(0.1, function()
            if not IsValid(rag) or not IsValid(phys) then return end
            
            -- Выбрасываем ногу вперед
            phys:ApplyForceOffset(dir * 25000, rag:GetBonePosition(boneIdx))
            rag:EmitSound("player/shove_0" .. math.random(1,5) .. ".wav", 65)

            -- Трассировка урона от самой ноги регдолла
            local tr = util.TraceHull({
                start = rag:GetBonePosition(boneIdx),
                endpos = rag:GetBonePosition(boneIdx) + dir * 65,
                mins = Vector(-8, -8, -8),
                maxs = Vector(8, 8, 8),
                filter = {rag, self}
            })
            
            if tr.Hit and IsValid(tr.Entity) then
                local dmg = 12
                if org and org.stamina and org.stamina.max then
                    local speedmul = (2 - (org.stamina[1] / org.stamina.max))
                    dmg = dmg * (2 - speedmul)
                end
                dmg = dmg * (self:IsBerserk() and org.berserk * 5 or 1)
                dmg = dmg * (org and org.legstrength or 1)

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker(self)
                dmginfo:SetDamage(dmg)
                dmginfo:SetDamageType(DMG_CLUB)
                dmginfo:SetDamageForce(dir * 4000)
                tr.Entity:TakeDamageInfo(dmginfo)
                
                if tr.Entity:IsPlayer() or tr.Entity:GetClass() == "prop_ragdoll" then
                    tr.Entity:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 70, math.random(90, 100))
                    if tr.Entity:IsPlayer() then
                        hg.Fake(tr.Entity)
                        tr.Entity:SetVelocity(dir * 400)
                    end
                end
            end
        end)
    end
end

local vpang = Angle(2, -1, 1)
function PLAYER:LegAttack()
    -- ПРОВЕРКА НА РЕГДОЛЛ: если у игрока активен FakeRagdoll, пинаем физикой лежа
    local rag = self.FakeRagdoll
    if IsValid(rag) then
        self:RagdollKick(rag)
        return
    end

    -- Стандартная проверка живого игрока (твой код)
    if not self:Alive() or hg.GetCurrentCharacter(self):IsRagdoll() or self:GetNWFloat("InLegKick",0) > CurTime() then return end
    if self.InLegKick and self.InLegKick > CurTime() then return end
    if self:GetNWBool("TauntStopMoving", false) then return end
    if hook.Run( "PlayerCanLegAttack", self ) == false then return end

    local isSprintKick = self:IsSprinting() and PlyGrounded(self)
    local isAirKick = not PlyGrounded(self) and self:GetVelocity().z > 40

    local handClass = "weapon_hands_sh"
    if self:HasWeapon("weapon_hg_coolhands") then
        handClass = "weapon_hg_coolhands"
    else
        handClass = "weapon_hands_sh"
    end

    local hands = self:GetWeapon(handClass)
    if not IsValid(hands) then
        self:Notify("Where is your hands swep???", 1, "WHERE YOUR HANDS AT??", 0)
    return end

    local anim = "kick_pistol_base"
    if isAirKick then
        anim = "kick_pistol_45_base"
    elseif isSprintKick then
        anim = "kick_pistol_25_base"
    else
        anim = (self:KeyDown(IN_DUCK) or self:Crouching()) and "kick_pistol_base_crouch" or self:EyeAngles()[1] > 60 and "curbstomp_base" or self:EyeAngles()[1] > 35 and "kick_pistol_25_base" or self:EyeAngles()[1] > 20 and "kick_pistol_45_base" or anim
    end

    self:EmitSound("player/clothes_generic_foley_0" .. math.random(1,5) .. ".wav",65)

    local org = self.organism
    local staminaCost = (anim == "curbstomp_base" and 12 or 20)
    
    if isAirKick then 
        staminaCost = staminaCost * 1.75 
    elseif isSprintKick then
        staminaCost = staminaCost * 1.5
    end
    
    org.stamina.subadd = org.stamina.subadd + staminaCost / (org.superfighter and 2 or 1)
    
    local speedmul = (2 - (org.stamina[1] / org.stamina.max))
    local speed = 1.5 * speedmul
    
    if isAirKick then 
        speed = speed * 0.85 
    elseif isSprintKick then
        speed = speed * 0.95
    end
    
    local animstopAdjust = 0.3 * speedmul
    
    local currentVelocity = self:GetVelocity():Length()
    local velocityDmgBonus = math.Clamp(currentVelocity / 150, 1, 2.2)
    
    local dmg = anim == "curbstomp_base" and 22 or 10 * (2 - speedmul)
    
    if isAirKick or isSprintKick then 
        dmg = dmg * velocityDmgBonus
    end
    
    dmg = dmg * (self:IsBerserk() and org.berserk * 5 or 1)
    dmg = dmg * (org.legstrength or 1)

    local kickEnd = CurTime() + speed - animstopAdjust
    self.InLegKick = kickEnd
    self:SetNWFloat("InLegKick", kickEnd)

    if isAirKick then
        local launchAng = self:EyeAngles()
        launchAng[1] = 0
        self:SetVelocity(launchAng:Forward() * 180 + Vector(0, 0, -50))
    else
        local v = self:GetVelocity()
        self:SetVelocity(Vector(0, 0, v.z))
    end

    self:PlayCustomAnims(anim, true, speed, isAirKick, animstopAdjust, {
        [0.12] = function(self)
            if hg.GetCurrentCharacter(self):IsRagdoll() then return end
            if not isAirKick and not self:IsOnGround() then self:PlayCustomAnims("") return end
        end,
        [0.21] = function(self)
            if hg.GetCurrentCharacter(self):IsRagdoll() then return end
            if not isAirKick and not self:IsOnGround() then self:PlayCustomAnims("") return end
            local ang = self:EyeAngles()
            if ang[1] > 55 and not (self:KeyDown(IN_DUCK) or self:Crouching()) then
                self:ViewPunch(vpang)
            else
                self:ViewPunch(-vpang)
            end
        end,
        [0.33] = function(self)
            if hg.GetCurrentCharacter(self):IsRagdoll() then return end
            if not isAirKick and not self:IsOnGround() then self:PlayCustomAnims("") return end
            
            local missed = true
            local ang = self:EyeAngles()
            ang[1] = 0

            self:EmitSound("player/shove_0" .. math.random(1,5) .. ".wav",65)

            local inDuck = (self:KeyDown(IN_DUCK) or self:Crouching()) and not isAirKick and not isSprintKick
            ang = self:EyeAngles()
            ang[1] = inDuck and 0 or math.max(ang[1],10)

            local reportPos = self:GetPos() + self:OBBCenter() + self:GetUp() * ( -5 )
            local rad = Vector(5,5,5)
            local kickRange = (isAirKick or isSprintKick) and 110 or 82
            
            local tr = util.TraceHull({
                start = (inDuck and reportPos) or self:EyePos(),
                endpos = ((inDuck and reportPos) or self:EyePos()) + ang:Forward() * kickRange ,
                filter = {hg.GetCurrentCharacter(self),self},
                maxs = rad,
                mins = -rad
            })

            local org = self.organism
            if org.rleg == 1 or org.rlegdislocation then
                org.painadd = org.painadd + 20
            end
            
            local entss = {}
            if !table.HasValue(entss, tr.Entity) then
                entss[#entss+1] = tr.Entity
            end
            local soundplayed = false
            local blacklist = {[self] = true, [hg.GetCurrentCharacter(self)] = true}
            if tr.Hit then
                soundplayed = true
                missed = false
                if org.rleg == 1 or org.rlegdislocation then
                    org.painadd = org.painadd + 20
                end
                self:EmitSound("weapons/melee/blunt_light" .. math.random(1,8) .. ".wav")
            end

            if tr.Entity.fires then
            local key, fire = next(tr.Entity.fires)

                if key then 
                    tr.Entity.fires[key] = nil

                    if IsValid(key) then
                        key:Remove()
                    end
                end
            end

            for k,ent in ipairs(entss) do
                if IsValid(ent) and not blacklist[ent] then
                    local normal = ang:Forward()
                    local phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
                    if !ent:IsPlayer() and not IsValid(phys) then continue end
                    if not soundplayed then
                        soundplayed = true
                        missed = false

                        if org.rleg == 1 or org.rlegdislocation then
                            org.painadd = org.painadd + 20
                        end

                        self:EmitSound("weapons/melee/blunt_light" .. math.random(1,8) .. ".wav")
                    end

                    local dmginfo = DamageInfo()

                    dmginfo:SetAttacker(self)
                    local inflictor = self:GetWeapon(handClass)
                    dmginfo:SetInflictor(inflictor)
                    dmginfo:SetDamage(dmg)
                    dmginfo:SetDamageForce(normal * dmg)
                    dmginfo:SetDamageType((ent:GetClass() == "func_breakable_surf") and DMG_SLASH or DMG_CLUB)
                    dmginfo:SetDamagePosition(tr.HitPos)

                    PenetrationGlobal = 1
                    MaxPenLenGlobal = 1
                    hg.AddForceRag(ent, tr.PhysicsBone or 0, normal * dmg * 1000, 0.25)
                    ent:TakeDamageInfo(dmginfo)
                    
                    if IsValid(phys) then
                        phys:ApplyForceOffset(normal * dmg * 200, tr.HitPos)
                    end

                    if ent:IsPlayer() or ent:GetClass() == "prop_ragdoll" then
                        ent:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 60, math.random(85, 105), 0.6)
                    end

                    if ent:IsPlayer() then
                        local knockChance = (isAirKick or isSprintKick) and 1 or 5
                        if math.random(1, knockChance) > 1 or isAirKick or isSprintKick then
                            timer.Simple(0,function()
                                hg.Fake(ent)
                            end)
                        end

                        local pushForce = (isAirKick or isSprintKick) and (150 * velocityDmgBonus) or 150
                        ent:SetVelocity(normal * pushForce)
                    end
                    if hgIsDoor and hgIsDoor(ent) and !ent:GetNoDraw() then
                        ent.HP = ent.HP or 200
                        local doorDmgMul = (isAirKick or isSprintKick) and 3 or 2
                        ent.HP = ent.HP - dmg * (tr.MatType == MAT_METAL and 1 or doorDmgMul)
                        ent:EmitSound( "physics/wood/wood_crate_impact_hard" .. math.random(1,4) .. ".wav" )
                        
                        if DoorIsOpen(ent) then
                            if !DoorIsOpen2(ent) then
                                if ent.FastOpenDoor then
                                    ent:FastOpenDoor(self, 5, true)
                                end
                                local oldname = self:GetName()
                                self:SetName(oldname..self:EntIndex())
                                if ent:GetClass() == "func_door_rotating" then
                                    ent:Fire("open", self:GetName(), 0, self, self)
                                elseif ent:GetClass() == "prop_door_rotating" then
                                    ent:Fire("openawayfrom", self:GetName(), 0, self, self)
                                end
                                self:SetName(oldname)
                            else
                                if ent.FastOpenDoor then
                                    ent:FastOpenDoor(self, 2, true)
                                end
                                ent:Fire("Close", oldname, 0, self, self)
                            end

                            ent:EmitSound("physics/wood/wood_box_impact_hard3.wav")
                        end

                        if ent.HP <= 0 then
                            hgBlastThatDoor(ent, normal * 125)
                        end
                    end
                end
            end

            if isAirKick and missed then
                timer.Simple(0, function()
                    if IsValid(self) then
                        hg.Fake(self)
                        local pain = self.organism
                        if pain then
                            pain.painadd = pain.painadd + 15
                        end
                    end
                end)
            elseif isSprintKick and missed then
                timer.Simple(0, function()
                    if IsValid(self) then
                        local pain = self.organism
                        if pain then
                            pain.painadd = pain.painadd + 8
                        end
                        self:SetVelocity(self:GetVelocity() * 0.2)
                    end
                end)
            end
        end
    })
end

concommand.Add("hg_kick", function(ply)
    if IsValid(ply) then ply:LegAttack() end
end)