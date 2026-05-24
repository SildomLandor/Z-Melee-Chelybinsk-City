hg.Appearance = hg.Appearance or {}
local A = hg.Appearance

A.Locale = {
	clothes = {
		normal = "Обычная",
		formal = "Костюм",
		plaid = "Клетка",
		striped = "Полоска",
		young = "Молодёжная",
		cold = "Зимняя",
		casual = "Повседневная",
		sweater_xmas = "Свитер",
		worker = "Рабочая",
		bomber_jacket1 = "Бомбер",
		camo_variant2 = "Камуфляж",
		pilot_jacket = "Пилотка",
		tactical_outfit = "Тактическая",
		hussar_jacket = "Гусарка",
		Tshirt3 = "Футболка 3",
		leather_jacket = "Кожанка",
		Tshirt1 = "Футболка 1",
		Tshirt2 = "Футболка 2",
		alpha_bomber = "Alpha бомбер",
		alpha_hoodie = "Alpha худи",
		lonsdale_hoodie = "Lonsdale",
		golden_adidas = "Золотые Adidas",
		wagner_group = "Вагнер",
		russian_army = "Армия РФ",
		Hello_Kitty = "Hello Kitty",
		Office_Worker = "Офис",
		Security_Officer = "Охрана",
		Zcity_Hoodie = "Z-City худи",
		Flecktarn = "Flecktarn",
		Hawaiian_Shirt = "Гавайка",
		Hawaiian_Shirt2 = "Гавайка 2",
		Sadsalat = "Sad salat",
		Army_Shirt = "Армейка",
		Lambda = "Lambda",
		bean = "Bean",
		y2k = "Y2K",
		medic1 = "Медик",
		antisocial = "Antisocial",
		peacefulhooligan = "Мирный хулиган",
		polska = "Польша",
		adidas_tracksuit = "Adidas костюм",
		Tshirt4 = "Футболка 4",
		Hawaiian_Shirt1 = "Гавайка",
		swiss = "Швейцарская",
	},
	bodygroups = {
		["None"] = "Без перчаток",
		["Gloves"] = "Перчатки",
		["Gloves fingerless"] = "Без пальцев",
		["Skilet"] = "Скелетные",
		["Skilet fingerless"] = "Скелетные (без пальцев)",
		["Winter"] = "Зимние",
		["Winter fingerless"] = "Зимние (без пальцев)",
		["Bikers gloves"] = "Байкерские",
		["Bikers wool"] = "Байкерские шерстяные",
		["Wool fingerless"] = "Шерстяные",
		["Mitten wool"] = "Варежки",
		["Standard Top"] = "Обычный верх",
		["Wide Top"] = "Широкий верх",
		["Wide More Top"] = "Очень широкий",
		["T-Shirt"] = "Футболка",
		["Closed Collar"] = "Закрытый ворот",
		["T-Shirt Hands"] = "Руки под футболку",
		["Robotic Hand"] = "Роборука",
		["Medical Gloves"] = "Медперчатки",
		["Odessa Jacket"] = "Куртка Одесса",
		["Robotic Arm"] = "Роборука (торс)",
		["Mossman Jacket"] = "Куртка Mossman",
		["Standard Bottom"] = "Обычные штаны",
		["Wide Bottom"] = "Широкие штаны",
		["Boots"] = "Ботинки",
		["Shorts"] = "Шорты",
		["Boots Wider"] = "Ботинки (широкие)",
	},
	facemaps = {
		["Default"] = "По умолчанию",
	},
	slots = {
		main = "Верх",
		pants = "Штаны",
		boots = "Обувь",
		hands = "Перчатки (текстура)",
	},
}

function A.GetClothLabel(key)
	return A.Locale.clothes[key] or string.NiceName(string.Replace(key or "", "_", " "))
end

function A.GetBodygroupLabel(key)
	return A.Locale.bodygroups[key] or key
end

function A.GetFacemapLabel(key)
	if key == "Default" then return "По умолчанию" end
	local n = string.match(key, "^Face (%d+)$")
	if n then return "Лицо " .. n end
	return key
end

A.ModelAliases = {
	["Male 01"] = "Мужчина 01", ["Male 02"] = "Мужчина 02", ["Male 03"] = "Мужчина 03",
	["Male 04"] = "Мужчина 04", ["Male 05"] = "Мужчина 05", ["Male 06"] = "Мужчина 06",
	["Male 07"] = "Мужчина 07", ["Male 08"] = "Мужчина 08", ["Male 09"] = "Мужчина 09",
	["Female 01"] = "Женщина 01", ["Female 02"] = "Женщина 02", ["Female 03"] = "Женщина 03",
	["Female 04"] = "Женщина 04", ["Female 05"] = "Женщина 05", ["Female 06"] = "Женщина 06",
}

function A.ResolveModelName(str)
	if not isstring(str) then return str end
	return A.ModelAliases[str] or str
end
