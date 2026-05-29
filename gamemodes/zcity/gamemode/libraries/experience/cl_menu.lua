--
zb = zb or {}
zb.Experience = zb.Experience or {}

local EXP = zb.Experience
EXP.OpenedAccount = EXP.OpenedAccount or nil

local wantProfile = false
local nextBulkRequest = 0

local function applyXp(ply, skill, exp)
    if not IsValid(ply) then return end
    ply.skill = skill
    ply.exp = exp
end

net.Receive("zb_xp_get", function()
    local ply = net.ReadEntity()
    applyXp(ply, net.ReadFloat(), net.ReadInt(19))
    hook.Run("ZB_XP_Updated", ply)

    if not wantProfile then return end
    wantProfile = false

    if IsValid(EXP.OpenedAccount) then EXP.OpenedAccount:Remove() end
    EXP.OpenedAccount = vgui.Create("ZB_AccountFrame")
    EXP.OpenedAccount:MakePopup()
    EXP.OpenedAccount:SetPlayer(ply)
end)

net.Receive("zb_xp_get_all", function()
    local n = net.ReadUInt(8)
    for i = 1, n do
        applyXp(net.ReadEntity(), net.ReadFloat(), net.ReadInt(19))
    end
    hook.Run("ZB_XP_Updated")
end)

function EXP.OpenMenu(ply)
    net.Start("zb_xp_get")
        net.WriteEntity(ply)
    net.SendToServer()
end

function EXP.AccountMenu(ply)
    wantProfile = true
    EXP.OpenMenu(ply)
end

function EXP.RequestAll()
    if nextBulkRequest > CurTime() then return end
    nextBulkRequest = CurTime() + 0.4
    net.Start("zb_xp_get_all")
    net.SendToServer()
end

function EXP.RequestMissing()
    for _, ply in player.Iterator() do
        if IsValid(ply) and ply.exp == nil then
            EXP.RequestAll()
            return
        end
    end
end
