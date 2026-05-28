zb.afk = zb.afk or {}

local afkNet = "zb_afk_state"
local reportDelay = 1
local idleDelay = 12
local timeoutDelay = 10
local spawnGrace = 20

if SERVER then
	util.AddNetworkString(afkNet)

	local function SetAfk(ply, afk, minimized)
		if not IsValid(ply) then return end
		ply:SetNWBool("ZB_AFK", afk and true or false)
		ply:SetNWBool("ZB_AFK_Minimized", minimized and true or false)
	end

	net.Receive(afkNet, function(_, ply)
		if not IsValid(ply) or ply:IsBot() then return end

		local afk = net.ReadBool()
		local minimized = net.ReadBool()
		if ply:Team() == TEAM_SPECTATOR then
			afk = false
			minimized = false
		end

		ply.zbAFKLastReport = CurTime()
		SetAfk(ply, afk, minimized)
	end)

	hook.Add("PlayerInitialSpawn", "zb_afk_init", function(ply)
		ply.zbAFKLastReport = CurTime()
		SetAfk(ply, false, false)
	end)

	hook.Add("PlayerSpawn", "zb_afk_clear_on_spawn", function(ply)
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
			if ply:Team() == TEAM_SPECTATOR then
				SetAfk(ply, false, false)
				continue
			end
			if now - (ply.zbAFKLastReport or 0) <= timeoutDelay then continue end
			SetAfk(ply, true, true)
		end
	end)
else
	local lastActive = CurTime()
	local lastAfk
	local lastMinimized
	local graceUntil = 0
	local wasAlive = false

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

	timer.Create("zb_afk_report", reportDelay, 0, function()
		local lp = LocalPlayer()
		if not IsValid(lp) or lp:IsBot() then return end

		local alive = lp:Alive()
		if alive and not wasAlive then
			graceUntil = CurTime() + spawnGrace
			Touch()
		end
		wasAlive = alive

		local spectator = lp:Team() == TEAM_SPECTATOR
		local minimized = system and system.HasFocus and not system.HasFocus() or false
		local afk = false
		if not spectator then
			afk = minimized or (CurTime() >= graceUntil and CurTime() - lastActive >= idleDelay)
		end

		if lastAfk == afk and lastMinimized == minimized then return end

		lastAfk = afk
		lastMinimized = minimized

		net.Start(afkNet)
		net.WriteBool(afk)
		net.WriteBool(minimized)
		net.SendToServer()
	end)
end
