-- ManipulateBoneAngles: [1]=pitch [2]=yaw [3]=roll
-- правь hg.throatclutch_pose; цель hg_throatclutch_dist — 4–6 на обеих руках
hg.throatclutch_pose = hg.throatclutch_pose or {
	male = {
		r_upperarm = Angle(-62, -32, 22),
		r_forearm  = Angle(-88, 12, -10),
		r_forearm_pos = Vector(0, 0, 0),
		l_upperarm = Angle(-62, 32, -22),
		l_forearm  = Angle(-88, -12, 10),
		l_forearm_pos = Vector(0, 0, 0),
		head  = Angle(16, 0, 0),
		spine = Angle(12, 0, 0),
	},
	female = {
		r_upperarm = Angle(-58, -30, 20),
		r_forearm  = Angle(-84, 10, -8),
		r_forearm_pos = Vector(0, 0, 1),
		l_upperarm = Angle(-58, 30, -20),
		l_forearm  = Angle(-84, -10, 8),
		l_forearm_pos = Vector(0, 0, 1),
		head  = Angle(14, 0, 0),
		spine = Angle(10, 0, 0),
	},
}

local vec0 = vector_origin
local layer = "throatclutch"
local tuneOverlay = ConVarExists("hg_throatclutch_debug") and GetConVar("hg_throatclutch_debug")
	or CreateClientConVar("hg_throatclutch_debug", "0", true, false, "показывать дистанцию рука→шея")

local function getPose(ply)
	local key = ThatPlyIsFemale(ply) and "female" or "male"
	return hg.throatclutch_pose[key] or hg.throatclutch_pose.male
end

function hg.throatclutch_hand_dist(ply, side)
	local neck = ply:LookupBone("ValveBiped.Bip01_Neck1")
	local hand = ply:LookupBone(side == "r" and "ValveBiped.Bip01_R_Hand" or "ValveBiped.Bip01_L_Hand")
	if not neck or not hand then return -1 end
	local mn, mh = ply:GetBoneMatrix(neck), ply:GetBoneMatrix(hand)
	if not mn or not mh then return -1 end
	return mn:GetTranslation():Distance(mh:GetTranslation())
end

hook.Add("Bones", "organism_throatclutch", function(ply, dtime)
	local org = ply.organism
	if not org then return end

	local w = hg.organism.ThroatClutchAmt(org)
	if w < 0.08 or not ply:Alive() or IsValid(ply.FakeRagdoll) or org.choking then return end

	w = math.min(w, 1)
	local pose = getPose(ply)
	local shake = math.sin(CurTime() * 9) * 4 * w
	local lerp = 0.1

	if hg.CanUseRightHand(ply) and not org.rarmamputated then
		hg.bone.Set(ply, "r_upperarm", vec0, (pose.r_upperarm + Angle(-shake, 0, 0)) * w, layer .. "rua", lerp, dtime)
		hg.bone.Set(ply, "r_forearm", pose.r_forearm_pos or vec0, pose.r_forearm * w, layer .. "rfa", lerp, dtime)
	end

	if hg.CanUseLeftHand(ply) and not org.larmamputated then
		hg.bone.Set(ply, "l_upperarm", vec0, (pose.l_upperarm + Angle(shake, 0, 0)) * w, layer .. "lua", lerp, dtime)
		hg.bone.Set(ply, "l_forearm", pose.l_forearm_pos or vec0, pose.l_forearm * w, layer .. "lfa", lerp, dtime)
	end

	if w > 0.15 then
		hg.bone.Set(ply, "head", vec0, (pose.head + Angle(shake * 0.4, 0, 0)) * w, layer .. "head", lerp, dtime)
		hg.bone.Set(ply, "spine2", vec0, pose.spine * w, layer .. "spine", lerp, dtime)
	end

	if tuneOverlay:GetBool() and ply == LocalPlayer() then
		local dr, dl = hg.throatclutch_hand_dist(ply, "r"), hg.throatclutch_hand_dist(ply, "l")
		if dr > 0 then
			debugoverlay.Text(ply:GetPos() + Vector(0, 0, 72), ("throat L:%.1f R:%.1f"):format(dl, dr), 0.12, true)
		end
	end
end)

local boneAlias = {
	rua = "r_upperarm", rfa = "r_forearm", rfp = "r_forearm_pos",
	lua = "l_upperarm", lfa = "l_forearm", lfp = "l_forearm_pos",
	head = "head", spine = "spine",
}

-- hg_throatclutch_tune rfa p 5
concommand.Add("hg_throatclutch_tune", function(_, _, args)
	local ply = LocalPlayer()
	local pose = getPose(ply)
	local key = boneAlias[args[1]] or args[1]
	local axis = args[2] or "p"
	local delta = tonumber(args[3]) or 0
	local val = pose[key]
	if not val or val[axis] == nil then
		print("кости: rua rfa rfp lua lfa lfp head spine | оси: p y r")
		return
	end
	val[axis] = val[axis] + delta
	print(key, axis, "=", val[axis], "| L:", hg.throatclutch_hand_dist(ply, "l"), "R:", hg.throatclutch_hand_dist(ply, "r"))
end)

concommand.Add("hg_throatclutch_dump", function()
	PrintTable(getPose(LocalPlayer()))
end)
