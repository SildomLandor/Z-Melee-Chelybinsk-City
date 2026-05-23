MODE.name = "riot"

local MODE = MODE

net.Receive("riot_start", function()
    if RiotSound then
        RiotSound:Stop()
        RiotSound = nil
    end

    sound.PlayFile("sound/zbattle/riot.wav", "noplay", function(station)
        if IsValid(station) then
            station:SetVolume(6) 
            station:Play()
            RiotSound = station
        end
    end)

    zb.RemoveFade()
end)


local teams = {
	[0] = {
		objective = "",
		name = "a Rioter",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Law Enforcement",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
    if zb.ROUND_START + 8.5 < CurTime() then return end
	 
	if not lply:Alive() then return end
	zb.RemoveFade()
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(),0,1)
	local team_ = lply:Team()
    draw.SimpleText("Homicide | Riot", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("You are "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
