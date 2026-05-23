MODE.name = "gwars"
local MODE = MODE

local playstart
local ended

local MusicVolume = GetConVar("snd_musicvolume")

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation2 = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	//music_themes/ghetto_loop.wav
	//music_themes/ghetto_start.wav
	
end)

local teams = {
	[0] = {
		objective = "Kill all groove mazafakas",
		name = "a Bloodz Member",
		color1 = Color(180, 0, 0),
		color2 = Color(180, 0, 0)
	},
	[1] = {
		objective = "Kill all bloodz mazafakas",
		name = "a Groove Member",
		color1 = Color(0, 180, 0),
		color2 = Color(0, 180, 0)
	},
}
local lerpsnd = 0.3
function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift", 
	size = ScreenScale(12), 
	extended = true, 
	weight = 650,
	antialias = true,
	italic = false
})

function MODE:HUDPaint()
	//if !lply.organism or !lply.organism.fear then return end

	local timeBeforeSWAT = (zb.ROUND_START - CurTime() + 120)
	if timeBeforeSWAT > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeSWAT, "%02i:%02i:%02i")
		local text = "00:00:00"
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w, h = surface.GetTextSize(text)
		local w2, h2 = surface.GetTextSize("11:11:11 time left before SWAT arrives!")
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + w, sh * 0.05)
		surface.DrawText("time left before SWAT arrives!")
		//draw.SimpleText(" left before SWAT arrives!", "timer_Font2", sw * 0.432, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		//draw.SimpleText(time, "timer_Font2", sw * 0.36, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0.3 * MusicVolume:GetFloat())
					station:Play()
				end
			end)

			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, !ended and (lply:Alive() and lply.organism and !lply.organism.otrub and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeSWAT <= 0 and 2 or 0), 0, 1) or 0.3) or 0)
		
		if zb.ROUND_START + 12 < CurTime() then
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
				GWARS_LoopStation:Play()
				
				if IsValid(GWARS_LoopStation2) then
					GWARS_LoopStation2:SetVolume(0)
					GWARS_LoopStation2:Play()
				end
			end
		end

		if IsValid(GWARS_LoopStation) and GWARS_LoopStation:GetState() == GMOD_CHANNEL_PLAYING then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
		end
	
		if timeBeforeSWAT <= 0 then
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(lerpsnd * MusicVolume:GetFloat())
			end
			
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(0)
			end
		end
	end

	if zb.ROUND_START + 8.5 < CurTime() then return end

	if not lply:Alive() then return end
	zb.RemoveFade()
	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
	draw.SimpleText("ZBattle | Gang Wars", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Rolename = teams[team_].name
	local ColorRole = teams[team_].color1
	ColorRole.a = 255 * fade
	draw.SimpleText("You are " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	local Objective = teams[team_].objective
	local ColorObj = teams[team_].color2
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

end