local Rand = math.Rand
local random = math.random

local function throatGaspSound(ply, vol)
	local fem = ThatPlyIsFemale(ply)
	if random(3) == 1 then
		ply:EmitSound("zcitysnd/real_sonar/" .. (fem and "female" or "male") .. "_cough" .. random(4) .. ".mp3", vol, random(88, 108))
	else
		ply:EmitSound("zcitysnd/real_sonar/" .. (fem and "fe" or "") .. "male_wheeze" .. random(5) .. ".mp3", vol, random(82, 98))
	end
end

function hg.organism.ThroatClutchGasp(org, force)
	local ply = org.owner
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if org.otrub and not force then return end

	org.nextThroatGasp = org.nextThroatGasp or 0
	if not force and org.nextThroatGasp > CurTime() then return end

	local amt = hg.organism.ThroatClutchAmt(org)
	if amt < 0.1 then return end

	org.nextThroatGasp = CurTime() + Rand(2, 4.5) / math.max(amt, 0.35)
	throatGaspSound(ply, 42 + amt * 28)
end

hook.Add("Org Clear", "throatclutch", function(org)
	org.nextThroatGasp = nil
end)

hook.Add("Org Think", "throatclutch", function(owner, org)
	if hg.organism.ThroatClutchAmt(org) < 0.15 then return end
	if org.otrub or org.choking then return end
	hg.organism.ThroatClutchGasp(org)
end)

hook.Add("Player Think", "throatclutch_fake", function(ply)
	if CLIENT then return end
	local rag = ply.FakeRagdoll
	if not IsValid(rag) then return end

	local org = ply.organism
	if not org or org.choking then return end
	if IsValid(rag.ConsLH) or IsValid(rag.ConsRH) then return end

	local amt = hg.organism.ThroatClutchAmt(org)
	if amt < 0.12 or not org.canmove then return end

	local head = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 10))
	local lh = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 5))
	local rh = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 7))
	if not IsValid(head) or not IsValid(lh) or not IsValid(rh) then return end

	local pos = head:GetPos()
	local ang = head:GetAngles()
	local neck = pos + ang:Forward() * 2 + ang:Up() * 1
	local wobble = math.sin(CurTime() * 8) * 1.5 * amt

	if not org.larmamputated then
		hg.ShadowControl(rag, 5, 0.001, nil, nil, nil, neck + ang:Right() * (-3 + wobble), 70 + amt * 30, 50)
	end
	if not org.rarmamputated then
		hg.ShadowControl(rag, 7, 0.001, nil, nil, nil, neck + ang:Right() * (3 - wobble), 70 + amt * 30, 50)
	end
end)
