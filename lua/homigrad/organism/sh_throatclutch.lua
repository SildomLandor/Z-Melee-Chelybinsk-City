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

function hg.organism.ShouldThroatClutchRagdollPose(rag, org)
	if not IsValid(rag) then return false end
	org = org or rag.organism
	if org and org.otrub then return false end
	if (rag.beingChokedUntil or 0) > CurTime() then return true end

	local amt = org and hg.organism.ThroatClutchAmt(org) or 0
	if amt < 0.2 then return false end
	if org and org.lasthit and org.lasthit + 2 > CurTime() then return false end

	local root = rag:GetPhysicsObject()
	if IsValid(root) and root:GetVelocity():Length() > 100 then return false end

	return true
end
