hg = hg or {}

local inf, ninf = 1 / 0, -1 / 0
local posLim = 28000
local velMax = 8000 * 8000
local angMax = 3600 * 3600

local classes = {
	prop_physics = true,
	prop_physics_multiplayer = true,
	prop_ragdoll = true,
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

function hg.physWatched(ent)
	return IsValid(ent) and classes[ent:GetClass()]
end

function hg.physCrazy(ent, po)
	if not IsValid(ent) then return end

	local p, a = ent:GetPos(), ent:GetAngles()
	if badVec(p) or badVec(a) or not okPos(p) then return "bad" end

	po = IsValid(po) and po or ent:GetPhysicsObject()
	if not IsValid(po) then return "bad" end

	local v = ent:GetVelocity()
	if badVec(v) or v:LengthSqr() > velMax then return "fast" end

	local av = po:GetAngleVelocity()
	if badVec(av) or av:LengthSqr() > angMax then return "fast" end
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

local function stop(ent, po)
	ent:CollisionRulesChanged()

	if IsValid(po) then
		po:EnableMotion(false)
		po:SetVelocity(vector_origin)
		po:SetAngleVelocity(vector_origin)
		po:Sleep()
	end

	ent:SetVelocity(vector_origin)
	ent:SetLocalVelocity(vector_origin)
	ent:SetLocalAngularVelocity(angle_zero)
	absVel(ent, vector_origin)
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

hook.Add("OnCrazyPhysics", "hg_phys", function(ent, po, why)
	if not hg.physWatched(ent) then return end

	why = why or hg.physCrazy(ent, po) or "fast"
	po = IsValid(po) and po or ent:GetPhysicsObject()

	if why == "bad" then
		ripCons(ent)
		drop(ent)
		return
	end

	ent.hg_physHits = (ent.hg_physHits or 0) + 1
	stop(ent, po)

	if not SERVER then return end

	if ent.hg_physHits >= 2 then ripCons(ent) end
	if ent.hg_physHits >= 3 then drop(ent) end
end)
