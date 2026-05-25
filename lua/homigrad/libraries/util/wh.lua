hg = hg or {}

local WH = {}
hg.Whitelist = WH

WH.Enabled = false

WH.SteamIDs = {
	["STEAM_0:0:162799155"] = true, -- informal
	["STEAM_0:1:628835900"] = true, -- bombino
}

function WH.Allows(ply)
	if not WH.Enabled then return true end
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	return WH.SteamIDs[ply:SteamID()] == true
end

function WH.AllowsSteamID(steamID)
	if not WH.Enabled then return true end
	return WH.SteamIDs[steamID] == true
end

if SERVER then
	hook.Add("CheckPassword", "hg_whitelist", function(steamid64)
		if not WH.Enabled then return end

		local sid = util.SteamIDFrom64(steamid64)
		if WH.SteamIDs[sid] then return end

		return false, "эй ты не туда попал парень"
	end)
end
