local function QuietGiveSWEP(ply, command, arguments)
	if not IsValid(ply) or not ply:Alive() or not arguments[1] then return end

	local swep = list.GetEntry("Weapon", arguments[1])
	if not swep then return end

	local isAdmin = ply:IsAdmin() or game.SinglePlayer()
	if (not swep.Spawnable and not isAdmin) or (swep.AdminOnly and not isAdmin) then return end
	if not gamemode.Call("PlayerGiveSWEP", ply, arguments[1], swep) then return end

	if not ply:HasWeapon(swep.ClassName) then
		Msg("Giving " .. ply:Nick() .. " a " .. swep.ClassName .. "\n")
		ply:SetSuppressPickupNotices(true)
		ply:Give(swep.ClassName)
		ply:SetSuppressPickupNotices(false)
	end

	ply:SelectWeapon(swep.ClassName)
end

concommand.Add("gm_giveswep", QuietGiveSWEP)

COMMANDS.sendtospawn = {
	function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 0 and args[1] or ply:Name()
		for i, ply2 in pairs(player.GetListByName(plya)) do
			if ply2:Alive() then
				ply2:Spawn()
				ply:ChatPrint( ply2:Name().. " | Sended to random spawn..." )
			end
		end
	end,
	0
}

COMMANDS.give = {
	function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 1 and args[1] or ply:Name()
		local wep = #args > 1 and args[2] or args[1]
		for i, ply2 in pairs(player.GetListByName(plya)) do
			if ply2:Alive() then
				ply2:SetSuppressPickupNotices(true)
				local ent = ply2:Give(wep)
				ply2:SetSuppressPickupNotices(false)
                if not IsValid(ent) then return end

                ent:Use(ply2)
				ply:ChatPrint( ply2:Name().. " | Weapon given" )
			end
		end
	end,
	0
}

COMMANDS.respawn = {
	function(ply, args)
		if not ply:IsAdmin() then return end
		local plya = #args > 0 and args[1] or ply:Name()
		for i, ply2 in pairs(player.GetListByName(plya)) do
			ply2:Spawn()
            ApplyAppearance( ply2 )
			local hands = ply2:Give("weapon_hands_sh")
			ply2:SelectWeapon(hands)

			ply:ChatPrint( ply2:Name().. " | Respawned" )
		end
	end,
	0
}