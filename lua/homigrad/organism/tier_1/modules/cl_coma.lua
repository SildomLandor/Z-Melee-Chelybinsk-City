local LerpFT = LerpFT or function(speed, cur, target)
	return Lerp(FrameTime() * (speed or 1) * 60, cur or 0, target)
end

hg.comaLerp = hg.comaLerp or 0
hg.comaDepthLerp = hg.comaDepthLerp or 0
hg.comaPulseLerp = hg.comaPulseLerp or 0

local comaMat = Material("vgui/gradient-d")
local comaMat2 = Material("vgui/gradient-u")

local function plyCommand(ply, cmd)
	ply.cmdtimer = ply.cmdtimer or 0
	if CurTime() < ply.cmdtimer then return end
	ply.cmdtimer = CurTime() + 0.12
	ply:ConCommand(cmd)
end

hook.Add("HG_OnComa", "cl_coma_fx", function(ply)
	if ply ~= LocalPlayer() then return end
	hg.comaLerp = 1
	hg.comaDepthLerp = ply.organism and ply.organism.coma_depth or 1
	plyCommand(ply, "soundfade 100 40")
end)

hook.Add("HG_OnWakeComa", "cl_coma_fx", function(ply)
	if ply ~= LocalPlayer() then return end
	plyCommand(ply, "soundfade 60 8")
end)

hook.Add("Post Post Pre Post Processing", "coma-effects", function()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local org = lply:Alive() and lply.organism or (IsValid(spect) and spect.organism)
	if not org or not org.brain then
		hg.comaLerp = LerpFT(0.04, hg.comaLerp, 0)
		return
	end

	local inComa = org.coma or false
	local depth = org.coma_depth or 0
	local flicker = (org.coma_flicker or 0) > 0

	hg.comaLerp = LerpFT(inComa and 0.08 or 0.03, hg.comaLerp, inComa and 1 or 0)
	hg.comaDepthLerp = LerpFT(0.05, hg.comaDepthLerp, depth)

	if hg.comaLerp < 0.02 then return end

	local k = hg.comaLerp * (0.65 + hg.comaDepthLerp * 0.35)
	local pulse = math.sin(CurTime() * (0.9 + hg.comaDepthLerp * 0.6)) * 0.5 + 0.5
	hg.comaPulseLerp = LerpFT(0.2, hg.comaPulseLerp, pulse)

	if inComa and lply:Alive() then
		local fade = math.floor(85 + hg.comaDepthLerp * 15 + pulse * 8)
		plyCommand(lply, "soundfade " .. fade .. " 30")
	end

	local scrW, scrH = ScrW(), ScrH()
	local a = 255 * k * (flicker and 0.55 or 0.92)
	surface.SetDrawColor(0, 0, 0, a)
	surface.SetMaterial(comaMat)
	surface.DrawTexturedRect(0, 0, scrW, scrH * (0.35 + hg.comaDepthLerp * 0.2))
	surface.SetMaterial(comaMat2)
	surface.DrawTexturedRect(0, scrH - scrH * (0.35 + hg.comaDepthLerp * 0.2), scrW, scrH)

	if flicker then
		local flash = math.sin(CurTime() * 24) * 0.5 + 0.5
		DrawColorModify({
			["$pp_colour_addr"] = flash * 0.02,
			["$pp_colour_addg"] = flash * 0.01,
			["$pp_colour_addb"] = flash * 0.03,
			["$pp_colour_brightness"] = flash * 0.04 - 0.02,
			["$pp_colour_contrast"] = 1 + flash * 0.08,
			["$pp_colour_colour"] = 0.85 + flash * 0.1,
			["$pp_colour_mulr"] = 0,
			["$pp_colour_mulg"] = 0,
			["$pp_colour_mulb"] = 0,
		})
	end

	DrawMotionBlur(0.04 + k * 0.08, k * 0.85, 0.01 + k * 0.02)
end)

hook.Add("ModifyTinnitusFactor", "coma-muffle", function(factor)
	local org = LocalPlayer().organism
	if not org or not org.coma then return end
	return factor + (org.coma_depth or 0) * 40
end)
