local shaderName = "FidelityFXCAS"

local r_ffx_cas	= CreateClientConVar( "r_ffx_cas", "0", true, false, "Enable Contrast Adaptive Sharpening (AMD FidelityFX CAS).", 0, 1 )
local r_ffx_cas_factor	= CreateClientConVar( "r_ffx_cas_factor", "0.35", true, false, "CAS: Contrast sharpening Amount. Negative values are possible for lighter sharpening.", 0, 1.3 )
local r_ffx_cas_debug	= CreateClientConVar( "r_ffx_cas_debug", "0", false, false, "Show edges of Adaptive Sharpening (AMD FidelityFX CAS).", 0, 1 )

local screentexture = render.GetScreenEffectTexture()
local mat = Material("pp/ffx_cas")
local mat_debug = Material("pp/ffx_cas_debug")

local function EnableSharpness()
	hook.Add("PreDrawHUD", shaderName, function() -- will works after Anti aliasing like FXAA, DLAA, SMAA, TAA, etc.
		if shaderlib then if !shaderlib.CanDrawEffects() then return end end
		render.UpdateScreenEffectTexture()
		render.CopyRenderTargetToTexture(screentexture)
		local _debug = r_ffx_cas_debug:GetBool()
		render.SetMaterial(_debug and mat_debug or mat)
	    render.DrawScreenQuad()
	end )
end

local function CalculateCAS()
	local CAS = r_ffx_cas_factor:GetFloat()
	local peak = 1 / (3*CAS -8.) // must be <0
	mat:SetFloat("$c0_x", peak)
	mat_debug:SetFloat("$c0_x", peak)
end

local function InitFFXCas()
	CalculateCAS()
	if r_ffx_cas:GetBool() then EnableSharpness() end
end

InitFFXCas()

hook.Add("Initialize", shaderName, function()
	timer.Simple(1, function()
		InitFFXCas()
	end)
end)

cvars.AddChangeCallback( r_ffx_cas:GetName(), function( convar_name, _, identifier )
	local enabled = identifier == "1"

	if enabled then
		EnableSharpness()
	else
		hook.Remove("PreDrawHUD", shaderName)
	end
end, shaderName )

cvars.AddChangeCallback( r_ffx_cas_factor:GetName(), CalculateCAS, shaderName )

/* LICENSE: Copyright (c) 2020 Advanced Micro Devices, Inc. All rights reserved. Permission is hereby granted, free of charge,
to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following
conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
