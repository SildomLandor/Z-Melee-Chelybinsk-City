
local shaderName = "FXAA"

local r_fxaa = CreateClientConVar( "r_fxaa", "0", true, false, "Enable/Disable FXAA.", 0, 1 )
local r_fxaa_quality = CreateClientConVar( "r_fxaa_quality", "3", true, false, "FXAA quality. Choose the quality preset. This needs to be compiled into the shader as it effects code. Best option to include multiple presets is to in each shader define the preset, then include this file. Low - 12 preset, default medium dither; Medium - 22 preset, less dither, more expensive; High - 39 preset, no dither, very expensive.", 1, 3 )

local r_fxaa_subpix = CreateClientConVar( "r_fxaa_subpix", "0.75", true, false, "Choose the amount of sub-pixel aliasing removal. This can effect sharpness. 1.00 - upper limit (softer); 0.75 - default amount of filtering; 0.50 - lower limit (sharper, less sub-pixel aliasing removal); 0.25 - almost off; 0.00 - completely off.", 0, 1 )
local r_fxaa_edgethreshold = CreateClientConVar( "r_fxaa_edgethreshold", "0.166", true, false, "The minimum amount of local contrast required to apply algorithm. 0.333 - too little (faster); 0.250 - low quality; 0.166 - default; 0.125 - high quality ; 0.063 - overkill (slower).", 0, 1 )
local r_fxaa_edgethresholdmin = CreateClientConVar( "r_fxaa_edgethresholdmin", "0.0833", true, false, "Trims the algorithm from processing darks. 0.0833 - upper limit (default, the start of visible unfiltered edges); 0.0625 - high quality (faster); 0.0312 - visible limit (slower). Likely want to set this to zero. As colors that are mostly not-green will appear very dark in the green channel! Tune by looking at mostly non-green content, then start at zero and increase until aliasing is a problem.", 0, 1 )

local screentexture = render.GetScreenEffectTexture()

local fxaa_mats = {
	Material("pp/pp_fxaa_low");
	Material("pp/pp_fxaa_medium");
	Material("pp/pp_fxaa_high");
}

local fxaa_mat = fxaa_mats[r_fxaa_quality:GetInt()]
local shader = fxaa_mat:GetShader()
local keyvalues = fxaa_mat:GetKeyValues()
keyvalues["$flags2"] = nil
keyvalues["$flags_defined"] = nil
keyvalues["$flags"] = nil
keyvalues["$flags_defined2"] = nil

local mats = {}

local function EnableFXAA()
	hook.Add("PostDrawEffects", shaderName, function()
		--if shaderlib and !shaderlib.CanDrawEffects( render.GetViewSetup() ) then return end

		local rt = render.GetRenderTarget()

		if rt and !mats[rt:GetName()] then
			local rt_name = rt:GetName()
			mats[rt_name] = CreateMaterial( "fxaa_"..rt_name, shader, keyvalues )
			mats[rt_name]:SetTexture("$basetexture", rt)
		end

		render.UpdateScreenEffectTexture()
		render.CopyRenderTargetToTexture(screentexture)

		render.SetMaterial(rt and mats[rt:GetName()] or fxaa_mat)
	    render.DrawScreenQuad()
	end )
end

if r_fxaa:GetBool() then EnableFXAA() end

cvars.AddChangeCallback( r_fxaa:GetName(), function( convar_name, _, identifier )
	local enabled = identifier == "1"

	if enabled then
		EnableFXAA()
	else
		hook.Remove("PostDrawEffects", shaderName)
	end
end, shaderName )

local function InitFXAAParams()
	fxaa_mat = fxaa_mats[r_fxaa_quality:GetInt()]
	fxaa_mat:SetFloat("$c0_x", r_fxaa_subpix:GetFloat())
	fxaa_mat:SetFloat("$c0_y", r_fxaa_edgethreshold:GetFloat())
	fxaa_mat:SetFloat("$c0_z", r_fxaa_edgethresholdmin:GetFloat())
end

cvars.AddChangeCallback( r_fxaa_quality:GetName(), InitFXAAParams, shaderName )
cvars.AddChangeCallback( r_fxaa_subpix:GetName(), InitFXAAParams, shaderName )
cvars.AddChangeCallback( r_fxaa_edgethreshold:GetName(), InitFXAAParams, shaderName )
cvars.AddChangeCallback( r_fxaa_edgethresholdmin:GetName(), InitFXAAParams, shaderName )

