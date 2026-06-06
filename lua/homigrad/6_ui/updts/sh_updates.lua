hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 5.4",
		date = "05.06.2026",
		title = "meleecity",
		lines = {
			"Фикс рубилова/против всех",
			"улучшение зоны в рубилова/против всех",
			"Новые шейдеры",
			"Больше оружий которые видно за спиной"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end