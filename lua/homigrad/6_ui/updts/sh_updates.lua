hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 2.8",
		date = "29.05.2026",
		title = "meleecity",
		lines = {
			"Множество багов исправлены.",
			"Обновлено отображение пульса в отрубе.",
			"Оптимизация смены режимов (очень заметно)",
			"Оптимизация организма."
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end

