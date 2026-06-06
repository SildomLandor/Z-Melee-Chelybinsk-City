mAC.decoys = {
	"SW_Title", "SW_Tab", "SW_Group", "SW_Elem",
	"SW_Small", "SW_Btn", "SW_ESP_Name", "SW_ESP_Info",
	"Oreo", "MMediumName", "WindowsSubTitle", "WindowsTitle",
	"RBoldO", "HP_RBoldO", "MMedium", "NickName_RBoldO", "FuncButtons",
	"NL_Logo", "NL_Header", "NL_Group", "NL_Text", "NL_Icon", "NL_Icon_Small",
}

mAC.fontExact = {
	"UI_Verdana", "UI_VerdanaBold", "UI_TahomaBig", "UI_Tahoma", "UI_TahomaBold",
	"UI_SmallFont", "UI_Century", "UI_Console", "UI_Trebuchet", "UI_Arial",
	"kefir.main", "kefir.main.small", "kefir.main.qcold", "kefir.main.tiny", "kefir.main.nano",
	"kefir.icons", "kefir.bold", "kefir.tab", "kefir.header",
	"kevir.main", "kevir.main.small", "kevir.main.qcold", "kevir.main.tiny", "kevir.main.nano",
	"kevir.icons", "kevir.bold", "kevir.tab", "kevir.header",
	"Chief.Default", "Chief.Bold", "Chieftain", "Chieftain.Main", "chieftain_main",
	"exec.main", "Exec.Main", "Exec.Menu", "EXEC.Font",
}

mAC.fontPrefix = {
	"kefir", "kefir.", "SW_", "UI_",
}

mAC.fontSuffix = {
	{ "chief", true }, { "chieftain", true }, { "exec", true }, { "exec.", true },
}

mAC.hardSig = {
	font_exec = true, jopa_rm = true, zoberg_rs = true, rs_hijack = true,
	nb_global = true, wh_chams_mat = true, mat_chams = true, settings_n = true, dbgview_wep = true,
	g_exec = true, g_kefir = true, g_kevir = true, g_chief = true, g_lynx = true,
	g_snixzz = true, g_baim = true, g_nb = true, g_sw = true,
	cc_exec = true, cc_chief = true, cc_lynx = true, cc_nb = true, cc_aim = true, cc_esp = true,
	nb_paint_ev = true, nb_plus_menu = true, nb_shutdown_sg = true, nb_mod_think = true,
	nb_wh_paint = true,
}

mAC.globProbe = {
	"EXEC", "Exec", "exec", "kefir", "Kefir", "kevir",
	"Chieftain", "chieftain", "Chief", "Lynx", "lynx", "snixzz", "BAIM", "nb", "SW", "SilkWare",
}

mAC.hookProbe = {
	{ "RenderScene", "zoberg", "zoberg_rs" },
	{ "RenderScene", "jopa", "jopa_gone" },
	{ "NB-PaintModule", "*", "nb_paint_ev" },
	{ "PlayerButtonDown", "NightbloomMenu_OpenOnPlusKey", "nb_plus_menu" },
	{ "ShutDown", "RemoveAntiScreenGrab", "nb_shutdown_sg" },
}

mAC.ccProbe = {
	{ "^exec$", "cc_exec" }, { "^%+exec", "cc_exec" }, { "^exec_", "cc_exec" },
	{ "chieftain", "cc_chief" }, { "^chief", "cc_chief" },
	{ "lynx", "cc_lynx" }, { "settings_n", "cc_nb" },
	{ "aimbot", "cc_aim" }, { "esp_menu", "cc_esp" },
	{ "silkware", "g_sw" }, { "kevir", "g_kevir" },
}

mAC.matProbe = {
	"WH_Chams", "Exec_Chams", "Chief_Chams", "SW_Chams",
	"chams_mat", "flat_chams", "ignorez_chams",
}

function mAC.FontBad(name)
	if not name or name == "" then return false end
	if mAC.decoyLookup and mAC.decoyLookup[name] then return false end

	for i = 1, #mAC.fontExact do
		if name == mAC.fontExact[i] then return true end
	end

	for i = 1, #mAC.fontPrefix do
		if name:sub(1, #mAC.fontPrefix[i]) == mAC.fontPrefix[i] then return true end
	end

	local l = string.lower(name)
	for i = 1, #mAC.fontSuffix do
		local p, sub = mAC.fontSuffix[i][1], mAC.fontSuffix[i][2]
		if sub and l:find(p, 1, true) then return true end
		if not sub and l:sub(1, #p) == p then return true end
	end

	return false
end

function mAC.SigHard(sig)
	if not sig then return false end
	if mAC.hardSig[sig] then return true end
	if sig:sub(1, 2) == "g_" or sig:sub(1, 3) == "cc_" then return true end
	if sig:sub(1, 7) == "nb_paint" or sig:sub(1, 3) == "nb_" then return true end
	return false
end

function mAC.BuildProbe(ply)
	local list, seen = {}, {}

	for i = 1, #mAC.decoys do
		local n = mAC.decoys[i]
		if not seen[n] then
			seen[n] = true
			list[#list + 1] = n
		end
	end

	for i = 1, #mAC.fontExact do
		local n = mAC.fontExact[i]
		if not seen[n] then
			seen[n] = true
			list[#list + 1] = n
		end
	end

	ply.mAC_probe = list
	ply.mAC_glob = table.Copy(mAC.globProbe)
	ply.mAC_cc = {}
	for i = 1, #mAC.ccProbe do ply.mAC_cc[i] = mAC.ccProbe[i][1] end
	ply.mAC_mat = table.Copy(mAC.matProbe)
	ply.mAC_decoys = #mAC.decoys
end

mAC.decoyLookup = {}
for i = 1, #mAC.decoys do mAC.decoyLookup[mAC.decoys[i]] = true end

function mAC.EvalFonts(ply, bits)
	if not ply.mAC_probe then return end
	local hit = {}
	for i = 1, #ply.mAC_probe do
		if i <= ply.mAC_decoys then continue end
		if not mAC.BitTest(bits, i) then continue end
		local name = ply.mAC_probe[i]
		if mAC.FontBad(name) then hit[#hit + 1] = name end
	end
	return hit
end

function mAC.EvalCC(ply, bits)
	local hit = {}
	if not ply.mAC_cc then return hit end
	for i = 1, #ply.mAC_cc do
		if not mAC.BitTest(bits, i) then continue end
		local sig = mAC.ccProbe[i] and mAC.ccProbe[i][2]
		if sig then hit[#hit + 1] = sig end
	end
	return hit
end

function mAC.EvalMats(ply, bits)
	local hit = {}
	if not ply.mAC_mat then return hit end
	for i = 1, #ply.mAC_mat do
		if mAC.BitTest(bits, i) then hit[#hit + 1] = ply.mAC_mat[i] end
	end
	return hit
end

function mAC.EvalGlobals(ply, bits)
	local hit = {}
	if not ply.mAC_glob then return hit end
	for i = 1, #ply.mAC_glob do
		if mAC.BitTest(bits, i) then hit[#hit + 1] = ply.mAC_glob[i] end
	end
	return hit
end

function mAC.EvalServerSig(ply, sigs)
	local hard, soft = {}, {}
	for i = 1, #sigs do
		local s = sigs[i]
		if mAC.SigHard(s) then hard[#hard + 1] = s else soft[#soft + 1] = s end
	end
	return hard, soft
end
