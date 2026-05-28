hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 2",
		date = "28.05.2026",
		title = "meleecity",
		lines = {
			"Организм у NPC теперь более реалистичен.",
			"Гилт работает намного лучше, логика поправлена.",
			"Много других мелких фиксов и правок.",
			"Теперь вы можете разьебать ноги зомби!",
			"У трейтора Диверсанта появился шприц и рация-приманка."
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end
