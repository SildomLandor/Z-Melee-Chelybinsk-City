-- HL2 / legacy ZBase slots -> homigrad_base (before zbase npc_base loads)

local hl2ToHg = {
	["weapon_ar2"] = "weapon_osipr",
	["weapon_smg1"] = "weapon_mp7",
	["weapon_pistol"] = "weapon_glock17",
	["weapon_shotgun"] = "weapon_m4super",
	["weapon_357"] = "weapon_deagle",
	["weapon_rpg"] = "weapon_hg_rpg",
	["weapon_crossbow"] = "weapon_hg_crossbow",
	["weapon_crowbar"] = "weapon_hg_crowbar_gordon",
	["weapon_stunstick"] = "weapon_hg_stunstick",
	["weapon_alyxgun"] = "weapon_ar15",
	["weapon_annabelle"] = "weapon_doublebarrel_short",
	["weapon_357_hl1"] = "weapon_revolver2",
	["weapon_glock_hl1"] = "weapon_glock17",
	["weapon_shotgun_hl1"] = "weapon_saiga12",
	["weapon_zb_canalspipe"] = "weapon_leadpipe",
	["weapon_elitepolice_mp5k"] = "weapon_mp7",
}

local zbToHl2 = {
	["weapon_zb_ar2"] = "weapon_ar2",
	["weapon_zb_357"] = "weapon_357",
	["weapon_zb_crossbow"] = "weapon_crossbow",
	["weapon_zb_crowbar"] = "weapon_crowbar",
	["weapon_zb_pistol"] = "weapon_pistol",
	["weapon_zb_rpg"] = "weapon_rpg",
	["weapon_zb_shotgun"] = "weapon_shotgun",
	["weapon_zb_smg1"] = "weapon_smg1",
	["weapon_zb_stunstick"] = "weapon_stunstick",
	["weapon_zb_alyxgun"] = "weapon_alyxgun",
	["weapon_zb_annabelle"] = "weapon_annabelle",
	["weapon_zb_357_hl1"] = "weapon_357_hl1",
	["weapon_zb_glock_hl1"] = "weapon_glock_hl1",
	["weapon_zb_shotgun_hl1"] = "weapon_shotgun_hl1",
}

ZBaseEngineWeaponReplacements = {}
ZBaseEngineWeaponFlipped = {}

for hl2, hg in pairs(hl2ToHg) do
	ZBaseEngineWeaponReplacements[hl2] = hg
	ZBaseEngineWeaponFlipped[hg] = hl2
end

for zb, hl2 in pairs(zbToHl2) do
	ZBaseEngineWeaponReplacements[zb] = ZBaseEngineWeaponReplacements[hl2]
end

ZBaseHomigradNPCWeapons = {}
for _, hg in pairs(hl2ToHg) do
	ZBaseHomigradNPCWeapons[#ZBaseHomigradNPCWeapons + 1] = hg
end

ZBaseNPCWeps = ZBaseHomigradNPCWeapons

if SERVER then
	hook.Add("InitPostEntity", "ZBaseHomigradWeps", function()
		for hl2, hg in pairs(ZBaseEngineWeaponReplacements) do
			local tbl = weapons.GetStored(hg)
			if tbl and not tbl.EngineCloneClass then
				tbl.EngineCloneClass = hl2
			end
		end
	end)
end
