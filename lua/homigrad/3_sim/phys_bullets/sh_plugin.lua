--\\
	--; TODO
	--; Для вычисления урона (энергии) Ek = (m * V^2) / 2
	--; Сопротивление воздуха F = B * v^2,
	--; Метры в сек в юниты в сек V * 52.5
	--; Дрейф

	--; Из разных пушек разная скорость пули
	--; Некоторые параметры будут считаться исходя из аммоайди

	--; У дроби высокое сопротивление воздуху (~75 метров и они падают)
--//

--\\Перевод плагиновых штук в ваши штуки
	hg.PhysBullet = hg.PhysBullet or {}
	local PLUGIN = hg.PhysBullet
	PLUGIN.ID = "PhysBullet"

	function PLUGIN:AddHook(id, func)
		hook.Add(id, "HG.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", func)
	end

	function PLUGIN:RunHook(id, ...)
		return hook.Run("HG.Plugin.List[" .. self.ID .. "].Hooks[" .. id .. "]", ...)
	end
--//

-- ulx luarun SetGlobalBool('PhysBullets_ReplaceDefault', true)
SetGlobalBool("PhysBullets_ReplaceDefault", false)

PLUGIN.Name = "Physics Bullet"
PLUGIN.Description = "Creates projectiles"
PLUGIN.Version = 1
PLUGIN.MainMaterial = Material("sprites/splodesprite")
PLUGIN.BulletsTable = PLUGIN.BulletsTable or {}
PLUGIN.BulletList = PLUGIN.BulletList or {}
PLUGIN.KeyPool = PLUGIN.KeyPool or {}
PLUGIN._nextKey = PLUGIN._nextKey or 0
PLUGIN.MaxTraceStep = 56
PLUGIN.MaxImpactsPerFrame = 40
PLUGIN.MaxDrawDistSqr = 6000000
PLUGIN.MaxPathDist = 12
PLUGIN._ammoCache = PLUGIN._ammoCache or {}
PLUGIN.MaxKeyBitsFilter = 6
PLUGIN.MaxKeyBits = 13 --; The same as gmod max ents bits, should be more than enough
PLUGIN.MaxAmmoIDBits = 8 --; Used for AmmoID
PLUGIN.MaxVelocityLenBits = 16 --; Up to 32767 * 2 hu/s
PLUGIN.MaxVelocityBits = 8
PLUGIN.MaxVelocityInt = 2^(PLUGIN.MaxVelocityBits - 1) - 1
PLUGIN.FirstPenetrationMul = 0.006	--; Что это нафиг
PLUGIN.DefaultSurfaceHardness = 0.5

PLUGIN.SurfaceHardness = {
	[MAT_METAL] = 0.9,
	[MAT_COMPUTER] = 0.9,
	[MAT_VENT] = 0.9,
	[MAT_GRATE] = 0.9,
	[MAT_FLESH] = 0.5,
	[MAT_ALIENFLESH] = 0.3,
	[MAT_SAND] = 0.1,
	[MAT_DIRT] = 0.9,
	[74] = 0.1,
	[85] = 0.2,
	[MAT_WOOD] = 0.5,
	[MAT_FOLIAGE] = 0.5,
	[MAT_CONCRETE] = 0.9,
	[MAT_TILE] = 0.8,
	[MAT_SLOSH] = 0.05,
	[MAT_PLASTIC] = 0.3,
	[MAT_GLASS] = 0.6,
}

PLUGIN.Bullet_StandartMask = MASK_SHOT

--\\Misc
	local function define_if_not_defined(tbl, key, value)
		if tbl[key] == nil then tbl[key] = value end
	end

	function PLUGIN.AllocKey()
		local pool = PLUGIN.KeyPool
		if #pool > 0 then return table.remove(pool) end
		PLUGIN._nextKey = PLUGIN._nextKey + 1
		return PLUGIN._nextKey
	end

	function PLUGIN.FreeKey(key)
		PLUGIN.KeyPool[#PLUGIN.KeyPool + 1] = key
	end

	function PLUGIN.RegisterBullet(bullet)
		bullet.Key = bullet.Key or PLUGIN.AllocKey()
		PLUGIN.BulletsTable[bullet.Key] = bullet
		local list = PLUGIN.BulletList
		list[#list + 1] = bullet
		bullet._listIndex = #list
	end

	function PLUGIN.UnregisterBullet(bullet)
		PLUGIN.BulletsTable[bullet.Key] = nil
		PLUGIN.FreeKey(bullet.Key)
		local list = PLUGIN.BulletList
		local idx = bullet._listIndex
		if not idx then return end
		local last = list[#list]
		if last ~= bullet then
			list[idx] = last
			last._listIndex = idx
		end
		list[#list] = nil
		bullet._listIndex = nil
	end

	function PLUGIN.CacheAmmo(ammoID)
		local cached = PLUGIN._ammoCache[ammoID]
		if cached then return cached end
		local name = game.GetAmmoName(ammoID)
		cached = hg.ammotypeshuy[name] or game.GetAmmoData(ammoID) or {}
		cached.BulletSettings = cached.BulletSettings or {}
		cached.BulletFunctions = cached.BulletFunctions or {}
		PLUGIN._ammoCache[ammoID] = cached
		return cached
	end

	function PLUGIN.SetupSizeHull(bullet)
		local size = bullet.Size * 0.5
		bullet.SizeMins = Vector(-size, -size, -size)
		bullet.SizeMaxs = Vector(size, size, size)
		bullet._sizeCached = bullet.Size
	end

	local function apply_spread(bullet)
		local spread = bullet.Spread
		if not spread then return end
		local vel = bullet.Vel
		local len = vel:Length()
		if len < 0.001 then return end
		local ang = (bullet.DirOriginal or vel / len):Angle()
		ang:RotateAroundAxis(ang:Up(), math.Rand(-spread[1] * 45, spread[1] * 45))
		ang:RotateAroundAxis(ang:Right(), math.Rand(-spread[2] * 45, spread[2] * 45))
		bullet.Vel = ang:Forward() * len
	end

	local function play_impact(trace)
		if not SERVER then return end
		if trace.StartSolid then return end
		local n = PLUGIN.ImpactThisFrame or 0
		if n >= PLUGIN.MaxImpactsPerFrame then return end
		PLUGIN.ImpactThisFrame = n + 1
		local ed = PLUGIN._fxEd or EffectData()
		PLUGIN._fxEd = ed
		ed:SetOrigin(trace.HitPos)
		ed:SetEntity(trace.Entity)
		ed:SetStart(trace.StartPos)
		ed:SetSurfaceProp(trace.SurfaceProps)
		ed:SetDamageType(DMG_BULLET)
		ed:SetHitBox(trace.HitBox)
		util.Effect("Impact", ed, true, true)
	end

	local function bullet_trace(bullet, start, endpos)
		local tr = bullet._tr
		tr.start = start
		tr.endpos = endpos
		tr.filter = bullet.TraceFilter
		tr.mask = bullet.TraceMask
		if bullet.Size == 0 then
			return util.TraceLine(tr)
		end
		tr.mins = bullet.SizeMins
		tr.maxs = bullet.SizeMaxs
		return util.TraceHull(tr)
	end

	local function translate_default_bullet_to_phys(bullet)
		bullet.Pos = bullet.Pos or bullet.Src
		bullet.Shooter = bullet.Shooter or bullet.Attacker
		bullet.Size = bullet.Size or bullet.HullSize or 0
		bullet.TraceFilter = bullet.TraceFilter or bullet.IgnoreEntity
		bullet.AmmoID = bullet.AmmoID or bullet.AmmoType
		bullet.TraceMask = bullet.TraceMask or PLUGIN.Bullet_StandartMask
		
		if(isstring(bullet.AmmoID))then
			bullet.AmmoID = game.GetAmmoID(bullet.AmmoID)
		end

		--=\\
			bullet.Force = bullet.Force or 1
			bullet.AmmoForce = bullet.AmmoForce or game.GetAmmoForce(bullet.AmmoID)	--; ????????????????????
		--=//

		local hg_ammo_table = PLUGIN.CacheAmmo(bullet.AmmoID)
		
		--=\\???
			bullet.AirResistMul = bullet.AirResistMul or hg_ammo_table.BulletSettings.AirResistMul
			bullet.LifeTime = bullet.LifeTime or hg_ammo_table.BulletSettings.LifeTime
			bullet.Mass = bullet.Mass or hg_ammo_table.BulletSettings.Mass or 1
			bullet.DamageType = bullet.DamageType or hg_ammo_table.dmgtype or DMG_BULLET
			bullet.PhysPenetrationMul = bullet.PhysPenetrationMul or hg_ammo_table.BulletSettings.PhysPenetrationMul or 1
			bullet.ForceMul = bullet.ForceMul or hg_ammo_table.ForceMul or 1
			bullet.TracerSetings = bullet.TracerSetings or hg_ammo_table.TracerSetings or {}
			bullet.TracerSetings.MaxPathPoints = bullet.TracerSetings.MaxPathPoints or 5
			bullet.FunctionInfo = bullet.FunctionInfo or hg_ammo_table.FunctionInfo or {}
		--=//

		--=\\Functions Overrides
			bullet.Draw = hg_ammo_table.BulletFunctions.Draw or bullet.Draw
			bullet.Remove = hg_ammo_table.BulletFunctions.Remove or bullet.Remove
			bullet.PreRemove = hg_ammo_table.BulletFunctions.PreRemove or bullet.PreRemove
			bullet.PostRemove = hg_ammo_table.BulletFunctions.PostRemove or bullet.PostRemove
			bullet.Hit = hg_ammo_table.BulletFunctions.Hit or bullet.Hit
			bullet.PostRicochet = hg_ammo_table.BulletFunctions.PostRicochet or bullet.PostRicochet
			bullet.PostPenetration = hg_ammo_table.BulletFunctions.PostPenetration or bullet.PostPenetration
			bullet.OnStopped = hg_ammo_table.BulletFunctions.OnStopped or bullet.OnStopped
			bullet.AddPathPoint = hg_ammo_table.BulletFunctions.AddPathPoint or bullet.AddPathPoint
		--=//

		if(bullet.Vel == nil)then
			bullet.StartLen = (bullet.Speed or hg_ammo_table.Speed or 320) * 52.5 * math.Rand(0.9, 1.1)
			bullet.Vel = bullet.Dir * bullet.StartLen
			bullet.Dir = nil
		end
		
		if(not bullet.StartLen)then
			bullet.StartLen = bullet.Vel:Length()
		end

		if SERVER and bullet.Spread then
			if not bullet.DirOriginal then
				local vel = bullet.Vel
				local vlen = vel:Length()
				bullet.DirOriginal = vlen > 0.001 and vel / vlen or bullet.Dir
			end
			apply_spread(bullet)
		end
	end

	local pellet_skip = {
		Key = true, _listIndex = true, _sizeCached = true, Removed = true, AttackedEnts = true,
		PathPoints = true, PathPoints_Swap = true, _tr = true, _pathAccum = true,
		LastThinkTime = true, LastUpdateTime = true, PenetratingMaterial = true,
		PenetratingStartPos = true, PenetratingTrace = true, PenetratingSky = true,
	}

	local function copy_bullet(bullet)
		local new_bullet = {}
		for k, v in pairs(bullet) do
			if not pellet_skip[k] then new_bullet[k] = v end
		end
		new_bullet.Pos = Vector(bullet.Pos)
		new_bullet.Vel = Vector(bullet.Vel)
		if bullet.DirOriginal then
			new_bullet.DirOriginal = Vector(bullet.DirOriginal)
		end
		return new_bullet
	end
--//

--\\Misc Network
	function PLUGIN.net_writekey(value)
		net.WriteUInt(value, PLUGIN.MaxKeyBits)
	end

	function PLUGIN.net_readkey()
		return net.ReadUInt(PLUGIN.MaxKeyBits)
	end

	function PLUGIN.net_writeammoid(value)
		net.WriteUInt(value, PLUGIN.MaxAmmoIDBits)
	end

	function PLUGIN.net_readammoid()
		return net.ReadUInt(PLUGIN.MaxAmmoIDBits)
	end

	function PLUGIN.net_writevelocity(value, len)
		if(!len)then
			len = value:Length()
			value = value / len
		end
		
		net.WriteInt(math.Round(value[1] * PLUGIN.MaxVelocityInt), PLUGIN.MaxVelocityBits)
		net.WriteInt(math.Round(value[2] * PLUGIN.MaxVelocityInt), PLUGIN.MaxVelocityBits)
		net.WriteInt(math.Round(value[3] * PLUGIN.MaxVelocityInt), PLUGIN.MaxVelocityBits)
		--; оптимизация круто но слишком заметна какашка когда скорость пули маленькая (ниче не заметно)
		net.WriteUInt(len, PLUGIN.MaxVelocityLenBits)
	end

	function PLUGIN.net_readvelocity()
		local x = net.ReadInt(PLUGIN.MaxVelocityBits)
		local y = net.ReadInt(PLUGIN.MaxVelocityBits)
		local z = net.ReadInt(PLUGIN.MaxVelocityBits)
		local value = Vector(x / PLUGIN.MaxVelocityInt, y / PLUGIN.MaxVelocityInt, z / PLUGIN.MaxVelocityInt)
		local len = net.ReadUInt(PLUGIN.MaxVelocityLenBits)
		
		return value * len
	end

	function PLUGIN.net_writetracefilter(filter)
		if not istable(filter) then
			net.WriteBool(true)
			net.WriteEntity(filter)
			return
		end
		if #filter == 1 and IsEntity(filter[1]) then
			net.WriteBool(true)
			net.WriteEntity(filter[1])
			return
		end
		net.WriteBool(false)
		local len = #filter
		net.WriteUInt(len, PLUGIN.MaxKeyBitsFilter)
		for key = 1, len do
			local value = filter[key]
			if isstring(value) then
				net.WriteBool(true)
				net.WriteString(value)
			elseif isentity(value) then
				net.WriteBool(false)
				net.WriteEntity(value)
			else
				ErrorNoHaltWithStack("Expected value at key " .. key .. " to be string or Entity, but got " .. type(value) .. "\n")
				return false
			end
		end
	end

	function PLUGIN.net_readtracefilter()
		if net.ReadBool() then
			return net.ReadEntity()
		end
		local len = net.ReadUInt(PLUGIN.MaxKeyBitsFilter)
		local filter = {}
		for key = 1, len do
			if net.ReadBool() then
				filter[key] = net.ReadString()
			else
				filter[key] = net.ReadEntity()
			end
		end
		return filter
	end
--//

--\\Network
	PLUGIN.NetworkTableFull = {
		{"Key", PLUGIN.net_writekey, PLUGIN.net_readkey},
		{"AmmoID", PLUGIN.net_writeammoid, PLUGIN.net_readammoid},
		{"CreationTime", net.WriteFloat, net.ReadFloat},
		{"LifeTime", net.WriteFloat, net.ReadFloat},
		{"DieOnHit", net.WriteBool, net.ReadBool},
		{"NoGravity", net.WriteBool, net.ReadBool},
		{"Pos", net.WriteVector, net.ReadVector},
		{"Vel", PLUGIN.net_writevelocity, PLUGIN.net_readvelocity},
		{"Size", net.WriteFloat, net.ReadFloat},
		{"AirResistMul", net.WriteFloat, net.ReadFloat}, --; WARNING
		{"Penetration", net.WriteFloat, net.ReadFloat},
		-- {"LoseVelocity", net.WriteFloat, net.ReadFloat},
		-- {"Color", net.WriteColor, net.ReadColor},
		{"TraceFilter", PLUGIN.net_writetracefilter, PLUGIN.net_readtracefilter},
	}

	PLUGIN.NetworkTableUpdate = {
		{"Key", PLUGIN.net_writekey, PLUGIN.net_readkey},	--; Always first
		{"Pos", net.WriteVector, net.ReadVector},
		{"Vel", PLUGIN.net_writevelocity, PLUGIN.net_readvelocity},
	}
--//

--; Пульки которые пиф паф взиу пиу
--; Написано будет все на анлийском потомучто я так уже начал и менять лень

--\\
	--; Bullet structure:
	--; Size - (number) Hull trace's size
	--; Color - Color of the bullet
	--; Pos	- Position

	--; Vel = bullet.Dir * (number) - Velocity
	--; AmmoID = 0 - Default game library's AmmoID
	--; AirResistMul = 0.0001 - Air resistance mul
	--; Mass = 1 - Mass
	--; PhysPenetrationMul = 1 - DEPRECATED Penetration trace length mul
	--; Damage = 0 - Damage dealt to the thing receiving shot
	--; NoNetwork = false - Disable networking?
	--; NoNetworkUpdate = false - Disable update networking?
	--; LoseVelocity = 1 - Velocity lost per second (scaled to engine.TickInterval)
	--; NoGravity = nil - Disable gravity? no gravity does not mean no air friction:troll:
	--; TraceFilter = bullet.Shooter - Trace filter. Functions are not supported for networking
	--; LifeTime = 5 - Time for this thing to live

	--; DieOnHit = false - Die on hit?

	--; Key = auto - Bullet's key in global table
	--; SizeMins = auto - Calculated automatically
	--; SizeMaxs = auto - Calculated automatically
	--; CreationTime = CurTime() - Time of creation
	--; LastThinkTime = CurTime() - Time of last think
	--; LastUpdateTime = auto - NetCDUpdateBullet
	--; AttackedEnts = auto - Calculated automatically

	--; Removed = auto - Set then removed
--//

--\\MetaTable
	PLUGIN.Class_Bullet = {}
	PLUGIN.Class_Bullet.__index = PLUGIN.Class_Bullet
	PLUGIN.Class_Bullet.__tostring = function(self)
		return "Bullet [" .. self.Key .. "]"
	end

	function PLUGIN.Class_Bullet:Think()
		if not PLUGIN:RunHook("BulletPreThink", self) then
			local ct = PLUGIN._thinkCT
			if self.LastThinkTime == ct then return end
			self.LastThinkTime = ct
		end

		if PLUGIN:RunHook("BulletThink", self) == false then return end

		local ct = PLUGIN._thinkCT
		if self.CreationTime + self.LifeTime <= ct then
			if self.OnStopped then self:OnStopped(nil, "time") end
			self:Die()
			return
		end

		if self.DistanceTraveled >= self.Distance then
			if self.OnStopped then self:OnStopped(nil, "distance") end
			self:Die()
			return
		end

		local interval = PLUGIN._thinkFT
		local grav = PLUGIN._thinkGrav

		if not self.NoGravity then
			self.Vel:Add(grav * interval)
		end

		local len = self.Vel:Length()
		self.DistanceTraveled = self.DistanceTraveled + len * interval
		if len < 0.001 then
			if self.OnStopped then self:OnStopped(nil, "len", self.PenetratingTrace) end
			self:Die()
			return
		end

		local dir = self.Vel / len
		local resist_mul = self.AirResistMul
		if self.PenetratingMaterial then
			resist_mul = PLUGIN.CalcMaterialResist(self.PenetratingMaterial)
		end
		len = len - math.min(resist_mul * interval * len * len, len)

		if self._sizeCached ~= self.Size then
			PLUGIN.SetupSizeHull(self)
		end

		self._tr = self._tr or {}
		local max_step = PLUGIN.MaxTraceStep
		local vel_normal = dir
		local len_before = len
		local vel_vector = vel_normal * len
		local iteration = 0

		while vel_vector and iteration < 4 do
			iteration = iteration + 1
			local move_vector = vel_normal * (len * interval)
			local move_len = move_vector:Length()
			local step_dir = move_len > 0.001 and (move_vector / move_len) or vel_normal
			local seg_left = move_len
			local trace, trace_hit

			while seg_left > 0.001 do
				local seg = seg_left > max_step and max_step or seg_left
				local seg_vec = step_dir * seg
				local seg_end = self.Pos + seg_vec
				trace = bullet_trace(self, self.Pos, seg_end)
				trace_hit = trace.Hit
				seg_left = seg_left - seg

				if self.PenetratingMaterial then
					if trace.AllSolid then
						self.Pos = seg_end
					else
						break
					end
				elseif trace_hit then
					self.Pos = trace.HitPos
					break
				else
					self.Pos = seg_end
				end
			end

			if self.PenetratingMaterial and not trace.AllSolid then
				local mat = self.PenetratingMaterial
				local pen_start = self.PenetratingStartPos
				local pen_iters = 8
				local pen_chunk = move_vector / pen_iters * self.Penetration / 50
				local penetration_pos, last_unsure

				for i = 1, pen_iters do
					local pstart = pen_start + pen_chunk * i
					local pend = pstart - pen_chunk * i
					local ptr = bullet_trace(self, pstart, pend)
					if not ptr.StartSolid and ptr.Hit then
						penetration_pos = ptr.HitPos
						break
					elseif not ptr.AllSolid then
						last_unsure = pstart
					end
				end

				if penetration_pos then
					self.Pos = penetration_pos
					len_before = PLUGIN.CalcVelocityLostInMaterial(mat, pen_start:DistToSqr(penetration_pos), len_before)
					len = math.min(len, len_before)
					if SERVER then
						local tb = self._tr
						tb.start = penetration_pos + move_vector
						tb.endpos = penetration_pos - move_vector
						tb.mask = self.TraceMask
						tb.filter = self.TraceFilter
						play_impact(util.TraceLine(tb))
					end
					self.PenetratingMaterial = nil
					self.PenetratingStartPos = nil
					self.PenetratingSky = false
					if CLIENT then self:AddPathPoint(self.Pos) end
					goto bullet_loop_tail
				else
					last_unsure = last_unsure or (self.Pos + move_vector)
					self.PenetratingStartPos = last_unsure
					if self.OnStopped then self:OnStopped(last_unsure, "penetration", self.PenetratingTrace) end
					self:Die()
					return
				end
			else
				if CLIENT then self:AddPathPoint(self.Pos) end

				if SERVER and trace_hit and IsValid(trace.Entity) then
					local attacked = self.AttackedEnts
					if not attacked then
						attacked = {}
						self.AttackedEnts = attacked
					end
					if not attacked[trace.Entity] then
						attacked[trace.Entity] = true
						local speedmul = len_before / self.StartLen
						local dmg = DamageInfo()
						dmg:SetDamage(self.Damage * math.sqrt(speedmul))
						dmg:SetDamageType(self.DamageType or DMG_BULLET)
						dmg:SetDamagePosition(trace.HitPos)
						dmg:SetDamageForce(self.AmmoForce * dir * (speedmul * self.Force * self.ForceMul))
						if IsValid(self.Shooter) then
							dmg:SetAttacker(self.Shooter)
							dmg:SetInflictor(self.Shooter)
						else
							dmg:SetAttacker(Entity(0))
							dmg:SetInflictor(Entity(0))
						end
						trace.Entity:DispatchTraceAttack(dmg, trace, dir)
						if trace.Entity.organism then
							if self.OnStopped then self:OnStopped(nil, "organism", trace) end
							self:Die()
							return
						end
					end
				end

				if trace_hit then
					if not self.PenetratingMaterial then
						play_impact(trace)
						vel_normal, len, len_before = self:Hit(trace, len, len_before)
					end
				end
			end

			::bullet_loop_tail::
			if self.Removed then return end

			vel_normal = vel_normal or dir
			len = len or len_before
			if len < 0.001 then
				if self.OnStopped then self:OnStopped(nil, "len", self.PenetratingTrace) end
				self:Die()
				return
			end

			if trace_hit or self.PenetratingMaterial then
				vel_vector = vel_normal * len
			else
				break
			end
		end

		self.Vel = vel_normal * len_before

		if SERVER and not self.NoNetworkUpdate then
			local net_cd = PLUGIN.NetCDUpdateBullet or 0.25
			if not self.LastUpdateTime or self.LastUpdateTime + net_cd <= ct then
				self.LastUpdateTime = ct
				PLUGIN.NetworkBulletUpdate(self)
			end
		end

		PLUGIN:RunHook("BulletPostThink", self)
	end

	local traces_materials = traces_materials or {}

	if CLIENT then
		local drawEyePos = Vector()
		function PLUGIN.Class_Bullet:Draw()
			local ts = self.TracerSetings
			if not ts then return end

			drawEyePos:Set(EyePos())
			if self.Pos:DistToSqr(drawEyePos) > PLUGIN.MaxDrawDistSqr then return end

			local tracer_body = ts.TracerBody
			if tracer_body then
				local head = math.max(self.Size, ts.TracerHeadSize or 5)
				render.SetMaterial(tracer_body)
				render.DrawSprite(self.Pos, head, head, ts.TracerColor or color_white)
			end

			local path = self.PathPoints
			if not path then return end

			local max_pts = ts.MaxPathPoints
			local count = #path
			if count < 2 then return end

			local color = ts.TracerColor or color_white
			local tail = ts.TracerTail
			if tail then
				local material_name = tail:GetName()
				if not traces_materials[material_name] then
					traces_materials[material_name] = CreateMaterial(material_name .. "_albedo", "UnlitGeneric", {
						["$basetexture"] = tail:GetTexture("$basetexture"),
						["$additive"] = 1,
						["$vertexalpha"] = 1,
						["$vertexcolor"] = 1
					})
				end
				render.SetMaterial(traces_materials[material_name])
			else
				render.SetColorMaterial()
			end

			local beam_n = math.min(count, max_pts)
			local start_i = count - beam_n + 1
			render.StartBeam(beam_n)
			for i = start_i, count do
				render.AddBeam(path[i], (ts.TracerWidth or 2) / 5, (i - start_i) / beam_n, color)
			end
			render.EndBeam()
		end

		function PLUGIN.Class_Bullet:AddPathPoint(pos)
			local accum = (self._pathAccum or 0) + self.Pos:Distance(pos)
			if accum < PLUGIN.MaxPathDist then
				self._pathAccum = accum
				return
			end
			self._pathAccum = 0

			local max_pts = self.TracerSetings.MaxPathPoints
			local path = self.PathPoints
			if not path then
				self.PathPoints = {pos}
				return
			end
			path[#path + 1] = pos
			if #path >= max_pts * 2 then
				local swap = self.PathPoints_Swap or {}
				self.PathPoints = swap
				self.PathPoints_Swap = {}
				swap[#swap + 1] = pos
			elseif #path >= max_pts then
				local swap = self.PathPoints_Swap or {}
				self.PathPoints_Swap = swap
				swap[#swap + 1] = pos
			end
		end
	end

	function PLUGIN.Class_Bullet:GetPos()
		return self.Pos
	end

	function PLUGIN.Class_Bullet:SetPos(pos)
		self.Pos = pos
	end

	function PLUGIN.Class_Bullet:GetVelocity()
		return self.Vel
	end

	function PLUGIN.Class_Bullet:SetVelocity(vel)
		self.Vel = vel
	end

	function PLUGIN.Class_Bullet:ApplyForceCenter(vel)
		self.Vel = self.Vel + vel
	end

	function PLUGIN.Class_Bullet:Hit(trace, len, len_before)
		if(self.DieOnHit)then
			-- if(SERVER)then	--; WARNING
				self:Die()
				return
			-- end
		end
		
		local new_vel_normal, len, ricochet, ang_diff, stopped = PLUGIN.CalcHit(trace, len, len_before, self.TraceMask, self.Penetration, self.SizeMins, self.SizeMaxs)
		
		--[[if(stopped)then
			self:Die()

			return
		end--]]

		if(ricochet)then
			local len_subtract_frac = (90 - ang_diff) / 90
			local resist_mul = PLUGIN.CalcMaterialResist(self.PenetratingMaterial)
			len_before = len_before - math.min(resist_mul * self.AirResistMul * 140 * len_subtract_frac * len_before * len_before, len_before)	--; Не подтверждено ни чем
			len = math.min(len, len_before)
			
			if(SERVER)then
				local rnd = math.random(12)
				if rnd == 8 then rnd = 9 end
				sound.Play("arc9_eft_shared/ricochet/ricochet" .. rnd .. ".ogg", trace.HitPos, 75, math.random(90, 110))
				--sound.Play("snd_jack_hmcd_ricochet_" .. math.random(1, 2) .. ".wav", trace.HitPos, 75, math.random(90, 110))
				--sound.Play("weapons/arccw/ricochet0" .. math.random(1, 5) .. "_quiet.wav", trace.HitPos, 75, math.random(90, 110))
			end
			
			if(self.PostRicochet)then
				self:PostRicochet(new_vel_normal, len, ricochet, ang_diff, len_before, trace)
			end
		else
			self.Pos = self.Pos + new_vel_normal * 1
			self.PenetratingMaterial = trace.MatType
			self.PenetratingStartPos = trace.HitPos
			self.PenetratingTrace = trace
			
			if(trace.HitSky)then
				self.PenetratingSky = true
			else
				local resist_mul = PLUGIN.CalcMaterialResist(self.PenetratingMaterial, 1)
				local resist = math.min(resist_mul * self.AirResistMul / self.PhysPenetrationMul * 200000000 / self.Mass, len_before)	--; Не подтверждено ни чем
				len_before = len_before - resist
				len = math.min(len, len_before)
				-- self.AirResistMul = self.AirResistMul * 2
			end
			
			if(self.PostPenetration)then
				self:PostPenetration(new_vel_normal, len, ricochet, ang_diff, len_before, trace)
			end
			
			if(stopped)then
				if(self.OnStopped) then
					self:OnStopped(nil, "hit", trace)
				end

				self:Die()
			end
		end
		
		return new_vel_normal, len, len_before
	end

	function PLUGIN.Class_Bullet:Die()
		self:Remove()
	end

	function PLUGIN.Class_Bullet:Remove()
		if(self.PreRemove)then
			if(self:PreRemove() == false)then
				return
			end
		end

		self.Removed = true
		PLUGIN.UnregisterBullet(self)

		if SERVER then
			if(self.CreationTime ~= CurTime())then
				PLUGIN.NetworkBulletRemove(self)
			end
		end
		
		if(self.PostRemove)then
			self:PostRemove()
		end
	end
--//

--\\Creation
	function PLUGIN.FlushCreateNet()
		local q = PLUGIN._netCreateQ
		if not q then return end
		PLUGIN._netCreateQ = nil
		for i = 1, #q do
			local b = q[i]
			if not b.Removed and not b.NoNetwork then
				PLUGIN.NetworkBulletFull(b, nil)
			end
		end
	end

	local function setup_and_spawn(bullet, lag_compensate)
		setmetatable(bullet, PLUGIN.Class_Bullet)
		translate_default_bullet_to_phys(bullet)

		bullet.AmmoID = bullet.AmmoID or 0
		bullet.Damage = bullet.Damage or 1
		bullet.AirResistMul = (bullet.AirResistMul or 0.0001) / 5
		bullet.Distance = bullet.Distance or 56756
		bullet.DistanceTraveled = 0
		bullet.LifeTime = bullet.LifeTime or 5
		bullet.LoseVelocity = bullet.LoseVelocity or 1
		bullet.Penetration = bullet.Penetration or 10
		define_if_not_defined(bullet, "DieOnHit", false)
		define_if_not_defined(bullet, "NoNetwork", false)
		define_if_not_defined(bullet, "NoNetworkUpdate", false)
		bullet.CreationTime = bullet.CreationTime or CurTime()
		bullet.LastUpdateTime = bullet.LastUpdateTime or bullet.CreationTime
		bullet.TraceFilter = bullet.TraceFilter or bullet.Shooter
		bullet.HG_IsBullet = true
		bullet._tr = bullet._tr or {}
		PLUGIN.SetupSizeHull(bullet)
		PLUGIN.RegisterBullet(bullet)

		if bullet.Damage == 0 then
			bullet.Damage = game.GetAmmoPlayerDamage(bullet.AmmoID) or 0
		end

		PLUGIN:RunHook("BulletPostSetup", bullet)

		if lag_compensate then bullet.Shooter:LagCompensation(true) end
		bullet:Think()
		if lag_compensate then bullet.Shooter:LagCompensation(false) end

		return bullet
	end

	function PLUGIN.CreateBullet(bullet)
		local num = bullet.Num or 1
		bullet.Num = nil
		local depth = (PLUGIN._createDepth or 0) + 1
		PLUGIN._createDepth = depth

		local lag_compensate = SERVER and IsValid(bullet.Shooter) and bullet.Shooter:IsPlayer()
		if lag_compensate then
			bullet.Vel = bullet.Vel + bullet.Shooter:GetVelocity()
		end

		local first = setup_and_spawn(bullet, lag_compensate)
		local net_q = SERVER and PLUGIN._netCreateQ

		if SERVER and not first.Removed and not first.NoNetwork then
			net_q = net_q or {}
			PLUGIN._netCreateQ = net_q
			net_q[#net_q + 1] = first
		end

		for i = 2, num do
			local pellet = copy_bullet(bullet)
			if SERVER and pellet.Spread then apply_spread(pellet) end
			setup_and_spawn(pellet, lag_compensate)
			if SERVER and not pellet.Removed and not pellet.NoNetwork then
				net_q = PLUGIN._netCreateQ or {}
				PLUGIN._netCreateQ = net_q
				net_q[#net_q + 1] = pellet
			end
		end

		PLUGIN._createDepth = depth - 1
		if depth == 1 then PLUGIN.FlushCreateNet() end

		PLUGIN:RunHook("BulletPostCreationNetwork", first)
		return first
	end
--//

--\\Calculations
	function PLUGIN.CalcMaterialResist(material, mul)
		return (PLUGIN.SurfaceHardness[material] or PLUGIN.DefaultSurfaceHardness) * (mul or 0.01)
	end

	function PLUGIN.CalcVelocityLostInMaterial(material, dist, len_before)
		local resist_mul = PLUGIN.CalcMaterialResist(material, 2)
		
		return math.max(len_before - resist_mul * dist, 0)
	end

	function PLUGIN.CalcHit(trace, len, len_before, trace_mask, penetration, size_mins, size_maxs)
		local trace_len = trace.Fraction * len
		local len_left = len - trace_len
		local trace_normal = trace.Normal
		local trace_hit_normal = trace.HitNormal
		local trace_angle = trace_normal:Angle()
		local surface_normal = trace.HitNormal
		local ricochet = true
		local stopped = false
		local ang_diff = -(math.deg(math.acos(trace_hit_normal:DotProduct(trace_normal))) - 180)
		local mat_hardness = PLUGIN.SurfaceHardness[trace.MatType] or PLUGIN.DefaultSurfaceHardness
		local penetration_mul = 1 - mat_hardness

		if len_before < 2500 then
			ricochet = false
			stopped = true
		else
			local penetration_dist = len_before * penetration_mul * PLUGIN.FirstPenetrationMul
			local hull_trace = PLUGIN._calcTr or {}
			PLUGIN._calcTr = hull_trace
			local move_vector = trace_normal * penetration_dist
			hull_trace.start = trace.HitPos + trace_normal
			hull_trace.endpos = hull_trace.start + move_vector
			hull_trace.mask = trace_mask
			local trace_new = util.TraceLine(hull_trace)
					
					if(trace_new.HitTexture == "**studio**")then
						local max_penetrate_iterations = 5
						local one_penetrate_chunk = (move_vector) / max_penetrate_iterations
						
						for penetrate_iteration = 1, max_penetrate_iterations do
							hull_trace.start = trace.HitPos + one_penetrate_chunk * penetrate_iteration + trace_normal
							hull_trace.endpos = hull_trace.start - one_penetrate_chunk * penetrate_iteration - trace_normal
							hull_trace.mask = trace_mask
							hull_trace.mins = size_mins
							hull_trace.maxs = size_maxs
							local trace_penetrating = nil
							
							if(size_mins and size_maxs)then
								trace_penetrating = util.TraceHull(hull_trace)
							else
								trace_penetrating = util.TraceLine(hull_trace)
							end
							
							if(!trace_penetrating.StartSolid)then
								ricochet = false

								break
							else
								if penetrate_iteration == max_penetrate_iterations then
									stopped = true
								end
							end
						end
					else
						if(trace.HitSky)then
							ricochet = false
						elseif(!trace_new.AllSolid and trace.HitTexture != "**displacement**")then
							if(size_mins and size_maxs)then	--; DEPRECATED
								--
							else
								ricochet = false
							end
						end
					end
					
			if (90 - ang_diff + util.SharedRandom("Ricochet", -15, 15, CurTime() * 100)) > (60 * mat_hardness * 0.6) then
				ricochet = false
			end
		end

		local ricochet_frac = (90 - ang_diff) / 90
		local new_vel_normal = nil
		
		if(ricochet)then
			trace_angle:RotateAroundAxis(surface_normal, 180)
			
			new_vel_normal = -trace_angle:Forward()
			new_vel_normal = new_vel_normal + Vector(util.SharedRandom("Ricochet", -1, 1, CurTime() + 1) * 0.3, util.SharedRandom("Ricochet", -1, 1, CurTime() + 2) * 0.3, util.SharedRandom("Ricochet", -1, 1, CurTime() + 3) * 0.3) * ricochet_frac
			new_vel_normal:Normalize()
		else
			new_vel_normal = trace_normal
		end
		
		return new_vel_normal, len_left, ricochet, ang_diff, stopped
	end
--//

--\\Hooks
	if #PLUGIN.BulletList == 0 then
		for _, b in pairs(PLUGIN.BulletsTable) do
			PLUGIN.BulletList[#PLUGIN.BulletList + 1] = b
			b._listIndex = #PLUGIN.BulletList
		end
	end

	PLUGIN:AddHook("Think", function()
		PLUGIN._thinkCT = CurTime()
		PLUGIN._thinkFT = SERVER and engine.TickInterval() or FrameTime()
		PLUGIN._thinkGrav = physenv.GetGravity()
		PLUGIN.ImpactThisFrame = 0
		local list = PLUGIN.BulletList
		for i = #list, 1, -1 do
			local b = list[i]
			if b and not b.Removed then b:Think() end
		end
	end)

	if CLIENT then
		PLUGIN:AddHook("PostDrawTranslucentRenderables", function(_, bSkybox)
			if bSkybox then return end
			local list = PLUGIN.BulletList
			for i = #list, 1, -1 do
				local b = list[i]
				if b and not b.Removed then b:Draw() end
			end
		end)
	end
--//

hook.Add("PostCleanupMap", "PhysBullets", function()
	local list = PLUGIN.BulletList
	for i = #list, 1, -1 do
		local b = list[i]
		if b then b:Die() end
	end
end)

hook.Add("EntityFireBullets", "あPhysBullets", function(ent, bullet)
	if(GetGlobalBool("PhysBullets_ReplaceDefault", false))then
		if(SERVER)then
			if bullet.DontUsePhysBullets then return end

			if(!IsValid(bullet.IgnoreEntity))then
				bullet.IgnoreEntity = ent
			end

			bullet.Spread = bullet.Spread or vector_origin

			if isnumber(bullet.Spread) then
				bullet.Spread = Vector(bullet.Spread, bullet.Spread, 0)
			end

			-- bullet.NoGravity = true
			-- bullet.DieOnHit = true
			-- bullet.Damage = 0
			local att = bullet.Attacker
			
			PLUGIN.CreateBullet(bullet)
			-- hook.Run("PostEntityFireBullets", ent, bullet)
		end
		
		return false
	end
end)

--\\Includes
	-- PLUGIN:Include("sv_plugin.lua")
	-- PLUGIN:Include("cl_plugin.lua")
--//

