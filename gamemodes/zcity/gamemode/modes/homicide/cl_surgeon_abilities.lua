local MODE = MODE

net.Receive("HMCD_SurgeonArteryCutting", function()
	local active = net.ReadBool()
	if active then
		MODE.StartSurgeonArteryCut(LocalPlayer(), net.ReadEntity())
	else
		MODE.StopSurgeonArteryCut(LocalPlayer())
	end
end)

hook.Add("Think", "HMCD_Surgeon", function()
	local ply = LocalPlayer()

	if ply.Ability_SurgeonArteryCut then
		MODE.ContinueSurgeonArteryCut(ply)
	end

	if ply.SurgeonOrganViewUntil and ply.SurgeonOrganViewUntil <= CurTime() then
		ply.SurgeonOrganViewUntil = nil
	end
end)

hook.Add("PlayerSpawn", "HMCD_Surgeon", function(ply)
	if ply ~= LocalPlayer() then return end
	ply.SurgeonOrganViewUntil = nil
end)

local render_DrawWireframeBox = render.DrawWireframeBox
local radius_sqr = (MODE.SurgeonOrganViewRadius or 500) ^ 2

hook.Add("PostDrawTranslucentRenderables", "HMCD_SurgeonOrgans", function()
	local lply = LocalPlayer()
	if zb.CROUND ~= "hmcd" then return end
	if lply.Profession ~= "surgeon" or not MODE.SurgeonOrganViewActive(lply) then return end
	if not lply:Alive() or lply.organism and lply.organism.otrub then return end

	local my_pos = lply:GetPos()

	for _, pl in player.Iterator() do
		if not pl:Alive() then continue end
		if pl:GetPos():DistToSqr(my_pos) > radius_sqr then continue end

		local org = pl.organism
		if org and org.alive == false then continue end

		local ent = hg.GetCurrentCharacter(pl)
		if not IsValid(ent) then continue end

		local organs = hg.organism.GetHitBoxOrgans(ent:GetModel(), ent)
		if not organs then continue end

		local boxs = hg.organism.ShootMatrix(ent, organs, pl)
		if not boxs then continue end

		for i = 1, #boxs do
			local box = boxs[i]
			local organ = box[6] and organs[box[6]][box[7]]
			render_DrawWireframeBox(box[1], box[2], box[3], box[4], (organ and organ[6]) or color_black)
		end
	end
end)

hook.Add("radialOptions", "HMCD_Surgeon", function()
	local ply = LocalPlayer()
	local org = ply.organism or {}

	if zb.CROUND ~= "hmcd" then return end
	if not ply:Alive() or org.otrub or ply.Profession ~= "surgeon" then return end

	local cd_left = MODE.SurgeonOrganViewCDLeft(ply)
	if cd_left > 0 then
		hg.radialOptions[#hg.radialOptions + 1] = {
			function() end,
			"Увидеть организмы (" .. MODE.FormatSurgeonTime(cd_left) .. ")",
		}
		return
	end

	hg.radialOptions[#hg.radialOptions + 1] = {
		function()
			ply.SurgeonOrganViewUntil = CurTime() + MODE.SurgeonOrganViewDuration
			ply.SurgeonOrganViewCDUntil = CurTime() + MODE.SurgeonOrganViewCooldown
		end,
		"Увидеть организмы",
	}
end)
