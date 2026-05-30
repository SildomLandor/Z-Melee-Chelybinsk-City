util.AddNetworkString("hg_booom")
hg = hg or {}

local DebrisSounds = {
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave01.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave010.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave02.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave03.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave04.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave05.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave06.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave07.wav",
	"explosion_debris/interior/explosion_debris_sprinkle_interior_wave09.wav",
}

local vecCone = Vector(5, 5, 0)
local dmgBurn = DMG_BLAST_SURFACE + DMG_BLAST + DMG_BURN
local dmgBurnCoop = dmgBurn + DMG_BULLET + DMG_BUCKSHOT + DMG_AIRBOAT
local ents_FindInSphere = ents.FindInSphere
local math_random = math.random
local math_min = math.min
local math_max = math.max
local math_Clamp = math.Clamp
local IsValid = IsValid

local function boomNet(pos, kind)
	net.Start("hg_booom")
	net.WriteVector(pos)
	net.WriteString(kind)
	net.Broadcast()
end

local function debrisRattle(ent, n)
	if n <= 10 then return end
	local pos, idx = ent:GetPos(), ent:EntIndex()
	for _ = 1, 3 do
		EmitSound(DebrisSounds[math_random(#DebrisSounds)], pos, idx, CHAN_AUTO, 1, 80)
	end
end

local function blastSphere(selfPos, ent, dis, fireOrg)
	local skip = { ent }
	local nPhys = 0
	local invDis = 1 / dis
	local list = ents_FindInSphere(selfPos, dis)

	for i = 1, #list do
		local enta = list[i]
		local isPly = enta:IsPlayer()
		local org = enta.organism
		local phys = enta:GetPhysicsObject()
		local hasPhys = IsValid(phys)

		if not isPly and not org and not hasPhys then continue end
		if hasPhys then nPhys = nPhys + 1 end

		local tracePos = isPly and (enta:GetPos() + enta:OBBCenter()) or enta:GetPos()
		local tr = hg.ExplosionTrace(selfPos, tracePos, skip)

		local force = enta:GetPos() - selfPos
		local len = force:Length()
		if len < 0.001 then continue end
		force:Div(len)

		local frac = math_Clamp((dis - len) * invDis, 0.5, 1)
		local forceadd = force * (frac * 50000)

		if org then
			local behindwall = tr.Entity ~= enta and tr.MatType ~= MAT_GLASS
			local owner = org.owner
			if IsValid(owner) and owner:IsPlayer() and (fireOrg or not behindwall) then
				if fireOrg then
					local div = behindwall and 3 or 1
					hg.ExplosionDisorientation(enta, 5 * frac / div, 6 * frac / div)
				else
					hg.ExplosionDisorientation(enta, 5 * frac, 6 * frac)
				end
				hg.RunZManipAnim(owner, "shieldexplosion")
			end
		end

		if tr.Entity ~= enta then
			forceadd = forceadd / 5
			continue
		end

		if isPly then
			hg.AddForceRag(enta, 0, forceadd * 0.5, 0.5)
			hg.AddForceRag(enta, 1, forceadd * 0.5, 0.5)
			timer.Simple(0, function() hg.LightStunPlayer(enta) end)
		end

		if hasPhys then phys:ApplyForceCenter(forceadd) end
	end

	return nPhys
end

local shrapJobs = {}
local SHRAPNEL_PER_TICK = 8

local function shrapnelPump()
	for i = #shrapJobs, 1, -1 do
		local job = shrapJobs[i]
		local ent = job.ent
		if not IsValid(ent) then
			table.remove(shrapJobs, i)
		else
			local bullet = job.bullet
			local shots = math_min(job.left, SHRAPNEL_PER_TICK)

			for _ = 1, shots do
				bullet.Dir = (ent:GetForward() + VectorRand() * 0.75):GetNormalized()
				bullet.Spread = vecCone * ((job.fired + 1) / job.mass / 5)
				ent:FireLuaBullets(bullet, true)
				job.fired = job.fired + 1
			end

			job.left = job.left - shots
			if job.left <= 0 then
				ent.ShrapnelDone = true
			end

			if ent.ShrapnelDone then
				SafeRemoveEntity(ent)
				table.remove(shrapJobs, i)
			end
		end
	end

	if #shrapJobs == 0 then
		hook.Remove("Think", "hg_shrapnel")
	end
end

local function shrapFilter(ent)
	local filt = { ent }
	local drums = hg.drums2
	for d = 1, #drums do
		filt[#filt + 1] = drums[d]
	end
	return filt
end

local function shrapnelBurst(ent, selfPos, owner, force, mass, countMul, shakeRad)
	local multi = math_min(mass / 5, 20)
	local bullet = {
		Src = selfPos,
		Spread = vecCone,
		Force = 0.01,
		Damage = force,
		AmmoType = "Metal Debris",
		Attacker = owner,
		Distance = 15000,
		DisableLagComp = true,
		Filter = shrapFilter(ent),
	}

	local shots = math_max(8, math_min(multi * countMul, 64))
	ent.ShrapnelDone = nil

	util.ScreenShake(selfPos, 100, 900, 1, shakeRad)
	shrapJobs[#shrapJobs + 1] = {
		ent = ent,
		bullet = bullet,
		left = shots,
		fired = 0,
		mass = math_max(mass, 1),
	}
	if #shrapJobs == 1 then
		hook.Add("Think", "hg_shrapnel", shrapnelPump)
	end
end

local function boomCore(ent, selfPos, owner, force, blastDmg, doorPow, doorRange, fxPow, netKind)
	util.BlastDamage(ent, owner, selfPos, blastDmg, force * 2)
	hgBlastDoors(ent, selfPos, doorPow, doorRange)
	hg.ExplosionEffect(selfPos, fxPow, 80)
	boomNet(selfPos, netKind)
end

local ExpTypes = {
	Fire = function(ent, force, mass)
		local multi = math_min(mass / 10, 20)
		force = force * multi
		local selfPos = ent:LocalToWorld(ent:OBBCenter())
		local owner = ent.owner or ent
		local rad = force / 8

		boomCore(ent, selfPos, owner, force, rad / 0.01905, force / 50, force / 15, force / 0.2, "Fire")

		if not IsValid(ent) then return end
		multi = math_min(mass / 5, 20)

		local tr = util.QuickTrace(selfPos, -vector_up * 500, { ent })
		local fire = CreateVFire(game.GetWorld(), tr.HitPos, tr.HitNormal, 150 / 7 * multi, ent)
		if IsValid(fire) then fire:ChangeLife(150) end

		for _ = 1, multi / 2 do
			local randvec = VectorRand(-1000, 1000)
			randvec[3] = math_random(100, 1000)
			CreateVFireBall(20, 50, selfPos + vector_up * 10, randvec)
		end

		local dis = rad / 0.01900
		debrisRattle(ent, blastSphere(selfPos, ent, dis, true))
		shrapnelBurst(ent, selfPos, owner, force, mass, 3, 5000)
	end,

	Sharpnel = function(ent, force, mass)
		local rad = force / 8
		local selfPos = ent:LocalToWorld(ent:OBBCenter())
		local owner = ent.owner or ent

		util.BlastDamage(ent, owner, selfPos, (force / 7.5) / 0.01905, force)
		hgBlastDoors(ent, selfPos, force / 50)
		hg.ExplosionEffect(selfPos, force / 0.2, 80)
		boomNet(selfPos, "Sharpnel")

		debrisRattle(ent, blastSphere(selfPos, ent, rad / 0.01900, false))
		shrapnelBurst(ent, selfPos, owner, force, mass, 5, 5000)
	end,

	Normal = function(ent, force)
		local rad = force / 8
		local selfPos = ent:LocalToWorld(ent:OBBCenter())
		local owner = ent.owner or ent

		util.BlastDamage(ent, owner, selfPos, (force / 7.5) / 0.01905, force)
		hgBlastDoors(ent, selfPos, force / 50)
		hg.ExplosionEffect(selfPos, force / 0.2, 80)
		boomNet(selfPos, "Normal")

		debrisRattle(ent, blastSphere(selfPos, ent, rad / 0.01900, false))

		if not IsValid(ent) then return end
		util.ScreenShake(selfPos, 100, 900, 1, 2000)
		SafeRemoveEntity(ent)
	end,
}

function hg.PropExplosion(ent, expType, force, mass)
	if ent.HasExploded then return end
	ent.HasExploded = true
	ExpTypes[expType](ent, force, mass)
end

local expItems = {
	["models/props_c17/oildrum001_explosive.mdl"] = { ExpType = "Fire", Force = 75 },
	["models/props_junk/gascan001a.mdl"] = { ExpType = "Fire", Force = 40 },
	["models/props_junk/propane_tank001a.mdl"] = { ExpType = "Sharpnel", Force = 30 },
	["models/props_junk/metalgascan.mdl"] = { ExpType = "Fire", Force = 40 },
	["models/props_junk/PropaneCanister001a.mdl"] = { ExpType = "Sharpnel", Force = 40 },
	["models/props_c17/canister01a.mdl"] = { ExpType = "Sharpnel", Force = 45 },
	["models/props_c17/canister02a.mdl"] = { ExpType = "Sharpnel", Force = 45 },
	["models/props_c17/canister_propane01a.mdl"] = { ExpType = "Fire", Force = 50 },
}

hg.expItems = expItems

hook.Add("EntityTakeDamage", "ExplosiveDamage", function(target, dmginfo)
	if not IsValid(target) then return end

	local tbl = expItems[target:GetModel()]
	if not tbl then return end

	hook.Run("ExplosivesTakeDamage", target, dmginfo)

	local rnd = CurrentRound and CurrentRound()
	local coop = rnd and rnd.name == "coop"
	if (coop and dmginfo:IsDamageType(dmgBurnCoop) or dmginfo:IsDamageType(dmgBurn)) and not target.babahnut then
		target.hp = (target.hp or 50) - dmginfo:GetDamage() / (dmginfo:IsDamageType(DMG_BURN) and 12.5 or 0.5)
		if target.hp <= 0 and (not target.Volume or target.Volume > 0) then
			target.babahnut = true
			hg.PropExplosion(target, tbl.ExpType, (target.Volume or tbl.Force) * 2, target:GetPhysicsObject():GetMass())
		end
	end

	dmginfo:ScaleDamage(0)
	return true
end)
