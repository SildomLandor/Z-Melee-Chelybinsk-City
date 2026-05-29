AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetModelScale(0.5)
	self:Activate()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(false)
	self.isbomb = true
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(10)
		phys:Wake()
		phys:EnableMotion(true)
	end
end

function ENT:OnRemove()
end

util.AddNetworkString("bomb_look")
util.AddNetworkString("bomb_enter")

local function inBombSite(pos, site)
	return zb and zb.BombInSite and zb.BombInSite(pos, site)
end

local function defuseKitInHands(ply)
	if not IsValid(ply) then return false end
	local wep = ply:GetActiveWeapon()
	return IsValid(wep) and wep:GetClass() == "weapon_zb_defusekit"
end

function ENT:CloseBombPanel(ply)
	if not IsValid(ply) then return end
	if ply.bomb == self then ply.bomb = nil end
	net.Start("bomb_look")
	net.WriteEntity(NULL)
	net.Send(ply)
end

function ENT:OpenBombPanel(ply)
	if not IsValid(ply) or not ply:Alive() or not self.active then return false end
	if ply:Team() == 0 then return false end
	if defuseKitInHands(ply) then
		self:CloseBombPanel(ply)
		return false
	end

	self.user = ply
	ply.bomb = self

	net.Start("bomb_look")
	net.WriteEntity(self)
	net.Send(ply)

	return true
end

net.Receive("bomb_enter",function(len, ply)
	if !ply:Alive() then return end
	if defuseKitInHands(ply) and IsValid(zb.bomb) and zb.bomb.active then return end

	local org = ply.organism
	local ent = ply.bomb

	if not IsValid(ent) or not ent.isbomb then return end

	if not ent.active and org and not org.canmove then return end

	local txt = net.ReadString()
	local num = tonumber(txt)
	
	if ent.isbomb then
		if not ent.active then
			local isSandbox = engine.ActiveGamemode() == "sandbox"
			if isSandbox or inBombSite(ent:GetPos(), 1) or inBombSite(ent:GetPos(), 2) then
				ent.code = txt
				ply:ChatPrint("The bomb's code is: "..ent.code)
				ent:ActivateBomb()
			else
				ply:ChatPrint("The bomb must be planted on site")
			end
		else
			if ent.code == txt then
				ent:DisableBomb()
				ent:SetNetVar("knowncode", "******")
				ply:ChatPrint("The bomb has been disarmed.")
			else
				local bombtxt = ent.code
				local knownnumbers = ent:GetNetVar("knowncode", "******")
				local newknownnumbers = ""

				for i = 1, #bombtxt do
					if bombtxt[i] == txt[i] then
						newknownnumbers = newknownnumbers .. txt[i]
					else
						newknownnumbers = newknownnumbers .. (knownnumbers[i] == bombtxt[i] and knownnumbers[i] or "*")
					end
				end

				ent:SetNetVar("knowncode", newknownnumbers)
				ply:ChatPrint(newknownnumbers)
			end
		end
	end
end)

function ENT:ExplodeNow()
	if self.exploded then return end
	self.Defuser = nil
	self.exploded = true
	zb.bombexploded = true

	if self.tbl and self.tbl.OnBombExploded then
		self.tbl:OnBombExploded()
	end

	util.ScreenShake(self:GetPos(), 95, 500, 4, 1000)
	hg.PropExplosion(self, "Fire", 300, 100)
end

function ENT:DisableBomb()
	self.Defuser = nil
	local activetime = self.ExplodeTime - (self:GetNetVar("timer") - CurTime())
	self:SetNetVar("timer", nil)
	self.addtime = activetime
	self.active = nil

	self:SetMoveType(MOVETYPE_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
	end
end

local plantOffPos = Vector(0, 0, 0)
local plantOffAng = Angle(-90, 0, 180)

local function pushFromWalls(pos, mins, maxs, filter)
	for i = 0, 7 do
		local dir = Vector(math.cos(math.rad(i * 45)), math.sin(math.rad(i * 45)), 0)
		local from = pos + Vector(0, 0, math.max(maxs.z * 0.35, 2))
		local tr = util.TraceLine({
			start = from,
			endpos = from + dir * 24,
			filter = filter,
			mask = MASK_SOLID,
		})
		if tr.Hit then
			pos = pos - dir * (24 - from:Distance(tr.HitPos) + 7)
		end
	end
	return pos
end

function ENT:SnapToSurface(surfaceNormal)
	local mins, maxs = self:OBBMins(), self:OBBMaxs()
	local nrm = (surfaceNormal or self.PlantNormal or vector_up):GetNormalized()
	local center = self:GetPos()

	local tr = util.TraceHull({
		start = center + nrm * 24,
		endpos = center + nrm * 0.25,
		mins = mins,
		maxs = maxs,
		filter = self,
		mask = MASK_SOLID,
	})

	local pos = tr.Hit and (tr.HitPos + tr.HitNormal * 1.2) or (center + nrm * 1.2)
	nrm = tr.Hit and tr.HitNormal or nrm

	if nrm.z > 0.65 then
		pos = pushFromWalls(pos, mins, maxs, self)
		local down = util.TraceHull({
			start = pos + Vector(0, 0, 12),
			endpos = pos - Vector(0, 0, 64),
			mins = mins,
			maxs = maxs,
			filter = self,
			mask = MASK_SOLID,
		})
		if down.Hit then
			pos = down.HitPos + down.HitNormal * 1.2
			nrm = down.HitNormal
		end
	end

	local wpos, wang = LocalToWorld(plantOffPos, plantOffAng, pos, nrm:Angle())
	self:SetPos(wpos)
	self:SetAngles(wang)
end

function ENT:ActivateBomb()
	self:SetNetVar("timer", CurTime() + self.ExplodeTime - (self.addtime or 0))
	self.active = true

	if self.tbl and not self.activatedonce then
		local siteName
		if inBombSite(self:GetPos(), 1) then
			siteName = "A"
		elseif inBombSite(self:GetPos(), 2) then
			siteName = "B"
		end
		PrintMessage(HUD_PRINTTALK, "Bomb has been planted"
			..(siteName and (" on site "..siteName) or "")
			..".")
		
		hg.UpdateRoundTime(zb.ROUND_TIME + self.ExplodeTime + 1)
	end

	self.activatedonce = true

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	self:SnapToSurface(self.PlantNormal)
	self:SetMoveType(MOVETYPE_NONE)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if defuseKitInHands(activator) then
		self:CloseBombPanel(activator)
		return
	end

	if self.active and activator:Team() == 1 then
		self:OpenBombPanel(activator)
		return
	end

	local isSandbox = engine.ActiveGamemode() == "sandbox"
	if self.active and activator:Team() == 0 then
		activator:ChatPrint("The bomb's code is: " .. self.code)
		return
	end

	if not isSandbox and not inBombSite(self:GetPos(), 1) and not inBombSite(self:GetPos(), 2) then
		activator:PickupObject(self)
		return
	end

	activator:PickupObject(self)
	self.user = activator
	activator.bomb = self

	if defuseKitInHands(activator) then return end

	net.Start("bomb_look")
	net.WriteEntity(self)
	net.Send(activator)
end

hook.Add("PlayerUse", "zb_bomb_no_code_for_ct", function(ply, ent)
	if not IsValid(ent) or ent:GetClass() ~= "bomb" then return end
	if not defuseKitInHands(ply) then return end
	if ent.CloseBombPanel then ent:CloseBombPanel(ply) end
	return false
end)

ENT.nextbeep = 0

function ENT:Think()
	self:NextThink(CurTime())
	if self.active then
		if self:GetNetVar("timer") < CurTime() then
			self:ExplodeNow()
		end

		--;; WHAT THE FAK YUUUUUUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH
		local timeLeft = self:GetNetVar("timer") - CurTime()
		if timeLeft <= 1.5 and timeLeft > 0 and not self.wtfPlayed and math.random(1, 100) <= 5 then
			self.wtfPlayed = true
			self:EmitSound("snds_jack_gmod/wtfboom.mp3")
		end

		if self.nextbeep < CurTime() and self:GetNetVar("timer") > CurTime() then
			local beep = math.max((self:GetNetVar("timer") - CurTime()) / self.ExplodeTime,0.05)	
			self.nextbeep = CurTime() + beep
			for i, ent in ipairs(ents.FindInSphere(self:GetPos(),32 / beep)) do
				if ent.organism then
					ent.organism.adrenalineAdd = ent.organism.adrenalineAdd + 0.02 / beep
					ent.organism.fear = math.min(ent.organism.fear + 0.02 / beep, 1)
				end
			end
			self:EmitSound("snd_jack_chargecapacitor.wav")
		end

		return true
	end
	
	
	if not self.active and self.wtfPlayed then
		self.wtfPlayed = nil
	end

	if self.user and not self:IsPlayerHolding() then
		net.Start("bomb_look")
		net.WriteEntity(NULL)
		net.Send(self.user)
		self.user.bomb = nil
		self.user = nil
	end

	return true
end
