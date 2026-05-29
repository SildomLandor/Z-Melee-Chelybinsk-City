hg = hg or {}

local sfs = hg.sfs
local maxOrg = 98304
local maxFx = 512

-- порядок = индекс в дельта пакете, не менять без смены протокола
hg.orgFullKeys = {
	"alive", "otrub", "owner", "stamina", "immobilization", "adrenaline", "adrenalineAdd", "analgesia",
	"lleg", "rleg", "rarm", "larm", "pelvis", "disorientation", "brain", "o2", "CO", "blood", "bloodtype",
	"bleed", "hurt", "pain", "shock", "pulse", "heartbeat", "timeValue", "holdingbreath", "arteria", "neckslit",
	"recoilmul", "meleespeed", "temperature", "canmove", "fear", "llegdislocation", "rlegdislocation",
	"rarmdislocation", "larmdislocation", "jawdislocation", "llegamputated", "rlegamputated", "rarmamputated",
	"larmamputated", "headamputated", "lungsfunction", "consciousness", "assimilated", "berserk", "noradrenaline",
	"LodgedEntities", "CantCheckPulse", "blindness", "critical", "incapacitated", "berserkActive2",
	"noradrenalineActive", "lastPepperHit", "superfighter", "coma", "coma_depth", "coma_gcs", "coma_flicker",
}

-- подмножество для PVS-зрителей (свой порядок индексов)
hg.orgBareKeys = {
	"alive", "otrub", "owner", "bloodtype", "pulse", "blood", "heartbeat", "analgesia", "o2", "timeValue",
	"superfighter", "lungsfunction", "lleg", "rleg", "rarm", "larm", "llegdislocation", "rlegdislocation",
	"rarmdislocation", "larmdislocation", "jawdislocation", "llegamputated", "rlegamputated", "rarmamputated",
	"larmamputated", "headamputated", "LodgedEntities", "neckslit", "berserkActive2", "CantCheckPulse",
	"noradrenalineActive",
}

function hg.orgPick(org, keys)
	local t = {}
	for i = 1, #keys do
		local k = keys[i]
		t[k] = org[k]
	end
	return t
end

hg.orgDefaults = {
	pain = 0, brain = 0, blood = 5000, bleed = 0, hurt = 0, shock = 0,
	pulse = 70, heartbeat = 70, disorientation = 0, adrenaline = 0, adrenalineAdd = 0,
	analgesia = 0, consciousness = 1, fear = 0, immobilization = 0, temperature = 36.7,
	recoilmul = 1, meleespeed = 1, timeValue = 0, CO = 0, berserk = 0, noradrenaline = 0,
	coma_depth = 0, coma_gcs = 15, assimilated = 0, lastPepperHit = 0,
	lleg = 0, rleg = 0, larm = 0, rarm = 0, pelvis = 0,
	alive = true, otrub = false, lungsfunction = true, canmove = true, superfighter = false,
	critical = false, incapacitated = false, berserkActive2 = false, noradrenalineActive = false,
	CantCheckPulse = false, holdingbreath = false, coma = false, coma_flicker = false,
	llegdislocation = false, rlegdislocation = false, larmdislocation = false, rarmdislocation = false,
	jawdislocation = false, llegamputated = false, rlegamputated = false, rarmamputated = false,
	larmamputated = false, headamputated = false, neckslit = false,
}

function hg.orgEnsureDefaults(org)
	if not istable(org) then return end
	for k, v in pairs(hg.orgDefaults) do
		if org[k] == nil then org[k] = v end
	end
end

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

local function fieldEq(a, b)
	if a == b then return true end
	if not istable(a) or not istable(b) then return false end
	if not sfs then return false end
	local ea, eb = sfs.encode(a), sfs.encode(b)
	return ea and eb and ea == eb
end

function hg.orgFieldEq(a, b)
	return fieldEq(a, b)
end

function hg.orgNeedsSend(cur, prev, keys)
	if not prev then return true end
	for i = 1, #keys do
		if not fieldEq(cur[keys[i]], prev[keys[i]]) then return true end
	end
	return false
end

function hg.orgWritePacket(cur, prev, keys, forceFull)
	if prev == nil and keys == nil and forceFull == nil then
		net.WriteUInt(1, 2)
		hg.orgWrite(cur)
		return
	end

	if forceFull or not prev then
		net.WriteUInt(1, 2)
		hg.orgWrite(cur)
		local snap = {}
		for i = 1, #keys do
			snap[keys[i]] = cur[keys[i]]
		end
		return snap
	end

	local idx, vals = {}, {}
	for i = 1, #keys do
		local k = keys[i]
		if not fieldEq(cur[k], prev[k]) then
			idx[#idx + 1] = i
			vals[#vals + 1] = cur[k]
		end
	end

	if #idx == 0 then
		net.WriteUInt(0, 2)
		return prev
	end

	net.WriteUInt(2, 2)
	net.WriteUInt(#idx, 7)
	for j = 1, #idx do
		net.WriteUInt(idx[j], 7)
	end
	hg.orgWrite(vals)

	local snap = table.Copy(prev)
	for j = 1, #idx do
		snap[keys[idx[j]]] = cur[keys[idx[j]]]
	end
	return snap
end

function hg.orgReadPacket(base, keys)
	local mode = net.ReadUInt(2)
	local org

	if mode == 1 then
		org = hg.orgRead()
		hg.orgEnsureDefaults(org)
	elseif mode == 2 and keys then
		local n = net.ReadUInt(7)
		local idx = {}
		for j = 1, n do
			idx[j] = net.ReadUInt(7)
		end
		local vals = hg.orgRead()
		if not vals then return end
		org = istable(base) and table.Copy(base) or {}
		for j = 1, n do
			org[keys[idx[j]]] = vals[j]
		end
		hg.orgEnsureDefaults(org)
	elseif mode == 0 then
		org = base
	else
		org = hg.orgRead()
	end

	if not org then return end
	return org, net.ReadBool(), net.ReadBool(), net.ReadBool(), net.ReadBool()
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
	net.WriteVector(pos)
	net.WriteVector(vel)
	net.WriteFloat(mul or 1)
	net.WriteUInt(math.Clamp(amt or 1, 0, 32), 6)
end

function hg.orgBloodRead()
	return net.ReadVector(), net.ReadVector(), net.ReadFloat(), net.ReadUInt(6)
end

function hg.orgSquirtSend(ent, bone, mat, pos, dir)
	net.WriteUInt(IsValid(ent) and ent:EntIndex() or 0, 16)
	net.WriteString(bone or "")
	net.WriteVector(pos)
	net.WriteVector(dir)
end

function hg.orgSquirtRead()
	local ent = Entity(net.ReadUInt(16))
	local bone = net.ReadString()
	local pos, dir = net.ReadVector(), net.ReadVector()
	local bid = IsValid(ent) and ent:LookupBone(bone)
	local bmat = bid and ent:GetBoneMatrix(bid)
	return ent, bone, bmat, pos, dir
end

function hg.orgFountainSend(ent, force)
	net.WriteUInt(IsValid(ent) and ent:EntIndex() or 0, 16)
	net.WriteVector(force or vector_origin)
end

function hg.orgFountainRead()
	return Entity(net.ReadUInt(16)), net.ReadVector()
end

function hg.netWriteSFS(t, lim)
	local d = pack(t)
	if not d then return false end
	lim = lim or maxOrg
	net.WriteUInt(#d, 17)
	net.WriteData(d, #d)
	return true
end

function hg.netReadSFS(lim)
	return hg.orgRead(lim)
end

function hg.orgNetHeader(owner, isBare)
	net.WriteUInt(IsValid(owner) and owner:EntIndex() or 0, 16)
	net.WriteBool(isBare and true or false)
end

function hg.orgNetReadHeader()
	return net.ReadUInt(16), net.ReadBool()
end
