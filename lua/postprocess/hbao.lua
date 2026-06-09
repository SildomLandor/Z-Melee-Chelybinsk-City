// HBAO from Estranged Act 1 of Alan Edwardes by AniCator and Drew Watts

local shaderName = "HBAO"
local pp_hbao = CreateClientConVar( "pp_hbao", "0", true, false, "Enable/Disable Horizon-Based Ambient Occlusion.", 0, 1 )
local pp_hbao_quality = CreateClientConVar( "pp_hbao_quality", "3", true, false, "HBAO quality.", 1, 3 )
local pp_hbao_upsample = CreateClientConVar( "pp_hbao_upsample", "1", true, false, "HBAO upsampling", 0, 1 )
local pp_hbao_radius = CreateClientConVar( "pp_hbao_radius", "32", true, false, "HBAO debug mode.", 8, 128 )
local pp_hbao_anglebias = CreateClientConVar( "pp_hbao_anglebias", "5", true, false, "HBAO debug mode.", 0, 128 )
local pp_hbao_intensity = CreateClientConVar( "pp_hbao_intensity", "1.5", true, false, "HBAO debug mode.", 0, 10 )
local pp_hbao_translucent = CreateClientConVar( "pp_hbao_translucent", "1", true, false, "HBAO post draw opaque hook.", 0, 1 )
local pp_hbao_debug = CreateClientConVar( "pp_hbao_debug", "0", false, false, "HBAO debug mode.", 0, 1 )

local hbao_mats = {
	Material("pp/hbao_low");
	Material("pp/hbao_medium");
	Material("pp/hbao_high")
}

local hbao_half_mats = {
	Material("pp/hbao_half_low");
	Material("pp/hbao_half_medium");
	Material("pp/hbao_half_high")
}

local function SetupHBAO()
	local hbao_blurx_mat = Material("pp/hbao_blurx")
	local hbao_blury_mat = Material("pp/hbao_blury")
	local hbao_upsampling_mat = Material("pp/hbao_upsampling")
	local hbao_blury_combine_mat = Material("pp/hbao_blury_combine")

	local upsampling = pp_hbao_upsample:GetBool()
	local quality = pp_hbao_quality:GetInt()
	local hbao_mat = upsampling and hbao_half_mats[quality] or hbao_mats[quality]

	local scrw,scrh = ScrW(),ScrH()
	local rt_size = upsampling and 0.5 or 1
	local rt_w, rt_h = scrw * rt_size, scrh * rt_size

	local size_mode = upsampling and RT_SIZE_LITERAL or RT_SIZE_FULL_FRAME_BUFFER
	local flags = upsampling and bit.bor(1,4,8,256,512) or bit.bor(16,4,8,256,512)

	local rt_hbao = GetRenderTargetEx("_rt_HBAO", rt_w, rt_h, rt_size,
		MATERIAL_RT_DEPTH_NONE, flags, 0, IMAGE_FORMAT_RGBA8888)

	local rt_hbao_filter = GetRenderTargetEx("_rt_HBAO_filter", rt_w, rt_h, rt_size,
		MATERIAL_RT_DEPTH_NONE, flags, 0, IMAGE_FORMAT_RGBA8888)

	local screentexture = render.GetScreenEffectTexture()

	local function getHBAOHook(state)
		return (state or pp_hbao_translucent:GetBool()) and "PostDrawReconstructionEffects" or "PostBumpDraw"
	end

	local hbao_hook = getHBAOHook()

	local function setFloat(k,v)
		hbao_blurx_mat:SetFloat(k,v)
		hbao_blury_mat:SetFloat(k,v)
		hbao_blury_combine_mat:SetFloat(k,v)
	end

	local function setMatrix(k,v)
		hbao_blurx_mat:SetMatrix(k,v)
		hbao_blury_mat:SetMatrix(k,v)
		hbao_blury_combine_mat:SetMatrix(k,v)
	end

	local dirs = {4;6;8}

	local function InitHBAO()
		local quality = pp_hbao_quality:GetInt()
	 	hbao_mat = upsampling and hbao_half_mats[quality] or hbao_mats[quality]
		local ANGLEBIAS = pp_hbao_anglebias:GetFloat()
		local g_AngleBias = math.rad(ANGLEBIAS);
		g_AngleBias = math.tan(g_AngleBias)
		local OCCLUSIONRADIUS = pp_hbao_radius:GetFloat()
		local OCCLUSIONINTENSITY = pp_hbao_intensity:GetFloat()
		local g_R = OCCLUSIONRADIUS
		local g_R2 = (g_R * g_R);
		local g_NegInvR2 = (-1.0 / g_R2);

		local NUM_DIRECTIONS = dirs[quality]

		local texelSize_x = 1/rt_w
		local texelSize_y = 1/rt_h

		hbao_mat:SetFloat("$c1_x", g_NegInvR2)
		hbao_mat:SetFloat("$c1_y", g_AngleBias)
		hbao_mat:SetFloat("$c1_z", OCCLUSIONINTENSITY / NUM_DIRECTIONS)
		hbao_mat:SetFloat("$c1_w", ( g_R * 0.5) )
		hbao_mat:SetFloat("$c2_x", g_R2)
		hbao_mat:SetFloat("$c2_y", texelSize_x * rt_h)
		local g_MaxRadiusPixels = 0.1 * math.min(rt_w, rt_h)
		hbao_mat:SetFloat("$c2_z", g_MaxRadiusPixels)
		hbao_mat:SetFloat("$c0_x", texelSize_x)
		hbao_mat:SetFloat("$c0_y", texelSize_y)
		hbao_mat:SetFloat("$c0_z", rt_w)
		hbao_mat:SetFloat("$c0_w", rt_h)

		hook.Run("ActivateGShaderBumps")
		if !GetConVar("r_shaderlib"):GetBool() then RunConsoleCommand("r_shaderlib", 1) end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then RunConsoleCommand("r_shaderlib_depthbuffer", 1) end
		if upsampling then
			if !GetConVar("r_shaderlib_half_depth"):GetBool() then RunConsoleCommand("r_shaderlib_half_depth", 1) end
		end

		setFloat("$c1_x",upsampling and 4 or 2.5)
		setFloat("$c2_x",upsampling and 1 or 15.0)
		setFloat("$c2_y",0)
	end

	local function draw_final_pass()
		local debug_mode = pp_hbao_debug:GetBool()

		if !debug_mode then
			render.OverrideBlend( true, BLEND_DST_COLOR, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD )
		end

		render.SetMaterial(upsampling and hbao_upsampling_mat or hbao_blury_combine_mat)
		render.DrawScreenQuad()

		render.OverrideBlend( false )
	end

	local function EnableDebug()
		hook.Add("HUDPaint", shaderName, function()
			draw_final_pass()
		end)
	end

	local function EnableHBAO()
		if pp_hbao_debug:GetBool() then EnableDebug() end
		local t_0001 = {0,   0,   0,   1}

		hook.Add(hbao_hook, shaderName, function()
			if !shaderlib.CanDrawEffects() then return end
			local fallback = hook.Run("ShouldDrawAmbientOcclusion") == false
			if fallback then return end
			
			local eyepos = EyePos()
			setFloat("$c3_x",eyepos.x)
			setFloat("$c3_y",eyepos.y)
			setFloat("$c3_z",eyepos.z)

			local viewSetup = render.GetViewSetup()
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

			setMatrix("$invviewprojmat",invViewProj)

			hbao_mat:SetFloat("$c2_w", MATERIAL_FOG_MODE)

			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)
			
			render.PushRenderTarget(rt_hbao)
			render.Clear(255,255,255,255)
			render.SetMaterial(hbao_mat)
			render.DrawScreenQuad()
			render.PopRenderTarget()

			

			render.PushRenderTarget(rt_hbao_filter)
			render.Clear(255,255,255,255)
			render.SetMaterial(hbao_blurx_mat)
			render.DrawScreenQuad()
			render.PopRenderTarget()

			if upsampling then
				render.PushRenderTarget(rt_hbao)
				render.Clear(255,255,255,255)
				render.SetMaterial(hbao_blury_mat)
				render.DrawScreenQuad()
				render.PopRenderTarget()
			end

			draw_final_pass()
		end)
	end

	cvars.AddChangeCallback( pp_hbao:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"
		if state then
			EnableHBAO()
		else
			hook.Remove("PreDrawEffects", shaderName)
			hook.Remove("PostDrawReconstructionEffects", shaderName)
			hook.Remove("PostBumpDraw", shaderName)
			hook.Remove("HUDPaint", shaderName)
		end
	end, shaderName )

	cvars.AddChangeCallback( pp_hbao_debug:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"
		if state then
			EnableDebug()
		else
			hook.Remove("HUDPaint", shaderName)
		end
	end, shaderName )

	cvars.AddChangeCallback( pp_hbao_translucent:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"
		hook.Remove("PreDrawEffects", shaderName)
		hook.Remove("PostDrawReconstructionEffects", shaderName)
		hook.Remove("PostBumpDraw", shaderName)
		hbao_hook = getHBAOHook(enabled)
		if !pp_hbao:GetBool() then return end
		EnableHBAO()
	end, shaderName )

	cvars.AddChangeCallback( pp_hbao_radius:GetName(), InitHBAO, shaderName )
	cvars.AddChangeCallback( pp_hbao_anglebias:GetName(), InitHBAO, shaderName )
	cvars.AddChangeCallback( pp_hbao_intensity:GetName(), InitHBAO, shaderName )
	cvars.AddChangeCallback( pp_hbao_quality:GetName(), InitHBAO, shaderName )

	InitHBAO()
	if pp_hbao:GetBool() then EnableHBAO() end

	INITED_HBAO = true
end

if INITED_HBAO then
	SetupHBAO()
end

hook.Add("InitPostShaderlib", shaderName, function()
	timer.Simple(1, function()
		SetupHBAO()
	end)
end)





