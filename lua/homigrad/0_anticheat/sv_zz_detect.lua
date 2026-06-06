net.Receive("mac_r", function(_, ply)
	if not IsValid(ply) or ply.mAC_done or not mAC.cfg.enabled then return end

	local fontBits = mAC.ReadBits()
	local globBits = mAC.ReadBits()
	local ccBits = mAC.ReadBits()
	local matBits = mAC.ReadBits()
	local sigN = net.ReadUInt(8)
	local sigs = {}
	for i = 1, sigN do sigs[i] = net.ReadString() end
	net.ReadBool()

	local fonts = mAC.EvalFonts(ply, fontBits) or {}
	local globs = mAC.EvalGlobals(ply, globBits) or {}
	local ccs = mAC.EvalCC(ply, ccBits) or {}
	local mats = mAC.EvalMats(ply, matBits) or {}

	for i = 1, #ccs do sigs[#sigs + 1] = ccs[i] end
	if #mats > 0 then sigs[#sigs + 1] = "mat_chams" end

	for i = 1, #globs do
		local g = globs[i]
		local l = string.lower(g)
		if l == "exec" or l == "kefir" or l == "kevir" then sigs[#sigs + 1] = "g_exec" end
		if l:find("chief", 1, true) then sigs[#sigs + 1] = "g_chief" end
		if l == "nb" then sigs[#sigs + 1] = "g_nb" end
		if l == "lynx" then sigs[#sigs + 1] = "g_lynx" end
		if l == "sw" or l == "silkware" then sigs[#sigs + 1] = "g_sw" end
	end

	if #fonts > 0 then
		mAC.Debug("detect fonts", mAC.PlayerLabel(ply), table.concat(fonts, ", "))
		mAC.Punish(ply, "fonts", table.concat(fonts, ", "))
		return
	end

	local hard, soft = mAC.EvalServerSig(ply, sigs)
	if #hard > 0 then
		mAC.Debug("detect hard", mAC.PlayerLabel(ply), table.concat(hard, ", "))
		mAC.Punish(ply, "sig", table.concat(hard, ", "))
		return
	end

	if #soft > 0 then
		mAC.Debug("detect soft", mAC.PlayerLabel(ply), table.concat(soft, ", "))
		mAC.LogDetection(ply, "soft", table.concat(soft, ", "))
	else
		mAC.Debug("probe clean", mAC.PlayerLabel(ply))
	end
end)
