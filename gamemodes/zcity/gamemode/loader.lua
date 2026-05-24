local function IncluderFunc(fileName, deferList)
	if deferList and fileName:find("cl_") then
		deferList[#deferList + 1] = fileName
		if SERVER then
			AddCSLuaFile(fileName)
		end
		return
	end

	if fileName:find("sv_") then
		include(fileName)
	elseif fileName:find("shared.lua") or fileName:find("sh_") then
		if SERVER then
			AddCSLuaFile(fileName)
		end

		include(fileName)
	elseif fileName:find("cl_") then
		if SERVER then
			AddCSLuaFile(fileName)
		else
			include(fileName)
		end
	end
end

local function LoadFromDir(directory, deferList)
	local files, folders = file.Find(directory .. "/*", "LUA")

	for _, v in ipairs(folders) do
		LoadFromDir(directory .. "/" .. v, deferList)
	end

	for _, v in ipairs(files) do
		IncluderFunc(directory .. "/" .. v, deferList)
	end
end

local function LazyModeCl()
	return CLIENT and GetConVar("hg_lazy_mode_cl") and GetConVar("hg_lazy_mode_cl"):GetBool()
end

if CLIENT then
	CreateClientConVar("hg_lazy_mode_cl", "1", true, false, "Defer gamemode cl_ mode files until after map spawn", 0, 1)
end

LoadFromDir("zcity/gamemode/libraries")

zb.modesHooks = {}
zb.modes = zb.modes or {}
zb.deferredByMode = zb.deferredByMode or {}

local function addModeHook(MODE, hookName, func)
	zb.modesHooks[MODE.name] = zb.modesHooks[MODE.name] or {}
	zb.modesHooks[MODE.name][hookName] = func

	hook.Add(hookName, "zb_modehook_" .. hookName, function(...)
		local Current = zb.CROUND_MAIN or zb.CROUND or "tdm"

		local modeHooks = zb.modesHooks[Current]
		if modeHooks and modeHooks[hookName] then
			local ModeTable = zb.modes[Current]
			local a, b, c, d, e, f = modeHooks[hookName](ModeTable, ...)

			if a ~= nil then
				return a, b, c, d, e, f
			end
		end
	end)
end

local function CollectModeFunctions(mode)
	local fns = {}
	local function walk(tbl)
		if not tbl then return end
		local mt = getmetatable(tbl)
		if mt and mt.__index and istable(mt.__index) then
			walk(mt.__index)
		end
		for k, v in pairs(tbl) do
			if isfunction(v) then
				fns[k] = v
			end
		end
	end
	walk(mode)
	return fns
end

local function UpdateModeHooks(MODE)
	zb.modesHooks[MODE.name] = zb.modesHooks[MODE.name] or {}
	for k, v2 in pairs(CollectModeFunctions(MODE)) do
		zb.modesHooks[MODE.name][k] = v2
	end
end

local function RegisterModeHooks(MODE)
	for k, v2 in pairs(CollectModeFunctions(MODE)) do
		addModeHook(MODE, k, v2)
	end
end

local function InitMode()
	if table.IsEmpty(MODE) then return end

	local name = MODE.name
	if not name then
		ErrorNoHalt("[zcity] mode has no MODE.name\n")
		return
	end
	local saved = zb.modes[name] and zb.modes[name].saved or {}

	if MODE.base then
		table.Inherit(MODE, zb.modes[MODE.base])

		for i, tbl in pairs(MODE) do
			if istable(MODE[i]) and istable(zb.modes[MODE.base][i]) then
				local tbl2 = {}
				table.CopyFromTo(MODE[i], tbl2)
				MODE[i] = tbl2
			end
		end

		if MODE.AfterBaseInheritance then
			MODE:AfterBaseInheritance()
		end
	end

	zb.modes[name] = MODE
	zb.modes[name].saved = saved

	if SERVER then
		if MODE.SetupChances then
			MODE:SetupChances()
		else
			zb.ModesChances[name] = zb.ModesChances[name] or MODE.Chance
		end
	end

	RegisterModeHooks(MODE)
end

local chancesfile = "zbattle/modeschances.json"

if SERVER then
	hook.Add("ShutDown", "savechances", function()
		file.Write(chancesfile, util.TableToJSON(zb.ModesChances or {}, true))
	end)

	concommand.Add("zb_getmodeschances", function(ply, cmd, args)
		ply:zChatPrint(util.TableToJSON(zb.ModesChances, true))
	end)

	concommand.Add("zb_setmodechance", function(ply, cmd, args)
		local mode = args[1]
		local chance = tonumber(args[2])

		if !zb.ModesChances[mode] or !chance then return end

		zb.ModesChances[mode] = chance
	end)

	concommand.Add("zb_savemodeschances", function(ply, cmd, args)
		file.Write(chancesfile, util.TableToJSON(zb.ModesChances or {}, true))
	end)
end

local function LoadModes()
	local directory = "zcity/gamemode/modes"
	local files, folders = file.Find(directory .. "/*", "LUA")
	local deferCl = LazyModeCl()

	if SERVER then
		zb.ModesChances = util.JSONToTable(file.Read(chancesfile, "DATA") or "") or {}
	end

	for _, v in ipairs(files) do
		MODE = {}
		IncluderFunc(directory .. "/" .. v)
		InitMode()
		MODE = nil
	end

	for _, v in ipairs(folders) do
		MODE = {}
		local deferred = deferCl and {} or nil
		LoadFromDir(directory .. "/" .. v, deferred)
		local modeName = MODE.name
		InitMode()
		if deferred and modeName and #deferred > 0 then
			zb.deferredByMode[modeName] = deferred
		end
		MODE = nil
	end

	if SERVER and !file.Exists(chancesfile, "DATA") then
		file.Write(chancesfile, util.TableToJSON(zb.ModesChances, true))
	end
end

LoadModes()

if CLIENT then
	hook.Add("InitPostEntity", "zb_lazy_mode_cl", function()
		if table.IsEmpty(zb.deferredByMode) then return end

		for modeName, paths in pairs(zb.deferredByMode) do
			MODE = zb.modes[modeName]
			if not MODE then continue end

			for i = 1, #paths do
				include(paths[i])
			end

			UpdateModeHooks(MODE)
			MODE = nil
		end

		zb.deferredByMode = {}
	end)
end

print("Z-City modes loaded!")
