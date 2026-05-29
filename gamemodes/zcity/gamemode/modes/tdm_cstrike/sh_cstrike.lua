local MODE = MODE

MODE.base = "tdm"
MODE.buymenu = true

MODE.PrintName = "Counter-Strike"
MODE.EndMenuTitle = "CS"
MODE.name = "cstrike"

zb.Points.BOMB_ZONE_A = zb.Points.BOMB_ZONE_A or {}
zb.Points.BOMB_ZONE_A.Color = Color(0, 120, 190)
zb.Points.BOMB_ZONE_A.Name = "Bomb Site A"

zb.Points.BOMB_ZONE_B = zb.Points.BOMB_ZONE_B or {}
zb.Points.BOMB_ZONE_B.Color = Color(190, 90, 0)
zb.Points.BOMB_ZONE_B.Name = "Bomb Site B"

zb.Points.HOSTAGE_DELIVERY_ZONE = zb.Points.HOSTAGE_DELIVERY_ZONE or {}
zb.Points.HOSTAGE_DELIVERY_ZONE.Color = Color(150,150,150)
zb.Points.HOSTAGE_DELIVERY_ZONE.Name = "HOSTAGE_DELIVERY_ZONE"

MODE.BuyItems["Gear"] = MODE.BuyItems["Gear"] or { Priority = 50 }
MODE.BuyItems["Gear"]["Набор разминирования"] = {
	Type = "Weapon",
	ItemClass = "weapon_zb_defusekit",
	Price = 300,
	Category = "Gear",
	Attachments = {},
	TeamBased = 1,
}