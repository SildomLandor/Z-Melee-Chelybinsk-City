util.AddNetworkString("HG_SuicideCutscene")
util.AddNetworkString("HG_SuicideCancel")

concommand.Add("suicide", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNWBool("suiciding") or ply.suiciding then return end
    if ply.suicideCutscene then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        ply:ChatPrint("Я... не могу закончить этим...")
        return
    end

    if wep.ishgweapon and wep:Clip1() <= 0 then
        ply:ChatPrint("Пусто...")
        return
    end

    ply.suicideCutscene = true
    ply.suicideCutsceneWep = wep

    net.Start("HG_SuicideCutscene")
    net.WriteBool(true)
    net.Send(ply)

    timer.Simple(4.0, function()
        if not IsValid(ply) or not ply:Alive() or not ply.suicideCutscene then return end
        local activeWep = ply:GetActiveWeapon()
        if IsValid(ply.suicideCutsceneWep) and activeWep == ply.suicideCutsceneWep then
            ply:SetNWBool("suiciding", true)
            ply.suiciding = true
            ply.startsuicide = CurTime()
        else
            ply.suicideCutscene = false
            ply.suicideCutsceneWep = nil
            net.Start("HG_SuicideCutscene")
            net.WriteBool(false)
            net.Send(ply)
        end
    end)

    timer.Simple(7.5, function()
        if not IsValid(ply) or not ply:Alive() or not ply.suicideCutscene then return end
        local activeWep = ply:GetActiveWeapon()
        if IsValid(ply.suicideCutsceneWep) and activeWep == ply.suicideCutsceneWep then
            if activeWep.ismelee or activeWep.CanSuicide then
                if activeWep.CanSuicide and ply.suiciding then
                    activeWep.SuicideRequest = false
                end
            end
        end
    end)
end)

net.Receive("HG_SuicideCancel", function(len, ply)
    if not IsValid(ply) or not ply.suicideCutscene then return end
    ply.suicideCutscene = false
    ply.suicideCutsceneWep = nil
    ply:SetNWBool("suiciding", false)
    ply.suiciding = false
    ply.startsuicide = nil

    net.Start("HG_SuicideCutscene")
    net.WriteBool(false)
    net.Send(ply)
end)

hook.Add("PlayerDeath", "HG_ResetSuicideCutscene", function(ply)
    if ply.suicideCutscene then
        ply.suicideCutscene = false
        ply.suicideCutsceneWep = nil
        net.Start("HG_SuicideCutscene")
        net.WriteBool(false)
        net.Send(ply)
    end
    ply:SetNWBool("suiciding", false)
    ply.suiciding = false
    ply.startsuicide = nil
end)

hook.Add("PlayerSpawn", "HG_ResetSuicideCutsceneSpawn", function(ply)
    ply:SetNWBool("suiciding", false)
    ply.suiciding = false
    ply.startsuicide = nil
    ply.suicideCutscene = false
    ply.suicideCutsceneWep = nil
    net.Start("HG_SuicideCutscene")
    net.WriteBool(false)
    net.Send(ply)
end)

hook.Add("PlayerSwitchWeapon", "HG_SuicideCutscene_NoSwitch", function(ply, oldWep, newWep)
    if ply.suicideCutscene then
        return true
    end
end)