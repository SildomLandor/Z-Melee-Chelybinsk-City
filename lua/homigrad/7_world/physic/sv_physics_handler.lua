if not hg.physCrazy then
	print("sv_physics_handler.lua:у тя мамы нету\n")
	return
end

local scanDt = 0.15
local scanN = 32
local panicN = 350
local ragDv = 2200
local ragDa = 4200

local restarting = false
local winT, winN = 0, 0

local kinds = {"prop_physics", "prop_physics_multiplayer"}
local idx = {1, 1}

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

hook.Add("Tick", "hg_phys_rag_realtime", function()
	local t = CurTime()

	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
		if not IsValid(ent) then continue end

		local why = hg.physCrazy(ent)
		if why then
			panic(ent, why)
			continue
		end

		local vm, am = 0, 0
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local po = ent:GetPhysicsObjectNum(i)
			if not IsValid(po) then continue end
			vm = math.max(vm, po:GetVelocity():Length())
			am = math.max(am, po:GetAngleVelocity():Length())
		end

		local pv = ent.hg_ragVm
		local pa = ent.hg_ragAm
		local pt = ent.hg_ragT
		ent.hg_ragVm = vm
		ent.hg_ragAm = am
		ent.hg_ragT = t

		if not pt then continue end
		if t - pt > 0.06 then continue end
		if math.abs(vm - pv) > ragDv or math.abs(am - pa) > ragDa then
			panic(ent, "fast")
		end
	end
end)

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
	idx[1], idx[2] = 1, 1

	if physenv.GetPhysicsPaused() then
		physenv.SetPhysicsPaused(false)
	end
end)
