require("niknaks")

local shaderName = "SSSS"

local pp_ssss               = CreateClientConVar( "pp_ssss", "0", true, false, "Enable/Disable screen space sun shafts.", 0, 1 )
local pp_ssss_debug         = CreateClientConVar( "pp_ssss_debug", "0", false, false, "Enable/Disable screen space sun shafts debug mode.", 0, 1 )
local pp_ssss_densitymode   = CreateClientConVar( "pp_ssss_densitymode", "1", true, false, "Enable/Disable fod Density value.", 0, 1 )
local pp_ssss_sunscale      = CreateClientConVar( "pp_ssss_sunscale", "5", true, false, "SSSS sun scale.", 0.5, 20 )
local pp_ssss_density       = CreateClientConVar( "pp_ssss_density", "0", true, false, "SSSS density.", 0, 1 )
local pp_ssss_decay         = CreateClientConVar( "pp_ssss_decay", "1", true, false, "SSSS decay.", 0, 1 )
local pp_ssss_weight        = CreateClientConVar( "pp_ssss_weight", "0", true, false, "SSSS weight.", 0, 1 )
local pp_ssss_exposure      = CreateClientConVar( "pp_ssss_exposure", "0", true, false, "SSSS exposure.", 0, 1 )
local pp_ssss_quality       = CreateClientConVar( "pp_ssss_quality", "4", true, false, "SSSS quality.", 1, 4 )
local pp_ssss_ultra_downsampling       = CreateClientConVar( "pp_ssss_ultra_downsampling", "0", true, false, "SSSS ultra down sampling as quad resolution.", 0, 1 )

local screentexture = render.GetScreenEffectTexture()

local ssss_mats = {
    Material("pp/ssss_ultra");
    Material("pp/ssss_high");
    Material("pp/ssss_medium");
    Material("pp/ssss_low");
}

local ssss_mat = ssss_mats[1] -- init
local ssss_mask_mat = Material("pp/ssss_mask")
local ssss_filter_h = Material("pp/ssss_filter_h")
local ssss_filter_v = Material("pp/ssss_filter_v")
local ultra_downsampling = pp_ssss_ultra_downsampling:GetBool()
local upsample_mat = ultra_downsampling and Material("pp/ssss_upsample_quad") or Material("pp/ssss_upsample_half")

local function InitSSSS()
    local rt_flags = render.GetHDREnabled() and CREATERENDERTARGETFLAGS_HDR or 0

    local rt_godrays = GetRenderTargetEx("_rt_godrays_mask", ScrW(), ScrH(),
        RT_SIZE_FULL_FRAME_BUFFER,
        MATERIAL_RT_DEPTH_NONE,
        --bit.bor(4, 8, 16, 256, 512, 32768, 8388608),
        bit.bor(4, 8, 256, 512),
        rt_flags,
        IMAGE_FORMAT_BGRX8888
        --IMAGE_FORMAT_RGB565
    )
    
    local rt_sun
    
    local rt_size = ultra_downsampling and 0.25 or 0.5
    
    local function CreateRT()
        rt_sun = GetRenderTargetEx("_rt_SSSS", ScrW() * rt_size, ScrH() * rt_size,
            RT_SIZE_LITERAL,
            MATERIAL_RT_DEPTH_NONE,
            bit.bor(16, 4, 8, 256, 512),
            rt_flags,
            IMAGE_FORMAT_RGBA16161616F
        )
    end

    CreateRT()

    local ultra = pp_ssss_quality:GetInt() == 1
    local high = pp_ssss_quality:GetInt() == 2

    local function SSSSEnable()
        local ply = LocalPlayer()

        if !GSHADER then
            LocalPlayer():ChatPrint( "(Missing addon GShader library) Please install GShader library to correctly work of SSAO https://steamcommunity.com/sharedfiles/filedetails/?id=3542644649." )
            return
        end

        if !GetConVar("r_shaderlib"):GetBool() then  RunConsoleCommand("r_shaderlib", 1) end
        if !GetConVar("r_shaderlib_depthbuffer"):GetBool() then  RunConsoleCommand("r_shaderlib_depthbuffer", 1) end

        local sun = util.GetSunInfo()
        if ( !sun ) then
            LocalPlayer():ChatPrint( "(SSSS) Sun in invalid." )
            return
        end

        local texs = {}
        local function getTex(str)
            if texs[str] then return texs[str] end
            local mat = Material(str)
            if mat and !mat:IsError() then
                texs[str] = Material(str):GetTexture("$basetexture")
            end
            return texs[str]
        end

        local Sun = ents.FindByClass("*_Sun")[1]

        hook.Add("RenderScreenspaceEffects", shaderName, function()
            if !shaderlib.CanDrawEffects() then return end
            local sun = util.GetSunInfo()
            if ( !sun ) then return end
            if !sun.enabled then return end

            local eyepos = EyePos()

            local sky_visible = util.IsSkyboxVisibleFromPoint(eyepos)
            if !sky_visible then return end

            local dir = sun.direction 
            -- если солнце в закате, то шейдер можно не рассчитывать

            local sunPos = eyepos + dir * 100000

            local sp = sunPos:ToScreen()

            if !sp.visible then return end

            local scrw, scrh = ScrW(), ScrH()

            local sp_normalized = {
                x = sp.x / scrw;
                y = sp.y / scrh;
            }

            local col = sun.sunColor -- or Sun:GetColor()
            local overlayColor = sun.overlayColor -- or Sun:GetColor()

            local sun_scale = pp_ssss_sunscale:GetFloat()

            local size = 100 - math.min(98, sun.sunSize)
            size = 1 / size * 2 * sun_scale
            ssss_mask_mat:SetFloat("$c0_x",  sun.sunSize == 0 and 0 or size )

            local size2 = 100 - math.min(99, sun.overlaySize)
            size2 = 1 / size2 * 4 * sun_scale
            ssss_mask_mat:SetFloat("$c0_y",  sun.overlaySize == 0 and 0 or size2 )

            ssss_mask_mat:SetFloat("$c2_x", col.r / 255)
            ssss_mask_mat:SetFloat("$c2_y", col.g / 255)
            ssss_mask_mat:SetFloat("$c2_z", col.b / 255)

            ssss_mask_mat:SetFloat("$c3_x", overlayColor.r / 255)
            ssss_mask_mat:SetFloat("$c3_y", overlayColor.g / 255)
            ssss_mask_mat:SetFloat("$c3_z", overlayColor.b / 255)

            local aspect = scrh / scrw
            ssss_mask_mat:SetFloat("$c0_z", aspect )
            ssss_mask_mat:SetFloat("$c1_x", sp_normalized.x)
            ssss_mask_mat:SetFloat("$c1_y", sp_normalized.y)

            -- нужно сестать стандартный
            local tex = getTex( sun.sunMaterial )
            if tex then
                ssss_mask_mat:SetTexture("$texture1", tex )
            end

            local tex = getTex( sun.overlayMaterial )
            if tex then
                ssss_mask_mat:SetTexture("$texture2", tex )
            end

            render.UpdateScreenEffectTexture()
            render.CopyRenderTargetToTexture(screentexture)
            
            render.PushRenderTarget(rt_godrays)
                render.Clear(0,0,0,0)
                if RT_CLOUDSMASK then
                    render.ClearDepth()
                    render.ClearStencil()
                end

                render.SetMaterial(ssss_mask_mat)
                render.DrawScreenQuad()

                if RT_CLOUDSMASK then
                    render.OverrideBlend(true,BLEND_ONE,BLEND_ONE,BLENDFUNC_REVERSE_SUBTRACT)
                    render.DrawTextureToScreen(RT_CLOUDSMASK)
                    render.OverrideBlend(false)
                end
            render.PopRenderTarget()

            local debug_mode = pp_ssss_debug:GetBool()

            ssss_mat:SetFloat("$c1_x", sp_normalized.x)
            ssss_mat:SetFloat("$c1_y", sp_normalized.y)

            local Density = pp_ssss_densitymode:GetBool() and render.GetFogMaxDensity() or pp_ssss_density:GetFloat()
            ssss_mat:SetFloat("$c2_x", Density)

            if !ultra then
                render.PushRenderTarget(rt_sun)
                    render.Clear(0,0,0,0)

                    render.SetMaterial(ssss_mat)
                    render.DrawScreenQuad()
                    
                    if !high then
                        render.SetMaterial(ssss_filter_v)
                        render.DrawScreenQuad()

                        render.SetMaterial(ssss_filter_h)
                        render.DrawScreenQuad()
                    end
                render.PopRenderTarget()
            end

            if !debug_mode then
                render.OverrideBlend(true, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
            end
                if !ultra then
                    render.SetMaterial(upsample_mat)
                    render.DrawScreenQuad()
                else
                    render.SetMaterial(ssss_mat)
                    render.DrawScreenQuad()
                end
            render.OverrideBlend(false)

            if debug_mode then
                cam.Start2D()
                    draw.DrawText(sp.x .. " " .. sp.y, "BudgetLabel", 500, 500)
                    surface.SetDrawColor(255,255,255)
                    local x,y,w,h = sp.x - 2, sp.y - 2, 4, 4
                    surface.DrawRect(x,y,w,h)
                    surface.SetDrawColor(0,0,0)
                    surface.DrawOutlinedRect(x,y,w,h)
                cam.End2D()
            end
        end )
    end

    cvars.AddChangeCallback( pp_ssss:GetName(), function( convar_name, _, identifier )
        local state = identifier == "1"

        if state then
            SSSSEnable()
        else
            hook.Remove("RenderScreenspaceEffects", shaderName)
        end
    end, shaderName )

    local range = 0.1
    local start = 1 - range

    cvars.AddChangeCallback( pp_ssss_decay:GetName(), function( convar_name, _, identifier )
        ssss_mat:SetFloat("$c2_y", start + tonumber(identifier) * range )
    end, shaderName )

    cvars.AddChangeCallback( pp_ssss_weight:GetName(), function( convar_name, _, identifier )
        ssss_mat:SetFloat("$c2_z", identifier)
    end, shaderName )

    cvars.AddChangeCallback( pp_ssss_exposure:GetName(), function( convar_name, _, identifier )
        ssss_mat:SetFloat("$c2_w", identifier)
    end, shaderName )

    local function InitMat()
        ssss_mat:SetFloat("$c2_y", start + pp_ssss_decay:GetFloat() * range )
        ssss_mat:SetFloat("$c2_z", pp_ssss_weight:GetFloat() )
        ssss_mat:SetFloat("$c2_w", pp_ssss_exposure:GetFloat() )
    end

    cvars.AddChangeCallback( pp_ssss_quality:GetName(), function( convar_name, _, identifier )
        local i = tonumber(identifier)
        ultra = i == 1
        high = i == 2
        ssss_mat = ssss_mats[i]

        InitMat()
    end, shaderName )

    timer.Simple(0, function()
        
        if pp_ssss:GetBool() then SSSSEnable() end
        ssss_mat = ssss_mats[pp_ssss_quality:GetInt()]
        InitMat()
    end)

    SSSS_INITED = true
end

if SSSS_INITED then
    InitSSSS()
end

hook.Add("PostCEFCodecFixStatus", shaderName, InitSSSS)


