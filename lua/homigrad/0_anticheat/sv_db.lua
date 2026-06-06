mAC.dbReady = false
mAC.fileDB = mAC.fileDB or { players = {}, bans = {}, cookies = {}, ips = {} }

local dataPath = "mac/store.json"

local function loadFileDB()
	if not file.Exists(dataPath, "DATA") then return end
	local raw = file.Read(dataPath, "DATA")
	if not raw or raw == "" then return end
	local t = util.JSONToTable(raw)
	if istable(t) then mAC.fileDB = t end
end

local function saveFileDB()
	file.CreateDir("mac")
	file.Write(dataPath, util.TableToJSON(mAC.fileDB, true) or "{}")
end

function mAC.DBEscape(v)
	if mysql and mysql.Escape then return mysql:Escape(tostring(v)) end
	return sql.SQLStr(tostring(v), true)
end

function mAC.DBQuery(sqlText, onDone)
	if not mAC.dbReady or not mysql then return false end
	local q = mysql:RawQuery(sqlText)
	if onDone then q.callback = onDone end
	q:Execute()
	return true
end

local function createTables()
	local q

	q = mysql:Create("mac_players")
		q:Create("steamid64", "VARCHAR(22) NOT NULL")
		q:Create("name", "VARCHAR(64) NOT NULL")
		q:Create("cookie", "VARCHAR(64) NOT NULL DEFAULT ''")
		q:Create("first_seen", "INT(11) NOT NULL DEFAULT 0")
		q:Create("last_seen", "INT(11) NOT NULL DEFAULT 0")
		q:Create("last_ip", "VARCHAR(45) NOT NULL DEFAULT ''")
		q:Create("banned", "TINYINT(1) NOT NULL DEFAULT 0")
		q:Create("ban_reason", "VARCHAR(128) NOT NULL DEFAULT ''")
		q:PrimaryKey("steamid64")
	q:Execute()

	q = mysql:Create("mac_ips")
		q:Create("rowid", "VARCHAR(72) NOT NULL")
		q:Create("ip", "VARCHAR(45) NOT NULL")
		q:Create("steamid64", "VARCHAR(22) NOT NULL")
		q:Create("last_seen", "INT(11) NOT NULL DEFAULT 0")
		q:Create("hits", "INT(11) NOT NULL DEFAULT 1")
		q:PrimaryKey("rowid")
	q:Execute()

	q = mysql:Create("mac_cookies")
		q:Create("rowid", "VARCHAR(90) NOT NULL")
		q:Create("cookie", "VARCHAR(64) NOT NULL")
		q:Create("steamid64", "VARCHAR(22) NOT NULL")
		q:Create("created", "INT(11) NOT NULL DEFAULT 0")
		q:PrimaryKey("rowid")
	q:Execute()

	q = mysql:Create("mac_log")
		q:Create("id", "INT(11) NOT NULL AUTO_INCREMENT")
		q:Create("steamid64", "VARCHAR(22) NOT NULL")
		q:Create("ip", "VARCHAR(45) NOT NULL DEFAULT ''")
		q:Create("reason", "VARCHAR(128) NOT NULL")
		q:Create("detail", "TEXT")
		q:Create("ts", "INT(11) NOT NULL DEFAULT 0")
		q:PrimaryKey("id")
	q:Execute()
end

function mAC.LogDetection(ply, reason, detail)
	local s64 = mAC.SteamID64(ply) or "0"
	local ip = mAC.IP(ply) or ""
	local line = string.format("[%s] %s %s %s | %s\n", os.date("%Y-%m-%d %H:%M:%S"), s64, IsValid(ply) and ply:Nick() or "?", ip, reason)
	if detail and detail ~= "" then line = line:sub(1, -2) .. " | " .. detail .. "\n" end
	file.CreateDir("mac")
	file.Append(mAC.cfg.logFile, line)

	if mAC.dbReady then
		local q = mysql:Insert("mac_log")
			q:Insert("steamid64", s64)
			q:Insert("ip", ip)
			q:Insert("reason", reason)
			q:Insert("detail", detail or "")
			q:Insert("ts", os.time())
		q:Execute()
	end
end

function mAC.UpsertPlayer(ply, cookie, ip)
	local s64 = mAC.SteamID64(ply)
	if not s64 then return end
	local now = os.time()
	local name = ply:Nick()

	if mAC.dbReady then
		local q = mysql:Select("mac_players")
			q:Where("steamid64", s64)
			q:Callback(function(res)
				if not IsValid(ply) then return end
				if istable(res) and #res > 0 then
					local u = mysql:Update("mac_players")
						u:Update("name", name)
						u:Update("last_seen", now)
						u:Update("last_ip", ip or "")
						if cookie and cookie ~= "" then u:Update("cookie", cookie) end
						u:Where("steamid64", s64)
					u:Execute()
				else
					local ins = mysql:Insert("mac_players")
						ins:Insert("steamid64", s64)
						ins:Insert("name", name)
						ins:Insert("cookie", cookie or "")
						ins:Insert("first_seen", now)
						ins:Insert("last_seen", now)
						ins:Insert("last_ip", ip or "")
					ins:Execute()
				end
			end)
		q:Execute()
	else
		local row = mAC.fileDB.players[s64] or {}
		row.name = name
		row.first_seen = row.first_seen or now
		row.last_seen = now
		row.last_ip = ip or row.last_ip or ""
		if cookie and cookie ~= "" then row.cookie = cookie end
		mAC.fileDB.players[s64] = row
		saveFileDB()
	end
end

function mAC.LinkIP(s64, ip)
	if not s64 or not ip or ip == "" then return end
	local now = os.time()
	local rowid = ip .. ":" .. s64

	if mAC.dbReady then
		local q = mysql:Select("mac_ips")
			q:Where("rowid", rowid)
			q:Callback(function(res)
				if istable(res) and #res > 0 then
					local u = mysql:Update("mac_ips")
						u:Update("last_seen", now)
						u:Update("hits", tonumber(res[1].hits or 0) + 1)
						u:Where("rowid", rowid)
					u:Execute()
				else
					local ins = mysql:Insert("mac_ips")
						ins:Insert("rowid", rowid)
						ins:Insert("ip", ip)
						ins:Insert("steamid64", s64)
						ins:Insert("last_seen", now)
						ins:Insert("hits", 1)
					ins:Execute()
				end
			end)
		q:Execute()
	else
		mAC.fileDB.ips[ip] = mAC.fileDB.ips[ip] or {}
		local row = mAC.fileDB.ips[ip][s64] or { hits = 0 }
		row.last_seen = now
		row.hits = (row.hits or 0) + 1
		mAC.fileDB.ips[ip][s64] = row
		saveFileDB()
	end
end

function mAC.LinkCookie(cookie, s64)
	if not cookie or cookie == "" or not s64 then return end
	local now = os.time()
	local rowid = cookie .. ":" .. s64

	if mAC.dbReady then
		local q = mysql:Select("mac_cookies")
			q:Where("rowid", rowid)
			q:Callback(function(res)
				if istable(res) and #res > 0 then return end
				local ins = mysql:Insert("mac_cookies")
					ins:Insert("rowid", rowid)
					ins:Insert("cookie", cookie)
					ins:Insert("steamid64", s64)
					ins:Insert("created", now)
				ins:Execute()
			end)
		q:Execute()

		local u = mysql:Update("mac_players")
			u:Update("cookie", cookie)
			u:Where("steamid64", s64)
		u:Execute()
	else
		mAC.fileDB.cookies[cookie] = mAC.fileDB.cookies[cookie] or {}
		mAC.fileDB.cookies[cookie][s64] = now
		if mAC.fileDB.players[s64] then mAC.fileDB.players[s64].cookie = cookie end
		saveFileDB()
	end
end

function mAC.SetBanned(s64, reason, ip)
	if not s64 then return end
	reason = reason or "ban"

	if mAC.dbReady then
		local q = mysql:Select("mac_players")
			q:Where("steamid64", s64)
			q:Callback(function(res)
				if istable(res) and #res > 0 then
					local u = mysql:Update("mac_players")
						u:Update("banned", 1)
						u:Update("ban_reason", reason)
						if ip and ip ~= "" then u:Update("last_ip", ip) end
						u:Where("steamid64", s64)
					u:Execute()
				else
					local ins = mysql:Insert("mac_players")
						ins:Insert("steamid64", s64)
						ins:Insert("name", "?")
						ins:Insert("cookie", "")
						ins:Insert("first_seen", os.time())
						ins:Insert("last_seen", os.time())
						ins:Insert("last_ip", ip or "")
						ins:Insert("banned", 1)
						ins:Insert("ban_reason", reason)
					ins:Execute()
				end
			end)
		q:Execute()
	else
		mAC.fileDB.bans[s64] = { reason = reason, ip = ip or "", ts = os.time() }
		saveFileDB()
	end
end

function mAC.ULibBanned(s64)
	if not s64 or not ULib or not ULib.bans then return false end
	local sid = util.SteamIDFrom64(s64)
	return sid and ULib.bans[sid] ~= nil or false
end

function mAC.Unban(s64)
	if not s64 then return end

	if mAC.dbReady then
		local u = mysql:Update("mac_players")
			u:Update("banned", 0)
			u:Update("ban_reason", "")
			u:Where("steamid64", s64)
		u:Execute()
	else
		mAC.fileDB.bans[s64] = nil
		saveFileDB()
	end

	if ULib and ULib.unban then
		local sid = util.SteamIDFrom64(s64)
		if sid then ULib.unban(sid) end
	end
end

function mAC.IsBanned(s64, ip, cookie, cb)
	if not cb then return end

	local function finish(hit, why, own)
		if hit and own and mAC.FalsePositiveReason(why) then
			mAC.Unban(s64)
			cb(false)
			return
		end
		if hit and own and not mAC.ULibBanned(s64) then
			mAC.Unban(s64)
			cb(false)
			return
		end
		cb(hit, why, own)
	end

	if not mAC.dbReady then
		if s64 and mAC.fileDB.bans[s64] then
			finish(true, mAC.fileDB.bans[s64].reason or "ban", true)
			return
		end
		if cookie and cookie ~= "" and mAC.fileDB.cookies[cookie] then
			for sid in pairs(mAC.fileDB.cookies[cookie]) do
				if sid ~= s64 and mAC.fileDB.bans[sid] then
					finish(true, "cookie", false)
					return
				end
			end
		end
		if ip and ip ~= "" and mAC.fileDB.ips[ip] then
			for sid in pairs(mAC.fileDB.ips[ip]) do
				if sid ~= s64 and mAC.fileDB.bans[sid] then
					finish(true, "ip", false)
					return
				end
			end
		end
		cb(false)
		return
	end

	local function playerBanned(sid, onResult)
		if not sid then onResult(false) return end
		local q = mysql:Select("mac_players")
			q:Where("steamid64", sid)
			q:Callback(function(res)
				if istable(res) and #res > 0 and tonumber(res[1].banned) == 1 then
					onResult(true, res[1].ban_reason or "ban")
				else
					onResult(false)
				end
			end)
		q:Execute()
	end

	playerBanned(s64, function(hit, why)
		if hit then finish(true, why, true) return end

		if cookie and cookie ~= "" then
			local q = mysql:Select("mac_cookies")
				q:Where("cookie", cookie)
				q:Callback(function(res)
					if not istable(res) or #res <= 0 then
						if ip and ip ~= "" then
							local q2 = mysql:Select("mac_ips")
								q2:Where("ip", ip)
								q2:Callback(function(r2)
									if not istable(r2) then finish(false) return end
									local left = #r2
									if left <= 0 then finish(false) return end
									for i = 1, #r2 do
										local sid = r2[i].steamid64
										if sid == s64 then
											left = left - 1
											if left <= 0 then finish(false) end
											continue
										end
										playerBanned(sid, function(h, w)
											left = left - 1
											if h then finish(true, "ip:" .. w, false) return end
											if left <= 0 then finish(false) end
										end)
									end
								end)
							q2:Execute()
						else
							finish(false)
						end
						return
					end

					local left = 0
					for i = 1, #res do if res[i].steamid64 ~= s64 then left = left + 1 end end
					if left <= 0 then finish(false) return end

					for i = 1, #res do
						local sid = res[i].steamid64
						if sid == s64 then continue end
						playerBanned(sid, function(h, w)
							left = left - 1
							if h then finish(true, "cookie:" .. w, false) return end
							if left <= 0 then finish(false) end
						end)
					end
				end)
			q:Execute()
			return
		end

		if ip and ip ~= "" then
			local q = mysql:Select("mac_ips")
				q:Where("ip", ip)
				q:Callback(function(res)
					if not istable(res) or #res <= 0 then finish(false) return end
					local left = 0
					for i = 1, #res do if res[i].steamid64 ~= s64 then left = left + 1 end end
					if left <= 0 then finish(false) return end
					for i = 1, #res do
						local sid = res[i].steamid64
						if sid == s64 then continue end
						playerBanned(sid, function(h, w)
							left = left - 1
							if h then finish(true, "ip:" .. w, false) return end
							if left <= 0 then finish(false) end
						end)
					end
				end)
			q:Execute()
			return
		end

		finish(false)
	end)
end

function mAC.CookieAlts(cookie, s64, cb)
	if not cookie or cookie == "" then cb({}) return end

	if not mAC.dbReady then
		local out = {}
		for sid in pairs(mAC.fileDB.cookies[cookie] or {}) do
			if sid ~= s64 then out[#out + 1] = sid end
		end
		cb(out)
		return
	end

	local q = mysql:Select("mac_cookies")
		q:Where("cookie", cookie)
		q:Callback(function(res)
			local out = {}
			if istable(res) then
				for i = 1, #res do
					local sid = res[i].steamid64
					if sid ~= s64 then out[#out + 1] = sid end
				end
			end
			cb(out)
		end)
	q:Execute()
end

loadFileDB()

if mAC.FalsePositiveReason then
	local dirty
	for s64, row in pairs(mAC.fileDB.bans) do
		if mAC.FalsePositiveReason(row.reason) then
			mAC.fileDB.bans[s64] = nil
			dirty = true
		end
	end
	if dirty then saveFileDB() end
end

hook.Add("InitPostEntity", "mAC_db_connect", function()
	if not mAC.db or not mysql then return end

	local cfg = mAC.db
	mysql:SetModule(cfg.module or "sqlite")

	if cfg.module == "sqlite" then
		mysql:Connect()
	else
		mysql:Connect(cfg.host, cfg.username, cfg.password, cfg.database, cfg.port or 3306)
	end
end)

hook.Add("DatabaseConnected", "mAC_db_tables", function()
	mAC.dbReady = true
	createTables()

	local cfg = mAC.db or {}
	local mod = cfg.module or mysql.module or "sqlite"
	local where = mod == "sqlite" and "sqlite" or string.format("%s:%s/%s", cfg.host or "?", cfg.port or 3306, cfg.database or "?")
	print("[mAC] DB connected (" .. mod .. " @ " .. where .. ")")

	local q = mysql:Select("mac_players")
		q:Where("banned", 1)
		q:Callback(function(res)
			if not istable(res) then return end
			for i = 1, #res do
				local row = res[i]
				if mAC.FalsePositiveReason(row.ban_reason) then
					mAC.Unban(row.steamid64)
				end
			end
		end)
	q:Execute()
end)

hook.Add("DatabaseConnected", "mAC_db_think", function()
	timer.Create("mAC_mysql", 0.5, 0, function()
		if mysql and mysql.Think then mysql:Think() end
	end)
end)
