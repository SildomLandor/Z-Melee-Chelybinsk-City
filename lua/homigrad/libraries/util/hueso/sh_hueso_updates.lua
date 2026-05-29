hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 2.1",
		date = "28.05.2026",
		title = "meleecity",
		lines = {
			"Карма: единые правила hmcd/капкан; копы не ловят штраф за трейтора; forgive сейвится.",
			"CStrike: разминирование, в закупке можно купить дефуз, зажми е на бомбу."
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end

