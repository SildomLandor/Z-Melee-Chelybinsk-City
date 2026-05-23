--
zb = zb or {}
zb.Experience = zb.Experience or {}

local EXP = zb.Experience
EXP.OpenedAccount = EXP.OpenedAccount or nil

local wantProfile = false

net.Receive("zb_xp_get", function()
    local ply = net.ReadEntity()
    ply.skill = net.ReadFloat()
    ply.exp = net.ReadInt(19)

    if not wantProfile then return end
    wantProfile = false

    if IsValid(EXP.OpenedAccount) then EXP.OpenedAccount:Remove() end
    EXP.OpenedAccount = vgui.Create("ZB_AccountFrame")
    EXP.OpenedAccount:MakePopup()
    EXP.OpenedAccount:SetPlayer(ply)
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
