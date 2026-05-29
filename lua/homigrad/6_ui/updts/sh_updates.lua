hg.updates = hg.updates or {}

hg.updates.updts = {
	{
		version = "Beta 3.1",
		date = "29.05.2026",
		title = "meleecity",
		lines = {
			"Организм оптимизирован",
			"Пульс в отрубе теперь более реалистичен",
			"Добавлены новые состояния организма",
			"Пофикшены известные баги",
			"Медицина пофикшена"
		},
	},
}

function hg.updates.GetLatestVersion()
	local list = hg.updates.updts
	local entry = list and list[#list]
	return entry and entry.version or ""
end

