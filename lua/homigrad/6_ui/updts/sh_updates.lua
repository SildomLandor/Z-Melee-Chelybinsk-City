hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 6.0",
		date = "06.06.2026",
		title = "meleecity",
		lines = {
			"Новый античит",
			"Фикс известных багов",
			"Новые логи (Админы теперь всегда следят за вами)"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end