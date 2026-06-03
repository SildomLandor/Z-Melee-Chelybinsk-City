local net          = net
local hook         = hook
local util         = util
local player       = player
local gameevent    = gameevent
local FindMetaTable = FindMetaTable
local IsValid      = IsValid
local Entity       = Entity
local Player       = Player
local LocalPlayer  = LocalPlayer
local CLIENT       = CLIENT
local next         = next
local istable      = istable
local isbool       = isbool
local IsEntity     = IsEntity
local tostring     = tostring
local ErrorNoHalt  = ErrorNoHalt
local CurTime      = CurTime
local rawget       = rawget
local rawset       = rawset
local timer_Simple = timer.Simple
local STR_INVENTORY        = "Inventory"
local STR_WOUNDS           = "wounds"
local STR_ARTERIALWOUNDS   = "arterialwounds"

local NET_GLOBAL_VAR_SET   = "zbGlobalVarSet"
local NET_NET_VAR_SET      = "zbNetVarSet"
local NET_NET_VAR_SET_SFS  = "zbNetVarSetSFS"
local NET_NET_VAR_DELETE   = "zbNetVarDelete"
local NET_LOCAL_VAR_SET    = "zbLocalVarSet"
local NET_FULLUPDATE_REQ   = "ZB_request_fullupdate"

local HOOK_GLOBAL_SET      = "OnGlobalVarSet"
local HOOK_NET_SET         = "OnNetVarSet"
local HOOK_LOCAL_SET       = "OnLocalVarSet"
local HOOK_INIT_POST_ENT   = "InitPostEntity"
local HOOK_REQ_FULLUPDATE  = "OnRequestFullUpdate"
local HOOK_ENT_REMOVED     = "EntityRemoved"
local HOOK_PLY_DISCONNECT  = "PlayerDisconnected"

local ID_INIT_POST_ENT_ZB  = "OnRequestFullUpdate_zb"
local ID_CLEAR_NET         = "ZB_clear_net"

local ERROR_SFS_FALLBACK   = "sh_networking.lua: SFS fail key=%s, fallback WriteType\n"

zb = zb or {}

zb.netSFSKeys = zb.netSFSKeys or {
    [STR_INVENTORY]      = true,
    [STR_WOUNDS]         = true,
    [STR_ARTERIALWOUNDS] = true,
}

zb.netSFSLim = zb.netSFSLim or {
    [STR_INVENTORY]      = 16384,
    [STR_WOUNDS]         = 8192,
    [STR_ARTERIALWOUNDS] = 8192,
}

local zb_netSFSKeys = zb.netSFSKeys
local zb_netSFSLim  = zb.netSFSLim

zb.net = zb.net or {}
local zb_net = zb.net
zb_net.globals = zb_net.globals or {}
local zb_net_globals = zb_net.globals

local entityMeta = FindMetaTable("Entity")
local playerMeta = FindMetaTable("Player")

local Entity_EntIndex = entityMeta.EntIndex
if CLIENT then

    local net_ReadString = net.ReadString
    local net_ReadType   = net.ReadType
    local net_ReadUInt   = net.ReadUInt
    local net_Receive    = net.Receive
    local hook_Run       = hook.Run

    net_Receive(NET_GLOBAL_VAR_SET, function()
        local key = net_ReadString()
        local var = net_ReadType()

        rawset(zb_net_globals, key, var)
        hook_Run(HOOK_GLOBAL_SET, key, var)
    end)

    net_Receive(NET_NET_VAR_SET, function()
        local index = net_ReadUInt(16)
        local key   = net_ReadString()
        local var   = net_ReadType()

        local entCache = rawget(zb_net, index)
        if not entCache then
            entCache = {}
            rawset(zb_net, index, entCache)
        end
        rawset(entCache, key, var)

        if IsValid(Entity(index)) then
            hook_Run(HOOK_NET_SET, index, key, var)
        else
            rawset(entCache, "waiting", true)
        end
    end)

    net_Receive(NET_NET_VAR_SET_SFS, function()
        local index = net_ReadUInt(16)
        local key   = net_ReadString()
        
        local hg = hg
        local var = hg and hg.netReadSFS and hg.netReadSFS(rawget(zb_netSFSLim, key))

        local entCache = rawget(zb_net, index)
        if not entCache then
            entCache = {}
            rawset(zb_net, index, entCache)
        end
        rawset(entCache, key, var)

        if IsValid(Entity(index)) then
            hook_Run(HOOK_NET_SET, index, key, var)
        else
            rawset(entCache, "waiting", true)
        end
    end)
    
    net_Receive(NET_NET_VAR_DELETE, function()
        rawset(zb_net, net_ReadUInt(16), nil)
    end)

    net_Receive(NET_LOCAL_VAR_SET, function()
        local key = net_ReadString()
        local var = net_ReadType()
        local localIdx = Entity_EntIndex(LocalPlayer())

        local entCache = rawget(zb_net, localIdx)
        if not entCache then
            entCache = {}
            rawset(zb_net, localIdx, entCache)
        end
        rawset(entCache, key, var)

        hook_Run(HOOK_LOCAL_SET, key, var)
    end)

    function GetNetVar(key, default)
        local value = rawget(zb_net_globals, key)
        return value ~= nil and value or default
    end

    function entityMeta:GetNetVar(key, default)
        local index = Entity_EntIndex(self)
        local entCache = rawget(zb_net, index)

        if entCache then
            local value = rawget(entCache, key)
            if value ~= nil then
                return value
            end
        end

        return default
    end

    playerMeta.GetLocalVar = entityMeta.GetNetVar

    local net_Start = net.Start
    local net_SendToServer = net.SendToServer

    function playerMeta:SyncVars()
        net_Start(NET_FULLUPDATE_REQ)
        net_SendToServer()
    end

    hook.Add(HOOK_INIT_POST_ENT, ID_INIT_POST_ENT_ZB, function()
        local lp = LocalPlayer()
        if IsValid(lp) then
            lp:SyncVars()
        end
    end)
else
    util.AddNetworkString(NET_FULLUPDATE_REQ)
    util.AddNetworkString(NET_GLOBAL_VAR_SET)
    util.AddNetworkString(NET_LOCAL_VAR_SET)
    util.AddNetworkString(NET_NET_VAR_SET)
    util.AddNetworkString(NET_NET_VAR_SET_SFS)
    util.AddNetworkString(NET_NET_VAR_DELETE)

    zb_net.list    = zb_net.list or {}
    zb_net.locals  = zb_net.locals or {}
    
    local zb_net_list   = zb_net.list
    local zb_net_locals = zb_net.locals

    local net_Start     = net.Start
    local net_WriteString = net.WriteString
    local net_WriteType = net.WriteType
    local net_WriteUInt = net.WriteUInt
    local net_Broadcast = net.Broadcast
    local net_Receive   = net.Receive
    local net_Send      = net.Send 

    net_Receive(NET_FULLUPDATE_REQ, function(len, ply)
        if not IsValid(ply) then return end
        ply.cooldown_sendnet = ply.cooldown_sendnet or 0
        if ply.cooldown_sendnet < CurTime() then
            ply.cooldown_sendnet = CurTime() + 1
            ply:SyncVars()
        end
    end)

    gameevent.Listen(HOOK_REQ_FULLUPDATE)
    hook.Add(HOOK_REQ_FULLUPDATE, ID_INIT_POST_ENT_ZB, function(data)
        local ply = Player(data.userid)
        if IsValid(ply) then
            ply:SyncVars()
        end
    end)

    local function invForNet(inv)
        if not istable(inv) then return inv end
        local w = inv.Weapons
        if not w then return inv end
        
        local out = {
            Ammo = inv.Ammo,
            Armor = inv.Armor,
            Attachments = inv.Attachments,
            Money = inv.Money,
            Weapons = {},
        }
        
        local out_weapons = out.Weapons
        for k, v in next, w do
            if isbool(v) or istable(v) then
                out_weapons[k] = v
            elseif IsEntity(v) then
                out_weapons[k] = IsValid(v) and Entity_EntIndex(v) or nil
            else
                out_weapons[k] = v
            end
        end
        return out
    end

    local hg = hg or {}
    hg.InvForNet = invForNet

    local function netVarEq(key, a, b)
        if a == b then return true end
        if not istable(a) or not istable(b) then return false end
        
        local hg_sfs = hg.sfs
        if not hg_sfs then return false end
        
        local hg_sfs_encode = hg_sfs.encode
        if not hg_sfs_encode then return false end

        local ea, eb = hg_sfs_encode(a), hg_sfs_encode(b)
        return ea and eb and ea == eb
    end

    local function prepNetVar(ent, key, value)
        if key == STR_INVENTORY and istable(value) then
            ent.inventory = value
            value = invForNet(value)
        end
        return value
    end
    local function sendNetVarData(index, key, var, receiver)
        timer_Simple(0, function()
            if receiver ~= nil and not IsValid(receiver) then return end

            local hg_netWriteSFS = hg.netWriteSFS

            if rawget(zb_netSFSKeys, key) and hg_netWriteSFS then
                net_Start(NET_NET_VAR_SET_SFS)
                net_WriteUInt(index, 16)
                net_WriteString(key)
                if not hg_netWriteSFS(var, rawget(zb_netSFSLim, key)) then
                    ErrorNoHalt(ERROR_SFS_FALLBACK:format(tostring(key)))
                    net_Start(NET_NET_VAR_SET)
                    net_WriteUInt(index, 16)
                    net_WriteString(key)
                    net_WriteType(var)
                end
            else
                net_Start(NET_NET_VAR_SET)
                net_WriteUInt(index, 16)
                net_WriteString(key)
                net_WriteType(var)
            end

            if receiver == nil then
                net_Broadcast()
            else
                net_Send(receiver)
            end
        end)
    end

    local function CheckBadType(name, object)
        return false
    end

    function GetNetVar(key, default)
        local value = rawget(zb_net_globals, key)
        return value ~= nil and value or default
    end

    function SetNetVar(key, value, receiver, unreliable)
        rawset(zb_net_globals, key, value)

        timer_Simple(0, function()
            if receiver ~= nil and not IsValid(receiver) then return end
            
            net_Start(NET_GLOBAL_VAR_SET, unreliable)
            net_WriteString(key)
            net_WriteType(value)

            if (receiver == nil) then
                net_Broadcast()
            else
                net_Send(receiver)
            end
        end)
    end
    
    function playerMeta:SyncVars()
        local hg_netWriteSFS = hg.netWriteSFS

        for k, v in next, zb_net_globals do
            net_Start(NET_GLOBAL_VAR_SET)
                net_WriteString(k)
                net_WriteType(v)
            net_Send(self)
        end

        local myLocals = rawget(zb_net_locals, self)
        if myLocals then
            for k, v in next, myLocals do
                net_Start(NET_LOCAL_VAR_SET)
                    net_WriteString(k)
                    net_WriteType(v)
                net_Send(self)
            end
        end

        for entity, data in next, zb_net_list do
            if IsValid(entity) then
                local index = Entity_EntIndex(entity)

                for k, v in next, data do
                    if rawget(zb_netSFSKeys, k) and hg_netWriteSFS then
                        net_Start(NET_NET_VAR_SET_SFS)
                        net_WriteUInt(index, 16)
                        net_WriteString(k)
                        hg_netWriteSFS(v, rawget(zb_netSFSLim, k))
                    else
                        net_Start(NET_NET_VAR_SET)
                        net_WriteUInt(index, 16)
                        net_WriteString(k)
                        net_WriteType(v)
                    end
                    net_Send(self)
                end
            else
                rawset(zb_net_list, entity, nil)
            end
        end
    end
    
    function playerMeta:GetLocalVar(key, default)
        local plCache = rawget(zb_net_locals, self)
        if plCache and rawget(plCache, key) ~= nil then
            return rawget(plCache, key)
        end

        return default
    end

    function playerMeta:SetLocalVar(key, value)
        local plCache = rawget(zb_net_locals, self)
        if not plCache then
            plCache = {}
            rawset(zb_net_locals, self, plCache)
        end
        rawset(plCache, key, value)

        timer_Simple(0, function()
            if not IsValid(self) then return end
            net_Start(NET_LOCAL_VAR_SET)
                net_WriteString(key)
                net_WriteType(value)
            net_Send(self)
        end)
    end

    function entityMeta:GetNetVar(key, default)
        local entCache = rawget(zb_net_list, self)
        if entCache and rawget(entCache, key) ~= nil then
            return rawget(entCache, key)
        end

        return default
    end

    function entityMeta:SetNetVar(key, value, receiver)
        local entCache = rawget(zb_net_list, self)
        if not entCache then
            entCache = {}
            rawset(zb_net_list, self, entCache)
        end
        
        value = prepNetVar(self, key, value)
        local old = rawget(entCache, key)

        if istable(value) and istable(old) and old == value then
            if rawget(zb_netSFSKeys, key) and netVarEq(key, old, value) then return end
        elseif old == value then
            return
        elseif istable(value) and istable(old) and rawget(zb_netSFSKeys, key) and netVarEq(key, old, value) then
            return
        end

        rawset(entCache, key, value)
        self:SendNetVar(key, receiver)
    end

    function entityMeta:SendNetVar(key, receiver)
        local entCache = rawget(zb_net_list, self)
        local var = entCache and rawget(entCache, key)
        sendNetVarData(Entity_EntIndex(self), key, var, receiver)
    end

    function entityMeta:ClearNetVars(receiver)
        rawset(zb_net_list, self, nil)
        rawset(zb_net_locals, self, nil)

        timer_Simple(0, function()
            if receiver ~= nil and not IsValid(receiver) then return end
            if not IsValid(self) then return end
            
            net_Start(NET_NET_VAR_DELETE)
            net_WriteUInt(Entity_EntIndex(self), 16)

            if (receiver == nil) then
                net_Broadcast()
            else
                net_Send(receiver)
            end
        end)
    end
    
    hook.Add(HOOK_ENT_REMOVED, ID_CLEAR_NET, function(ent, fullUpdate)
        if IsValid(ent) then ent:ClearNetVars() end
    end)

    hook.Add(HOOK_PLY_DISCONNECT, ID_CLEAR_NET, function(ply)
        if IsValid(ply) then ply:ClearNetVars() end
    end)
end