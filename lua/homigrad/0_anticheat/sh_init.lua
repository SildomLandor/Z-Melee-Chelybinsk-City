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

local fpmarks = { "cf_font", "font_exec", "jopa_gone", "jopa_rm" }

function mAC.FalsePositiveReason(reason)
	reason = tostring(reason or "")
	for i = 1, #fpmarks do
		if reason:find(fpmarks[i], 1, true) then return true end
	end
	return false
end

function mAC.ReasonCategory(reason)
	reason = tostring(reason or "")

	if reason == "cookie_alt" or reason == "cookie" then return "cookie_alt" end
	if reason == "ip" then return "bypass" end
	if reason:sub(1, 7) == "cookie:" then return "cookie" end
	if reason:sub(1, 3) == "ip:" then return "ip" end

	local body = reason
	while body:match("^#%d+%s*") do
		body = body:gsub("^#%d+%s*", "", 1)
	end
	body = body:match("^([^|]+)") or body
	body = body:match("^(%S+)") or body

	if body == "ban" or body == "banned" then return "banned" end
	if body == "cookie_alt" then return "cookie_alt" end
	if body == "bypass" then return "bypass" end
	if body == "fonts" or body == "sig" or body == "soft" then return body end

	return body
end

function mAC.BanCode(reason)
	local cfg = mAC.cfg and mAC.cfg.banCodes or {}
	reason = tostring(reason or "")

	if reason:sub(1, 7) == "cookie:" then return cfg.cookie or 5 end
	if reason:sub(1, 3) == "ip:" then return cfg.ip or 7 end

	local cat = mAC.ReasonCategory(reason)

	if cfg[cat] then return cfg[cat] end
	if cat == "ban" or cat == "banned" then return cfg.banned or 4 end
	if cat == "cookie_alt" then return cfg.cookie_alt or 6 end
	if cat == "bypass" then return cfg.bypass or 3 end

	return cfg.default or 9
end

function mAC.PublicBanMsg(code)
	return "КОД: " .. tostring(code)
end

function mAC.SecretBanNote(reason, detail, code)
	local cat = mAC.ReasonCategory(reason)
	local s = string.format("#%s %s", tostring(code), cat)
	if detail and detail ~= "" then s = s .. " | " .. tostring(detail) end
	return s
end

function mAC.PlayerLabel(ply)
	if not IsValid(ply) then return "?" end
	return string.format("%s (%s | %s)", ply:Nick(), ply:SteamID(), mAC.IP(ply) or "?")
end

function mAC.Debug(...)
	if not SERVER then return end
	if not mAC.cfg or not mAC.cfg.debug then return end

	local n = select("#", ...)
	local parts = {}
	for i = 1, n do parts[i] = tostring(select(i, ...)) end

	local line = table.concat(parts, " ")
	print("[mAC] " .. line)

	if mAC.cfg.logFile then
		file.CreateDir("mac")
		file.Append(mAC.cfg.logFile, string.format("[%s] [dbg] %s\n", os.date("%Y-%m-%d %H:%M:%S"), line))
	end
end

function mAC.PlayerSnap(ply)
	if not IsValid(ply) then return end
	return {
		nick = ply:Nick(),
		sid = ply:SteamID(),
		s64 = ply:SteamID64(),
		ip = mAC.IP(ply),
		ent = ply:EntIndex(),
	}
end
