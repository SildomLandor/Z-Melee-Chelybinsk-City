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
	stopAt = 0,
	wander = 0,
	beatJ = { amp = 1, qrs = 1, morph = 0 },
	adrenTox = 0,
	pvcAt = 0,
}
-- ради реализма на такое идти... Я думаю это круто
for i = 1, e.n do e.buf[i] = 0 end

local function smooth01(t)
	t = math.Clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function pulseEdgeFade(x, xL, xR, fw)
	return smooth01((x - xL) / fw) * smooth01((xR - x) / fw)
end

local function rollBeatJ(rr)
	e.beatJ.amp = 1 + (math.random() - 0.5) * 0.16
	e.beatJ.qrs = 1 + (math.random() - 0.5) * 0.14
	e.beatJ.morph = (math.random() - 0.5) * 0.05 * rr
end

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
	e.stopAt = 0
	e.wander = 0
	e.beatJ.amp = 1
	e.beatJ.qrs = 1
	e.beatJ.morph = 0
	e.adrenTox = 0
	e.pvcAt = 0
	rollBeatJ(60 / 70)
	for i = 1, e.n do e.buf[i] = 0 end
end

local function adrenLoad(o)
	local a = tonumber(o.adrenaline) or 0
	local add = tonumber(o.adrenalineAdd) or 0
	return math.Clamp((a - 2) / 2.5, 0, 1) + math.Clamp(add / 4, 0, 1) * 0.32
end

local function crY(y0, y1, y2, y3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * y1) + (-y0 + y2) * t + (2 * y0 - 5 * y1 + 4 * y2 - y3) * t2 + (-y0 + 3 * y1 - 3 * y2 + y3) * t3)
end

local function otrubActive()
	local p = LocalPlayer()
	if not IsValid(p) or not p:Alive() then return false end
	local o = p.organism
	return o and o.otrub or false
end

local function org()
	local p = LocalPlayer()
	if not IsValid(p) or not p:Alive() then return end
	local o = p.organism
	if not o or not o.otrub then return end
	return o
end

local function vfib(o)
	return o.vfib == true and not o.heartstop
end

local function bpm(o)
	if o.heartstop then return 0 end
	if vfib(o) then
		return math.Clamp(tonumber(o.heartbeat) or 240, 160, 260)
	end
	local pulse = tonumber(o.pulse) or 0
	if pulse <= 0.5 then return 0 end
	local hb = tonumber(o.heartbeat)
	if not hb or hb <= 0.5 then return 0 end
	return math.Clamp(hb, 8, 220)
end

local function bell(dt, hw)
	if hw < 1e-5 then return 0 end
	local t = dt / hw
	if t < -1 or t > 1 then return 0 end
	return 1 - t * t
end

local function ecgWave(phase, rr, m)
	rr = math.max(rr, 60 / 220)
	local tox = m.adrenTox or 0
	local sc = m.sc * (1 + tox * 0.22 + (m.adrenNow or 0) * 0.08)
	local amp = m.amp * e.beatJ.amp * (1 - tox * 0.35)
	local q = m.qrs * e.beatJ.qrs * (1 + (m.adrenNow or 0) * 0.12)
	local sh = e.beatJ.morph
	local v = 0

	if phase < rr * 0.12 then
		local p = (phase + sh) / sc
		v = v - 0.22 * q * bell(p - rr * 0.024, rr * 0.016)
		v = v + 1.08 * q * bell(p - rr * 0.008, rr * 0.011)
		v = v - 0.36 * q * bell(p - rr * 0.036, rr * 0.017)
		return v
	end

	if phase < rr * 0.50 then
		local tAmp = 0.32 * amp * (1 - tox * 0.25)
		return tAmp * bell((phase + sh) / sc - rr * 0.31, rr * 0.095)
	end

	if phase > rr * 0.68 then
		local pAmp = 0.13 * amp * (1 - tox * 0.65)
		return pAmp * bell((phase + sh) / sc - rr * 0.79, rr * 0.055)
	end

	return 0
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

local function sample(t, hb, m, isVfib)
	if isVfib then
		local sev = math.Clamp(tonumber(m.vfib) or 0.5, 0.2, 1)
		local chaos = math.sin(t * 22) * 0.12 + math.sin(t * 37 + 1.5) * 0.1 + math.sin(t * 56 + 0.7) * 0.06
		local noise = (math.random() - 0.5) * 0.12
		push((chaos + noise) * (0.8 + sev * 0.45))
		return
	end

	if hb <= 0 then
		push(0)
		return
	end

	local n = 0
	while t >= e.tNext and n < 2 do
		local gap = 60 / hb
		local jit = 0.22 + e.rr * 0.38 + e.hm * 0.25 + (m.adrenTox or 0) * 0.35
		gap = gap * (1 + (math.random() - 0.5) * jit)
		gap = math.max(gap, 60 / 220)
		e.tBeat = e.tNext
		e.tNext = e.tNext + gap
		e.flash = e.tBeat
		rollBeatJ(gap)
		local tox = m.adrenTox or 0
		if tox > 0.3 and math.random() < 0.1 + tox * 0.28 then
			e.pvcAt = e.tBeat + gap * (0.32 + math.random() * 0.28)
		end
		n = n + 1
	end

	local phase = t - e.tBeat
	local rr = math.max(e.tNext - e.tBeat, 60 / 220)
	local tox = m.adrenTox or 0

	if e.pvcAt > 0 and t >= e.pvcAt and t < e.pvcAt + 0.07 then
		local p = (t - e.pvcAt) / 0.07
		local v = 0.78 * bell(p - 0.04, 0.034) - 0.22 * bell(p - 0.058, 0.018)
		push(v * (0.55 + tox * 0.5) + (math.random() - 0.5) * 0.02)
		return
	end
	if e.pvcAt > 0 and t >= e.pvcAt + 0.07 then e.pvcAt = 0 end

	e.wander = e.wander * 0.94 + (math.random() - 0.5) * 0.004
	local drift = math.sin(t * 0.9 + e.tBeat) * 0.007 + math.sin(t * 2.1) * 0.005 + e.wander
	drift = drift + math.sin(t * 5.3) * 0.006 * tox
	local grain = (math.random() - 0.5) * 0.011 * (1 + e.hm * 1.5 + e.rr * 0.8 + tox * 1.2)
	push(ecgWave(phase, rr, m) + drift + grain)
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

	local srvTox = tonumber(o.adren_tox)
	if srvTox then
		e.adrenTox = Lerp(FrameTime() * 4, e.adrenTox, srvTox)
	else
		local load = adrenLoad(o)
		if load > 0.05 then
			e.adrenTox = math.min(e.adrenTox + FrameTime() * load * 0.1, 0.25)
		else
			e.adrenTox = math.max(e.adrenTox - FrameTime() * 0.045, 0)
		end
	end

	local adrenNow = math.Clamp(((tonumber(o.adrenaline) or 0) - 1.6) / 2.8, 0, 1)
	arr = math.min(arr + e.adrenTox * 0.55 + adrenNow * 0.25, 1)

	e.hm = Lerp(FrameTime() * 4, e.hm, sev)
	e.rr = Lerp(FrameTime() * 4, e.rr, arr)

	return {
		amp = math.Clamp(1 - e.hm * 0.55 - e.adrenTox * 0.2, 0.2, 1),
		qrs = math.Clamp(1 - e.hm * 0.45, 0.35, 1) * math.Clamp(lungs * 0.4 + 0.6, 0.5, 1),
		sc = 1 + e.hm * 0.12 + e.rr * 0.06 + e.adrenTox * 0.1,
		vfib = o.vfib_severity or 0,
		adrenTox = e.adrenTox,
		adrenNow = adrenNow,
	}
end

hook.Add("Think", "pulseotrub.update", function()
	local active = otrubActive()
	local ft = FrameTime()
	e.show = Lerp(ft * (active and 4 or 2.2), e.show, active and 1 or 0)

	local o = org()
	if not o then
		if e.show < 0.02 then e.on = false end
		return
	end

	if not e.on then
		reset()
		e.dispBpm = bpm(o)
		e.on = true
	end

	local isVfib = vfib(o)
	local hb = bpm(o)
	e.dispBpm = Lerp(FrameTime() * 6, e.dispBpm, hb)
	local rt = RealTime()
	if hb <= 0 and not isVfib then
		if e.stopAt == 0 then e.stopAt = rt end
	else
		e.stopAt = 0
	end
	local stop = e.stopAt ~= 0 and (rt - e.stopAt) >= 0.55

	e.flat = stop

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
		sample(e.tSample, hb, m, isVfib)
		n = n + 1
	end
end)

hook.Add("HUDPaint", "pulseotrub.draw", function()
	if e.show < 0.02 or e.idx < 2 then return end

	local o = org()
	local sh = ScrH()
	local scale = 2.1
	local pad = ScreenScaleH(6 * scale)
	local hh = e.h * scale
	local x, y = 0, sh - hh - ScreenScaleH(36 * scale)
	local mid = y + hh * 0.5
	local gain = hh * 0.46
	local isVfib = o and vfib(o)
	local stop = e.stopAt ~= 0 and (RealTime() - e.stopAt) >= 0.55
	local a = math.floor(255 * e.show)

	local x0 = x + pad
	local w0 = ScrW() - pad * 2
	local xEnd = x0 + w0
	local fadeW = math.min(w0 * 0.16, ScreenScaleH(62 * scale))
	local visW = w0
	local xStart = x0
	local cnt = e.idx
	local x1, y1
	local sub = 3

	local function bufI(vi)
		return math.Clamp(e.n - cnt + vi, 1, e.idx)
	end

	local function ptX(vi)
		return xStart + (bufI(vi) - 1) / math.max(e.n - 1, 1) * visW
	end

	local function ptY(vi, thick)
		local yv = mid - e.buf[bufI(vi)] * gain
		if thick == 1 then yv = yv + 1 end
		return yv
	end

	local function stroke(xa, ya, xb, yb, la)
		local fa = math.floor(la * pulseEdgeFade((xa + xb) * 0.5, x0, xEnd, fadeW))
		if fa > 0 then
			surface.SetDrawColor(255, 255, 255, fa)
			surface.DrawLine(xa, ya, xb, yb)
		end
	end

	render.SetScissorRect(x0, y, xEnd, y + hh, true)

	for pass = 1, 2 do
		local thick = pass == 1 and 1 or 0
		local la = pass == 1 and math.floor(a * 0.35) or a
		x1, y1 = ptX(1), ptY(1, thick)
		for i = 2, cnt do
			local y0 = ptY(math.max(i - 2, 1), thick)
			local yA = ptY(i - 1, thick)
			local yB = ptY(i, thick)
			local yC = ptY(math.min(i + 1, cnt), thick)
			local xA, xB = ptX(i - 1), ptX(i)
			for s = 1, sub do
				local t = s / sub
				local x2 = xA + (xB - xA) * t
				local y2 = crY(y0, yA, yB, yC, t)
				stroke(x1, y1, x2, y2, la)
				x1, y1 = x2, y2
			end
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
	local tox = e.adrenTox or 0
	if beatA > 0 and o and not stop and not isVfib and tox < 0.75 then
		local bs = ScreenScaleH(5)
		local bfa = pulseEdgeFade(lblX + bs * 0.5, x0, xEnd, fadeW)
		local blink = 1 - tox * 0.45
		surface.SetDrawColor(255, 255, 255, math.floor(255 * beatA * bfa * blink))
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
	if not e.on then
		reset()
		e.on = true
	end
end)

hook.Add("zbClientModeCleanup", "pulseotrub.off", function()
	e.on = false
	e.show = 0
	reset(0)
end)
