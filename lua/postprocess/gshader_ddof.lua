
local shaderName = "GShaderDDoF"

-- TODO: NPC autofocus mode

local r_ddof_gshader 			= CreateClientConVar( "r_ddof_gshader", "0", true, false, "Enable Diffuse DDOF.", 0, 1 )
local r_ddof_gshader_debug 		= CreateClientConVar( "r_ddof_gshader_debug", "0", true, false, "Enable DDoF debug mode.", 0, 1 )
local r_ddof_gshader_aperture 	= CreateClientConVar( "r_ddof_gshader_aperture", "12", true, false, "DDoF aperture.", 5, 100 )
-- 22 16 11 8 5.6 4 2.8 1.8
local r_ddof_gshader_radius 	= CreateClientConVar( "r_ddof_gshader_radius", "2", true, false, "DDoF boken radius.", 1, 20 )
local r_ddof_gshader_near 		= CreateClientConVar( "r_ddof_gshader_near", "0.10", true, false, "DDoF near scale.", 0.01, 5 )
local r_ddof_gshader_manual		= CreateClientConVar( "r_ddof_gshader_manual", "0", true, false, "Enable DDoF manual focus distance.", 0, 1 )
local r_ddof_gshader_focus		= CreateClientConVar( "r_ddof_gshader_focus", "600", true, false, "DDoF manual focus distance.", 0, 1000000 )

-- Bokeh
local r_ddof_gshader_mul 		= CreateClientConVar( "r_ddof_gshader_mul", "5", true, false, "DDoF luminance multiplier.", 0, 5 )
local r_ddof_gshader_bias		= CreateClientConVar( "r_ddof_gshader_bias", "5", true, false, "DDoF luminance bias.", 0, 5 )
local r_ddof_gshader_exposure	= CreateClientConVar( "r_ddof_gshader_exposure", "0", true, false, "DDoF exposure.", 0, 5 )

local function InitDDOF()
	local mat_coc = Material("pp/pp_coc")
	local mat_ddof_blur_near = Material("pp/pp_ddof_blur_near")
	local mat_ddof_blur_far = Material("pp/pp_ddof_blur_far")
	local mat_ddof_combine = Material("pp/pp_ddof_combine")
	local coc_max = Material("pp/pp_coc_max")
	local coc_combine = Material("pp/pp_coc_combine")
	local coc_debug = Material("pp/pp_coc_debug")

	local scrw, scrh = ScrW(), ScrH()

	local linux = render.GetDXLevel() == 92 or system.IsLinux() or system.IsOSX()
	local coc_size = 0.5

	-- https://github.com/doitsujin/dxvk/pull/5608

	local rt_coc = GetRenderTargetEx("_rt_CoC", scrw*coc_size, scrh*coc_size,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_NONE,
		bit.bor(4,8,256,512),
		0,
		linux and IMAGE_FORMAT_RGBA8888 or IMAGE_FORMAT_IA88
		--IMAGE_FORMAT_BGRX8888
		--IMAGE_FORMAT_IA88
	)
	
	local rt_coc_near = GetRenderTargetEx("_rt_CoC_near", scrw*coc_size, scrh*coc_size,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_NONE,
		bit.bor(4,8,256,512),
		0,
		--IMAGE_FORMAT_BGRX8888
		linux and IMAGE_FORMAT_RGBA8888 or IMAGE_FORMAT_I8
	)

	local dof_size = 0.5

	local dof_image_format = IMAGE_FORMAT_RGB888 --IMAGE_FORMAT_BGRX8888 -- IMAGE_FORMAT_BGRX8888 IMAGE_FORMAT_RGBA16161616

	local rt_dof_near = GetRenderTargetEx("_rt_DoF_near", scrw*dof_size, scrh*dof_size,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_NONE,
		bit.bor(4,8,256,512),
		0,
		dof_image_format -- IMAGE_FORMAT_RGBA1010102
	)

	local rt_dof_far = GetRenderTargetEx("_rt_DoF_far", scrw*dof_size, scrh*dof_size,
		RT_SIZE_LITERAL,
		MATERIAL_RT_DEPTH_NONE,
		bit.bor(4,8,256,512),
		0,
		dof_image_format -- IMAGE_FORMAT_RGBA1010102
	)

	local aperture = r_ddof_gshader_aperture:GetFloat()
	mat_coc:SetFloat("$c2_z", aperture)
	local BokehRadius = r_ddof_gshader_radius:GetFloat()
	mat_ddof_blur_near:SetFloat("$c0_x", BokehRadius)
	mat_ddof_blur_far:SetFloat("$c0_x", BokehRadius)
	mat_ddof_blur_far:SetFloat("$c1_y", r_ddof_gshader_mul:GetFloat())
	mat_ddof_blur_far:SetFloat("$c1_z", r_ddof_gshader_bias:GetFloat())
	mat_ddof_blur_far:SetFloat("$c1_w", r_ddof_gshader_exposure:GetFloat())
	
	cvars.AddChangeCallback( r_ddof_gshader_aperture:GetName(), function( convar_name, _, identifier )
		mat_coc:SetFloat("$c2_z", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ddof_gshader_radius:GetName(), function( convar_name, _, identifier )
		mat_ddof_blur_near:SetFloat("$c0_x", identifier)
		mat_ddof_blur_far:SetFloat("$c0_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ddof_gshader_mul:GetName(), function( convar_name, _, identifier )
		mat_ddof_blur_near:SetFloat("$c1_y", identifier)
		mat_ddof_blur_far:SetFloat("$c1_y", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ddof_gshader_bias:GetName(), function( convar_name, _, identifier )
		mat_ddof_blur_near:SetFloat("$c1_z", identifier)
		mat_ddof_blur_far:SetFloat("$c1_z", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ddof_gshader_exposure:GetName(), function( convar_name, _, identifier )
		mat_ddof_blur_near:SetFloat("$c1_w", identifier)
		mat_ddof_blur_far:SetFloat("$c1_w", identifier)
	end, shaderName )


	--local temp_hitPos = vector_origin
	 temp_hitPos = vector_origin

	local screentexture = render.GetScreenEffectTexture()

	local debug_mode = r_ddof_gshader_debug:GetBool()
	local hitPos = vector_origin

	local function GetCameraView( client )
		local viewSetup = render.GetViewSetup()
		local origin = viewSetup.origin
		local angles = viewSetup.angles
		local fov = viewSetup.fov

		if hg and hg.gshaderView and hg.PlyInFake and hg.PlyInFake( client ) then
			local view = hg.gshaderView
			if view.origin then origin = view.origin end
			if view.angles then angles = view.angles end
			if view.fov then fov = view.fov end
		end

		return origin, angles, fov, viewSetup
	end

	local function GetFocusFilter( client )
		local filter = { client:GetVehicle(), client:GetViewEntity() or client }

		if IsValid( client.FakeRagdoll ) then
			filter[ #filter + 1 ] = client.FakeRagdoll
		end

		if IsValid( client.OldRagdoll ) then
			filter[ #filter + 1 ] = client.OldRagdoll
		end

		return filter
	end

	local function EnableDDOF()
		if !GSHADER then
			LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of ssr https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
			return
		end
		
		if GetConVar("mat_aaquality"):GetInt() > 0 then
			LocalPlayer():ChatPrint( "CAUTION! MSAA NOT SUPPORT DEFERRED RENDER. Use SMAA or FXAA addon!" )
		end

		if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", "1") end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", "1") end

		hook.Add("PostDrawEffects", shaderName, function()
			if !shaderlib.CanDrawEffects() then return end

			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)
			
			local enabled_3dsky	= game.Get3DSkyboxInfo()
			local skybox_scale	= enabled_3dsky and enabled_3dsky.scale or 1
			local sky_camera_pos	= enabled_3dsky and enabled_3dsky.origin or vector_origin
			
			local client = LocalPlayer()
			local eyepos, eyeAng, camFov, viewSetup = GetCameraView( client )

			--local _FocusRange

			if r_ddof_gshader_manual:GetBool() then
				_FocusRange = r_ddof_gshader_focus:GetFloat()
			else
				local forward = eyeAng:Forward()
				local dir = forward * 100000000
				local filter = GetFocusFilter( client )

				local tr = util.TraceLine({
				    start = eyepos;
				    endpos = eyepos + dir;
				    filter = filter;
				    mask = MASK_BLOCKLOS_AND_NPCS;
				})

				hitPos = tr.HitPos
				local hitSky = tr.HitSky

				if hitSky and enabled_3dsky and GetConVar("r_3dsky"):GetBool() == true then
				    local eye_sky = sky_camera_pos + eyepos/skybox_scale

				    local tr = util.TraceLine({
					    start = eye_sky;
					    endpos = eye_sky + dir;
					    mask = MASK_BLOCKLOS_AND_NPCS;
					})

					hitPos = (tr.HitPos-sky_camera_pos)*skybox_scale
				end

				local temp_dist = temp_hitPos:Distance(hitPos)
				local adaptive_speed = 0.1 * (temp_dist / (1 + temp_dist))
				temp_hitPos = LerpVector(adaptive_speed, temp_hitPos, hitPos)
				_FocusRange = 100 + temp_hitPos:Distance(eyepos)
			end

			if hg and hg.PlyInFake and hg.PlyInFake( client ) then
				_FocusRange = _FocusRange + 200
			end

			mat_coc:SetFloat("$c0_x", 1 / _FocusRange * r_ddof_gshader_near:GetFloat() )
			mat_coc:SetFloat("$c0_y", _FocusRange)

			local fov = math.tan(math.rad(camFov * 0.5))
			-- reconstruct focallength from fov
			local aspect_ratio = viewSetup.aspect
			local sensor_width = 36.0
			sensor_width = sensor_width / aspect_ratio
			local focallength = sensor_width / (2 * fov)

			mat_coc:SetFloat("$c2_y", focallength)

			render.PushRenderTarget(rt_coc)
				render.Clear(0,0,0,0)
				render.SetMaterial(mat_coc)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.PushRenderTarget(rt_coc_near)
				render.Clear(0,0,0,0)
				render.SetMaterial(coc_max)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.PushRenderTarget(rt_coc)
				render.SetMaterial(coc_combine)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.PushRenderTarget(rt_dof_near)
				render.Clear(0,0,0,0)
				render.SetMaterial(mat_ddof_blur_near)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.PushRenderTarget(rt_dof_far)
				render.Clear(0,0,0,0)
				render.SetMaterial(mat_ddof_blur_far)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.SetMaterial(mat_ddof_combine)
			render.DrawScreenQuad()

			--render.DrawTextureToScreen(rt_dof)
		end)
	end

	local color_red = Color(255,0,0)

	local function EnableDebugMode()
		hook.Add("PreDrawHUD", shaderName, function()
			render.SetMaterial(coc_debug)
			render.DrawScreenQuad()
			
			if r_ddof_gshader_manual:GetBool() then return end

			cam.Start3D()
				render.SetColorMaterial()
				render.DrawSphere(hitPos, 2, 16, 16, color_red)
			cam.End3D()
		end)
	end

	cvars.AddChangeCallback( r_ddof_gshader_debug:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		debug_mode = state

		if state then
			EnableDebugMode()
		else
			hook.Remove("PreDrawHUD", shaderName)
		end
	end, shaderName )

	if debug_mode then EnableDebugMode() end
	
	cvars.AddChangeCallback( r_ddof_gshader:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		if state then
			EnableDDOF()
			if r_ddof_gshader_debug:GetBool() then EnableDebugMode() end
		else
			hook.Remove("PostDrawEffects", shaderName)
			hook.Remove("PreDrawHUD", shaderName)
		end
	end, shaderName )

	if r_ddof_gshader:GetBool() then EnableDDOF() end

	DOF_INITED = true
end

if DOF_INITED then
	InitDDOF()
end

hook.Add("PostCEFCodecFixStatus", shaderName, InitDDOF)

/*
local GOLDEN_ANGLE = 2.39996323;
local points64 = {};
local points16 = {};

local idx64 = 0;
local idx16 = 0;
local max = 80
for j = 0, max - 1 do
	local theta = j * GOLDEN_ANGLE;
	local r = math.sqrt(j) / math.sqrt(max);

	local p = Vector(r * math.cos(theta), r * math.sin(theta), 0);

	if (j % 5 == 0) then
		points16[idx16] = p;
		idx16 = idx16 +1;
	else
		points64[idx64] = p;
		idx64 = idx64 + 1;
	end
end

local function print_krenel()
	print( "static const float2 kernel[" .. max .. "] = {" )
	for i = 0, #points64 do
		print( "float2(" .. points64[i].x ..  ", " ..  points64[i].y .. ")," )
	end
	print( "}" )

	print( "static const float2 PentagonOffsets[" .. 16 .. "] = {" )
	for i = 0, #points16 do
		print( "float2(" .. points16[i].x ..  ", " ..  points16[i].y .. ")," )
	end
	print( "}" )
end
*/
