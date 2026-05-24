local MODE = MODE
MODE.name = "hmcd"
MODE.PrintName = "Хомисайд"

--\\
MODE.TraitorExpectedAmtBits = 13
--//

--\\Sub Roles
MODE.ConVarName_SubRole_Traitor_SOE = "hmcd_subrole_traitor_soe"
MODE.ConVarName_SubRole_Traitor = "hmcd_subrole_traitor"

if(CLIENT)then
	MODE.ConVar_SubRole_Traitor_SOE = CreateClientConVar(MODE.ConVarName_SubRole_Traitor_SOE, "traitor_default_soe", true, true, "Подроль предателя в режиме ЧП (Homicide)")
	MODE.ConVar_SubRole_Traitor = CreateClientConVar(MODE.ConVarName_SubRole_Traitor, "traitor_default", true, true, "Подроль убийцы в стандартном Homicide")
end

--; TODO
--; Инженер - шахид бомба + иеды

MODE.SubRoles = {
	--=\\Traitor
	--==\\
	--; https://youtu.be/zP7ux8WsYYI?si=S-Uw2EAehGR5WD3D
	["traitor_default"] = {
		Name = "Дефолт",
		Description = [[Стандартный набор.
Долго готовился.
Оружие, яды, гранаты, тяжёлый нож и сигнальный пистолет Zoraki.]],
		Objective = "Полный стандартный набор в карманах. Убей всех.",
		SpawnFunction = function(ply)
			local wep = ply:Give("weapon_zoraki")
			
			timer.Simple(1, function()
				wep:ApplyAmmoChanges(2)
			end)
			
			ply:Give("weapon_buck200knife")	
			ply:Give("weapon_hg_rgd_tpik")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_shuriken")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_suit")
			ply:Give("weapon_hg_jam")
			-- ply:Give("weapon_traitor_poison2")
			-- ply:Give("weapon_traitor_poison3")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_default_soe"] = {
		Name = "Дефолт",
		Description = [[Стандартный набор ЧП.
Долго готовился.
Глушитель, нож, гранаты, яды, взрывчатка и доп. магазин.]],
		Objective = "Полный стандартный набор в карманах. Убей всех.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			local p22 = ply:Give("weapon_p22")
			if not IsValid(p22) then return end
			ply:GiveAmmo(p22:GetMaxClip1() * 1, p22:GetPrimaryAmmoType(), true)
			
			hg.AddAttachmentForce(ply, p22, "supressor4")
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			ply:Give("weapon_traitor_ied")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory",inv)
		end,
	},
	--==//
	
	--==\\
	["traitor_infiltrator"] = {
		Name = "Саботажник",
		Description = [[Ломает шеи сзади.
Может полностью переодеться в одежду игрока из регдолла.
Только нож, эпипен и дымовая граната.]],
		Objective = "Эксперт по диверсиям. Действуй тихо, убирай по одному.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	["traitor_infiltrator_soe"] = {
		Name = "Саботажник",
		Description = [[Ломает шеи сзади.
Переодевание через регдолл.
Дым, нож, тазер с двумя доп. электродами и эпипен.]],
		Objective = "Эксперт по диверсиям. Действуй тихо, убирай по одному.",
		SpawnFunction = function(ply)
			local taser = ply:Give("weapon_taser")
			
			ply:GiveAmmo(taser:GetMaxClip1() * 2, taser:GetPrimaryAmmoType(), true)
			ply:Give("weapon_sogknife")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_walkie_talkie")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_hg_smokenade_tpik")
			
			ply.organism.recoilmul = 1
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
		end,
	},
	--==//
	
	--==\\
	--; СДЕЛАТЬ ЕМУ ЛУТ ДРУГИХ ИГРОКОВ ДАЖЕ ПОКА У НИХ НЕТ ПУШКИ В РУКАХ
	--; Сделать ему вырубание по вагус нерву
	["traitor_assasin"] = {
		Name = "Ассасин",
		Description = [[Быстро обезоруживает с любого угла.
Быстрее сзади и по регдоллу спереди.
Опытен в стрельбе.
+80 к выносливости.
Рация.]],
		Objective = "Разоружи стрелка и убей его, его-же оружием.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.8
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {}) // WHY SOMEONE COMMENTED THIS
			--inv["Weapons"]["hg_flashlight"] = true
			
			--ply:SetNetVar("Inventory", inv) // BUT NOT THIS???
		end,
	},
	["traitor_assasin_soe"] = {
		Name = "Ассасин",
		Description = [[Быстро обезоруживает с любого угла.
Быстрее сзади и по регдоллу спереди.
Опытен в стрельбе.
+80 к выносливости.
Нож, эпипен, фонарик.]],
		Objective = "Разоружи стрелка и убей его, его-же оружием.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")	
			ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_walkie_talkie")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_hg_shuriken")
			
			ply.organism.recoilmul = 0.4
			ply.organism.stamina.max = 300
			--local inv = ply:GetNetVar("Inventory", {}) // WHY SOMEONE COMMENTED THIS
			--inv["Weapons"]["hg_flashlight"] = true
			
			--ply:SetNetVar("Inventory", inv) // BUT NOT THIS???
		end,
	},
	--==//
	
	--==\\
	["traitor_chemist"] = {
		Name = "Химик",
		Description = [[Набор ядов, нож и эпипен.
Устойчив к своим химикатам.
Чувствует яды в воздухе.]],
		Objective = "Отравляй всё, что движется.",
		SpawnFunction = function(ply)
			ply:Give("weapon_sogknife")
			ply:Give("weapon_adrenaline")
			ply:Give("weapon_traitor_poison1")
			ply:Give("weapon_traitor_poison2")
			ply:Give("weapon_traitor_poison3")
			ply:Give("weapon_traitor_poison4")
			ply:Give("weapon_traitor_poison_consumable")
			
			ply.organism.stamina.max = 220
			local inv = ply:GetNetVar("Inventory", {})
			inv["Weapons"]["hg_flashlight"] = true
			
			ply:SetNetVar("Inventory", inv)
			CleanChemicalsOfPlayer(ply)
		end,
	},
	--==//
	-- ["traitor_demoman"] = {
		-- Name = "Demoman",
		-- Description = [[Has many explosives.
-- Can rig certain items with bombs
-- (Radio, certain consumables, etc.)]],
		-- Objective = "You're the ultimate chemist who decided to use knowledge to hurt others.",
		-- SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")
			-- ply:Give("weapon_adrenaline")
			-- ply:Give("weapon_hg_rgd_tpik")
			-- ply:Give("weapon_hg_pipebomb_tpik")
			-- ply:Give("weapon_hg_smokenade_tpik")
			-- ply:Give("weapon_traitor_ied")
			-- ply:Give("weapon_walkie_talkie")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		-- end,
	-- },
	["traitor_custom"] = {
		Name = "Мокрушник",
		Description = [[Снаряжение из главного меню. Без пресета.]],
		Objective = "Убей всех выбранным снаряжением.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			ply.organism.stamina.max = 220
			if hg and hg.TraitorLoadout then
				hg.TraitorLoadout.GiveTraitorFlashlight(ply)
			end
		end,
	},
	["traitor_custom_soe"] = {
		Name = "Мокрушник",
		Description = [[Снаряжение из главного меню. Без пресета.]],
		Objective = "Убей всех выбранным снаряжением.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			ply.organism.stamina.max = 220
			ply.organism.recoilmul = 1
			if hg and hg.TraitorLoadout then
				hg.TraitorLoadout.GiveTraitorFlashlight(ply)
			end
		end,
	},
	["traitor_martial_artist"] = {
		Name = "Мастер боевых искусств",
		Description = [[Супербоец. Нунчаки с собой. Без фонарика.]],
		Objective = "Твоё тело — оружие. Убей всех.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			if hg and hg.TraitorLoadout then
				hg.TraitorLoadout.ApplySkillset(ply, "martial_artist", "standard")
			end
		end,
	},
	["traitor_martial_artist_soe"] = {
		Name = "Мастер боевых искусств",
		Description = [[Супербоец. Нунчаки с собой. Без фонарика.]],
		Objective = "Твоё тело — оружие. Убей всех.",
		SpawnFunction = function(ply)
			if not IsValid(ply) then return end
			if hg and hg.TraitorLoadout then
				hg.TraitorLoadout.ApplySkillset(ply, "martial_artist", "soe")
			end
		end,
	},
	["traitor_zombie"] = {
		Name = "Зомби",
		Description = [[Тихо заражает игроков.
Врач может вылечить.
Если все вылечены — зомби проигрывает.
При смерти переносится в тело другого заражённого.
Без оружия. Выглядит как обычный человек.]],
		Objective = "Зарази всех. Избегай врача.",
		SpawnFunction = function(ply)
			-- ply:Give("weapon_sogknife")	
			-- ply:Give("weapon_adrenaline")
			
			-- ply.organism.stamina.max = 220
			-- local inv = ply:GetNetVar("Inventory", {})
			-- inv["Weapons"]["hg_flashlight"] = true
			
			-- ply:SetNetVar("Inventory", inv)
		end,
	},
	--=//
}
--//

--\\Professions
MODE.ProfessionsRoundTypes = {
	["standard"] = true,
	["soe"] = true,
}

MODE.Professions = {
	["doctor"] = {
		Name = "Врач",
		SpawnFunction = function(ply)	--; TODO MAKE IT WORK
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["huntsman"] = {
		Name = "Егерь",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["engineer"] = {
		Name = "Инженер",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["cook"] = {
		Name = "Повар",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
	["builder"] = {
		Name = "Строитель",
		SpawnFunction = function(ply)
			--; It's a bad practice to give professions any weapons or tools
		end,
	},
}
--//

--\\
--; Названия перменных чуть чуть конченные получились, нужно будет подумать как улучшить
--; ужас
MODE.FadeScreenTime = 1.5
MODE.DefaultRoundStartTime = 6
MODE.RoleChooseRoundStartTime = 10

MODE.RoleChooseRoundTypes = {
	["standard"] = {
		TraitorDefaultRole = "traitor_default",
		Traitor = {
			["traitor_default"] = true,
			["traitor_custom"] = true,
			["traitor_infiltrator"] = true,
			["traitor_chemist"] = true,
			["traitor_assasin"] = true,
			["traitor_martial_artist"] = true,
			--; ОБЪЕДЕНИТЬ ХИМИКА И ДИВЕРСАНТА!!! наверное
			-- ["traitor_demoman"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
			["builder"] = {
				Chance = 1,
			},
		},
	},
	["soe"] = {
		TraitorDefaultRole = "traitor_default_soe",
		Traitor = {
			["traitor_default_soe"] = true,
			["traitor_custom_soe"] = true,
			["traitor_infiltrator_soe"] = true,
			["traitor_chemist"] = true,
			["traitor_assasin_soe"] = true,
			["traitor_martial_artist_soe"] = true,
			-- ["traitor_demoman_soe"] = true,
		},
		Professions = {
			["doctor"] = {
				Chance = 1,
			},
			["huntsman"] = {
				Chance = 1,
			},
			["engineer"] = {
				Chance = 1,
			},
			["cook"] = {
				Chance = 1,
			},
		},
	},
}
--//

MODE.Roles = {}
MODE.Roles.soe = {
	traitor = {
		name = "предатель",
		color = Color(190,0,0)
	},

	gunner = {
		name = "невиновный",
		color = Color(158,0,190)
	},

	innocent = {
		name = "невиновный",
		color = Color(0,120,190)
	},
}

MODE.Roles.standard = {
	traitor = {
		objective = "Долго готовился. Убей всех.",
		name = "убийца",
		color = Color(190,0,0)
	},

	gunner = {
		name = "свидетель",
		color = Color(158,0,190)
	},

	innocent = {
		name = "свидетель",
		color = Color(0,120,190)
	},
}

MODE.Roles.gunfreezone = {
	traitor = {
		name = "убийца",
		color = Color(190,0,0)
	},

	gunner = {
		name = "невиновный",
		color = Color(0,120,190)
	},

	innocent = {
		name = "невиновный",
		color = Color(0,120,190)
	},
}

if hg and hg.TraitorLoadout then
	hg.TraitorLoadout.ApplySubRoleLocales(MODE)
end

function MODE.GetPlayerTraceToOther(ply, aim_vector, dist)
	local trace = hg.eyeTrace(ply, dist, nil, aim_vector)
	
	if(trace)then
		local aim_ent = trace.Entity
		local other_ply = nil
		
		if(IsValid(aim_ent))then
			if(aim_ent:IsPlayer())then
				other_ply = aim_ent
			elseif(aim_ent:IsRagdoll())then
				if(IsValid(aim_ent.ply))then
					other_ply = aim_ent.ply
				end
			end
		end
		
		return aim_ent, other_ply, trace
	else
		return nil
	end
end