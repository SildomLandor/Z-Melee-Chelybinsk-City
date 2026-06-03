zb = zb or {}
-- сюда можете не смотреть это баланс...
zb.DefaultKarma = 190
zb.MaximumHarm = 45
zb.MaxGuiltPair = 200
zb.MaxKarma = 200
zb.MinKarma = -60

zb.KarmaLossScale = 100
zb.GuiltPerHarmAmt = 60
zb.RetaliatonGuilt = 100
zb.GuiltBanThreshold = 100

function zb.GuiltRetal(guilt)
	return math.min((guilt or 0) / zb.RetaliatonGuilt, 1)
end

function zb.GuiltAddFromAmt(amt)
	return amt * zb.GuiltPerHarmAmt
end

function zb.GuiltKarmaLossFromAmt(amt)
	return amt * zb.KarmaLossScale * 2
end

function zb.GuiltKarmaGain(ply, karma)
	if karma >= zb.MaxKarma then return 0 end
	if karma <= zb.DefaultKarma then return ply.KarmaGain or 0.75 end

	local t = (karma - zb.DefaultKarma) / (zb.MaxKarma - zb.DefaultKarma)
	return (ply.KarmaGain or 0.75) * math.max(1 - t * 0.85, 0.15)
end

function zb.GuiltKarmaMul(victim)
	if not victim:IsPlayer() then return 1 end
	return math.Clamp((victim.Karma or zb.DefaultKarma) / zb.DefaultKarma, 1, 1.2)
end
