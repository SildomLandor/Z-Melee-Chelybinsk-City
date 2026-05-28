if !SERVER then return end

ZBaseNav = ZBaseNav or {}

local downLong = Vector(0, 0, -10000)
local stepDirs = {0, 32, -32, 58, -58, 90, -90, 125, -125}

local function hull(npc)
	local mn, mx = npc:GetCollisionBounds()
	return mn, mx
end

function ZBaseNav.GroundAt(pos, filter)
	local tr = util.TraceLine({
		start = pos + Vector(0, 0, 48),
		endpos = pos + downLong,
		mask = MASK_NPCWORLDSTATIC,
		filter = filter,
	})
	if !tr.Hit then return pos end
	return tr.HitPos + tr.HitNormal * 4
end

function ZBaseNav.Hull(npc, from, to, mask)
	local mn, mx = hull(npc)
	return util.TraceHull({
		start = from,
		endpos = to,
		mins = mn,
		maxs = mx,
		filter = {npc},
		mask = mask or MASK_NPCSOLID,
	})
end

function ZBaseNav.ClearAhead(npc, from, dir, dist)
	dir.z = 0
	if dir:LengthSqr() < 1 then return false end
	dir:Normalize()

	local tr = ZBaseNav.Hull(npc, from + Vector(0, 0, 4), from + dir * dist + Vector(0, 0, 4))
	return tr.Fraction > 0.92
end

function ZBaseNav.StepToward(npc, from, goal, reach)
	local flat = goal - from
	flat.z = 0
	local dist = flat:Length()
	if dist < (reach or 40) then return ZBaseNav.GroundAt(goal, npc) end

	flat:Normalize()
	local want = math.min(280, dist)
	local baseAng = flat:Angle()

	for _, yaw in ipairs(stepDirs) do
		local dir = baseAng:Forward()
		if yaw != 0 then
			dir = (baseAng + Angle(0, yaw, 0)):Forward()
		end
		dir.z = 0
		dir:Normalize()

		local to = from + dir * want
		local tr = ZBaseNav.Hull(npc, from + Vector(0, 0, 4), to + Vector(0, 0, 4))
		if tr.Fraction > 0.9 then
			return ZBaseNav.GroundAt(tr.HitPos - tr.HitNormal * 2, npc)
		end

		local upFrom = from + Vector(0, 0, 42)
		local upTo = upFrom + dir * want * 0.85
		tr = ZBaseNav.Hull(npc, upFrom, upTo)
		if tr.Fraction > 0.9 then
			return ZBaseNav.GroundAt(tr.HitPos - tr.HitNormal * 2, npc)
		end
	end

	local tr = util.TraceLine({
		start = from + Vector(0, 0, 24),
		endpos = from + flat * want,
		filter = {npc},
		mask = MASK_NPCSOLID,
	})
	return ZBaseNav.GroundAt(tr.HitPos + tr.HitNormal * 6, npc)
end

function ZBaseNav.MeshPath(fromPos, toPos, maxAreas)
	if !navmesh or !navmesh.GetNavArea then return end

	local destArea = navmesh.GetNavArea(toPos, 320)
	local startArea = navmesh.GetNavArea(fromPos, 320)
	if !destArea or !startArea then return end

	if startArea == destArea then
		return {ZBaseNav.GroundAt(toPos)}
	end

	maxAreas = maxAreas or 28
	local q, qi = {{startArea, {}}}, 1
	local seen = {[startArea] = true}

	while qi <= #q do
		local node = q[qi]
		qi = qi + 1
		local area, path = node[1], node[2]

		if area == destArea then
			local wps = {}
			for i = 1, #path do
				wps[i] = ZBaseNav.GroundAt(path[i]:GetCenter())
			end
			wps[#wps + 1] = ZBaseNav.GroundAt(toPos)
			return wps
		end

		if #path >= maxAreas then continue end

		for _, adj in ipairs(area:GetAdjacentAreas()) do
			if seen[adj] then continue end
			seen[adj] = true

			local np = {}
			for i = 1, #path do np[i] = path[i] end
			np[#np + 1] = adj

			q[#q + 1] = {adj, np}
		end
	end
end

function ZBaseNav.BuildRoute(npc, dest)
	dest = ZBaseNav.GroundAt(dest, npc)
	local from = npc:WorldSpaceCenter()

	local mesh = ZBaseNav.MeshPath(from, dest)
	if mesh and #mesh > 0 then return mesh, true end

	local route = {}
	local cursor = from
	for _ = 1, 12 do
		if cursor:DistToSqr(dest) < 3600 then break end
		local wp = ZBaseNav.StepToward(npc, cursor, dest, 48)
		if !wp or wp:DistToSqr(cursor) < 64 then break end
		route[#route + 1] = wp
		cursor = wp
	end
	route[#route + 1] = dest

	return route, false
end
