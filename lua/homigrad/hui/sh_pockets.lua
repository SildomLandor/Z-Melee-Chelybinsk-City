hg.PocketsConfig = {
	SlotCount         = 2,
	OpenDistance      = 80,
	ValidationRange   = 125,
	SlotIconSizeW     = 120,
	SlotIconSizeH     = 80,
	SlotWidth         = 158,
	SlotHeight        = 120,
	SlotSpacing       = 8,
}

hg.PocketsItems = {}

function hg.RegisterPocketItem(id, data)
	if not istable(data) then return end
	data.ID = id
	hg.PocketsItems[id] = data
end
