hg = hg or {}
hg.ConVars = hg.ConVars or {}
hg.postprocess = hg.postprocess or {}
hg.postprocess.extra = hg.postprocess.extra or {}

local CreateClientConVar = CreateClientConVar
local GetConVar = GetConVar
local ConVarExists = ConVarExists

local hg_potatopc = ConVarExists("hg_potatopc") and GetConVar("hg_potatopc") or CreateClientConVar("hg_potatopc", "0", true, false, "Toggle potato (low-end pc) mode", 0, 1)
hg.ConVars.potatopc = hg_potatopc

CreateClientConVar("hg_tpik_near_only", "0", true, false, "TPIK only for local player and spect target", 0, 1)

function hg.LightPostFX()
	return hg_potatopc:GetBool()
end

function hg.postprocess.AddExtra(id, fn)
	hg.postprocess.extra[id] = fn
end

function hg.postprocess.RunExtra()
	for _, fn in pairs(hg.postprocess.extra) do
		fn()
	end
end

local perfPresets = {
	mid = {
		hg_potatopc = 1,
		hg_anims_draw_distance = 768,
		hg_tpik_distance = 640,
		hg_anim_fps = 40,
		hg_attachment_draw_distance = 512,
		hg_optimise_scopes = 1,
		hg_maxsmoketrails = 4,
		hg_bulletholes = 80,
		hg_blood_draw_distance = 512,
		hg_blood_fps = 15,
		hg_tpik_near_only = 0,
		mat_hdr_level = 0,
	},
	low = {
		hg_potatopc = 1,
		hg_anims_draw_distance = 512,
		hg_tpik_distance = 384,
		hg_anim_fps = 30,
		hg_attachment_draw_distance = 384,
		hg_optimise_scopes = 2,
		hg_maxsmoketrails = 2,
		hg_bulletholes = 40,
		hg_blood_draw_distance = 384,
		hg_blood_fps = 12,
		hg_tpik_near_only = 1,
		mat_hdr_level = 0,
	},
	off = {
		hg_potatopc = 0,
		hg_anims_draw_distance = 1024,
		hg_tpik_distance = 1024,
		hg_anim_fps = 66,
		hg_attachment_draw_distance = 1024,
		hg_optimise_scopes = 1,
		hg_maxsmoketrails = 10,
		hg_bulletholes = 200,
		hg_blood_draw_distance = 1024,
		hg_blood_fps = 24,
		hg_tpik_near_only = 0,
	},
}

function hg.ApplyPerfPreset(name)
	local preset = perfPresets[name]
	if not preset then return false end

	for cvar, val in pairs(preset) do
		local cv = GetConVar(cvar)
		if not cv then continue end
		if cv:GetMax() == 1 and cv:GetMin() == 0 and type(val) == "number" and val <= 1 then
			cv:SetBool(val >= 1)
		else
			cv:SetInt(val)
		end
	end

	return true
end

local baselineSamples, baselineTag

local function finishBaseline()
	if not baselineSamples then return end
	local n = #baselineSamples
	if n < 1 then
		baselineSamples = nil
		return
	end

	local sum = 0
	for i = 1, n do sum = sum + baselineSamples[i] end
	local avg = math.Round(sum / n, 1)

	local msg = string.format("[hg perf] %s — avg %.1f FPS (%d samples). Запиши в блокнот для сравнения.", baselineTag or "?", avg, n)
	print(msg)
	chat.AddText(Color(120, 200, 120), msg)
	baselineSamples = nil
	baselineTag = nil
end

concommand.Add("hg_fps_baseline", function(_, _, args)
	local tag = args[1] or "test"
	local sec = math.Clamp(tonumber(args[2]) or 5, 2, 30)

	if baselineSamples then
		finishBaseline()
	end

	baselineTag = tag
	baselineSamples = {}
	chat.AddText(Color(200, 200, 120), string.format("[hg perf] Замер «%s» %d сек — стой на месте, смотри в сцену.", tag, sec))

	local tEnd = CurTime() + sec
	local last = RealTime()

	timer.Create("hg_fps_baseline", 0.1, 0, function()
		local now = RealTime()
		local dt = now - last
		last = now
		if dt > 0 then
			baselineSamples[#baselineSamples + 1] = 1 / dt
		end

		if CurTime() >= tEnd then
			timer.Remove("hg_fps_baseline")
			finishBaseline()
		end
	end)
end)