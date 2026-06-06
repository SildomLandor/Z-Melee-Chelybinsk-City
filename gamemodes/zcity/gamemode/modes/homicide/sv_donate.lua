local MODE = MODE

MODE.Donaters = {
	-- ["STEAM_0:0:791306214"] = {surgeon = true},
	["STEAM_0:0:162799155"] = {surgeon = true},
}

function MODE.GetDonatePerks(ply)
	if not IsValid(ply) then return end
	return MODE.Donaters[ply:SteamID()]
end

function MODE.HasDonatePerk(ply, perk)
	local perks = MODE.GetDonatePerks(ply)
	return perks and perks[perk]
end

function MODE.CanBeSurgeon(ply)
	if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then return false end
	if ply.isTraitor or ply.isGunner then return false end
	return MODE.HasDonatePerk(ply, "surgeon")
end

function MODE.AssignDonateProfessions()
	if not MODE.RoleChooseRoundTypes or not MODE.RoleChooseRoundTypes[MODE.Type] then return end

	for _, ply in player.Iterator() do
		if MODE.CanBeSurgeon(ply) then
			ply.Profession = "surgeon"
		end
	end
end

function MODE.SurgeonGiveLoadout(ply)
	if not IsValid(ply) or ply.Profession ~= "surgeon" then return end
	if ply:HasWeapon("weapon_scalpel") then return end
	ply:Give("weapon_scalpel")
end

util.AddNetworkString("HMCD_SurgeonAnalyzing")
util.AddNetworkString("HMCD_SurgeonArteryCutting")
util.AddNetworkString("HMCD_SurgeonReveal")
util.AddNetworkString("HMCD_SurgeonAnalyzeRequest")

local function hmcd_round_active()
	return zb.CROUND == "hmcd" or zb.CROUND_MAIN == "hmcd"
end

local function surgeon_busy(ply)
	return ply.Ability_SurgeonAnalyze or ply.Ability_SurgeonArteryCut
end

local function surgeon_validate_action(ply, victim)
	if not hmcd_round_active() then return false end
	if not IsValid(ply) or ply.Profession ~= "surgeon" then return false end
	if not ply:Alive() or ply.organism and ply.organism.otrub then return false end
	if surgeon_busy(ply) then return false end
	if not IsValid(victim) or not victim:IsPlayer() or victim == ply or not victim:Alive() then return false end
	if not MODE.SurgeonCanSeeTarget(ply, victim) then return false end

	local aim_ent = hg.GetCurrentCharacter(victim) or victim
	if not MODE.SurgeonCanTouchTarget(ply, aim_ent, victim) then return false end

	return true, aim_ent
end

net.Receive("HMCD_SurgeonAnalyzeRequest", function(_, ply)
	local victim = net.ReadEntity()
	if not surgeon_validate_action(ply, victim) then return end
	MODE.StartSurgeonAnalyze(ply, victim)
end)

hook.Add("PlayerPostThink", "HMCD_Surgeon", function(ply)
	if zb.CROUND ~= "hmcd" and zb.CROUND_MAIN ~= "hmcd" then return end
	if not ply:Alive() or ply.Profession ~= "surgeon" then return end
	if ply.organism and ply.organism.otrub then return end

	if ply.Ability_SurgeonAnalyze then
		MODE.ContinueSurgeonAnalyze(ply)
	end

	if ply:KeyDown(IN_WALK) then
		if ply:KeyPressed(IN_USE) and not ply.Ability_SurgeonAnalyze and not ply.Ability_SurgeonArteryCut then
			local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply, nil, MODE.SurgeonReach)
			if IsValid(other_ply) and other_ply ~= ply and other_ply:Alive()
				and MODE.SurgeonWantsSharpCut(ply, ply:GetActiveWeapon())
				and MODE.SurgeonTraceArtery(ply, other_ply)
				and MODE.SurgeonCanTouchTarget(ply, aim_ent or other_ply, other_ply) then
				MODE.StartSurgeonArteryCut(ply, other_ply)
			end
		elseif ply:KeyDown(IN_USE) and ply.Ability_SurgeonArteryCut then
			MODE.ContinueSurgeonArteryCut(ply)
		end

		if ply:KeyReleased(IN_USE) then
			MODE.StopSurgeonArteryCut(ply)
		end
	else
		MODE.StopSurgeonArteryCut(ply)
	end
end)

hook.Add("PlayerSpawn", "HMCD_SurgeonLoadout", function(ply)
	timer.Simple(0, function()
		if not IsValid(ply) or not ply:Alive() then return end
		ply.SurgeonRevealVictim = nil
		ply.SurgeonRevealUntil = nil
		MODE.StopSurgeonAnalyze(ply)
		MODE.StopSurgeonArteryCut(ply)
		MODE.SurgeonGiveLoadout(ply)
	end)
end)

hook.Add("PlayerDisconnected", "HMCD_Surgeon", function(ply)
	ply.SurgeonRevealVictim = nil
	ply.SurgeonRevealUntil = nil
end)
