hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 4.5",
		date = "01.06.2026",
		title = "meleecity",
		lines = {
			"Очень много изменений",
			"Много известных багов исправлено"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end