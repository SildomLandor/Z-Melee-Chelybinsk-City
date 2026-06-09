
// LVutner&Akabenko

local shaderName = "SSAOPlus"

local pp_ssao 						= CreateClientConVar( "pp_ssao_plus", "0", true, false, "Enable/Disable screen space ambient occlusion.", 0, 1 )
local pp_ssao_plus_size				= CreateClientConVar( "pp_ssao_plus_size", "1", true, false, "SSAO rt size mul.", 0.5, 1 )
local pp_ssao_plus_contrast 		= CreateClientConVar( "pp_ssao_plus_contrast", "4", true, false, "SSAO contrast.", 1, 10 )
local pp_ssao_plus_radius 			= CreateClientConVar( "pp_ssao_plus_radius", "16", true, false, "SSAO radius.", 8, 64 )	
local pp_ssao_plus_bias 			= CreateClientConVar( "pp_ssao_plus_bias", "0.15", true, false, "SSAO bias.", 0, 0.5 )
local pp_ssao_plus_quality 			= CreateClientConVar( "pp_ssao_plus_quality", "4", true, false, "SSAO quality.", 1, 4 )
local pp_ssao_plus_debug 			= CreateClientConVar( "pp_ssao_plus_debug", "0", false, false, "SSAO quality.", 0, 1 )
local pp_ssao_plus_downsample		= CreateClientConVar( "pp_ssao_plus_downsample", "0", true, false, "SSAO downsample.", 0, 1 )
local pp_ssao_plus_translucent 		= CreateClientConVar( "pp_ssao_plus_translucent", "1", true, false, "Translucent fix.", 0, 1 )
local pp_ssao_plus_weapon 			= CreateClientConVar( "pp_ssao_plus_weapon", "1", true, false, "Weapon Translucent fix.", 0, 1 )

local function InitSSAO()
	local screentexture = render.GetScreenEffectTexture()

	local upsampling = pp_ssao_plus_downsample:GetBool()
	local mul = upsampling and 0.5 or 1
	local w,h = ScrW() * mul, ScrH() * mul

	local ssao_rt = GetRenderTargetEx("_rt_SSAO", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    0,
	    IMAGE_FORMAT_RGBA8888
	)
	
	local ssao_rt2 = GetRenderTargetEx("_rt_SSAO_filter", w,h,
	    RT_SIZE_LITERAL,
	    MATERIAL_RT_DEPTH_NONE,
	    bit.bor(1,4,8,256,512),
	    0,
	    IMAGE_FORMAT_RGBA8888
	)

	local upsample_mat = Material("pp/ssao_upsample")

	local ssao_mats = {
		Material("pp/pp_ssao_plus_very_low");
		Material("pp/pp_ssao_plus_low");
		Material("pp/pp_ssao_plus_medium");
		Material("pp/pp_ssao_plus_high");
	}

	local ssao_plus_mat = ssao_mats[1]

	local function getSSAOMat(i)
		i = i or math.Clamp( math.Round( pp_ssao_plus_quality:GetInt() ), 1, #ssao_mats )
		ssao_plus_mat = ssao_mats[i] or ssao_mats[1]
	end

	getSSAOMat(i)

	local pp_ssao_v = upsampling and Material("pp/ssao_blury_up") or Material("pp/ssao_blury")
	local pp_ssao_h = Material("pp/ssao_blurx") 
	local ssao_radius = 1

	local function RenderSecondPassSSAO()
	   	render.OverrideBlend( true, BLEND_DST_COLOR, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD )
		render.SetMaterial(upsampling and upsample_mat or pp_ssao_v)
		render.DrawScreenQuad()
		render.OverrideBlend( false )
	end

	local t_0001 = {0,   0,   0,   1}
	
	local function RenderSSAO(viewSetup)
		local fallback = hook.Run("ShouldDrawAmbientOcclusion") == false
		if fallback then return end

		viewSetup = viewSetup or render.GetViewSetup()
		if !shaderlib.CanDrawEffects(viewSetup) then return end

		local view = shaderlib.GetViewSpaceMatrix(viewSetup.origin, viewSetup.angles)
		--view = cam.GetViewMatrix()

		ssao_plus_mat:SetMatrix("$INVVIEWPROJMAT", view )

		local eyepos = EyePos()

		local inv_proj_m11 = math.tan(math.rad(viewSetup.fov) * 0.5)
		local proj_m11     = 1 / inv_proj_m11
		local inv_proj_m00 = inv_proj_m11 * viewSetup.aspect
		local proj_scale   = ScrH() * proj_m11 * 0.5

		ssao_plus_mat:SetFloat("$c3_x", proj_scale)
		ssao_plus_mat:SetFloat("$c3_z", inv_proj_m11)
		ssao_plus_mat:SetFloat("$c3_w", inv_proj_m00)

		ssao_plus_mat:SetFloat("$c2_w", eyepos.z)

		ssao_plus_mat:SetFloat("$c2_y", eyepos.x)
		ssao_plus_mat:SetFloat("$c2_z", eyepos.y)
		ssao_plus_mat:SetFloat("$c2_w", eyepos.z)

		pp_ssao_v:SetFloat("$c3_x", eyepos.x)
		pp_ssao_v:SetFloat("$c3_y", eyepos.y)
		pp_ssao_v:SetFloat("$c3_z", eyepos.z)
		pp_ssao_h:SetFloat("$c3_x", eyepos.x)
		pp_ssao_h:SetFloat("$c3_y", eyepos.y)
		pp_ssao_h:SetFloat("$c3_z", eyepos.z)

		ssao_plus_mat:SetFloat("$c3_y", MATERIAL_FOG_MODE )

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

		pp_ssao_h:SetMatrix("$INVVIEWPROJMAT", invViewProj)
		pp_ssao_v:SetMatrix("$INVVIEWPROJMAT", invViewProj)

		cam.Start2D()
			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)

		    render.PushRenderTarget(ssao_rt)
		    	render.Clear(255,255,255,255)
				render.SetMaterial(ssao_plus_mat)
			    render.DrawScreenQuad()
			render.PopRenderTarget()
			
			render.PushRenderTarget(ssao_rt2)
				render.Clear(0,0,0,255)
				render.SetMaterial(pp_ssao_h)
				render.DrawScreenQuad()
		   	render.PopRenderTarget()
		   	
		   	if upsampling then
			   	render.PushRenderTarget(ssao_rt)
					render.SetMaterial(pp_ssao_v)
				    render.DrawScreenQuad()
				render.PopRenderTarget()
			end

		   	RenderSecondPassSSAO()

		cam.End2D()
	end

	local function getSSAOHook(state)
		return (state or pp_ssao_plus_translucent:GetBool()) and "PostDrawReconstructionPreEffects" or "PreDrawEffects"
	end
	
	HOOK_SSAO = getSSAOHook()
	
	local function CalcSSAORadius(radius)
		radius = radius or pp_ssao_plus_radius:GetFloat()
		ssao_radius = radius
		
		ssao_plus_mat:SetFloat("$c1_x", radius)
	end
	
	local function InitSSAOParams()
		if !ssao_plus_mat then getSSAOMat(i) end

		ssao_plus_mat:SetFloat("$c0_x", pp_ssao_plus_bias:GetFloat())
		ssao_plus_mat:SetFloat("$c2_x", pp_ssao_plus_contrast:GetFloat())

		CalcSSAORadius(pp_ssao_plus_radius:GetFloat())

		local c1x = upsampling and 4 or 2.5
		local c2x = upsampling and 1 or 15.0

		pp_ssao_v:SetFloat("$c1_x",c1x)
		pp_ssao_v:SetFloat("$c2_x",c2x)

		pp_ssao_h:SetFloat("$c1_x",c1x)
		pp_ssao_h:SetFloat("$c2_x",c2x)
	end

	local function removeHooks()
		hook.Remove("PostDrawReconstructionPreEffects",shaderName)
		hook.Remove("PostDrawViewModel",shaderName)
		hook.Remove("PreDrawEffects",shaderName)
		hook.Remove("PostDrawEffects", shaderName)
	end
	
	local function EnableDebugMode()
		hook.Add("PostDrawEffects", shaderName, function()
			render.Clear(255,255,255,255)
		   	RenderSecondPassSSAO()
		end)
	end

	local function EnableSSAO()
		if !GSHADER then
			LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of SSAO https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
			return
		end

		if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", 1) end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", 1) end

		removeHooks()

		InitSSAOParams()

		hook.Add(HOOK_SSAO, shaderName, function(viewSetup, viewProj) 
			RenderSSAO()
		end)

		if pp_ssao_plus_debug:GetBool() then
			EnableDebugMode()
		end
	end

	cvars.AddChangeCallback( pp_ssao:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			EnableSSAO()
		else
			removeHooks()
		end
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_quality:GetName(), function( convar_name, _, identifier )
		getSSAOMat( math.Clamp( math.Round( tonumber(identifier ) ) , 1, #ssao_mats) )
		InitSSAOParams()
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_bias:GetName(), function( convar_name, _, identifier )
		ssao_plus_mat:SetFloat("$c0_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_contrast:GetName(), function( convar_name, _, identifier )
		ssao_plus_mat:SetFloat("$c2_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_radius:GetName(), function( convar_name, _, identifier )
		local ssao_radius = tonumber(identifier)
		CalcSSAORadius(ssao_radius)
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_debug:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled and pp_ssao:GetBool() then
			EnableDebugMode()
		else
			hook.Remove("PostDrawEffects", shaderName)
		end
	
	end, shaderName )

	cvars.AddChangeCallback( pp_ssao_plus_translucent:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"
		
		HOOK_SSAO = getSSAOHook(enabled)
		if !pp_ssao:GetBool() then return end
		EnableSSAO()
	end, shaderName )
	
	timer.Simple(0.1, function()
		InitSSAOParams()
		if pp_ssao:GetBool() then EnableSSAO() end
	end)

	SSAO_INITED = true
end

if SSAO_INITED then
	InitSSAO()
end

hook.Add("PostCEFCodecFixStatus", shaderName, InitSSAO)
