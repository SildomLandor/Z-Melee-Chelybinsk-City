hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 3.7",
		date = "29.05.2026",
		title = "meleecity",
		lines = {
			"Фикс всей медицины",
			"Теперь нельзя совершать самоубийство руками",
			"ИИ обновлен, оптимизирован и стал гораздно лучше",
			"Пофикшены все известные баги",
			"gwars: не выдаются дополнительные пушки",
			"В отрубе показывается очень реалистичное ЭКГ"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end

