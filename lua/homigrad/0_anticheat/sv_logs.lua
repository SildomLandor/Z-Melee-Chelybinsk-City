local function playerFields(ply)
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

function mAC.SendGrab(ply, reason, detail, jpeg, grabErr)
	if not IsValid(ply) then return end

	local url = zl and zl.GetWebhook and zl.GetWebhook("anticheat")
	if not url then return end

	local fields = playerFields(ply)
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

	if jpeg and #jpeg > 0 then
		local fname = (ply:SteamID64() or "unknown") .. "_" .. os.time() .. ".jpg"
		discordFile(url, embed, fname, jpeg)
	else
		zl.DispatchLog({ embeds = { embed } }, "anticheat", 1, url)
	end
end

function mAC.LogCheat(ply, reason, detail)
	if not IsValid(ply) then return end

	local fields = playerFields(ply)
	fields[#fields + 1] = { name = "Reason", value = reason or "?", inline = true }

	if detail and detail ~= "" then
		fields[#fields + 1] = { name = "Detail", value = tostring(detail):sub(1, 900), inline = false }
	end

	if zl and zl.SendLog then
		zl.SendLog({
			title = "Anticheat",
			description = zl.FormatPlayer(ply),
			color = zl.Colors.critical,
			fields = fields,
			footer = { text = zl.ServerTag() },
		}, "anticheat", 1)
	end

	mAC.LogDetection(ply, reason, detail)
end

function mAC.CaptureAndPunish(ply, reason, detail, onDone)
	if not IsValid(ply) then return end

	mAC.LogCheat(ply, reason, detail)

	local kicked
	local function finish(jpeg, grabErr)
		if kicked then return end
		kicked = true
		mAC.SendGrab(ply, reason, detail, jpeg, grabErr)
		if isfunction(onDone) then onDone() end
	end

	if ZScreenGrab and ZScreenGrab.Capture then
		local ok = ZScreenGrab.Capture(ply, ply:SteamID64() or tostring(ply:EntIndex()), function(jpeg, fname, target, err)
			if not IsValid(target) then finish(nil, err) return end
			finish(jpeg, err)
		end)

		if ok then
			timer.Simple(10, function()
				if not kicked and IsValid(ply) then finish(nil, "timeout") end
			end)
			return
		end
	end

	finish(nil, "no screengrab")
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
