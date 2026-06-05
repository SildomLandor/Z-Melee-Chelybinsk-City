local intbin = 0.0254
local skey = { [1] = "BOMB_ZONE_A", [2] = "BOMB_ZONE_B" }

local function siteKey(site)
	return skey[site == 1 and 1 or 2]
end

function zb.InchesToMeters(units)
	return units * intbin
end

function zb.GetBombSitePoints(site)
	local key = siteKey(site)

	if CLIENT then
		local pts = zb.ClPoints and zb.ClPoints[key]
		if pts and #pts > 0 then return pts end
	end

	if SERVER and zb.GetMapPoints then
		return zb.GetMapPoints(key) or {}
	end

	return {}
end

function zb.GetBombSiteCenter(site)
	local pts = zb.GetBombSitePoints(site)
	local n = #pts
	if n == 0 then return end
	if n == 1 then return pts[1].pos end

	local c = Vector()
	for i = 1, n do
		c = c + pts[i].pos
	end
	return c / n
end

local function baseRadiusUnits()
	local cv = GetConVar("zb_bomb_site_radius")
	local m = cv and cv:GetFloat() or 25
	return math.Clamp(m, 15, 40) / intbin
end

function zb.GetBombSiteRadius(site)
	local r = baseRadiusUnits()
	local center = zb.GetBombSiteCenter(site)
	if not center then return r end

	for _, pt in ipairs(zb.GetBombSitePoints(site)) do
		r = math.max(r, pt.pos:Distance(center))
	end
	return r
end

function zb.BombInSite(pos, site)
	local center = zb.GetBombSiteCenter(site)
	if not center then return false end
	return pos:Distance(center) <= zb.GetBombSiteRadius(site)
end

function zb.BombInAnySite(pos)
	return zb.BombInSite(pos, 1) or zb.BombInSite(pos, 2)
end
