
local hullscale = Vector(1, 1, 1)

util.AddNetworkString("ZB_ChooseSpecPly")
util.AddNetworkString("ZB_SpecMode")
util.AddNetworkString("ZB_SpectatePlayer") 

net.Receive("ZB_ChooseSpecPly", function(len, ply)
    if ply:Alive() then return end

    local key = net.ReadInt(32)
    local tbl = zb:CheckAlive()
    if #tbl == 0 then return end

    ply.chosenspect = ply.chosenspect and isnumber(ply.chosenspect) and ply.chosenspect or 1
    ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
    ply.viewmode = ply.viewmode or 1

    local prevEnt = ply.chosenSpectEntity

    if key == IN_ATTACK then
        ply.chosenspect = ply.chosenspect + 1
        if ply.chosenspect > #tbl then ply.chosenspect = 1 end
    elseif key == IN_ATTACK2 then
        ply.chosenspect = ply.chosenspect - 1
        if ply.chosenspect < 1 then ply.chosenspect = #tbl end
    elseif key == IN_RELOAD then
        ply.viewmode = (ply.viewmode % 3) + 1
    else
        return
    end

    ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
    ply.chosenSpectEntity = tbl[ply.chosenspect]
    if not IsValid(ply.chosenSpectEntity) then return end

    ply:SetNWEntity("spect", ply.chosenSpectEntity)
    ply:SetNWInt("viewmode", ply.viewmode)
    ply.lastSpectTarget = ply.chosenSpectEntity

    net.Start("ZB_SpectatePlayer")
    net.WriteEntity(ply.chosenSpectEntity)
    net.WriteEntity(IsValid(prevEnt) and prevEnt or NULL)
    net.WriteInt(ply.viewmode, 4)
    net.Send(ply)
end)

hook.Add("SetupPlayerVisibility", "spectPVS", function(ply, viewent)
    if ply:Alive() then return end

    local entity = ply.chosenSpectEntity
    if IsValid(entity) and not entity:TestPVS(ply) then
        AddOriginToPVS(entity:GetPos())
    end
end)

hook.Add("PlayerDeathThink", "spectNetwork", function(ply)
    if ply:Alive() then return end

    local ent = ply.chosenSpectEntity or player.GetAll()[1]
    if IsValid(ply) then
        ply:SetNWEntity("spect", ent)
        ply:SetNWInt("viewmode", ply.viewmode or 1)
        if IsValid(ent) then
            if ent.organism and ply.viewmode == 1 then
                if (ply.netsendtime or 0) < CurTime() then
                    ply.netsendtime = CurTime() + 1
                    hg.send_organism(ent.organism, ply)
                end
            end
            local entr = hg.GetCurrentCharacter(ent)
            local pos = ent:GetPos()

            if ply.viewmode ~= 3 then
                local currentPos = ply:GetPos()
                local targetPos = pos
                local distance = currentPos:Distance(targetPos)

                if distance > 100 or ply.lastSpectTarget ~= ent then
                    ply:SetPos(targetPos)
                    ply.lastSpectTarget = ent
                end
            end
        end

        if ply.viewmode == 3 then
            if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
                ply:SetMoveType(MOVETYPE_NOCLIP)
            end
            if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
                ply:Spectate(OBS_MODE_ROAMING)
            end
        else
            if ply:GetMoveType() == MOVETYPE_NOCLIP then
                ply:SetMoveType(MOVETYPE_WALK)
            end
        end
    end
end)

function GM:PlayerDeath(ply)
    ply.lastSpectTarget = nil
    ply.chosenSpectEntity = nil

    ply:Spectate(OBS_MODE_ROAMING)
    ply:SetHull(-hullscale, hullscale)
    ply:SetHullDuck(-hullscale, hullscale)

    ply.chosenspect = ply:EntIndex()
    ply.viewmode = 1

    timer.Simple(0.1, function()
        if IsValid(ply) and not ply:Alive() then
            local alivePlayers = zb:CheckAlive()
            if #alivePlayers > 0 then
                ply.chosenSpectEntity = alivePlayers[1]
                ply.chosenspect = 1
                ply:SetNWEntity("spect", ply.chosenSpectEntity)
                ply:SetNWInt("viewmode", ply.viewmode or 1)
                ply.lastSpectTarget = ply.chosenSpectEntity

                net.Start("ZB_SpectatePlayer")
                net.WriteEntity(ply.chosenSpectEntity)
                net.WriteEntity(NULL)
                net.WriteInt(ply.viewmode or 1, 4)
                net.Send(ply)
            end
        end
    end)
end

net.Receive("ZB_SpecMode", function(len, ply)
    local bool = net.ReadBool()
    local enable = not hook.Run("ZB_JoinSpectators", ply)

    if enable and bool and ply:Team() != TEAM_SPECTATOR then
        if ply:Alive() then ply:Kill() end
        ply:SetTeam(TEAM_SPECTATOR)
        PrintMessage(HUD_PRINTTALK, ply:Name() .. " joined the spectators.")
    elseif ply:Team() != 1 then
        ply:SetTeam(1)
    end
end)