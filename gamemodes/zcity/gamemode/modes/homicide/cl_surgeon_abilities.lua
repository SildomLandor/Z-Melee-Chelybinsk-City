local MODE = MODE

net.Receive("HMCD_SurgeonAnalyzing", function()
	local active = net.ReadBool()
	if active then
		MODE.StartSurgeonAnalyze(LocalPlayer(), net.ReadEntity())
	else
		MODE.StopSurgeonAnalyze(LocalPlayer())
	end
end)

net.Receive("HMCD_SurgeonArteryCutting", function()
	local active = net.ReadBool()
	if active then
		MODE.StartSurgeonArteryCut(LocalPlayer(), net.ReadEntity())
	else
		MODE.StopSurgeonArteryCut(LocalPlayer())
	end
end)

net.Receive("HMCD_SurgeonReveal", function()
	local lply = LocalPlayer()
	lply.SurgeonRevealVictim = net.ReadEntity()
	lply.SurgeonRevealUntil = net.ReadFloat()
end)

hook.Add("Think", "HMCD_Surgeon", function()
	local ply = LocalPlayer()

	if ply.Ability_SurgeonArteryCut then
		MODE.ContinueSurgeonArteryCut(ply)
	end

	if ply.SurgeonRevealUntil and ply.SurgeonRevealUntil <= CurTime() then
		ply.SurgeonRevealVictim = nil
		ply.SurgeonRevealUntil = nil
	end
end)

local render_DrawWireframeBox = render.DrawWireframeBox
local reveal_col = MODE.SurgeonRevealColor or Color(255, 0, 0)

hook.Add("PostDrawTranslucentRenderables", "HMCD_SurgeonReveal", function()
	local lply = LocalPlayer()
	if lply.Profession ~= "surgeon" then return end
	if not lply.SurgeonRevealUntil or lply.SurgeonRevealUntil <= CurTime() then return end

	local target = lply.SurgeonRevealVictim
	if not IsValid(target) or not target:Alive() then return end
	if not MODE.SurgeonCanSeeTarget(lply, target) then return end

	local ent = hg.GetCurrentCharacter(target)
	if not IsValid(ent) then return end

	local organs = hg.organism.GetHitBoxOrgans(ent:GetModel(), ent)
	if not organs then return end

	local boxs = hg.organism.ShootMatrix(ent, organs, target)
	if not boxs then return end

	for i = 1, #boxs do
		local box = boxs[i]
		local organ = box[6] and organs[box[6]][box[7]]
		if organ and MODE.SurgeonIsVulnerableOrgan(organ[1]) then
			render_DrawWireframeBox(box[1], box[2], box[3], box[4], reveal_col)
		end
	end
end)

local function requestAnalyze(victim)
	net.Start("HMCD_SurgeonAnalyzeRequest")
		net.WriteEntity(victim)
	net.SendToServer()
end

hook.Add("radialOptions", "HMCD_Surgeon", function()
	local ply = LocalPlayer()
	local org = ply.organism or {}

	if not MODE.IsRoundTypeSuitableForProfessions() then return end
	if not ply:Alive() or org.otrub or ply.Profession ~= "surgeon" then return end
	if ply.Ability_SurgeonAnalyze or ply.Ability_SurgeonArteryCut then return end

	local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply, nil, MODE.SurgeonReach)
	if not IsValid(other_ply) or other_ply == ply or not other_ply:Alive() then return end
	if not MODE.SurgeonCanSeeTarget(ply, other_ply) then return end
	if not MODE.SurgeonCanTouchTarget(ply, aim_ent or other_ply, other_ply) then return end

	hg.radialOptions[#hg.radialOptions + 1] = {function() requestAnalyze(other_ply) end, "Узнать уязвимые точки"}
end)
