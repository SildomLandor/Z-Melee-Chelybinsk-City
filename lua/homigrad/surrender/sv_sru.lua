util.AddNetworkString("hg_surrender_enter")
util.AddNetworkString("hg_surrender_exit")
util.AddNetworkString("hg_surrender_loop")
util.AddNetworkString("hg_surrender_voice")
util.AddNetworkString("hg_kneel_enter")
util.AddNetworkString("hg_kneel_exit")
util.AddNetworkString("hg_kneel_loop")
util.AddNetworkString("hg_kneel_hull")
util.AddNetworkString("hg_kneel_hbh_transition")

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

local surrSlot  = GESTURE_SLOT_ATTACK_AND_RELOAD
local kneelSlot = GESTURE_SLOT_CUSTOM

local tSurrExit  = 0.6
local tKneelBegin = 1.3
local tKneelExit  = 1.3

local kneeling = {}
local kneelTrans = {}
local kneelLock = {}
local surrendering = {}

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

local function relay(name, ply, vi)
	net.Start(name)
		net.WriteEntity(ply)
		net.WriteUInt(vi, 4)
	net.SendOmit(ply)
end

local function relayHbh(ply, baseVi, dir)
	net.Start("hg_kneel_hbh_transition")
		net.WriteEntity(ply)
		net.WriteUInt(baseVi, 4)
		net.WriteString(dir)
	net.SendOmit(ply)
end

local function clearState(ply)
	if not IsValid(ply) then return end
	kneeling[ply] = nil
	kneelTrans[ply] = nil
	kneelLock[ply] = nil
	surrendering[ply] = nil
	ply.Kneeling = false
	ply:SetNWBool("Kneeling", false)
	ply:SetNWBool("Surrendering", false)
end

net.Receive("hg_surrender_enter", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local vi = net.ReadUInt(4)
	surrendering[ply] = true
	ply:SetNWBool("Surrendering", true)
	playSurr(ply, vi, 1)
	relay("hg_surrender_enter", ply, vi)
end)

net.Receive("hg_surrender_loop", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local vi = net.ReadUInt(4)
	playSurr(ply, vi, 2)
	relay("hg_surrender_loop", ply, vi)
end)

net.Receive("hg_surrender_exit", function(_, ply)
	if not IsValid(ply) then return end
	local vi = net.ReadUInt(4)
	surrendering[ply] = nil
	ply:SetNWBool("Surrendering", false)
	playSurr(ply, vi, 3)
	relay("hg_surrender_exit", ply, vi)
end)

net.Receive("hg_surrender_voice", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local phrase = net.ReadString()
	local muffed = net.ReadBool()
	local pitch = net.ReadUInt(8)
	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	ent:EmitSound(phrase, muffed and 75 or 85, pitch, 1, CHAN_AUTO, 0, muffed and 14 or 0)
end)

net.Receive("hg_kneel_enter", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local vi = net.ReadUInt(4)
	kneeling[ply] = true
	kneelTrans[ply] = CurTime() + tKneelBegin
	kneelLock[ply] = ply:GetPos()
	ply.Kneeling = true
	ply:SetNWBool("Kneeling", true)
	playKneel(ply, vi, 1)
	relay("hg_kneel_enter", ply, vi)
end)

net.Receive("hg_kneel_loop", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local vi = net.ReadUInt(4)
	playKneel(ply, vi, 2)
	relay("hg_kneel_loop", ply, vi)
end)

net.Receive("hg_kneel_exit", function(_, ply)
	if not IsValid(ply) then return end
	local vi = net.ReadUInt(4)
	kneeling[ply] = nil
	kneelTrans[ply] = CurTime() + tKneelExit
	kneelLock[ply] = nil
	ply.Kneeling = false
	ply:SetNWBool("Kneeling", false)
	playKneel(ply, vi, 3)
	relay("hg_kneel_exit", ply, vi)
end)

net.Receive("hg_kneel_hbh_transition", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local baseVi, dir = net.ReadUInt(4), net.ReadString()
	playKneelHbh(ply, baseVi, dir)
	relayHbh(ply, baseVi, dir)
end)

net.Receive("hg_kneel_hull", function(_, ply)
	if not IsValid(ply) then return end
	kneelLock[ply] = net.ReadBool() and ply:GetPos() or nil
end)

hook.Add("SetupMove", "kneel_movement_lock_server", function(ply, mv)
	if not kneeling[ply] and not (kneelTrans[ply] and kneelTrans[ply] > CurTime()) then return end
	mv:SetForwardSpeed(0)
	mv:SetSideSpeed(0)
	mv:SetUpSpeed(0)
	local vel = mv:GetVelocity()
	mv:SetVelocity(Vector(0, 0, vel.z))
	mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_FORWARD + IN_BACK + IN_MOVELEFT + IN_MOVERIGHT + IN_JUMP)))
end)

hook.Add("FinishMove", "kneel_position_lock_server", function(ply)
	local locked = kneelLock[ply]
	if not locked then return end
	local cur = ply:GetPos()
	if cur.x ~= locked.x or cur.y ~= locked.y then
		ply:SetPos(Vector(locked.x, locked.y, cur.z))
	end
end)

hook.Add("PlayerDisconnected", "kneel_cleanup", clearState)
hook.Add("PlayerDeath", "kneel_cleanup_death", clearState)
hook.Add("PlayerSpawn", "kneel_cleanup_spawn", clearState)
hook.Add("Fake", "kneel_cleanup_ragdoll", clearState)
hook.Add("HG_OnOtrub", "kneel_cleanup_otrub", clearState)

hook.Add("PlayerRunConCommand", "surrender_block_fake_kick", function(ply, cmd)
	if not IsValid(ply) then return end
	if cmd == "fake" and (surrendering[ply] or kneeling[ply]) then return true end
	if cmd == "hg_kick" and kneeling[ply] then return true end
end)
