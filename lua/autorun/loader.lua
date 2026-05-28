hg = hg or {}
hg.Version = "Beta 1.8"
hg.GitHub_ReposOwner = "Rastawontfix, Sildom_Landor"
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
        if f:match("^homigrad/libraries/") then
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

local FONT_DEFAULT = font()
function CreateFontFamily(base, fonts)
    base = base or {}

    for name, overrides in pairs(fonts) do
        local opts = {
            font      = base.font or FONT_DEFAULT,
            size      = overrides.size,              -- size обязателен
            weight    = overrides.weight or base.weight or 400,
            outline   = (overrides.outline ~= nil) and overrides.outline or (base.outline ~= nil and base.outline or false),
            antialias = (overrides.antialias ~= nil) and overrides.antialias or (base.antialias ~= nil and base.antialias or false),
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

