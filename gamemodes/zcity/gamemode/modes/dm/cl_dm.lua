
MODE.name = "dm"

local MODE = MODE

local radius = nil
local mapsize = 7500

local roundend = false

local snds = {
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/ujuwzquyre/01.%20A%20Grim%20Feeling.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/zgagxqybov/02.%20Alley%20.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/qsoislqepd/17.%20Hazardous.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/zqxkrixwbn/26.%20Rooftops.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/kvlgywwwnt/13.%20Escape.mp3"
}

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)

local function restartMusic()
	local snd = snds[math.random(#snds)]

	if IsValid(dmmusic) then
		dmmusic:Stop()
		dmmusic = nil
	end
	
	sound.PlayURL(snd, "mono noblock noplay", function(station, errID, err)
		if IsValid(station) then
			station:EnableLooping(true)
			station:SetVolume(0.1)
			
			dmmusic = station
		else
			print(errID, err)
		end
	end)
end


net.Receive("dm_start",function()
	roundend = false

	hg.DynaMusic:Start( "mirrors_edge" )

	zb.RemoveFade()
	
	ZonePos = net.ReadVector()
	zonedistance = net.ReadFloat()

    surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
	sound.PlayFile( "sound/ambient/energy/force_field_loop1.wav", "noblock", function( station, errCode, errStr )
		if ( IsValid( station ) ) then
			zb.SoundStation = station
			
			station:Play()
			station:EnableLooping( true )
			station:SetVolume(0)
		end
	end )
end)

hook.Add("Think", "ZoneSoundThink", function()
	if CurrentRound() and CurrentRound().name ~= "dm" then return end
	local station = zb.SoundStation
	if not IsValid(station) then return end
	if deathmatch_nozone:GetBool() then return end
	local radius = MODE.GetZoneRadius()
	local volume = math.Clamp((LocalPlayer():GetPos():Distance(ZonePos) - radius) + 200,0,200) / 200
	station:SetVolume(volume)
end)

local fighter = {
    objective = "Kill everyone.",
    name = "Fighter",
    color1 = Color(0,120,190)
}

--local zonemodel = ClientsideModel("models/hunter/misc/sphere375x375.mdl",RENDERGROUP_TRANSLUCENT)
--zonemodel:SetNoDraw(true)
--zonemodel:SetMaterial("hmcd_dmzone")

local mat = Material("hmcd_dmzone")

local mapsize = 7500

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if(!bSkybox and !isDraw3DSkybox) and !deathmatch_nozone:GetBool() then
		local radius = MODE.GetZoneRadius()
		render.SetMaterial(mat)
		render.DrawSphere( ZonePos, -radius, 60, 60, color_white )
	end
	--zonemodel:DrawModel()
end

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
	
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
	if zb.ROUND_START + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(zb.ROUND_START + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local ply = LocalPlayer()
		--if IsValid(dmmusic) then
		--	if dmmusic:GetTime() >= (dmmusic:GetLength() - 1) then
		--		restartMusic()
--
		--		return
		--	end
--
		--	if dmmusic:GetState() != GMOD_CHANNEL_PLAYING then
		--		dmmusic:Play()
		--		
		--		return
		--	end
--
		--	local vol = math.Clamp((CurTime() - (zb.ROUND_START + 22)),0.1, ply:Alive() and ply.organism.otrub and 0.1 or 0.2 + math.min((ply.organism.adrenaline or 0) * 25,2))
		--	if roundend then
		--		vol =  math.Clamp((roundend - CurTime() + 1) / 2,0.1, ply:Alive() and ply.organism.otrub and 0.1 or 0.2 + math.min((ply.organism.adrenaline or 0) * 25,2))
		--	end
		--	local musicVolume = GetConVar("snd_musicvolume"):GetFloat()
		--	dmmusic:SetVolume(vol*musicVolume)
		--end
	end
	
	 
	if not lply:Alive() then return end
    if zb.ROUND_START + 8.5 < CurTime() then return end
	zb.RemoveFade()
    local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(),0,1)
    
    draw.SimpleText("Homicide | DeathMatch", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = fighter.name
	local ColorRole = fighter.color1
    ColorRole.a = 255 * fade
    draw.SimpleText("You are a "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = fighter.objective
    local ColorObj = fighter.color1
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)


function MODE:RoundStart()
    for i,ply in player.Iterator() do
		ply.won = nil
		ply.most_violent_player = nil
    end

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end