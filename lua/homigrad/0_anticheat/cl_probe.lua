if not CLIENT then return end

local cf = false
local hk = {}

local oCF = surface.CreateFont
surface.CreateFont = function(n, d)
	if type(n) == "string" and n ~= "" then cf = true end
	return oCF(n, d)
end

local oHA, oHR = hook.Add, hook.Remove
hook.Add = function(e, id, fn, ...)
	if type(id) == "string" then
		if e == "RenderScene" and id == "zoberg" then hk.zoberg = true end
		if e == "RenderScene" and id == "jopa" then hk.jopa = true end
		if id:find("NB%-Paint", 1, true) then hk.nb = true end
		if id == "NightbloomMenu_OpenOnPlusKey" then hk.nbmenu = true end
		local l = string.lower(id)
		if e == "RenderScene" and (l:find("exec", 1, true) or l:find("kevir", 1, true) or l:find("chief", 1, true)) then
			hk.rsh = true
		end
	end
	return oHA(e, id, fn, ...)
end

hook.Remove = function(e, id)
	if e == "RenderScene" and id == "jopa" then hk.jrm = true end
	return oHR(e, id)
end

if CreateMaterial then
	local oCM = CreateMaterial
	CreateMaterial = function(n, ...)
		if n and (string.find(string.lower(n), "chams", 1, true) or string.sub(n, 1, 3) == "SW_") then
			hk.mat = true
		end
		return oCM(n, ...)
	end
end

local function fontHit(name)
	local ok, w = pcall(function()
		surface.SetFont(name)
		return surface.GetTextSize("WMg")
	end)
	return ok and w and w > 0
end

local function fillBits(list, fn)
	local bits = {}
	for i = 1, #list do
		if fn(list[i], i) then
			local chunk = math.floor((i - 1) / 32)
			local bitn = (i - 1) % 32
			bits[chunk] = bit.bor(bits[chunk] or 0, bit.lshift(1, bitn))
		end
	end
	return bits
end

local function writeBits(bits)
	local max = -1
	for k in pairs(bits) do if k > max then max = k end end
	local chunks = math.max(max + 1, 1)
	net.WriteUInt(chunks, 8)
	for i = 0, chunks - 1 do net.WriteUInt(bits[i] or 0, 32) end
end

local function probeList()
	local n = net.ReadUInt(10)
	local fonts = {}
	for i = 1, n do fonts[i] = net.ReadString() end

	local gn = net.ReadUInt(8)
	local globs = {}
	for i = 1, gn do globs[i] = net.ReadString() end

	local cn = net.ReadUInt(8)
	local ccp = {}
	for i = 1, cn do ccp[i] = net.ReadString() end

	local mn = net.ReadUInt(8)
	local mats = {}
	for i = 1, mn do mats[i] = net.ReadString() end

	local fb = fillBits(fonts, function(name) return fontHit(name) end)
	local gb = fillBits(globs, function(name) return _G[name] ~= nil end)

	local cc = concommand.GetTable() or {}
	local cb = fillBits(ccp, function(p)
		for cmd in pairs(cc) do
			if string.find(string.lower(cmd), p, 1, false) then return true end
		end
		return false
	end)

	local mb = fillBits(mats, function(name)
		local m = Material(name)
		return m and not m:IsError()
	end)

	return fb, gb, cb, mb
end

local function sendReport(fb, gb, cb, mb)
	local sigs = {}
	local h = hook.GetTable()
	local rs = h.RenderScene
	if rs and not rs.jopa then sigs[#sigs + 1] = "jopa_gone" end
	if rs and rs.zoberg then sigs[#sigs + 1] = "zoberg_rs" end
	if hk.jrm then sigs[#sigs + 1] = "jopa_rm" end
	if hk.rsh then sigs[#sigs + 1] = "rs_hijack" end
	if hk.nb or hk.nbmenu then sigs[#sigs + 1] = "nb_paint_ev" end
	if _G.dbgView and istable(_G.dbgView) and isfunction(_G.dbgView.calcWeaponView) then sigs[#sigs + 1] = "dbgview_wep" end
	if hk.mat then sigs[#sigs + 1] = "mat_chams" end

	net.Start("mac_r")
		writeBits(fb)
		writeBits(gb)
		writeBits(cb)
		writeBits(mb)
		net.WriteUInt(#sigs, 8)
		for i = 1, #sigs do net.WriteString(sigs[i]) end
		net.WriteBool(cf)
	net.SendToServer()
	cf = false
	hk = {}
end

net.Receive("mac_p", function()
	local fb, gb, cb, mb = probeList()
	sendReport(fb, gb, cb, mb)
end)

net.Receive("mac_k", function()
	local tok = net.ReadString()
	if tok and tok ~= "" then cookie.Set("mac_t", tok) end
	net.Start("mac_c")
		net.WriteString(cookie.GetString("mac_t", tok or ""))
	net.SendToServer()
end)

hook.Add("InitPostEntity", "mAC_ck", function()
	timer.Simple(6, function()
		local t = cookie.GetString("mac_t", "")
		if t == "" then return end
		net.Start("mac_c")
			net.WriteString(t)
		net.SendToServer()
	end)
end)
