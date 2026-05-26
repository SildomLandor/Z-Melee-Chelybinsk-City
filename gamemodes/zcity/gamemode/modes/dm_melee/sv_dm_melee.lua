local MODE = MODE

local melees = {
	"weapon_buck200knife",
	"weapon_sogknife",
	"weapon_bat",
	"weapon_barbedbat",
	"weapon_melee",
	"weapon_wrench",
	"weapon_pan",
	"weapon_hg_katana",
	"weapon_hg_sledgehammer",
	"weapon_hg_crowbar",
	"weapon_hg_shovel",
	"weapon_hg_machete",
	"weapon_hg_nunchuks",
	"weapon_hg_spear_pro",
	"weapon_tomahawk",
	"weapon_ram",
	"weapon_hg_axe",
}

local meleeSet = {}
for _, cls in ipairs(melees) do
	meleeSet[cls] = true
end
meleeSet.weapon_hg_slayersword = true

local fallbacks = {"weapon_melee", "weapon_pocketknife", "weapon_bat"}

local function hasMeleeWeapon(ply)
	for _, wep in ipairs(ply:GetWeapons()) do
		if meleeSet[wep:GetClass()] then return true end
	end
	return false
end

local function giveRandomMelee(ply)
	local tried = {}

	for _ = 1, #melees do
		local cls = melees[math.random(#melees)]
		if not tried[cls] then
			tried[cls] = true
			local wep = ply:Give(cls)
			if IsValid(wep) then return wep end
		end
	end

	for _, cls in ipairs(fallbacks) do
		local wep = ply:Give(cls)
		if IsValid(wep) then return wep end
	end
end

function MODE:EquipPlayer(ply, trySlayer)
	if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then return false end
	if CurrentRound() ~= self then return false end

	local tag = zb.ROUND_BEGIN or 0
	if ply.zb_dm_melee_loadout == tag and hasMeleeWeapon(ply) then return true end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	local inv = ply:GetNetVar("Inventory", {}) or {}
	inv.Weapons = inv.Weapons or {}
	inv.Weapons.hg_sling = true
	ply:SetNetVar("Inventory", inv)

	ply:Give("weapon_hands_sh")

	if trySlayer then
		local slayer = ply:Give("weapon_hg_slayersword")
		if not IsValid(slayer) then
			giveRandomMelee(ply)
		end
	elseif not hasMeleeWeapon(ply) then
		giveRandomMelee(ply)
	end

	if not ply:HasWeapon("weapon_bandage_sh") then
		ply:Give("weapon_bandage_sh")
	end

	ply:SelectWeapon("weapon_hands_sh")
	ply.zb_dm_melee_loadout = tag
	zb.GiveRole(ply, "Fighter", Color(190, 15, 15))

	timer.Simple(0.1, function()
		if not IsValid(ply) then return end
		ply.noSound = false
		ply:SetSuppressPickupNotices(false)
	end)

	return hasMeleeWeapon(ply)
end

function MODE:RoundStart()
	self.slayerRoll = math.random() < 0.01
	self.slayerGiven = false

	local mode = self

	local function tryAll()
		if CurrentRound() ~= mode then return end

		for _, ply in player.Iterator() do
			local trySlayer = mode.slayerRoll and not mode.slayerGiven
			if mode:EquipPlayer(ply, trySlayer) and trySlayer and hasMeleeWeapon(ply) then
				mode.slayerGiven = true
			end
		end
	end

	tryAll()
	timer.Simple(0, tryAll)
	timer.Simple(0.15, tryAll)
	timer.Simple(0.35, tryAll)
end

hook.Add("PlayerSpawn", "ZB_DMMelee_Loadout", function(ply)
	local mode = CurrentRound()
	if not mode or mode.name ~= "dm_melee" or zb.ROUND_STATE ~= 1 then return end

	timer.Simple(0, function()
		if not IsValid(ply) then return end
		local m = CurrentRound()
		if m and m.EquipPlayer then m:EquipPlayer(ply, false) end
	end)
end)
