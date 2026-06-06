local MODE = MODE

MODE.Donaters = {
	["STEAM_0:0:791306214"] = {surgeon = true},
	--["STEAM_0:0:162799155"] = {surgeon = true, ment = true},
	["STEAM_0:1:628835900"] = {ment = true}
	--["steam"] = {surgeon = true}
}

function MODE.GetDonatePerks(ply)
	if not IsValid(ply) then return end

	local perks = MODE.Donaters[ply:SteamID()]
	if perks then return perks end

	local id64 = ply:SteamID64()
	if not id64 then return end

	for sid, row in pairs(MODE.Donaters) do
		if util.SteamIDTo64(sid) == id64 then
			return row
		end
	end
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

function MODE.IsMentGunner(ply)
	if not IsValid(ply) or not ply.isGunner or ply.isTraitor then return false end
	return MODE.HasDonatePerk(ply, "ment")
end

function MODE.AssignDonateProfessions()
	for _, ply in player.Iterator() do
		if MODE.CanBeSurgeon(ply) then
			ply.Profession = "surgeon"
		end
	end
end

function MODE.SurgeonGiveLoadout(ply)
	if not IsValid(ply) or ply.Profession ~= "surgeon" then return end
end

local function ment_give_wep(ply, class)
	local wep = ply:Give(class)
	if not IsValid(wep) then return wep end
	local clip, ammoType = wep:GetMaxClip1(), wep:GetPrimaryAmmoType()
	if clip and clip > 0 and ammoType and ammoType >= 0 then
		ply:RemoveAmmo(ply:GetAmmoCount(ammoType), ammoType)
	end
	return wep
end

function MODE.ClearMentPerks(ply)
	if not IsValid(ply) then return end
	ply.isMent = nil
	ply.MentKarmaLossMul = nil
	ply.MeleeDamageMul = nil
	ply._mentStaminaBase = nil
end

function MODE.ApplyMentStats(ply)
	if not IsValid(ply) or not ply.organism then return end

	ply.MeleeDamageMul = 1.1
	ply.MentKarmaLossMul = 2
	ply.isMent = true

	local org = ply.organism
	if not org.stamina then return end

	local base = ply._mentStaminaBase or org.stamina.max or org.stamina[1] or 180
	ply._mentStaminaBase = base
	local newMax = math.Round(base * 1.1)
	org.stamina.max = newMax
	org.stamina.range = newMax
	org.stamina[1] = math.min(org.stamina[1] or newMax, newMax)
end

function MODE.ApplyMentGunnerLoot(ply)
	if not MODE.IsMentGunner(ply) then
		MODE.ClearMentPerks(ply)
		return false
	end

	for _, wep in ipairs(ply:GetWeapons()) do
		if wep:GetClass() ~= "weapon_hands_sh" then
			ply:StripWeapon(wep:GetClass())
		end
	end

	ment_give_wep(ply, "weapon_makarov")
	ply:Give("weapon_handcuffs")
	ply:Give("weapon_handcuffs_key")

	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = nil
	ply:SetNetVar("Inventory", inv)

	if ply.organism then
		ply.organism.recoilmul = 1
	end

	MODE.ApplyMentStats(ply)
	return true
end

if not MODE._MentKarmaGainPatched and zb.GuiltKarmaGain then
	MODE._MentKarmaGainPatched = true
	local origGain = zb.GuiltKarmaGain
	function zb.GuiltKarmaGain(ply, karma)
		local gain = origGain(ply, karma)
		if MODE.IsMentGunner(ply) then
			gain = gain * 1.1
		end
		return gain
	end
end

hook.Add("HMCD_GunManLoot", "HMCD_Ment", function(ply)
	if not IsValid(ply) or not ply.isGunner then
		if IsValid(ply) then MODE.ClearMentPerks(ply) end
		return
	end
	MODE.ApplyMentGunnerLoot(ply)
end)

util.AddNetworkString("HMCD_SurgeonArteryCutting")

hook.Add("PlayerPostThink", "HMCD_Surgeon", function(ply)
	if zb.CROUND ~= "hmcd" and zb.CROUND_MAIN ~= "hmcd" then return end
	if not ply:Alive() or ply.Profession ~= "surgeon" then return end
	if ply.organism and ply.organism.otrub then return end

	if ply:KeyDown(IN_WALK) then
		if ply:KeyDown(IN_USE) then
			if ply.Ability_SurgeonArteryCut then
				MODE.ContinueSurgeonArteryCut(ply)
			elseif ply:KeyPressed(IN_USE) or ply:KeyPressed(IN_WALK) then
				local _, other_ply = MODE.GetPlayerTraceToOther(ply, nil, MODE.SurgeonReach)
				if IsValid(other_ply) and other_ply ~= ply and other_ply:Alive()
					and MODE.SurgeonWantsSharpCut(ply, ply:GetActiveWeapon()) then
					MODE.StartSurgeonArteryCut(ply, other_ply)
				end
			end
		elseif ply.Ability_SurgeonArteryCut then
			MODE.StopSurgeonArteryCut(ply)
		end
	else
		MODE.StopSurgeonArteryCut(ply)
	end
end)

hook.Add("PlayerSpawn", "HMCD_Donate", function(ply)
	timer.Simple(0, function()
		if not IsValid(ply) or not ply:Alive() then return end

		MODE.StopSurgeonArteryCut(ply)

		if MODE.CanBeSurgeon(ply) then
			ply.Profession = "surgeon"
		end

		MODE.SurgeonGiveLoadout(ply)

		if not ply.isGunner then
			MODE.ClearMentPerks(ply)
		end
	end)
end)

hook.Add("PlayerDisconnected", "HMCD_Donate", function(ply)
	MODE.ClearMentPerks(ply)
end)