zb.afk = zb.afk or {}

if SERVER then
	util.AddNetworkString("zb_afk_state")

	local function SetAfk(ply, afk, minimized)
		if not IsValid(ply) then return end
		ply:SetNWBool("ZB_AFK", afk and true or false)
		ply:SetNWBool("ZB_AFK_Minimized", minimized and true or false)
	end

	net.Receive("zb_afk_state", function(_, ply)
		if not IsValid(ply) or ply:IsBot() then return end

		local afk = net.ReadBool()
		local minimized = net.ReadBool()

		ply.zbAFKLastReport = CurTime()
		SetAfk(ply, afk, minimized)
	end)

	hook.Add("PlayerInitialSpawn", "zb_afk_init", function(ply)
		ply.zbAFKLastReport = CurTime()
		SetAfk(ply, false, false)
	end)

	hook.Add("PlayerDisconnected", "zb_afk_cleanup", function(ply)
		ply.zbAFKLastReport = nil
	end)

	timer.Create("zb_afk_timeout_check", 2, 0, function()
		local now = CurTime()
		for _, ply in player.Iterator() do
			if not IsValid(ply) or ply:IsBot() then continue end
			if now - (ply.zbAFKLastReport or 0) <= 6 then continue end
			SetAfk(ply, true, true)
		end
	end)
else
	local lastActive = CurTime()
	local lastAfk
	local lastMinimized

	local function Touch()
		lastActive = CurTime()
	end

	hook.Add("CreateMove", "zb_afk_input", function(cmd)
		if cmd:GetButtons() == 0 and cmd:GetMouseX() == 0 and cmd:GetMouseY() == 0 then return end
		Touch()
	end)

	hook.Add("PlayerBindPress", "zb_afk_bind", function()
		Touch()
	end)

	hook.Add("OnContextMenuOpen", "zb_afk_ctx_open", Touch)
	hook.Add("OnContextMenuClose", "zb_afk_ctx_close", Touch)
	hook.Add("StartChat", "zb_afk_chat_start", Touch)
	hook.Add("FinishChat", "zb_afk_chat_finish", Touch)

	timer.Create("zb_afk_report", 1, 0, function()
		local lp = LocalPlayer()
		if not IsValid(lp) or lp:IsBot() then return end

		local minimized = system and system.HasFocus and not system.HasFocus() or false
		local afk = minimized or CurTime() - lastActive >= 12

		if lastAfk == afk and lastMinimized == minimized then return end

		lastAfk = afk
		lastMinimized = minimized

		net.Start("zb_afk_state")
		net.WriteBool(afk)
		net.WriteBool(minimized)
		net.SendToServer()
	end)
end
