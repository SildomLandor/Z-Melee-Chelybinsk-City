hg.blood_react_next = hg.blood_react_next or 0
hg.blood_react_cells = hg.blood_react_cells or {}

local CELL = 80
local see_dist_sqr = 380 * 380
local close_dist_sqr = 120 * 120
local fov_dot = 0.2
local room_radius = 400
local room_min_cells = 4
local wall_blood_cells = 2
local check_step = 0.6

local ceil_trace = { mask = MASK_SOLID_BRUSHONLY }
local look_trace = { mask = MASK_SOLID }

local function canBloodThought(ply)
	if not IsValid(ply) or not ply:Alive() then return false end
	if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return false end
	if hook.Run("HG_CanThoughts", ply) == false then return false end
	if ply:IsBerserk() then return false end

	local org = ply.organism
	if not org or org.otrub then return false end

	return true
end

local function countBloodCells(pos, radius)
	radius = radius or room_radius
	local cells = hg.blood_react_cells
	if not cells then return 0 end

	local rings = math.ceil(radius / CELL)
	local cx = math.floor(pos.x / CELL)
	local cy = math.floor(pos.y / CELL)
	local cz = math.floor(pos.z / CELL)
	local n = 0

	for dx = -rings, rings do
		for dy = -rings, rings do
			for dz = -1, 2 do
				if cells[(cx + dx) .. ":" .. (cy + dy) .. ":" .. (cz + dz)] then
					n = n + 1
				end
			end
		end
	end

	return n
end

local function playerSeesBlood(eye, aim)
	local parts = hg.bloodparticles1
	if not parts then return false end

	for i = 1, #parts do
		local part = parts[i]
		if not part then continue end

		local bpos = part[1]
		local ds = bpos:DistToSqr(eye)
		if ds > see_dist_sqr then continue end

		if ds <= close_dist_sqr then return true end

		local dir = bpos - eye
		if dir:LengthSqr() < 1 then continue end
		dir:Normalize()

		if aim:Dot(dir) >= fov_dot then return true end
	end

	return false
end

local function playerLooksAtBloodDecal(eye, aim)
	look_trace.start = eye
	look_trace.endpos = eye + aim * 380
	look_trace.filter = lply

	local tr = util.TraceLine(look_trace)
	if not tr.Hit then return false end

	return countBloodCells(tr.HitPos, 160) >= wall_blood_cells
end

local function playerInBloodRoom(pos)
	if countBloodCells(pos) < room_min_cells then return false end

	ceil_trace.start = pos
	ceil_trace.endpos = pos + Vector(0, 0, 520)
	local tr = util.TraceLine(ceil_trace)

	return tr.Hit and not tr.HitSky
end

local next_check = 0

hook.Add("Think", "hg_blood_react", function()
	if CurTime() < next_check then return end
	next_check = CurTime() + check_step

	local ply = lply
	if not canBloodThought(ply) then return end
	if CurTime() < hg.blood_react_next then return end

	local eye = ply:EyePos()
	local aim = ply:GetAimVector()
	local sees = playerSeesBlood(eye, aim) or playerLooksAtBloodDecal(eye, aim)
	local room = not sees and playerInBloodRoom(eye)

	if not sees and not room then return end

	local msg = hg.get_blood_react_message and hg.get_blood_react_message() or ""
	if msg == "" then return end

	ply:Notify(msg, 4, Color(210, 185, 185, 255))
	hg.blood_react_next = CurTime() + math.Rand(20, 38)
end)

hook.Add("Player Spawn", "hg_blood_react_reset", function(ply)
	if ply ~= lply then return end
	hg.blood_react_next = CurTime() + 8
end)

hook.Add("PostCleanupMap", "hg_blood_react_reset_cells", function()
	hg.blood_react_cells = {}
	hg.blood_react_next = 0
end)
