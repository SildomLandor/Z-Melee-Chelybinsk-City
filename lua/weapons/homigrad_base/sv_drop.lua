hg = hg or {}

local vpang = Angle(1,-2,1)
local function drop(ply, wep, newWeapon, vel)
	local wep = isentity(wep) and wep or ply:GetActiveWeapon()
	if not IsValid(wep) or wep.NoDrop then return end
	if ply:GetNWFloat("willsuicide", 0) > 0 then return end -- you cant escape.
	local eyeAngles = ply:LocalEyeAngles()
	local isWep = wep.ismelee2 or ishgweapon(wep)
	ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)
	ply:ViewPunch(vpang)
	timer.Simple(isWep and 0.0 or 0.0,function()
		if not IsValid(ply) or not IsValid(wep) then return end
		local pos, ang
		
		if wep.WorldModel_Transform then
			pos, ang = wep:WorldModel_Transform(true)
		end
		
		if not IsValid(newWeapon) then
			ply:SelectWeapon("weapon_hands_sh")
			ply:SetActiveWeapon(ply:GetWeapon("weapon_hands_sh"))
		else
			ply:SelectWeapon(newWeapon:GetClass())
			ply:SetActiveWeapon(newWeapon)
		end

		ply:DropWeapon(wep, nil, not IsValid(wep.fakeGun) and (eyeAngles:Forward() * (isnumber(vel) and vel or 250)) + ply:GetVelocity() or nil)
		
		wep.init = true
		wep.IsSpawned = true

		timer.Simple(0,function()
			if pos and ang then
				local tr = {}
				tr.start = ply:EyePos()
				tr.endpos = pos
				tr.filter = {ply,wep}
				tr.mask = MASK_SOLID
				local tr = util.TraceLine(tr)
				if tr.Hit then pos = ply:EyePos() end
				wep:SetPos(pos)
				wep:SetAngles(ang)
			end
		end)

		ply:ViewPunch(Angle(-1,5,-2))
		wep:SetOwner()
		if IsValid(wep.fakeGun) then wep:RemoveFake() end	
	end)
end

hg.drop = drop

concommand.Add("drop", drop)
concommand.Add("dropweapon", drop)
concommand.Add("-drop", drop)
concommand.Add("-dropweapon", drop)
local whitelist = {
	["*drop"] = true,
	["/drop"] = true,
	["!drop"] = true
}

local shoveNext = shoveNext or {}
local shoveMins = Vector(-10, -10, -8)
local shoveMaxs = Vector(10, 10, 8)
local shoveFilter = {
	["weapon_hands_sh"] = true
}
local shoveProp = {
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_ragdoll"] = true
}

local function shove(ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local org = ply.organism
	if org and org.otrub then return end
	if ply:InVehicle() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end
	if not shoveFilter[wep:GetClass()] then return end

	local ct = CurTime()
	if (shoveNext[ply] or 0) > ct then return end

	local eye = ply:EyePos()
	local aim = ply:GetAimVector()
	local tr = util.TraceHull({
		start = eye,
		endpos = eye + aim * 72,
		filter = {ply, hg.GetCurrentCharacter(ply)},
		mins = shoveMins,
		maxs = shoveMaxs,
		mask = MASK_SHOT_HULL
	})

	local ent = tr.Entity
	if not IsValid(ent) then return end

	local isHuman = (ent:IsPlayer() and ent ~= ply and ent:Alive()) or ent:IsNPC()
	local isProp = shoveProp[ent:GetClass()] or false
	if not isHuman and not isProp then return end

	shoveNext[ply] = ct + 0.65
	ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND)
	ply:ViewPunch(Angle(-2, math.Rand(-2, 2), 0))

	if isHuman then
		ent:SetVelocity(aim * 260 + Vector(0, 0, 40))
	elseif isProp then
		local phys = ent:GetPhysicsObjectNum(tr.PhysicsBone or 0)
		if IsValid(phys) then
			local mass = math.max(phys:GetMass(), 1)
			local massK = math.Clamp(70 / mass, 0.08, 1)
			local push = 24000 * massK
			phys:Wake()
			phys:ApplyForceOffset(aim * push, tr.HitPos)
		end
	end

	ply:SetVelocity(-aim * 35)
	sound.Play("Flesh.ImpactSoft", tr.HitPos, 65, math.random(96, 108))
end

hook.Add("HG_PlayerSay", "homigrad-drop-weapons", function(ply, txtTbl, text)
	if whitelist[text] then
		drop(ply)
		txtTbl[1] = ""
	end
end)

concommand.Add("hg_shove", shove)