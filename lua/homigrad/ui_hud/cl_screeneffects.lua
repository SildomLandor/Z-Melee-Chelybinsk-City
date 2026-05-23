local ScrW, ScrH = ScrW(), ScrH()
hook.Add("OnScreenSizeChanged", "hg_screeneffects_scr", function()
	ScrW, ScrH = ScrW(), ScrH()
end)

local function DrawSunEffect()
	local sun = util.GetSunInfo()
	if !sun then return end
	if !sun.obstruction == 0 or sun.obstruction == 0 or !sun.direction then return end
	local sunpos = EyePos() + sun.direction * 1024 * 4
	local scrpos = sunpos:ToScreen()
	local dot = (sun.direction:Dot(EyeVector()) - 0.8) * 5
	if dot <= 0 then return end
	DrawSunbeams(0.1, 0.15 * dot * sun.obstruction, 0.1, scrpos.x / ScrW, scrpos.y / ScrH)
end

hg.postprocess = hg.postprocess or {}
local postprs = hg.postprocess
postprs.addtiveLayer = {
	bloom_darken = 0,
	bloom_mul = 0,
	bloom_sizex = 0,
	bloom_sizey = 0,
	bloom_passes = 0,
	bloom_colormul = 0,
	bloom_colorr = 0,
	bloom_colorg = 0,
	bloom_colorb = 0,
	blur_addalpha = 0,
	blur_drawalpha = 0,
	blur_delay = 0,
	toytown = 0,
	toytown_h = 0,
	brightness = 0,
	sharpen = 0,
	sharpen_dist = 0
}

postprs.layers = postprs.layers or {}
local layers = postprs.layers
local layers_name = {}
function postprs.LayerAdd(name, tab)
	tab.weight = 0
	layers_name[#layers_name + 1] = name
	layers[name] = tab
end

function postprs.LayerWeight(name, lerp, value)
	layers[name].weight = LerpFT(lerp, layers[name].weight, value)
end

function postprs.LayerSetWeight(name, value)
	layers[name].weight = value
end

local addtiveLayer = postprs.addtiveLayer

local h = {
	["$pp_colour_addr"] = 0.012,
	["$pp_colour_addg"] = -0.006,
	["$pp_colour_addb"] = 0.018,
	["$pp_colour_brightness"] = -0.045,
	["$pp_colour_contrast"] = 1.12,
	["$pp_colour_colour"] = 0.28,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0,
}

local tab = table.Copy(h)
local hook_Run = hook.Run
local potatoTab = table.Copy(h)

hook.Add("RenderScreenspaceEffects", "homigrad", function()
	if hg.LightPostFX and hg.LightPostFX() then
		DrawColorModify(potatoTab)
		hook_Run("Post Post Pre Post Processing")
		return
	end

	hook_Run("Post Processing")

	local extraBright = 0
	for i = 1, #layers_name do
		local layer = layers[layers_name[i]]
		extraBright = extraBright + Lerp(layer.weight, 0, layer.brightness or 0)
	end

	tab["$pp_colour_brightness"] = h["$pp_colour_brightness"] + extraBright
	DrawColorModify(tab)

	hook_Run("Post Pre Post Processing")
	hook_Run("Post Post Processing")

	if hg.postprocess and hg.postprocess.RunExtra then
		hg.postprocess.RunExtra()
	end

	hook_Run("Post Post Pre Post Processing")
end)

postprs.LayerAdd("main", {
	bloom_darken = 0.64,
	bloom_mul = 0.5,
	bloom_sizex = 4,
	bloom_sizey = 4,
	bloom_passes = 2,
	bloom_colormul = 1,
	bloom_colorr = 1,
	bloom_colorg = 1,
	bloom_colorb = 1
})

postprs.LayerAdd("water", {
	bloom_darken = 0.15,
	bloom_mul = 1,
	bloom_sizex = 30,
	bloom_sizey = 30,
	bloom_passes = 2,
	bloom_colormul = 1,
	bloom_colorr = 0.05,
	bloom_colorg = 0.5,
	bloom_colorb = 1,
	blur_addalpha = 0.1,
	blur_drawalpha = 0.5,
	blur_delay = 0.01
})

postprs.LayerAdd("water2", {
	toytown = 6,
	toytown_h = 4
})

postprs.LayerAdd("water3", {
	brightness = -0.5
})

local oldWaterLevel, lastWater = 0, 0
local LayerWeight = postprs.LayerWeight
local LayerSetWeight = postprs.LayerSetWeight
local CurTime = CurTime
local timecheck = CurTime()
hook.Add("Post Processing", "Main", function()
	local ply = lply:Alive() and lply or lply:GetNWEntity("spect")
	if !IsValid(ply) then return end
	local waterLevel = oldWaterLevel
	if timecheck < CurTime() then
		local pos = hg.eye(lply)
		if !pos then return end

		waterLevel = (ply:WaterLevel() == 3) or ((ply:WaterLevel() > 1) and bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER)

		timecheck = CurTime() + 0.1
	end

	local time = CurTime()

	if oldWaterLevel != waterLevel and waterLevel then
		lastWater = time + 2
	end

	local animpos = lastWater - time
	if animpos > 0 then
		LayerSetWeight("water3", animpos)
	else
		LayerSetWeight("water3", 0)
	end

	if waterLevel then
		LayerWeight("main", 0.1, 0)
		LayerWeight("water", 0.1, 1)
		LayerWeight("water2", 0.1, 1)
	else
		LayerWeight("main", 0.5, 1)
		LayerWeight("water", 0.5, 0)
		LayerWeight("water2", 0.01, 0)
	end

	oldWaterLevel = waterLevel
	DrawSunEffect()
end)

local painMat = Material("effects/shaders/zb_grain")
local noiseMat = Material("effects/shaders/zb_grainwhite")
local vignetteMat = Material("effects/shaders/zb_vignette")
local assimilationMat = Material("effects/shaders/zb_assimilation")
local coldMat = Material("effects/shaders/zb_colda")
local grainMat = Material("effects/shaders/zb_grain2")
local heatMat = Material("effects/shaders/zb_heat")
local blindMat = Material("effects/shaders/zb_blind")

local PainLerp = 0
local O2Lerp = 0
local assimilatedLerp = 0
local tempLerp = 36.6

local show_image_time = 0
local show_some_images_time = 0
local lobotomy_mats = {
	Material("overlays/photopsiaoverlay1.png"),
	Material("overlays/photopsiaoverlay2.png"),
	Material("overlays/photopsiaoverlay3.png"),
	Material("overlays/photopsiaoverlay4.png"),
	Material("overlays/photopsiaoverlay5.png"),
	Material("overlays/peripheralorboverlay.png"),
	Material("overlays/tallflash1.png"),
	Material("overlays/tallflash2.png"),
	Material("overlays/tallflash3.png")
}

local function stopthings()
	PainLerp = 0
	O2Lerp = 0
	shockLerp = 0
	assimilatedLerp = 0
	tempLerp = 36.6
	consciousnessLerp = 1

	lply.tinnitus = 0

	if IsValid(NoiseStation) then
		NoiseStation:Stop()
		NoiseStation = nil
	end

	if IsValid(NoiseStation2) then
		NoiseStation2:Stop()
		NoiseStation2 = nil
	end

	if IsValid(BrainTraumaStation) then
		BrainTraumaStation:Stop()
		BrainTraumaStation = nil
	end

	if IsValid(BrainTraumaStation2) then
		BrainTraumaStation2:Stop()
		BrainTraumaStation2 = nil
	end

	if IsValid(BrainTraumaStation3) then
		BrainTraumaStation3:Stop()
		BrainTraumaStation3 = nil
	end

	if IsValid(BrainTraumaStation4) then
		BrainTraumaStation4:Stop()
		BrainTraumaStation4 = nil
	end

	if IsValid(BrainTraumaStation5) then
		BrainTraumaStation5:Stop()
		BrainTraumaStation5 = nil
	end

	if IsValid(Tinnitus) then
		Tinnitus:Stop()
		Tinnitus = nil
	end

	if IsValid(AssimilationStation) then
		AssimilationStation:Stop()
		AssimilationStation = nil
	end
end

local stations = {0.06, 0.1, 0.15, 0.22, 0.27}

local choosera = 1
local tempolerp = 0
local lerpblood = 0
local addtime = CurTime()
local hurtoverlay = Material("zcity/neurotrauma/damageOverlay.png", "smooth")

local depthFrame = -1

local function updScreen()
	render.UpdateScreenEffectTexture()
end

local function updDepth()
	updScreen()
	if depthFrame == FrameNumber() then return end
	render.UpdateFullScreenDepthTexture()
	depthFrame = FrameNumber()
end

local LerpFT = LerpFT or Lerp

local fx = {
	active = false,
	drawBlind = false,
	drawHurt = false,
	drawHeat = false,
	drawAssim = false,
	drawGrain = false,
	drawCold = false,
	drawPain = false,
	drawO2 = false,
	drawBrainBlur = false,
	drawBrainImg = false,
	drawOtrubBlur = false,
	blindness = 0,
	consciousness = 0,
	heat = 0,
	pain = 0,
	shock = 0,
	o2 = 0,
	brain = 0,
	otrub = false,
	lobotomy_index = 0,
}

local function ensurePainBeat()
	if IsValid(PainStation) and PainStation:GetState() == GMOD_CHANNEL_PLAYING then return end
	sound.PlayFile("sound/zbattle/pain_beat.ogg", "noblock noplay", function(station)
		if IsValid(station) then
			station:SetVolume(0)
			station:Play()
			station:SetTime(math.min(math.Rand(0, station:GetLength()), 139))
			PainStation = station
			station:EnableLooping(true)
		end
	end)
end

local function ensureAssimSound()
	if IsValid(AssimilationStation) and AssimilationStation:GetState() == GMOD_CHANNEL_PLAYING then return end
	sound.PlayFile("sound/zbattle/furry/conversion/assimilation_noise3.ogg", "noblock noplay", function(station)
		if IsValid(station) then
			station:SetVolume(0)
			station:Play()
			AssimilationStation = station
			station:EnableLooping(true)
		end
	end)
end

local function ensureBrainSound(chooser)
	if IsValid(BrainTraumaStation) and choosera == chooser and BrainTraumaStation:GetState() == GMOD_CHANNEL_PLAYING then return end
	if IsValid(BrainTraumaStation) then
		BrainTraumaStation:Stop()
		BrainTraumaStation = nil
	end
	choosera = chooser
	sound.PlayFile("sound/zcitysnd/real_sonar/brainhemorrhagestage" .. chooser .. ".mp3", "noblock noplay", function(station)
		if IsValid(station) then
			station:SetVolume(0)
			station:Play()
			BrainTraumaStation = station
			station:EnableLooping(true)
		end
	end)
end

hook.Add("Think", "ItHurtsThink", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")

	if IsValid(PainStation) then
		PainStation:SetVolume(0)
	end

	if !lply:Alive() and !IsValid(spect) then stopthings() fx.active = false return end
	if !lply:Alive() and viewmode != 1 then stopthings() fx.active = false return end

	local organism = lply:Alive() and lply.organism or (IsValid(spect) and spect.organism)
	if !organism or !organism.brain then stopthings() fx.active = false return end
	if !organism.o2 or !isnumber(organism.o2[1]) or !organism.analgesia then stopthings() fx.active = false return end

	local org = organism
	fx.active = true
	fx.otrub = org.otrub

	local o2raw = (org.o2[1] or 0) + (org.CO or 0)
	local brain = org.brain or 0

	O2Lerp = LerpFT(0.01, O2Lerp, (30 - o2raw) * (org.otrub and 2 or 10) + (brain * 100) * (org.otrub and 1 or 5))
	tempLerp = LerpFT(0.01, tempLerp, org.temperature)

	local pain = math.max((org.pain or 0) - 15, 0)
	local shock = (org.shock or 0) * 1 + (1 - org.consciousness) * 40
	shockLerp = LerpFT(0.01, shockLerp or 0, shock + (lply.suiciding and math.max(0, org.heartbeat - 90) or 0))
	consciousnessLerp = LerpFT(org.consciousness < (consciousnessLerp or 1) and 1 or 0.01, consciousnessLerp or 1, org.consciousness)
	PainLerp = LerpFT(0.05, PainLerp, math.max(pain * (org.otrub and 0.2 or 1), 0))
	assimilatedLerp = LerpFT(0.01, assimilatedLerp, org.assimilated or 0)

	local tempo = math.Clamp((5 - (tempLerp - 29)) * 0.5 - 5 * (org.heartbeat < 1 and 1 or 0), 0, 5)
	tempolerp = LerpFT(0.01, tempolerp, tempo)

	fx.drawBlind = org.blindness or (amtflashed or 0) >= 0.8
	fx.blindness = fx.drawBlind and ((((org.blindness and math.Round(org.blindness) == 0) or (amtflashed or 0) >= 0.8) and 0) or org.blindness) or 0

	fx.drawHurt = (org.consciousness or 1) < 0.7
	if fx.drawHurt then
		lerpblood = LerpFT(0.01, lerpblood or 0, math.Clamp((0.7 - org.consciousness) * 5, 0, 1) * 255)
		addtime = addtime + FrameTime() / 6
	end

	fx.drawHeat = tempLerp > 38
	fx.heat = fx.drawHeat and (tempLerp - 38) or 0

	fx.drawAssim = assimilatedLerp > 0.001
	fx.drawGrain = (org.consciousness or 1) < 1
	fx.consciousness = fx.drawGrain and (1 - consciousnessLerp) or 0

	fx.drawCold = tempolerp > 0
	fx.drawPain = PainLerp > 0.001 or shockLerp > 5 or org.otrub
	fx.drawO2 = O2Lerp > 1
	fx.o2 = O2Lerp
	fx.brain = brain

	if fx.drawPain or PainLerp > 0.01 then
		ensurePainBeat()
	end

	if fx.drawAssim then
		ensureAssimSound()
		if IsValid(AssimilationStation) then
			AssimilationStation:SetVolume(assimilatedLerp * 2)
		end
	elseif IsValid(AssimilationStation) then
		AssimilationStation:Stop()
		AssimilationStation = nil
	end

	if brain > 0.01 then
		local chooser = 1
		for i = 1, #stations do
			if stations[i] < brain then chooser = i end
		end
		ensureBrainSound(chooser)
		if IsValid(BrainTraumaStation) then
			BrainTraumaStation:SetVolume(math.Clamp(!org.otrub and brain * 2 or 0, 0, 1))
		end
	elseif IsValid(BrainTraumaStation) then
		BrainTraumaStation:Stop()
		BrainTraumaStation = nil
	end

	if lply.tinnitus and lply.tinnitus > CurTime() and lply:Alive() then
		if !IsValid(Tinnitus) or Tinnitus:GetState() != GMOD_CHANNEL_PLAYING then
			sound.PlayFile("sound/zcitysnd/real_sonar/tinnitus" .. math.random(3) .. ".mp3", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					Tinnitus = station
					station:EnableLooping(true)
				end
			end)
		elseif IsValid(Tinnitus) then
			Tinnitus:SetVolume(math.min(math.max(lply.tinnitus - CurTime(), 0) / 10, 1))
		end
	elseif IsValid(Tinnitus) then
		Tinnitus:Stop()
		Tinnitus = nil
	end

	fx.drawBrainBlur = false
	fx.drawBrainImg = false
	brain_motionblur = false

	if brain > 0.1 and !org.otrub then
		if show_some_images_time > 0 then
			fx.drawBrainBlur = true
			brain_motionblur = true
			show_some_images_time = show_some_images_time - 1

			if show_image_time <= 0 and math.random(10 * (1 - brain)) < 2 then
				show_image_time = 250 * (0.1 * 3) * math.Rand(0.1, 1) * (math.random(2) == 1 and 0.1 or 1)
				fx.lobotomy_index = math.random(#lobotomy_mats)
			end

			if show_image_time > 0 then
				fx.drawBrainImg = true
				show_image_time = show_image_time - 1
			end
		else
			show_some_images_time = math.random(1200) < (brain * 15) and 250 or 0
		end
	else
		show_image_time = 0
		fx.lobotomy_index = 0
	end

	if fx.drawO2 and fx.o2 > 50 and !org.otrub then
		if !IsValid(NoiseStation2) or NoiseStation2:GetState() != GMOD_CHANNEL_PLAYING then
			sound.PlayFile("sound/zbattle/conscioustypebeat.ogg", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					station:SetTime(math.min(brain / 0.5 * station:GetLength(), 87))
					NoiseStation2 = station
					station:EnableLooping(true)
				end
			end)
		elseif IsValid(NoiseStation2) then
			NoiseStation2:SetVolume(math.Clamp((fx.o2 - 50) / 100 + (brain > 0.3 and (brain - 0.3) * 5 or 0), 0, 0.25))
		end
	elseif IsValid(NoiseStation2) then
		NoiseStation2:SetVolume(0)
	end

	if fx.drawO2 and fx.o2 > 20 and org.otrub then
		if !IsValid(NoiseStation) or NoiseStation:GetState() != GMOD_CHANNEL_PLAYING then
			sound.PlayFile("sound/zbattle/unconscious_type_beat.ogg", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					station:SetTime(math.min(brain / 0.5 * station:GetLength(), 200))
					NoiseStation = station
					station:EnableLooping(true)
				end
			end)
		elseif IsValid(NoiseStation) then
			NoiseStation:SetVolume(math.Clamp((fx.o2 - 30) / 100 + (brain > 0.3 and (brain - 0.3) * 5 or 0), 0, 1))
		end
	elseif IsValid(NoiseStation) then
		NoiseStation:SetVolume(0)
	end

	if !fx.drawO2 and IsValid(NoiseStation) then
		NoiseStation:Stop()
		NoiseStation = nil
	end

	if fx.drawPain then
		local strobe = math.ease.InOutSine(math.abs(math.cos(CurTime() * 2))) * PainLerp / 2
		fx.pain = PainLerp + strobe
		fx.shock = shockLerp
		fx.drawOtrubBlur = org.otrub
		if IsValid(PainStation) then
			PainStation:SetVolume(math.Clamp(math.Remap(fx.pain, 0, 120, 0, 2), 0, 2))
		end
	else
		fx.drawOtrubBlur = false
	end

	fx.active = fx.drawBlind or fx.drawHurt or fx.drawHeat or fx.drawAssim or fx.drawGrain or fx.drawCold
		or fx.drawPain or fx.drawO2 or fx.drawBrainBlur or fx.drawBrainImg
end)

hook.Add("Post Post Processing", "ItHurts", function()
	if !fx.active then return end

	local ct = CurTime()
	local org_otrub = fx.otrub

	if fx.drawBlind then
		updDepth()
		blindMat:SetFloat("$c0_x", 5)
		blindMat:SetFloat("$c0_y", ct)
		blindMat:SetFloat("$c0_z", math.Round(fx.blindness))
		render.SetMaterial(blindMat)
		render.DrawScreenQuad()
	end

	if fx.drawHurt then
		local amt = (math.cos(addtime) + math.sin(addtime * 3) + math.sin(addtime * 2)) / 90
		local amt2 = (math.sin(addtime) + math.cos(addtime * 5) + math.sin(addtime * 6)) / 90
		hurtoverlay:SetMatrix("$basetexturetransform", Matrix({
			{1 - amt, amt, 0, -amt2 / 2},
			{amt2, 1 - amt2, 0, -amt / 2},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		}))
		surface.SetMaterial(hurtoverlay)
		surface.SetDrawColor(0, 0, 0, lerpblood)
		surface.DrawTexturedRect(-ScrW * 2, -ScrH * 2, ScrW * 5, ScrH * 5)
	end

	if fx.drawHeat then
		updScreen()
		heatMat:SetFloat("$c0_x", -ct * 0.25)
		heatMat:SetFloat("$c0_y", 0.06 * fx.heat)
		heatMat:SetFloat("$c2_x", (math.sin(ct) - 2) * fx.heat)
		render.SetMaterial(heatMat)
		render.DrawScreenQuad()
	end

	if fx.drawAssim then
		updScreen()
		assimilationMat:SetFloat("$c0_x", -ct)
		assimilationMat:SetFloat("$c0_y", assimilatedLerp * 3)
		local ctime = ct * 2
		local val = math.Clamp(3 - 1 / 3 * (math.sin(ctime * 2.8862) + math.cos(ctime * 1.115) - math.sin(ctime * 0.6215) + 3), 0, 5)
		local val2 = math.Clamp(1 - 1 / 6 * (math.sin(ctime * 1.1862) + math.cos(ctime * 2.315) - math.sin(ctime * 0.9215) + 3), 0, 1)
		assimilationMat:SetFloat("$c1_y", val)
		assimilationMat:SetFloat("$c1_x", val2 - 0.5)
		render.SetMaterial(assimilationMat)
		render.DrawScreenQuad()
	end

	if fx.drawGrain then
		updDepth()
		local c = fx.consciousness
		grainMat:SetFloat("$c0_x", ct)
		grainMat:SetFloat("$c0_y", 0.5)
		grainMat:SetFloat("$c0_z", c * 3)
		grainMat:SetFloat("$c1_x", c)
		grainMat:SetFloat("$c1_y", 10)
		grainMat:SetFloat("$c1_z", c)
		grainMat:SetFloat("$c2_x", 0)
		grainMat:SetFloat("$c2_y", 0)
		grainMat:SetFloat("$c2_z", 0)
		grainMat:SetFloat("$c3_x", 0)
		render.SetMaterial(grainMat)
		render.DrawScreenQuad()
	end

	if fx.drawCold then
		updScreen()
		coldMat:SetFloat("$c0_y", tempolerp)
		render.SetMaterial(coldMat)
		render.DrawScreenQuad()
	end

	if fx.drawPain then
		local pain = fx.pain
		local shock = fx.shock
		updScreen()

		vignetteMat:SetFloat("$c2_x", ct + 10000)
		vignetteMat:SetFloat("$c0_z", org_otrub and 5 or (pain / 40 + math.max(shock - 5, 0) / 3))
		vignetteMat:SetFloat("$c1_y", org_otrub and 10 or (pain / 40 + math.max(shock - 5, 0) / 3))
		render.SetMaterial(vignetteMat)
		render.DrawScreenQuad()

		updScreen()

		painMat:SetFloat("$c2_x", ct + 10000)
		painMat:SetFloat("$c0_y", 0.8)
		painMat:SetFloat("$c0_z", 1)
		painMat:SetFloat("$c1_x", math.Clamp(pain / 90, 0, 0.75))
		painMat:SetFloat("$c1_y", math.Clamp(pain / 90, 0, 0.75))
		render.SetMaterial(painMat)
		render.DrawScreenQuad()

		if fx.drawOtrubBlur then
			DrawMotionBlur(0.1, 1., 0.01)
			lply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), 2, 0.5)
		end
	end

	if fx.drawBrainBlur then
		DrawMotionBlur(0.1, 1., 0.1)
	end

	if fx.drawBrainImg and fx.lobotomy_index > 0 then
		local rand = 5
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(lobotomy_mats[fx.lobotomy_index])
		surface.DrawTexturedRect(-math.random(rand), -math.random(rand), ScrW + math.random(rand), ScrH + math.random(rand))
	end

	if fx.drawO2 then
		updScreen()
		local o2 = fx.o2
		noiseMat:SetFloat("$c0_y", 1 - o2 / 200)
		noiseMat:SetFloat("$c0_z", 1)
		noiseMat:SetFloat("$c1_x", math.Clamp(o2 / 200, 0, 2))
		noiseMat:SetFloat("$c1_y", o2 * (!org_otrub and 0.05 or 1))
		noiseMat:SetFloat("$c2_x", ct + 10000)
		render.SetMaterial(noiseMat)
		render.DrawScreenQuad()
	end
end)

hook.Add("Post Post Processing", "HorrorMood", function()
	if hg.LightPostFX and hg.LightPostFX() then return end
	if fx.drawPain then return end

	local ct = CurTime()
	updScreen()

	vignetteMat:SetFloat("$c2_x", ct + 10000)
	vignetteMat:SetFloat("$c0_z", 0.55)
	vignetteMat:SetFloat("$c1_y", 0.55)
	render.SetMaterial(vignetteMat)
	render.DrawScreenQuad()

	painMat:SetFloat("$c2_x", ct + 10000)
	painMat:SetFloat("$c0_y", 0.8)
	painMat:SetFloat("$c0_z", 1)
	painMat:SetFloat("$c1_x", 0.07)
	painMat:SetFloat("$c1_y", 0.07)
	render.SetMaterial(painMat)
	render.DrawScreenQuad()
end)

hook.Add("Player_Death", "ItDoesntNow", function(ply)
	if !((ply == lply) or (ply == lply:GetNWEntity("spect"))) then return end
	stopthings()
	fx.active = false
end)

hook.Add("Player Spawn", "ItDoesntNow", function(ply)
	if ply != lply then return end
	stopthings()
	fx.active = false
end)

local function removeflash()
	if IsValid(lply.blindflash) then
		lply.blindflash:Remove()
	end
end

local lastFlashMode, lastFlashP, lastFlashY, lastFlashR
hook.Add("PreDrawOpaqueRenderables", "renderblindnessflash", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	if !lply:Alive() and !IsValid(spect) then removeflash() return end
	if !lply:Alive() and viewmode != 1 then removeflash() return end

	local organism = lply:Alive() and lply.organism or (IsValid(spect) and spect.organism)
	if !organism or isbool(organism) then return end

	if !(organism.blindness or (amtflashed or 0) >= 0.8) then removeflash() lastFlashMode = nil return end
	local blindness = ((organism.blindness and math.Round(organism.blindness) == 0) or amtflashed >= 0.8) and 0 or organism.blindness

	local eyesmode = math.Round(blindness)
	local view = render.GetViewSetup(true)
	local p, y, r = view.angles[1], view.angles[2], view.angles[3]
	y = y + (eyesmode == 2 and 90 or eyesmode == 1 and -90 or 0)
	p = eyesmode == 0 and p or 0

	if lastFlashMode == eyesmode and lastFlashP == p and lastFlashY == y and lastFlashR == r then return end
	lastFlashMode = eyesmode
	lastFlashP, lastFlashY, lastFlashR = p, y, r
	local Ang = Angle(p, y, r)

	if !IsValid(lply.blindflash) then
		lply.blindflash = ProjectedTexture()
		lply.blindflash:SetTexture("effects/flashlight001")
		lply.blindflash:SetEnableShadows(false)
		lply.blindflash:SetConstantAttenuation(.1)
	end

	lply.blindflash:SetFarZ(40)
	lply.blindflash:SetFOV(160)
	lply.blindflash:SetBrightness(1)
	lply.blindflash:SetPos(view.origin)
	lply.blindflash:SetAngles(Ang)
	lply.blindflash:Update()
end)
