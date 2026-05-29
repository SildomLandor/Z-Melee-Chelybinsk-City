local Near = {
	"ied/ied_detonate_01.wav", "ied/ied_detonate_02.wav", "ied/ied_detonate_03.wav",
}
local Far = {
	"ied/ied_detonate_dist_01.wav", "ied/ied_detonate_dist_02.wav", "ied/ied_detonate_dist_03.wav",
}

local ExplosiveSound = {
	Fire = { Near = Near, Far = Far, Effect = "pcf_jack_incendiary_ground_sm2" },
	Sharpnel = { Near = Near, Far = Far, Effect = "pcf_jack_groundsplode_medium" },
	Normal = { Near = Near, Far = Far, Effect = "pcf_jack_groundsplode_small" },
}

local upAng = vector_up:Angle()
local effectCount = 0
local effectResetAt = 0
local CurTime = CurTime
local table_Random = table.Random
local math_random = math.random
local EmitSound = EmitSound
local render_GetViewSetup = render.GetViewSetup
local ParticleEffect = ParticleEffect

local function playBoomSnd(snd, sndFar, pos)
	local delay = pos:Distance(render_GetViewSetup(true).origin) / 17836
	timer.Simple(delay, function()
		EmitSound(sndFar, pos, 0, CHAN_WEAPON, 1, 110, 0, 100, 0, nil)
		EmitSound(snd, pos, 0, CHAN_AUTO, 1, delay > 0.6 and 140 or 110, 0, 100, 0, nil)
	end)
end

net.Receive("hg_booom", function()
	local pos = net.ReadVector()
	local cfg = ExplosiveSound[net.ReadString()]
	if not cfg then return end

	local t = CurTime()
	if effectResetAt < t then effectCount = 0 end
	if effectCount < 10 then
		ParticleEffect(cfg.Effect, pos, upAng)
		effectCount = effectCount + 1
		effectResetAt = t + 0.2
	end

	playBoomSnd(table_Random(cfg.Near), table_Random(cfg.Far), pos)
end)
