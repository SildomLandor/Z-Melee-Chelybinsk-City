hg = hg or {}
hg.Version = "Beta 6.0"
hg.GitHub_ReposOwner = "informal1337, Rastawontfix, Sildom_Landor"
hg.GitHub_ReposName = "Meleecity: Delicacy Reworked" 
-- А силдом гей
local print = print
local SysTime = SysTime
local string_lower = string.lower
local string_match = string.match
local table_sort = table.sort
local table_remove = table.remove
local table_insert = table.insert

local AddCSLuaFile = AddCSLuaFile
local file = file
local hook = hook
local include = include

local LUA_EXT = ".lua"
local LUA_EXT_LEN = #LUA_EXT

local SIDE_SV = 1
local SIDE_CL = 2
local SIDE_SH = 3

local PREFIX_MASK = {
    sv_ = SIDE_SV,
    cl_ = SIDE_CL,
    sh_ = SIDE_SH
}

local function GetFileSide(fileName)
    local lower = string_lower(fileName)
    local prefix = lower:sub(1, 3)
    local mask = PREFIX_MASK[prefix]
    if mask then return mask end

    local baseLen = #fileName - LUA_EXT_LEN
    if baseLen >= 3 then
        local suffix = lower:sub(baseLen - 2, baseLen)
        if suffix == "_sv" then return SIDE_SV end
        if suffix == "_cl" then return SIDE_CL end
        if suffix == "_sh" then return SIDE_SH end
    end
    return SIDE_SH
end

local function ProcessDirectoryOrdered(rootDir)
    local allFiles = {}
    local queue = { rootDir }

    while #queue > 0 do
        local currentDir = table_remove(queue, 1)
        local files, dirs = file.Find(currentDir .. "/*", "LUA")

        if files then
            table_sort(files)
            for i = 1, #files do
                local fileName = files[i]
                if fileName:sub(-LUA_EXT_LEN) == LUA_EXT then
                    table_insert(allFiles, currentDir .. "/" .. fileName)
                end
            end
        end

        if dirs then
            table_sort(dirs)
            for i = #dirs, 1, -1 do
                table_insert(queue, 1, currentDir .. "/" .. dirs[i])
            end
        end
    end

    return allFiles
end

local function LoadFilesInOrder(fileList)
    for i = 1, #fileList do
        local fullPath = fileList[i]
        local fileName = string_match(fullPath, "/([^/]+)$")
        local side = GetFileSide(fileName)

        if SERVER then
            if side == SIDE_SV then
                include(fullPath)
            elseif side == SIDE_SH then
                AddCSLuaFile(fullPath)
                include(fullPath)
            else
                AddCSLuaFile(fullPath)
            end
        else
            if side ~= SIDE_SV then
                include(fullPath)
            end
        end
    end
end

local function Run()
    local startTime = SysTime()
    print("Loading kzcity...")
    hg.loaded = false

    local allFiles = ProcessDirectoryOrdered("homigrad")
    local libFiles, otherFiles = {}, {}
    for _, f in ipairs(allFiles) do
        -- !libraries/0..6 first; homigrad: 0_core -> 1_server -> 2_client -> 3_sim -> 4_body -> 5_items -> 6_ui -> 7_world -> 8_audio -> 9_meta
        if f:match("^homigrad/!libraries/") then
            table_insert(libFiles, f)
        else
            table_insert(otherFiles, f)
        end
    end
    for i = #libFiles, 1, -1 do
        table_insert(otherFiles, 1, libFiles[i])
    end

    LoadFilesInOrder(otherFiles)

    hg.loaded = true
    print(string.format("Loaded zcity, %.5f seconds needed", SysTime() - startTime))
    hook.Run("HomigradRun")
end

if SERVER then
    local function UpdateServerHostname()
        local hostname = "CHELYABINSK | RU | " .. hg.Version

        local port = 0
        local ip = game.GetIPAddress()
        if ip and ip ~= "loopback" then
            port = tonumber(ip:match(":(%d+)$")) or 0
        end
        if port == 0 then
            local cv = GetConVar("hostport")
            if cv then port = cv:GetInt() end
        end

        if port == 27735 then
            hostname = hostname .. " | server 1"
        elseif port == 27019 then
            hostname = hostname .. " | server 2"
        else
            hostname = hostname .. " | non-official server"
        end

        RunConsoleCommand("hostname", hostname)
    end

    hook.Add("InitPostEntity", "ZB_SetHostname", function()
        timer.Simple(5, UpdateServerHostname)
    end)
end

local initpostLoaded = false
hook.Add("InitPostEntity", "zcity_opt", function()
    if initpostLoaded then return end
    initpostLoaded = true
    LoadFilesInOrder(ProcessDirectoryOrdered("initpost"))
    print("Loaded initpost")
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "TrixiePro-Heavy", true, false, "change every text font to selected because ui customization is cool")
font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "TrixiePro-Heavy"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

function CreateFontFamily(base, fonts)
    base = base or {}
    local typeface = base.font or font()

    for name, overrides in pairs(fonts) do
        local opts = {
            font      = overrides.font or typeface,
            size      = overrides.size,              -- size обязателен
            weight    = overrides.weight or base.weight or 400,
            outline   = (overrides.outline ~= nil) and overrides.outline or (base.outline ~= nil and base.outline or false),
            antialias = (overrides.antialias ~= nil) and overrides.antialias or (base.antialias ~= nil and base.antialias or true),
            shadow    = (overrides.shadow ~= nil) and overrides.shadow or (base.shadow ~= nil and base.shadow or false),
            extended  = (overrides.extended ~= nil) and overrides.extended or (base.extended ~= nil and base.extended or true),
        }
        surface.CreateFont(name, opts)
    end
end

Run()

if SERVER then
    AddCSLuaFile("wos/dynabase/loader/loader.lua")
end

include("wos/dynabase/loader/loader.lua")

if SERVER then
    AddCSLuaFile()

    local files = {
        "materials/vgui/weapon_beartrap_homigrad.png",
        "materials/vgui/weapon_beartrap_homigrad.vmt",
        "materials/models/freeman/beartrap_diffuse.vtf",
        "materials/models/freeman/beartrap_specular.vtf",
        "materials/models/freeman/trap_dif.vmt",
        "sound/beartrap.wav",
        "models/stiffy360/beartrap.dx80.vtx",
        "models/stiffy360/beartrap.dx90.vtx",
        "models/stiffy360/beartrap.mdl",
        "models/stiffy360/beartrap.phy",
        "models/stiffy360/beartrap.sw.vtx",
        "models/stiffy360/beartrap.vvd",
        "models/stiffy360/beartrap.xbox.vtx",
        "models/stiffy360/c_beartrap.dx80.vtx",
        "models/stiffy360/c_beartrap.dx90.vtx",
        "models/stiffy360/c_beartrap.mdl",
        "models/stiffy360/c_beartrap.sw.vtx",
        "models/stiffy360/c_beartrap.vvd",
        "models/stiffy360/c_beartrap.xbox.vtx"
    }

    for _, path in ipairs(files) do
        resource.AddFile(path)
    end
end