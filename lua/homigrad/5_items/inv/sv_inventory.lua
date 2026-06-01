local blackList = {
    ["weapon_hands_sh"] = true,
    ["weapon_zombclaws"] = true
}

local META = getmetatable("PLAYER")
META.inventory = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}
META.armors = {}

function hg.CreateInv(ply)
    ply.inventory = {}
    local inv = ply.inventory
    inv.Weapons = {}
    for i, wep in ipairs(ply:GetWeapons()) do
        if blackList[wep:GetClass()] then continue end
        inv.Weapons[wep:GetClass()] = wep
    end

    inv.Ammo = ply:GetAmmo()
    inv.Armor = {}
    inv.Attachments = {}
    ply:SetNetVar("Inventory", inv)
end

function hg.RenewInv(ply, isDead)
    ply.inventory = ply.inventory or {}
    local inv = ply.inventory
    inv.Weapons = inv.Weapons or {}

    local sling = inv.Weapons["hg_sling"]
    local kastet = inv.Weapons["hg_brassknuckles"]
    local flashlight = inv.Weapons["hg_flashlight"]

    inv.Weapons = {}

    for i, wep in pairs(ply:GetWeapons()) do
        if blackList[wep:GetClass()] then continue end
        if not isDead then
            inv.Weapons[wep:GetClass()] = wep
        else
            ply.nohook = true
            ply:DropWeapon(wep)

            wep:SetNoDraw(true)
            wep:DrawShadow(false)
            wep:AddSolidFlags(FSOLID_NOT_SOLID)

            local rag = ply:GetNWEntity("RagdollDeath")

            if IsValid(rag) then
                wep:SetPos(rag:GetPos() + vector_up * -10000)
                wep:SetParent(rag, 0)
            else
                wep:SetPos(ply:GetPos())
                wep:SetParent(ply, 0)
            end

            inv.Weapons[wep:GetClass()] = wep
        end
    end

    inv.Weapons["hg_sling"] = sling
    inv.Weapons["hg_brassknuckles"] = kastet
    inv.Weapons["hg_flashlight"] = flashlight
    inv.Ammo = ply:GetAmmo()
    inv.Armor = inv.Armor or {}
    inv.Attachments = inv.Attachments or {}
    ply:SetNetVar("Inventory", inv)
end

hook.Add("Player Spawn", "homigrad-inventory", function(ply)
    hg.CreateInv(ply)
    ply.armors = {}
    ply.armors_health = {}
    ply:SyncArmor()
end)

hook.Add("WeaponEquip", "homigrad-inventory", function(wep, ply)
    local inv = ply.inventory or {}
    if blackList[wep:GetClass()] then return end

    wep:SetNoDraw(false)

    inv.Weapons = inv.Weapons or {}
    inv.Weapons[wep:GetClass()] = wep

    if wep.sling then
        wep.sling = nil
        if not inv["Weapons"]["hg_sling"] then
            inv["Weapons"]["hg_sling"] = true
            ply:ChatPrint("You took the sling the weapon was attached to.")
        else
            local sling = ents.Create("hg_sling")
            sling:SetPos(ply:EyePos())
            sling:SetVelocity(ply:GetAimVector() * 5)
            sling:Spawn()
            ply:ChatPrint("You deattached the sling the weapon was connected to.")
        end
    end

    ply:SetNetVar("Inventory", inv)

    if IsValid(ply.FakeRagdoll) then
        for _, other in player.Iterator() do
            if not other.lootTakePending then continue end
            local prefix = ply:EntIndex() .. "|Weapons|" .. wep:GetClass()
            local ragPrefix = IsValid(ply.FakeRagdoll) and (ply.FakeRagdoll:EntIndex() .. "|Weapons|" .. wep:GetClass()) or nil
            for key in pairs(other.lootTakePending) do
                if key == prefix or key == ragPrefix then
                    other.lootTakePending[key] = nil
                end
            end
        end
    end
end)

hook.Add("PlayerDroppedWeapon", "homigrad-inventory", function(ply, wep)
    local inv = ply.inventory or {}
    if ply:IsNPC() then return end
    if blackList[wep:GetClass()] then return end
    if not inv.Weapons or not inv.Weapons[wep:GetClass()] then return end
    if ply.nohook then ply.nohook = nil return end
    inv.Weapons[wep:GetClass()] = nil
    ply:SetNetVar("Inventory", inv)
end)

hook.Add("PlayerAmmoChanged", "homigrad-inventory", function(ply, ammoID, oldcount, newcount)
    if not ply.inventory then return end
    ply.inventory.Ammo = ply:GetAmmo()
    ply:SetNetVar("Inventory", ply.inventory)

    if game.GetAmmoName(ammoID) == "Grenade" then
        local wep = ply:Give("weapon_hg_hl2nade_tpik")
        wep.DontEquipInstantly = true
        wep.count = newcount - oldcount
        ply:SetAmmo(0, ammoID)

        timer.Simple(0.1, function()
            wep.DontEquipInstantly = nil
        end)
    end
end)

local vecZero = Vector(0, 0, 0)
hook.Add("PlayerDropWeapon", "homigrad-inventory", function(ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep.NoDrop then return end
    local eyeAngles = ply:EyeAngles()
    eyeAngles.x = 0
    local ent = hg.GetCurrentCharacter(ply)
    local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")

    if wep.RemoveFake then wep:RemoveFake() end
    wep:SetCollisionGroup(COLLISION_GROUP_WORLD)
    ply:DropWeapon(wep, ply:EyePos(), vecZero)
    wep:SetPos(ply:EyePos())
    ply.inventory.Weapons[wep:GetClass()] = nil
    ply:SetNetVar("Inventory", ply.inventory)
    ply:SetActiveWeapon(NULL)

    timer.Simple(0.1, function()
        if not IsValid(wep) then return end
        if not IsValid(ply) then return end
        local ent = IsValid(ply:GetNWEntity("RagdollDeath")) and ply:GetNWEntity("RagdollDeath") or ply.FakeRagdoll
        if not IsValid(ent) then return end
        local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")
        local handpos, handang = ent:GetPos(), ent:GetAngles()
        if bon then
            local phys = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bon))
            if IsValid(phys) then
                handpos = phys:GetPos()
                handang = phys:GetAngles()
            end
        end

        local localpos, localang = LocalToWorld(wep.WorldPos and wep.WorldPos + Vector(3.5, 0, 0) or vector_origin, wep.WorldAng or angle_zero, handpos, handang)
        localang:RotateAroundAxis(localang:Forward(), 180)
        wep:SetPos(localpos)
        wep:SetAngles(localang)
        wep:SetVelocity(vector_origin)
        wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local physbone = ent:TranslateBoneToPhysBone(bon)
        local physbonetorso = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))

        local cons = constraint.Weld(wep, ent, 0, physbone, 600, true, false)

        if math.random(1, 10) <= 2 then
            timer.Simple(4, function()
                timer.Simple(0, function()
                    constraint.NoCollide(wep, ent, 0, 0)
                end)
                if IsValid(cons) then
                    cons:Remove()
                end
            end)
        end

        local enta = ply:Alive() and (ply.organism and !ply.organism.otrub) and ply or ent
        local inv = (enta.inventory or enta:GetNetVar("Inventory", {}))
        if not inv["Weapons"] then return end
        if inv["Weapons"]["hg_sling"] and ((ishgweapon(wep) and not wep:IsPistolHoldType()) or wep.ismelee2) then
            constraint.Rope(wep, ent, 0, physbonetorso, vector_origin, vector_origin, 10, 5, 0, 0, "null", true, color_white)
            wep.sling = true
            ent.rope_attach = wep
            inv["Weapons"]["hg_sling"] = nil
            enta:SetNetVar("Inventory", inv)
        end
    end)
end)

hook.Add("PlayerLoadout", "giveHands", function(ply)
    ply:Give("weapon_hands_sh")
    return true
end)

hook.Add("DoPlayerDeath", "homigrad-inventory", function(ply)
    hook.Run("PlayerDropWeapon", ply)
end)

function hg.TransferItems(ply, ragdoll)
    if not IsValid(ragdoll) then return end

    local inv = ply.inventory
    if not istable(inv) then inv = {} end

    ragdoll.inventory = inv
    ragdoll:SetNetVar("Inventory", inv)

    hg.CreateInv(ply)
    ply:SetNetVar("Inventory", {})
    ply.inventory = ply:GetNetVar("Inventory", {})

    hook.Run("ItemsTransfered", ply, ragdoll)

    ragdoll:SetNetVar("Armor", ply.armors)
    ragdoll.armors = ragdoll:GetNetVar("Armor", {})
    ragdoll:SetNetVar("HideArmorRender", ply:GetNetVar("HideArmorRender", false))

    ply:SetNetVar("Armor", {})
    ply.armors = ply:GetNetVar("Armor", {})

    hg.SyncWeapons()
end

hook.Add("PostPlayerDeath", "homigrad-inventory", function(ply)
    local ragdoll = ply:GetNWEntity("RagdollDeath")
    hg.RenewInv(ply, true)
    hg.TransferItems(ply, ragdoll)
    ply:SetNetVar("Inventory", ply.inventory)
    if IsValid(ragdoll) then
        ragdoll:SetNetVar("Inventory", ragdoll.inventory)
    end

    ply:SetNetVar("Armor", {})
    ply:SetNetVar("Inventory", {})
    ply:RemoveAllAmmo()
end)

local function NormalizeWeaponLootValue(value)
	if isentity(value) then
		return IsValid(value) and value or nil
	end
	if isnumber(value) then
		local wep = Entity(value)
		if IsValid(wep) and wep:IsWeapon() then return wep end
		return nil
	end
	if istable(value) or isbool(value) then
		return value
	end
	return nil
end

local function GetLootInventory(ent)
	local owner = hg.GetLootPlayer(ent)
	if IsValid(owner) then
		owner.inventory = owner.inventory or {}
		return owner.inventory, owner
	end

	ent.inventory = ent.inventory or ent:GetNetVar("Inventory")
	NormalizeInventoryWeapons(ent.inventory)
	return ent.inventory, ent
end

local function CanLootPlayer(ply)
	return IsValid(ply) and ply:IsPlayer() and IsValid(ply.FakeRagdoll)
end

local LOOT_TYPES = {
	Weapons = true,
	Ammo = true,
	Armor = true,
	Attachments = true,
}

local function CanLootEntity(ent)
	if not IsValid(ent) then return false end
	local owner = hg.GetLootPlayer(ent)
	if IsValid(owner) then return CanLootPlayer(owner) end
	if ent:IsRagdoll() then
		return istable(ent.inventory) or istable(ent:GetNetVar("Inventory"))
	end
	if ent:IsPlayer() then return IsValid(ent.FakeRagdoll) end
	return string.find(ent:GetClass() or "", "prop_") ~= nil
end

local function SyncCorpseLootInventory(ent, receiver)
	ent.inventory = ent.inventory or ent:GetNetVar("Inventory")
	NormalizeInventoryWeapons(ent.inventory)
	if not ent.inventory then return end
	ent:SetNetVar("Inventory", ent.inventory)
	if IsValid(receiver) then ent:SendNetVar("Inventory", receiver) end
	return ent.inventory
end

local function NormalizeInventoryWeapons(inv)
	if not istable(inv) then return inv end
	if not istable(inv.Weapons) then return inv end

	for class, value in pairs(inv.Weapons) do
		local normalized = NormalizeWeaponLootValue(value)
		inv.Weapons[class] = normalized
	end
	return inv
end

local function IsWeaponEquippedBy(owner, wepClass)
	if not IsValid(owner) or not owner:IsPlayer() then return false end
	local act = owner:GetActiveWeapon()
	return IsValid(act) and act:GetClass() == wepClass
end

local functions = {
    ["Weapons"] = function(ply, ent, wep)
        local owner = hg.GetLootPlayer(ent)
        local invEnt = IsValid(owner) and owner or ent
        local inv = invEnt.inventory
        if not inv or not inv.Weapons or not inv.Weapons[wep] then return end

        local invWeapon = NormalizeWeaponLootValue(inv.Weapons[wep])
        inv.Weapons[wep] = invWeapon
        if invWeapon == nil then return end
        if IsWeaponEquippedBy(owner, wep) then return end

        local weapon
        local weaponIsEnt = isentity(invWeapon) and IsValid(invWeapon) and invWeapon:IsWeapon()
        if not weaponIsEnt then
            if IsValid(owner) and owner:HasWeapon(wep) then return end

            local weaponData = weapons.Get(wep) or scripted_ents.GetStored(wep)
            if not weaponData then
                inv.Weapons[wep] = nil
                return
            end

            weapon = ents.Create(wep)
            if not IsValid(weapon) then
                inv.Weapons[wep] = nil
                return
            end

            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory != 1)
            weapon.IsSpawned = true
            weapon.init = true
            weapon:Spawn()
            weapon:SetPos(ent:GetPos())
            weapon:SetAngles(ent:GetAngles())

            if weapon.SetInfo and invWeapon ~= true then
                weapon:SetInfo(invWeapon)
            end
        else
            if IsValid(owner) and owner:HasWeapon(wep) and owner:GetWeapon(wep) ~= invWeapon then return end

            weapon = invWeapon
            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory != 1)

            weapon:SetParent(NULL)
            weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            weapon:SetAngles(ent:GetAngles())
            weapon:SetNoDraw(false)
            weapon:DrawShadow(true)
            weapon:RemoveSolidFlags(FSOLID_NOT_SOLID)
        end

        inv.Weapons[wep] = nil

        if IsValid(owner) then
            if weaponIsEnt then
                owner:DropWeapon(weapon)
                weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
                if IsValid(weapon:GetOwner()) then
                    inv.Weapons[wep] = invWeapon
                    return
                end
            else
                owner:StripWeapon(wep)
            end
        end

        ply:DropObject()

        if not weapon:IsWeapon() then weapon:Use(ply) return end

        weapon.IsSpawned = false
        weapon.init = false

        if not hook.Run("PlayerCanPickupWeapon", ply, weapon) then
            weapon.IsSpawned = true
            weapon.init = true
            weapon:SetPos(ply:EyePos())
            inv.Weapons[wep] = invWeapon
            return
        end

        if IsValid(weapon) and weapon:IsWeapon() then
            ply:PickupWeapon(weapon)
        end

        if not weapon.DontEquipInstantly then
            timer.Simple(0, function() ply:SelectWeapon(weapon:GetClass()) end)
        end
    end,
    ["Ammo"] = function(ply, ent, ammo, amt)
        local owner = hg.GetLootPlayer(ent)
        local invEnt = IsValid(owner) and owner or ent
        local inv = invEnt.inventory
        if not inv or not inv.Ammo then return end

        local ammoID = tonumber(ammo)
        if not ammoID then return end

        local amt2 = inv.Ammo[ammoID]
        if not amt2 or amt != amt2 then return end

        local ammoName = game.GetAmmoName(ammoID)
        if not ammoName then return end

        ply:GiveAmmo(amt2, ammoName, true)
        inv.Ammo[ammoID] = nil
        if IsValid(owner) then
            owner:SetAmmo(0, ammoName)
            owner.inventory.Ammo = owner:GetAmmo()
        end
    end,
    ["Armor"] = function(ply, ent, placement, armor)
        if not hg.armor[placement] or not hg.armor[placement][armor] then
            hg.ArmorDbg("sv_inventory.lua", "Armor transfer: нет данных для [" .. tostring(placement) .. "][" .. tostring(armor) .. "]")
            return
        end
        if hg.armor[placement][armor].nodrop then return end

        local owner = hg.GetLootPlayer(ent)
        local invEnt = IsValid(owner) and owner or ent
        invEnt.armors = invEnt.armors or {}
        ply.armors = ply.armors or {}
        if (not invEnt.armors[placement]) or (invEnt.armors[placement] ~= armor) or ply.armors[placement] then
            hg.ArmorDbg("sv_inventory.lua", "Armor transfer: отказ — ent[" .. tostring(placement) .. "]=" .. tostring(invEnt.armors[placement]) .. " ply[" .. tostring(placement) .. "]=" .. tostring(ply.armors[placement]))
            return
        end
        if !hg.AddArmor(ply, armor) then
            hg.ArmorDbg("sv_inventory.lua", "Armor transfer: AddArmor fail — " .. tostring(armor))
            return
        end
        invEnt.armors[placement] = nil

        if placement == "face" and invEnt:GetNetVar("zableval_masku", false) and armor != "nightvision1" then
            ply:SetNetVar("zableval_masku", true)
            invEnt:SetNetVar("zableval_masku", false)
        end

        hook.Run("ItemTransfer", ply, ent, placement, armor)
    end,
    ["Attachments"] = function(ply, ent, att)
        att = tonumber(att)
        if not att then return end

        local owner = hg.GetLootPlayer(ent)
        local invEnt = IsValid(owner) and owner or ent
        local inv = invEnt.inventory
        if not inv or not inv.Attachments or not inv.Attachments[att] then return end

        ply.inventory = ply.inventory or {}
        ply.inventory.Attachments = ply.inventory.Attachments or {}
        ply.inventory.Attachments[#ply.inventory.Attachments + 1] = inv.Attachments[att]
        inv.Attachments[att] = nil
    end,
}

local function BuildLootTakeKey(ent, tblIndex, thing)
    if not IsValid(ent) then return "" end
    return ent:EntIndex() .. "|" .. tblIndex .. "|" .. thing
end

local function GetLootTakeDuration(tblIndex, thing)
    if tblIndex == "Weapons" then
        local swep = weapons.Get(thing)
        local weight = swep and tonumber(swep.weight)
        if weight then return math.Clamp(weight, 0, 5) end
    end
    return math.Rand(0.5, 1.15)
end

util.AddNetworkString("ply_take_item_begin")
util.AddNetworkString("ply_take_item_begin_ack")
net.Receive("ply_take_item_begin", function(_, ply)
    local tblIndex = net.ReadString()
    local thing = net.ReadString()
    net.ReadTable()
    local ent = net.ReadEntity()

    if not LOOT_TYPES[tblIndex] then return end
    if not isstring(thing) or thing == "" or #thing > 128 then return end
    if not IsValid(ent) or not IsValid(ply) or not ply:Alive() then return end
    if not CanLootEntity(ent) then return end
    if ent:GetPos():Distance(ply:GetPos()) > 125 then return end

    local lootOwner = hg.GetLootPlayer(ent)
    if tblIndex == "Weapons" and IsValid(lootOwner) then
        local act = lootOwner:GetActiveWeapon()
        if IsValid(act) and act:GetClass() == thing then return end
    end

    local inv = select(1, GetLootInventory(ent))
    if tblIndex == "Weapons" and (not inv or not inv.Weapons or inv.Weapons[thing] == nil) then return end

    local key = BuildLootTakeKey(ent, tblIndex, thing)
    local duration = GetLootTakeDuration(tblIndex, thing)
    ply.lootTakePending = ply.lootTakePending or {}
    ply.lootTakePending[key] = CurTime() + duration

    net.Start("ply_take_item_begin_ack")
        net.WriteString(key)
        net.WriteFloat(duration)
    net.Send(ply)
end)

util.AddNetworkString("ply_take_item")
net.Receive("ply_take_item", function(len, ply)
    local tblIndex = net.ReadString()
    local thing = net.ReadString()
    local tbl = net.ReadTable()
    local ent = net.ReadEntity()

    if not LOOT_TYPES[tblIndex] then return end
    if not isstring(thing) or thing == "" or #thing > 128 then return end
    if not IsValid(ent) or not IsValid(ply) or not ply:Alive() then return end
    if not CanLootEntity(ent) then return end
    if ent:GetPos():Distance(ply:GetPos()) > 125 then return end

    local key = BuildLootTakeKey(ent, tblIndex, thing)
    local unlockTime = ply.lootTakePending and ply.lootTakePending[key]
    if not unlockTime or unlockTime > CurTime() then return end
    if (ply.cooldown_takeitem or 0) > CurTime() then return end

    local lootOwner = hg.GetLootPlayer(ent)
    if tblIndex == "Weapons" and IsValid(lootOwner) and IsWeaponEquippedBy(lootOwner, thing) then
        ply.lootTakePending[key] = nil
        return
    end

    ply.cooldown_takeitem = CurTime() + 0.3
    ply.lootTakePending[key] = nil

    local inv, invEnt = GetLootInventory(ent)
    if not inv and hg.EnsureLootInventory(ply, ent) then
        inv, invEnt = GetLootInventory(ent)
    end
    if not inv then return end

    if tblIndex == "Weapons" and (not inv.Weapons or inv.Weapons[thing] == nil) then return end
    if tblIndex == "Attachments" then
        local att = tonumber(thing)
        if not att or not inv.Attachments or inv.Attachments[att] == nil then return end
    end

    invEnt.inventory = inv
    NormalizeInventoryWeapons(inv)

    local func = functions[tblIndex]
    if func then func(ply, ent, thing, unpack(tbl)) end
    ply:SetNetVar("Inventory", ply.inventory)
    invEnt:SetNetVar("Inventory", inv)
    ply:SyncArmor()
    invEnt:SyncArmor()
end)

local function LootBoxTier(model)
    if not istable(hg.loot_boxes) then return end
    model = string.lower(model or "")
    if hg.loot_boxes[model] then return hg.loot_boxes[model] end
    local alt = model:gsub("_damagedmax", ""):gsub("_damaged", "")
    if alt ~= model and hg.loot_boxes[alt] then return hg.loot_boxes[alt] end
end

function hg.EnsureLootInventory(ply, ent)
    if not IsValid(ent) then return end

    if ent:IsRagdoll() then
        local owner = hg.GetLootPlayer(ent)
        if IsValid(owner) then
            hg.RenewInv(owner)
            ent.inventory = owner.inventory
            ent.armors = owner.armors or owner:GetNetVar("Armor", {})
            ent:SetNetVar("Inventory", owner:GetNetVar("Inventory"))
            ent:SetNetVar("Armor", ent.armors)
            if IsValid(ply) then
                ent:SendNetVar("Inventory", ply)
                ent:SendNetVar("Armor", ply)
            end
            return owner.inventory
        end
        return SyncCorpseLootInventory(ent, ply)
    end

    ent.inventory = ent.inventory or ent:GetNetVar("Inventory")
    NormalizeInventoryWeapons(ent.inventory)
    if ent.inventory then
        ent:SetNetVar("Inventory", ent.inventory)
        if IsValid(ply) then ent:SendNetVar("Inventory", ply) end
        return ent.inventory
    end

    if not string.find(ent:GetClass() or "", "prop_") then return end

    hook.Run("ZB_InventoryChecked", ply, ent)

    ent.inventory = ent.inventory or ent:GetNetVar("Inventory")
    NormalizeInventoryWeapons(ent.inventory)
    if ent.inventory then
        ent:SetNetVar("Inventory", ent.inventory)
        if IsValid(ply) then ent:SendNetVar("Inventory", ply) end
        return ent.inventory
    end

    if not LootBoxTier(ent:GetModel()) then return end

    ent.armors = ent.armors or {}
    ent.inventory = {Weapons = {}, Ammo = {}, Attachments = {}}
    ent.was_opened = true
    ent:SetNetVar("Armor", ent.armors)
    ent:SetNetVar("Inventory", ent.inventory)
    if IsValid(ply) then
        ent:SendNetVar("Inventory", ply)
        ent:SendNetVar("Armor", ply)
    end

    return ent.inventory
end

util.AddNetworkString("should_open_inv")
local playerMeta = FindMetaTable("Player")
function playerMeta:OpenInventory(ent)
    if not IsValid(ent) then return end
    if not CanLootEntity(ent) then return end

    if not ent:IsPlayer() and not hg.EnsureLootInventory(self, ent) then return end

    hook.Run("ZB_InventoryOpened", self, ent)
    local lootOwner = hg.GetLootPlayer(ent)
    if IsValid(lootOwner) then
        hg.RenewInv(lootOwner)
        if not ent:IsPlayer() then
            ent.inventory = lootOwner.inventory
            ent:SetNetVar("Inventory", lootOwner:GetNetVar("Inventory"))
        end
    elseif ent:IsRagdoll() then
        SyncCorpseLootInventory(ent, self)
    end
    if self:IsPlayer() then hg.RenewInv(self) end
    self.cooldown_takeitem = CurTime() + 0.5

    net.Start("should_open_inv")
    net.WriteEntity(ent)
    net.Send(self)
end

function playerMeta:GetLookTrace()
    if not IsValid(self) or not self:Alive() then return end
    local tr = {}
    local ent = IsValid(self.FakeRagdoll) and self.FakeRagdoll or self
    local att = ent:GetAttachment(ent:LookupAttachment("eyes"))
    if not att then return false end
    tr.start = att.Pos
    tr.endpos = att.Pos + self:EyeAngles():Forward() * 80
    tr.filter = ent
    return util.TraceLine(tr)
end

hook.Add("Player Think", "loot-fellows", function(ply)
    if not ply:Alive() then return end
    ply.keypressed = ply.keypressed or false

    local use = ply:KeyDown(IN_ATTACK2) and ply:KeyDown(IN_USE) and not ply:KeyDown(IN_ATTACK)

    if use then
        local trace = hg.eyeTrace(ply, 60)
        if not trace then return end
        local ent = trace.Entity
        local _, _, canloot = hook.Run("ZB_CanLootInventory", ply, ent, nil)
        if canloot ~= nil and canloot == false then
            ply.keypressed = true
            return
        end

        if not IsValid(ent) then return end
        if not hg.EnsureLootInventory(ply, ent) then return end

        if not ply.keypressed then ply:OpenInventory(ent) end
        ply.keypressed = true
    else
        ply.keypressed = false
    end
end)

hook.Add("PlayerUse", "homigrad-inv-prop", function(ply, ent)
    if not ply:Alive() or not IsValid(ent) then return end
    if not string.find(ent:GetClass() or "", "prop_") then return end
    return
end)
