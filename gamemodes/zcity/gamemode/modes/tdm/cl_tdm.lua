MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "swat4" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

hook.Add( "StartCommand", "TDM_DisallowMoveOrShoting", function( ply, mv )
	--; BLYAT NY NAXUA PISAT VSE V ODNY LINIY BLYAAA
	if zb.CROUND == "tdm" and (zb.ROUND_START or 0) + 20 > CurTime() then 
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
    local StartTime = zb.ROUND_START or CurTime()
	if StartTime + 7.5 < CurTime() then return end
    local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()
	if StartTime + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Press F3 to open buymenu", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime( math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i" )
		draw.SimpleText( time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

    if StartTime + 20 < CurTime() then return end
	 
	if not lply:Alive() then return end
	zb.RemoveFade()
    local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
    draw.SimpleText("ZBattle | "..(self.PrintName or "Team Deathmatch"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("You are "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)


net.Receive("tdm_open_buymenu",function() OpenBuyMenu() end)
TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil