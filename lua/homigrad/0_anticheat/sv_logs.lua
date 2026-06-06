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

function mAC.ZLStatus()
	local url = mAC.cfg and mAC.cfg.webhook or ""
	local reg = zl and zl.GetWebhook and zl.GetWebhook("anticheat")

	return {
		zl = zl ~= nil,
		enabled = zl and zl.Enabled or false,
		ready = mAC._logsReady or false,
		webhookCfg = url ~= "",
		webhookReg = reg ~= nil and reg ~= "",
		queue = zl and zl.GetQueueSize and zl.GetQueueSize() or 0,
	}
end

local function zlDiag()
	local st = mAC.ZLStatus()
	local lines = {
		"zl=" .. tostring(st.zl),
		"enabled=" .. tostring(st.enabled),
		"ready=" .. tostring(st.ready),
		"webhook=" .. tostring(st.webhookReg),
		"queue=" .. tostring(st.queue),
	}

	if not st.zl then
		lines[#lines + 1] = "даун"
	elseif not st.enabled then
		lines[#lines + 1] = "zl.Enabled=false в zetalogs/sv_config.lua"
	elseif not st.webhookReg then
		lines[#lines + 1] = "webhook не зарегистрирован"
	elseif st.zl and st.webhookReg then
		lines[#lines + 1] = "discord.com:443"
	end

	return table.concat(lines, " | ")
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
		success = function(code)
			mAC.Debug("discord file ok http", code)
		end,
		failed = function(err)
			mAC.Debug("discord file fail", err)
		end,
	})

	return true
end

local function directDiscord(log, onDone)
	local url = mAC.cfg and mAC.cfg.webhook
	if not url or url == "" then
		if onDone then onDone(false, "no webhook url") end
		return false
	end

	local payload
	if zl and zl.BuildPayload and zl.GetMeta then
		payload = zl.BuildPayload(log, zl.GetMeta())
	elseif zl and zl.BuildEmbed then
		payload = { embeds = { zl.BuildEmbed(log) } }
	else
		payload = { embeds = { { title = log.title or "mAC", description = log.description or "?" } } }
	end

	HTTP({
		url = url,
		method = "POST",
		type = "application/json",
		body = util.TableToJSON(payload),
		success = function(code)
			mAC.Debug("direct discord ok http", code)
			if onDone then onDone(true, code) end
		end,
		failed = function(err)
			mAC.Debug("direct discord fail", err)
			if onDone then onDone(false, err) end
		end,
	})

	return true
end

function mAC.SendGrab(ply, reason, detail, jpeg, grabErr, code, snap)
	local url = zl and zl.GetWebhook and zl.GetWebhook("anticheat") or mAC.cfg.webhook
	if not url or url == "" then
		mAC.Debug("SendGrab: no webhook")
		return
	end

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

	local embed = zl and zl.BuildEmbed and zl.BuildEmbed({
		title = "Anticheat · screenshot",
		color = zl.Colors.critical,
		fields = fields,
		footer = { text = zl.ServerTag() },
	}) or { title = "Anticheat · screenshot", fields = fields }

	local fnameBase = (snap and snap.s64) or (IsValid(ply) and ply:SteamID64()) or "unknown"

	if jpeg and #jpeg > 0 then
		discordFile(url, embed, fnameBase .. "_" .. os.time() .. ".jpg", jpeg)
	elseif zl and zl.DispatchLog then
		zl.DispatchLog({ embeds = { embed } }, "anticheat", 1, url)
	else
		directDiscord({ title = embed.title, fields = fields })
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

	local log = {
		title = "Anticheat · ban",
		description = snap and string.format("%s (%s | %s)", snap.nick or "?", snap.sid or "?", snap.ip or "?") or "?",
		color = zl and zl.Colors and zl.Colors.critical or 16711680,
		fields = fields,
		footer = { text = zl and zl.ServerTag and zl.ServerTag() or game.GetMap() },
	}

	local sent = zl and zl.SendLog and zl.SendLog(log, "anticheat", 1)
	if sent == false or sent == nil then
		mAC.Debug("ZL SendLog miss, direct fallback")
		directDiscord(log)
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
	if mAC._logsReady then return true end

	local url = mAC.cfg and mAC.cfg.webhook
	if not url or url == "" then
		mAC.Debug("logs boot: webhook url empty in sv_config")
		return false
	end

	if not zl then
		mAC.Debug("logs boot: zl nil — addon zetalogs не загружен")
		return false
	end

	if not zl.RegisterWebhook then
		mAC.Debug("logs boot: zl.RegisterWebhook missing")
		return false
	end

	if not zl.RegisterWebhook("anticheat", url) then
		mAC.Debug("logs boot: RegisterWebhook rejected url")
		return false
	end

	mAC._logsReady = true
	mAC.Debug("logs boot: anticheat webhook ok")
	return true
end

hook.Add("ZetaLogsLoaded", "mAC_logs", boot)

hook.Add("InitPostEntity", "mAC_logs_boot", function()
	timer.Simple(0, boot)
	timer.Simple(2, boot)
	timer.Simple(5, function()
		boot()
		print("[mAC] zetalogs: " .. zlDiag())
	end)
end)

timer.Simple(0, boot)

hook.Add("ZetaLogsSent", "mAC_zl_dbg", function(target, level, code)
	mAC.Debug("ZL sent", target or "?", "lvl", level, "http", code)
end)

hook.Add("ZetaLogsSkipped", "mAC_zl_dbg", function(_, target, level, reason)
	mAC.Debug("ZL skipped", target or "?", "lvl", level, reason or "?")
end)

concommand.Add("mac_zltest", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	print("[mAC] zetalogs diag: " .. zlDiag())
	boot()

	local log = {
		title = "mAC test",
		description = "webhook test from " .. (zl and zl.ServerTag and zl.ServerTag() or game.GetMap()),
		color = zl and zl.Colors and zl.Colors.medium or 3447003,
	}

	if zl and zl.SendLog then
		local ok = zl.SendLog(log, "anticheat", 1)
		print("[mAC] zl.SendLog -> " .. tostring(ok))
	end

	directDiscord(log, function(ok, info)
		print("[mAC] direct HTTP -> " .. tostring(ok) .. " (" .. tostring(info) .. ")")
		if not ok then
			print("[mAC] хост не пускает HTTP к discord — включи outbound 443 или спроси поддержку хоста")
		end
	end)
end)
