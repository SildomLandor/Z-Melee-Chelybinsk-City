local e = {
	h = ScreenScaleH(30),
	p = {},
	max = 320,
	i = 1,
	step = 1 / 60,
	sample = 0,
	beat = 0,
	next = 0,
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

local function sq(t, c, w, a)
	t = (t - c) / w
	if t < -1 or t > 1 then return 0 end
	return a * (1 - t * t)
end

local function wave(t, m)
	local q, a, sc = m.qrs, m.amp, m.sc
	t = t / sc
	local v = sq(t, 0.07, 0.045, 0.1 * a)
	v = v + sq(t, 0.155, 0.016, -0.2 * q)
	v = v + sq(t, 0.168, 0.012, 1.1 * q)
	v = v + sq(t, 0.182, 0.02, -0.35 * q)
	return v + sq(t, 0.36, 0.095, 0.26 * a)
end

local function push(v)
	e.p[e.i] = v
	e.i = e.i + 1
	if e.i > e.max then e.i = 1 end
end

local function skipGap(gap)
	e.sample = e.sample + gap
	e.beat = e.beat + gap
	e.next = e.next + gap
end

local function sampleAt(t, stop, bpm, m)
	if stop then
		push(math.sin(t * 0.7) * 0.004)
		return
	end

	while t >= e.next do
		local d = (60 / math.max(bpm, 1)) * (1 + math.sin(t * 2.1) * 0.04 * e.rr)
		if e.rr > 0.55 and math.random() < 0.06 * e.rr then
			d = d * math.Rand(0.78, 1.28)
		end
		e.beat = e.next
		e.next = e.next + d
	end

	local bt = t - e.beat
	local base = math.sin(t * 0.55) * 0.011 + math.sin(t * 1.25 + e.beat) * 0.006
	base = base + math.sin(t * 76) * 0.003 * e.rr
	push(wave(bt, m) + base * (1 + e.hm * 0.4))
end

hook.Add("Think", "pulseotrub.update", function()
	local o = g()
	if not o then return end

	local bpm = math.Clamp(o.heartbeat or 70, 0, 260)
	local stop = o.heartstop or bpm <= 0
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

	local rt = RealTime()
	if e.sample <= 0 then
		e.sample = rt
		e.beat = rt
		e.next = rt
	end

	if system.HasFocus and not system.HasFocus() then
		e.hold = e.hold or rt
		return
	end

	if e.hold then
		skipGap(rt - e.hold)
		e.hold = nil
	end

	local m = {
		amp = math.Clamp(1 - e.hm * 0.55, 0.35, 1),
		qrs = math.Clamp(1 - e.hm * 0.45, 0.4, 1) * math.Clamp(lungs * 0.4 + 0.6, 0.55, 1),
		sc = 1 + e.hm * 0.12 + e.rr * 0.08,
	}

	local n = 0
	while rt >= e.sample + e.step and n < 4 do
		e.sample = e.sample + e.step
		sampleAt(e.sample, stop, bpm, m)
		n = n + 1
	end
end)

hook.Add("HUDPaint", "pulseotrub.draw", function()
	if not g() then return end

	local sw, sh = ScrW(), ScrH()
	local scale = 1.5
	local ww, hh = sw, e.h * scale
	local x, y = 0, sh - hh - ScreenScaleH(50 * scale)
	local mid, gain = y + hh * 0.5, hh * 0.35
	local p, idx, max = e.p, e.i, e.max

	surface.SetDrawColor(255, 255, 255, 220)
	local x1, y1
	for i = 1, max do
		local k = (idx + i - 1) % max + 1
		local x2 = x + (i - 1) / (max - 1) * (ww - 2) + 1
		local y2 = mid - p[k] * gain
		if x1 then surface.DrawLine(x1, y1, x2, y2) end
		x1, y1 = x2, y2
	end
end)

hook.Add("Player Spawn", "pulseotrub.reset", function(ply)
	if ply ~= LocalPlayer() then return end
	e.sample = 0
	e.beat = 0
	e.next = 0
	e.hold = nil
	for i = 1, e.max do
		e.p[i] = 0
	end
end)
