local function playerFields(ply, snap)
	if snap then
		return {
			{ name = "Player", value = snap.nick or "?", inline = true },
			{ name = "SteamID", value = snap.sid or "?", inline = true },
			{ name = "SteamID64", value = snap.s64 or "?", inline = true },
			{ name = "IP", value = snap.ip or "?", inline = true },
		}
	end

	if not IsValid(ply) then
		return {
			{ name = "Player", value = "invalid", inline = true },
		}
	end

	local ip = mAC.IP(ply) or "?"
	return {
		{ name = "Player", value = ply:Nick(), inline = true },
		{ name = "SteamID", value = ply:SteamID(), inline = true },
		{ name = "SteamID64", value = ply:SteamID64() or "?", inline = true },
		{ name = "IP", value = ip, inline = true },
	}
end

local function discordFile(url, embed, filename, bin)
	if not url or not bin or #bin <= 0 then return false end

	local boundary = "MAC" .. tostring(math.floor(SysTime() * 1000))
	local payload = util.TableToJSON({ embeds = { embed } }) or "{}"
	local head = table.concat({
		"--" .. boundary .. "\r\n",
		"Content-Disposition: form-data; name=\"payload_json\"\r\n\r\n",
		payload, "\r\n",
		"--" .. boundary .. "\r\n",
		"Content-Disposition: form-data; name=\"files[0]\"; filename=\"", filename, "\"\r\n",
		"Content-Type: image/jpeg\r\n\r\n",
	}, "")

	HTTP({
		url = url,
		method = "POST",
		headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
			["Content-Length"] = tostring(#head + #bin + #("\r\n--" .. boundary .. "--\r\n")),
		},
		body = head .. bin .. "\r\n--" .. boundary .. "--\r\n",
	})

	return true
end

function mAC.SendGrab(ply, reason, detail, jpeg, grabErr, code, snap)
	local url = zl and zl.GetWebhook and zl.GetWebhook("anticheat")
	if not url then return end

	snap = snap or (IsValid(ply) and mAC.PlayerSnap(ply))

	local fields = playerFields(ply, snap)
	fields[#fields + 1] = { name = "Код", value = tostring(code or "?"), inline = true }
	fields[#fields + 1] = { name = "Reason", value = reason or "?", inline = true }

	if detail and detail ~= "" then
		fields[#fields + 1] = { name = "Detail", value = tostring(detail):sub(1, 900), inline = false }
	end

	if grabErr then
		fields[#fields + 1] = { name = "Screengrab", value = grabErr, inline = false }
	end

	local embed = zl.BuildEmbed({
		title = "Anticheat · screenshot",
		color = zl.Colors.critical,
		fields = fields,
		footer = { text = zl.ServerTag() },
	})

	local fnameBase = (snap and snap.s64) or (IsValid(ply) and ply:SteamID64()) or "unknown"

	if jpeg and #jpeg > 0 then
		discordFile(url, embed, fnameBase .. "_" .. os.time() .. ".jpg", jpeg)
	else
		zl.DispatchLog({ embeds = { embed } }, "anticheat", 1, url)
	end
end

function mAC.LogCheat(ply, reason, detail, code, snap)
	snap = snap or (IsValid(ply) and mAC.PlayerSnap(ply))

	local fields = playerFields(ply, snap)
	fields[#fields + 1] = { name = "Код", value = tostring(code or "?"), inline = true }
	fields[#fields + 1] = { name = "Reason", value = reason or "?", inline = true }

	if detail and detail ~= "" then
		fields[#fields + 1] = { name = "Detail", value = tostring(detail):sub(1, 900), inline = false }
	end

	if zl and zl.SendLog then
		local desc = snap and string.format("%s (%s | %s)", snap.nick or "?", snap.sid or "?", snap.ip or "?") or "?"
		zl.SendLog({
			title = "Anticheat · ban",
			description = desc,
			color = zl.Colors.critical,
			fields = fields,
			footer = { text = zl.ServerTag() },
		}, "anticheat", 1)
	end

	if IsValid(ply) then
		mAC.LogDetection(ply, mAC.SecretBanNote(reason, detail, code))
	else
		file.CreateDir("mac")
		file.Append(mAC.cfg.logFile, string.format("[%s] %s %s\n", os.date("%Y-%m-%d %H:%M:%S"), snap and snap.s64 or "?", mAC.SecretBanNote(reason, detail, code)))
	end
end

function mAC.GrabAsync(ply, snap, reason, detail, code)
	if not IsValid(ply) or not ZScreenGrab or not ZScreenGrab.Capture then
		mAC.SendGrab(ply, reason, detail, nil, "no screengrab", code, snap)
		return
	end

	local fname = snap and snap.s64 or ply:SteamID64() or tostring(ply:EntIndex())
	local done

	ZScreenGrab.Capture(ply, fname, function(jpeg, _, target, err)
		if done then return end
		done = true
		mAC.SendGrab(target, reason, detail, jpeg, err, code, snap)
	end)

	timer.Simple(8, function()
		if done then return end
		done = true
		mAC.SendGrab(ply, reason, detail, nil, "timeout", code, snap)
	end)
end

local function boot()
	if mAC._logsReady then return end
	if not zl or not zl.RegisterWebhook then return end

	mAC._logsReady = true
	zl.RegisterWebhook("anticheat", "https://discord.com/api/webhooks/1512867508477100114/o4QW36P1MWCZfQTwkC6DnQwM3Is4QrMVYicsUGPBRYjnM7yPld3npERD-ecWihqMNC8k")
end

hook.Add("ZetaLogsLoaded", "mAC_logs", boot)

timer.Simple(0, function()
	if zl and zl.RegisterWebhook then boot() end
end)
