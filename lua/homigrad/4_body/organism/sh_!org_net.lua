hg = hg or {}

local sfs = hg.sfs
local maxOrg = 98304
local maxFx = 512

local function pack(t)
	if not sfs then
		ErrorNoHalt("sh_!org_net.lua: нет sfs\n")
		return
	end

	local d, err = sfs.encode(t)
	if not d then
		ErrorNoHalt("sh_!org_net.lua: " .. tostring(err) .. "\n")
		return
	end

	return d
end

function hg.orgWrite(t, lim)
	local d = pack(t)
	if not d then return end

	lim = lim or maxOrg
	net.WriteUInt(#d, 17)
	net.WriteData(d, #d)
end

function hg.orgRead(lim)
	if not sfs then return end

	lim = lim or maxOrg
	local n = net.ReadUInt(17)
	if n < 1 or n > lim then return end

	local t, err = sfs.decode(net.ReadData(n), n + 64)
	if err then
		ErrorNoHalt("sh_!org_net.lua: " .. tostring(err) .. "\n")
		return
	end

	return t
end

function hg.orgWritePacket(t)
	hg.orgWrite(t)
end

function hg.orgReadPacket()
	local t = hg.orgRead()
	if not t then return end
	return t, net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()
end

function hg.orgWriteFx(t)
	local d = pack(t)
	if not d then return end

	net.WriteUInt(#d, 12)
	net.WriteData(d, #d)
end

function hg.orgReadFx()
	if not sfs then return end

	local n = net.ReadUInt(12)
	if n < 1 or n > maxFx then return end

	local t, err = sfs.decode(net.ReadData(n), n + 32)
	if err then
		ErrorNoHalt("sh_!org_net.lua: " .. tostring(err) .. "\n")
		return
	end

	return t
end

function hg.orgBloodSend(pos, vel, mul, amt)
	hg.orgWriteFx({pos, vel, mul, amt})
end

function hg.orgBloodRead()
	local d = hg.orgReadFx()
	if not d then return end
	return d[1], d[2], d[3], d[4]
end

function hg.orgSquirtSend(ent, bone, mat, pos, dir)
	hg.orgWriteFx({ent, bone, mat, pos, dir})
end

function hg.orgSquirtRead()
	local d = hg.orgReadFx()
	if not d then return end
	return d[1], d[2], d[3], d[4], d[5]
end

function hg.orgFountainSend(ent, force)
	hg.orgWriteFx({ent, force})
end

function hg.orgFountainRead()
	local d = hg.orgReadFx()
	if not d then return end
	return d[1], d[2]
end
