

local shaderName = "PhysicallyBasedBloom"
local physbasedbloom = {}

local max_iterations = 16

local pp_pbb = CreateClientConVar( "pp_pbb", "0", true, false, "Enable/Disable Physically Based Bloom.", 0, 1 )

local pp_pbb_sky = CreateClientConVar( "pp_pbb_sky", "1", true, false, "PBB Sky mask.", 0, 1 )

local pp_pbb_treshold = CreateClientConVar( "pp_pbb_treshold", "1.3", true, false, "Physically Based Bloom treshold", 0, 5 )
local pp_pbb_solftreshold = CreateClientConVar( "pp_pbb_solftreshold", "0.1", true, false, "Physically Based Bloom treshold", 0, 1 )
local pp_pbb_tr_intensity = CreateClientConVar( "pp_pbb_tr_intensity", "0.5", true, false, "Physically Based Bloom intensity", 0, 5 )

local pp_pbb_tonemap = CreateClientConVar( "pp_pbb_tonemap", "1", false, false, "Physically Based Bloom tonemapping.", 0, 1 )

local pp_pbb_debug = CreateClientConVar( "pp_pbb_debug", "0", false, false, "Physically Based Bloom debug.", 0, 1 )
local pp_pbb_r = CreateClientConVar( "pp_pbb_r", "255", true, false, "Physically Based Bloom r.", 0, 255 )
local pp_pbb_g = CreateClientConVar( "pp_pbb_g", "255", true, false, "Physically Based Bloom g.", 0, 255 )
local pp_pbb_b = CreateClientConVar( "pp_pbb_b", "255", true, false, "Physically Based Bloom b.", 0, 255 )
local pp_pbb_colormultiply = CreateClientConVar( "pp_pbb_colormultiply", "1", true, false, "Physically Based Bloom Color Multiply.", 0, 20 )
local pp_pbb_strength = CreateClientConVar( "pp_pbb_strength", "0.5", true, false, "Bloom Strenght.", 0, 1 )
local pp_pbb_scale_x = CreateClientConVar( "pp_pbb_scale_x", "1", true, false, "Physically Based Bloom Scale x.", 1, 10 )
local pp_pbb_scale_y = CreateClientConVar( "pp_pbb_scale_y", "1", true, false, "Physically Based Bloom Scale y.", 1, 10 )
local pp_pbb_scale_z = CreateClientConVar( "pp_pbb_scale_z", "1", true, false, "Physically Based Bloom Scale z.", 1, 10 )

-- Dirt on lens
local pp_pbb_dirt = CreateClientConVar( "pp_pbb_dirt", "0", true, false, "PBB dirt.", 0, 1 )
local pp_pbb_dirt_tex = CreateClientConVar( "pp_pbb_dirt_mat", "0", true, false, "PBB dirt texture.", 0, 1 )
local pp_pbb_intensity = CreateClientConVar( "pp_pbb_intensity", "5", true, false, "Dirt Mask Intensity.", 0, 20 )

-- Chromatic aberration
local pp_pbb_chromatic = CreateClientConVar( "pp_pbb_chromatic", "0", true, false, "Chromatic aberration.", 0, 1 )
--local pp_pbb_radius = CreateClientConVar( "pp_pbb_radius", "0.9", true, false, "Chromatic aberration. Below this radius the effect is less visible.", 0, 2 )
--local pp_pbb_offset = CreateClientConVar( "pp_pbb_offset", "1.8", true, false, "Chromatic aberration. Over this radius the effects is maximal.", 0, 2 )
local pp_pbb_power = CreateClientConVar( "pp_pbb_power", "1.5", true, false, "Chromatic aberration. Ower of the chromatic displacement (curve of the 'fvChroma' vector).", 1, 3 )

local pp_pbb_chroma_r = CreateClientConVar( "pp_pbb_chroma_r", "0.05", true, false, "Chromatic aberration R.", -1, 1 )
local pp_pbb_chroma_g = CreateClientConVar( "pp_pbb_chroma_g", "-0.05", true, false, "Chromatic aberration G.", -1, 1 )
local pp_pbb_chroma_b = CreateClientConVar( "pp_pbb_chroma_b", "0", true, false, "Chromatic aberration B.", -1, 1 )

--local pp_pbb_multiply = CreateClientConVar( "pp_pbb_multiply", "1", true, false, "Chromatic aberration multiply.", 0.1, 1 )

local pp_pbb_format = CreateClientConVar( "pp_pbb_format", "1", true, false, "Physically Based Bloom image format. 0: IMAGE_FORMAT_RGB888; 1: IMAGE_FORMAT_RGBA16161616F.", 0, 1 )

local flags = render.GetHDREnabled() and CREATERENDERTARGETFLAGS_HDR or 0

function physbasedbloom.CalcMaxIterations() 
	for i = 1,max_iterations do
		local s = 2^(i-1)
		local h = ScrH()/s

		if h < 2 then break end
		max_iterations = i
	end
end

physbasedbloom.CalcMaxIterations()

local pp_pbb_iterations = CreateClientConVar( "pp_pbb_iterations", max_iterations, true, false, "Physically Based Bloom count passes.", 1, max_iterations )

local image_format = pp_pbb_format:GetInt() == 1 and IMAGE_FORMAT_RGBA16161616F or IMAGE_FORMAT_RGB888 -- BRANCH == "x86-64" and IMAGE_FORMAT_RGBA1010102 or IMAGE_FORMAT_RGBA8888

local screentexture = render.GetScreenEffectTexture()
local mask_mat 			= Material("pp/bloom_mask")
local chroma_mat 		= Material("pp/bloom_chromatic")
local chromatic_aberration = pp_pbb_chromatic:GetBool()
local bloom_mat_combine = Material("pp/bloom_combine")

local rt_emissive = GetRenderTargetEx("_rt_Emissive", ScrW(), ScrH(),
	RT_SIZE_FULL_FRAME_BUFFER,
	MATERIAL_RT_DEPTH_NONE,
	bit.bor(4,8,16,256,512,8388608),
	flags,
	IMAGE_FORMAT_RGB888 -- IMAGE_FORMAT_RGBA1010102 IMAGE_FORMAT_RGBA8888
)

local options = {
	"pp/dirtmasktexture";
	"pp/lensdirt";
	"pp/fx_lensdirt";
	"pp/lensdirt_ins2";
}

local function OnSelectMat(material)
	local mat = Material(material)
	if mat:IsError() or !mat then
		mat = Material(options[1])
	end

	local basetexture 	= mat:GetTexture("$basetexture")
	bloom_mat_combine:SetTexture("$texture1", basetexture)
end

RT_BLOOM = RT_BLOOM or {}
BLOOM_MATS_DOWN = BLOOM_MATS_DOWN or {}
BLOOM_MATS_UP = BLOOM_MATS_UP or {}


local bloom_mips_count = pp_pbb_iterations:GetInt() or max_iterations
bloom_mips_count = math.Clamp(bloom_mips_count,pp_pbb_iterations:GetMin(),pp_pbb_iterations:GetMax())
local rt_base_name = "_rt_pbb"
local bloom_up = Material("pp/bloom_up")
local bloom_up_keyvalues = bloom_up:GetKeyValues()
bloom_up_keyvalues["$flags2"] = nil
bloom_up_keyvalues["$flags_defined2"] = nil
bloom_up_keyvalues["$flags"] = nil
bloom_up_keyvalues["$flags_defined"] = nil
bloom_up_keyvalues["$pixshader"] = "bloom_up_ps30"

local bloom_down = Material("pp/bloom_down")
local bloom_down_keyvalues = bloom_down:GetKeyValues()
bloom_down_keyvalues["$flags2"] = nil
bloom_down_keyvalues["$flags_defined2"] = nil
bloom_down_keyvalues["$flags"] = nil
bloom_down_keyvalues["$flags_defined"] = nil

local function SetFloatMat(key, value)
	bloom_mat_combine:SetFloat(key, value)
end

local function SetTextureMat(key, value)
	bloom_mat_combine:SetTexture(key, value)
end

local function PhysicallyBasedBloom()
	if shaderlib and !shaderlib.CanDrawEffects() then return end
	hook.Run("PreDrawBloom")

	render.PushRenderTarget(RT_BLOOM[1])
		render.SetMaterial( BLOOM_MATS_DOWN[1] )
		render.DrawScreenQuad()
	render.PopRenderTarget()

	for i = 2, bloom_mips_count do
		render.PushRenderTarget(RT_BLOOM[i])
			render.SetMaterial( BLOOM_MATS_DOWN[i] )
			render.DrawScreenQuad()
		render.PopRenderTarget()
	end

	render.OverrideBlend( true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD )

	for i = bloom_mips_count - 1, 1, -1 do
		render.PushRenderTarget(RT_BLOOM[i])
			render.SetMaterial( BLOOM_MATS_UP[i] )
			render.DrawScreenQuad()
		render.PopRenderTarget()
	end

	render.OverrideBlend( false )

	render.UpdateScreenEffectTexture()
	render.CopyRenderTargetToTexture(screentexture)
	render.SetMaterial( bloom_mat_combine )
	render.DrawScreenQuad()
end

local tonemap_value = 0

local function EnableDebugMode()
	hook.Add("HUDPaint", shaderName, function()
		render.DrawTextureToScreenRect(rt_emissive,  ScrW()-ScrW()/3,0, ScrW()/3, ScrH()/3)
		bloom_mat_combine:SetTexture("$basetexture", "black")

		draw.DrawText("Tonemap Linear Value: " .. tonemap_value, "BudgetLabel", ScrW()*0.5, ScrH()*0.2, color_white, TEXT_ALIGN_LEFT)
	end)
end

local function DisableBloom()
	RunConsoleCommand("mat_disable_bloom", old_mat_disable_bloom)

	hook.Remove("PreDrawEffects", shaderName)
	hook.Remove("RenderScreenspaceEffects", shaderName)
	hook.Remove("HUDPaint", shaderName)
	hook.Remove("PreDrawShadows", shaderName)
end

local function NotifyChangeResolution()
	DisableBloom()
	LocalPlayer():ChatPrint( "(Change screen resolution) Retry to "..(game.SinglePlayer() and "map" or "server").." for Physically Based Bloom works again." )
end

hook.Add( "OnScreenSizeChanged", shaderName, function( oldWidth, oldHeight, newWidth, newHeight )
	if newWidth == oldWidth and newHeight == oldHeight then return end -- ignore MSAA changes
	CHANGED_RESOLUTION = true
	NotifyChangeResolution()
end )

local hook_mask = "PreDrawBloom" --"PreDrawEffects"
local mask_mat = (pp_pbb_sky:GetBool() and GSHADER) and Material("pp/bloom_mask") or Material("pp/bloom_mask_no_sky")

function physbasedbloom.EnablePhysBasedBloom()
	if !PHYS_BASE_BLOOM_INITED then
		physbasedbloom.CalcMaxIterations() 
		physbasedbloom.InitPhysBasedBloom()
	end

	if CHANGED_RESOLUTION then NotifyChangeResolution() return end

	if GSHADER and !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", 1) end

	old_mat_disable_bloom = GetConVar("mat_disable_bloom"):GetInt()
	RunConsoleCommand("mat_disable_bloom", 1)

	hook.Add(hook_mask, shaderName, function()
		if shaderlib and !shaderlib.CanDrawEffects() then return end
		render.UpdateScreenEffectTexture()
		render.CopyRenderTargetToTexture(screentexture)
		
		render.PushRenderTarget(rt_emissive)
			render.Clear(0,0,0,0)
			render.SetMaterial(mask_mat)
			render.DrawScreenQuad()
		render.PopRenderTarget()

		if chromatic_aberration then
			render.PushRenderTarget(rt_emissive)
				render.SetMaterial(chroma_mat)
				render.DrawScreenQuad()
			render.PopRenderTarget()
		end
		
		tonemap_value = render.GetToneMappingScaleLinear().x
		local value = (pp_pbb_tonemap:GetBool() and tonemap_value or 1) * pp_pbb_colormultiply:GetFloat()
		SetFloatMat("$c1_w", value)
	end)

	hook.Add("RenderScreenspaceEffects", shaderName, PhysicallyBasedBloom)

	if pp_pbb_debug:GetBool() then EnableDebugMode() end
end

local function StartPBB()
	if pp_pbb:GetBool() then physbasedbloom.EnablePhysBasedBloom() end
end

cvars.AddChangeCallback( pp_pbb:GetName(), function( convar_name, _, identifier )
	local enabled = identifier == "1"

	if enabled then
		physbasedbloom.EnablePhysBasedBloom()
	else
		DisableBloom()
	end
end, shaderName )

local bloom_matrix = Matrix()

local function InitMaskMatrix()
	mask_mat = (GSHADER and pp_pbb_sky:GetBool()) and Material("pp/bloom_mask") or Material("pp/bloom_mask_no_sky")
	local _Threshold = pp_pbb_treshold:GetFloat()
	local _SoftThreshold = pp_pbb_solftreshold:GetFloat()

	bloom_matrix:SetField( 1, 1, _Threshold )
	local knee = _Threshold * _SoftThreshold
	bloom_matrix:SetField( 3, 1, knee )
	local knee2 = 2 * knee
	bloom_matrix:SetField( 4, 1, knee2 )

	local knee4 = (4 * knee + 0.00001)
	bloom_matrix:SetField( 1, 2, knee2 )

	local _Intensity = pp_pbb_tr_intensity:GetFloat()
	bloom_matrix:SetField( 2, 1, _Intensity )

	mask_mat:SetMatrix("$viewprojmat", bloom_matrix)
end

cvars.AddChangeCallback( pp_pbb_treshold:GetName(), function( convar_name, _, identifier )
	--mask_mat:SetFloat("c0_x", tonumber(identifier) )

	local value = tonumber(identifier)

	bloom_matrix:SetField( 1, 1, value ) // _Threshold
	local knee = value * pp_pbb_solftreshold:GetFloat()
	bloom_matrix:SetField( 3, 1, knee ) // _Threshold * _SoftThreshold
	local knee2 = 2 * knee
	bloom_matrix:SetField( 4, 1, knee2 ) // 2 * knee

	local knee4 = (4 * knee + 0.00001)
	bloom_matrix:SetField( 1, 2, knee2 )

	mask_mat:SetMatrix("$viewprojmat", bloom_matrix)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_solftreshold:GetName(), function( convar_name, _, identifier )
	--mask_mat:SetFloat("c0_y", tonumber(identifier) )

	local value = tonumber(identifier)
	local knee = pp_pbb_treshold:GetFloat() * value
	bloom_matrix:SetField( 3, 1, knee ) // _Threshold * _SoftThreshold

	mask_mat:SetMatrix("$viewprojmat", bloom_matrix)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_tr_intensity:GetName(), function( convar_name, _, identifier )
	--mask_mat:SetFloat("c0_z", tonumber(identifier) )
	local value = tonumber(identifier)
	bloom_matrix:SetField( 1, 2, value ) // _Intensity

	mask_mat:SetMatrix("$viewprojmat", bloom_matrix)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_debug:GetName(), function( convar_name, _, identifier )
	local enabled = identifier == "1"
	
	if enabled then
		EnableDebugMode()
	else
		bloom_mat_combine:SetTexture("$basetexture", "_rt_FullFrameFB")
		hook.Remove("HUDPaint", shaderName)
	end

end, shaderName )

cvars.AddChangeCallback( pp_pbb_r:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c1_x", identifier/255)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_g:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c1_y", identifier/255)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_b:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c1_z", identifier/255)
end, shaderName )

--[[cvars.AddChangeCallback( pp_pbb_colormultiply:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c1_w", identifier)
end, shaderName )]]

local function SetScaleBloom(key, value)
	for i = 1,bloom_mips_count do
		if BLOOM_MATS_UP[i] then -- у некоторых редко были скриптовые ошибки
			BLOOM_MATS_UP[i]:SetFloat(key, value)
		end
	end
end

cvars.AddChangeCallback( pp_pbb_scale_x:GetName(), function( convar_name, _, identifier )
	SetScaleBloom("$c0_x", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_scale_y:GetName(), function( convar_name, _, identifier )
	SetScaleBloom("$c0_y", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_scale_z:GetName(), function( convar_name, _, identifier )
	SetScaleBloom("$c0_z", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_iterations:GetName(), function( convar_name, _, identifier )
	bloom_mips_count = math.Round(identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_chromatic:GetName(), function( convar_name, _, identifier )
	chromatic_aberration = identifier == "1"
end, shaderName )

cvars.AddChangeCallback( pp_pbb_strength:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c2_w", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_intensity:GetName(), function( convar_name, _, identifier )
	SetFloatMat("$c3_x", identifier)
end, shaderName )

local function getFinalColor(value, n)
	n = 1 + tonumber(n)/10
	chroma_mat:SetFloat(value, n)
end

cvars.AddChangeCallback( pp_pbb_chroma_r:GetName(), function( convar_name, _, identifier )
	getFinalColor("$c0_x", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_chroma_g:GetName(), function( convar_name, _, identifier )
	getFinalColor("$c0_y", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_chroma_b:GetName(), function( convar_name, _, identifier )
	getFinalColor("$c0_z", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_power:GetName(), function( convar_name, _, identifier )
	chroma_mat:SetFloat("$c3_x", identifier)
end, shaderName )

cvars.AddChangeCallback( pp_pbb_sky:GetName(), function( convar_name, _, identifier )
	local state = identifier == "1"
	mask_mat = (state and GSHADER) and Material("pp/bloom_mask") or Material("pp/bloom_mask_no_sky")
	InitMaskMatrix()
end, shaderName )

local gamma = 1 -- 1/2.2

local function UpdateCombine()
	bloom_mat_combine = pp_pbb_dirt:GetBool() and Material("pp/bloom_combine_dirt") or Material("pp/bloom_combine")
	local _ColorIntensity = Vector(pp_pbb_r:GetFloat(),pp_pbb_g:GetFloat(),pp_pbb_b:GetFloat())/255
	local _ColorMultiply = pp_pbb_colormultiply:GetFloat()

	SetFloatMat("$c1_x", _ColorIntensity.x)
	SetFloatMat("$c1_y", _ColorIntensity.y)
	SetFloatMat("$c1_z", _ColorIntensity.z)
	--SetFloatMat("$c1_w", _ColorMultiply)
	SetFloatMat("$c3_x", pp_pbb_intensity:GetFloat())
	SetFloatMat("$c2_w", pp_pbb_strength:GetFloat())
	SetFloatMat("$c1_x", (pp_pbb_r:GetFloat()/255) ^ gamma)
	SetFloatMat("$c1_y", (pp_pbb_g:GetFloat()/255) ^ gamma)
	SetFloatMat("$c1_z", (pp_pbb_b:GetFloat()/255) ^ gamma)

	SetTextureMat("$texture2", RT_BLOOM[1])

	OnSelectMat( pp_pbb_dirt_tex:GetString() )
end

cvars.AddChangeCallback( pp_pbb_dirt:GetName(), function( convar_name, _, identifier )
	UpdateCombine()
end, shaderName )

local function InitChroma()
	getFinalColor("$c0_x", pp_pbb_chroma_r:GetFloat())
	getFinalColor("$c0_y", pp_pbb_chroma_g:GetFloat())
	getFinalColor("$c0_z", pp_pbb_chroma_g:GetFloat())
	chroma_mat:SetFloat("$c3_x", pp_pbb_power:GetFloat())
end

function physbasedbloom.InitPhysBasedBloom()
	for i = 1,max_iterations do
		local s = 2^(i-1)
		local w = ScrW()/s
		local h = ScrH()/s

		RT_BLOOM[i] = GetRenderTargetEx(rt_base_name..i, w, h,
			--RT_SIZE_LITERAL_PICMIP,
			RT_SIZE_LITERAL,
			MATERIAL_RT_DEPTH_NONE,
			bit.bor(4,8,256,512,16),
			flags,
			image_format
		)

		local is_first = i == 1

		BLOOM_MATS_DOWN[i] = is_first and Material("pp/bloom_down_first") or CreateMaterial("bloom_dow2n_"..i, "screenspace_general", bloom_down_keyvalues)
		BLOOM_MATS_DOWN[i]:SetFloat("$c0_y", 0.25) -- Luminance
		BLOOM_MATS_UP[i] = CreateMaterial("bloom_up"..i, "screenspace_general", bloom_up_keyvalues)
		BLOOM_MATS_UP[i]:SetFloat("$c0_x", pp_pbb_scale_x:GetFloat())
		BLOOM_MATS_UP[i]:SetFloat("$c0_y", pp_pbb_scale_y:GetFloat())
		BLOOM_MATS_UP[i]:SetFloat("$c0_z", pp_pbb_scale_z:GetFloat())
	end
	
	BLOOM_MATS_DOWN[1]:SetTexture("$basetexture", rt_emissive)

	for i = 2, max_iterations do
		BLOOM_MATS_DOWN[i]:SetTexture("$basetexture", RT_BLOOM[i - 1])
	end

	for i = bloom_mips_count - 1, 1, -1 do
		BLOOM_MATS_UP[i]:SetTexture("$basetexture", RT_BLOOM[i + 1])
	end

	UpdateCombine()

	InitChroma()

	PHYS_BASE_BLOOM_INITED = true
end

hook.Add("InitPostEntity", shaderName, function()
	timer.Simple(0, function()
		physbasedbloom.InitPhysBasedBloom()
		InitMaskMatrix()
		StartPBB()
	end)
end)

if PHYS_BASE_BLOOM_INITED then
	StartPBB()
end

physbasedbloom.InitPhysBasedBloom()
InitMaskMatrix()


