local shaderName = "PhysicalSky"

-- Physical Sky
local cl_physsky				= CreateClientConVar( "cl_physsky",	"0", true, false, "Enable Physical Sky.", 0, 1 )
local cl_physsky_turbidity		= CreateClientConVar("cl_physsky_turbidity", "1.9",	true, false, "Physical Sky turbidity.", 0, 5 )
local cl_physsky_exposition		= CreateClientConVar("cl_physsky_exposition", "15.9", true, false, "Physical Sky turbidity.", 0, 125 )
local cl_physsky_sphere			= CreateClientConVar("cl_physsky_sphere", "1", true, false, "Physical Sky sphere.", 0, 1 )
local cl_physsky_autosun		= CreateClientConVar("cl_physsky_autosun", "1", true, false, "Physical Sky auto sun color.", 0, 1 )
local cl_physsky_debug_mode		= CreateClientConVar( "cl_physsky_debug_mode", "0", false, false, "Phys sky debug mode.", 0, 1 )

-- Volumetric Clouds
local cl_clouds 				= CreateClientConVar("cl_clouds", "1", true, false, "Volumetric cloud.", 0, 1 ) 
local cl_clouds_density			= CreateClientConVar("cl_clouds_density", "2", true, false, "Volumetric cloud density.", 0, 2 )
local cl_clouds_coverage		= CreateClientConVar("cl_clouds_coverage", 0.71 * 100, true, false, "Volumetric cloud coverage.", 0, 100 )
local cl_clouds_sunintensity	= CreateClientConVar("cl_clouds_sunintensity", "2.27", true, false, "Volumetric cloud sun intensity.", 0, 100 )
local cl_clouds_attenuation		= CreateClientConVar("cl_clouds_attenuation", "88.27", true, false, "Volumetric cloud sun attenuation.", 0, 100 ) -- 51.27
local cl_clouds_attenuation2	= CreateClientConVar("cl_clouds_attenuation2", "15.13", true, false, "Volumetric cloud sun attenuation 2.", 0, 100 )
local cl_clouds_fog				= CreateClientConVar("cl_clouds_fog", "7.96", true, false, "Volumetric cloud sun attenuation 2.", 0, 100 ) 
local cl_clouds_ambient			= CreateClientConVar("cl_clouds_ambient", "1.98", true, false, "Volumetric cloud sun attenuation 2.", 0, 5 ) 
local cl_clouds_speed 			= CreateClientConVar("cl_clouds_speed", "0.1", true, false, "Volumetric cloud speed.", 0, 3 ) 
local cl_clouds_min				= CreateClientConVar("cl_clouds_min", "0", true, false, "Volumetric cloud min clouds.", 0, 35 ) 
local cl_clouds_max				= CreateClientConVar("cl_clouds_max", "35", true, false, "Volumetric cloud max clouds.", 0, 35 ) 

-- Stars
local cl_physsky_star_scale		= CreateClientConVar( "cl_physsky_star_scale", "5", true, false, "Phys sky debug mode.", 0.5, 10 )
local cl_physsky_star_power		= CreateClientConVar( "cl_physsky_star_power", "0", true, false, "Phys sky debug mode.", 0, 100 )
local cl_physsky_star_speed		= CreateClientConVar( "cl_physsky_star_speed", "0.02", true, false, "Volumetric cloud speed.", 0, 5 ) 

local auto_sun_color = color_white

local function InitPhysicalSky()


	local mat = Material("volumetric_clouds/skydome")

	local segments = 12 // MAX 64
	local radius = 5000

	local function createSkyMesh()
	    local verts = {}
	    local pi2 = 2 * math.pi
	    local half_pi = math.pi * 0.5
	    
	    for i = 0, segments - 1 do
	        local theta1 = (i / segments) * half_pi
	        local theta2 = ((i + 1) / segments) * half_pi
	        local theta1_sin_radius = radius * math.sin(theta1)
			local theta2_sin_radius = radius * math.sin(theta2)
			local radius_theta1 = radius * math.cos(theta1)
			local radius_theta2 = radius * math.cos(theta2)

	        for j = 0, segments - 1 do
	            local phi1 = (j / segments) * pi2
	            local phi2 = ((j + 1) / segments) * pi2

	            local phi1_cos = math.cos(phi1)
	            local phi1_sin = math.sin(phi1)
	            local phi2_cos = math.cos(phi2)
	            local phi2_sin = math.sin(phi2)

	            verts[#verts + 1] = {
	                position = Vector(
	                	theta1_sin_radius * phi1_cos,
	                	theta1_sin_radius * phi1_sin,
	                	radius_theta1
	            	),
	            }

	            verts[#verts + 1] = {
	                position = Vector(
	                	theta1_sin_radius * phi2_cos,
	                	theta1_sin_radius * phi2_sin,
	                	radius_theta1
	            	),
	            }
	            verts[#verts + 1] = {
	                position = Vector(
	                	theta2_sin_radius * phi2_cos,
	                	theta2_sin_radius * phi2_sin,
	                	radius_theta2
	            	),
	            }
	            verts[#verts + 1] = {
	                position = Vector(
	                	theta2_sin_radius * phi1_cos,
	                	theta2_sin_radius * phi1_sin,
	                	radius_theta2
	            	),
	            }
	        end
	    end
	    
	    return verts
	end

	local skyVerts = createSkyMesh()

	local rtFlags = render.GetHDREnabled() and CREATERENDERTARGETFLAGS_HDR or 0

	local linux = ( system.IsLinux() or system.IsOSX() or system.IsProton() or render.GetDXLevel() == 92 )
	local image_format = linux and IMAGE_FORMAT_RGBA8888 or IMAGE_FORMAT_I8
	
	RT_CLOUDSMASK = GetRenderTargetEx("_rt_CloudMask", ScrW(), ScrH(),
		RT_SIZE_FULL_FRAME_BUFFER,
		MATERIAL_RT_DEPTH_SHARED,
		bit.bor(4,8,256,512),
		rtFlags, 
		image_format
	)

	local vertes_num = #skyVerts/4

	local function DrawSkyMesh()
		mesh.Begin(MATERIAL_QUADS, vertes_num)
			for i = 1,#skyVerts do
				mesh.Position(skyVerts[i].position)
				-- mesh.TexCoord(0, skyVerts[i].u, skyVerts[i].v)
				mesh.AdvanceVertex()
			end
		mesh.End()
	end

	// HDTV rec. 709 matrix.
	local M_XYZ2RGB = {
		3.240479, -0.969256,  0.055648,
		-1.53715,   1.875991, -0.204043,
		-0.49853,   0.041556,  1.057311,
	}

	// Converts color repesentation from CIE XYZ to RGB color-space.
	local function xyzToRgb(xyz)
		return Vector(
			M_XYZ2RGB[1] * xyz.x + M_XYZ2RGB[4] * xyz.y + M_XYZ2RGB[7] * xyz.z,
			M_XYZ2RGB[2] * xyz.x + M_XYZ2RGB[5] * xyz.y + M_XYZ2RGB[8] * xyz.z,
			M_XYZ2RGB[3] * xyz.x + M_XYZ2RGB[6] * xyz.y + M_XYZ2RGB[9] * xyz.z
		)
	end

	// Precomputed luminance of sky in the zenith point in XYZ colorspace.
	// Computed using code from Game Engine Gems, Volume One, chapter 15. Implementation based on Dr. Richard Bird model.
	// This table is used for piecewise linear interpolation. Day/night transitions are highly inaccurate.
	// The scale of luminance change in Day/night transitions is not preserved.
	// Luminance at night was increased to eliminate need the of HDR render.

	local skyLuminanceXYZTable = {
		Vector( 0.308,    0.308,    0.411    ),
		Vector( 0.308,    0.308,    0.410    ),
		Vector( 0.301,    0.301,    0.402    ),
		Vector( 0.287,    0.287,    0.382    ),
		Vector( 0.258,    0.258,    0.344    ),
		Vector( 0.258,    0.258,    0.344    ),
		Vector( 0.610,    0.629,    1.045    ),
		Vector( 0.962851, 1.000000, 1.747835 ),
		Vector( 0.967787, 1.000000, 1.776762 ),
		Vector( 0.970173, 1.000000, 1.788413 ),
		Vector( 0.971431, 1.000000, 1.794102 ),
		Vector( 0.972099, 1.000000, 1.797096 ),
		Vector( 0.972385, 1.000000, 1.798389 ),
		Vector( 0.972361, 1.000000, 1.798278 ),
		Vector( 0.972020, 1.000000, 1.796740 ),
		Vector( 0.971275, 1.000000, 1.793407 ),
		Vector( 0.969885, 1.000000, 1.787078 ),
		Vector( 0.967216, 1.000000, 1.773758 ),
		Vector( 0.961668, 1.000000, 1.739891 ),
		Vector( 0.610,    0.629,    1.045    ),
		Vector( 0.264,    0.264,    0.352    ),
		Vector( 0.264,    0.264,    0.352    ),
		Vector( 0.290,    0.290,    0.386    ),
		Vector( 0.303,    0.303,    0.404    ),
	};

	// Turbidity tables. Taken from:
	// A. J. Preetham, P. Shirley, and B. Smits. A Practical Analytic Model for Daylight. SIGGRAPH '99
	// Coefficients correspond to xyY colorspace.
	local ABCDE =
	{
		Vector(-0.2592, -0.2608, -1.4630 ),
		Vector(0.0008,  0.0092,  0.4275 ),
		Vector(0.2125,  0.2102,  5.3251 ),
		Vector(-0.8989, -1.6537, -2.5771 ),
		Vector(0.0452,  0.0529,  0.3703 ),
	};
	local ABCDE_t =
	{
		Vector(-0.0193, -0.0167,  0.1787 ),
		Vector(-0.0665, -0.0950, -0.3554 ),
		Vector(-0.0004, -0.0079, -0.0227 ),
		Vector(-0.0641, -0.0441,  0.1206 ),
		Vector(-0.0033, -0.0109, -0.0670 ),
	};

	local function interpolate(lowerTime, lowerVal, upperTime, upperVal,time)
		local tt = (time - lowerTime) / (upperTime - lowerTime);
		local result = LerpVector(tt, lowerVal, upperVal)
		return result;
	end

	local function MultAdd(src1, src2, src3)
		local tmp = Vector(0,0,0)
		tmp.x = src1.x * src2.x + src3.x;
		tmp.y = src1.y * src2.y + src3.y;
		tmp.z = src1.z * src2.z + src3.z;
		return tmp;
	end

	local function computePerezCoeff(_turbidity)
		local turbidity = Vector(_turbidity, _turbidity, _turbidity);

		local out = {}

		for ii = 1,5 do
			local tmp = MultAdd(ABCDE_t[ii], turbidity, ABCDE[ii]);
			out[ii] = tmp
		end

		return out
	end
	local s = 0.4

	local time = 0

	local function EnableDebugMode()
		hook.Add("HUDPaint", shaderName, function()
			
			render.DrawTextureToScreenRect(RT_CLOUDSMASK,0,0,ScrW()*s,ScrH()*s)

			local msaa_enabled = GetConVar("mat_aaquality"):GetInt() > 0 or GetConVar("mat_antialias"):GetInt() > 1

			if msaa_enabled then
				draw.DrawText( "Выключи MSAA в настройках з сити. иначе у тебя не будет лучей света. можешь включить FXAA", "TargetID",0,0, color_white, TEXT_ALIGN_LEFT )
			end

			local sun_info = util.GetSunInfo()
			local sun_dir = sun_info.direction

			draw.DrawText( "Time: " .. time .. "\n Auto Sun Color: " .. tostring(auto_sun_color) .. "\nSun dir: "..tostring(sun_dir), "TargetID", ScrW() * 0.5, ScrH() * 0.25, color_white, TEXT_ALIGN_CENTER )
		end)
	end

	-- в отражении рендерим только небо

	local function vecPow(vec, pow)
		vec.x = vec.x ^ pow
		vec.y = vec.y ^ pow
		vec.z = vec.z ^ pow

		return vec
	end

	local turbidity = cl_physsky_turbidity:GetFloat()
	local perezCoeff = computePerezCoeff(turbidity)

	local function PerezDir(costheta, cosgamma)
        local A = perezCoeff[1]
        local B = perezCoeff[2]
        local C = perezCoeff[3]
        local D = perezCoeff[4]
        local E = perezCoeff[5]
        
        local inv_costheta = 1.0 / costheta
        local gamma = math.acos(cosgamma)
        
        local term1_x = 1 + A.x * math.exp(B.x * inv_costheta)
        local term1_y = 1 + A.y * math.exp(B.y * inv_costheta)
        local term1_z = 1 + A.z * math.exp(B.z * inv_costheta)
        
        local exp_Dgamma_x = math.exp(D.x * gamma)
        local exp_Dgamma_y = math.exp(D.y * gamma)
        local exp_Dgamma_z = math.exp(D.z * gamma)
        
        local term2_x = 1 + C.x * exp_Dgamma_x + E.x * (cosgamma * cosgamma)
        local term2_y = 1 + C.y * exp_Dgamma_y + E.y * (cosgamma * cosgamma)
        local term2_z = 1 + C.z * exp_Dgamma_z + E.z * (cosgamma * cosgamma)
        
        return Vector(term1_x * term2_x, term1_y * term2_y, term1_z * term2_z)
    end

	local function EnablePhysSky()
		if cl_physsky_debug_mode:GetBool() then EnableDebugMode() end

		skyLuminance = skyLuminance or Vector(0,0,0)

		cloudDir = cloudDir or vector_origin
		cloudSpeed = 0.022

		local Sun = ents.FindByClass("*_Sun")[1]
		if !IsValid(Sun) then
			local client = LocalPlayer()
			if IsValid(client) then
				client:ChatPrint( "Physical Sky: No sun on map. No data for calculations." )
			end
			return
		end
		local x86_64 = BRANCH == "x86-64" or BRANCH == "dev"
		local wind_placeholder = Vector(0.6, 0.4, 0) * 7


		old_GetSunInfo = old_GetSunInfo or util.GetSunInfo

		if cl_physsky_autosun:GetBool() then
			function util.GetSunInfo()
				local t = old_GetSunInfo()
				t.sunColor = auto_sun_color
				t.overlayColor = auto_sun_color
				return t
			end
		end

		local pow = 1/2.2
		local skyDir = Vector(0, 0, 0) -- Vector(0, 0, 1)

		local function DrawSkyDome()
			local viewSetup = render.GetViewSetup()
			if !shaderlib.CanDrawEffects(viewSetup) then return end -- water reflection broks skydome render

			local sun_info = util.GetSunInfo()
			if !sun_info then return end


			-- Physical Sky
			local col = sun_info.sunColor or Sun:GetColor()
			mat:SetFloat("$c3_x", col.r / 255)
			mat:SetFloat("$c3_y", col.g / 255)
			mat:SetFloat("$c3_z", col.b / 255)

			local sun_dir = sun_info.direction
			mat:SetFloat("$c1_x", sun_dir.x)
			mat:SetFloat("$c1_y", sun_dir.y)
			mat:SetFloat("$c1_z", sun_dir.z)
			local z = sun_dir.z

			local windVelocity = game.GetWindSpeed and game.GetWindSpeed() or wind_placeholder
			local windDir = windVelocity:GetNormalized()
			local windSpeed = windVelocity:Length()

			cloudDir = LerpVector(0.0001, cloudDir, windDir)

			local cloud_speed = cl_clouds_speed:GetFloat()

			local curTime = CurTime()
			local curTime_cloud = CurTime() * cloud_speed
			local dir = -cloudDir
			dir.x = dir.x - curTime_cloud
			dir.y = dir.y - curTime_cloud

			local star_speed = curTime * cl_physsky_star_speed:GetFloat() * 0.1
			mat:SetFloat("$c3_w", star_speed )

			mat:SetFloat("$c2_x", dir.x)
			mat:SetFloat("$c2_y", dir.y)

			time = (z * 0.5 + 0.4) * 13.3
			time = math.Clamp(math.fmod(time, 24.0), 0.01, 24.0);

			local lowerTime = math.Clamp(math.fmod(math.floor(time) - 1, 24.0), 0.0, 24.0);
			local upperTime = math.Clamp(math.fmod(math.ceil(time), 24.0), 0.0, 24.0);
			local lowerVal = skyLuminanceXYZTable[lowerTime+1];
			local upperVal = skyLuminanceXYZTable[upperTime+1];
		 	skyLuminance = LerpVector(0.005, skyLuminance, interpolate(lowerTime, lowerVal, upperTime, upperVal, time)) -- 0.01

			mat:SetFloat("$c0_x", skyLuminance.x)
			mat:SetFloat("$c0_y", skyLuminance.y)
			mat:SetFloat("$c0_z", skyLuminance.z)

			local lumTotal = skyLuminance.x + skyLuminance.y + skyLuminance.z
			local g_SkyLum_xy_lumTotal_x = skyLuminance.x / lumTotal
			local g_SkyLum_xy_lumTotal_y = skyLuminance.y / lumTotal -- надо сетать в реал тайме
			mat:SetFloat("$c2_w", g_SkyLum_xy_lumTotal_x) 
			mat:SetFloat("$c1_w", g_SkyLum_xy_lumTotal_y) 

			local msaa_enabled = GetConVar("mat_aaquality"):GetInt() > 0 or GetConVar("mat_antialias"):GetInt() > 1

			--local draw_stars = sun_dir.z < -0.2 and 1 or 0
			--mat:SetFloat("$c0_w", draw_stars)

			-- Volumetric Clouds
			render.PushRenderTarget(RT_CLOUDSMASK)
				render.Clear(0,0,0,0,false,true)
			render.PopRenderTarget()

			cam.Start3D( vector_origin, EyeAngles() )
				render.OverrideDepthEnable(true,true)
				render.SetMaterial( mat )
				if !msaa_enabled then
					render.SetRenderTargetEx(1, RT_CLOUDSMASK)
				end
				--cam.IgnoreZ(true)
				if cl_physsky_sphere:GetBool() then
					render.DrawSphere( vector_origin, viewSetup.zfar, segments, segments )
				else
					DrawSkyMesh() -- cheaper than DrawSphere
				end
				--cam.IgnoreZ(false)
				if !msaa_enabled then
					render.SetRenderTargetEx(1)
				end
				render.OverrideDepthEnable(false,false)
			cam.End3D()

			if !cl_physsky_autosun:GetBool() then return end
    
		    local cos_theta = sun_dir.z
		    cos_theta = math.max(cos_theta, 0.001)
		    local cosgamma_zenith = skyDir:Dot(sun_dir)

		    local P0 = PerezDir(1.0, cosgamma_zenith)
		    local P = PerezDir(cos_theta, 1.0)

		    local Yp = Vector(
		        g_SkyLum_xy_lumTotal_x * (P.x / P0.x),
		        g_SkyLum_xy_lumTotal_y * (P.y / P0.y),
		        skyLuminance.y * (P.z / P0.z)
		    )
		    
		    local skyColorXYZ = Vector( Yp.x * Yp.z / Yp.y, Yp.z, (1 - Yp.x - Yp.y) * Yp.z / Yp.y )
		    
		    --local exposition = cl_physsky_exposition:GetFloat()
		    local rgb = xyzToRgb(skyColorXYZ) * 255  -- * (1 / exposition)
		    rgb = vecPow(rgb, pow) * 3.6

		    auto_sun_color = Color( math.Clamp(rgb.x , 0, 255), math.Clamp(rgb.y , 0, 255), math.Clamp(rgb.z , 0, 255) )

		    if IsValid(g_SkyPaint) then
		    	local star_texture = g_SkyPaint:GetDTString( 0 )
			    mat:SetTexture("$texture3", star_texture)

			    --[[local star = g_SkyPaint:GetDTAngle( 0 )
			    local star_scale = star.p
			    mat:SetFloat("$c2_z", star_scale)]]
			end
		end

		--hook.Add("PostDraw2DSkyBox", shaderName, DrawSkyDome)
		hook.Add("PostDrawReconstruction", shaderName, DrawSkyDome)
	end

	cvars.AddChangeCallback( cl_physsky_debug_mode:GetName(), function( convar_name, _, identifier )
		local enable = identifier == "1"

		if enable then
			EnableDebugMode()
		else
			hook.Remove("HUDPaint", shaderName)
		end
	end, shaderName )

	local t0 = {0;0;0;0}

	local samples2 = 32

	--[[local flatgrass_cloud_mats = {
		"models/flata/clouds_flata.mdl";
		"models/flata/clouds_flata2.mdl";
		"models/flata/clouds_flata3.mdl";
	}]]

	local function SetupTurbidity()
		local cloud_state = cl_clouds:GetBool()
		local sky_state = cl_physsky:GetBool()

		if !cloud_state or !sky_state then
			render.PushRenderTarget(RT_CLOUDSMASK)
				render.Clear(0,0,0,0,false,true)
			render.PopRenderTarget()
		end

		--[[if map_name == "gm_flatgrass_remaster" then
			-- hide map clouds
			for k,ent in pairs(ents.FindByClass("prop_dynamic")) do
				if flatgrass_cloud_mats[ent:GetModel()] then
					ent:SetNoDraw(true)
				else
					ent:SetNoDraw(false)
				end
			end
		end]]

		if !sky_state then return end

		local cloud_mat = linux and Material("volumetric_clouds/skydome_volumetric_linux") or Material("volumetric_clouds/skydome_volumetric_clouds")
		mat = cloud_state and cloud_mat or Material("volumetric_clouds/skydome")

		local star_luma = cl_physsky_star_power:GetFloat()

		local exposition = 1 / cl_physsky_exposition:GetFloat()

		turbidity = cl_physsky_turbidity:GetFloat()
		perezCoeff = computePerezCoeff(turbidity)

		local coverage = cl_clouds_coverage:GetFloat() / 100
		local half_coverage2 = math.Clamp(coverage-0.5, 0, 1) * 2
		inv_coverage_half_coverage2 = 1-coverage*half_coverage2

		local minCloud = cl_clouds_min:GetFloat()
		local maxCloud = cl_clouds_max:GetFloat()

		local maxCloud_minCloud = maxCloud - minCloud

		local inv_maxCloud_minCloud = 1 / maxCloud_minCloud

		local sun_dest = maxCloud_minCloud*0.01 -- 0.01
		
		local avrStep2 = maxCloud_minCloud / samples2;

		local minCloud_inv_maxCloud_minCloud = minCloud * inv_maxCloud_minCloud

		local cloud_density = cl_clouds_density:GetFloat()
		cloud_density = 2 * cloud_density
		local sunIntensity = cl_clouds_sunintensity:GetFloat()

		mat:SetFloat("$c2_z", cl_physsky_star_scale:GetFloat() )

		local mFirst = Matrix({
			{perezCoeff[1].x,perezCoeff[2].x,perezCoeff[3].x,perezCoeff[4].x};
			{perezCoeff[1].y,perezCoeff[2].y,perezCoeff[3].y,perezCoeff[4].y};
			{perezCoeff[1].z,perezCoeff[2].z,perezCoeff[3].z,perezCoeff[4].z};
			{exposition;sun_dest;coverage;star_luma};
		})

		local mSecond = Matrix({
			{perezCoeff[5].x;					cl_clouds_attenuation:GetFloat();	cl_clouds_fog:GetFloat();			cloud_density};
			{perezCoeff[5].y;					cl_clouds_attenuation2:GetFloat();	cl_clouds_ambient:GetFloat();		sunIntensity}; 
			{perezCoeff[5].z;					half_coverage2;						maxCloud;							inv_coverage_half_coverage2};
			{minCloud_inv_maxCloud_minCloud;	avrStep2;							minCloud;							inv_maxCloud_minCloud};
		})

		mat:SetMatrix("$VIEWPROJMAT", mFirst)
		mat:SetMatrix("$INVVIEWPROJMAT", mSecond)
	end

	cvars.AddChangeCallback( cl_physsky_turbidity:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_density:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_coverage:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_sunintensity:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_min:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_max:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_attenuation:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_attenuation2:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_fog:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds_ambient:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_physsky_exposition:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_clouds:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_physsky_star_power:GetName(), SetupTurbidity, shaderName )
	cvars.AddChangeCallback( cl_physsky_star_scale:GetName(), SetupTurbidity, shaderName )

	cvars.AddChangeCallback( cl_physsky_autosun:GetName(), function( convar_name, _, identifier )
		local state = identifier == "1"

		if state then
			function util.GetSunInfo()
				local t = old_GetSunInfo()
				t.sunColor = auto_sun_color
				t.overlayColor = auto_sun_color
				return t
			end
		else
			util.GetSunInfo = old_GetSunInfo -- reset
		end
	end, shaderName )

	cvars.AddChangeCallback( cl_physsky:GetName(), function( convar_name, _, identifier )
		local enable = identifier == "1"

		if enable then
			EnablePhysSky()
		else
			-- hook.Remove("PostDraw2DSkyBox", shaderName)
			hook.Remove("HUDPaint", shaderName)
			hook.Remove("PostDrawReconstruction", shaderName)
		end

		SetupTurbidity()

	end, shaderName )

	SetupTurbidity()

	if cl_physsky:GetBool() then EnablePhysSky() end
end

if RT_CLOUDSMASK then
	InitPhysicalSky()
end

hook.Add("PostCEFCodecFixStatus", shaderName, function()
	timer.Simple(0, function()
		InitPhysicalSky()
	end)
end)

-- Military Conflict: Vietnam maps fix
-- https://store.steampowered.com/app/1012110/Military_Conflict_Vietnam/

local function InitMCV()
	local map_name = game.GetMap()
	if !string.find(map_name, "mcv_") then return end

	local flags = 4 + 2097152 -- nodraw & tranclucent

    Material("tools/toolsocclusion"):SetInt("$flags", flags)
    Material("fog/fog_disc_2"):SetInt("$flags", flags)
    Material("fog/fog_disc_1"):SetInt("$flags", flags)
    Material("fog/fog_disc_1_bluish"):SetInt("$flags", flags)
    Material("fog/fog_disc_2_bluish"):SetInt("$flags", flags)
    Material("fog/fog_disc_2_orange"):SetInt("$flags", flags)
    Material("fog/fog_disc_1_orange"):SetInt("$flags", flags)
end

hook.Add("InitPostEntity", "MCV", InitMCV)


