local MODE = MODE
MODE.name = "criresp"
local song
local songfade = 0
net.Receive("criresp_start", function()
	surface.PlaySound("zbattle/criresp.mp3") 

	timer.Simple(3, function()
		sound.PlayFile( "sound/zbattle/criresp/criepmission.mp3", "mono noblock", function( station )
			if ( IsValid( station ) ) then
				station:Play()
				song = station
				songfade = 1
			end
		end )
	end)
end)

local teams = {
	[0] = {
		objective = "Переговоры провалены, устранить угрозу 10-4",
		name = "Оператор СОБР",
		color1 = Color(68, 10, 255),
		color2 = Color(68, 10, 255)
	},
	[1] = {
		objective = "Это мой дом! я буду делать, что хочу",
		name = "Подозреваемый",
		color1 = Color(228, 49, 49),
		color2 = Color(228, 49, 49)
	},
}

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()
	if zb.ROUND_START + 85 < CurTime() then
		 
		if songfade <= 0.01 and IsValid( song ) then
			song:Stop()
			surface.PlaySound(lply:Team() == 0 and "zbattle/criresp/barricadedsuspectstart.mp3" or "snd_jack_hmcd_policesiren.wav")
		elseif IsValid( song ) then
			songfade = Lerp( 0.01, songfade, 0 )
			song:SetVolume(songfade)
		end
	end
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
local posadd = 0
function MODE:HUDPaint()
	if zb.ROUND_START + 90 > CurTime() then
		posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4) 
		local color = Color(255*-math.sin(CurTime()*3),25,255*math.sin(CurTime()*3))
		draw.SimpleText( "Капиталисты будуте тут через: "..string.FormattedTime(zb.ROUND_START + 90 - CurTime(), "%02i:%02i"	), "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Капиталисты будуте тут через: "..string.FormattedTime(zb.ROUND_START + 90 - CurTime(), "%02i:%02i"	), "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
		surface.SetDrawColor(0, 0, 0, 255 * fade)
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
	end

	if zb.ROUND_START + 8.5 > CurTime() then
		if not lply:Alive() and not lply:Team() == 0 then return end
		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
		local team_ = lply:Team()
		draw.SimpleText("Мини игры | Внештатная ситуация", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local Rolename = teams[team_].name
		local ColorRole = teams[team_].color1
		ColorRole.a = 255 * fade
		draw.SimpleText("Ты - " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		local Objective = teams[team_].objective
		local ColorObj = teams[team_].color2
		ColorObj.a = 255 * fade
		draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

net.Receive("cri_roundend", function()
	local whowin = net.ReadBool()
	zb.EndMenu.Open({
		sound = whowin and "zbattle/criresp/failedSWAT.mp3" or "ambient/alarms/warningbell1.wav",
		statusText = function(ply)
			if ply:GetNetVar("handcuffed", false) then return " — обезврежен" end
			if not ply:Alive() then return " — мёртв" end
			return ""
		end,
	})
end)

function MODE:RoundStart()
	zb.EndMenu.Close()
end

