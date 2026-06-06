local Clamp, Approach = math.Clamp, math.Approach

hg.organism.module.alcohol = {}
local module = hg.organism.module.alcohol

local function getStage(level, tol)
	local effective = math.max(level - tol * 0.55, 0)
	if effective < 0.12 then return 0 end
	if effective < 0.7 then return 1 end
	if effective < 1.7 then return 2 end
	return 3
end

function hg.organism.AddAlcohol(org, dose)
	if not org or dose <= 0 then return 0 end

	org.alcohol = Clamp((org.alcohol or 0) + dose, 0, 4)
	org.alcoholAbsorb = 0
	org.alcoholRecentDose = CurTime()
	org.alcoholPeak = math.max(org.alcoholPeak or 0, org.alcohol or 0)

	return org.alcohol
end

module[1] = function(org)
	org.alcohol = 0
	org.alcoholAbsorb = 0
	org.alcoholStage = 0
	org.alcoholPeak = 0
	org.alcoholTolerance = 0
	org.alcoholDependence = 0
	org.alcoholWithdrawal = 0
	org.hangover = 0
	org.alcoholLiverLoad = 0
	org.blackoutRisk = 0
	org.alcoholBlackoutUntil = 0
	org.nextAlcoholStumble = 0
	org.nextAlcoholTurnShift = 0
	org.alcoholTurnLag = 0
	org.alcoholTurnLagTarget = 0
	org.nextWithdrawalShake = 0
	org.alcoholRecoilBonus = 0
end

module[2] = function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() then
		org.alcohol = Approach(org.alcohol or 0, 0, timeValue / 160)
		return
	end

	local liverState = org.alcoholLiverClearMul or Clamp(1 - (org.liver or 0), 0.15, 1)
	local absorb = math.min(org.alcoholAbsorb or 0, timeValue * 0.18)
	if absorb > 0 then
		org.alcoholAbsorb = math.max(org.alcoholAbsorb - absorb, 0)
		org.alcohol = Clamp((org.alcohol or 0) + absorb, 0, 4)
	end

	local stage = getStage(org.alcohol or 0, org.alcoholTolerance or 0)
	org.alcoholStage = stage

	local clearRate = (timeValue / 190) * liverState * (1 - math.min(stage, 2) * 0.08)
	org.alcohol = Approach(org.alcohol or 0, 0, math.max(clearRate, timeValue / 500))
	org.alcoholPeak = math.max((org.alcoholPeak or 0) - timeValue / 450, org.alcohol or 0)

	local heavy = Clamp(((org.alcohol or 0) - 1.1) / 2.2, 0, 1)
	local regular = Clamp(((org.alcohol or 0) - 0.35) / 1.5, 0, 1)
	org.alcoholTolerance = Clamp((org.alcoholTolerance or 0) + timeValue * regular / 900 - timeValue / 2600, 0, 1.3)
	org.alcoholDependence = Clamp((org.alcoholDependence or 0) + timeValue * heavy / 1300 - timeValue / 4200, 0, 1.4)

	local noAlcohol = (org.alcohol or 0) < 0.12 and (org.alcoholAbsorb or 0) <= 0.01
	local withdrawalBase = Clamp(((org.alcoholDependence or 0) - 0.3) / 1.1, 0, 1)
	if noAlcohol and withdrawalBase > 0 then
		org.alcoholWithdrawal = Clamp((org.alcoholWithdrawal or 0) + timeValue * (0.18 + withdrawalBase * 0.5), 0, 1.6)
	else
		org.alcoholWithdrawal = Approach(org.alcoholWithdrawal or 0, 0, timeValue / 35)
	end

	local hangoverIn = Clamp((org.alcoholPeak or 0) - (org.alcohol or 0), 0, 2.8)
	if (org.alcohol or 0) < 0.3 and hangoverIn > 0.3 then
		org.hangover = Clamp((org.hangover or 0) + timeValue * hangoverIn / 140, 0, 1.5)
	else
		org.hangover = Approach(org.hangover or 0, 0, timeValue / 90)
	end

	org.alcoholLiverLoad = Clamp((org.alcoholLiverLoad or 0) + timeValue * heavy / 200 - timeValue / 350, 0, 1.4)

	if stage > 0 then
		local sed = (org.alcohol or 0) * (1 - Clamp((org.alcoholTolerance or 0) * 0.4, 0, 0.4))
		local buzz = Clamp(((org.alcohol or 0) - 0.12) / 1.2, 0, 1)
		local analgesiaBoost = Clamp((sed - 0.25) * 0.35, 0, 0.8)
		org.analgesia = math.max(org.analgesia or 0, analgesiaBoost)

		local drunkRecoil = Clamp(sed * 0.2, 0, 0.5)
		org.recoilmul = (org.recoilmul or 1) - (org.alcoholRecoilBonus or 0) + drunkRecoil
		org.alcoholRecoilBonus = drunkRecoil
		org.meleespeed = math.max((org.meleespeed or 1) - Clamp(sed * 0.12, 0, 0.35), 0.55)
		org.disorientation = Clamp(math.max(org.disorientation or 0, sed * 0.5 + buzz * 0.8), 0, 10)
		org.stamina.subadd = (org.stamina.subadd or 0) + sed * 0.2

		if stage >= 2 then
			org.shock = math.max(org.shock or 0, (org.shock or 0) + timeValue * (sed - 0.35) * 0.3)
			org.fearadd = (org.fearadd or 0) + timeValue * 0.06

			local drunkControl = Clamp((sed - 0.45) / 1.4, 0, 1)
			if drunkControl > 0 then
				if (org.nextAlcoholTurnShift or 0) <= CurTime() then
					org.nextAlcoholTurnShift = CurTime() + math.Rand(0.18, 0.4)
					org.alcoholTurnLagTarget = math.Rand(-3.5, 3.5) * (0.5 + drunkControl)
				end

				org.alcoholTurnLag = Approach(org.alcoholTurnLag or 0, org.alcoholTurnLagTarget or 0, timeValue * (2.2 + drunkControl * 2.5))

				local ang = owner:EyeAngles()
				ang.y = ang.y + (org.alcoholTurnLag or 0) * math.min(timeValue, 0.08)
				owner:SetEyeAngles(ang)

				if (org.nextAlcoholStumble or 0) <= CurTime() and math.random() < Clamp(timeValue * 0.18 * drunkControl, 0, 0.09) then
					org.nextAlcoholStumble = CurTime() + math.Rand(2.5, 5.5)
					org.lightstun = math.max(org.lightstun or 0, CurTime() + math.Rand(0.18, 0.45))
					org.stamina.subadd = (org.stamina.subadd or 0) + 0.2 * drunkControl
					owner:ViewPunch(Angle(math.Rand(0.8, 1.8), math.Rand(-2.8, 2.8), math.Rand(-0.8, 0.8)))
				end
			end
		end
	else
		org.recoilmul = (org.recoilmul or 1) - (org.alcoholRecoilBonus or 0)
		org.alcoholRecoilBonus = 0
		org.alcoholTurnLag = Approach(org.alcoholTurnLag or 0, 0, timeValue * 3)
		org.alcoholTurnLagTarget = 0
	end

	local withdrawal = org.alcoholWithdrawal or 0
	if withdrawal > 0.01 then
		org.disorientation = Clamp((org.disorientation or 0) + timeValue * withdrawal * 0.1, 0, 10)
		org.painadd = (org.painadd or 0) + timeValue * (2 + withdrawal * 5)
		org.shock = Clamp((org.shock or 0) + timeValue * withdrawal * 0.5, 0, 120)
		org.stamina.subadd = (org.stamina.subadd or 0) + withdrawal * 0.4
		org.fearadd = (org.fearadd or 0) + timeValue * withdrawal * 0.08

		if (org.nextWithdrawalShake or 0) < CurTime() and math.random() < Clamp(withdrawal * 0.04, 0, 0.12) then
			org.nextWithdrawalShake = CurTime() + math.random(6, 12)
			if IsValid(owner) then
				owner:ViewPunch(AngleRand(-2, 2))
			end
		end
	end

	local hangover = org.hangover or 0
	if hangover > 0.01 then
		org.stamina.subadd = (org.stamina.subadd or 0) + hangover * 0.16
		org.painadd = (org.painadd or 0) + timeValue * hangover * 2.2
		org.disorientation = Clamp((org.disorientation or 0) + timeValue * hangover * 0.04, 0, 10)
	end

	local cardioRisk = Clamp(((org.heartbeat or 70) - 150) / 80, 0, 1) * 0.2
	local breathingRisk = Clamp((10 - (org.o2 and org.o2[1] or 10)) / 10, 0, 1) * 0.45
	local bleedingRisk = Clamp((3000 - (org.blood or 5000)) / 2000, 0, 1) * 0.2
	local baseRisk = Clamp(((org.alcohol or 0) - 1.8) / 1.8, 0, 1)
	local risk = baseRisk + cardioRisk + breathingRisk + bleedingRisk
	org.blackoutRisk = Clamp(risk, 0, 2)

	if stage >= 3 and risk > 0.35 then
		org.consciousness = Approach(org.consciousness or 1, 0, timeValue / (8 - math.min(risk * 2, 5)))
		if (org.alcoholBlackoutUntil or 0) <= CurTime() and math.random() < Clamp(timeValue * math.max(risk - 0.45, 0) * 0.01, 0, 0.08) then
			org.alcoholBlackoutUntil = CurTime() + math.random(2, 6)
		end
	end

	if (org.alcoholBlackoutUntil or 0) > CurTime() then
		org.needotrub = true
	end

end
