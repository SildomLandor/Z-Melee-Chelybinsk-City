local vec0, ang0 = vector_origin, angle_zero
local layer = "throatclutch"

hook.Add("Bones", "organism_throatclutch", function(ply, dtime)
	local org = ply.organism
	if not org then return end

	local w = hg.organism.ThroatClutchAmt(org)
	if w < 0.08 or not ply:Alive() or IsValid(ply.FakeRagdoll) or org.choking then return end

	w = math.min(w, 1)
	local shake = math.sin(CurTime() * 9) * 4 * w
	local lerp = 0.1

	if hg.CanUseRightHand(ply) and not org.rarmamputated then
		hg.bone.Set(ply, "r_upperarm", vec0, Angle(-58 - shake, -28, 18) * w, layer .. "rua", lerp, dtime)
		hg.bone.Set(ply, "r_forearm", vec0, Angle(-82, 8, -8) * w, layer .. "rfa", lerp, dtime)
	end

	if hg.CanUseLeftHand(ply) and not org.larmamputated then
		hg.bone.Set(ply, "l_upperarm", vec0, Angle(-58 + shake, 28, -18) * w, layer .. "lua", lerp, dtime)
		hg.bone.Set(ply, "l_forearm", vec0, Angle(-82, -8, 8) * w, layer .. "lfa", lerp, dtime)
	end

	if w > 0.15 then
		hg.bone.Set(ply, "head", vec0, Angle(14 + shake * 0.4, 0, 0) * w, layer .. "head", lerp, dtime)
		hg.bone.Set(ply, "spine2", vec0, Angle(10, 0, 0) * w, layer .. "spine", lerp, dtime)
	end
end)
