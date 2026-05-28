hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 2",
		date = "28.05.2026",
		title = "meleecity",
		lines = {
			"Зомбари: последние зомби на волне подсвечиваются красным контуром.",
			"хомисайд: выбор трейтора честнее - нельзя два раунда подряд, долго без роли - выше шанс.",
			"ZBase: умная навигация без нодов - обход, navmesh, анти-стак и прыжки через препятствия.",
			"ZBase: NPC сами вытягиваются при застревании в погоне, follow и подходе к цели",
			"Капкан: -50 кармы за установку под ноги или попадание по игроку.",
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end
