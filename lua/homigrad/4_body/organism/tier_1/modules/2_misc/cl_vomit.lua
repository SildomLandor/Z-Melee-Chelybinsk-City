local function spawnVomitParticle(emitter, pos, vel, dieTime)
	local part = emitter:Add("particle/water/waterdrop_001a", pos)
	if not part then return end
	part:SetVelocity(vel)
	part:SetDieTime(dieTime)
	part:SetStartAlpha(200)
	part:SetEndAlpha(0)
	part:SetStartSize(math.Rand(2, 4))
	part:SetEndSize(math.Rand(4, 7))
	part:SetColor(255, 230, 0)
	part:SetGravity(Vector(0, 0, -500))
	part:SetCollide(true)
	part:SetBounce(0)
	part:SetCollideCallback(function(prt, hitpos, hitnormal)
		if math.random(1, 3) == 1 then
			util.Decal("YellowBlood", hitpos + hitnormal * 5, hitpos - hitnormal * 5)
		end
		prt:SetVelocity(Vector(0, 0, -70))
		prt:SetGravity(Vector(0, 0, -50))
		prt:SetCollideCallback(function() end)
	end)
end

net.Receive("vomit_squirt", function()
	local rag, boneName, mat, pos, dir = hg.orgSquirtRead()
	if not IsValid(rag) then return end

	local ent = hg.RagdollOwner(rag) or rag
	local ply = ent
	local bone = ent:LookupBone(boneName)
	if not isnumber(bone) or not mat then return end

	local len = dir:Length()
	local localPos, localDir = WorldToLocal(pos, dir:Angle(), mat:GetTranslation(), mat:GetAngles())

	if ply == lply then
		localPos:Add(-Vector(2, -2, 0))
	end

	local name = "vomitsquirt" .. ent:EntIndex()
	local i = 50
	local maxI = i
	local emitter = ParticleEmitter(pos)

	timer.Create(name, 0.01 * game.GetTimeScale(), i + 10, function()
		if not IsValid(ent) then
			timer.Remove(name)
			if emitter then emitter:Finish() end
			return
		end

		local drawEnt = IsValid(ent.FakeRagdoll) and ent.FakeRagdoll or ent
		local amt = math.max(i / maxI, 0.2)
		if math.random(5) == 1 then return end

		local bmat = drawEnt:GetBoneMatrix(bone)
		if not bmat then
			timer.Remove(name)
			if emitter then emitter:Finish() end
			return
		end

		if ply == lply and (i == 50 or i == 25) then
			ViewPunch(Angle(15, 0, 0))
		end

		local ppos, pang = LocalToWorld(localPos, localDir, bmat:GetTranslation(), bmat:GetAngles())
		local sprayDir = pang

		if lply == ply then
			sprayDir = lply:EyeAngles()
		end

		sprayDir = sprayDir:Forward() * len
		emitter:SetPos(ppos)
		spawnVomitParticle(emitter, ppos + VectorRand(-0.2, 0.2), sprayDir * amt * 90 + VectorRand(-amt * 25, amt * 25), math.Rand(0.5, 1.2))
		i = i - 1

		if i <= 0 and emitter then
			emitter:Finish()
			emitter = nil
		end
	end)
	timer.Adjust(name, 0)
end)
