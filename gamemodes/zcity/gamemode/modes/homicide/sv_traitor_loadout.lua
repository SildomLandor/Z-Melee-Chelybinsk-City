local MODE = MODE
local TL = hg.TraitorLoadout

function MODE.ApplyTraitorLoadout(ply, modeType)
	if not IsValid(ply) or not ply.isTraitor or not ply.MainTraitor then return end
	if not hg or not hg.TraitorLoadout then return end

	local loadout = TL.GetPlayerLoadout(ply)
	local sub_role = TL.ResolveSubRole(loadout.skillset, modeType)
	local roles = MODE.RoleChooseRoundTypes[modeType]

	if roles then
		if not roles.Traitor[sub_role] then
			sub_role = roles.TraitorDefaultRole or "traitor_default"
		end
		if not MODE.SubRoles[sub_role] then
			sub_role = roles.TraitorDefaultRole or "traitor_default"
		end
	end

	ply.SubRole = sub_role
	loadout = TL.ApplyToTraitor(ply, loadout, modeType) or loadout

	if TL.WantsDefaultLoot(loadout) then
		local t = MODE.Types[modeType]
		if t and t.TraitorLoot then
			t.TraitorLoot(ply)
		end
	end
end
