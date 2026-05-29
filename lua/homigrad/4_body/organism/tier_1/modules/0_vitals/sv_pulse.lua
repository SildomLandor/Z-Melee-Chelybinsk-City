local min, max, Round, halfValue2 = math.min, math.max, math.Round, util.halfValue2
--local Organism = hg.organism
hg.organism.module.pulse = {}
local module = hg.organism.module.pulse
module[1] = function(org)
	org.heart = 0
	org.heartstop = false
	org.vfib = false
	org.vfib_severity = 0
	org.vfib_at = 0
	org.vfib_until = 0
	org.adren_vfib_cd = 0
	org.heartrestart_at = 0
	org.adren_tox = 0
	org.adren_doses = 0
	org.pulse = 70 -- that's the blood pressure
	org.heartbeat = 70
	org.spo2 = 100

	org.tempchanging = 0
	org.heatbuff = 30 -- seconds of heat supply
	org.needed_temp = 36.7
end

function hg.organism.should_gain_fear(org)
	return ((org.pain > 30) or (org.blood < 3000) or (org.bleed > 1))// + (org.just_damaged_bone and ((org.just_damaged_bone + 10 - CurTime()) >= 10) and 10 or 0)
end

local function beginVfib(org, minSeverity)
	if org.vfib or org.heartstop then return end
	if (org.adren_doses or 0) < 2 then return end
	if (org.adren_vfib_cd or 0) > CurTime() then return end
	local tox = org.adren_tox or 0
	if tox < 0.72 then return end
	org.vfib = true
	org.vfib_at = CurTime()
	org.vfib_until = CurTime() + 18
	if minSeverity then
		org.vfib_severity = math.max(org.vfib_severity or 0, minSeverity)
	end
	if not org.isPly or not IsValid(org.owner) or not org.owner:Alive() then return end
	local ply = org.owner
	org.needotrub = true
	org.needfake = true
	org.consciousness = math.min(org.consciousness or 1, 0.05)
	ply:Notify("Блять... Сердце....", true, "vfib", 0)
	ply.fullsend = true
	timer.Simple(0, function()
		if not IsValid(ply) or not ply:Alive() then return end
		local o = ply.organism
		if o and o.vfib and not o.heartstop then
			hg.Fake(ply, nil, true, true)
		end
	end)
end

module[2] = function(owner, org, timeValue)
	local heart = 1 - org.heart
	local brain = math.Clamp(1 - org.brain * 1.5,0,1)
	local o2 = org.o2
	local o2 = halfValue2(o2[1], o2.range, o2.k)
	org.spo2 = math.Clamp(math.Round((org.o2[1] / math.max(org.o2.range, 1)) * 100), 0, 100)

	//if org.isPly and not org.otrub and (heart == 0) then org.owner:Notify("My torso hurts.",true,"heart",6) end
	//if org.isPly and not org.otrub and org.heartstop then org.owner:Notify("",true,"heartstop",6) end

	local stamina = org.stamina
	
	local pulse = 70-- + 120 * ((stamina.max or 180) - stamina[1]) / (stamina.max or 180) * (org.lungsfunction and 1 or 0)
	--pulse = pulse + math.min(org.adrenaline, 2) * 40 + (!org.otrub and math.max(org.fear * 50, 0) or 0)
	pulse = org.alive and pulse or 0
	pulse = math.Clamp(pulse, 0, 200)
	
	org.pulse = math.Approach(org.pulse, pulse, pulse > org.pulse and timeValue * 2 or timeValue * 2)
	
	--local k = heart * o2 * (1 / math.Clamp((org.blood - 2000) / 3000,0.2,1)) * brain * (org.heartstop and 0.1 or 1) --* halfValue2(stamina[2], stamina.fatigueRange, stamina.fatigueK)
	local k = heart * o2 * (math.Clamp((org.blood - 1000) / 4000,0,1)) * brain * (org.heartstop and 0.1 or 1)
	pulse = pulse * k
	pulse = pulse * (math.Clamp(math.Remap(org.temperature, 28, 36.7, 0.5, 1), 0.5, 1))
	
	org.pulse = math.Approach(org.pulse, pulse, heart == 0 and timeValue * 10 or timeValue * 5)

	org.fearadd = math.Clamp(org.fearadd, 0, 3)

	local heartbeat = org.pulse < 70 and 70 + (70 - org.pulse) * 4 or org.pulse

	local runnin_or_exhausted = org.analgesia < 1 and (org.stamina.sub > 0 or org.stamina[1] < (org.stamina.max * 0.66))
	org.heartbeat = math.Approach(org.heartbeat, math.max(heartbeat - 10, runnin_or_exhausted and ((1 - math.min(1, org.stamina[1] / (org.stamina.max * 1))) * 110 + 90) or 60), !runnin_or_exhausted and timeValue * 2 or timeValue * 15)
	
	heartbeat = heartbeat + (owner.suiciding and 50 or 0)
	heartbeat = heartbeat + 40 * math.max(0, org.fear)
	heartbeat = heartbeat + math.Clamp(org.shock, 0, 40)
	heartbeat = heartbeat + math.Clamp(org.pain, 40, 80) - 40
	heartbeat = heartbeat + 40 * math.min(org.adrenaline, 3)
	heartbeat = heartbeat - 40 * math.min(org.analgesia / 2.5, 1)
	heartbeat = heartbeat + 100 * math.Clamp(math.Remap(org.temperature, 40, 42, 0, 1), 0, 1)
	heartbeat = heartbeat - 160 * (1 - math.Clamp(math.Remap(org.temperature, 28, 36.7, 0, 1), 0, 1))

	org.heartbeat = math.Approach(org.heartbeat, heartbeat, heartbeat > org.heartbeat and timeValue * 5 or timeValue * 3)
	local adren = org.adrenaline
	local doses = org.adren_doses or 0

	if doses > 0 and adren < 1.2 and (org.last_adren_dose or 0) + 90 < CurTime() then
		org.adren_doses = math.max(doses - 1, 0)
		doses = org.adren_doses
	end

	local vfibRisk = 0
	vfibRisk = vfibRisk + math.Clamp((org.heartbeat - 230) / 100, 0, 1) * 0.7
	vfibRisk = vfibRisk + math.Clamp((org.temperature - 39) / 2, 0, 1) * 0.45
	vfibRisk = vfibRisk + math.Clamp(org.shock / 65, 0, 1) * 0.35
	vfibRisk = vfibRisk + math.Clamp((12 - org.o2[1]) / 12, 0, 1) * 0.6
	vfibRisk = vfibRisk + math.Clamp((org.brain - 0.45) / 0.55, 0, 1) * 0.3
	if doses >= 2 then
		vfibRisk = vfibRisk + math.Clamp((adren - 2.2) / 2.3, 0, 1) * 0.55
	end

	local toxIn = 0
	if doses >= 2 then
		toxIn = math.Clamp((adren - 2.8) / 1.8, 0, 1) + math.Clamp((org.adrenalineAdd or 0) / 4, 0, 1) * 0.25
	end
	if toxIn > 0.05 then
		org.adren_tox = math.min((org.adren_tox or 0) + timeValue * toxIn * 0.22, 1)
	else
		org.adren_tox = math.max((org.adren_tox or 0) - timeValue * 0.06, 0)
	end
	if doses >= 2 then
		vfibRisk = vfibRisk + (org.adren_tox or 0) * 0.65
	end

	if doses >= 2 and (org.adren_tox or 0) > 0.55 and (org.heart or 1) > 0 and not org.heartstop then
		org.heart = math.max((org.heart or 1) - timeValue * 0.012 * org.adren_tox, 0)
	end

	if doses >= 2 and (org.adren_tox or 0) > 0.65 and adren < 1.6 and not org.heartstop and not org.vfib then
		org.heartbeat = math.Approach(org.heartbeat, math.min(org.heartbeat, 58), timeValue * 14)
	end

	if not org.heartstop and not org.vfib and vfibRisk > 0 and doses >= 2 then
		local chance = math.Clamp(vfibRisk * timeValue * 0.25, 0, 0.2)
		if math.Rand(0, 1) < chance then
			beginVfib(org)
		end
	end

	if org.vfib and not org.heartstop then
		org.vfib_severity = math.Clamp((org.vfib_severity or 0) + timeValue * (0.3 + vfibRisk * 0.9), 0, 1)
		org.pulse = math.Approach(org.pulse, 0, timeValue * (10 + org.vfib_severity * 45))
		org.heartbeat = math.Approach(org.heartbeat, math.random(220, 320), timeValue * 90)

		if (org.vfib_until or 0) < CurTime() and (org.vfib_at or 0) + 8 < CurTime() then
			local stopChance = math.Clamp(timeValue * (0.04 + org.vfib_severity * 0.18), 0, 0.25)
			if math.Rand(0, 1) < stopChance then
				org.heartstop = true
				org.adren_vfib_cd = CurTime() + 90
			end
		end
	else
		org.vfib_severity = math.max((org.vfib_severity or 0) - timeValue * 0.35, 0)
	end
	
	if org.heartbeat > 300 and not org.vfib and doses >= 2 and (org.adren_tox or 0) >= 0.72 then
		beginVfib(org, 0.45)
	end

	if not org.vfib and not org.heartstop then
		local minHeartbeat = 0
		if (org.heartrestart_at or 0) <= CurTime() and org.pulse > 12 then
			minHeartbeat = 25
		end
		org.heartbeat = math.Clamp(org.heartbeat, minHeartbeat, 220)
	end

	if org.heartstop then
		org.vfib = false
		org.vfib_severity = 0
		org.heartrestart_at = 0
		org.heartbeat = 0
	end

	org.fear = math.Approach(org.fear, (org.otrub and 0 or (org.fearadd > 0 and 1 or -1)), org.otrub and timeValue * 0.5 or (org.fearadd > 0 and (org.fear < 0 and timeValue * 5 * org.fearadd or timeValue / 5 * org.fearadd) or (org.fear <= 0 and timeValue / 240 or timeValue / 50)))
	-- less time to start fearing, more time to become calm again
	-- if no fear, in 3 minutes become slightly talkative, so would say random phrases to calm themselves in a current situation
	local gainfear = hg.organism.should_gain_fear(org)
	org.fearadd = math.Approach(org.fearadd, 0, gainfear and timeValue or timeValue / 4.9) -- 15 seconds to stop fearing something and start to calm down
	org.fearadd = math.Approach(org.fearadd, 1, gainfear and timeValue / 5 or 0)
	
	local adrenK = max(1 + org.adrenaline, 1)

	if not org.vfib and (org.pulse < 10 or org.brain >= 0.6) then org.heartstop = true end
	if org.temperature < 28 or org.temperature > 42 then org.heartstop = true end

	if org.temperature < 34 or org.temperature > 38 or org.blood < 4000 or org.pain > 20 then
		org.fear = math.max(org.fear, 0)
	end

	-- temperature
	local needed_temp = math.min(math.max(37 * (org.pulse / 45), 35), 36.7)
	local changeRate = timeValue / 60
	changeRate = changeRate * (org.temperature < needed_temp and math.Clamp(org.heatbuff / 60, 1, 2) or 1)
	if math.abs(org.tempchanging) < changeRate then
		org.temperature = math.Approach(org.temperature, needed_temp, changeRate)
	else
		org.needed_temp = needed_temp
	end
	
	if not org.heartstop then
		org.last_heartbeat = CurTime()
	end

	if org.heartstop and adren > 0 and (org.adrenaline_try or 0) < CurTime() then
		local blocked = doses >= 2 and ((org.adren_vfib_cd or 0) > CurTime() or (org.adren_tox or 0) > 0.55)
		if not blocked then
			local chance = math.Clamp(adren * 18, 0, 18)
			local rand = math.random(100)
			org.adrenaline_try = CurTime() + 0.35
			if chance > rand then
				org.heartstop = false
				org.heartbeat = 0
				org.heartrestart_at = CurTime() + 1.8
			end
		end
	end

	if org.heartstop then
		org.heartstoptime = org.heartstoptime or CurTime()
		if org.isPly then
			//org.owner:Notify("I'm feeling dizzy...", true, "heartstop", 10)
		end
	else
		if org.isPly then
			//org.owner:ResetNotification("heartstop")
		end
		org.heartstoptime = nil
	end

	if org.alive and org.heartstoptime and org.heartstoptime + 30 < CurTime() and (org.lastsoundtime or 0) < CurTime() and org.otrub then
		org.owner:EmitSound("breathing/agonalbreathing_"..math.random(13)..".wav", 60)
		--org.owner:EmitSound("breathing/agonalbreathing_"..math.random(13)..".wav", 50)
		
		org.lastsoundtime = CurTime() + math.random(25,35)
	end
end

--if org.heartstop then org.needotrub = true end --не совсем...
util.AddNetworkString("pulse")
function hg.organism.Pulse(owner, org, timeValue)
	local stamina = org.stamina
	if org.o2[1] > 1 and org.alive and org.heart < 1 and org.brain < 0.6 then
		--org.brain = max(org.brain - timeValue / 30, 0) --regen
	end--brain damage is usually permanent

	if owner:IsPlayer() and owner:Alive() then
		net.Start("pulse")
		net.Send(owner)
	end
end