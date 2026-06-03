zb = zb or {}
zb.Experience = zb.Experience or {}

local EXP = zb.Experience

EXP.BandStep = 100
EXP.MaxRoundExp = 200
EXP.MaxNormalRoundExp = 100

EXP.Rewards = {
	minor = {4, 15},
	normal = {15, 30},
	major = {100, 200},
}

EXP.Bands = {}
for tier = 10, 1, -1 do
	local min = tier == 1 and 0 or EXP.BandStep * 2 ^ (tier - 2)
	local max = tier == 10 and 1e18 or EXP.BandStep * 2 ^ (tier - 1)
	EXP.Bands[#EXP.Bands + 1] = {
		icon = Material("vgui/mats_jack_awards/" .. tier),
		name = "",
		skill = {min, max},
	}
end

function EXP.RollReward(kind)
	local row = EXP.Rewards[kind or "normal"]
	if not row then return 0 end
	local cap = kind == "major" and EXP.MaxRoundExp or EXP.MaxNormalRoundExp
	return math.min(math.random(row[1], row[2]), cap)
end
