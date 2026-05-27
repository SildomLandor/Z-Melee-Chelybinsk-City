local blackList = {
    ["weapon_hands_sh"] = true,
    ["weapon_zombclaws"] = true
}

local invDebug = CreateConVar("hg_inv_debug", "0", FCVAR_ARCHIVE, "huyhuyhuy")
local function InvDbg(ply, fmt, ...)
    if not invDebug:GetBool() then return end
    local who = IsValid(ply) and (ply:Nick() .. "#" .. ply:EntIndex()) or "world"
    print(("sv_inventory.lua:" .. fmt):format(who, ...))
end


local META = getmetatable("PLAYER")
META.inventory = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}
META.armors = {}

function hg.CreateInv(ply)
    InvDbg(ply, "hg.CreateInv")
    ply.inventory = {}
    local inv = ply.inventory
    inv.Weapons = {}
    for i, wep in ipairs(ply:GetWeapons()) do
        if blackList[wep:GetClass()] then continue end
        inv.Weapons[wep:GetClass()] = wep--wep.GetInfo and wep:GetInfo() or true
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

    local sling = inv.Weapons["hg_sling"] -- Вот бы все это автоматизировать
    local kastet = inv.Weapons["hg_brassknuckles"]
    local flashlight = inv.Weapons["hg_flashlight"]

    inv.Weapons = {}

    for i, wep in pairs(ply:GetWeapons()) do
        if blackList[wep:GetClass()] then continue end
        if not isDead then
            inv.Weapons[wep:GetClass()] = wep--wep.GetInfo and wep:GetInfo() or true
        else
            ply.nohook = true
            ply:DropWeapon(wep)

            wep:SetNoDraw(true)
            wep:DrawShadow(false)
            wep:AddSolidFlags(FSOLID_NOT_SOLID)

            local rag = ply:GetNWEntity("RagdollDeath")

            if IsValid(rag) then
                wep:SetPos(rag:GetPos() + vector_up * - 10000)
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
            ply:ChatPrint("Вы прикрепили ремень к оружию.")
        else
            local sling = ents.Create("hg_sling")
            sling:SetPos(ply:EyePos())
            sling:SetVelocity(ply:GetAimVector() * 5)
            sling:Spawn()
            ply:ChatPrint("Вы отсоединили ремень, к которому было прикреплено оружие.")
       
        end
    end

    ply:SetNetVar("Inventory", inv)
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

hook.Add("PlayerAmmoChanged", "homigrad-inventory", function(ply,ammoID,oldcount,newcount)
    if not ply.inventory then return end
    ply.inventory.Ammo = ply:GetAmmo()
    ply:SetNetVar("Inventory", ply.inventory)

    if game.GetAmmoName(ammoID) == "Grenade" then

        local wep = ply:Give("weapon_hg_hl2nade_tpik")
        wep.DontEquipInstantly = true
        wep.count = newcount-oldcount
        ply:SetAmmo(0,ammoID)

        timer.Simple(0.1,function()
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

    timer.Simple(0.1,function()
        if not IsValid(wep) then return end
        if not IsValid(ply) then return end
        local ent = IsValid(ply:GetNWEntity("RagdollDeath")) and ply:GetNWEntity("RagdollDeath") or ply.FakeRagdoll
        if not IsValid(ent) then return end
        local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")
        local handpos,handang = ent:GetPos(),ent:GetAngles()
        if bon then
            local phys = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bon))
            if IsValid(phys) then
                handpos = phys:GetPos()
                handang = phys:GetAngles()
            end
        end

        local localpos,localang = LocalToWorld(wep.WorldPos and wep.WorldPos + Vector(3.5,0,0) or vector_origin,wep.WorldAng or angle_zero,handpos,handang)
        localang:RotateAroundAxis(localang:Forward(),180)
        wep:SetPos(localpos)
        wep:SetAngles(localang)
        wep:SetVelocity(vector_origin)
        wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local physbone = ent:TranslateBoneToPhysBone(bon)
        local physbonetorso = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))

        local cons = constraint.Weld(wep, ent, 0, physbone, 600, true, false)

        if math.random(1,10) <= 2 then
            timer.Simple(4, function()
                timer.Simple(0, function()
                    local cons2 = constraint.NoCollide(wep, ent, 0, 0)
                end)
                if IsValid(cons) then
                    cons:Remove()
                    cons = nil
                end
            end)
        end

        local enta = ply:Alive() and (ply.organism and !ply.organism.otrub) and ply or ent
        local inv = enta:GetNetVar("Inventory",{})
        if not inv["Weapons"] then return end
        if inv["Weapons"]["hg_sling"] and ishgweapon(wep) and not wep:IsPistolHoldType() then
            local rope = constraint.Rope(wep,ent,0,physbonetorso,vector_origin,vector_origin,10,5,0,0,"null",true,color_white)
            wep.sling = true
            ent.rope_attach = wep
            inv["Weapons"]["hg_sling"] = nil
            enta:SetNetVar("Inventory",inv)
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

function hg.TransferItems(ply,ragdoll)
	if IsValid(ragdoll) then
		local inv = ply:GetNetVar("Inventory",{})
		--if inv["Weapons"] then
		--	for wep,tbl in pairs(inv["Weapons"]) do
		--		local weapon = weapons.Get(wep)
		--		if weapon and weapon.holsteredBone and not weapon.shouldntDrawHolstered then
		--			tbl[3] = true
		--		end
		--	end
		--end
		ragdoll.inventory = inv
		ragdoll:SetNetVar("Inventory",ragdoll.inventory)
		-- ragdoll:SetNetVar("zb_Scrappers_RaidMoney",ply:GetNetVar("zb_Scrappers_RaidMoney"))

		hg.CreateInv(ply)
		ply:SetNetVar("Inventory",{})
		ply.inventory = ply:GetNetVar("Inventory",{})

        hook.Run("ItemsTransfered",ply,ragdoll)

		ragdoll:SetNetVar("Armor",ply.armors)
		ragdoll.armors = ragdoll:GetNetVar("Armor",{})
		ragdoll:SetNetVar("HideArmorRender", ply:GetNetVar("HideArmorRender", false))
		
		ply:SetNetVar("Armor",{})
		ply.armors = ply:GetNetVar("Armor",{})
		
		hg.SyncWeapons()
	end
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

local function GetEntInv(ent)
    if not IsValid(ent) then return end

    local inv = ent.inventory
    if not inv then
        inv = ent:GetNetVar("Inventory")
        if inv then ent.inventory = inv end
    end

    return inv
end

local function SyncEntInvNet(ent, receiver)
    local inv = GetEntInv(ent)
    if inv then ent:SetNetVar("Inventory", inv) end
    if ent.armors then ent:SetNetVar("Armor", ent.armors) end
    if receiver and IsValid(ent) then
        if inv then ent:SendNetVar("Inventory", receiver) end
        if ent.armors then ent:SendNetVar("Armor", receiver) end
    end
end

local function IsLootContainer(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() or ent:IsRagdoll() then return true end
    if not string.find(ent:GetClass() or "", "prop_") then return false end
    local model = string.lower(ent:GetModel() or "")
    local hasLootBoxes = istable(hg.loot_boxes)
    local isLootModel = hasLootBoxes and hg.loot_boxes[model] ~= nil
    if invDebug:GetBool() then
        InvDbg(nil, "is_loot_container model=%s class=%s loot_boxes=%s in_loot=%s", model, ent:GetClass() or "nil", tostring(hasLootBoxes), tostring(isLootModel))
    end
    return isLootModel
end

local function CanLootEnt(ent)
    if not IsValid(ent) then return false end
    if not ent:IsPlayer() then return true end

    if ent:Alive() then
        return ent.organism and ent.organism.otrub and IsValid(ent.FakeRagdoll)
    end

    return true
end

local functions = {
    ["Weapons"] = function(ply, ent, wep)
        local inv = GetEntInv(ent)
        if not inv or not inv.Weapons then return end

        if (ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == wep) then return end
        if not inv.Weapons[wep] then return end

        --local weapon = weapons.Get(wep)
        --if not weapon then return end
        
        local weapon
        local weaponIsEnt = (not isbool(inv.Weapons[wep])) and IsValid(inv.Weapons[wep]) and inv.Weapons[wep]:IsWeapon()
        --print(weaponIsEnt)
        if not weaponIsEnt then
            weapon = ents.Create(wep)
            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory != 1)
            weapon.IsSpawned = true
            weapon.init = true
            --weapon.init = true--<^разве это не одно и то же?
            weapon:Spawn()
            weapon:SetPos(ent:GetPos())
            weapon:SetAngles(ent:GetAngles())
            
            local tbl = inv.Weapons[wep]
            if weapon.SetInfo then weapon:SetInfo(tbl) end
        else
            weapon = inv.Weapons[wep]
            weapon.DontEquipInstantly = (not weapon.NoHolster) and (weapon.weaponInvCategory != 1)

            weapon:SetParent( NULL )
            weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            weapon:SetAngles( ent:GetAngles() )
            weapon:SetNoDraw( false )
            weapon:DrawShadow( true )
            weapon:RemoveSolidFlags(FSOLID_NOT_SOLID)
            --

            --local tbl = ent.inventory.Weapons[wep]
            --if weapon.SetInfo then weapon:SetInfo(tbl) end
        end

        --print(weapon:GetPos())

        inv.Weapons[wep] = nil
        ent.inventory = inv

        if ent:IsPlayer() then
            if weaponIsEnt then
                ent:DropWeapon(weapon)
                weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            else
                ent:StripWeapon(wep)
            end
        end

        ply:DropObject()

        if not weapon:IsWeapon() then weapon:Use(ply) return end
        
        weapon.IsSpawned = false
        weapon.init = false

        if not hook.Run("PlayerCanPickupWeapon",ply,weapon) then 
            --print("huy")
            weapon.IsSpawned = true weapon.init = true 
            weapon:SetPos(ply:EyePos())
            return
        end
        
        if IsValid(weapon) and weapon:IsWeapon() then
            ply:PickupWeapon(weapon)
        end

        if not weapon.DontEquipInstantly then timer.Simple(0,function() ply:SelectWeapon(weapon:GetClass()) end) end
    end,
    ["Ammo"] = function(ply, ent, ammo, amt)
        local inv = GetEntInv(ent)
        if not inv or not inv.Ammo then return end

        local amt2 = inv.Ammo[tonumber(ammo)]
        if not amt2 or amt != amt2 then return end

        ply:GiveAmmo(amt2, game.GetAmmoName(ammo), true)
        if ent:IsPlayer() then
            ent:SetAmmo(0, game.GetAmmoName(ammo))
        else
            inv.Ammo[tonumber(ammo)] = nil
        end
        ent.inventory = inv
    end,
    ["Armor"] = function(ply, ent, placement, armor)
        if hg.armor[placement][armor].nodrop then return end
        if (not ent.armors[placement]) or (ent.armors[placement] ~= armor) or ply.armors[placement] then return end
        if !hg.AddArmor(ply, armor) then return end
        ent.armors[placement] = nil

        if placement == "face" and ent:GetNetVar("zableval_masku", false) and armor != "nightvision1" then
            ply:SetNetVar("zableval_masku", true)
            ent:SetNetVar("zableval_masku", false)
        end

        hook.Run("ItemTransfer",ply, ent, placement, armor)
    end,
    ["Attachments"] = function(ply, ent, att)
        local inv = GetEntInv(ent)
        if not inv or not inv.Attachments then return end

        att = tonumber(att)
        if not inv.Attachments[att] then return end
        ply.inventory.Attachments[#ply.inventory.Attachments + 1] = inv.Attachments[att]
        inv.Attachments[att] = nil
        ent.inventory = inv
    end,
    -- ["Money"] = function(ply, ent)
    --     local money = ent:GetNetVar("zb_Scrappers_RaidMoney", 0)
    --     ply:SetNetVar("zb_Scrappers_RaidMoney", ply:GetNetVar("zb_Scrappers_RaidMoney", 0) + money)
    --     ent:SetNetVar("zb_Scrappers_RaidMoney", 0)
    -- end,
}

local function BuildLootTakeKey(ent, tblIndex, thing)
    if not IsValid(ent) then return "" end
    return ent:EntIndex() .. "|" .. tblIndex .. "|" .. thing
end

local function GetLootTakeDuration(tblIndex, thing)
    if tblIndex == "Weapons" then
        local swep = weapons.Get(thing)
        local weight = swep and tonumber(swep.weight)
        if weight ~= nil then
            return math.Clamp(weight, 0, 5)
        end
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

    if not IsValid(ent) or not IsValid(ply) then return end
    if not CanLootEnt(ent) then return end
    if ent:GetPos():Distance(ply:GetPos()) > 125 then return end

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
net.Receive("ply_take_item", function(_, ply)
    local tblIndex = net.ReadString()
    local thing = net.ReadString()
    local tbl = net.ReadTable()
    local ent = net.ReadEntity()

    if not IsValid(ent) or not IsValid(ply) then return end
    if not CanLootEnt(ent) then return end
    if ent:GetPos():Distance(ply:GetPos()) > 125 then return end

    local key = BuildLootTakeKey(ent, tblIndex, thing)
    local unlockTime = ply.lootTakePending and ply.lootTakePending[key]
    if not unlockTime or unlockTime > CurTime() then return end
    if (ply.cooldown_takeitem or 0) > CurTime() then return end

    ply.cooldown_takeitem = CurTime() + 0.3
    ply.lootTakePending[key] = nil

    local func = functions[tblIndex]
    if func then func(ply, ent, thing, unpack(tbl)) end
    SyncEntInvNet(ent)
    ply:SetNetVar("Inventory", ply.inventory)
    ply:SyncArmor()
    ent:SyncArmor()
end)

util.AddNetworkString("should_open_inv")
local playerMeta = FindMetaTable("Player")
function playerMeta:OpenInventory(ent)
    if not IsValid(ent) then
        InvDbg(self, "open_inventory blocked: invalid entity")
        return
    end
    if not CanLootEnt(ent) then
        InvDbg(self, "open_inventory blocked: CanLootEnt=false class=%s model=%s", ent:GetClass() or "nil", string.lower(ent:GetModel() or ""))
        return
    end

    hook.Run("ZB_InventoryChecked", self, ent)

    local inv = GetEntInv(ent)
    if not inv and IsLootContainer(ent) then
        -- Fallback: if loot hook did not populate inventory, create empty container anyway.
        ent.inventory = {Weapons = {}, Ammo = {}, Attachments = {}}
        ent.armors = ent.armors or {}
        ent:SetNetVar("Inventory", ent.inventory)
        ent:SetNetVar("Armor", ent.armors)
        inv = ent.inventory
        InvDbg(self, "fallback inventory created class=%s model=%s", ent:GetClass() or "nil", string.lower(ent:GetModel() or ""))
    end

    if not inv then
        InvDbg(self, "open_inventory blocked: no inventory after ZB_InventoryChecked class=%s model=%s", ent:GetClass() or "nil", string.lower(ent:GetModel() or ""))
        return
    end

    hook.Run("ZB_InventoryOpened", self, ent)
    if ent:IsPlayer() and ent:Alive() then hg.RenewInv(ent) end
    if self:IsPlayer() then hg.RenewInv(self) end

    SyncEntInvNet(ent, self)
    self.cooldown_takeitem = CurTime() + 0.3

    net.Start("should_open_inv")
    net.WriteEntity(ent)
    net.WriteTable(inv)
    net.WriteTable(ent.armors or ent:GetNetVar("Armor") or {})
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

hook.Add("Player Think", "loot-fellows",function(ply)
    if not ply:Alive() then return end
    ply.keypressed = ply.keypressed or false
    --if not ply:GetLookTrace() then return end

    local use = IsValid(ply.FakeRagdoll) and (ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED) and not ply:KeyDown(IN_ATTACK) and not ply:KeyDown(IN_ATTACK2)) or (not IsValid(ply.FakeRagdoll) and (ply:KeyDown(IN_ATTACK2) and ply:KeyDown(IN_USE)))
    
    if use then
        local trace = hg.eyeTrace(ply, 60)
    
        if not trace then return end
        local ent = trace.Entity
        if not IsValid(ent) then return end

        if ent:IsPlayer() and not ent:Alive() then
            local rag = ent:GetNWEntity("RagdollDeath")
            if IsValid(rag) then ent = rag end
        else
            ent = IsValid(hg.RagdollOwner(ent)) and hg.RagdollOwner(ent) or ent
        end

        if ent:IsPlayer() and not (ent.organism and ent.organism.otrub) then
            if not ply.keypressed then ply:ChatPrint("Не могу обыскать человека пока он в сознании.") end
            ply.keypressed = true
            return
        end
		local _ply, _ent, canloot = hook.Run("ZB_CanLootInventory", ply, ent, nil)
		if canloot ~= nil and canloot == false then
            InvDbg(ply, "blocked by ZB_CanLootInventory class=%s model=%s", ent:GetClass() or "nil", string.lower(ent:GetModel() or ""))
			ply.keypressed = true
			return
		end
    
        if invDebug:GetBool() then
            local model = string.lower(ent:GetModel() or "")
            InvDbg(ply, "attempt open class=%s model=%s has_inv=%s is_loot=%s loot_boxes=%s", ent:GetClass() or "nil", model, tostring(GetEntInv(ent) ~= nil), tostring(IsLootContainer(ent)), tostring(istable(hg.loot_boxes)))
        end

        if not ply.keypressed then ply:OpenInventory(ent) end
        
        ply.keypressed = true
    else
        ply.keypressed = false
    end
end)

--// Prop inventory example
--[[
	local pos = Entity(1):GetEyeTrace().HitPos
	local ent = ents.Create("prop_physics")
	ent:SetModel("models/props_interiors/Furniture_Desk01a.mdl")
	ent:SetPos(pos)
	ent:Spawn()
	ent.inventory = {}
	local wep = "weapon_ar15"
	local weapon = weapons.Get(wep)
	ent.inventory.Weapons = {[wep] = {30,hg.ClearAttachments(wep)}}
	hg.SetAttachment(ent.inventory.Weapons[wep][2],"supressor2",wep)
	ent:SetNetVar("Inventory",ent.inventory)
]]