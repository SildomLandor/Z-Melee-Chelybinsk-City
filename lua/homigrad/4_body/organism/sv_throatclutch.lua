local Rand, random = math.Rand, math.random

local function ragIsChokingSomeone(rag)
	if IsValid(rag.ConsLH) and IsValid(rag.ConsLH.choking) then return true end
	if IsValid(rag.ConsRH) and IsValid(rag.ConsRH.choking) then return true end
	return false
end

local function shouldClutchRagdoll(rag, org, opts)
	if not IsValid(rag) then return false end
	if ragIsChokingSomeone(rag) then return false end

	org = org or rag.organism
	local beingChoked = (rag.beingChokedUntil or 0) > CurTime()
	local neckslit = org and org.neckslit == true

	if not beingChoked and not neckslit then return false end
	if not opts.force and org and org.otrub and not beingChoked then return false end

	local root = rag:GetPhysicsObject()
	if not opts.force and not beingChoked and IsValid(root) and root:GetVelocity():Length() > 100 then
		return false
	end

	return true, org, beingChoked
end

function hg.organism.ThroatClutchRagdoll(rag, org, opts)
	opts = opts or {}

	local ok, ragOrg, beingChoked = shouldClutchRagdoll(rag, org, opts)
	if not ok then return end

	local headPhys = rag:GetPhysicsObjectNum(hg.realPhysNum(rag, 10))
	if not IsValid(headPhys) then return end

	local pos = headPhys:GetPos()
	local ang = headPhys:GetAngles()
	local right = ang:Right()
	local forward = ang:Forward()
	local gripAng = Angle(ang.p, ang.y, ang.r)

	local lGrip = pos - right * 4 + forward * 2
	local rGrip = pos + right * 4 + forward * 2

	local forced = opts.force or beingChoked
	local ss = forced and 0.001 or 0.05
	local foreSpd, foreDamp = forced and 1200 or 120, forced and 120 or 40
	local handSpd, handDamp = forced and 400 or 60, forced and 80 or 30

	if not ragOrg or not ragOrg.larmamputated then
		hg.ShadowControl(rag, 4, ss, gripAng, 90, 40, lGrip, foreSpd, foreDamp)
		hg.ShadowControl(rag, 5, ss, gripAng, 0, 0, lGrip, handSpd, handDamp)
	end

	if not ragOrg or not ragOrg.rarmamputated then
		hg.ShadowControl(rag, 6, ss, gripAng, 90, 40, rGrip, foreSpd, foreDamp)
		hg.ShadowControl(rag, 7, ss, gripAng, 0, 0, rGrip, handSpd, handDamp)
	end
end

local function throatGaspSound(ply, vol)
	local fem = ThatPlyIsFemale(ply)
	if random(3) == 1 then
		ply:EmitSound("zcitysnd/real_sonar/" .. (fem and "female" or "male") .. "_cough" .. random(4) .. ".mp3", vol, random(88, 108))
		return
	end

	ply:EmitSound("zcitysnd/real_sonar/" .. (fem and "fe" or "") .. "male_wheeze" .. random(5) .. ".mp3", vol, random(82, 98))
end

function hg.organism.ThroatClutchGasp(org, force)
	if not org then return end

	local ply = org.owner
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if org.otrub and not force then return end

	local neckslit = org.neckslit == true
	local amt = hg.organism.ThroatClutchAmt(org)
	if neckslit then
		amt = math.max(amt, 0.2)
	end
	if amt < 0.1 then return end

	org.nextThroatGasp = org.nextThroatGasp or 0
	if not force and org.nextThroatGasp > CurTime() then return end

	org.nextThroatGasp = CurTime() + Rand(2, 4.5) / math.max(amt, 0.35)
	throatGaspSound(ply, 42 + amt * 28)
end

hook.Add("Org Clear", "throatclutch", function(org)
	org.nextThroatGasp = nil
end)

hook.Add("Org Think", "throatclutch", function(owner, org)
	if not org or org.otrub then return end

	local neckslit = org.neckslit == true
	local amt = hg.organism.ThroatClutchAmt(org)
	if not neckslit and amt < 0.15 then return end

	hg.organism.ThroatClutchGasp(org)

	if neckslit and owner:IsPlayer() and owner:Alive() and not IsValid(owner.FakeRagdoll) then
		org.needfake = true
	end
end, HOOK_LOW)
