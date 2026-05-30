hg.drums = hg.drums or {}
hg.drums2 = hg.drums2 or {}
hg.gasolinePath = hg.gasolinePath or {}

local math_random = math.random
local math_Round = math.Round
local math_max = math.max
local CurTime = CurTime

local vecZero = Vector(0, 0, 0)
local angZero = Angle(0, 0, 0)

local gasModels = {
	["models/props_c17/oildrum001_explosive.mdl"] = true,
	["models/props_junk/gascan001a.mdl"] = true,
	["models/props_junk/metalgascan.mdl"] = true,
}

hg.gas_models = gasModels

local vecHole = {
	["models/props_c17/oildrum001_explosive.mdl"] = Vector(10, 0, 0),
}

PrecacheParticleSystem("env_fire_medium")

local function markGasPathDirty()
	if SERVER then hg.gasPathDirty = true end
end

if SERVER then
	util.AddNetworkString("gas particle")
	util.AddNetworkString("gasoline_path")

	local function addDrum(ent)
		if not IsValid(ent) or not gasModels[ent:GetModel()] then return end

		local maxs, mins = ent:OBBMaxs(), ent:OBBMins()
		local hole = vecHole[ent:GetModel()]
		local pos

		if hole then
			vecZero:Set(hole)
			pos = maxs + mins + vecZero
		end

		hg.drums[ent:EntIndex()] = {
			Entity = ent,
			Volume = hole and math_random(1, pos[3]) or maxs[3] * 0.8,
			high_point = {
				[1] = hole and {pos, CurTime()} or nil
			}
		}
		table.insert(hg.drums2, ent)
	end

	hook.Add("OnEntityCreated", "drum_spawn", function(ent)
		timer.Simple(0, function() addDrum(ent) end)
	end)

	local drumThinkNext = 0
	hook.Add("Think", "drum_think", function()
		local t = CurTime()
		if drumThinkNext > t then return end
		drumThinkNext = t + 0.1

		for idx, drum in pairs(hg.drums) do
			hook.Run("Drum Think", idx, drum)
		end
	end)

	local pathThinkNext = 0
	local ents_FindInSphere = ents.FindInSphere
	local IGNITE_SPREAD_SQR = 2048
	local PATH_GRID = 96
	local MAX_PATH_PER_TICK = 64
	local MAX_GAS_PATH = 2048
	local pathCursor = 1
	local pathSyncAt = 0

	local function pathCell(x, y)
		return x .. "|" .. y
	end

	local function pathCellFromVec(pos)
		return math.floor(pos[1] / PATH_GRID), math.floor(pos[2] / PATH_GRID)
	end

	local function syncGasPath(now)
		if not hg.gasPathDirty or pathSyncAt > now then return end
		hg.gasPathDirty = false
		pathSyncAt = now + 0.25
		net.Start("gasoline_path")
		net.WriteTable(hg.gasolinePath)
		net.Broadcast()
	end

	hook.Add("Think", "path_think", function()
		local t = CurTime()
		if pathThinkNext > t then return end
		pathThinkNext = t + 0.1

		local path = hg.gasolinePath
		local pathCount = #path
		if pathCount == 0 then return end
		if pathCursor > pathCount then pathCursor = 1 end

		local grid = {}
		for i = 1, pathCount do
			local tbl = path[i]
			if not tbl then continue end
			local pos = tbl[1]
			local cx, cy = pathCellFromVec(pos)
			local key = pathCell(cx, cy)
			local bucket = grid[key]
			if not bucket then
				bucket = {}
				grid[key] = bucket
			end
			bucket[#bucket + 1] = i
		end

		local processed = 0
		while processed < MAX_PATH_PER_TICK and pathCount > 0 do
			local tbl = path[pathCursor]
			pathCursor = pathCursor + 1
			if pathCursor > pathCount then pathCursor = 1 end
			processed = processed + 1

			if not tbl then continue end
			local pos, ignited = tbl[1], tbl[2]

			if isnumber(ignited) and ignited + 60 < t then
				tbl[2] = true
				markGasPathDirty()
				continue
			end

			if not isnumber(ignited) then continue end

			local cx, cy = pathCellFromVec(pos)
			for x = cx - 1, cx + 1 do
				for y = cy - 1, cy + 1 do
					local near = grid[pathCell(x, y)]
					if not near then continue end

					for _, j in ipairs(near) do
						local other = path[j]
						if not other or other == tbl or other[2] or (pos - other[1]):LengthSqr() >= IGNITE_SPREAD_SQR then continue end
						other[2] = t
						other[3] = tbl[3] or other[3]
						markGasPathDirty()
					end
				end
			end

			for _, obj in ipairs(ents_FindInSphere(pos, 32)) do
				if not IsValid(obj) or obj:GetMoveType() == MOVETYPE_NONE then continue end
				if obj:IsPlayer() and (not obj:Alive() or obj:GetMoveType() == MOVETYPE_NOCLIP or IsValid(obj.FakeRagdoll)) then continue end
				if obj:IsOnFire() or obj:WaterLevel() >= 1 then continue end

				CreateVFire(obj, obj:GetPos(), -vector_up, 100, tbl[3])
			end
		end

		syncGasPath(t)
	end)

	hook.Add("PostCleanupMap", "removetrailsofevidence", function()
		hg.drums = {}
		hg.drums2 = {}
		hg.gasolinePath = {}
		hg.gasPathDirty = true
	end)

	hook.Add("PlayerInitialSpawn", "gasoline_path_sync", function(ply)
		if #hg.gasolinePath == 0 then return end
		net.Start("gasoline_path")
		net.WriteTable(hg.gasolinePath)
		net.Send(ply)
	end)

	local vecTemp = Vector(0, 0, 0)
	local leakTr = {}

	hook.Add("Drum Think", "Main", function(idx, drum)
		local ent = drum.Entity
		if not IsValid(ent) then
			hg.drums[idx] = nil
			return
		end

		local pos = ent:GetPos()
		ent.lastvel = ent.lastvel or ent:GetVelocity()

		local diff = ent.lastvel:LengthSqr() - ent:GetVelocity():LengthSqr()
		if math.abs(diff) > 75 * 75 and drum.Volume > 1 then
			ent.lastvel = ent:GetVelocity()
			ent:EmitSound("player/footsteps/wade3.wav", 65, math.random(55, 75) * math.Clamp(2 - drum.Volume * 0.1, 1, 2))
		end

		for _, point in pairs(drum.high_point) do
			ent.Volume = drum.Volume

			local high_point = vecZero
			high_point:Set(point[1])
			high_point:Rotate(ent:GetAngles())

			local center = ent:OBBCenter()
			center:Rotate(ent:GetAngles())

			local dot = math.max(math.abs(vector_up:Dot(ent:GetUp())), 0.99)
			vecTemp[3] = drum.Volume / dot - ent:OBBCenter()[3]

			local volumePos = center + vecTemp
			volumePos:Add(ent:GetVelocity() / 8)

			if math_Round(high_point[3], 1) < math_Round(volumePos[3], 1) + 1 then
				drum.Volume = math_max(drum.Volume - 0.1, 0)
				drum.leaking = true
				drum.loopsound = drum.loopsound or CreateSound(ent, "ambient/water/leak_1.wav")
				drum.loopsound:Play()

				leakTr.start = pos + high_point
				leakTr.endpos = leakTr.start - vector_up * 256
				leakTr.filter = ent
				local tr = util.TraceLine(leakTr)

				if tr.Hit and tr.Entity == Entity(0) and (drum.lastFireCreated or 0) < CurTime() then
					drum.lastFireCreated = CurTime() + 0.2
					hg.gasolinePath[#hg.gasolinePath + 1] = {tr.HitPos, false}
					if #hg.gasolinePath > MAX_GAS_PATH then table.remove(hg.gasolinePath, 1) end
					markGasPathDirty()
				elseif tr.Entity != Entity(0) then
					tr.Entity.shouldburn = (tr.Entity.shouldburn or 0) + 1
				end

				if (drum.lastParticleNet or 0) < CurTime() then
					drum.lastParticleNet = CurTime() + 0.05
					net.Start("gas particle")
					net.WriteVector(pos + high_point)
					net.WriteVector(ent:GetVelocity() + VectorRand(-15, 15) + (pos + high_point - (center + ent:GetPos())):GetNormalized() * 60)
					net.WriteEntity(ent)
					net.SendPVS(pos + high_point)
				end
			elseif drum.loopsound then
				drum.loopsound:Stop()
				drum.leaking = false
			end

			if point[2] < CurTime() then point[2] = point[2] + 0.1 end
		end

		if drum.Volume <= 0.5 then
			if drum.loopsound then
				drum.loopsound:Stop()
				drum.loopsound = nil
			end

			ent:SetNWBool("EmptyBarrel", true)
			hg.drums[idx] = nil
		end
	end)

	hook.Add("EntityRemoved", "drum_removed", function(ent)
		local drum = hg.drums[ent:EntIndex()]
		if drum and drum.loopsound then
			drum.loopsound:Stop()
			drum.loopsound = nil
		end
		table.RemoveByValue(hg.drums2, ent)
	end)

	hook.Add("ExplosivesTakeDamage", "drum_damage", function(ent, dmgInfo)
		if !hg.drums[ent:EntIndex()] then return end
		if !(dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) or (dmgInfo:IsDamageType(DMG_SLASH) and dmgInfo:GetDamage() >= 25)) then return end

		local dmgPos = dmgInfo:GetDamagePosition()
		local tr = util.QuickTrace(dmgPos, (ent:GetPos() + ent:OBBCenter()) - dmgPos)
		if tr.Entity == ent then dmgPos = tr.HitPos end

		local drum = hg.drums[ent:EntIndex()]
		if #drum.high_point < 5 then
			drum.high_point[#drum.high_point + 1] = {WorldToLocal(dmgPos, angZero, ent:GetPos(), ent:GetAngles()), CurTime()}
		end
	end)
else
	net.Receive("drums_debug", function()
		hg.drums = net.ReadTable()
	end)

	hg.effparticles = hg.effparticles or {}

	net.Receive("gasoline_path", function()
		hg.gasolinePath = net.ReadTable()

		for i, eff in pairs(hg.effparticles) do
			if hg.gasolinePath[i] then continue end
			if eff and eff:IsValid() then
				eff:StopEmissionAndDestroyImmediately()
			end
		end
	end)

	hook.Add("PreDrawEffects", "fireeffects", function()
		local t = CurTime()
		for i, tbl in ipairs(hg.gasolinePath) do
			local ignited = tbl[2]
			local eff = hg.effparticles[i]

			if isnumber(ignited) and (!eff or !eff:IsValid()) then
				hg.effparticles[i] = CreateParticleSystemNoEntity("vFire_Base_Medium", tbl[1], AngleRand() * 5)
				eff = hg.effparticles[i]
			end

			if not eff or !eff:IsValid() then continue end

			if ignited == true or (isnumber(ignited) and ignited + 60 < t) then
				eff:StopEmission()
			end
		end
	end)

	hook.Add("PostCleanupMap", "removetrailsofevidence", function()
		hg.gasolinePath = {}
		for _, eff in pairs(hg.effparticles) do
			if eff and eff:IsValid() then
				eff:StopEmissionAndDestroyImmediately()
			end
		end
	end)
end
