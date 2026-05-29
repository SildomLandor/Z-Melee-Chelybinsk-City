hook.Add("ZB_EndRound", "zb_round_sweep", function()
	for _, ent in ents.Iterator() do
		if IsValid(ent) and ent.IsSupportTeamMember then
			ent:Remove()
		end
	end

	for _, ply in player.Iterator() do
		if IsValid(ply.FakeRagdoll) then hg.FakeUp(ply, true, true) end
		if ply.organism then hg.organism.Clear(ply.organism) end
	end
end)
