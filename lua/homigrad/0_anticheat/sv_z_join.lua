function mAC.OnJoin(ply)
	if not mAC.cfg.enabled then return end
	local s64 = mAC.SteamID64(ply)
	if not s64 then return end

	local ip = mAC.IP(ply) or ""
	local token = mAC.session[s64] and mAC.session[s64].token or mAC.Token(40)
	mAC.session[s64] = { token = token, ip = ip }
	ply.mAC_token = token

	mAC.Debug("join", mAC.PlayerLabel(ply), "db=" .. tostring(mAC.dbReady), "probe in", mAC.cfg.probeDelay or 10, "s")

	mAC.BuildProbe(ply)

	mAC.CheckBypass(ply, "", function(blocked, why, own)
		if not IsValid(ply) then return end
		if blocked then
			mAC.Debug("join blocked", mAC.PlayerLabel(ply), "why=", why or "?", "own=", tostring(own))
			mAC.HandleBlocked(ply, why, own, ip)
			return
		end

		mAC.Debug("join ok", mAC.PlayerLabel(ply), "cookie pending")

		mAC.UpsertPlayer(ply, token, ip)
		mAC.LinkIP(s64, ip)
		mAC.PushCookie(ply, token)

		timer.Simple(mAC.cfg.probeDelay or 10, function()
			if not IsValid(ply) or ply.mAC_done then return end
			mAC.Debug("probe send", mAC.PlayerLabel(ply), "first")
			mAC.SendProbe(ply)
		end)

		timer.Create("mAC_rp_" .. ply:EntIndex(), mAC.cfg.reprobe or 45, 0, function()
			if not IsValid(ply) or ply.mAC_done then
				timer.Remove("mAC_rp_" .. ply:EntIndex())
				return
			end
			mAC.Debug("probe send", mAC.PlayerLabel(ply), "reprobe")
			mAC.SendProbe(ply)
		end)
	end)
end

hook.Add("PlayerInitialSpawn", "mAC_join", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then mAC.OnJoin(ply) end
	end)
end)

hook.Add("PlayerAuthed", "mAC_ip", function(ply)
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply)
	if not s64 or not ip then return end
	mAC.LinkIP(s64, ip)
	mAC.UpsertPlayer(ply, ply.mAC_token or "", ip)
end)

hook.Add("PlayerDisconnected", "mAC_leave", function(ply)
	local s64 = mAC.SteamID64(ply)
	if s64 and mAC.session[s64] then
		mAC.session[s64].token = ply.mAC_token or mAC.session[s64].token
	end
	mAC.Debug("leave", mAC.PlayerLabel(ply))
	timer.Remove("mAC_rp_" .. ply:EntIndex())
end)

net.Receive("mac_c", function(_, ply)
	if not IsValid(ply) or ply.mAC_done then return end

	local cookie = net.ReadString() or ""
	local s64 = mAC.SteamID64(ply)
	local ip = mAC.IP(ply) or ""

	if cookie == "" then cookie = ply.mAC_token or "" end
	if cookie ~= "" then mAC.LinkCookie(cookie, s64) end

	mAC.Debug("cookie", mAC.PlayerLabel(ply), cookie ~= "" and "set" or "empty")

	mAC.UpsertPlayer(ply, cookie, ip)
	mAC.LinkIP(s64, ip)

	mAC.CheckBypass(ply, cookie, function(blocked, why, own)
		if not IsValid(ply) then return end
		if blocked then
			mAC.Debug("cookie blocked", mAC.PlayerLabel(ply), "why=", why or "?", "own=", tostring(own))
			mAC.HandleBlocked(ply, why, own, cookie)
		end
	end)
end)
