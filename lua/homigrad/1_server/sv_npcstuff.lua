local CurTime, timer, math, table, Angle, Vector, IsValid, LerpAngle, LerpVector = CurTime, timer, math, table, Angle, Vector, IsValid, LerpAngle, LerpVector
local math_random, math_Rand = math.random, math.Rand

--\\ NPCs with organism (loot table optional)
	local organismNPCs = {
		["npc_metropolice"] = true,
		["npc_combine_s"] = true,
		["npc_citizen"] = true,
		["npc_zombie"] = true,
		["npc_zombie_torso"] = true,
		["npc_fastzombie"] = true,
		["npc_poisonzombie"] = true,
		["npc_zombine"] = true,
		["zbase_armored_zombie"] = true,
		["zbase_armored_zombie_torso"] = true,
		["zbase_armored_zombine"] = true,
		["zbase_combine_zombie"] = true,
		["zbase_combine_zombie_torso"] = true,
		["zbase_fast_zombie"] = true,
		["zbase_fast_zombie_torso"] = true,
		["zbase_classic_female_zombie"] = true,
		["zbase_classic_female_zombie_torso"] = true,
		["zbase_funguscrab_zombie"] = true,
		["zbase_funguscrab_zombie_torso"] = true,
		["zbase_metro_zombie"] = true,
		["zbase_metro_zombie_grenade"] = true,
		["zbase_poison_spitter_zombie"] = true,
		["zbase_poison_spitter_zombie_torso"] = true,
		["zbase_poison_zombie"] = true,
		["zbase_classic_zombie"] = true,
		["zbase_classic_zombie_torso"] = true,
		["zbase_classic_zombine"] = true,
	}

	local lootNPCs = { --// Loot goes here
		["npc_metropolice"] = {
			"weapon_hg_stunstick",
			"weapon_medkit_sh",
			"weapon_bandage_sh",
			"weapon_handcuffs",
			"weapon_walkie_talkie"
		},
		["npc_combine_s"] = {
			"weapon_melee",
			"weapon_hg_hl2nade_tpik",
			"weapon_bandage_sh",
			"weapon_handcuffs"
		},
		["npc_citizen"] = {
			"weapon_smallconsumable",
			"weapon_bandage_sh",
			"weapon_painkillers"
		}
	}

	local funcspawnNPCs = { --// Custom on NPC spawn function goes here
		["npc_combine_s"] = function(ent)
			ent.organism.CantCheckPulse = true

			--// Armor
			ent.armors = {}
			ent.armors["torso"] = "cmb_armor"
			ent.armors["head"] = "cmb_helmet"
			ent:SyncArmor()
		end,
		["npc_metropolice"] = function(ent)
			--// Armor
			ent.armors = {}
			ent.armors["torso"] = "metrocop_armor"
			ent.armors["head"] = "metrocop_helmet"
			ent:SyncArmor()
		end
	}

	local nameNPCs = { --// NPC name and color goes here (visible while looking at & while looting)
		["npc_metropolice"] = {"Metrocop", Vector(0, 100, 255) / 255},
		["npc_combine_s"] = {"Combine", Vector(0, 180, 180) / 255},
		["npc_citizen"] = {"Refugee", Vector(255, 155, 0) / 255}
	}

	local function npcWantsOrganism(ent)
		if not ent:IsNPC() then return false end
		if ent.IsZombieModeNPC then return false end
		if organismNPCs[ent:GetClass()] then return true end
		if ent.IsZBaseNPC or ent:GetNWBool("IsZBaseNPC", false) then return true end
		return false
	end

	local zombieEngineClasses = {
		npc_zombie = true,
		npc_zombie_torso = true,
		npc_fastzombie = true,
		npc_fastzombie_torso = true,
		npc_poisonzombie = true,
		npc_zombine = true,
		zbase_armored_zombie = true,
		zbase_armored_zombie_torso = true,
		zbase_armored_zombine = true,
		zbase_combine_zombie = true,
		zbase_combine_zombie_torso = true,
		zbase_fast_zombie = true,
		zbase_fast_zombie_torso = true,
		zbase_classic_female_zombie = true,
		zbase_classic_female_zombie_torso = true,
		zbase_funguscrab_zombie = true,
		zbase_funguscrab_zombie_torso = true,
		zbase_metro_zombie = true,
		zbase_metro_zombie_grenade = true,
		zbase_poison_spitter_zombie = true,
		zbase_poison_spitter_zombie_torso = true,
		zbase_poison_zombie = true,
		zbase_classic_zombie = true,
		zbase_classic_zombie_torso = true,
		zbase_classic_zombine = true,
	}

	function hg.organism.NpcIsOrganismZombie(npc)
		if not IsValid(npc) or not npc:IsNPC() then return false end
		if npc:Classify() == CLASS_ZOMBIE then return true end

		local cls = npc:GetClass()
		if zombieEngineClasses[cls] then return true end

		local eng = npc.GetEngineClass and npc:GetEngineClass()
		if eng and zombieEngineClasses[eng] then return true end

		return false
	end

	function hg.organism.ZombieLegAmputate(npc, org, limb)
		if not IsValid(npc) or not org or (limb ~= "lleg" and limb ~= "rleg") then return end

		local other = limb == "lleg" and "rleg" or "lleg"

		org.llegamputated = true
		org.rlegamputated = true
		org.lleg = 1
		org.rleg = 1
		org.legstrength = 0
		org.alive = false
		org[other .. "amputated"] = true

		hg.organism.KillNpc(npc)
	end

	function hg.organism.KillNpc(ent)
		if not IsValid(ent) then return end
		if ent:IsPlayer() and ent.Kill then
			ent:Kill()
			return
		end
		if not ent:IsNPC() or not ent.Alive or not ent:Alive() then return end

		if ent:GetMoveType() == MOVETYPE_NONE then
			ent:SetMoveType(MOVETYPE_STEP)
		end

		ent.hgForceKill = true
		ent:SetHealth(0)

		if ent.Fire then
			ent:Fire("Die", "", 0)
		end

		if not ent:Alive() then return end

		local att = ent:GetEnemy()
		if not IsValid(att) then att = game.GetWorld() end

		local dmg = DamageInfo()
		dmg:SetAttacker(att)
		dmg:SetInflictor(att)
		dmg:SetDamage(99999)
		dmg:SetDamageType(bit.bor(DMG_SLASH, DMG_NEVERGIB))
		dmg:SetDamageForce(Vector(0, 0, 100))
		dmg:SetDamagePosition(ent:WorldSpaceCenter())
		ent.hgForceKill = true
		ent:TakeDamageInfo(dmg)
	end

	local function initNpcOrganism(ent)
		if not IsValid(ent) or ent.organism or not npcWantsOrganism(ent) then return end

		hg.organism.Add(ent)
		hg.organism.Clear(ent.organism)
		ent.organism.fakePlayer = true

		local class = ent:GetClass()
		if funcspawnNPCs[class] then
			funcspawnNPCs[class](ent)
		end

		if nameNPCs[class] then
			ent:SetNWString("PlayerName", nameNPCs[class][1])
			ent:SetNWVector("PlayerColor", nameNPCs[class][2])
			ent.GetPlayerName = function()
				return nameNPCs[class][1]
			end
		end
	end

	local hg_noorganismnpcs = CreateConVar("hg_noorganismnpcs", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "NPCs will NOT have organism system like the players", 0, 1)
	hook.Add("OnEntityCreated", "npcorg", function(ent)
		if hg_noorganismnpcs:GetBool() then return end

		timer.Simple(0, function()
			if hg_noorganismnpcs:GetBool() then return end
			if not IsValid(ent) then return end
			initNpcOrganism(ent)
		end)
	end)

	

	local function getNpcOrganism(ent)
		if not IsValid(ent) then return end
		if ent.organism then return ent.organism end
		local fake = ent.hgFakeRagdoll
		if IsValid(fake) and fake.organism then return fake.organism end
	end

	local function transferNpcOrganismToRag(ent, rag)
		if not IsValid(ent) or not IsValid(rag) then return end
		if rag.organism then return end

		local srcOrg = getNpcOrganism(ent)
		if not srcOrg then return end

		local newOrg = hg.organism.Add(rag)
		table.Merge(newOrg, srcOrg)

		hook.Run("RagdollDeath", ent, rag)

		if zb and zb.net and zb.net.list and zb.net.list[ent] then
			zb.net.list[rag] = zb.net.list[rag] or {}
			table.Merge(zb.net.list[rag], zb.net.list[ent])
		end

		newOrg.alive = false
		newOrg.owner = rag
		rag:CallOnRemove("organism", hg.organism.Remove, rag)
		rag.fullsend = true
		hg.send_bareinfo(newOrg)

		ent.organism = nil

		local fake = ent.hgFakeRagdoll
		if IsValid(fake) and fake ~= rag then
			fake.organism = nil
			SafeRemoveEntity(fake)
			ent.hgFakeRagdoll = nil
			if ent.SetNWEntity then
				ent:SetNWEntity("hgFakeRagdoll", NULL)
			end
		end
	end

	hook.Add("CreateEntityRagdoll", "npcloot", function(ent, rag)
		local class = ent:GetClass()
		local loot = lootNPCs[class]

		rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		if IsValid(ent) and IsValid(rag) and ent:IsNPC() and loot and #loot > 0 then
			rag.inventory = {}
			rag.inventory.Weapons = {}

			transferNpcOrganismToRag(ent, rag)

			rag.armors = ent.armors

			for k, wep in pairs(loot) do
				local weapon = weapons.Get(wep)
				if rag.inventory.Weapons and rag.inventory.Weapons[wep] then return end
				rag.inventory.Weapons = rag.inventory.Weapons or {}
				rag.inventory.Weapons[wep] = weapon and weapon.GetInfo and weapon:GetInfo() or true
				rag:SetNetVar("Inventory", rag.inventory)
			end

			if nameNPCs[class] then
				ent:SetNWString("PlayerName", nameNPCs[class][1])
				ent:SetNWVector("PlayerColor", nameNPCs[class][2])
				rag:SetNWString("PlayerName", nameNPCs[class][1])
				rag:SetNWVector("PlayerColor", nameNPCs[class][2])
			end
		end
	end)

	hook.Add("CreateEntityRagdoll", "hg_npc_organism_rag", function(ent, rag)
		if hg_noorganismnpcs:GetBool() then return end
		if not IsValid(ent) or not IsValid(rag) or not ent:IsNPC() then return end
		if not getNpcOrganism(ent) then return end

		if ent.IsZBaseNPC then
			ent.ZBase_WasGibbedOnDeath = false
		end
		transferNpcOrganismToRag(ent, rag)
	end, HOOK_HIGH)

--\\ Tough NPCs
	local hg_toughnpcs = CreateConVar("hg_toughnpcs", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Toggle more health for npcs", 0, 1)
	local npcToBuff = {
		["npc_metropolice"] = 100,
		["npc_combine_s"] = 150,
		["npc_citizen"] = 100,
		["npc_kleiner"] = 100,
		["npc_magnusson"] = 100,
		["npc_eli"] = 100,
		["npc_odessa"] = 100,
		["npc_breen"] = 100,
		["npc_zombie"] = 120,
		["npc_fastzombie"] = 90,
		["npc_headcrab"] = 50,
		["npc_headcrab_fast"] = 40,
		["npc_headcrab_black"] = 70,
		["npc_fastzombie_torso"] = 80,
		["npc_zombie_torso"] = 110,
		["npc_manhack"] = 50,
		["npc_antlion_grub"] = 20,
	}
	hook.Add("OnEntityCreated", "toughnpcs", function(ent)
		timer.Simple(0.2, function()
			if hg_toughnpcs:GetBool() and IsValid(ent) and ent:IsNPC() and npcToBuff[ent:GetClass()] then
				ent:SetHealth(npcToBuff[ent:GetClass()])
				ent:SetMaxHealth(npcToBuff[ent:GetClass()])
				ent:SetPlaybackRate(2)
				ent:SetKeyValue("m_flPlaybackSpeed", 2)
			end
		end)
	end)
--//


--\\ Give our guns to NPCs
	local function addNPCweps()
		local weaponlist = weapons.GetList()
		local based = weapons.IsBasedOn -- RESPECT
		for _, wep in ipairs(weaponlist) do
			local classname = wep.ClassName
			if (based(classname, "homigrad_base") or based(classname, "weapon_melee") or classname == "weapon_melee" or based(classname, "weapon_medkit_sh") or classname == "weapon_medkit_sh") and wep.Spawnable then
				list.Add("NPCUsableWeapons", { 
					class = classname,
					title = wep.PrintName,
					category = wep.Category or "ZCity Other"
				})
			end
		end
	end

	hook.Add("Initialize", "InitAddNPCweps", addNPCweps)
	hook.Add("InitPostEntity", "InitPostAddNPCweps", addNPCweps)
--//
