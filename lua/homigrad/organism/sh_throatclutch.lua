hg.organism = hg.organism or {}

function hg.organism.ThroatClutchAmt(org)
	if not org or not org.alive then return 0 end
	return math.max(org.arteria or 0, org.trachea or 0)
end
