mAC = mAC or {}

function mAC.SteamID64(ply)
	if not IsValid(ply) then return end
	return ply:SteamID64()
end

function mAC.IP(ply)
	if not IsValid(ply) then return end
	local raw = ply:IPAddress()
	if not raw or raw == "" then return end
	return string.match(raw, "^([^:]+)") or raw
end

function mAC.Token(len)
	len = len or 32
	local t = {}
	for i = 1, len do
		t[i] = string.char(math.random(48, 122))
	end
	return table.concat(t)
end

function mAC.BitSet(bits, i)
	if not bits or i < 1 then return bits end
	local n = math.floor((i - 1) / 32)
	local b = (i - 1) % 32
	bits[n] = bit.bor(bits[n] or 0, bit.lshift(1, b))
	return bits
end

function mAC.BitTest(bits, i)
	if not bits or i < 1 then return false end
	local n = math.floor((i - 1) / 32)
	local b = (i - 1) % 32
	local v = bits[n]
	if not v then return false end
	return bit.band(v, bit.lshift(1, b)) ~= 0
end

function mAC.ReadBits()
	local n = net.ReadUInt(8)
	local out = {}
	for i = 1, n do
		out[i - 1] = net.ReadUInt(32)
	end
	return out
end

function mAC.WriteBits(bits)
	local max = -1
	for k in pairs(bits or {}) do
		if k > max then max = k end
	end
	local chunks = math.max(max + 1, 1)
	net.WriteUInt(chunks, 8)
	for i = 0, chunks - 1 do
		net.WriteUInt(bits[i] or 0, 32)
	end
end
