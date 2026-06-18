
local shaderName = "SSR"

local r_ssr						= CreateClientConVar( "r_ssr", "0", true, false, "Screen Space Reflections.", 0, 1 )
local r_ssr_stencil				= CreateClientConVar( "r_ssr_stencil", "1", true, false, "Screen Space Reflections by Stencil.", 0, 1 )
local r_ssr_intensity			= CreateClientConVar( "r_ssr_intensity", "1", true, false, "SSR Intensity.", 0.25, 20 )
local r_ssr_stencil_intensity	= CreateClientConVar( "r_ssr_stencil_intensity", "1", true, false, "SSR Intensity.", 0.25, 20 )
--local r_ssr_luma				= CreateClientConVar( "r_ssr_luma", "1", true, false, "SSR Luma power.", 0, 20 )
--local r_ssr_distance			= CreateClientConVar( "r_ssr_distance", "5000", true, false, "SSR Luma power.", 192, 20000 )
local r_ssr_length 				= CreateClientConVar( "r_ssr_length", "69.94", true, false, "SSR Ray start length.", 1, 100 )
local r_ssr_quality				= CreateClientConVar( "r_ssr_quality", "3", true, false, "SSR quality.", 1, 3 )
local r_ssr_debug				= CreateClientConVar( "r_ssr_debug", "0", false, false, "SSR debug mode.", 0, 1 )
local r_ssr_nomaks				= CreateClientConVar( "r_ssr_nomaks", "0", true, false, "Screen Space Reflections disabled mask.", 0, 1 )

local r_ssr_contrast 			= CreateClientConVar( "r_ssr_contrast", "0", true, false, "Screen Space Reflections contrast.", 0, 1 )
local r_ssr_saturation_r 		= CreateClientConVar( "r_ssr_saturation_r", "255", true, false, "Screen Space Reflections saturation r.", 0, 255 )
local r_ssr_saturation_g 		= CreateClientConVar( "r_ssr_saturation_g", "255", true, false, "Screen Space Reflections saturation g.", 0, 255 )
local r_ssr_saturation_b 		= CreateClientConVar( "r_ssr_saturation_b", "255", true, false, "Screen Space Reflections saturation b.", 0, 255 )
local r_ssr_tint_r 				= CreateClientConVar( "r_ssr_tint_r", "128", true, false, "Screen Space Reflections tint r.", 0, 255 )
local r_ssr_tint_g 				= CreateClientConVar( "r_ssr_tint_g", "128", true, false, "Screen Space Reflections tint g.", 0, 255 )
local r_ssr_tint_b 				= CreateClientConVar( "r_ssr_tint_b", "128", true, false, "Screen Space Reflections tint b.", 0, 255 )
local r_ssr_texture				= CreateClientConVar( "r_ssr_texture", "2", true, false, "Screen Space Reflections framebuffer texture", 1, 2 )
local r_ssr_frensel			= CreateClientConVar( "r_ssr_frensel", "2", true, false, "Screen Space Reflections frensel", 1, 20 )
local r_ssr_error			= CreateClientConVar( "r_ssr_error", "10", true, false, "Screen Space Reflections frensel", 0, 500 )
local r_ssr_auto			= CreateClientConVar( "r_ssr_auto", "1", true, false, "Screen Space Reflections auto mode", 0, 1 )
local r_ssr_treshold			= CreateClientConVar( "r_ssr_treshold", "0.1", true, false, "Screen Space Reflections reflection treshold", 0, 1 )

local lenght_t = {
	60,
	50,
	1
}

local ssr_textures = {
	render.GetPowerOfTwoTexture(),
	render.GetScreenEffectTexture( 0 ),
}

local screentexture = render.GetScreenEffectTexture()
local mat_ssr = Material("pp/pp_ssr_low")
local texture_ssr = ssr_textures[math.Clamp(r_ssr_texture:GetInt(),1,2)]
local mat_ssr_stencil = Material("pp/pp_ssr_stencil_low")
local debug_mode = false

local function ssr_setfloat(str, value)
	mat_ssr:SetFloat(str, value)
	mat_ssr_stencil:SetFloat(str, value)
end

local function ssr_setmatrix(str, matrix)
	mat_ssr:SetMatrix(str, matrix)
	mat_ssr_stencil:SetMatrix(str, matrix)
end

local function InitSSR()
	
	
	
	local ssr_mats = {
		Material("pp/pp_ssr_low");
		Material("pp/pp_ssr_medium");
		Material("pp/pp_ssr_high");
	}

	local ssr_stencil_mats = {
		Material("pp/pp_ssr_stencil_low");
		Material("pp/pp_ssr_stencil_medium");
		Material("pp/pp_ssr_stencil_high");
	}

	local hook_name = "PostBumpDraw" --"PostDrawReconstructionEffects" PostDrawTranslucentRenderables

	STENCIL_SSR = 0x30

	local white_classes = {}
	for name_hook, func in pairs(hook.GetTable()["ConfigClassesSSR"] or {}) do
		table.Merge(white_classes, func())
	end

	/*
	local white_models = {}
	for name_hook, func in pairs(hook.GetTable()["ConfigModelsSSR"] or {}) do
		local result = func()
		for k,v in pairs(result) do
			result[string.lower(k)] = v
		end
		table.Merge(white_models, result)
	end
	*/

	SSR_ENT_NUM = SSR_ENT_NUM or 0
	SSR_ENTS_INDEX = SSR_ENTS_INDEX or {}

	hook.Add("PostCleanupMap", shaderName, function()
		SSR_ENT_NUM = 0
		SSR_ENTS_INDEX = {}
	end)
	
	hook.Add( "OnEntityCreated", shaderName, function( ent )
		local ply = LocalPlayer()
		if !IsValid(ply) then return end
		local class = ent:GetClass()
		if class == "gmod_hands" then return end
		if ent:IsPlayer() then return end
		local model = ent:GetModel()

		if !white_classes[class] then return end --  and !white_models[model]
		
		SSR_ENT_NUM = SSR_ENT_NUM + 1
		SSR_ENTS_INDEX[ent:EntIndex()] = true

		timer.Simple(0, function()

			ent.RenderOverride = function(self, flags)
				if halo.RenderedEntity() == self then self:DrawModel(flags) return end -- Rubat's fix

				local rt = render.GetRenderTarget()
				if rt and rt:GetName() == "_rt_waterreflection" then self:DrawModel(flags) return end

				render.SetStencilEnable( true )

			    render.SetStencilWriteMask(0xFF)
			    render.SetStencilTestMask(0xFF)
			    render.SetStencilReferenceValue(STENCIL_SSR)

			    render.SetStencilCompareFunction(STENCIL_ALWAYS)
			    render.SetStencilPassOperation(STENCIL_REPLACE)
			    render.SetStencilFailOperation(STENCIL_KEEP)
			    render.SetStencilZFailOperation(STENCIL_KEEP)

				self:DrawModel(flags)

				render.SetStencilEnable( false )
			end
		end)
	end )

	hook.Add("EntityRemoved", shaderName, function(ent)
		if !ent:IsValid() then return end

		local index = ent:EntIndex()

		if SSR_ENTS_INDEX[index] then
			SSR_ENT_NUM = math.max(0, SSR_ENT_NUM - 1)
		end
	end)	

	hook.Add("ShutDown", shaderName, function()
		hook.Remove("EntityRemoved", shaderName) -- фикс скриптовой ошибки рендера игрока при выходе с сервера
	end)

	local function EnableStencilSSR()
		hook.Add("DrawStencilSSR", shaderName, function()
			render.SetStencilEnable(true)

			render.SetStencilPassOperation(STENCIL_KEEP)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			render.SetStencilCompareFunction(STENCIL_EQUAL)

			render.SetStencilReferenceValue(STENCIL_SSR)

			render.SetMaterial(mat_ssr_stencil)
			render.DrawScreenQuad()

			render.SetStencilEnable(false)
		end)
	end

	local function EnableDebugMode()
		--[[hook.Add("HUDPaint", shaderName, function()
			render.DrawTextureToScreenRect(rt_specular_bump, 0, 0, ScrW(), ScrH())
		end)]]
	end

	local function EnableSSR()
		if !GSHADER then
			LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of ssr https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
			return
		end

		if GetConVar("mat_aaquality"):GetInt() > 0 or GetConVar("mat_antialias"):GetInt() > 1  then
			LocalPlayer():ChatPrint( "Выключи сглаживание в настройках графики. можешь включить SMAA или FXAA в настройках з сити" )
			--return
		end

		if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", "1") end
		if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", "1") end
		if !GetConVar("r_shaderlib_bumps"):GetBool() then  RunConsoleCommand("r_shaderlib_bumps", "1") end

		if r_ssr_stencil:GetBool() then EnableStencilSSR() end
		if r_ssr_debug:GetBool() then EnableDebugMode() end
		
		hook.Add(hook_name, shaderName, function()
			local viewSetup = render.GetViewSetup()
			if !shaderlib.CanDrawEffects(viewSetup) then return end

			hook.Run("PreDrawSSR", viewSetup)
			
			local pos = viewSetup.origin

			local ViewProj = shaderlib.GetViewProjMatrix(viewSetup)
			ssr_setmatrix("$viewprojmat", ViewProj)

			ssr_setfloat("$c0_x", pos.x)
			ssr_setfloat("$c0_y", pos.y)
			ssr_setfloat("$c0_z", pos.z)

			ssr_setfloat("$c1_w", MATERIAL_FOG_MODE)

			render.UpdateScreenEffectTexture()
			render.CopyRenderTargetToTexture(screentexture)
			
			if !debug_mode then
				render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
			end

			local nomask = r_ssr_nomaks:GetBool()
			render.SetMaterial(nomask and mat_ssr_stencil or mat_ssr)
			render.DrawScreenQuad()
			
			if SSR_ENT_NUM > 0 and !nomask then
				hook.Run("DrawStencilSSR")
			end
	
			render.OverrideBlend(false)
		end)
	end

	cvars.AddChangeCallback( r_ssr:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			EnableSSR()
		else
			hook.Remove("RenderScreenspaceEffects", shaderName)
			hook.Remove("PostBumpDraw", shaderName)
			hook.Remove("HUDPaint", shaderName)
			hook.Remove("PreDrawSSR", shaderName)
			hook.Remove("DrawStencilSSR", shaderName)
		end
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_stencil:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"

		if enabled then
			EnableStencilSSR()
		else
			hook.Remove("DrawStencilSSR", shaderName)
		end
	end, shaderName )
	
	cvars.AddChangeCallback( r_ssr_debug:GetName(), function( convar_name, _, identifier )
		local enabled = identifier == "1"
		debug_mode = enabled

		if enabled then
			EnableDebugMode()
		else
			hook.Remove("HUDPaint", shaderName)
		end
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_intensity:GetName(), function( convar_name, _, identifier )
		mat_ssr:SetFloat("$c1_y", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_stencil_intensity:GetName(), function( convar_name, _, identifier )
		mat_ssr_stencil:SetFloat("$c1_y", identifier)
	end, shaderName )

	--[[cvars.AddChangeCallback( r_ssr_luma:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c1_z", identifier)
	end, shaderName )]]

	cvars.AddChangeCallback( r_ssr_contrast:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c3_w", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_tint_r:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c3_x", tonumber(identifier)/255 )
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_tint_g:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c3_y", tonumber(identifier)/255)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_tint_b:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c3_z", tonumber(identifier)/255)
	end, shaderName )

	local mData = Matrix()

	cvars.AddChangeCallback( r_ssr_saturation_r:GetName(), function( convar_name, _, identifier )
		mData:SetField(1, 1, tonumber(identifier)/255)
		ssr_setmatrix("$INVVIEWPROJMAT", mData)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_saturation_g:GetName(), function( convar_name, _, identifier )
		mData:SetField(2, 1, tonumber(identifier)/255)
		ssr_setmatrix("$INVVIEWPROJMAT", mData)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_saturation_b:GetName(), function( convar_name, _, identifier )
		mData:SetField(3, 1, tonumber(identifier)/255)
		ssr_setmatrix("$INVVIEWPROJMAT", mData)
	end, shaderName )

	--[[cvars.AddChangeCallback( r_ssr_distance:GetName(), function( convar_name, _, identifier )
		local dist = tonumber( identifier )
		ssr_setfloat("$c2_z", dist)
		ssr_setfloat("$c2_w", dist*1.2)
	end, shaderName )]]

	cvars.AddChangeCallback( r_ssr_length:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c2_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_frensel:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c1_x", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_error:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c2_y", identifier)
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_treshold:GetName(), function( convar_name, _, identifier )
		ssr_setfloat("$c2_z", identifier)
	end, shaderName )

	local function InitParams()
		mat_ssr:SetFloat("$c1_y", r_ssr_intensity:GetFloat())
		mat_ssr_stencil:SetFloat("$c1_y", r_ssr_stencil_intensity:GetFloat())

		--ssr_setfloat("$c1_z", r_ssr_luma:GetFloat())
		--[[local dist = r_ssr_distance:GetFloat()
		ssr_setfloat("$c2_z", dist)
		ssr_setfloat("$c2_w", dist*1.2)]]
		ssr_setfloat("$c2_x", r_ssr_length:GetFloat())
		ssr_setfloat("$c3_w", r_ssr_contrast:GetFloat())
		ssr_setfloat("$c3_x", r_ssr_tint_r:GetFloat()/255)
		ssr_setfloat("$c3_y", r_ssr_tint_g:GetFloat()/255)
		ssr_setfloat("$c3_z", r_ssr_tint_b:GetFloat()/255)
		ssr_setfloat("$c1_x", r_ssr_frensel:GetFloat())
		ssr_setfloat("$c2_y", r_ssr_error:GetFloat())
		ssr_setfloat("$c2_z", r_ssr_treshold:GetFloat())

		mData:SetField(1, 1, r_ssr_saturation_r:GetFloat()/255)
		mData:SetField(2, 1, r_ssr_saturation_g:GetFloat()/255)
		mData:SetField(3, 1, r_ssr_saturation_b:GetFloat()/255)
		ssr_setmatrix("$INVVIEWPROJMAT", mData)

		local i = math.Clamp(r_ssr_texture:GetInt(),1,2)
		texture_ssr = ssr_textures[i]
		mat_ssr:SetTexture("$basetexture", texture_ssr)
		mat_ssr_stencil:SetTexture("$basetexture", texture_ssr)

		local lin = i == 1 and 1 or 0
		mat_ssr:SetInt("$linearead_basetexture", lin)
		mat_ssr_stencil:SetInt("$linearead_basetexture", lin)
	end

	cvars.AddChangeCallback( r_ssr_quality:GetName(), function( convar_name, _, identifier )
		local i = tonumber(identifier)

		mat_ssr = ssr_mats[ i ]
		mat_ssr_stencil = ssr_stencil_mats[ i ]

		if r_ssr_auto:GetBool() then
			RunConsoleCommand("r_ssr_length", lenght_t[i])
		end

		InitParams()
	end, shaderName )

	cvars.AddChangeCallback( r_ssr_texture:GetName(), InitParams, shaderName )

	timer.Simple(0, function()
		local i = math.Clamp( math.floor( r_ssr_quality:GetInt() ), 1, #ssr_mats )
		mat_ssr = ssr_mats[ i ] or ssr_mats[ 1 ]
		mat_ssr_stencil = ssr_stencil_mats[ i ] or ssr_stencil_mats[ 1 ]
		if r_ssr:GetBool() then EnableSSR()  end
		InitParams()
	end)
	
	SSR_INITED = true
end

if SSR_INITED then
	InitSSR()
end

hook.Add("PostCEFCodecFixStatus", shaderName, function()
	timer.Simple(0, function()
		InitSSR()
	end)
end)

