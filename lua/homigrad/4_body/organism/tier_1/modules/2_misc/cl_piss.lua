local holding

local function spawnPissParticle(emitter, pos, vel, dieTime)
	local part = emitter:Add("particle/water/waterdrop_001a", pos)
	if not part then return end
	part:SetVelocity(vel)
	part:SetDieTime(dieTime)
	part:SetStartAlpha(200)
	part:SetEndAlpha(0)
	part:SetStartSize(math.Rand(2, 4))
	part:SetEndSize(math.Rand(4, 6))
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

net.Receive("piss_particles", function()
	local startPos = net.ReadVector()
	local dir = net.ReadVector()
	local hitPos = net.ReadVector()
	local hit = net.ReadBool()

	local emitter = ParticleEmitter(startPos)
	if not emitter then return end

	local streamLen = startPos:Distance(hitPos)
	local numParticles = math.max(math.floor(streamLen / 10), 8)

	for _ = 1, math.min(numParticles, 15) do
		local frac = math.Rand(0, 1)
		local ppos = startPos + dir * streamLen * frac
		spawnPissParticle(emitter, ppos, dir * 300 + VectorRand() * 15, math.Rand(1, 1.5))
	end

	if hit then
		for _ = 1, 4 do
			local splatPos = hitPos + VectorRand() * math.Rand(2, 6)
			local splatVel = (hitPos - startPos):GetNormalized() * math.Rand(50, 150) + VectorRand() * 30
			splatVel.z = math.Rand(20, 60)
			spawnPissParticle(emitter, splatPos, splatVel, math.Rand(0.3, 0.6))
		end
	end

	emitter:Finish()
end)

local emitter

local function localPissFx(ply)
	if not IsValid(ply) then return end
	emitter = emitter or ParticleEmitter(ply:GetPos())
	local spawnPos = ply:EyePos() - Vector(0, 0, 30) + ply:GetAimVector() * 10
	emitter:SetPos(spawnPos)
	spawnPissParticle(emitter, spawnPos, ply:GetAimVector() * 300 + VectorRand() * 15, math.Rand(1, 1.5))
end

hook.Add("Think", "hg_piss_fx", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:GetNWBool("peeing") then
		if emitter then
			emitter:Finish()
			emitter = nil
		end
		return
	end
	localPissFx(ply)
end)

hook.Add("CreateMove", "hg_piss_key", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then
		if holding then
			holding = false
			net.Start("hg_piss")
			net.WriteBool(false)
			net.SendToServer()
		end
		return
	end

	if gui.IsGameUIVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

	local down = input.IsKeyDown(KEY_P)
	if down == holding then return end
	holding = down

	net.Start("hg_piss")
	net.WriteBool(down)
	net.SendToServer()
end)
