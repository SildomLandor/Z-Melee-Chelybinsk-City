local surrAnims = {
	{ "G_Surrender",  "g_surrenderloopArms",  "G_Surrenderend"  },
	{ "G_Surrender2", "g_surrenderloopArms2", "G_Surrenderend2" },
	{ "G_Surrender3", "g_surrenderloopArms3", "G_Surrenderend3" },
}

local kneelAnims = {
	{ "kneeldown",  "kneeldownloop",  "kneeldownEND"  },
	{ "kneeldown2", "kneeldown2loop", "kneeldown2END" },
	{ "kneeldown3", "kneeldown3loop", "kneeldown3end" },
}

local kneelHbh = {
	[1] = { "kneeldownTransition",  "kneeldownTransitionBack"  },
	[2] = { "kneeldown2Transition", "kneeldown2TransitionBack" },
}

local scaredVo = {
	"vo/episode_1/npc/male01/cit_evac_casualty10.wav", "vo/npc/male01/ohno.wav",
	"vo/npc/male01/startle01.wav", "vo/npc/male01/startle02.wav",
	"vo/episode_1/npc/male01/cit_alert_head06.wav", "vo/episode_1/npc/male01/cit_buddykilled04.wav",
	"vo/episode_1/npc/male01/cit_evac_casualty09.wav",
}

local surrSlot  = GESTURE_SLOT_ATTACK_AND_RELOAD
local kneelSlot = GESTURE_SLOT_CUSTOM

local minHold      = 5
local surrCdTime   = 4
local kneelCdTime  = 2
local standCdTime  = 1.5
local hbhCdTime    = 1.2
local wepLockTime  = 10

local tSurrBegin   = 0.8
local tSurrLoop    = 1.8
local tSurrExit    = 0.6
local tKneelBegin  = 1.3
local tKneelLoop   = 1.8
local tKneelExit   = 1.3
local tHbhKneel    = 0.39
local tHbhStand    = 0.5

local kneelCd, hbhCd, standCd, surrCd = 0, 0, 0, 0

local inSurrender, inKneel, inHbh, hbhBusy, kneelBusy, kneelReady, forcedExit, wepReach = false, false, false, false, false, false, false, false
local surrVar, prevSurrVar, kneelVar = 1, 1, 1
local surrStart, wepAllow, kneelYaw = 0, 0, 0

local remoteKneel = {}

local function resolveSeq(ply, name, act)
	local seq = ply:LookupSequence(name)
	if seq and seq ~= -1 then return seq, false end
	return act, true
end

local function playSlot(ply, slot, seq, actMode, loop)
	if actMode then ply:AnimRestartGesture(slot, seq, loop or false)
	else ply:AddVCDSequenceToGestureSlot(slot, seq, 0, loop or false) end
end

local function playAnim(ply, slot, anims, vi, part, act, resetAfter)
	local v = anims[vi]
	if not v then return end
	local seq, actMode = resolveSeq(ply, v[part], act)
	playSlot(ply, slot, seq, actMode, false)
	if resetAfter then
		timer.Simple(resetAfter, function()
			if IsValid(ply) then ply:AnimResetGestureSlot(slot) end
		end)
	end
end

local function playSurr(ply, vi, part)
	local reset = (part == 3) and tSurrExit or nil
	playAnim(ply, surrSlot, surrAnims, vi, part, part == 3 and ACT_GMOD_GESTURE_ITEM_PLACE or ACT_GMOD_GESTURE_TAUNT_ZOMBIE, reset)
end

local function playKneel(ply, vi, part)
	local reset = (part == 3) and tKneelExit or nil
	playAnim(ply, kneelSlot, kneelAnims, vi, part, part == 3 and ACT_GMOD_GESTURE_ITEM_PLACE or ACT_GMOD_GESTURE_TAUNT_ZOMBIE, reset)
end

local function playKneelHbh(ply, baseVi, dir)
	local tr = kneelHbh[baseVi]
	if not tr then return end
	local seq, actMode = resolveSeq(ply, dir == "enter" and tr[1] or tr[2], ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
	playSlot(ply, kneelSlot, seq, actMode, false)
end

local function foley(ply)
	if (ply.NextFoley or 0) >= CurTime() then return end
	ply:EmitSound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav", 55)
	ply.NextFoley = CurTime() + 2.5
end

local function forceHands(ply)
	if not IsValid(ply) then return end
	local hands = ply:GetWeapon("weapon_hands_sh")
	if IsValid(hands) then hands:Deploy() end
end

local function dropWep(ply)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() ~= "weapon_hands_sh" then RunConsoleCommand("dropweapon") end
end

local function canLeaveSurr()
	return CurTime() >= surrStart + minHold
end

local function startSurrLoop(ply, vi)
	if not inSurrender then return end
	playSurr(ply, vi, 2)
	timer.Create("surrender_loop_timer", tSurrLoop, 0, function()
		if not inSurrender or not IsValid(ply) then timer.Remove("surrender_loop_timer") return end
		playSurr(ply, surrVar, 2)
		net.Start("hg_surrender_loop") net.WriteUInt(surrVar, 4) net.SendToServer()
	end)
end

local function startKneelLoop(ply, vi)
	if not inKneel then return end
	playKneel(ply, vi, 2)
	timer.Create("kneel_loop_timer", tKneelLoop, 0, function()
		if not inKneel or not IsValid(ply) then timer.Remove("kneel_loop_timer") return end
		playKneel(ply, kneelVar, 2)
		net.Start("hg_kneel_loop") net.WriteUInt(kneelVar, 4) net.SendToServer()
	end)
end

local exitSurr, exitKneel, enterSurr, enterKneel

local function hbhTransition(ply, fromVi, toVi, onDone)
	hbhBusy = true
	timer.Remove("surrender_loop_timer")
	timer.Remove("kneel_loop_timer")
	timer.Remove("hbh_transition_timer")

	if inKneel then
		local baseVi = (toVi == 3) and fromVi or toVi
		local dir = (toVi == 3) and "enter" or "exit"

		playKneelHbh(ply, baseVi, dir)
		net.Start("hg_kneel_hbh_transition") net.WriteUInt(baseVi, 4) net.WriteString(dir) net.SendToServer()

		if surrAnims[toVi] then
			playAnim(ply, surrSlot, surrAnims, toVi, 1, ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
			net.Start("hg_surrender_enter") net.WriteUInt(toVi, 4) net.SendToServer()
		end

		timer.Create("hbh_transition_timer", tHbhKneel, 1, function()
			if not IsValid(ply) or not inSurrender then hbhBusy = false return end
			hbhBusy = false
			surrVar, kneelVar = toVi, toVi
			playKneel(ply, toVi, 2)
			net.Start("hg_kneel_loop") net.WriteUInt(toVi, 4) net.SendToServer()
			startKneelLoop(ply, toVi)
			if onDone then onDone() end
			startSurrLoop(ply, toVi)
		end)
	else
		if surrAnims[fromVi] then
			playAnim(ply, surrSlot, surrAnims, fromVi, 3, ACT_GMOD_GESTURE_ITEM_PLACE)
			net.Start("hg_surrender_exit") net.WriteUInt(fromVi, 4) net.SendToServer()
		end

		timer.Create("hbh_transition_timer", tHbhStand, 1, function()
			if not IsValid(ply) or not inSurrender then hbhBusy = false return end
			if surrAnims[toVi] then
				playAnim(ply, surrSlot, surrAnims, toVi, 1, ACT_GMOD_GESTURE_TAUNT_ZOMBIE)
				net.Start("hg_surrender_enter") net.WriteUInt(toVi, 4) net.SendToServer()
			end
			timer.Simple(tSurrBegin, function()
				if not IsValid(ply) or not inSurrender then hbhBusy = false return end
				hbhBusy = false
				surrVar = toVi
				if onDone then onDone() end
				startSurrLoop(ply, toVi)
			end)
		end)
	end
end

local function enterHbh(ply)
	if not inSurrender or hbhBusy or CurTime() < hbhCd or inHbh then return end
	if inKneel and not kneelReady then return end
	hbhCd = CurTime() + hbhCdTime
	prevSurrVar = surrVar
	hbhTransition(ply, surrVar, 3, function() inHbh = true end)
end

local function exitHbh(ply)
	if not inSurrender or not inHbh or hbhBusy or CurTime() < hbhCd then return end
	if inKneel and not kneelReady then return end
	hbhCd = CurTime() + hbhCdTime
	hbhTransition(ply, 3, prevSurrVar, function() inHbh = false end)
end

exitSurr = function(ply)
	if not inSurrender or not canLeaveSurr() then return end
	inSurrender, inHbh, hbhBusy = false, false, false
	timer.Remove("surrender_loop_timer")
	timer.Remove("hbh_transition_timer")
	playSurr(ply, surrVar, 3)
	net.Start("hg_surrender_exit") net.WriteUInt(surrVar, 4) net.SendToServer()
	surrVar, prevSurrVar = 1, 1
end

enterSurr = function(ply)
	local vi = math.random(2)
	surrVar, prevSurrVar = vi, vi
	inSurrender, inHbh = true, false
	surrStart = CurTime()
	wepAllow = CurTime() + wepLockTime

	playSurr(ply, vi, 1)
	net.Start("hg_surrender_enter") net.WriteUInt(vi, 4) net.SendToServer()

	local phrase = scaredVo[math.random(#scaredVo)]
	if ThatPlyIsFemale(ply) then phrase = string.Replace(phrase, "male01", "female01") end
	net.Start("hg_surrender_voice")
		net.WriteString(phrase)
		net.WriteBool(ply.armors and ply.armors["face"] == "mask2")
		net.WriteUInt(ply.VoicePitch or 100, 8)
	net.SendToServer()

	foley(ply)
	timer.Create("surrender_begin_timer", tSurrBegin, 1, function()
		if IsValid(ply) and inSurrender then startSurrLoop(ply, vi) end
	end)
end

exitKneel = function(ply)
	if not inKneel or CurTime() < kneelCd then return end
	if inSurrender and not canLeaveSurr() then return end

	kneelCd, standCd = CurTime() + kneelCdTime, CurTime() + standCdTime
	inKneel, kneelReady, kneelBusy = false, false, true
	timer.Remove("kneel_loop_timer")
	timer.Remove("kneel_begin_timer")

	playKneel(ply, kneelVar, 3)
	net.Start("hg_kneel_exit") net.WriteUInt(kneelVar, 4) net.SendToServer()
	net.Start("hg_kneel_hull") net.WriteBool(false) net.SendToServer()
	foley(ply)

	timer.Create("kneel_exit_timer", tKneelExit, 1, function() kneelBusy = false end)
	kneelVar = 1
end

enterKneel = function(ply)
	if CurTime() < kneelCd or CurTime() < standCd then return end
	kneelCd = CurTime() + kneelCdTime

	kneelVar = surrVar
	inKneel, kneelBusy, kneelReady = true, false, false
	kneelYaw = ply:EyeAngles().y
	wepAllow = math.max(wepAllow, CurTime() + wepLockTime)

	playKneel(ply, kneelVar, 1)
	net.Start("hg_kneel_enter") net.WriteUInt(kneelVar, 4) net.SendToServer()
	foley(ply)

	timer.Create("kneel_begin_timer", tKneelBegin, 1, function()
		if not IsValid(ply) or not inKneel then return end
		kneelReady = true
		startKneelLoop(ply, kneelVar)
		net.Start("hg_kneel_hull") net.WriteBool(true) net.SendToServer()
		if inSurrender then
			timer.Simple(0.1, function()
				if IsValid(ply) and inSurrender then playSurr(ply, surrVar, 2) end
			end)
		end
	end)
end

local function enterKneelSurr(ply)
	enterSurr(ply)
	timer.Simple(0.25, function() if IsValid(ply) then enterKneel(ply) end end)
end

local function surrReset(ply)
	if ply ~= LocalPlayer() or not inSurrender then return end
	local vi = surrVar
	timer.Remove("surrender_loop_timer")
	timer.Remove("surrender_begin_timer")
	timer.Remove("hbh_transition_timer")
	if IsValid(ply) then ply:AnimResetGestureSlot(surrSlot) end
	inSurrender, inHbh, hbhBusy, forcedExit, wepReach = false, false, false, false, false
	surrVar, prevSurrVar, wepAllow = 1, 1, 0
	net.Start("hg_surrender_exit") net.WriteUInt(vi, 4) net.SendToServer()
end

local function kneelReset(ply)
	if ply ~= LocalPlayer() or (not inKneel and not kneelBusy) then return end
	local vi = kneelVar
	timer.Remove("kneel_loop_timer")
	timer.Remove("kneel_begin_timer")
	timer.Remove("kneel_exit_timer")
	if IsValid(ply) then ply:AnimResetGestureSlot(kneelSlot) end
	inKneel, kneelBusy, kneelReady, kneelVar, kneelYaw = false, false, false, 1, 0
	kneelCd, standCd, forcedExit, wepReach, wepAllow = 0, 0, false, false, 0
	net.Start("hg_kneel_exit") net.WriteUInt(vi, 4) net.SendToServer()
	net.Start("hg_kneel_hull") net.WriteBool(false) net.SendToServer()
end

local function canUse(ply)
	return IsValid(ply) and ply:Alive() and not (ply.organism and ply.organism.otrub) and hg.GetCurrentCharacter(ply) == ply
end

-- remote anims

net.Receive("hg_surrender_enter", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	playSurr(ply, vi, 1)
	timer.Simple(tSurrBegin, function() if IsValid(ply) then playSurr(ply, vi, 2) end end)
end)

net.Receive("hg_surrender_loop", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	playSurr(ply, vi, 2)
end)

net.Receive("hg_surrender_exit", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	playSurr(ply, vi, 3)
end)

net.Receive("hg_kneel_enter", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	remoteKneel[ply] = true
	playKneel(ply, vi, 1)
	timer.Simple(tKneelBegin, function()
		if IsValid(ply) and remoteKneel[ply] then playKneel(ply, vi, 2) end
	end)
end)

net.Receive("hg_kneel_loop", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	playKneel(ply, vi, 2)
end)

net.Receive("hg_kneel_exit", function()
	local ply, vi = net.ReadEntity(), net.ReadUInt(4)
	if not IsValid(ply) or ply == LocalPlayer() then return end
	remoteKneel[ply] = false
	playKneel(ply, vi, 3)
end)

net.Receive("hg_kneel_hbh_transition", function()
	local ply, baseVi, dir = net.ReadEntity(), net.ReadUInt(4), net.ReadString()
	if not IsValid(ply) or ply == LocalPlayer() then return end
	playKneelHbh(ply, baseVi, dir)
end)

-- movement / wep lock

hook.Add("SetupMove", "kneel_movement_lock", function(ply, mv)
	if ply ~= LocalPlayer() or (not inKneel and not kneelBusy) then return end
	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	mv:SetUpSpeed(0)
	local vel = mv:GetVelocity()
	mv:SetVelocity(Vector(0, 0, vel.z))
	mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_JUMP)))
end)

hook.Add("CreateMove", "kneel_view_limit", function(cmd)
	if not inKneel then return end
	local ang = cmd:GetViewAngles()
	local yaw = math.Clamp(math.NormalizeAngle(ang.y - kneelYaw), -20, 20)
	ang.y, ang.p = kneelYaw + yaw, math.Clamp(ang.p, -100, 100)
	cmd:SetViewAngles(ang)
end)

hook.Add("Think", "surrender_strong_weapon_lock", function()
	local ply = LocalPlayer()
	if not (inSurrender or inKneel) or CurTime() >= wepAllow then return end
	forceHands(ply)
end)

hook.Add("PlayerSwitchWeapon", "surrender_block_switch", function(ply)
	if ply ~= LocalPlayer() or not (inSurrender or inKneel) or CurTime() >= wepAllow then return end
	forceHands(ply)
	return true
end)

hook.Add("PlayerSelectWeapon", "surrender_block_selectweapon", function(ply)
	if ply ~= LocalPlayer() or not (inSurrender or inKneel) or CurTime() >= wepAllow then return end
	forceHands(ply)
	return true
end)

hook.Add("CreateMove", "surrender_weapon_lock_input", function(cmd)
	if not (inSurrender or inKneel) or CurTime() >= wepAllow then return end
	cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_USE + IN_ATTACK + IN_ATTACK2)))
	cmd:SetImpulse(0)
end)

hook.Add("Think", "surrender_kneel_weapon_watch", function()
	local ply = LocalPlayer()
	if not (inSurrender or inKneel or kneelBusy) then wepReach = false return end
	if wepReach or CurTime() < wepAllow then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() == "weapon_hands_sh" then return end

	wepReach = true
	if inKneel then
		exitKneel(ply)
		timer.Simple(tKneelExit * 0.6, function()
			if inSurrender then exitSurr(ply) end
			timer.Simple(tSurrExit, function() wepReach = false end)
		end)
	else
		exitSurr(ply)
		timer.Simple(tSurrExit, function() wepReach = false end)
	end
end)

hook.Add("Think", "surr_kneel_attack_cancel", function()
	local ply = LocalPlayer()
	if not (inSurrender or inKneel) or forcedExit then return end
	if gui.IsGameUIVisible() or vgui.CursorVisible() then return end
	if not input.IsMouseDown(MOUSE_LEFT) or CurTime() <= surrStart + 0.3 then return end

	forcedExit = true
	wepAllow = math.max(wepAllow, CurTime() + 5)

	if inKneel and inSurrender then
		exitKneel(ply)
		timer.Simple(tKneelExit, function()
			if IsValid(ply) and inSurrender then exitSurr(ply) end
			forcedExit = false
		end)
	elseif inKneel then
		exitKneel(ply)
		timer.Simple(tKneelExit, function() forcedExit = false end)
	elseif inSurrender then
		exitSurr(ply)
		timer.Simple(tSurrExit, function() forcedExit = false end)
	end
end)

hook.Add("PlayerBindPress", "surrender_block_punch", function(ply, bind)
	if ply ~= LocalPlayer() or not (inSurrender or inKneel) then return end
	if string.find(bind, "+attack") or string.find(bind, "fake") then return true end
	if inKneel and string.find(bind, "hg_kick") then return true end
end)

hook.Add("radialOptions", "surrender_option", function()
	local ply = LocalPlayer()
	if not canUse(ply) then return end

	if kneelBusy then
		hg.radialOptions[#hg.radialOptions + 1] = { function() return -1 end, "Встаю..." }
		return
	end

	if hbhBusy then
		hg.radialOptions[#hg.radialOptions + 1] = { function() return -1 end, "..." }
		return
	end

	if inKneel then
		hg.radialOptions[#hg.radialOptions + 1] = {
			function(btn)
				if btn == 2 then
					if inHbh then
						hg.CreateRadialMenu({
							{ function() exitKneel(ply) end, "Встать" },
							{ function() exitHbh(ply) end, "Руки вверх" },
						})
					else
						hg.CreateRadialMenu({
							{ function() exitKneel(ply) end, "Встать" },
							{ function() enterHbh(ply) end, "Руки за голову" },
						})
					end
					return -1
				end
				exitKneel(ply)
			end,
			inHbh and "На коленях, руки за головой\nПКМ — меню" or "На коленях, руки вверх\nПКМ — меню"
		}
		return
	end

	if inSurrender then
		hg.radialOptions[#hg.radialOptions + 1] = {
			function(btn)
				if btn == 2 then
					if inHbh then
						hg.CreateRadialMenu({
							{ function() exitSurr(ply) end, "Прекратить сдачу" },
							{ function() enterKneel(ply) end, "На колени" },
							{ function() exitHbh(ply) end, "Руки вверх" },
						})
					else
						hg.CreateRadialMenu({
							{ function() exitSurr(ply) end, "Прекратить сдачу" },
							{ function() enterKneel(ply) end, "На колени" },
							{ function() enterHbh(ply) end, "Руки за голову" },
						})
					end
					return -1
				end
				exitSurr(ply)
			end,
			inHbh and "Сдача (руки за головой)\nПКМ — меню" or "Сдача\nПКМ — меню"
		}
		return
	end

	local wep = ply:GetActiveWeapon()
	local armed = IsValid(wep) and wep:GetClass() ~= "weapon_hands_sh"
	hg.radialOptions[#hg.radialOptions + 1] = {
		function(btn)
			if CurTime() < surrCd then return -1 end
			surrCd = CurTime() + surrCdTime
			if armed then dropWep(ply) end
			timer.Simple(0.15, function()
				if not IsValid(ply) then return end
				if btn == 2 then enterKneelSurr(ply) else enterSurr(ply) end
			end)
		end,
		"Сдаться\nПКМ — на колени"
	}
end)

hook.Add("HG_OnOtrub", "surrender_reset", surrReset)
hook.Add("PlayerDeath", "surrender_reset_death", surrReset)
hook.Add("PlayerSpawn", "surrender_reset_spawn", surrReset)
hook.Add("Fake", "surrender_reset_ragdoll", function(ply) if ply == LocalPlayer() then surrReset(ply) end end)

hook.Add("HG_OnOtrub", "kneel_reset", kneelReset)
hook.Add("PlayerDeath", "kneel_reset_death", kneelReset)
hook.Add("PlayerSpawn", "kneel_reset_spawn", kneelReset)
hook.Add("Fake", "kneel_reset_ragdoll", function(ply) if ply == LocalPlayer() then kneelReset(ply) end end)

concommand.Add("surrender_toggle", function()
	local ply = LocalPlayer()
	if not canUse(ply) then return end
	if inSurrender then exitSurr(ply) return end
	if CurTime() < surrCd then return end
	surrCd = CurTime() + surrCdTime
	dropWep(ply)
	timer.Simple(0.15, function() if IsValid(ply) then enterSurr(ply) end end)
end)

concommand.Add("kneel_toggle", function()
	local ply = LocalPlayer()
	if not canUse(ply) then return end
	if inKneel then exitKneel(ply) return end
	if kneelBusy then return end
	if not inSurrender then
		if CurTime() < surrCd then return end
		surrCd = CurTime() + surrCdTime
		dropWep(ply)
		timer.Simple(0.15, function() if IsValid(ply) then enterKneelSurr(ply) end end)
	else
		enterKneel(ply)
	end
end)
