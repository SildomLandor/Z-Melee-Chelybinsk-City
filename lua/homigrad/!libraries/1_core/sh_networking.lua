zb = zb or {}

zb.netSFSKeys = {
    Inventory = true,
    wounds = true,
    arterialwounds = true,
}

zb.netSFSLim = {
    Inventory = 16384,
    wounds = 8192,
    arterialwounds = 8192,
}

if (CLIENT) then
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.globals = zb.net.globals or {}

    net.Receive("zbGlobalVarSet", function()
        local key, var = net.ReadString(), net.ReadType()

    	zb.net.globals[key] = var

        hook.Run("OnGlobalVarSet", key, var)
    end)

    net.Receive("zbNetVarSet", function()
        local index = net.ReadUInt(16)

		local key = net.ReadString()
    	local var = net.ReadType()
		
        zb.net[index] = zb.net[index] or {}
        zb.net[index][key] = var

		if IsValid(Entity(index)) then
			hook.Run("OnNetVarSet", index, key, var)
		else
			zb.net[index].waiting = true
		end
    end)

    net.Receive("zbNetVarSetSFS", function()
        local index = net.ReadUInt(16)
        local key = net.ReadString()
        local var = hg.netReadSFS(zb.netSFSLim[key])

        zb.net[index] = zb.net[index] or {}
        zb.net[index][key] = var

        if IsValid(Entity(index)) then
            hook.Run("OnNetVarSet", index, key, var)
        else
            zb.net[index].waiting = true
        end
    end)
	
    net.Receive("zbNetVarDelete", function()
    	zb.net[net.ReadUInt(16)] = nil
    end)

    net.Receive("zbLocalVarSet", function()
    	local key = net.ReadString()
    	local var = net.ReadType()

    	zb.net[LocalPlayer():EntIndex()] = zb.net[LocalPlayer():EntIndex()] or {}
    	zb.net[LocalPlayer():EntIndex()][key] = var

    	hook.Run("OnLocalVarSet", key, var)
    end)

    function GetNetVar(key, default) -- luacheck: globals GetNetVar
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function entityMeta:GetNetVar(key, default)
    	local index = self:EntIndex()

    	if (zb.net[index] and zb.net[index][key] != nil) then
    		return zb.net[index][key]
    	end

    	return default
    end

    playerMeta.GetLocalVar = entityMeta.GetNetVar

	hook.Add("InitPostEntity", "OnRequestFullUpdate_zb", function()
		LocalPlayer():SyncVars()
	end)

	function playerMeta:SyncVars()
		net.Start("ZB_request_fullupdate")
		net.SendToServer()
	end
else
	util.AddNetworkString("ZB_request_fullupdate")

	net.Receive("ZB_request_fullupdate",function(len,ply)
		ply.cooldown_sendnet = ply.cooldown_sendnet or 0
		if ply.cooldown_sendnet < CurTime() then
			ply.cooldown_sendnet = CurTime() + 1

			ply:SyncVars()
		end
	end)

	gameevent.Listen( "OnRequestFullUpdate" )
	hook.Add("OnRequestFullUpdate", "OnRequestFullUpdate_zb", function(data)
		local id = data.userid
		local ply = Player(id)
		
		ply:SyncVars()
	end)
	
	
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.list = zb.net.list or {}
    zb.net.locals = zb.net.locals or {}
    zb.net.globals = zb.net.globals or {}

    util.AddNetworkString("zbGlobalVarSet")
    util.AddNetworkString("zbLocalVarSet")
    util.AddNetworkString("zbNetVarSet")
    util.AddNetworkString("zbNetVarSetSFS")
    util.AddNetworkString("zbNetVarDelete")

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
        for k, v in pairs(w) do
            if isbool(v) or istable(v) then
                out.Weapons[k] = v
            elseif IsEntity(v) then
                out.Weapons[k] = IsValid(v) and v:EntIndex() or nil
            else
                out.Weapons[k] = v
            end
        end
        return out
    end

    hg.InvForNet = hg.InvForNet or invForNet

    local function netVarEq(key, a, b)
        if a == b then return true end
        if not istable(a) or not istable(b) then return false end
        if not hg.sfs then return false end
        local ea, eb = hg.sfs.encode(a), hg.sfs.encode(b)
        return ea and eb and ea == eb
    end

    local function prepNetVar(ent, key, value)
        if key == "Inventory" and istable(value) then
            ent.inventory = value
            value = invForNet(value)
        end
        return value
    end

    local function sendNetVarData(index, key, var, receiver)
        if zb.netSFSKeys[key] and hg.netWriteSFS then
            net.Start("zbNetVarSetSFS")
            net.WriteUInt(index, 16)
            net.WriteString(key)
            if not hg.netWriteSFS(var, zb.netSFSLim[key]) then
                ErrorNoHalt("sh_networking.lua: SFS fail key=" .. tostring(key) .. ", fallback WriteType\n")
                net.Start("zbNetVarSet")
                net.WriteUInt(index, 16)
                net.WriteString(key)
                net.WriteType(var)
            end
        else
            net.Start("zbNetVarSet")
            net.WriteUInt(index, 16)
            net.WriteString(key)
            net.WriteType(var)
        end

        if receiver == nil then
            net.Broadcast()
        else
            net.Send(receiver)
        end
    end

    local function CheckBadType(name, object)
		return false
    	--[[if (isfunction(object)) then
    		ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")

    		return true
    	elseif (istable(object)) then
    		for k, v in pairs(object) do
    			if (CheckBadType(name, k) or CheckBadType(name, v)) then
    				return true
    			end
    		end
    	end--]]
    end

    function GetNetVar(key, default)
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function SetNetVar(key, value, receiver, unreliable)
    	if (CheckBadType(key, value)) then return end
    	--if (GetNetVar(key) == value) then return end
		
    	zb.net.globals[key] = value

    	net.Start("zbGlobalVarSet", unreliable)
    	net.WriteString(key)
    	net.WriteType(value)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
    function playerMeta:SyncVars()
    	for k, v in pairs(zb.net.globals) do
    		net.Start("zbGlobalVarSet")
    			net.WriteString(k)
    			net.WriteType(v)
    		net.Send(self)
    	end

    	for k, v in pairs(zb.net.locals[self] or {}) do
    		net.Start("zbLocalVarSet")
    			net.WriteString(k)
    			net.WriteType(v)
    		net.Send(self)
    	end

    	for entity, data in pairs(zb.net.list) do
    		if (IsValid(entity)) then
    			local index = entity:EntIndex()

    			for k, v in pairs(data) do
                    if zb.netSFSKeys[k] and hg.netWriteSFS then
                        net.Start("zbNetVarSetSFS")
                        net.WriteUInt(index, 16)
                        net.WriteString(k)
                        hg.netWriteSFS(v, zb.netSFSLim[k])
                    else
                        net.Start("zbNetVarSet")
                        net.WriteUInt(index, 16)
                        net.WriteString(k)
                        net.WriteType(v)
                    end
    				net.Send(self)
    			end
			else
				zb.net.list[entity] = nil
    		end
    	end
    end
	
    function playerMeta:GetLocalVar(key, default)
    	if (zb.net.locals[self] and zb.net.locals[self][key] != nil) then
    		return zb.net.locals[self][key]
    	end

    	return default
    end

    function playerMeta:SetLocalVar(key, value)
    	if (CheckBadType(key, value)) then return end

    	zb.net.locals[self] = zb.net.locals[self] or {}
    	zb.net.locals[self][key] = value

    	net.Start("zbLocalVarSet")
    		net.WriteString(key)
    		net.WriteType(value)
    	net.Send(self)
    end

    function entityMeta:GetNetVar(key, default)
    	if (zb.net.list[self] and zb.net.list[self][key] != nil) then
    		return zb.net.list[self][key]
    	end

    	return default
    end

    function entityMeta:SetNetVar(key, value, receiver)
    	if (CheckBadType(key, value)) then return end

		zb.net.list[self] = zb.net.list[self] or {}
        value = prepNetVar(self, key, value)

        local old = zb.net.list[self][key]
        if istable(value) and istable(old) and old == value then
            if zb.netSFSKeys[key] and netVarEq(key, old, value) then return end
        elseif old == value then
            return
        elseif istable(value) and istable(old) and zb.netSFSKeys[key] and netVarEq(key, old, value) then
            return
        end

    	zb.net.list[self][key] = value
		self:SendNetVar(key, receiver)
	end

    function entityMeta:SendNetVar(key, receiver)
        local var = zb.net.list[self] and zb.net.list[self][key]
        sendNetVarData(self:EntIndex(), key, var, receiver)
    end

    function entityMeta:ClearNetVars(receiver)
    	zb.net.list[self] = nil
    	zb.net.locals[self] = nil

    	net.Start("zbNetVarDelete")
    	net.WriteUInt(self:EntIndex(), 16)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
	hook.Add("EntityRemoved","ZB_clear_net",function(ent,fullUpdate)
		ent:ClearNetVars()
	end)

	hook.Add("PlayerDisconnected","ZB_clear_net",function(ply)
		ply:ClearNetVars()
	end)
end