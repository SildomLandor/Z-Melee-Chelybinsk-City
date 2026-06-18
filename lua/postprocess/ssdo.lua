local shaderName = "SSDO"

local pp_ssdo					= CreateClientConVar( "pp_ssdo", "0", true, false, "Enable/Disable screen space direction occlusion.", 0, 1 )
local pp_ssdo_contrast 			= CreateClientConVar( "pp_ssdo_contrast", "4", true, false, "SSDO contrast.", 1, 10 )
local pp_ssdo_radius 			= CreateClientConVar( "pp_ssdo_radius", "16", true, false, "SSDO radius.", 8, 64 )	
local pp_ssdo_bias 				= CreateClientConVar( "pp_ssdo_bias", "0.25", true, false, "SSDO bias.", 0.01, 0.5 )
local pp_ssdo_bias_offset		= CreateClientConVar( "pp_ssdo_bias_offset", "8", true, false, "SSDO offset.", 1, 200 )
local pp_ssdo_quality 			= CreateClientConVar( "pp_ssdo_quality", "4", true, false, "SSDO quality.", 1, 4 )
local pp_ssdo_debug 			= CreateClientConVar( "pp_ssdo_debug", "0", false, false, "SSDO quality.", 0, 1 )
local pp_ssdo_translucent 		= CreateClientConVar( "pp_ssdo_translucent", "0", true, false, "Translucent fix.", 0, 1 )
local pp_ssdo_mul 				= CreateClientConVar( "pp_ssdo_mul", "1", true, false, "SSDO indirect light mul.", 0, 10 )
local pp_ssdo_format 			= CreateClientConVar( "pp_ssdo_format", "2", true, false, "SSDO image format. 0: IMAGE_FORMAT_BGRA4444; 1: IMAGE_FORMAT_RGBA8888; 2: IMAGE_FORMAT_RGBA16161616F.", 0, 2 )

local function InitSSDO()
	local screentexture = render.GetScreenEffectTexture()

	local mul = 0.5 
	local w,h = ScrW() * mul, ScrH() * mul

	local formats = {
		[0] = IMAGE_FORMAT_BGRA4444;
		[1] = IMAGE_FORMAT_RGBA8888;
		[2] = IMAGE_FORMAT_RGBA16161616F;
	}

	local image_format = formats[pp_ssdo_format:GetInt()]
	
	local ssdo_rt = GetRenderTargetEx("_rt_SSDO", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    0,
	    image_format
	)	
	
	local ssdo_rt2 = GetRenderTargetEx("_rt_SSDO_filter", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    0,
	    image_format
	)	
	
	local rt_half_depth = GetRenderTargetEx("_rt_HalfDepth", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    --bit.bor(4,8,256,512,8388608),
	    --bit.bor(1,4,8,256,512,32768,8388608),
	    0,
	    IMAGE_FORMAT_R32F
	    --IMAGE_FORMAT_RGBA8888 -- нужно сделать выбираемым
	    -- 16
	    --linux and IMAGE_FORMAT_RGBA8888 or IMAGE_FORMAT_IA88
	    -- BRANCH == "x86-64" and IMAGE_FORMAT_R16F or IMAGE_FORMAT_R32F
	)
	
	local half_fb_format = pp_ssdo_format:GetInt() == 0 and IMAGE_FORMAT_RGB565 or IMAGE_FORMAT_BGRX8888
	
	local rt_half_fb = GetRenderTargetEx("_rt_HalfFB", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    0,
	    half_fb_format
	)

	local upsample_mat = Material("pp/ssdo_upsample")

	local ssdo_mats = {
		Material("pp/ssdo_very_low");
		Material("pp/ssdo_low");
		Material("pp/ssdo_medium");
		Material("pp/ssdo_hight");
	}

	local ssdo_mat = ssdo_mats[1]

	local function getssdoMat(i)
		i = i or math.Clamp( math.Round( pp_ssdo_quality:GetInt() ), 1, #ssdo_mats )
		ssdo_mat = ssdo_mats[i] or ssdo_mats[1]
	end

	getssdoMat(i)

	local pp_ssdo_v = Material("pp/ssdo_blur_v")
	local pp_ssdo_h = Material("pp/ssdo_blur_h") 
	local ssdo_radius = 1

	local t_0001 = {0,   0,   0,   1}

	local function Renderssdo(viewSetup, viewProj, viewProjTr)
		viewSetup = viewSetup or render.GetViewSetup()
		if !shaderlib.CanDrawEffects(viewSetup) then return end
		viewProj = viewProj or shaderlib.GetViewProjMatrix(viewSetup)
		ssdo_mat:SetMatrix("$INVVIEWPROJMAT", viewProj )

		local eyepos = EyePos()

		pp_ssdo_v:SetFloat("$c3_x", eyepos.x)
		pp_ssdo_v:SetFloat("$c3_y", eyepos.y)
		pp_ssdo_v:SetFloat("$c3_z", eyepos.z)
		pp_ssdo_h:SetFloat("$c3_x", eyepos.x)
		pp_ssdo_h:SetFloat("$c3_y", eyepos.y)
		pp_ssdo_h:SetFloat("$c3_z", eyepos.z)

		ssdo_mat:SetFloat("$c3_y", MATERIAL_FOG_MODE )

		local F = -viewSetup.angles:Forward()
        local R =  viewSetup.angles:Right()
        local U = -viewSetup.angles:Up() 

        local mViewAng = Matrix({
            {R.x, R.y, R.z, 0},
            {U.x, U.y, U.z, 0},
            {F.x, F.y, F.z, 0},
            t_0001,
        })

		local mProj = shaderlib.GetProjMatrix(viewSetup)
        mProj:Mul(mViewAng)
        local invViewProj = mProj:GetInverse()

		pp_ssdo_h:SetMatrix("$INVVIEWPROJMAT", mProj)
		pp_ssdo_v:SetMatrix("$INVVIEWPROJMAT", mProj)

		upsample_mat:SetFloat("$c0_x", eyepos.x)
	   	upsample_mat:SetFloat("$c0_y", eyepos.y)
	   	upsample_mat:SetFloat("$c0_z", eyepos.z)

		cam.Start2D()
			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)

			render.CopyTexture(screentexture, rt_half_fb)

		    --[[render.PushRenderTarget(ssdo_rt)
		    	render.Clear(0,0,0,255)
		    render.PopRenderTarget()

		    render.PushRenderTarget(rt_half_depth)
		    	render.Clear(0,0,0,0)
		    render.PopRenderTarget()]]

		    render.SetRenderTargetEx(0, ssdo_rt)
		    render.SetRenderTargetEx(1, rt_half_depth)
				render.SetMaterial(ssdo_mat)
			    shaderlib.DrawScreenQuad() 
			render.SetRenderTargetEx(0)
		    render.SetRenderTargetEx(1)

			render.PushRenderTarget(ssdo_rt2)
				render.Clear(0,0,0,255)
				render.SetMaterial(pp_ssdo_h)
				render.DrawScreenQuad()
			render.PopRenderTarget()

			render.PushRenderTarget(ssdo_rt)
				render.Clear(0,0,0,255)
				render.SetMaterial(pp_ssdo_v)
				render.DrawScreenQuad()
			render.PopRenderTarget()

		   	render.SetMaterial(upsample_mat)
			render.DrawScreenQuad()
		cam.End2D()
	end

	local function getssdoHook(state)
		return "PostBumpDraw"--"PreDrawEffects"--(state or pp_ssdo_translucent:GetBool()) and "PostDrawReconstructionPreEffects" or "PreDrawEffects"
	end
	
	HOOK_ssdo = getssdoHook()
	
	local function CalcssdoRadius(radius, distance)
		radius = radius or pp_ssdo_radius:GetFloat()
		distance = distance or pp_ssdo_bias_offset:GetFloat()

		local g_rrd = (radius * radius * distance)
		ssdo_radius = radius
		
		ssdo_mat:SetFloat("$c1_x", radius)
		ssdo_mat:SetFloat("$c3_x", 1/g_rrd)
	end
	
	local function InitssdoParams()
		if !ssdo_mat then getssdoMat(i) end

		ssdo_mat:SetFloat("$c0_x", pp_ssdo_bias:GetFloat())
		ssdo_mat:SetFloat("$c2_x", pp_ssdo_contrast:GetFloat())
		ssdo_mat:SetFloat("$c3_z", pp_ssdo_mul:GetFloat())
		upsample_mat:SetFloat("$c3_x", pp_ssdo_mul:GetFloat())

		CalcssdoRadius(pp_ssdo_radius:GetFloat())
	end

	local function removeHooks()
		hook.Remove("PostBumpDraw",shaderName)
	end

	local function EnableDebugMode()
		upsample_mat:SetTexture("$texture3", "grey")
	end

	local function Enablessdo()
		if !GSHADER then
			LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of ssdo https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
			return
		end

		if GetConVar("mat_aaquality"):GetInt() > 0 or GetConVar("mat_antialias"):GetInt() > 1  then
			LocalPlayer():ChatPrint( "Выключи сглаживание в настройках графики. можешь включить SMAA или FXAA в настройках з сити" )
			--return
		end

		if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", 1) end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", 1) end
		if !GetConVar("r_shaderlib_bumps"):GetBool() then  RunConsoleCommand("r_shaderlib_bumps", 1) end
		
		removeHooks()

		InitssdoParams()

		hook.Add(HOOK_ssdo, shaderName, function(viewSetup, viewProj) 
			Renderssdo()
		end)

		if pp_ssdo_debug:GetBool() then
			EnableDebugMode()
		end
	end

	cvars.AddChangeCallback( pp_ssdo:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			Enablessdo()
		else
			removeHooks()
		end
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_quality:GetName(), function( convar_name, _, identifier )
		getssdoMat( math.Clamp( math.Round( tonumber(identifier ) ) , 1, #ssdo_mats) )
		InitssdoParams()
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_bias:GetName(), function( convar_name, _, identifier )
		ssdo_mat:SetFloat("$c0_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_bias_offset:GetName(), function( convar_name, _, identifier )
		CalcssdoRadius(nil, tonumber(identifier))
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_contrast:GetName(), function( convar_name, _, identifier )
		ssdo_mat:SetFloat("$c2_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_mul:GetName(), function( convar_name, _, identifier )
		ssdo_mat:SetFloat("$c3_z", identifier)
		upsample_mat:SetFloat("$c3_x", identifier)
	end, shaderName )


	cvars.AddChangeCallback( pp_ssdo_radius:GetName(), function( convar_name, _, identifier )
		local ssdo_radius = tonumber(identifier)
		CalcssdoRadius(ssdo_radius)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_debug:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled and pp_ssdo:GetBool() then
			EnableDebugMode()
		else
			upsample_mat:SetTexture("$texture3", "_rt_FullFrameFB")
		end
		
	end, shaderName )

	cvars.AddChangeCallback( pp_ssdo_translucent:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		HOOK_ssdo = getssdoHook(enabled)
		if !pp_ssdo:GetBool() then return end
		Enablessdo()
	end, shaderName )
	
	timer.Simple(0.1, function()
		InitssdoParams()
		if pp_ssdo:GetBool() then Enablessdo() end
	end)

	SSDO_INITED = true
end

if SSDO_INITED then
	InitSSDO()
end

hook.Add("PostCEFCodecFixStatus", shaderName, InitSSDO)
