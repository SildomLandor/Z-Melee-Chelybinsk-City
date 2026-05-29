hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

if not RNDX then
    include("homigrad/!libraries/4_client/cl_rndx.lua")
end

local CORNER_RADIUS = 16
local BASE_FLAGS = RNDX.SHAPE_IOS

function GetPrintName( self )
    local class = self:GetClass()
    local phrase = language.GetPhrase(class)
    return phrase ~= class and phrase or self:GetPrintName()
end

local Show = 0
local Transparent = 0
local LastSelectedSlot = 0
local LastSelectedSlotPos = 0

local SelectedSlot = 0
local SelectedSlotPos = 0

local GlitchLines = {}

function AddGlitchEffect(x, y, w, h)
    for i = 1, math.random(3, 5) do
        table.insert(GlitchLines, { x = x + math.Rand(2, w - 4), y = y + math.Rand(2, h - 2), width = math.Rand(w*0.2, w*0.7), height = math.Rand(1, 2), life = math.Rand(0.08, 0.2), spawnTime = CurTime(), offsetX = math.Rand(-15, 15), colorType = math.random(1, 3) })
    end
end

function DrawGlitchLines()
    local now = CurTime()
    local alpha = Transparent
    
    for i = #GlitchLines, 1, -1 do
        local g = GlitchLines[i]
        local lifeLeft = g.life - (now - g.spawnTime)
        
        if lifeLeft <= 0 then
            table.remove(GlitchLines, i)
        else
            local progress = 1 - (lifeLeft / g.life)
            local a = alpha * (1 - progress) * 230
            
            if g.colorType == 1 then
                surface.SetDrawColor(255, 255, 255, a)
                surface.DrawRect(g.x, g.y, g.width, g.height)
                
                surface.SetDrawColor(255, 50, 50, a * 0.6)
                surface.DrawRect(g.x + g.offsetX, g.y, g.width * 0.6, g.height)
                
            elseif g.colorType == 2 then
                surface.SetDrawColor(200, 20, 20, a)
                surface.DrawRect(g.x, g.y, g.width, g.height)
                
                surface.SetDrawColor(200, 200, 200, a * 0.5)
                surface.DrawRect(g.x - g.offsetX * 0.5, g.y, g.width * 0.4, g.height)
                
            else
                surface.SetDrawColor(0, 0, 0, a)
                surface.DrawRect(g.x, g.y, g.width, g.height)
                
                surface.SetDrawColor(200, 200, 200, a * 0.4)
                surface.DrawRect(g.x + g.offsetX * 0.3, g.y, g.width * 0.3, g.height)
            end
        end
    end
end

function DrawText(text, font, posX, posY, color, textAlign)
    draw.DrawText( text, font, posX + 2, posY + 2, ColorAlpha(color_black,Transparent*255) ,textAlign )
    draw.DrawText( text, font, posX, posY, ColorAlpha(color,Transparent*255) ,textAlign )
end

local function DrawTextInRect(text, font, posX, posY, rectX, rectY, rectW, rectH, color, textAlign)
    render.SetScissorRect(rectX, rectY, rectX + rectW, rectY + rectH, true)
    DrawText(text, font, posX, posY, color, textAlign)
    render.SetScissorRect(0, 0, 0, 0, false)
end

function GetSelectedWeapon()
    if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
    local Weapons = GetWeaponTable( LocalPlayer() )
    return Weapons[SelectedSlot] and Weapons[SelectedSlot][SelectedSlotPos] or Weapons[LastSelectedSlot][LastSelectedSlotPos] or Weapons[0][0]
end

function GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    local WeaponsGet = ply:GetWeapons()
    local FormatedTable = {
        [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
    }

    table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

    for k,wep in ipairs(WeaponsGet) do
        local tTbl = FormatedTable[wep.Slot or 0]
        local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
        local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
        tTbl[ iPos ] = wep
    end
    return FormatedTable
end

local scrW, scrH = ScrW(), ScrH()
local SCREEN_MARGIN = 12

local AcsentColor = Color(155,155,155)
local gradient_u = Material("vgui/gradient-d")

surface.CreateFont("HomigradFontTypewriterMedium", { font = "TrixiePro-Heavy", size = ScreenScale(8), weight = 500, antialias = true, extended = true })

surface.CreateFont("HomigradFontTypewriterSmall", { font = "TrixiePro-Heavy", size = 19, weight = 500, antialias = true, extended = true })

WeaponPositions = {}

function WeaponSelectorDraw( ply )
    if not IsValid( ply ) or not ply:Alive() then return end
    if Show < CurTime() then 
        SelectedSlot = LastSelectedSlot 
        SelectedSlotPos = -1
        
        return 
    end

    scrW, scrH = ScrW(), ScrH()

    local Weapons = GetWeaponTable( ply )
    local SelectedWep = GetSelectedWeapon()
    if not IsValid(SelectedWep) then return end
    Transparent = LerpFT( 0.2, Transparent, math.min( Show - CurTime(), 1 ) )
    
    WeaponPositions = {}
    
    local SuperAmmout = 0
    local AmmoutSlots = 0
    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        AmmoutSlots = AmmoutSlots + 1
    end

    local sizeX = scrW * 0.1
    local slotsTotalW = AmmoutSlots * sizeX
    local slotsStartX = math.Clamp(scrW * 0.5 - slotsTotalW * 0.5, SCREEN_MARGIN, scrW - slotsTotalW - SCREEN_MARGIN)

    for i = 0, #Weapons do
        local slotTbl = Weapons[i]
        if table.Count(slotTbl) < 1 then continue end
        local position = slotsStartX + SuperAmmout * sizeX
        
        DrawText( i+1, "HomigradFontTypewriterMedium", position + sizeX/2, scrH*0.02, ColorAlpha(color_white,Transparent*255) ,TEXT_ALIGN_CENTER )
        
        local Ammout = 0
        local lastPos = 0
        for Id = 0, #slotTbl do
            wepId = Id
            local wep = slotTbl[wepId]
            if not wep then continue end
            
            local sizeH = SelectedWep == wep and (scrH *0.12) or (scrH *0.025)
            local LastSelected = 0
            if slotTbl[wepId-1] and SelectedWep == slotTbl[wepId-1] then
                lastPos = (scrH *0.095) 
            end
            
            local weaponX = position
            local weaponY = (scrH * 0.025) * (Ammout) + (scrH * 0.05) + lastPos
            
            WeaponPositions[wep] = {x = weaponX,y = weaponY,w = sizeX,h = sizeH}
            
            RNDX.Draw(CORNER_RADIUS, weaponX, weaponY, sizeX, sizeH, ColorAlpha(color_black, Transparent * 205), BASE_FLAGS)
            
            if SelectedWep == wep then
                DrawGlitchLines()
            end
            
            if SelectedWep == wep then
                local gradTex = gradient_u:GetTexture("$basetexture")
                if gradTex then
                    RNDX.DrawTexture(CORNER_RADIUS, weaponX, weaponY, sizeX, sizeH, Color(100, 100, 100, Transparent * 200), gradTex, BASE_FLAGS)
                end
            end
            
            if SelectedWep == wep then
                RNDX.DrawOutlined(CORNER_RADIUS, weaponX, weaponY, sizeX, sizeH, Color(180, 180, 180, Transparent * 155), 2, BASE_FLAGS)
            end
            
            local sizeHi = weaponY + 2.5
            
            local textColor = ColorAlpha(color_white,Transparent*255)
            if SelectedWep == wep then
                local time = CurTime()
                local trigger = math.sin(time * 0.5)
                if trigger > 0.8 then
                     local t = (math.sin(time * 30) + 1) / 2
                     local gb = 255 * (1 - t)
                     textColor = ColorAlpha(Color(255, gb, gb), Transparent*255)
                end
            end

            DrawTextInRect(
                GetPrintName(wep),
                "HomigradFontTypewriterSmall",
                position + sizeX / 2,
                sizeHi,
                position,
                sizeHi,
                sizeX,
                math.max(sizeH - 4, 14),
                textColor,
                TEXT_ALIGN_CENTER
            )
            Ammout = Ammout + 1

            if SelectedWep == wep and wep.DrawWeaponSelection then
                wep:DrawWeaponSelection(position + 5, (scrH * 0.025) * (Ammout) + (scrH * 0.055) + lastPos, sizeX - 10, sizeH, Transparent*255)
            end
        end
        SuperAmmout = SuperAmmout + 1
    end
end

local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    SelectedSlot = SelectedSlot < 0 and #Weapons or SelectedSlot - 1
    SelectedSlotPos = Weapons[SelectedSlot] and #Weapons[SelectedSlot] or 0

    if Weapons[SelectedSlot] == nil or Weapons[SelectedSlot][SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end

end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    SelectedSlot = SelectedSlot > #Weapons and 0 or SelectedSlot + 1
    SelectedSlotPos = 0

    if Weapons[SelectedSlot] == nil or Weapons[SelectedSlot][SelectedSlotPos] == nil then
        GetDown(Weapons)
    end

end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100)
end

function ChangeSelectionWep( ply, key )
    if not IsValid( ply ) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end
    
    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        local Weapons = GetWeaponTable( ply )
        local oldSelectedWep = GetSelectedWeapon()

        Show = CurTime() + 4
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then 
                SelectedSlotPos = -1
            end
            SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            SelectedSlot = iPos
            LastSelected = iPos
        elseif key == "invprev" then
            SelectedSlotPos = SelectedSlotPos - 1
            if Weapons[SelectedSlot] and SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
        elseif key == "invnext" then
            SelectedSlotPos = SelectedSlotPos + 1
            if Weapons[SelectedSlot] and SelectedSlotPos > #Weapons[SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(LastInv) then
            Show = 0
            LastInv = LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( LastInv )
            LastInv = oldwep
        end
        
        local newSelectedWep = GetSelectedWeapon()
        if newSelectedWep then
            timer.Simple(0, function()
                local wepPos = WeaponPositions[newSelectedWep]
                if wepPos then
                    AddGlitchEffect(wepPos.x, wepPos.y, wepPos.w, wepPos.h)
                end
            end)
        end
    end
end

function SetActuallyWeapon( ply, cmd )
    if not IsValid( ply ) or not ply:Alive() then return end
    if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and Show > CurTime() then

        if Selected and Selected > CurTime() then 
            cmd:RemoveKey(IN_ATTACK) 
            cmd:RemoveKey(IN_ATTACK2) 
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 
            
            if IsValid(GetSelectedWeapon()) then
                LastInv = LastInv ~= ply:GetActiveWeapon() and LastInv or ply:GetActiveWeapon()
                
                local selectedWep = GetSelectedWeapon()
                local wepPos = WeaponPositions[selectedWep]
                if wepPos then
                    AddGlitchEffect(wepPos.x, wepPos.y, wepPos.w, wepPos.h)
                end
                
                input.SelectWeapon( GetSelectedWeapon() )
            end
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2) 

            LastSelectedSlot = SelectedSlot
            LastSelectedSlotPos = SelectedSlotPos
            Selected = CurTime() + 0.2
            Show = CurTime() + 0.2
            surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", SetActuallyWeapon )

function WS.IsOpen()
	return Show > CurTime()
end

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)