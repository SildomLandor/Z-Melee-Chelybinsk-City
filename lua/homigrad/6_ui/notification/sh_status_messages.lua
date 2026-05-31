
local allowedchars = {
	"ah",
	"AH",
	"ghh",
	"GH",
	"AHHH",
}

local audible_pain = {
    "ААААХГХ.. ЧЕРТ, КАК ЖЕ БОЛЬНО.",
    "Я БОЛЬШЕ НЕ МОГУ ЭТО ТЕРПЕТЬ!",
    "Пусть это ЗАКОНЧИТСЯ, пусть ЭТО ЗАКОНЧИТСЯ, ПОЖАЛУЙСТА!",
    "почему... ПОЧЕМУ НАСТОЛЬКО БОЛЬНО",
    "Вырубите меня... ПРОШУ!",
    "За что мне такое — зачем я вообще чувствую боль...",
    "Я бы на всё согласился, лишь бы перестало болеть. НА ВСЁ.",
    "Это не жизнь, это настоящая ПЫТКА.",
    "Мне уже всё равно, ПРОСТО ОСТАНОВИТЕ ЭТУ БОЛЬ.",
    "Всё перестало иметь значение, КРОМЕ ТОГО, ЧТОБЫ БОЛЬ ПРЕКРАТИЛАСЬ...",
    "Каждая секунда — вечность в ОГНЕ.",
    "СМЕРТЬ... СЕЙЧАС МИЛОСТЬ ДЛЯ МЕНЯ...",
    "Хотя бы миг без боли...",
    "я нечего не чувствую... КРОМЕ ЭТОЙ БОЛИ.",
}

local sharp_pain = {
	"АААХХ",
	"АААХ",
	"ААааАХ",
	"ААааАХ",
	"ААааАААГХ",
	"ААааАХ",
	"ААаАааХ",
	"АААААааХ",
	"ААааАХХХХ",
	"ААаАА",
	"АААААа",
	"ААААаАААаааагхх",
	"АААааАа",
	"АааААагхф",
	"ааАааАафф",
	"аааххх",
	"АААааГХХХ",
	"АААааААХХ",
	"АААааАААААаГХХХХ",
	"АААааАААААаГХАААХХХ",
	"АААааАААААаГХХААААААХХ",
	"АААааАААААаГХХХХ",
	"АААааАААааАААаГХХХХ",
	"АААааАААааАААаАААААААГХХХХ",
	"АААааАААААаГХХХХ",
	"АААааАААААААААХХХ",
	"АААааАААААаГХАаааХХ",
	"АААааАААААаАаааааААААХХ",
	"АААааАААААаААААААААДГХХХХ",
	"АААааАААааАААаАААААААААААААГГГГГГАГХХХХ",
	"АААааАААааАААаАААААААААААААААААААХ",
}

hg.sharp_pain = sharp_pain

blood_react_phrases = {
	"Пахнет... Метталом?"
	"Такой резкий запах меди и мускуса... странно"
	"Пахнет... Кровью?"
}

local random_phrase = {
	"Что-то не так... Но что?",
	"Слишком тихо вокруг... Меня это напрягает",
	"Воздух сейчас кажется легким и свежим.",
	"Так тихо, будто я один во всем мире?",
	"Воздух резко стал тяжелым... Это запах меттала?",
	"Черт... Я забыл свой телефон дома.",
	"Эхх... вот-бы музыку послушать.",
	"КТО ЭТО... Черт... Это просто мусор.",
}

local fear_hurt_ironic = {
	"Наверное, из этого стоило бы вынести урок... если выживу.",
	"Будущему биографу я это не объясню.",
	"Глупый способ умирать, конечно.",
	"Зато жизнь скучной не была.",
	"Заметка себе: больше так не делать.",
	"Ну, есть и хуже дни для смерти.",
}

local fear_phrases = {
	"Не так уж всё и плохо... наверное?",
	"Я не хочу умирать вот так.",
	"Неужели всё закончится вот так?",
	"Это нехорошо.",
	"Правда, здесь ли всему конец?",
	"Я не хочу погибнуть вот так.",
	"Хотел бы я найти выход.",
	"О стольком сожалею сейчас.",
	"Не может быть, что это всё.",
	"Не верю, что это происходит со мной.",
	"Надо было воспринимать это серьёзнее.",
	"А вдруг я не справлюсь..?",
	"Всё хуже, чем думал.",
	"Это так нечестно.",
	"Я ещё не могу сдаться.",
	"Я и представить не мог, что будет вот так.",
	"Надо было слушать свою интуицию.",
	"Дыши. Просто дыши.",
	"Холодные руки. Ровные руки.",
}

local is_aimed_at_phrases = {
    "Господи. Вот и всё.",
    "Не двигаться.",
    "Неужели я правда сейчас умру?",
    "Надо было бежать. Почему я не убежал?",
    "Пожалуйста, не стреляй. Пожалуйста.",
    "Я вижу его палец на спусковом крючке.",
    "Я не хочу умирать. Только не так.",
    "Если я начну умолять, станет хуже?",
    "Это не может быть наяву. Этого не может быть.",
    "Кто-нибудь, помогите. Пожалуйста. Кто-нибудь.",
    "Я не хочу умирать в таком месте.",
    "Я не хочу, чтобы мой последний миг был полон страха.",
    "Я не хочу умирать.",
}

local near_death_poetic = {
	"Пытаюсь встать... но не могу...",
	"Дышу... но будто вдыхаю пустоту...",
	"Уже не понимаю, открыты ли глаза...",
	"Последнее, что почувствую — вкус крови и металла.",
	"Взгляд всё время куда-то уходит.",
	"Не могу вспомнить, как вообще стоять.",
	"Всё в голове отдаётся эхом.",
	"Моргнул — возвращаюсь будто слишком долго.",
	"Пальцы больше ни за что не цепляются.",
	"Лёгкие отказываются наполняться.",
	"Уже поздно жалеть о чём-то.",
}
--[[
local near_death_positive = {
	"I don't want to die.",
	"I have to survive.",
	"There's still a chance.",
	"I can't let fear win.",
	"Just one more try.",
	"I refuse to die here.",
	"Alright... think this through.",
	"Just stay still. Moving makes it worse.",
	"Breathe slow. Panic won't help.",
	"It's not over until it's over.",
	"Pain is just a signal. Ignore it.",
	"If this is it... at least it's gonna be quick.",
	"I've survived worse. Probably.",
	"This isn't how I pictured it.",
}
]]

local broken_limb = {
	"БЛЯТЬ. БЛЯТЬ. ОНО ТОЧНО СЛОМАНО!",
	"Я ЧУВСТВУЮ, КАК КОСТОЧКИ ДВИГАЮТСЯ!",
	"ОНА СЛОМАНА. ТОЧНО... Я ЧУВСТВУЮ...",
	"Болит даже, когда думаю об этом. Точно сломано.",
	"Мне кажется, тут не должно вот так сгибаться.",
	"Чёрт... Кажется, она сломана.",
	"Не вижу открытого перелома, но что-то там точно не так; кажется, я сломал(а) что-то.",
}

local dislocated_limb = {
	"Блять, она вообще не должна так сгибаться.",
	"Мне нужно вправить кость на место.",
	"Нет... Надо вернуть её обратно самостоятельно.",
	"Там так сильно болит... Нужно бы к врачу.",
	"Конечность не на своём месте.",
}

local hungry_a_bit = {
    "Ммх... Жрать охота...",
    "Было бы круто поесть чего-нибудь...",
    "Я голоден...",
    "Надо бы что-то съесть.",
}

local very_hungry = {
    "Живот... Блин...",
    "Если не поем, будет ещё хуже...",
    "Живот... Чёрт, тошнит уже.",
}

local after_unconscious = {
    "Что произошло? Больно...",
	"Где я? Почему всё болит...",
	"Я... Я думал(а), что сейчас умру...",
	"Голова... Что случилось?",
	"Я чуть не умер(ла) только что?",
	"Ощущение, будто реально умер(ла).",
	"Меня там наверху не приняли?",
	"Ох, блядь... башка раскалывается...",
	"Сейчас встать будет адски тяжело... но надо пробовать...",
	"Я вообще не узнаю это место... или всё же узнаю?",
	"Я больше НИКОГДА не хочу переживать такое!",
}

local slight_braindamage_phraselist = {
	"Я ничего не понимаю...",
	"В этом нет смысла...",
	"Где я?",
	"А? Что это..?",
	"Я не понимаю, что происходит...",
	"Алло?",
	"Уххх... эээ... что?..",
	"Что... происходит?",
}

local braindamage_phraselist = {
	"Bbbee.. wheea mgh?!",
	"Bmmeee... mehk...",
	"Mm--hhhh. Mmm?",
	"Ghmgh whhh...",
	"Ahgg...mg?",
	"Hgghh... D-Dmmh.",
	"Lmmmphf, mp-hf!",
	"Heeelllhhpphp...",
	"Nghh... Gmh?",
	"Ggg... Bgh..",
	"Bhrhraihin.",
}

local cold_phraselist = {
	"Становится очень холодно...",
	"Слишком холодно для меня.",
	"Я весь дрожу, пиздец, честное слово.",
	"Здесь дико морозно...",
	"Нужно хоть что-нибудь, чтобы согреться...",
	"Мне реально холодно...",
	"Я себя плохо чувствую от такого холода, блядь."
}

local freezing_phraselist = {
	"Я... не чувствую с...воего тела...",
	"Я не... н-не чувствую ног...",
	"Я про-просто пиздец как з-замерзаю...",
	"Я-я думаю... у меня лицо о-онемело...",
	"Х-холодно...",
	"Я... не чувствую в-вообще н-ничего...",
}

local numb_phraselist = {
	"Мне больше... не холодно...",
	"Почему... вдруг стало тепло..?",
	"Кажется, я в порядке... Наверное...",
	"Наконец-то хоть какое-то тепло...",
	"Я снова чувствую тепло... Каким-то образом...",
	"Я ведь только что мёрз... Откуда это тепло взялось?..",
}

local hot_phraselist = {
	"Я весь потный...",
	"Эта жара меня убивает...",
	"Вся одежда мокрая от пота, блядь.",
	"Я так воняю потом, пиздец. Пора бы остудиться...",
	"Слишком уж жарко, блин.",
	"Меня прям жёстко накрывает от жары...",
	"Почему здесь так жарко?",
}

local heatstroke_phraselist = {
	"МНЕ НУЖНА ВОДА!!",
	"Пожалуйста... воды...",
	"У меня кружится голова... Бляя-",
	"ГОЛОВА! – Она болит...",
	"Голова просто раскалывается...",
}

local heatvomit_phraselist = {
	"От этой жары... сейчас блевану-",
	"Угххх... сейчас стошнит-",
	"Бляя... Оуух... Я себя вообще не чувствую-"
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Toggle thoughts of your character", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local temperature = org.temperature
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 65) and 5
		or (temperature < 31 and 0.5)
		or (temperature > 38 and 0.5)
		or (blood < 3000 and 0.3)
		--or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = hook.Run("HG_CanThoughts", ply) --ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"
	if nomessage ~= nil and nomessage == false then return "" end

    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local temperature = org.temperature
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist
	
	if temperature < 35 then
		most_wanted_phraselist = temperature > 31 and cold_phraselist or (temperature < 28 and numb_phraselist or freezing_phraselist)
	elseif temperature > 38 then
		most_wanted_phraselist = temperature < 40 and hot_phraselist or heatstroke_phraselist
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				most_wanted_phraselist = near_death_poetic
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	elseif hg.fearful(ply) then
		most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

local allowedlist_types = {
	heatvomit = heatvomit_phraselist,
}

function hg.get_phraselist(ply, type)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end
	
	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism	
	if not org or not org.brain then return "" end

	if not isstring(type) or not allowedlist_types[type] then return "" end

	local needed_list = allowedlist_types[type]

	local str = needed_list[math.random(#needed_list)]
	return str
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end
