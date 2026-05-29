local e = {
	n = 256,
	buf = {},
	idx = 0,
	h = ScreenScaleH(44),
	step = 1 / 60,
	tSample = 0,
	tBeat = 0,
	tNext = 0,
	hold = nil,
	on = false,
	show = 0,
	sweep = 0,
	flat = false,
	dispBpm = 70,
	hm = 0,
	rr = 0,
	flash = 0,
}

for i = 1, e.n do e.buf[i] = 0 end

local function reset(rt)
	rt = rt or RealTime()
	e.tSample = rt
	e.tBeat = rt
	e.tNext = rt
	e.hold = nil
	e.flat = false
	e.flash = 0
	e.sweep = 0
	e.dispBpm = 70
	e.idx = 0
	for i = 1, e.n do e.buf[i] = 0 end
end

local function org()
	local p = LocalPlayer()
	if not IsValid(p) or not p:Alive() then return end
	local o = p.organism
	if not o or not o.otrub then return end
	return o
end

local function bpm(o)
	if o.heartstop then return 0 end
	local hb = tonumber(o.heartbeat)
	if not hb or hb <= 0 then return 0 end
	return math.Clamp(hb, 8, 220)
end

local function sq(t, c, w, a)
	t = (t - c) / w
	if t < -1 or t > 1 then return 0 end
	return a * (1 - t * t)
end

local function qrs(t, m)
	t = t / m.sc
	local v = sq(t, 0.07, 0.045, 0.1 * m.amp)
	v = v + sq(t, 0.155, 0.016, -0.2 * m.qrs)
	v = v + sq(t, 0.168, 0.012, 1.1 * m.qrs)
	v = v + sq(t, 0.182, 0.02, -0.35 * m.qrs)
	return v + sq(t, 0.36, 0.095, 0.26 * m.amp)
end

local function push(v)
	if e.idx < e.n then
		e.idx = e.idx + 1
	else
		for i = 1, e.n - 1 do
			e.buf[i] = e.buf[i + 1]
		end
	end
	e.buf[e.idx] = math.Clamp(v, -1.4, 1.4)
end

local function sample(t, hb, m)
	local n = 0
	while t >= e.tNext and n < 2 do
		local gap = 60 / hb
		gap = gap * (1 + (math.random() - 0.5) * 0.22 * e.rr)
		gap = math.max(gap, 60 / 220)
		e.tBeat = e.tNext
		e.tNext = e.tNext + gap
		e.flash = t
		n = n + 1
	end

	local bt = t - e.tBeat
	local base = math.sin(t * 0.6) * 0.009 + math.sin(t * 1.3 + e.tBeat) * 0.005
	base = base + math.sin(t * 4.1) * 0.007 * e.hm
	push(qrs(bt, m) + base * (1 + e.hm * 0.35))
end

local function skipGap(dt)
	e.tSample = e.tSample + dt
	e.tBeat = e.tBeat + dt
	e.tNext = e.tNext + dt
end

local function metrics(o)
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

	return {
		amp = math.Clamp(1 - e.hm * 0.55, 0.25, 1),
		qrs = math.Clamp(1 - e.hm * 0.45, 0.35, 1) * math.Clamp(lungs * 0.4 + 0.6, 0.5, 1),
		sc = 1 + e.hm * 0.12 + e.rr * 0.06,
	}
end

hook.Add("Think", "pulseotrub.update", function()
	local o = org()
	e.show = Lerp(FrameTime() * 4, e.show, o and 1 or 0)

	if not o then
		e.on = false
		return
	end

	if not e.on then
		reset()
		e.dispBpm = bpm(o)
		e.on = true
	end

	local hb = bpm(o)
	e.dispBpm = Lerp(FrameTime() * 6, e.dispBpm, hb)
	local stop = hb <= 0

	if stop then
		if not e.flat then
			e.flat = true
			e.idx = 0
			for i = 1, e.n do e.buf[i] = 0 end
		end
	else
		e.flat = false
	end

	local rt = RealTime()
	if system.HasFocus and not system.HasFocus() then
		e.hold = e.hold or rt
		return
	end
	if e.hold then
		skipGap(rt - e.hold)
		e.hold = nil
	end

	if stop then
		push(0)
		return
	end

	local m = metrics(o)
	local n = 0
	while rt >= e.tSample + e.step and n < 4 do
		e.tSample = e.tSample + e.step
		sample(e.tSample, hb, m)
		n = n + 1
	end
end)

hook.Add("HUDPaint", "pulseotrub.draw", function()
	if e.show < 0.02 or e.idx < 2 then return end
	local o = org()
	if not o then return end

	local sh = ScrH()
	local scale = 2.1
	local pad = ScreenScaleH(6 * scale)
	local hh = e.h * scale
	local x, y = 0, sh - hh - ScreenScaleH(36 * scale)
	local mid = y + hh * 0.5
	local gain = hh * 0.46
	local hb = bpm(o)
	local stop = hb <= 0
	local a = math.floor(255 * e.show)

	local x0 = x + pad
	local w0 = ScrW() - pad * 2
	local visW = w0
	local xStart = x0
	local cnt = e.idx
	local x1, y1

	render.SetScissorRect(x0, y, x0 + w0, y + hh, true)

	for pass = 1, 2 do
		x1, y1 = nil, nil
		local thick = pass == 1 and 1 or 0
		local la = pass == 1 and math.floor(a * 0.35) or a
		surface.SetDrawColor(255, 255, 255, la)
		for i = 1, cnt do
			local x2 = xStart + (e.n - cnt + i - 1) / math.max(e.n - 1, 1) * visW
			local y2 = mid - e.buf[i] * gain
			if thick == 1 then y2 = y2 + 1 end
			if x1 then surface.DrawLine(x1, y1, x2, y2) end
			x1, y1 = x2, y2
		end
	end

	render.SetScissorRect(0, 0, 0, 0, false)

	local lblA = a
	if lblA < 4 then return end

	local font = "ZCity_Veteran"
	surface.SetFont(font)
	local lblX = xStart + ScreenScaleH(4)
	local lblY = y + pad
	local beatA = math.Clamp(1 - (RealTime() - e.flash) * 9, 0, 1) * e.show
	if beatA > 0 and not stop then
		local bs = ScreenScaleH(5)
		surface.SetDrawColor(255, 255, 255, math.floor(255 * beatA))
		surface.DrawRect(lblX, lblY + ScreenScaleH(2), bs, bs)
	end
end)

hook.Add("Player Spawn", "pulseotrub.reset", function(ply)
	if ply ~= LocalPlayer() then return end
	e.on = false
	e.show = 0
	reset(0)
end)

hook.Add("HG_OnOtrub", "pulseotrub.reset", function(ply)
	if ply ~= LocalPlayer() then return end
	reset()
	e.on = true
end)

hook.Add("zbClientModeCleanup", "pulseotrub.off", function()
	e.on = false
	e.show = 0
	reset(0)
end)
