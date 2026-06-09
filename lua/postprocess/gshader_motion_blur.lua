local shaderName = "MotionBlur"

local r_motionblur 				= CreateClientConVar( "r_motionblur", "0", true, false, "Enable/Disable Motion Blur.", 0, 1 )
local r_motionblur_x 			= CreateClientConVar( "r_motionblur_x", "0.5", true, false, "Motion Blur horizontal.", 0.1, 50 )
local r_motionblur_y 			= CreateClientConVar( "r_motionblur_y", "0.5", true, false, "Motion Blur vertical.", 0.1, 50 )
local r_motionblur_clamp 		= CreateClientConVar( "r_motionblur_clamp", "100", true, false, "Motion Blur vertical.", 1, 1000 )
local r_motionblur_exponent 	= CreateClientConVar( "r_motionblur_exponent", "150", true, false, "Motion Blur lerp exponent.", 5, 400 )
local r_motionblur_debugmode 	= CreateClientConVar( "r_motionblur_debugmode", "0", false, false, "Motion Blur debug mode.", 0, 1 )

-- Per object
local r_motionblur_per_object	= CreateClientConVar( "r_motionblur_per_object", "1", true, false, "Enable/Disable Per object Motion Blur.", 0, 1 )
local r_motionblur_scale_npcs 	= CreateClientConVar( "r_motionblur_scale_npcs", "2", true, false, "Motion Blur velocity per object NPCs scale.", 0, 10 )
local r_motionblur_scale_props	= CreateClientConVar( "r_motionblur_scale_props", "2", true, false, "Motion Blur velocity per object props scale.", 0, 10 )
local r_motionblur_dist			= CreateClientConVar( "r_motionblur_dist", "1500", true, false, "Motion Blur velocity per object distance.", 0, 10000 )
local r_motionblur_targetfps	= CreateClientConVar( "r_motionblur_targetfps", "300", true, false, "Motion Blur velocity per object distance.", 30, 300 )
local r_motionblur_format		= CreateClientConVar( "r_motionblur_format", "1", true, false, "Motion Blur velocity per object format.", 0, 1 )

local decode = !r_motionblur_format:GetBool()

local mat_motionblur = decode and Material("pp/pp_motion_blur_decode") or Material("pp/pp_motion_blur")
local mat_motionblur_camera = Material("pp/pp_motion_blur_camera")
local mat_motionblur_debug = decode and Material("pp/pp_motion_blur_debug_decode") or Material("pp/pp_motion_blur_debug")
-- pp_motion_blur_decode

local rt_size = 1--1 -- 0.5 0.25
local scrw, scrh = ScrW(), ScrH()
local w_size, h_size = scrw * rt_size, scrh * rt_size

local blacklist_rendergroups = {
	[RENDERGROUP_VIEWMODEL] = true,
	[RENDERGROUP_VIEWMODEL_TRANSLUCENT] = true,
}

local blacklist_rendermode = {
	[RENDERMODE_TRANSTEXTURE] = true;
	[RENDERMODE_NONE] = true;
}

local blacklist_dynamic_ent = {
	["func_brush"] 						= true,
	["viewmodel"] 						= true,
	["gmod_hands"] 						= true,
	["phys_bone_follower"] 				= true,
	["player"] 							= true, // Players are blacklisted as shadow casting entities as they are rendered separately from the entity.
	["func_movelinear"] 				= true,
	["func_illusionary"] 				= true,
	["class C_BaseFlex"] 				= true,
	["mg_viewmodel"] 					= true, // Modern Warfare Weapons
	["class C_FuncOccluder"] 			= true,
	["phys_bone_follower"] 				= true,
	["class C_BaseToggle"] 				= true,
	["class C_Func_Dust"] 				= true,
	["func_breakable_surf"] 			= true,
	["class C_FuncAreaPortalWindow"] 	= true,
	["env_steam"] 						= true,
	["env_fire"] 						= true,
	["class C_RopeKeyframe"] 			= true,
	["class C_EnvScreenOverlay"] 		= true,
	["class C_ParticleSystem"] 			= true,
	["env_sprite"] 						= true,
	["class C_EnvWind"] 				= true,
	["class C_LightGlow"] 				= true,
	["class C_ColorCorrectionVolume"] 	= true,
	["class C_FogController"] 			= true,
	["class C_ColorCorrection"] 		= true,
	["class C_BaseEntity"] 				= true,
	["class C_GMODGameRulesProxy"] 		= true,
	["class C_PlayerResource"] 			= true,
	["prop_effect"] 					= true,
	["prop_dynamic"] 					= true,
	["prop_door"] 						= true,
	["prop_door_rotating"] 				= true,
	["manipulate_bone"] 				= true,
}

per_object_motion_blur_ents = per_object_motion_blur_ents or {}
per_object_motion_blur_index = per_object_motion_blur_index or {}
per_object_motion_blur_mats = per_object_motion_blur_mats or {}

local rt_velocity_object
local rt_velocity_dummy

local function createMat(name,shader,kv)
	local mat = CreateMaterial(name, shader, kv)
	mat:SetInt("$flags2", 130)
	return mat
end

local mat_writer = decode and Material("pp/velocity_write_encode") or Material("pp/velocity_write")
local key_values = mat_writer:GetKeyValues()
key_values["$flags"] = nil
key_values["$flags2"] = nil
key_values["$flags_defined"] = nil
key_values["$flags_defined2"] = nil
local mat_shader = mat_writer:GetShader()
local key_values_alphatest = table.Copy(key_values)
key_values_alphatest["$pixshader"] = decode and "velocitywrite_alphatest_encode_ps30" or "velocitywrite_alphatest_ps30"

hook.Add("OnEntityCreated", "MotionBlurPerObject", function(ent)
	if !ent:IsValid() then return end
	if ent:GetNoDraw() or ent:IsWeapon() then return end
	if ent == game.GetWorld() then return end
	if blacklist_rendermode[ent:GetRenderMode()] then return end
	if blacklist_rendergroups[ent:GetRenderGroup()] then return end
	local model = ent:GetModel()
	if !model or model == "" then return end
	if IsUselessModel(model) then return end
	if string.find(model,".vmt") then return end
	if string.find(model,".bsp") then return end
	if string.find(model,"C_") then return end
	local class = ent:GetClass()
	if string.find(class,"C_") then return end
	local mats = ent:GetMaterials()
	if #mats <= 0 then return end
	local index = ent:EntIndex()
	if index <= -1 then return end
	if blacklist_dynamic_ent[class] then return end

	local i = #per_object_motion_blur_ents + 1
	per_object_motion_blur_ents[i] = ent
	per_object_motion_blur_index[index] = i
	ent.mins, ent.maxs = ent:GetModelBounds()

	per_object_motion_blur_mats[i] = {}

	local ct_ind = CurTime() + index

	for i2 = 1,#mats do
		local tex = mats[i2]

		local patch = "materials/"..tex..".vmt"
		local mat_file = file.Read( patch, "GAME" )

		local name = "per_object_velocity" .. ct_ind + i2 -- надо регать от куртайма

		if !mat_file then per_object_motion_blur_mats[i][#per_object_motion_blur_mats[i] + 1] = createMat(name,mat_shader,key_values) continue end

		local orig_mat_key_values = util.KeyValuesToTable( mat_file )

		local alphatest = (orig_mat_key_values["$alphatest"] or 0) >= 1 or (orig_mat_key_values["$translucent"] or 0) >= 1

		local alphatest_reference = orig_mat_key_values["$alphatestreference"] or 0.5

		if !alphatest then per_object_motion_blur_mats[i][#per_object_motion_blur_mats[i] + 1] = createMat(name,mat_shader,key_values) continue end

		-- creating mat with alphatest support
		local mat_alpha = createMat(name,mat_shader,key_values_alphatest)
		-- basetexture bind
		local bt = Material( tex ):GetTexture("$basetexture")
		mat_alpha:SetFloat( "$c1_x", alphatest_reference )

		mat_alpha:SetTexture( "$BASETEXTURE", bt )
		per_object_motion_blur_mats[i][#per_object_motion_blur_mats[i] + 1] = mat_alpha
	end
end)

hook.Add("EntityRemoved", shaderName, function(ent)
	if !ent:IsValid() then return end
	local index = ent:EntIndex()
	local id = per_object_motion_blur_index[index]
	if !id then return end

	table.remove(per_object_motion_blur_ents, id)
	table.remove(per_object_motion_blur_mats, id)

	per_object_motion_blur_index[index] = nil
end)

hook.Add("ShutDown", shaderName, function()
	hook.Remove("EntityRemoved", shaderName)
end)

local ply_prev_pos = Vector(0,0,0)
--local encode = false
--local vector050505 = Vector(0.5, 0.5, 0.5)

local renderflags2 = bit.bor( STUDIO_RENDER, (STUDIO_SKIP_DECALS or 0), (STUDIO_SKIP_FLEXES or 0) )
local renderflags = bit.bor( STUDIO_RENDER, STUDIO_NOSHADOWS, (STUDIO_SKIP_DECALS or 0), (STUDIO_SKIP_FLEXES or 0) ) --bit.bor( STUDIO_RENDER, STUDIO_NOSHADOWS, STUDIO_SHADOWDEPTHTEXTURE, (STUDIO_SKIP_DECALS or 0), (STUDIO_SKIP_FLEXES or 0) )
-- убран флаг STUDIO_SHADOWDEPTHTEXTURE. плохо работат с сет материал

local function drawMotionBlurModel(ent, eyepos, config_dist, ply_velocity, parent, vehicle, fps_factor, mat_table, noflags, cam_pos, cam_angles,view_mins, view_maxs)
	local succ = 0

	if !IsValid( ent ) then return succ end
	if ent:GetNoDraw() then return succ end

	local pos = ent:GetPos()
	
	local prev_pos = (ent.old_pos or vector_origin)

	local vVelocity = ( pos - prev_pos ):Length()

	if ( vVelocity != 0 ) then -- самая дешевая проверка
		-- Distance optimization
		if ( pos:DistToSqr( eyepos ) <= config_dist ) then
			-- PVS optimization
			if NikNaks.CurrentMap:PVSCheck( eyepos, pos ) then
				-- BBOX optimization
				local ang = ent:GetAngles()
				if !ent.maxs or util.IsOBBIntersectingOBB(pos,ang,ent.mins, ent.maxs,cam_pos, cam_angles,view_mins, view_maxs, 0) then

					
					local char = ( ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot() )
					local m_flVelocityScale = char and r_motionblur_scale_npcs:GetFloat() or r_motionblur_scale_props:GetFloat()

					local mats = ent:GetMaterials()

					local ent_velocity = pos - prev_pos

					local factor = ply_velocity - ent_velocity
					factor = Vector(
						math.min( 1, math.abs( factor.x ) ),
						math.min( 1, math.abs( factor.y ) ),
						math.min( 1, math.abs( factor.z ) )
					)

					local factor_max = math.max( factor.x, math.max( factor.y, factor.z ) + 1e-4 )

					if IsValid(vehicle) then 
						factor_max = 1e-4
					end

					if ( factor_max != 0 ) then -- Avoid rendering if the speed is the same as the player's.
						local p_prev = prev_pos:ToScreen()
						local p_cur = pos:ToScreen()

						local per_object_velocity = Vector(p_cur.x / scrw, p_cur.y / scrh, 0) - Vector(p_prev.x / scrw, p_prev.y / scrh, 0)
						per_object_velocity.x = math.Clamp(per_object_velocity.x, -1, 1)
						per_object_velocity.y = math.Clamp(per_object_velocity.y, -1, 1)
						
						-- if encode then per_object_velocity = per_object_velocity * 0.5 + vector050505 end

						local factor = factor_max * fps_factor
						
						if decode then factor = math.min(factor, 1) end
						local scale_factor = m_flVelocityScale * factor

						local x = scale_factor * per_object_velocity.x 
						local y = scale_factor / 4 * per_object_velocity.y 

						mat_writer:SetFloat( "$c0_x", x )
						mat_writer:SetFloat( "$c0_y", y )
						mat_writer:SetFloat( "$c2_x", factor_max )

						if mat_table then
							for i2 = 1,#mats do
								local mat = mat_table[i2] or mat_writer
								mat:SetFloat( "$c0_x", x )
								mat:SetFloat( "$c0_y", y )
								mat:SetFloat( "$c2_x", factor_max )
								render.MaterialOverrideByIndex( i2 - 1, mat )
							end
						else
							render.ModelMaterialOverride( mat_writer )
						end
						local flags = noflags and renderflags2 or renderflags
						--render.SetRenderTargetEx(1, rt_velocity_object)
						ent:DrawModel( flags )
						succ = 1

						if mat_table then
							for i2 = 1,#mats do
								render.MaterialOverrideByIndex( i2 - 1, nil )
							end
						end
						
						render.ModelMaterialOverride( mat_writer )
																	-- Vehicle
						local childred = ent:GetChildren()
						if childred then 							
							for i = 1,#childred do
								local ent1 = childred[i] 			-- Player
								-- if !IsValid(ent1) then continue end
								local isWeapon = ent1:IsWeapon()
								if isWeapon then
									if ent.GetActiveWeapon and ent:GetActiveWeapon() then
										if ent1 != ent:GetActiveWeapon() then continue end
									end

									--render.SetRenderTargetEx(1, rt_velocity_object)

									ent1:DrawModel( flags )
									if isWeapon then continue end

									local childred2 = ent1:GetChildren()
									if childred2 then 			
										for i = 1,#childred2 do
											local ent2 = childred2[i] 	-- Weapon
											--render.SetRenderTargetEx(1, rt_velocity_object)
											ent2:DrawModel( flags )
										end
									end
								end

							end
						end

						render.ModelMaterialOverride()
					end
				end
			end
		end
	end

	local factor = 1 - math.exp(-600 * math.max(FrameTime(), 0.01) )
	if ent.old_pos and LocalPlayer() != ent then
		ent.old_pos = LerpVector(factor, ent.old_pos, pos)
	else
		ent.old_pos = ent:GetPos()
	end

	return succ
end

local function CalcFPSFactor()
	local frametime = FrameTime()
	local target_fps = r_motionblur_targetfps:GetFloat()
	if frametime == 0 then frametime = 1 / target_fps end
	local fps = 1 / frametime
	local fps_factor = fps / target_fps
	return fps_factor
end

local function MotionBlurPerObject()
	local fps_factor = CalcFPSFactor()

	local config_dist = r_motionblur_dist:GetFloat() ^ 2
	local viewSetup = render.GetViewSetup(true)
	local viewProj = shaderlib.GetViewProjMatrix(viewSetup)
	local znear = viewSetup.znear
	viewSetup.znear = znear + 0.005 -- bias fix. можно сделать выше, чтобы пропали декали

	local client = LocalPlayer()
	local ply_pos = client:GetPos()
	local parent = client:GetParent()
	local vehicle = client:GetVehicle()

	-- if IsValid(vehicle) then
	--	ply_pos = vehicle:GetPos()
	-- end

	local aspect = viewSetup.aspect

	viewSetup.w = scrw * rt_size
	viewSetup.h = scrh * rt_size

	local thirdperson = client:ShouldDrawLocalPlayer()
	local eyepos = MainEyePos()

	local ply_velocity = ply_pos - ply_prev_pos

	render.PushRenderTarget(rt_velocity_object)
		render.Clear(0,0,0,0)
	render.PopRenderTarget()

	local drawcalls = 0
	
	-- BBOX optimization
	local eyepos = viewSetup.origin
	local fov = math.cot( math.rad( viewSetup.fov * 0.5 ) )
	local zfar = viewSetup.zfar
	local halfH_far = zfar / fov
	local halfW_far = halfH_far * viewSetup.aspect
	local pos = eyepos + viewSetup.angles:Forward() * znear
	local view_mins = Vector(0, -halfW_far, -halfH_far)
	local view_maxs = Vector(zfar - znear,  halfW_far,  halfH_far)
	local angles = viewSetup.angles

	-- BUG: если сетнуть материал, случается баг
	render.PushRenderTarget(rt_velocity_object) 
		cam.Start(viewSetup)
		render.OverrideDepthEnable(true, true)
			local velocity = GetViewEntity() != client and vector_origin or ply_velocity

			for i = 1,#per_object_motion_blur_ents do -- очень дорогой цикл
				local ent = per_object_motion_blur_ents[i]
				local mat_table = per_object_motion_blur_mats[i]
				drawcalls = drawcalls + drawMotionBlurModel(ent, eyepos, config_dist, velocity, parent, vehicle, fps_factor, mat_table, nil, pos, angles,view_mins, view_maxs)
			end

			if GetViewEntity() != client or thirdperson then
				if client:Alive() then
					drawcalls = drawcalls + drawMotionBlurModel(client, eyepos, config_dist, velocity, parent, vehicle, fps_factor, nil, true,pos, angles,view_mins, view_maxs)
				end
			end

			-- render players
			for _, ply in player.Iterator() do
				if ply == client then continue end
				if !ply:Alive() then continue end
				drawcalls = drawcalls + drawMotionBlurModel(ply, eyepos, config_dist, velocity, parent, vehicle, fps_factor, nil, nil,pos, angles,view_mins, view_maxs)
			end 
		render.OverrideDepthEnable(false, false)
		cam.End()
	render.PopRenderTarget()

	ply_prev_pos = ply_pos

	return fps_factor, drawcalls
end

-- end velocity buffer per object

local screentexture = render.GetScreenEffectTexture()

old_ViewProj = old_ViewProj or Matrix()

local MotionBlur = {}
MotionBlur.pos = vector_origin
MotionBlur.ang = angle_zero
MotionBlur.fov = 90

local function InitMotionData()
	local viewSetup = render.GetViewSetup()
	if shaderlib then
		old_ViewProj = shaderlib.GetViewProjMatrix(viewSetup)
	end

	MotionBlur.pos = viewSetup.origin
	MotionBlur.ang = viewSetup.angles
	MotionBlur.fov = viewSetup.fov
end

hook.Add( "InitPostEntity", shaderName, InitMotionData)

local motion_blur_stencil = 21

local function InitMotionBlur()
	-- Velocity buffer per object
	local linux =  ( system.IsLinux() or system.IsOSX() or render.GetDXLevel() == 92 )
	-- лучше всего использовать стенсилы на двойной рендер модели и затем по стенсилу записывать его буфер велосити
	-- MATERIAL_RT_DEPTH_SEPARATE 

	local format = decode and IMAGE_FORMAT_RGBA8888 or IMAGE_FORMAT_RGBA16161616F
	
	rt_velocity_object = GetRenderTargetEx("_rt_Velocity_object", w_size, h_size,
		RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_SHARED, bit.bor(4, 8, 256, 512), 0, format) -- IMAGE_FORMAT_RG1616F
	
	--rt_velocity_dummy = GetRenderTargetEx("_rt_Velocity_dummy", w_size, h_size,
	--	RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_SHARED, bit.bor(4, 8, 256, 512), 0, IMAGE_FORMAT_A8) -- MATERIAL_RT_DEPTH_NONE MATERIAL_RT_DEPTH_SHARED
	
	local hookname = "PostDrawTranslucentRenderables"
	
	local function EnableMotionBlur()
		if !GSHADER then
			LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of Motion blur https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
			return
		end

		if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", "1") end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", "1") end
		if !GetConVar("r_shaderlib_bumps"):GetBool() then  RunConsoleCommand("r_shaderlib_bumps", "1") end

		InitMotionData()

		local old_motion_blur = GetConVar("mat_motion_blur_enabled"):GetInt()
		local old_motion_intensity = GetConVar("mat_motion_blur_falling_intensity"):GetFloat()

		if !linux then -- linux game freeze 
			RunConsoleCommand("mat_motion_blur_enabled", 0)
		end
		RunConsoleCommand("mat_motion_blur_falling_intensity", 0)

		local function DrawGShaderMotionBlur()
			local fps_factor, drawcalls = hook.Run("PreDrawMotionBlur")
			if !fps_factor then fps_factor = CalcFPSFactor() end

			local debug_mode = r_motionblur_debugmode:GetBool()
			local mat = (drawcalls or 0) <= 0 and mat_motionblur_camera or mat_motionblur
			if debug_mode then mat = mat_motionblur_debug end

			mat:SetFloat("$c0_x", r_motionblur_x:GetFloat() * fps_factor )
			mat:SetFloat("$c0_y", r_motionblur_y:GetFloat() * fps_factor )
			mat:SetMatrix("$VIEWPROJMAT", old_ViewProj)
			mat:SetFloat("$c1_x", r_motionblur_clamp:GetFloat()*0.001 )

			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)

			render.SetMaterial(mat)
		    render.DrawScreenQuad()

		    if debug_mode then
		    	cam.Start2D()
		    	draw.DrawText("Per object drawcalls: " .. (drawcalls or 0), "BudgetLabel", ScrW()*0.5,ScrH()*0.2,color_white,TEXT_ALIGN_CENTER)
		    	cam.End2D()
		    end

	        hook.Run("PostDrawMotionBlur")
	        --render.DrawTextureToScreen(rt_velocity_object)
		end

		hook.Add(hookname, shaderName, function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
			if isDrawSkybox then return end
	        if isDraw3DSkybox then return end
	        if isDrawingDepth then return end

			if !shaderlib.CanDrawEffects() then return end
			DrawGShaderMotionBlur()
		end)

		hook.Add("PostDrawEffects", shaderName, function() -- Beatrun fix
			if !shaderlib.CanDrawEffects() then return end
			local viewSetup = render.GetViewSetup(true)
			local factor = 1 - math.exp(-MotionBlur.exponent * math.max(FrameTime(), 0.01) )
	        
	        MotionBlur.pos = LerpVector(factor, MotionBlur.pos, viewSetup.origin)
	        MotionBlur.ang = LerpAngle(factor, MotionBlur.ang, viewSetup.angles)
	        MotionBlur.fov = Lerp(factor, MotionBlur.fov, viewSetup.fov)

	        viewSetup.origin = MotionBlur.pos
	        viewSetup.angles = MotionBlur.ang
	        viewSetup.fov = MotionBlur.fov

	        old_ViewProj = shaderlib.GetViewProjMatrix(viewSetup)
		end)
	end

	if r_motionblur:GetBool() then EnableMotionBlur() end

	cvars.AddChangeCallback( r_motionblur:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			EnableMotionBlur()
		else
			if !linux then
				RunConsoleCommand("mat_motion_blur_enabled", old_motion_blur)
			end
			RunConsoleCommand("mat_motion_blur_falling_intensity", old_motion_intensity)
			hook.Remove( "GetMotionBlurValues", shaderName)
			hook.Remove(hookname, shaderName)
			hook.Remove("PrePlayerDraw", shaderName)
			hook.Remove("PostPlayerDraw", shaderName)
			hook.Remove("PostDrawMotionBlur", shaderName)
			hook.Remove("PostDrawEffects", shaderName)
		end
	end, shaderName )

	local function ActivatePerObject()
		if GetConVar("mat_aaquality"):GetInt() > 0 or GetConVar("mat_antialias"):GetInt() > 1  then
			LocalPlayer():ChatPrint( "Выключи сглаживание в настройках графики. можешь включить SMAA или FXAA в настройках з сити" )
			return
		end

		hook.Add("PreDrawMotionBlur", shaderName, MotionBlurPerObject)
	end

	if r_motionblur_per_object:GetBool() then
		ActivatePerObject()
	end
	
	cvars.AddChangeCallback( r_motionblur_per_object:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			ActivatePerObject()
		else
			hook.Remove("PreDrawMotionBlur", shaderName)
			hook.Add("PreRender", shaderName, function()
				render.PushRenderTarget(rt_velocity_object)
					render.Clear(0,0,0,0)
				render.PopRenderTarget()
				hook.Remove("PreRender", shaderName)
			end)
		end
	end, shaderName )

	INITED_MOTIONBLUR = true
end

if INITED_MOTIONBLUR then
	InitMotionBlur()
end

hook.Add("PostCEFCodecFixStatus", shaderName, function()
	timer.Simple(0, function()
		InitMotionBlur()
	end)
end)

cvars.AddChangeCallback( r_motionblur_clamp:GetName(), function( convar_name, _, identifier )
	mat_motionblur:SetFloat("$c1_x", tonumber(identifier)*0.001 )
	mat_motionblur_camera:SetFloat("$c1_x", tonumber(identifier)*0.001 )
end, shaderName )


MotionBlur.exponent = r_motionblur_exponent:GetFloat()

cvars.AddChangeCallback( r_motionblur_exponent:GetName(), function( convar_name, _, identifier )
	MotionBlur.exponent = tonumber(identifier)
end, shaderName )
