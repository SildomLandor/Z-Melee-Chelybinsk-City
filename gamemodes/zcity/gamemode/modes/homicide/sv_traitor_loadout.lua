local MODE = MODE
local TL = hg.TraitorLoadout

util.AddNetworkString("HMCD_TraitorLoadout")

net.Receive("HMCD_TraitorLoadout", function(_, ply)
	if not IsValid(ply) then return end
	if ply.HMCD_TraitorLoadoutNext and ply.HMCD_TraitorLoadoutNext > CurTime() then return end
	ply.HMCD_TraitorLoadoutNext = CurTime() + TL.NetCooldown

	local str = net.ReadString()
	if not isstring(str) or #str > 4096 then return end

	ply.HMCD_TraitorLoadout = TL.Sanitize(TL.Parse(str))
end)

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
	TL.ApplyToTraitor(ply, loadout, modeType)
end
