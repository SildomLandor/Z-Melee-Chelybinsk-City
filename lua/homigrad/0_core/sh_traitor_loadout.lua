hg = hg or {}
local TL = {}
hg.TraitorLoadout = TL

TL.MaxPoints = 30
TL.ConVarName = "hmcd_traitor_loadout"

TL.Items = {
	["weapon_pl15"] = {cost = 15, name = "ПЛ-15"},
	["weapon_buck200knife"] = {cost = 6, name = "BUCK 200 Нож"},
	["weapon_sogknife"] = {cost = 3, name = "SOG Нож"},
	["weapon_fiberwire"] = {cost = 3, name = "Удавка"},
	["weapon_hg_rgd_tpik"] = {cost = 6, name = "РГД-5"},
	["weapon_adrenaline"] = {cost = 4, name = "Эпипен"},
	["weapon_pepperspray_tpik"] = {cost = 4, name = "Перцовый балончик"},
	["weapon_hg_shuriken"] = {cost = 2, name = "Сюрикен"},
	["weapon_hg_smokenade_tpik"] = {cost = 3, name = "Дымовая граната"},
	["weapon_traitor_ied"] = {cost = 6, name = "СВУ (Бомба)"},
	["weapon_traitor_poison1"] = {cost = 3, name = "Шприц с тетродотоксином"},
	["weapon_traitor_poison2"] = {cost = 2, name = "Ампула с Ви-Икс"},
	["weapon_traitor_poison4"] = {cost = 3, name = "Ампула с Кураре"},
	["weapon_traitor_poison3"] = {cost = 6, name = "Баночка Цианида"},
	["weapon_traitor_suit"] = {cost = 5, name = "Маскировачный костюм"},
	["weapon_hg_jam"] = {cost = 1, name = "Блокиратор двери"},
	["weapon_p22"] = {cost = 8, name = "Walter П22"},
	["weapon_taser"] = {cost = 8, name = "Электрошокер"},
	["weapon_beartrap_homigrad"] = {cost = 8, name = "Капкан"},
}

TL.Addons = {
	["weapon_p22_extra_mag"] = {cost = 2, name = "П22 Дополнительный магазин", parent = "weapon_p22", extraMag = 1},
	["weapon_p22_silencer"] = {cost = 2, name = "П22 Глушитель", parent = "weapon_p22", att = "supressor4"},
	["weapon_pl15_extra_mag"] = {cost = 3, name = "ПЛ-15 Дополнительный магазин", parent = "weapon_pl15", extraMag = 1},
	["weapon_pl15_silencer"] = {cost = 2, name = "ПЛ-15 Глушитель", parent = "weapon_pl15", att = "supressor4"},
}

TL.WeaponAddonOrder = {
	["weapon_p22"] = {"weapon_p22_extra_mag", "weapon_p22_silencer"},
	["weapon_pl15"] = {"weapon_pl15_extra_mag", "weapon_pl15_silencer"},
}

TL.Skillsets = {
	["none"] = {cost = 0, name = "Мокрушник", desc = "Без особых навыков.", objective = "Убей всех выбранным снаряжением."},
	["infiltrator"] = {cost = 10, name = "Саботажник", desc = "Может сворачивать шеи, и переодеваться в одежду трупов.", objective = "Эксперт по диверсиям. Действуй тихо, убирай по одному."},
	["diversant"] = {cost = 11, name = "Диверсант", desc = "Крадёт снаряжение со спины, режет горло острым предметом, переодевается в трупы. Тихий бег без следов. Рация-приманка и парализующий шприц.", objective = "Действуй из тени. Разъединяй, обезвреживай, заманивай."},
	["assassin"] = {cost = 12, name = "Ассасин", desc = "Быстро обезоруживает людей, опытен в стрельбе.", objective = "Разоружай стрелка и бей его же оружием."},
	["chemist"] = {cost = 3, name = "Химик", desc = "Устойчив к химикатам, обнаруживает химические вещества в воздухе.", objective = "Отравляй всё, что движется."},
	["martial_artist"] = {cost = 30, name = "Мастер боевых искусств", desc = "Начинает с нунчаками. Усиленные кулаки, ноги и урон в ближнем бою. +40% к выносливости. Может обезоруживать и сворачивать шеи. Без фонарика.", objective = "Твоё тело — оружие. Убей всех.", exclusive = true},
}

TL.WeaponExclusions = {
	["weapon_buck200knife"] = {["weapon_sogknife"] = true},
	["weapon_sogknife"] = {["weapon_buck200knife"] = true},
}

TL.SubRoleBySkillset = {
	standard = {
		none = "traitor_custom",
		infiltrator = "traitor_infiltrator",
		diversant = "traitor_diversant",
		assassin = "traitor_assasin",
		chemist = "traitor_chemist",
		martial_artist = "traitor_martial_artist",
	},
	soe = {
		none = "traitor_custom_soe",
		infiltrator = "traitor_infiltrator_soe",
		diversant = "traitor_diversant_soe",
		assassin = "traitor_assasin_soe",
		chemist = "traitor_chemist",
		martial_artist = "traitor_martial_artist_soe",
	},
}

TL.SubRoleLocales = {
	traitor_default = {
		name = "Дефолт",
		desc = "Стандартный набор: оружие, яды, гранаты, нож и сигнальный пистолет.",
		objective = "Полный стандартный набор. Убей всех.",
	},
	traitor_default_soe = {
		name = "Дефолт",
		desc = "Стандартный набор ЧП: глушитель, нож, гранаты, яды и взрывчатка.",
		objective = "Полный стандартный набор. Убей всех.",
	},
	traitor_zombie = {
		name = "Зомби",
		desc = "Тихо заражает игроков. Лечится врачом. Без оружия, выглядит как обычный человек.",
		objective = "Зарази всех. Избегай врача.",
	},
}

TL._skillsetBySubRole = {}
for _, map in pairs(TL.SubRoleBySkillset) do
	for skillset, subRole in pairs(map) do
		TL._skillsetBySubRole[subRole] = skillset
	end
end

function TL.GetSubRoleLabel(subRoleId)
	local skillset = TL._skillsetBySubRole[subRoleId]
	if skillset and TL.Skillsets[skillset] then
		return TL.Skillsets[skillset].name
	end
	local loc = TL.SubRoleLocales[subRoleId]
	return loc and loc.name
end

function TL.GetSubRoleDescription(subRoleId)
	local skillset = TL._skillsetBySubRole[subRoleId]
	if skillset and TL.Skillsets[skillset] then
		return TL.Skillsets[skillset].desc
	end
	local loc = TL.SubRoleLocales[subRoleId]
	return loc and loc.desc
end

function TL.GetSubRoleObjective(subRoleId)
	local skillset = TL._skillsetBySubRole[subRoleId]
	if skillset and TL.Skillsets[skillset] then
		local ss = TL.Skillsets[skillset]
		return ss.objective or ss.desc
	end
	local loc = TL.SubRoleLocales[subRoleId]
	return loc and loc.objective
end

function TL.ApplySubRoleLocales(modeTbl)
	local MODE = modeTbl or (zb and zb.modes and zb.modes.hmcd)
	if not MODE or not MODE.SubRoles then return end

	for subRoleId, info in pairs(MODE.SubRoles) do
		local name = TL.GetSubRoleLabel(subRoleId)
		if name then info.Name = name end
	end
end

hook.Add("InitPostEntity", "TL_ApplySubRoleLocales", function()
	TL.ApplySubRoleLocales()
end)

if SERVER then
	util.AddNetworkString("TL_SyncLoadout")

	net.Receive("TL_SyncLoadout", function(_, ply)
		if not IsValid(ply) then return end
		local str = net.ReadString()
		if not isstring(str) or #str > 1024 then return end
		ply.TL_LoadoutStr = str
	end)
end

if CLIENT then
	TL.ClientConVar = CreateClientConVar(TL.ConVarName, "", true, true)

	local function TL_PushLoadout(str)
		if TL.ClientConVar then
			pcall(TL.ClientConVar.SetString, TL.ClientConVar, str)
		end
		if not IsValid(LocalPlayer()) then return end
		net.Start("TL_SyncLoadout")
			net.WriteString(str)
		net.SendToServer()
	end

	hook.Add("InitPostEntity", "TL_SyncLoadoutOnJoin", function()
		local data = file.Read("meleecity_traitor_loadout.txt", "DATA")
		if isstring(data) and data ~= "" then
			TL_PushLoadout(data)
		end
	end)

	function TL.PushLoadout(str)
		if not isstring(str) then return end
		TL_PushLoadout(str)
	end
end

function TL.HasWeaponConflict(selected, weaponId)
	local ex = TL.WeaponExclusions[weaponId]
	if ex then
		for _, wid in ipairs(selected) do
			if wid ~= weaponId and ex[wid] then return true end
		end
	end
	for _, wid in ipairs(selected) do
		if wid ~= weaponId then
			local other = TL.WeaponExclusions[wid]
			if other and other[weaponId] then return true end
		end
	end
	return false
end

function TL.Parse(str)
	if not isstring(str) or str == "" then
		return {weapons = {}, skillset = "none"}
	end
	local ok, tbl = pcall(util.JSONToTable, str)
	if ok and istable(tbl) then return tbl end
	return {weapons = {}, skillset = "none"}
end

function TL.Sanitize(raw)
	local out = {weapons = {}, skillset = "none"}
	if type(raw) ~= "table" then raw = {} end

	if type(raw.skillset) == "string" and TL.Skillsets[raw.skillset] then
		out.skillset = raw.skillset
	end

	local skillInfo = TL.Skillsets[out.skillset]
	if skillInfo.exclusive then
		return out
	end

	local pts = skillInfo.cost
	local used = {}
	local order = {}

	if type(raw.weapons) == "table" then
		for k, v in pairs(raw.weapons) do
			local wid = type(v) == "string" and v or (type(k) == "string" and v == true and k)
			if wid and not used[wid] and (TL.Items[wid] or TL.Addons[wid]) then
				used[wid] = true
				order[#order + 1] = wid
			end
		end
	end

	used = {}
	for _, wid in ipairs(order) do
		local info = TL.Items[wid]
		if info and not used[wid] and not TL.HasWeaponConflict(out.weapons, wid) then
			if pts + info.cost <= TL.MaxPoints then
				used[wid] = true
				out.weapons[#out.weapons + 1] = wid
				pts = pts + info.cost
			end
		end
	end

	for _, wid in ipairs(order) do
		local addon = TL.Addons[wid]
		if addon and not used[wid] and used[addon.parent] then
			if pts + addon.cost <= TL.MaxPoints then
				used[wid] = true
				out.weapons[#out.weapons + 1] = wid
				pts = pts + addon.cost
			end
		end
	end

	return out
end

function TL.Encode(loadout)
	local s = util.TableToJSON(loadout)
	if not isstring(s) or s == "" then
		return "{\"weapons\":[],\"skillset\":\"none\"}"
	end
	return s
end

function TL.ResolveSubRole(skillset, modeType)
	local map = TL.SubRoleBySkillset[modeType] or TL.SubRoleBySkillset.standard
	return map[skillset] or map.none
end

function TL.GiveTraitorFlashlight(ply)
	if not IsValid(ply) then return end
	local inv = ply:GetNetVar("Inventory", {})
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true
	ply:SetNetVar("Inventory", inv)
end

function TL.ApplySkillset(ply, skillset, modeType)
	if not IsValid(ply) or not ply.organism then return end

	ply.organism.superfighter = false
	ply.organism.recoilmul = 1
	ply.MeleeDamageMul = nil
	ply.FistsDamageMul = nil

	ply.organism.stamina.range = 220
	ply.organism.stamina.max = 220
	ply.organism.stamina[1] = 220

	if skillset == "assassin" then
		ply.organism.recoilmul = (modeType == "soe") and 0.4 or 0.8
		ply.organism.stamina.range = 300
		ply.organism.stamina.max = 300
		ply.organism.stamina[1] = 300
		TL.GiveTraitorFlashlight(ply)
	elseif skillset == "infiltrator" then
		TL.GiveTraitorFlashlight(ply)
	elseif skillset == "diversant" then
		TL.GiveTraitorFlashlight(ply)
		ply:Give("weapon_traitor_diversant_syringe")
		ply:Give("weapon_traitor_decoy_radio")
	elseif skillset == "chemist" then
		TL.GiveTraitorFlashlight(ply)
		if SERVER and CleanChemicalsOfPlayer then
			CleanChemicalsOfPlayer(ply)
		end
	elseif skillset == "martial_artist" then
		ply.MeleeDamageMul = 2.5
		ply.FistsDamageMul = 2.5
		ply.organism.stamina.range = 154
		ply.organism.stamina.max = 308
		ply.organism.stamina[1] = 308
		ply:Give("weapon_hg_nunchuks")
	elseif skillset == "none" then
		TL.GiveTraitorFlashlight(ply)
	end
end

function TL.ApplyWeapons(ply, weaponList)
	if not IsValid(ply) or not istable(weaponList) then return end

	local given = {}
	for _, class in ipairs(weaponList) do
		if TL.Items[class] and not TL.Addons[class] then
			local wep = ply:Give(class)
			if IsValid(wep) then given[class] = wep end
		end
	end

	for _, class in ipairs(weaponList) do
		local addon = TL.Addons[class]
		if not addon then continue end

		local wep = given[addon.parent]
		if not IsValid(wep) then continue end

		if addon.att and hg and hg.AddAttachmentForce then
			hg.AddAttachmentForce(ply, wep, addon.att)
		elseif addon.extraMag then
			local amt = wep.GetMaxClip1 and wep:GetMaxClip1() or 0
			if amt > 0 then
				ply:GiveAmmo(amt * addon.extraMag, wep:GetPrimaryAmmoType(), true)
			end
		end
	end
end

function TL.WantsDefaultLoot(loadout)
	loadout = loadout or {}
	local skillInfo = TL.Skillsets[loadout.skillset or "none"]
	if skillInfo and skillInfo.exclusive then return false end
	return #(loadout.weapons or {}) == 0
end

function TL.ApplyToTraitor(ply, loadout, modeType)
	if not IsValid(ply) then return end
	loadout = TL.Sanitize(loadout or {})
	TL.ApplySkillset(ply, loadout.skillset, modeType)
	if not TL.Skillsets[loadout.skillset].exclusive then
		TL.ApplyWeapons(ply, loadout.weapons)
	end
	return loadout
end

if CLIENT then
	function TL.SaveLocal(loadout)
		loadout = TL.Sanitize(loadout)
		local dataStr = TL.Encode(loadout)
		file.Write("meleecity_traitor_loadout.txt", dataStr)
		TL.PushLoadout(dataStr)
		return loadout
	end
end

function TL.GetPlayerLoadout(ply)
	if not IsValid(ply) then return TL.Sanitize({}) end
	if CLIENT then
		local str = TL.ClientConVar and TL.ClientConVar:GetString() or ""
		if str == "" then
			str = file.Read("meleecity_traitor_loadout.txt", "DATA") or ""
		end
		return TL.Sanitize(TL.Parse(str))
	end
	local str = ply.TL_LoadoutStr
	if not isstring(str) or str == "" then
		str = ply:GetInfo(TL.ConVarName)
	end
	return TL.Sanitize(TL.Parse(str))
end
