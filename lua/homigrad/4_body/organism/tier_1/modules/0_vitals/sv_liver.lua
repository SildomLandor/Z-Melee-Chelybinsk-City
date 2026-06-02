--local Organism = hg.organism
hg.organism.module.liver = {}
local module = hg.organism.module.liver
module[1] = function(org)
	org.liver = 0
end

module[2] = function(owner, org, mulTime)
	if not org.alive or org.hearstop then return end
	local damage = org.liver or 0
	local stage = org.alcoholStage or 0
	local load = org.alcoholLiverLoad or 0
	local alco = org.alcohol or 0
	local withdrawal = org.alcoholWithdrawal or 0

	if alco > 0.55 then
		local tox = math.Clamp((alco - 0.55) / 2.3, 0, 1)
		local delta = mulTime / 3200 * tox * (1 + load * 0.6)
		if stage >= 3 then delta = delta * 1.7 end
		org.liver = math.Clamp(damage + delta, 0, 1)
	else
		local recover = mulTime / 2500
		recover = recover * (1 - load * 0.6)
		if withdrawal > 0.6 then recover = recover * 0.6 end
		org.liver = math.max(damage - recover, 0)
	end

	local liverState = math.Clamp(1 - (org.liver or 0), 0.15, 1)
	org.alcoholLiverClearMul = liverState
end