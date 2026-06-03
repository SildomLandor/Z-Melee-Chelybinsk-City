--
zb = zb or {}

zb.Experience = zb.Experience or {}

zb.Experience.SkillMedals = {
    {
        icon = Material("vgui/mats_jack_awards/pt"),
        name = "Pt",
        skill = { 4.6, 99999999999999 }
    },
    {
        icon = Material("vgui/mats_jack_awards/au"),
        name = "Au",
        skill = { 3.7, 4.6 }
    },
    {
        icon = Material("vgui/mats_jack_awards/pd"),
        name = "Pd",
        skill = { 2.9, 3.7 }
    },
    {
        icon = Material("vgui/mats_jack_awards/ir"),
        name = "Ir",
        skill = { 2.2, 2.9 }
    },
    {
        icon = Material("vgui/mats_jack_awards/os"),
        name = "Os",
        skill = { 1.6, 2.2 }
    },
    {
        icon = Material("vgui/mats_jack_awards/ru"),
        name = "Ru",
        skill = { 1.1, 1.6 }
    },
    {
        icon = Material("vgui/mats_jack_awards/ag"),
        name = "Ag",
        skill = { .7, 1.1 }
    },
    {
        icon = Material("vgui/mats_jack_awards/sn"),
        name = "Sn",
        skill = { .4, .7 }
    },
    {
        icon = Material("vgui/mats_jack_awards/ni"),
        name = "Ni",
        skill = { .2, .4 }
    },
    {
        icon = Material("vgui/mats_jack_awards/cu"),
        name = "Cu",
        skill = { 0, .2 }
    },
}

local SHTable = zb.Experience
zb.Experience.UI = zb.Experience.UI or {}

function zb.Experience.GetAwards( self )
    local skill = self.skill
    local exp = self.exp
    --print(skill,exp)
    --print(MedalTab.skill[1])
    local Medal = nil
    for i = 1, #SHTable.SkillMedals do
        local MedalTab = SHTable.SkillMedals[i]
        if skill >= tonumber( MedalTab.skill[1] ) and skill < tonumber( MedalTab.skill[2] ) then 
            Medal = table.Copy( MedalTab )
            break 
        end
    end

    local Band = nil
    for i = 1, #SHTable.Bands do
        local BandTab = SHTable.Bands[i]
        if exp >= tonumber( BandTab.skill[1] ) and exp < tonumber( BandTab.skill[2] ) then 
            Band = table.Copy( BandTab )
            break 
        end
    end
    

    return Band, Medal
end


local plyMeta = FindMetaTable("Player")

function plyMeta:GetAwards()
    if CLIENT then
        net.Start("zb_xp_get")
            net.WriteEntity(self)
        net.SendToServer()
    end
    return zb.Experience.GetAwards( self )
end

function plyMeta:GetStatVal(dataName, fallback)
    if not CLIENT then return end
    net.Start("get_svPData")
        net.WriteEntity( self )
        net.WriteString( dataName )
    net.SendToServer()
    if self.SvDB and self.SvDB[dataName] then
        return self.SvDB[dataName] 
    end
    return fallback
end

if SERVER then
    util.AddNetworkString("get_svPData")

    net.Receive( "get_svPData", function( len, ply )
        local ent = net.ReadEntity()
        local dataName = net.ReadString()
        if not ent["Get"..dataName] then return end
        net.Start("get_svPData")
            net.WriteEntity( ent )
            net.WriteString( dataName )
            net.WriteFloat( ent["Get"..dataName] and ent["Get"..dataName](ent) or 0 )
        net.Send(ply)
    end)

    hook.Add("PlayerDeath","ZB_GiveKills", function(ply)
        timer.Simple(.1,function()
            if not IsValid(ply) then return end
            local most_harm,biggest_attacker = 0,nil
                --print(ply)
            for attacker,attacker_harm in pairs(zb.HarmDone[ply] or {}) do
                --print(attacker)
                if not IsValid(attacker) then continue end
                if most_harm < attacker_harm then
                    most_harm = attacker_harm
                    biggest_attacker = attacker
                end
            end
            ply:GiveDeaths(1)
            if IsValid(biggest_attacker) then
                if biggest_attacker == ply then
                    biggest_attacker:GiveSuicides(1)
                else
                    biggest_attacker:GiveKills(1)
                end
            end
        end)
    end)
else
    local UI = zb.Experience.UI
    UI.col = {
        frameBG = Color(10, 10, 19, 235),
        frameBorder = Color(90, 90, 95, 120),
        panelBG = Color(8, 8, 16, 245),
        panelBorder = Color(255, 255, 255, 25),
        text = Color(200, 200, 200, 255),
        textDim = Color(160, 160, 165, 180),
        textMuted = Color(100, 100, 108, 140),
        textTitle = Color(200, 200, 200, 255),
        textBlood = Color(180, 40, 35, 255),
        accent = Color(200, 200, 200, 60),
        accentDim = Color(255, 255, 255, 15),
        separator = Color(255, 255, 255, 12),
        scrollTrack = Color(255, 255, 255, 6),
        scrollGrip = Color(200, 200, 200, 60),
        scrollGripHov = Color(200, 200, 200, 100),
        rowAlt = Color(255, 255, 255, 4),
    }
    UI.NoiseMat = Material("vgui/noisevhs")
    if UI.NoiseMat:IsError() then UI.NoiseMat = Material("vgui/white") end

    function UI.StyleScrollbar(sbar)
        if not IsValid(sbar) then return end
        local col = UI.col
        sbar:SetHideButtons(true)
        sbar.Paint = function(_, sw, sh)
            surface.SetDrawColor(col.scrollTrack)
            surface.DrawRect(0, 0, sw, sh)
        end
        sbar.btnGrip.Paint = function(btn, sw, sh)
            surface.SetDrawColor(btn:IsHovered() and col.scrollGripHov or col.scrollGrip)
            surface.DrawRect(2, 0, sw - 4, sh)
        end
    end

    function UI.PaintNoiseOverlay(w, h, col, a)
        if UI.NoiseMat:IsError() then return end
        surface.SetMaterial(UI.NoiseMat)
        surface.SetDrawColor(255, 255, 255, a or 6)
        local u, v = math.random(0, 512), math.random(0, 512)
        surface.DrawTexturedRectUV(0, 0, w, h, u / 512, v / 512, u / 512 + w / 768, v / 512 + h / 768)
        for y = 0, h, 3 do
            surface.SetDrawColor(0, 0, 0, 12)
            surface.DrawRect(0, y, w, 1)
        end
        surface.SetDrawColor(col.frameBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    net.Receive( "get_svPData", function()
        local ent = net.ReadEntity()
        local dataName = net.ReadString()
        local dataType = net.ReadFloat()
        ent.SvDB = ent.SvDB or {}
        ent.SvDB[dataName] = dataType
        if IsValid(zb.Experience.OpenedAccount) and isfunction(zb.Experience.OpenedAccount.Update) then
            zb.Experience.OpenedAccount:Update(ent)
        end
   
    end)
end