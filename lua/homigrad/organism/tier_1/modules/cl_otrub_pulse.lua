local e = {
	h = ScreenScaleH(30),
	p = {},
	max = 320,
	i = 1,
	n = 0,
	b = 0,
	hm = 0,
	rr = 0,
}

for i = 1, e.max do
	e.p[i] = 0
end

local function g()
	local p = LocalPlayer()
	if not IsValid(p) or not p:Alive() then return end
	local o = p.organism
	if not o or not o.otrub then return end
	return o
end

local function w(t, m)
	local q = m.qrs
	local tw = m.tw
	local pw = m.pw

	if t < 0.04 * pw then
		return math.sin(t / (0.04 * pw) * math.pi) * 0.12 * m.a
	elseif t < 0.08 * pw then
		return -math.sin((t - 0.04 * pw) / (0.04 * pw) * math.pi) * 0.2 * q
	elseif t < 0.12 * pw then
		return math.sin((t - 0.08 * pw) / (0.04 * pw) * math.pi) * 1.25 * q
	elseif t < 0.17 * pw then
		return -math.sin((t - 0.12 * pw) / (0.05 * pw) * math.pi) * 0.4 * q
	elseif t < 0.34 * tw then
		return math.sin((t - 0.17 * pw) / (0.17 * tw) * math.pi) * 0.3 * m.a
	end

	return 0
end

hook.Add("Think", "pulseotrub.update", function()
	local o = g()
	if not o then return end

	local bpm = math.Clamp(o.heartbeat or o.pulse or 70, 0, 260)
	local t = CurTime()
	local s = o.heartstop or bpm <= 0
	local o2 = math.Clamp(o.o2 and o.o2[1] or 30, 0, 30)
	local blood = math.Clamp((o.blood or 5000) / 5000, 0, 1)
	local heart = math.Clamp(o.heart or 1, 0, 1)
	local pain = math.Clamp((o.pain or 0) / 120, 0, 1)
	local lungs = o.lungsfunction and 1 or 0
	local crit = o.critical and 1 or 0
	local hold = o.holdingbreath and 1 or 0

	local sev = math.Clamp((1 - heart) * 0.45 + (1 - blood) * 0.25 + (1 - o2 / 30) * 0.2 + crit * 0.1, 0, 1)
	local arr = math.Clamp((1 - heart) * 0.75 + (1 - o2 / 30) * 0.25 + pain * 0.2, 0, 1)
	if hold > 0 then arr = math.min(arr + 0.2, 1) end

	e.hm = Lerp(FrameTime() * 4, e.hm, sev)
	e.rr = Lerp(FrameTime() * 4, e.rr, arr)

	if s then
		e.p[e.i] = math.Rand(-0.006, 0.006)
	else
		local jitter = (math.Rand(-0.12, 0.12) * e.rr) + (math.sin(t * 2.7) * 0.05 * e.rr)
		local d = (60 / math.max(bpm, 1)) * (1 + jitter)
		if e.n <= t then
			e.b = t
			e.n = t + d
		end

		local bt = t - e.b
		local m = {
			a = math.Clamp(1 - e.hm * 0.55, 0.35, 1),
			qrs = math.Clamp(1 - e.hm * 0.45, 0.4, 1) * math.Clamp(lungs * 0.4 + 0.6, 0.55, 1),
			tw = 1 + e.hm * 0.2,
			pw = 1 + e.rr * 0.35,
		}
		local v = w(bt, m)
		local n = 0.01 + e.rr * 0.05 + e.hm * 0.03
		v = v + math.sin(t * (7 + e.rr * 9)) * (0.01 + e.rr * 0.02) + math.Rand(-n, n)
		if e.rr > 0.65 and math.random() < 0.035 then v = v + math.Rand(-0.35, 0.35) * e.rr end
		e.p[e.i] = v
	end

	e.i = e.i + 1
	if e.i > e.max then e.i = 1 end
end)

hook.Add("HUDPaint", "pulseotrub.draw", function()
	local o = g()
	if not o then return end

	local sw, sh = ScrW(), ScrH()
	local scale = 1.5
	local ww, hh = sw, e.h * scale
	local x = 0
	local y = sh - hh - ScreenScaleH(50 * scale)

	local c = Color(255, 255, 255)

	surface.SetDrawColor(c.r, c.g, c.b, 220)
	local x1, y1
	for i = 1, e.max do
		local k = (e.i + i - 1) % e.max + 1
		local x2 = x + (i - 1) / (e.max - 1) * (ww - 2) + 1
		local y2 = y + hh * 0.5 - e.p[k] * (hh * 0.35)
		if x1 then surface.DrawLine(x1, y1, x2, y2) end
		x1, y1 = x2, y2
	end

	--draw.SimpleText(s and "ASYSTOLE" or ("BPM: " .. bpm), "Default", x + 6, y - 2, c, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)

hook.Add("Player Spawn", "pulseotrub.reset", function(ply)
	if ply ~= LocalPlayer() then return end
	e.n = 0
	e.b = 0
	for i = 1, e.max do
		e.p[i] = 0
	end
end)
