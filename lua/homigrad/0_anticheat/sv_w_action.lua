mAC.session = mAC.session or {}

local function banPlayer(ply, pubMsg, secretReason)
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply)
	if s64 then mAC.SetBanned(s64, secretReason or pubMsg, ip) end

	if ULib and ULib.ban and s64 then
		ULib.ban(ply, mAC.cfg.banTime or 0, pubMsg)
		return
	end

	ply:Kick(pubMsg)
end

function mAC.KickBanned(ply, why)
	if not IsValid(ply) or ply.mAC_done then return end
	ply.mAC_done = true
	ply:Kick(mAC.PublicBanMsg(mAC.BanCode(why)))
end

function mAC.Punish(ply, reason, detail)
	if not IsValid(ply) or ply.mAC_done then return end
	ply.mAC_done = true

	local code = mAC.BanCode(reason)
	local pub = mAC.PublicBanMsg(code)
	local secret = mAC.SecretBanNote(reason, detail, code)
	local snap = mAC.PlayerSnap(ply)

	if mAC.LogCheat then
		mAC.LogCheat(ply, reason, detail, code, snap)
	end

	if mAC.GrabAsync then
		mAC.GrabAsync(ply, snap, reason, detail, code)
	end

	banPlayer(ply, pub, secret)
end

function mAC.CheckBypass(ply, cookie, cb)
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply)
	if not s64 then cb(false) return end

	mAC.IsBanned(s64, ip, cookie, function(banned, why, own)
		if banned then cb(true, why, own) return end
		if not cookie or cookie == "" then cb(false) return end

		mAC.CookieAlts(cookie, s64, function(alts)
			if #alts <= 0 then cb(false) return end

			if not mAC.dbReady then
				for i = 1, #alts do
					if mAC.fileDB.bans[alts[i]] then
						cb(true, "cookie_alt", false)
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
						 cb(true, "cookie_alt", false)
						elseif left <= 0 and not flagged then
						 cb(false)
						end
					end)
				q:Execute()
			end
		end)
	end)
end

concommand.Add("mac_unban", function(ply, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	local id = args[1]
	if not id or id == "" then return end

	local s64 = id:match("^7656%d+$") and id or util.SteamIDTo64(id)
	if not s64 or s64 == "0" then return end

	mAC.Unban(s64)
	print("[mAC] unbanned " .. s64)
end)
