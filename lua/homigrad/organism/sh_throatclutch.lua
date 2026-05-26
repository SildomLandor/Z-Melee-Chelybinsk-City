hg.organism = hg.organism or {}

function hg.organism.ThroatClutchAmt(org)
	if not org or not org.alive then return 0 end
	return math.max(org.arteria or 0, org.trachea or 0)
end

function hg.organism.IsThroatClutchActive(rag, org)
	if not IsValid(rag) then return false end
	org = org or rag.organism
	if org and hg.organism.ThroatClutchAmt(org) >= 0.12 then return true end
	return (rag.beingChokedUntil or 0) > CurTime()
end
