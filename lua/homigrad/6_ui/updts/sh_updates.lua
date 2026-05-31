hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 4.0",
		date = "31.05.2026",
		title = "meleecity",
		lines = {
			"Исправлены все известные баги",
			"Броня теперь работает корректно",
			"Добавлено новое оружие: Welrod Mk.I",
			"Пофикшен пакет для крови"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end