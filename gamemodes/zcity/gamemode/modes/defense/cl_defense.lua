MODE.name = "defense"

local MODE = MODE


local highlightNPCs = {}


net.Receive("npc_defense_start",function()
    surface.PlaySound("csgo_round.wav")
end)

local teams = {
	[1] = {
		objective = "Defend your base from the attack of the combines.",
		name = "a Refugee",
		color1 = Color(240,109,1),
		color2 = Color(190,95,0)
	},
}

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

    surface.SetDrawColor(0, 0, 0, 255 * fade)
    surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local NextWave_Time = 0

net.Receive("npc_defense_newwave", function()
	local time = net.ReadFloat()
	NextWave_Time = time
end)

local timePos = 0

function MODE:HUDPaint()
	if NextWave_Time > CurTime() - 5 then
		timePos = Lerp( FrameTime()*5, timePos, 1-math.min((NextWave_Time - CurTime())/1,1) )
		local time = string.FormattedTime(NextWave_Time - CurTime())
		time.s = (time.s < 10 and "0" or "")..time.s
		time.m = (time.m < 10 and "0" or "")..time.m
		draw.SimpleText( "Next wave in ".. time.m ..":" .. time.s, "ZB_HomicideMedium", sw * 0.5, sh * (0.9 + timePos), Color(87,146,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

    if zb.ROUND_START + 8.5 < CurTime() then return end
	 
	if not lply:Alive() then return end
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
    draw.SimpleText("ZBattle | HL2 Base Defense", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
    local playerRole = lply:GetNWString("PlayerRole", "Refugee") 
    local roleColor = teams[team_].color1
    roleColor.a = 255 * fade
    draw.SimpleText("You are a " .. playerRole, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local objective = teams[team_].objective
    local objectiveColor = teams[team_].color2
    objectiveColor.a = 255 * fade
    draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objectiveColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

--[[concommand.Add("defense_test_boss_banner", function()
	if not LocalPlayer():IsAdmin() then return end
    bossWaveData.active = true
    bossWaveData.startTime = CurTime()
    bossWaveData.scale = 0
    

    surface.PlaySound("ambient/alarms/razortrain_horn1.wav")
    timer.Simple(0.8, function()
        surface.PlaySound("ambient/alarms/klaxon1.wav")
    end)
    
    --chat.AddText(Color(255, 50, 50), "[DEFENSE] ", Color(255, 255, 255), "Boss banner test activated!")
end)]]



