mAC.session = mAC.session or {}

local function banPlayer(ply, reason)
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply)
	if s64 then mAC.SetBanned(s64, reason, ip) end

	local msg = mAC.cfg.kickMsg or "anticheat"
	if ULib and ULib.ban and s64 then
		ULib.ban(ply, mAC.cfg.banTime or 0, reason)
		return
	end

	ply:Kick(msg)
end

function mAC.Punish(ply, reason, detail)
	if not IsValid(ply) or ply.mAC_done then return end
	ply.mAC_done = true

	if mAC.CaptureAndPunish then
		mAC.CaptureAndPunish(ply, reason, detail, function()
			if IsValid(ply) then banPlayer(ply, reason) end
		end)
		return
	end

	mAC.LogDetection(ply, reason, detail)
	banPlayer(ply, reason)
end

function mAC.CheckBypass(ply, cookie, cb)
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply)
	if not s64 then cb(false) return end

	mAC.IsBanned(s64, ip, cookie, function(banned, why)
		if banned then cb(true, why) return end
		if not cookie or cookie == "" then cb(false) return end

		mAC.CookieAlts(cookie, s64, function(alts)
			if #alts <= 0 then cb(false) return end

			if not mAC.dbReady then
				for i = 1, #alts do
					if mAC.fileDB.bans[alts[i]] then
						cb(true, "cookie_alt")
						return
					end
				end
				cb(false)
				return
			end

			local left, flagged = #alts, false
			for i = 1, #alts do
				local q = mysql:Select("mac_players")
					q:Where("steamid64", alts[i])
					q:Callback(function(res)
						left = left - 1
						if not flagged and istable(res) and #res > 0 and tonumber(res[1].banned) == 1 then
						 flagged = true
						 cb(true, "cookie_alt")
						elseif left <= 0 and not flagged then
						 cb(false)
						end
					end)
				q:Execute()
			end
		end)
	end)
end
