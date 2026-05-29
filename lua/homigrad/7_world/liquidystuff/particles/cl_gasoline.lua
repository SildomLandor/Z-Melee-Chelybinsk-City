gasparticles = gasparticles or {}
gasparticles_hook = gasparticles_hook or {}
local gasparticles_hook = gasparticles_hook

local DECAL_BUDGET = 8
local DEDUP_CELL = 4
local DEDUP_COOLDOWN = 0.15
local FAR_DIST_SQR = 2500 * 2500
local FAR_SKIP = 0.6

local recent_hits = {}

local tr_out = {}
local tr = {
	mask = MASK_SOLID_BRUSHONLY,
	output = tr_out
}

local mat = Material("effects/blooddrop")
local vecDown = Vector(0, 0, -40)
local vecZero = Vector(0, 0, 0)
local col = Color(131, 70, 21, 250)

local LerpVector = LerpVector
local math_random = math.random
local util_TraceLine = util.TraceLine
local render_SetMaterial = render.SetMaterial
local render_DrawBeam = render.DrawBeam

local function hash_hit(pos, nrm)
	return math.floor(pos.x / DEDUP_CELL) .. "," .. math.floor(pos.y / DEDUP_CELL) .. "," .. math.floor(pos.z / DEDUP_CELL)
		.. "|" .. math.floor(nrm.x * 10 + 0.5) .. "," .. math.floor(nrm.y * 10 + 0.5) .. "," .. math.floor(nrm.z * 10 + 0.5)
end

local function place_decal(hit_pos, normal)
	local lp = LocalPlayer()
	if IsValid(lp) and lp:GetPos():DistToSqr(hit_pos) > FAR_DIST_SQR and math.random() < FAR_SKIP then
		return false
	end

	util.Decal("BeerSplash", hit_pos + normal, hit_pos - normal)
	return true
end

gasparticles_hook[1] = function(anim_pos)
	for i = 1, #gasparticles do
		local part = gasparticles[i]
		local pos = LerpVector(anim_pos, part[2], part[1])
		local diff = part[2] - part[1]
		render_SetMaterial(mat)
		render_DrawBeam(pos - diff * 2, pos + diff * 2, 10, 0, 1, col)
	end
end

gasparticles_hook[2] = function(mul)
	local now = CurTime()
	local placed = 0

	for k, t in pairs(recent_hits) do
		if t <= now then recent_hits[k] = nil end
	end

	for i = #gasparticles, 1, -1 do
		local part = gasparticles[i]
		if not part then
			gasparticles[i] = gasparticles[#gasparticles]
			gasparticles[#gasparticles] = nil
			goto cont
		end

		local pos, posSet, vel = part[1], part[2], part[3]
		tr.start = posSet
		tr.endpos = posSet + vel * mul
		util_TraceLine(tr)

		if tr_out.Hit then
			if placed < DECAL_BUDGET then
				local key = hash_hit(tr_out.HitPos, tr_out.HitNormal)
				if not recent_hits[key] or recent_hits[key] <= now then
					if place_decal(tr_out.HitPos, tr_out.HitNormal) then
						recent_hits[key] = now + DEDUP_COOLDOWN
						placed = placed + 1
						sound.Play("homigrad/blooddrip" .. math_random(1, 4) .. ".wav", tr_out.HitPos, math.random(10, 60), math.random(80, 120))
					end
				end
			end
			gasparticles[i] = gasparticles[#gasparticles]
			gasparticles[#gasparticles] = nil
		else
			pos:Set(posSet)
			posSet:Set(tr_out.HitPos)
			vel = LerpVector(0.25 * mul, vel, vecZero)
			vel:Add(vecDown)
			part[3] = vel
		end

		::cont::
	end
end
