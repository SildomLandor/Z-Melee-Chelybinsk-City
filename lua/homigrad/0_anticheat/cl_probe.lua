if not CLIENT then return end

local decoys = 0
local fontSet = {}

local function refreshFonts()
	fontSet = {}
	if type(surface.GetLuaFonts) == "function" then
		for _, name in ipairs(surface.GetLuaFonts() or {}) do
			fontSet[name] = true
		end
	end
end

hook.Add("InitPostEntity", "mAC_fonts", refreshFonts)

local function fontHit(name, idx)
	if idx <= decoys then return false end
	if not next(fontSet) then refreshFonts() end
	return fontSet[name] or false
end

local function globHit(name)
	local v = _G[name]
	if v == nil then return false end

	local l = string.lower(name)
	if l == "nb" then return istable(v) and (v.module or v.modules) end
	if l == "sw" or l == "silkware" then return istable(v) end
	if l == "exec" or l == "kefir" or l == "kevir" then return istable(v) or isfunction(v) end
	if l:find("chief", 1, true) or l == "lynx" or l == "snixzz" or l == "baim" then
		return istable(v) or isfunction(v)
	end

	return false
end

local function hookSigs()
	local sigs = {}
	local h = hook.GetTable()
	local rs = h.RenderScene

	if rs and rs.zoberg then sigs[#sigs + 1] = "zoberg_rs" end

	if rs then
		for id in pairs(rs) do
			local l = string.lower(id)
			if l:find("exec", 1, true) or l:find("kevir", 1, true) or l:find("kefir", 1, true) then
				sigs[#sigs + 1] = "rs_hijack"
				break
			end
		end
	end

	if h["NB-PaintModule"] then sigs[#sigs + 1] = "nb_paint_ev" end
	if h.PlayerButtonDown and h.PlayerButtonDown.NightbloomMenu_OpenOnPlusKey then
		sigs[#sigs + 1] = "nb_plus_menu"
	end
	if h.ShutDown and h.ShutDown.RemoveAntiScreenGrab then sigs[#sigs + 1] = "nb_shutdown_sg" end

	if _G.dbgView and istable(_G.dbgView) and isfunction(_G.dbgView.calcWeaponView) then
		sigs[#sigs + 1] = "dbgview_wep"
	end

	return sigs
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
	decoys = net.ReadUInt(8)

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

	local fb = fillBits(fonts, fontHit)
	local gb = fillBits(globs, globHit)

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
	local sigs = hookSigs()

	net.Start("mac_r")
		writeBits(fb)
		writeBits(gb)
		writeBits(cb)
		writeBits(mb)
		net.WriteUInt(#sigs, 8)
		for i = 1, #sigs do net.WriteString(sigs[i]) end
		net.WriteBool(false)
	net.SendToServer()
end

net.Receive("mac_p", function()
	refreshFonts()
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
