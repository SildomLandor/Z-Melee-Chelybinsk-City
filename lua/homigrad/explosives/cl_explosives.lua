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
local effectPerMSec = 0
local effectCDCurTime = 0

local function PlaySndDist(snd, snd2, pos, isOnWater, watersnd)
	if SERVER then return end
	local delay = pos:Distance(render.GetViewSetup(true).origin) / 17836
	timer.Simple(delay, function()
		if isOnWater then
			EmitSound(watersnd, pos, 0, CHAN_WEAPON, 1, 100, 0, 85, 0, nil)
			return
		end
		EmitSound(snd2, pos, 0, CHAN_WEAPON, 1, 110, 0, 100, 0, nil)
		EmitSound(snd, pos, 0, CHAN_AUTO, 1, delay > 0.6 and 140 or 110, 0, 100, 0, nil)
	end)
end

net.Receive("hg_booom", function()
	local pos = net.ReadVector()
	local typ = net.ReadString()
	local cfg = ExplosiveSound[typ]

	if effectCDCurTime < CurTime() then
		effectPerMSec = 0
	end
	if effectPerMSec < 10 then
		ParticleEffect(cfg.Effect, pos, upAng)
		effectPerMSec = effectPerMSec + 1
		effectCDCurTime = CurTime() + 0.2
	end

	PlaySndDist(table.Random(cfg.Near), table.Random(cfg.Far), pos, false, "huy")
end)
