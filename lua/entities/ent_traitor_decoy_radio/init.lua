AddCSLuaFile("shared.lua")
include("shared.lua")

local baitSounds = {
	"radio/voip_end_transmit_beep_01.wav",
	"radio/voip_end_transmit_beep_03.wav",
	"radio/voip_end_transmit_beep_05.wav",
	"radiorandom/radio1.wav",
	"radiorandom/radio3.wav",
	"radiorandom/radio5.wav",
}

function ENT:Initialize()
	self:SetModel("models/cof/weapons/mobile/w_mobile.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(true)
	self.NextBaitSound = CurTime() + math.Rand(8, 18)
	SafeRemoveEntityDelayed(self, 300)
end

function ENT:Think()
	if CurTime() < (self.NextBaitSound or 0) then return end
	self.NextBaitSound = CurTime() + math.Rand(12, 28)
	local snd = baitSounds[math.random(#baitSounds)]
	self:EmitSound(snd, 55, math.random(92, 108), 0.75, CHAN_STATIC)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if not activator.isTraitor then return end
	activator:Give("weapon_traitor_decoy_radio")
	self:Remove()
end
