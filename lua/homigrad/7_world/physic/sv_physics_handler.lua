if not hg.physCrazy then
	print("sv_physics_handler.lua:у тя мамы нету\n")
	return
end

local scanDt = 0.15
local scanN = 32
local panicN = 350

local restarting = false
local winT, winN = 0, 0

local kinds = {"prop_physics", "prop_physics_multiplayer", "prop_ragdoll"}
local idx = {1, 1, 1}

local function panic(ent, why)
	if not IsValid(ent) then return end

	hook.Run("OnCrazyPhysics", ent, ent:GetPhysicsObject(), why)

	if hg.physPlayerRag(ent) then return end

	local t = CurTime()
	if t > winT then
		winT = t + 1
		winN = 1
	else
		winN = winN + 1
	end

	if winN < panicN or physenv.GetPhysicsPaused() then return end
	physenv.SetPhysicsPaused(true)
end

local function scan()
	for ki = 1, #kinds do
		local list = ents.FindByClass(kinds[ki])
		local n = #list
		if n < 1 then continue end

		local c = idx[ki]
		for _ = 1, math.min(scanN, n) do
			if c > n then c = 1 end

			local ent = list[c]
			c = c + 1

			if not IsValid(ent) or ent:IsPlayer() then continue end

			local why = hg.physCrazy(ent)
			if why then
				panic(ent, why)
			elseif ent.hg_physHits and ent.hg_physHits > 0 then
				ent.hg_physHits = ent.hg_physHits - 1
			end
		end

		idx[ki] = c
	end
end

timer.Create("hg_phys_scan", scanDt, 0, scan)

hook.Add("Tick", "hg_phys_restart", function()
	if not physenv.GetPhysicsPaused() or restarting then return end

	restarting = true
	PrintMessage(HUD_PRINTTALK, "физике пиздец, карта перезагрузится через 10 секунд")

	timer.Create("hg_phys_restart", 10, 1, function()
		engine.CloseServer()
		timer.Simple(0, function()
			RunConsoleCommand("changelevel", game.GetMap())
		end)
	end)
end)

hook.Add("PostCleanupMap", "hg_phys_reset", function()
	restarting = false
	winT, winN = 0, 0
	idx[1], idx[2], idx[3] = 1, 1, 1

	if physenv.GetPhysicsPaused() then
		physenv.SetPhysicsPaused(false)
	end
end)
