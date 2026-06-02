hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 5.1",
		date = "02.06.2026",
		title = "meleecity",
		lines = {
			"пивная бутылка",
			"улучшение пульса в отрубе",
			"много багов известных исправлено"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end