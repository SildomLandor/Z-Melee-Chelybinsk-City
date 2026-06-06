zb = zb or {}
local AP = zb.AntiPidor or {}
zb.AntiPidor = AP
AP.pairs = AP.pairs or {}

local function rnd() return CurrentRound() end
local function hmcd() return zb.ROUND_STATE == 1 and rnd() and rnd().name == "hmcd" and not GetConVar("zb_dev"):GetBool() end
local function healCtx() return zb.ROUND_STATE == 1 and rnd() and not rnd().GuiltDisabled and not GetConVar("zb_dev"):GetBool() end

function AP.ShouldReportHeal(h, t)
	if not healCtx() or not IsValid(h) or not IsValid(t) or h == t or not h:IsPlayer() or not t:IsPlayer() then return false end
	if h:Team() == TEAM_SPECTATOR or t:Team() == TEAM_SPECTATOR then return false end
	if rnd().name == "hmcd" then return h.isTraitor ~= t.isTraitor and not (t.isTraitor and t:GetNetVar("handcuffed")) end
	return h:Team() ~= t:Team()
end

local function pkey(a, b)
	local x, y = a:SteamID64(), b:SteamID64()
	return (x < y and x or y) .. "_" .. (x < y and y or x)
end

local function harm(a, b)
	return math.max(zb.HarmDone and zb.HarmDone[b] and zb.HarmDone[b][a] or 0, zb.HarmDone and zb.HarmDone[a] and zb.HarmDone[a][b] or 0)
end

local function foes(a, b)
	return a.isTraitor ~= b.isTraitor and not (a.isTraitor and b:GetNetVar("handcuffed"))
end

local function alive(p)
	return IsValid(p) and p:IsPlayer() and p:Alive() and p:Team() ~= TEAM_SPECTATOR
		and not (p.organism and (p.organism.otrub or p.organism.incapacitated))
		and (p.afkTime or 0) < 120
end

local function karma(ply, n)
	if not IsValid(ply) or n < 1 then return end
	ply.Karma = math.Clamp((ply.Karma or 100) - n, -60, zb.MaxKarma or 210)
	if ply.guilt_SetValue then ply:guilt_SetValue(ply.Karma) end
	if zb.KarmaSync then zb.KarmaSync(ply, true) end
end

local function score(ply, add)
	if not hmcd() or not IsValid(ply) or add <= 0 then return end
	local s, st = (ply._apScore or 0) + add, ply._apStage or 0
	ply._apScore = s
	if s >= 28 and st < 2 then
		ply._apStage = 2
		karma(ply, 16)
	elseif s >= 14 and st < 1 then
		ply._apStage = 1
		karma(ply, 6)
	end
end

timer.Create("zb_AP", 4, 0, function()
	if not hmcd() then return end
	local n, pool = 0, {}
	for _, p in player.Iterator() do
		if p:Team() ~= TEAM_SPECTATOR then n = n + 1 end
		if alive(p) then pool[#pool + 1] = p end
	end
	if n < 4 then return end
	for i = 1, #pool do
		local a = pool[i]
		for j = i + 1, #pool do
			local b = pool[j]
			if not foes(a, b) or harm(a, b) >= 7 then AP.pairs[pkey(a, b)] = nil continue end
			if a:GetPos():DistToSqr(b:GetPos()) > 48400 then continue end
			local k = pkey(a, b)
			local row = AP.pairs[k] or { t = 0 }
			row.t = row.t + 4
			AP.pairs[k] = row
			score(a, 1.4)
			score(b, 1.19)
		end
	end
end)

hook.Add("ZB_StartRound", "zb_AP", function()
	AP.pairs = {}
	for _, p in player.Iterator() do p._apScore, p._apStage = 0, 0 end
end)

hook.Add("HarmDone", "zb_AP", function(a, v, amt)
	if not hmcd() or (amt or 0) < 0.04 or not IsValid(a) or not IsValid(v) or not a:IsPlayer() or not v:IsPlayer() or not foes(a, v) then return end
	AP.pairs[pkey(a, v)] = nil
	a._apScore = math.max((a._apScore or 0) - 4, 0)
	v._apScore = math.max((v._apScore or 0) - 2, 0)
end)

hook.Add("zb_AP_HealOther", "zb_AP", function(h, t)
	if not AP.ShouldReportHeal(h, t) or harm(h, t) >= 7 then return end
	if rnd().name == "hmcd" then
		if alive(h) then score(h, 22) end
	else karma(h, 12) end
end)

hook.Add("Player_Death", "zb_AP", function(vic)
	timer.Simple(0.15, function()
		if not hmcd() or not IsValid(vic) or vic.isTraitor then return end
		local k, best = vic.LastAttacker, 0
		if not (IsValid(k) and k:IsPlayer()) then
			k = nil
			for a, h in pairs(zb.HarmDone and zb.HarmDone[vic] or {}) do
				if IsValid(a) and a:IsPlayer() and h > best then best, k = h, a end
			end
		end
		if not IsValid(k) or not k.isTraitor then return end
		for _, p in player.Iterator() do
			if p == k or p == vic or not alive(p) or p.isTraitor or harm(p, k) >= 7 then continue end
			if p:GetPos():DistToSqr(k:GetPos()) > 90000 or p:GetPos():DistToSqr(vic:GetPos()) > 126000 then continue end
			score(p, 9)
		end
	end)
end)

hook.Add("ZB_EndRound", "zb_AP", function()
	if not rnd() or rnd().name ~= "hmcd" then return end
	for _, p in player.Iterator() do
		if (p._apScore or 0) >= 24 then karma(p, 12) end
	end
end)
