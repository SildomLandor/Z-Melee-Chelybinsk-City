local Rand, random, sin, cos = math.Rand, math.random, math.sin, math.cos
local CurTime = CurTime

function hg.organism.ThroatClutchRagdoll(rag, org)
	if not IsValid(rag) then return end
	org = org or rag.organism
	if org and org.choking then return end
	if IsValid(rag.ConsLH) or IsValid(rag.ConsRH) then return end

	local headPhysRef = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 10))
	local lhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 5))
	local rhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 7))
	if not IsValid(headPhysRef) or not IsValid(lhandPhys) or not IsValid(rhandPhys) then return end

	local pos = headPhysRef:GetPos()
	local lpos = lhandPhys:GetPos()
	local rpos = rhandPhys:GetPos()
	local t = CurTime()

	if not org or not org.larmamputated then
		local leftOffset = pos - (pos - lpos):GetNormalized() * (2 + sin(t * 2) * 0.5)
		hg.ShadowControl(rag, 4, 0.001, nil, nil, nil, leftOffset, 80, 60)
		hg.ShadowControl(rag, 5, 0.001, nil, nil, nil, leftOffset, 80, 60)
	end
	if not org or not org.rarmamputated then
		local rightOffset = pos - (pos - rpos):GetNormalized() * (2 + cos(t * 1.8) * 0.5)
		hg.ShadowControl(rag, 6, 0.001, nil, nil, nil, rightOffset, 80, 60)
		hg.ShadowControl(rag, 7, 0.001, nil, nil, nil, rightOffset, 80, 60)
	end
end

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
	local amt = hg.organism.ThroatClutchAmt(org)
	if amt < 0.15 then return end
	if org.otrub or org.choking then return end

	hg.organism.ThroatClutchGasp(org)

	if owner:IsPlayer() and owner:Alive() and not IsValid(owner.FakeRagdoll) and amt >= 0.2 then
		org.needfake = true
	end
end)
