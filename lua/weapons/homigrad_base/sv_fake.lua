--
SWEP.WorkWithFake = true
local weaponNullQueue = {}
local nullTimerActive = false

hook.Add("PlayerSwitchWeapon", "homigrad-weapons", function(ply, oldWep, newWep)
    local switch = hook.Run("PlayerSwitchInFake", ply, oldWep, newWep)
    if switch ~= nil then
        return switch
    end

    local ragdoll = ply.FakeRagdoll
    if not IsValid(ragdoll) then return end

    local weld = ragdoll.weldHuy
    if IsValid(weld) then
        weld:Remove()
        ragdoll.weldHuy = nil
    end

    if IsValid(oldWep) and oldWep.RemoveFake then
        oldWep:RemoveFake()
    end

    local canUseFake = ply.organism and ply.organism.canmove and IsValid(newWep) and newWep.WorkWithFake
    local hasFingers = ragdoll:LookupBone("ValveBiped.Bip01_R_Finger21") ~= nil
    if hasFingers then
        local targetAngle = canUseFake and Angle(0, -90, 0) or Angle(0, 0, 0)
        for i = 1, 4 do
            local boneName = "ValveBiped.Bip01_R_Finger" .. i .. "1"
            local boneIndex = ragdoll:LookupBone(boneName)
            if boneIndex then
                ragdoll:ManipulateBoneAngles(boneIndex, targetAngle)
            end
        end
    end

    if canUseFake then
        -- newWep:CreateFake(ragdoll)
    else
        ply.ActiveWeapon = newWep

        if not oldWep.Holster or oldWep:Holster(newWep) then
            weaponNullQueue[#weaponNullQueue + 1] = ply
            if not nullTimerActive then
                nullTimerActive = true
                timer.Simple(0, function()
                    for _, p in ipairs(weaponNullQueue) do
                        if IsValid(p) then
                            p:SetActiveWeapon(NULL)
                        end
                    end
                    for i = 1, #weaponNullQueue do
                        weaponNullQueue[i] = nil
                    end
                    nullTimerActive = false
                end)
            end
        end

        return true 
    end
end)

hook.Add("Fake", "weapons", function(ply, ragdoll)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.WorkWithFake and IsValid(ply.ActiveWeapon) then
		ply:SetActiveWeapon(ply.ActiveWeapon)
		--wep:CreateFake(ragdoll)
	else
		if IsValid(wep) and wep.Holster then
			wep:Holster(ply:GetWeapon("weapon_hands_sh"))
		end
		ply:SetActiveWeapon(NULL)
	end
end)

function SWEP:SetFakeGun(ent)
	self:SetNWEntity("fakeGun", ent)
	self.fakeGun = ent
end

local function GetPhysBoneNum(ent,string)
	if not IsValid(ent) then return 7 end
	return ent:TranslateBoneToPhysBone(ent:LookupBone(string))
end

function SWEP:CreateFake(ragdoll)
	if IsValid(self:GetNWEntity("fakeGun")) then return end
	if not IsValid(ragdoll) then return end
	local ent = ents.Create("prop_physics")
	local physbonelh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_L_Hand")
	local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
	local lh = ragdoll:GetPhysicsObjectNum(physbonelh)
	local rh = ragdoll:GetPhysicsObjectNum(physbonerh)
	--rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
	local _,ang = LocalToWorld(vector_origin,Angle(0,0,180),vector_origin,self:GetOwner():EyeAngles())
	--rh:SetAngles(ang)
	--lh:SetPos(rh:GetPos())
	ent:SetModel(self.WorldModel)
	ent:SetPos(rh:GetPos())
	ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
	
	for i = 1, #self:GetBodyGroups() do
		ent:SetBodygroup(i, self:GetBodygroup(i))
	end

	ent:Spawn()
	
	if !IsValid(ent:GetPhysicsObject()) then return end

	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetMoveType(MOVETYPE_NONE)
	--ent:SetOwner(ragdoll)
	ent:GetPhysicsObject():SetMass(0)
	ent.dontPickup = true
	ent.fakeOwner = self
	ragdoll:DeleteOnRemove(ent)
	ragdoll.fakeGun = ent
	if IsValid(ragdoll.ConsRH) then ragdoll.ConsRH:Remove() end
	self:SetFakeGun(ent)
	ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)

	--constraint.Weld(ent,ragdoll,0,0,0,true)
	--constraint.NoCollide(ent, ragdoll, 0, 0)

	local vec,ang = LocalToWorld(Vector(8,-2,0),Angle(0,0,180),rh:GetPos(),rh:GetAngles())

	if self.LHandPos then
		if IsValid(ragdoll.ConsLH) then ragdoll.ConsLH:Remove() end

		--lh:SetPos(vec)
		--lh:SetAngles(ang)
		--ragdoll.weldHuy = constraint.Weld(ragdoll,ragdoll,physbonelh,physbonerh,0,true)
		--constraint.Weld(ent,ragdoll,0,5,0,true)
	end

	/*

	local vec,ang = LocalToWorld(self.WorldPos,self.WorldAng,ent:GetPos(),ent:GetAngles())
	ent:SetPos(vec)

	constraint.Weld(ent,ragdoll,0,physbonerh,0,true)
	constraint.NoCollide(ent, ragdoll, 0, 0)
	if self.LHandPos then
		if IsValid(ragdoll.ConsLH) then ragdoll.ConsLH:Remove() end

		local vec,_ = LocalToWorld(self.LHPos,self.LHAng,rh:GetPos(),ang)

		lh:SetPos(vec)
		lh:SetAngles(ent:GetAngles())
		ragdoll.weldHuy = constraint.Weld(ragdoll,ragdoll,physbonelh,physbonerh,0,true)
		constraint.Weld(ent,ragdoll,0,5,0,true)
	end

	*/

	ent:SetNoDraw(true)
end

function SWEP:RemoveFake()
	if not IsValid(self.fakeGun) then return end
	self.fakeGun:Remove()
	self:SetFakeGun()
end

hook.Add("AllowPlayerPickup", "homigrad-weapons-pickup-e", function(ply, ent)
	if ply.FakeRagdoll or ent.dontPickup then
		return false
	end
end)