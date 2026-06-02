hg = hg or {}

local inf, ninf = 1 / 0, -1 / 0
local posLim = 28000

local classes = {
	prop_physics = true,
	prop_physics_multiplayer = true,
	prop_ragdoll = true,
}

local velMaxSqr = 6500 * 6500
local angMaxSqr = {
	prop = 5500 * 5500,
	ragdoll = 10000 * 10000,
}

local velClamp = {
	prop = 3000,
	ragdoll = 3800,
}

local angClamp = {
	prop = 2000,
	ragdoll = 4500,
}

function math.BadNumber(n)
	return n == nil or n == inf or n == ninf or not (n >= 0 or n <= 0)
end

local function badVec(v)
	return math.BadNumber(v.x) or math.BadNumber(v.y) or math.BadNumber(v.z)
end

local function okPos(p)
	return p.x >= -posLim and p.x <= posLim
		and p.y >= -posLim and p.y <= posLim
		and p.z >= -posLim and p.z <= posLim
end

local function isRag(ent)
	return ent:GetClass() == "prop_ragdoll"
end

function hg.physPlayerRag(ent)
	if not isRag(ent) then return end

	local ply = ent.ply
	if not IsValid(ply) then
		ply = ent:GetNWEntity("ply", NULL)
	end

	if IsValid(ply) and ply:IsPlayer() then
		return ply
	end
end

function hg.physWatched(ent)
	return IsValid(ent) and classes[ent:GetClass()]
end

local function crazyPo(po, angLimSqr)
	if not IsValid(po) then return "bad" end

	local v = po:GetVelocity()
	if badVec(v) or v:LengthSqr() > velMaxSqr then return "fast" end

	local av = po:GetAngleVelocity()
	if badVec(av) or av:LengthSqr() > angLimSqr then return "fast" end
end

function hg.physCrazy(ent, po)
	if not IsValid(ent) then return end

	local p, a = ent:GetPos(), ent:GetAngles()
	if badVec(p) or badVec(a) or not okPos(p) then return "bad" end

	local angLimSqr = isRag(ent) and angMaxSqr.ragdoll or angMaxSqr.prop

	if isRag(ent) then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local why = crazyPo(ent:GetPhysicsObjectNum(i), angLimSqr)
			if why then return why end
		end
		return
	end

	return crazyPo(IsValid(po) and po or ent:GetPhysicsObject(), angLimSqr)
end

local function absVel(ent, vel)
	if ent:GetInternalVariable("m_vecAbsVelocity") == vel then return end

	ent:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)

	local ch = ent:GetChildren()
	for i = 1, #ch do
		ch[i]:AddEFlags(EFL_DIRTY_ABSVELOCITY)
	end

	ent:SetSaveValue("m_vecAbsVelocity", vel)
	ent:SetSaveValue("velocity", vel)
end

local function clampLen(v, max)
	local sqr = v:LengthSqr()
	if sqr <= max * max or sqr < 1 then return v end
	return v * (max / math.sqrt(sqr))
end

local function calmPo(po, vMax, aMax)
	if not IsValid(po) then return end

	po:EnableMotion(true)
	po:Wake()

	local v = po:GetVelocity()
	po:SetVelocity(badVec(v) and vector_origin or clampLen(v, vMax))

	local av = po:GetAngleVelocity()
	po:SetAngleVelocity(badVec(av) and vector_origin or clampLen(av, aMax))
end

local function calm(ent, po)
	ent:CollisionRulesChanged()

	local rag = isRag(ent)
	local vMax = rag and velClamp.ragdoll or velClamp.prop
	local aMax = rag and angClamp.ragdoll or angClamp.prop

	if rag then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			calmPo(ent:GetPhysicsObjectNum(i), vMax, aMax)
		end
	else
		calmPo(IsValid(po) and po or ent:GetPhysicsObject(), vMax, aMax)
	end

	local ev = ent:GetVelocity()
	ev = badVec(ev) and vector_origin or clampLen(ev, vMax)

	ent:SetVelocity(ev)
	ent:SetLocalVelocity(ev)
	ent:SetLocalAngularVelocity(angle_zero)
	absVel(ent, ev)
end

local function ripCons(ent)
	if not SERVER then return end

	local done, q = {}, {ent}

	while #q > 0 do
		local e = table.remove(q, 1)
		if not IsValid(e) or done[e] then continue end
		done[e] = true

		if constraint.RemoveAll then constraint.RemoveAll(e) end

		local linked = constraint.GetAllConstrainedEntities(e)
		if not linked then continue end

		for o in pairs(linked) do
			if IsValid(o) and not done[o] then q[#q + 1] = o end
		end
	end
end

local function drop(ent)
	if not SERVER or not IsValid(ent) or ent.hg_physDrop then return end

	ent.hg_physDrop = true
	ent:Remove()
end

local function ragGrace(ent)
	return isRag(ent) and ent:GetCreationTime() > CurTime() - 0.4
end

hook.Add("OnCrazyPhysics", "hg_phys", function(ent, po, why)
	if not hg.physWatched(ent) then return end
	if ragGrace(ent) then return end

	why = why or hg.physCrazy(ent, po) or "fast"
	po = IsValid(po) and po or ent:GetPhysicsObject()

	if isRag(ent) then
		drop(ent)
		return
	end

	if why == "bad" then
		if hg.physPlayerRag(ent) then
			calm(ent, po)
			return
		end

		ripCons(ent)
		drop(ent)
		return
	end

	calm(ent, po)

	if not SERVER or hg.physPlayerRag(ent) then return end

	ent.hg_physHits = (ent.hg_physHits or 0) + 1

	if ent.hg_physHits >= 8 then ripCons(ent) end
	if ent.hg_physHits >= 15 then drop(ent) end
end)
