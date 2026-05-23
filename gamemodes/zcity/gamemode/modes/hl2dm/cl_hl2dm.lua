MODE.name = "hl2dm"

local MODE = MODE

net.Receive("hl2dm_start",function()
    surface.PlaySound("hl2mode1.wav")
	zb.RemoveFade()
	hg.DynaMusic:Start( "hl_coop" )
end)

local teams = {
	[0] = {
		objective = "Kill all combines and survive.",
		name = "a Rebel",
		name_refugee = "the Refugee",
		color1 = Color(230,100,5),
		color2 = Color(210,80,0),
		color3 = Color(25, 110, 25),
        color4 = Color(5, 90, 5),
		color_subrole = Color(180, 15, 15),
	},
	[1] = {
        objective = "Destroy all rebel forces.",
        name = "a Combine Soldier",
        name_elite = "the Elite Combine Soldier",
        name_shotgunner = "the Combine Shotgunner",
        color1 = Color(0, 200, 220), -- самый
        color2 = Color(0, 180, 200),
        color3 = Color(180, 15, 15),
		color4 = Color(160, 0, 0),
        color5 = Color(190, 185, 185),
		color6 = Color(170, 175, 175),
	},
}

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

--// Ну вроде сделал его чуточку читаемым 
function MODE:HUDPaint()
    if zb.ROUND_START + 8.5 < CurTime() then return end
     
    if not lply:Alive() then return end
    zb.RemoveFade()

    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
    local team_id = lply:Team()
    local role = lply:GetNWString("PlayerRole")
    local team_data = teams[team_id]

    draw.SimpleText("ZBattle | Half-Life 2 Deathmatch", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	--; Любимое ООП шарика
    local role_data = {
        name = team_data.name,
        color = team_data.color1,
        objective = team_data.objective
    }
    
    role_data.color.a = 255 * fade

    draw.SimpleText("You are " .. role_data.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, role_data.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local objective_color = team_data.color2

    objective_color.a = 255 * fade

    draw.SimpleText(role_data.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objective_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

