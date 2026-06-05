local MODE = MODE
MODE.name = "tdm"
MODE.buymenu = true

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HMCD_TDM_CT = zb.Points.HMCD_TDM_CT or {}
zb.Points.HMCD_TDM_CT.Color = Color(0,0,150)
zb.Points.HMCD_TDM_CT.Name = "HMCD_TDM_CT"

zb.Points.HMCD_TDM_T = zb.Points.HMCD_TDM_T or {}
zb.Points.HMCD_TDM_T.Color = Color(150,95,0)
zb.Points.HMCD_TDM_T.Name = "HMCD_TDM_T"

MODE.PrintName = "Team Deathmatch"
MODE.EndMenuTitle = "Командный бой"

--[[
    ["weapon_hk_usp"] = {
        Type = "Weapon",
        Price = "600",
        Category = "Pistols",
        Attachments = {
            "supressor3", "supressor4"
        }
    },
]]

MODE.BuyItems = {}

local priority = 1
local function AddItemToBUY(ItemName, Type, ItemClass, Price, Category, Attachments, Amount, TeamBased)
    if not MODE.BuyItems[Category] then
        MODE.BuyItems[Category] = {}
        MODE.BuyItems[Category].Priority = priority
        priority = priority + 1
    end

    MODE.BuyItems[Category][ItemName] = {
        Type = Type,
        ItemClass = ItemClass,
        Price = Price,
        Category = Category,
        Attachments = Attachments,
        Amount = Amount,
        TeamBased = TeamBased,
    }
end
-- Weapons
AddItemToBUY( "HK-USP", "Оружие", "weapon_hk_usp", 500, "Пистолеты", {"supressor3", "supressor4"} )
AddItemToBUY( "Glock-17", "Оружие", "weapon_glock17", 550, "Пистолеты", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Glock-18C", "Оружие", "weapon_glock18c", 1400, "Пистолеты", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Walter-P22", "Оружие", "weapon_p22", 300, "Пистолеты", {"supressor4"} )
AddItemToBUY( "Desert Eagle", "Оружие", "weapon_deagle", 900, "Пистолеты" )
AddItemToBUY( "MR-96", "Оружие", "weapon_revolver2", 750, "Пистолеты", {"supressor4"} )
AddItemToBUY( "FNX-45", "Оружие", "weapon_fn45", 700, "Пистолеты", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Colt M45A1", "Оружие", "weapon_m45", 450, "Пистолеты", {} )
AddItemToBUY( "Colt M1911", "Оружие", "weapon_m1911", 400, "Пистолеты", {} )
AddItemToBUY( "Browning Hi-Power", "Оружие", "weapon_browninghp", 700, "Пистолеты", {} )
AddItemToBUY( "Beretta PX4", "Оружие", "weapon_px4beretta", 400, "Пистолеты", {"supressor4"} )
AddItemToBUY( "PL-15", "Оружие", "weapon_pl15", 500, "Пистолеты", {"supressor4"} )
AddItemToBUY( "ČZ 75", "Оружие", "weapon_cz75", 500, "Пистолеты", {"supressor4"} )
AddItemToBUY( "Colt King Cobra", "Оружие", "weapon_revolver357", 800, "Пистолеты", {} )

AddItemToBUY( "Ruger 10/22", "Оружие", "weapon_ruger", 1000, "Карабины", {} )
AddItemToBUY( "Mini-14", "Оружие", "weapon_mini14", 2200, "Карабины", {} )

AddItemToBUY( "AKM", "Оружие", "weapon_akm", 3200, "Штурмовые винтовки", {"holo6","holo1","holo2","supressor1","optic7"}, nil, 0 )
AddItemToBUY( "M4A1", "Оружие", "weapon_m4a1", 2700, "Штурмовые винтовки", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "HK416", "Оружие", "weapon_hk416", 3000, "Штурмовые винтовки", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "AK-74", "Оружие", "weapon_ak74", 2400, "Штурмовые винтовки", {"holo6","holo1","holo2","supressor1","supressor8","optic7"}, nil, 0 )

AddItemToBUY( "MP-5", "Оружие", "weapon_mp5", 1500, "ПП", {"supressor4"} )
AddItemToBUY( "MP-7", "Оружие", "weapon_mp7", 2300, "ПП", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "MAC-11", "Оружие", "weapon_mac11", 1600, "ПП", {"supressor4"}, nil, 0 )
AddItemToBUY( "Uzi", "Оружие", "weapon_uzi", 1300, "ПП", {}, nil, 0 )
AddItemToBUY( "KRISS Vector", "Оружие", "weapon_vector", 2300, "ПП", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "P90", "Оружие", "weapon_p90", 2300, "ПП", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "Steyr TMP", "Оружие", "weapon_tmp", 2100, "ПП", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "Šcorpion vz. 61", "Оружие", "weapon_skorpion", 1200, "ПП", {}, nil, 0 )

AddItemToBUY( "Лук \"Охотник на оленей\"", "Оружие", "weapon_hg_bow", 2000, "Специальное", {} )
AddItemToBUY( "Медвежий капкан", "Оружие", "weapon_beartrap_homigrad", 450, "Специальное", {} )

AddItemToBUY( "Remington-870", "Оружие", "weapon_remington870", 1700, "Дробовики", {"holo1","holo2","supressor5","holo15"} )
AddItemToBUY( "SPAS-12", "Оружие", "weapon_spas12", 2200, "Дробовики", {"supressor5"} )
AddItemToBUY( "Обрез IZh-43", "Оружие", "weapon_doublebarrel_short", 800, "Дробовики", {}, nil, 0 )
AddItemToBUY( "IZh-43", "Оружие", "weapon_doublebarrel", 1100, "Дробовики", {}, nil, 0 )
AddItemToBUY( "XM-1014", "Оружие", "weapon_xm1014", 2300, "Дробовики", {"holo14", "holo3"} )

AddItemToBUY( "M249", "Оружие", "weapon_m249", 5750, "Тяжелое", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "M60", "Оружие", "weapon_m60", 7000, "Тяжелое", {} )
AddItemToBUY( "ПКМ", "Оружие", "weapon_pkm", 7800, "Тяжелое", {"optic4"} )
AddItemToBUY( "РПК-74", "Оружие", "weapon_rpk", 3700, "Тяжелое", {"optic4", "holo6", "holo13", "holo14", "holo6fur"} )

AddItemToBUY( "SR-25", "Оружие", "weapon_sr25", 5500, "Снайперские", {"supressor7","optic6", "optic2", "grip2"} , nil, 1)
AddItemToBUY( "Karabiner 98k", "Оружие", "weapon_kar98", 2100, "Снайперские", {"optic12"} )
AddItemToBUY( "SKS", "Оружие", "weapon_sks", 2900, "Снайперские", {"optic4"}, nil, 0 )
AddItemToBUY( "СВД", "Оружие", "weapon_svd", 5200, "Снайперские", {"optic4"}, nil, 0 )
AddItemToBUY( "Barrett M98B", "Оружие", "weapon_m98b", 4200, "Снайперские", {} )

-- Броня
AddItemToBUY( "Бронежилет IIIA", "Броня", "ent_armor_vest3", 450, "Снаряжение", {} )
AddItemToBUY( "Бронежилет III", "Броня", "ent_armor_vest4", 650, "Снаряжение", {} )
AddItemToBUY( "Бронежилет IV", "Броня", "ent_armor_vest1", 1000, "Снаряжение", {} )
AddItemToBUY( "Шлем ACH III", "Броня", "ent_armor_helmet1", 350, "Снаряжение", {} )
AddItemToBUY( "Баллистическая маска", "Броня", "ent_armor_mask1", 650, "Снаряжение", {} )

-- Разное
AddItemToBUY( "ПНВ GPNVG-18", "Броня", "ent_armor_nightvision1", 450, "Снаряжение", {} )
AddItemToBUY( "Фонарик", "Броня", "hg_flashlight", 250, "Снаряжение", {} )

-- Ближний бой
AddItemToBUY( "Мачете", "Оружие", "weapon_hg_machete", 300, "Ближний бой", {}, nil, 0 )
AddItemToBUY( "Топорик", "Оружие", "weapon_hatchet", 300, "Ближний бой", {}, nil, 0 )
AddItemToBUY( "Томагавк", "Оружие", "weapon_tomahawk", 300, "Ближний бой", {}, nil, 1 )
AddItemToBUY( "Полицейская дубинка", "Оружие", "weapon_hg_tonfa", 100, "Ближний бой", {}, nil, 1 )
AddItemToBUY( "Таран", "Оружие", "weapon_ram", 100, "Ближний бой", {}, nil, 1 )

-- Медицина
AddItemToBUY( "Бинт", "Медицина", "weapon_bandage_sh", 200, "Медицина", {} )
AddItemToBUY( "Большой бинт", "Медицина", "weapon_bigbandage_sh", 400, "Медицина", {} )
AddItemToBUY( "Аптечка", "Медицина", "weapon_medkit_sh", 650, "Медицина", {} )
AddItemToBUY( "Жгут", "Медицина", "weapon_tourniquet", 150, "Медицина", {} )
AddItemToBUY( "Обезболивающее", "Медицина", "weapon_painkillers", 200, "Медицина", {} )
AddItemToBUY( "Морфин", "Медицина", "weapon_morphine", 1000, "Медицина", {} )
AddItemToBUY( "Фентанил", "Медицина", "weapon_fentanyl", 2000, "Медицина", {} )
AddItemToBUY( "Эпипен (Адреналин)", "Медицина", "weapon_adrenaline", 800, "Медицина", {} )
AddItemToBUY( "Пакет крови", "Медицина", "weapon_bloodbag", 400, "Медицина", {} )
AddItemToBUY( "Маннитол", "Медицина", "weapon_mannitol", 300, "Медицина", {} )
AddItemToBUY( "Налоксон", "Медицина", "weapon_naloxone", 100, "Медицина", {} )
AddItemToBUY( "Декомпрессионная игла", "Медицина", "weapon_needle", 50, "Медицина", {} )
AddItemToBUY( "Бета-блокатор", "Медицина", "weapon_betablock", 250, "Медицина", {} )

-- Взрывчатка
AddItemToBUY( "M67", "Оружие", "weapon_hg_grenade_tpik", 500, "Взрывчатка", {} )
AddItemToBUY( "РГД-5", "Оружие", "weapon_hg_rgd_tpik", 450, "Взрывчатка", {} )
AddItemToBUY( "Светошумовая граната", "Оружие", "weapon_hg_flashbang_tpik", 250, "Взрывчатка", {} )

-- Патроны
AddItemToBUY( "7.62x39мм (30)", "Патроны", "ent_ammo_7.62x39mm", 100, "Патроны", {}, 30)
AddItemToBUY( "7.62x39мм БП (30)", "Патроны", "ent_ammo_7.62x39mmbp", 300, "Патроны", {}, 30)
AddItemToBUY( "7.62x39мм СС (30)", "Патроны", "ent_ammo_7.62x39mmsp", 150, "Патроны", {}, 30)

AddItemToBUY( "7.62x54мм (20)", "Патроны", "ent_ammo_7.62x54mm", 100, "Патроны", {}, 20)

AddItemToBUY( "7.62x51мм (20)", "Патроны", "ent_ammo_7.62x51mm", 150, "Патроны", {}, 20)
AddItemToBUY( "7.62x51мм M993 (20)", "Патроны", "ent_ammo_7.62x51mmm993", 300, "Патроны", {}, 20)

AddItemToBUY( ".338 Lapua Magnum (20)", "Патроны", "ent_ammo_.338lapuamagnum", 350, "Патроны", {}, 20)

AddItemToBUY( "9x19мм (30)", "Патроны", "ent_ammo_9x19mmparabellum", 75, "Патроны", {}, 30)
AddItemToBUY( "9x19мм Трассирующие (30)", "Патроны", "ent_ammo_9x19mmgreentracer", 100, "Патроны", {}, 30)
AddItemToBUY( "9x19мм QuakeMaker (30)", "Патроны", "ent_ammo_9x19mmqm", 150, "Патроны", {}, 30)
AddItemToBUY( "9x17мм (30)", "Патроны", "ent_ammo_9x17mm", 75, "Патроны", {}, 30)
AddItemToBUY( "7.65x17мм (30)", "Патроны", "ent_ammo_7.65x17mm", 75, "Патроны", {}, 30)

AddItemToBUY( "5.56x45мм (30)", "Патроны", "ent_ammo_5.56x45mm", 100, "Патроны", {}, 30)
AddItemToBUY( "5.56x45мм БП (30)", "Патроны", "ent_ammo_5.56x45mmap", 200, "Патроны", {}, 30)
AddItemToBUY( "5.56x45мм M856 (30)", "Патроны", "ent_ammo_5.56x45mmm856", 150, "Патроны", {}, 30)

AddItemToBUY( "5.45x39мм (30)", "Патроны", "ent_ammo_5.45x39mm", 100, "Патроны", {}, 30)
AddItemToBUY( "4.6x30мм (30)", "Патроны", "ent_ammo_4.6x30mm", 100, "Патроны", {}, 30)
AddItemToBUY( "5.7x28мм (30)", "Патроны", "ent_ammo_5.7x28mm", 100, "Патроны", {}, 30)

AddItemToBUY( "12/70 Дробь (12)", "Патроны", "ent_ammo_12/70gauge", 100, "Патроны", {}, 12)
AddItemToBUY( "12/70 Травматический (12)", "Патроны", "ent_ammo_12/70beanbag", 25, "Патроны", {}, 12)
AddItemToBUY( "12/70 RIP (12)", "Патроны", "ent_ammo_12/70rip", 250, "Патроны", {}, 12)
AddItemToBUY( "12/70 Пуля (12)", "Патроны", "ent_ammo_12/70slug", 150, "Патроны", {}, 12)

AddItemToBUY( ".22 Long Rifle (60)", "Патроны", "ent_ammo_.22longrifle", 50, "Патроны", {}, 60)

AddItemToBUY( ".45 ACP (30)", "Патроны", "ent_ammo_.45acp", 75, "Патроны", {}, 30)
AddItemToBUY( ".45 ACP Hydro-Shock (30)", "Патроны", "ent_ammo_.45acphydroshock", 125, "Патроны", {}, 30)

AddItemToBUY( ".50 Action Express (20)", "Патроны", "ent_ammo_.50actionexpress", 75, "Патроны", {}, 20)
AddItemToBUY( ".50 Action Express Copper (20)", "Патроны", "ent_ammo_.50actionexpresscopper", 100, "Патроны", {}, 20)
AddItemToBUY( ".50 Action Express JHP (20)", "Патроны", "ent_ammo_.50actionexpressjhp", 100, "Патроны", {}, 20)

AddItemToBUY( ".357 Magnum (20)", "Патроны", "ent_ammo_.357magnum", 75, "Патроны", {}, 20)
AddItemToBUY( ".38 Special (20)", "Патроны", "ent_ammo_.38special", 75, "Патроны", {}, 20)
AddItemToBUY( ".40 Smith & Wesson (30)", "Патроны", "ent_ammo_.40sw", 75, "Патроны", {}, 30)
AddItemToBUY( ".44 Remington Magnum (20)", "Патроны", "ent_ammo_.44remingtonmagnum", 75, "Патроны", {}, 20)

AddItemToBUY( "Стрела", "Патроны", "ent_ammo_arrow", 25, "Патроны", {}, 5)

function MODE:HG_MovementCalc_2( mul, ply, cmd, mv )
    if (zb.ROUND_START or 0) + 20 > CurTime() and cmd then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_FORWARD)
        cmd:RemoveKey(IN_BACK)
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)

        if mv then
            mv:RemoveKey(IN_ATTACK)
            mv:RemoveKey(IN_FORWARD)
            mv:RemoveKey(IN_BACK)
            mv:RemoveKey(IN_MOVELEFT)
            mv:RemoveKey(IN_MOVERIGHT)
        end

        if IsValid(ply) and IsValid(ply:GetWeapon("weapon_hands_sh")) then
            cmd:SelectWeapon(ply:GetWeapon("weapon_hands_sh"))
            if SERVER then ply:SelectWeapon("weapon_hands_sh") end
        end
        
        mul[1] = 0
    end
end

function MODE:PlayerCanLegAttack( ply )
	if zb.CROUND == "tdm" and (zb.ROUND_START or 0) + 20 > CurTime() then
		return false
	end
end