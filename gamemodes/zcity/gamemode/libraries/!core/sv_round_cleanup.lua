local function zbFreezeOrganism(org)
	if not org then return end
	org.godmode = true
end

hook.Add("ZB_EndRound", "zb_round_sweep", function()
	for _, ent in ents.Iterator() do
		if IsValid(ent) and ent.IsSupportTeamMember then
			ent:Remove()
		end
	end

	for _, ply in player.Iterator() do
		zbFreezeOrganism(ply.organism)

		local rag = ply.FakeRagdoll
		if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath") end
		if IsValid(rag) then zbFreezeOrganism(rag.organism) end
	end
end)

hook.Add("ZB_StartRound", "zb_round_unfreeze", function()
	for _, ply in player.Iterator() do
		if ply.organism then ply.organism.godmode = nil end
	end
end)
