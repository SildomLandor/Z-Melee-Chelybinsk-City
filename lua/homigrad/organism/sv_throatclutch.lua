local Rand, random, sin, cos = math.Rand, math.random, math.sin, math.cos
local CurTime = CurTime

local function ragIsChokingSomeone(rag)
	if IsValid(rag.ConsLH) and IsValid(rag.ConsLH.choking) then return true end
	if IsValid(rag.ConsRH) and IsValid(rag.ConsRH.choking) then return true end
end

function hg.organism.ThroatClutchRagdoll(rag, org)
	if not IsValid(rag) then return end
	org = org or rag.organism
	if ragIsChokingSomeone(rag) then return end

	local headPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 10))
	local lhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 5))
	local rhandPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 7))
	if not IsValid(headPhys) or not IsValid(lhandPhys) or not IsValid(rhandPhys) then return end

	local pos = headPhys:GetPos()
	local t = CurTime()
	local spd, damp = 220, 90

	if not org or not org.larmamputated then
		local lpos = lhandPhys:GetPos()
		local grip = pos - (pos - lpos):GetNormalized() * (2 + sin(t * 2) * 0.35)
		hg.ShadowControl(rag, 3, 0.001, nil, nil, nil, grip, spd, damp)
		hg.ShadowControl(rag, 5, 0.001, nil, nil, nil, grip, spd, damp)
	end
	if not org or not org.rarmamputated then
		local rpos = rhandPhys:GetPos()
		local grip = pos - (pos - rpos):GetNormalized() * (2 + cos(t * 1.8) * 0.35)
		hg.ShadowControl(rag, 2, 0.001, nil, nil, nil, grip, spd, damp)
		hg.ShadowControl(rag, 7, 0.001, nil, nil, nil, grip, spd, damp)
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
	if org.otrub then return end

	hg.organism.ThroatClutchGasp(org)

	if owner:IsPlayer() and owner:Alive() and not IsValid(owner.FakeRagdoll) and amt >= 0.2 then
		org.needfake = true
	end
end, HOOK_LOW)
