local pp_scaf = CreateClientConVar( "pp_scaf", "1", true, false, "Enable/Disable chromatic aberration filter.", 0, 1 )
local pp_scaf_intensity = CreateClientConVar( "pp_scaf_intensity", "0", true, false, "How intense the chromatic aberration will be.", 0, 200 )
local pp_scaf_redx = CreateClientConVar( "pp_scaf_redx", "8", true, false, "Mixing of chromatic aberrations in the red channel along the X-axis.", 0, 128 )
local pp_scaf_redy = CreateClientConVar( "pp_scaf_redy", "4", true, false, "Mixing of chromatic aberrations in the red channel along the Y-axis.", 0, 128 )
local pp_scaf_greenx = CreateClientConVar( "pp_scaf_greenx", "4", true, false, "Mixing of chromatic aberrations in the green channel along the X-axis.", 0, 128 )
local pp_scaf_greeny = CreateClientConVar( "pp_scaf_greeny", "2", true, false, "Mixing of chromatic aberrations in the green channel along the Y-axis.", 0, 128 )
local pp_scaf_bluex = CreateClientConVar( "pp_scaf_bluex", "0", true, false, "Mixing of chromatic aberrations in the blue channel along the X-axis.", 0, 128 )
local pp_scaf_bluey = CreateClientConVar( "pp_scaf_bluey", "0", true, false, "Mixing of chromatic aberrations in the blue channel along the Y-axis.", 0, 128 )

-- https://wiki.facepunch.com/gmod/cvars.AddChangeCallback
local enabled = pp_scaf:GetBool()
cvars.AddChangeCallback( pp_scaf:GetName(), function( _, __, new )
	enabled = new == "1"
end, addonName )

local Run = hook.Run

local function isPostProcessPermitted()
	return enabled and Run( "PostProcessPermitted", "scafilter" ) ~= false
end

local redX, greenX, blueX = 0, 0, 0
local redY, greenY, blueY = 0, 0, 0
local floor = math.floor
local intensity = 0

hook.Add( "Think", addonName, function()
	if isPostProcessPermitted() then
		intensity = pp_scaf_intensity:GetFloat()
		redX = floor( pp_scaf_redx:GetInt() * intensity )
		greenX = floor( pp_scaf_greenx:GetInt() * intensity )
		blueX = floor( pp_scaf_bluex:GetInt() * intensity )
		redY = floor( pp_scaf_redy:GetInt() * intensity )
		greenY = floor( pp_scaf_greeny:GetInt() * intensity )
		blueY = floor( pp_scaf_bluey:GetInt() * intensity )
	else
		intensity = 0
		redX, greenX, blueX = 0, 0, 0
		redY, greenY, blueY = 0, 0, 0
	end
end )

-- https://wiki.facepunch.com/gmod/GM:OnScreenSizeChanged
local width, height = ScrW(), ScrH()
hook.Add( "OnScreenSizeChanged", addonName, function()
	width, height = ScrW(), ScrH()
end )

local SetMaterial, DrawScreenQuad, DrawScreenQuadEx, UpdateScreenEffectTexture = render.SetMaterial, render.DrawScreenQuad, render.DrawScreenQuadEx, render.UpdateScreenEffectTexture
local screenEffectTexture, black = render.GetScreenEffectTexture( 0 ), Material( "vgui/black" )

local red = Material( "color/red" )
red:SetTexture( "$basetexture", screenEffectTexture )

local green = Material( "color/green" )
green:SetTexture( "$basetexture", screenEffectTexture )

local blue = Material( "color/blue" )
blue:SetTexture( "$basetexture", screenEffectTexture )

hook.Add( "RenderScreenspaceEffects", addonName, function()
	if intensity <= 0 then return end

	UpdateScreenEffectTexture()

	SetMaterial( black )
	DrawScreenQuad()
	SetMaterial( black )
	DrawScreenQuad()

	SetMaterial( red )
	DrawScreenQuadEx( -redX / 2, -redY / 2, width + redX, height + redY )

	SetMaterial( green )
	DrawScreenQuadEx( -greenX / 2, -greenY / 2, width + greenX, height + greenY )

	SetMaterial( blue )
	DrawScreenQuadEx( -blueX / 2, -blueY / 2, width + blueX, height + blueY )

	render.SetColorModulation( 1, 1, 1 )
end )
