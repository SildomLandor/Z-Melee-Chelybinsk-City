if CLIENT then
    local suspectFonts = {
        "UI_Verdana", "UI_VerdanaBold", "UI_TahomaBig", "UI_Tahoma", "UI_TahomaBold",
        "UI_SmallFont", "UI_Century", "UI_Console", "UI_Trebuchet", "UI_Arial",
        "kefir.main", "kefir.main.small", "kefir.main.qcold", "kefir.main.tiny", "kefir.main.nano",
        "kefir.icons", "kefir.bold", "kefir.tab", "kefir.header",
        "Chief.Default", "Chief.Bold", "Chieftain", "Chieftain.Main", "chieftain_main",
        "exec.main", "Exec.Main", "Exec.Menu", "EXEC.Font",
    }

    local suspectLookup = {}
    for i = 1, #suspectFonts do suspectLookup[suspectFonts[i]] = true end

    local function fontBad(n)
        if not n or n == "" then return false end
        if suspectLookup[n] then return true end
        if n:sub(1, 6) == "kefir." then return true end
        if n:sub(1, 3) == "UI_" then return true end
        local l = string.lower(n)
        if l:sub(1, 5) == "chief" or l:find("chieftain", 1, true) then return true end
        if l:sub(1, 4) == "exec" or l:find("exec%.", 1, true) then return true end
        return false
    end

    local trackedFonts = {}
    local lastFontReport = ""
    local fontScanQueued = false

    local sigq, siglast, sigbusy = {}, "", false
    local function sigpush(s)
        if not s or s == "" then return end
        sigq[s] = (sigq[s] or 0) + 1
        sigbusy = true
    end

    local originalCreateFont = surface.CreateFont
    surface.CreateFont = function(name, data)
        if type(name) == "string" and name ~= "" then
            trackedFonts[name] = true
            if fontBad(name) then
                fontScanQueued = true
                sigpush("font_exec")
            end
        end
        return originalCreateFont(name, data)
    end

    local function collectSuspiciousFonts()
        local listed = {}
        if type(surface.GetLuaFonts) == "function" then
            listed = surface.GetLuaFonts() or {}
        elseif type(surface.GetFonts) == "function" then
            listed = surface.GetFonts() or {}
        end
        local lookup = {}
        for i = 1, #listed do lookup[listed[i]] = true end
        for fontName in pairs(trackedFonts) do lookup[fontName] = true end

        local found, seen = {}, {}
        for fontName in pairs(lookup) do
            if fontBad(fontName) and not seen[fontName] then
                seen[fontName] = true
                found[#found + 1] = fontName
            end
        end
        return found
    end

    local function sendFontReport()
        local found = collectSuspiciousFonts()
        if #found <= 0 then return end
        table.sort(found)
        local key = table.concat(found, "|")
        if key == lastFontReport then return end
        lastFontReport = key

        net.Start("mcity_ac_font_report")
        net.WriteUInt(#found, 8)
        for i = 1, #found do net.WriteString(found[i]) end
        net.SendToServer()
    end

    hook.Add("Think", "mcity_ac_font_debounce", function()
        if not fontScanQueued then return end
        fontScanQueued = false
        sendFontReport()
    end)

    local function sigflush()
        if not sigbusy then return end
        sigbusy = false
        local t, n = {}, 0
        for k, v in pairs(sigq) do
            n = n + 1
            t[n] = k .. (v > 1 and ("x" .. v) or "")
        end
        if n <= 0 then return end
        table.sort(t)
        local k = table.concat(t, "|")
        if k == siglast then return end
        siglast = k
        net.Start("mcity_ac_sig_report")
        net.WriteUInt(n, 8)
        for i = 1, n do net.WriteString(t[i]) end
        net.SendToServer()
    end

    hook.Add("Think", "mcity_ac_sig_deb", function()
        if not sigbusy then return end
        sigflush()
    end)

    local badMats = {
        WH_Chams = true, Exec_Chams = true, Chief_Chams = true,
        chams_mat = true, flat_chams = true, ignorez_chams = true,
    }
    local function matBad(n)
        if not n then return false end
        if badMats[n] then return true end
        local l = string.lower(n)
        if l:find("chams", 1, true) and not l:find("homigrad", 1, true) then return true end
        return false
    end

    if CreateMaterial then
        local oCM = CreateMaterial
        CreateMaterial = function(n, ...)
            if matBad(n) then sigpush("mat_chams") end
            return oCM(n, ...)
        end
    end

    local badG = {
        EXEC = "g_exec", Exec = "g_exec", exec = "g_exec",
        kefir = "g_kefir", Kefir = "g_kefir",
        Chieftain = "g_chief", chieftain = "g_chief", Chief = "g_chief",
        Lynx = "g_lynx", lynx = "g_lynx",
        snixzz = "g_snixzz", BAIM = "g_baim",
        nb = "g_nb",
    }

    local ccNeed = {
        { "^exec$", "cc_exec" },
        { "^%+exec", "cc_exec" },
        { "^exec_", "cc_exec" },
        { "chieftain", "cc_chief" },
        { "^chief", "cc_chief" },
        { "lynx", "cc_lynx" },
        { "settings_n", "cc_nb" },
        { "aimbot", "cc_aim" },
        { "esp_menu", "cc_esp" },
    }

    local oAdd, oRem = hook.Add, hook.Remove
    hook.Add = function(e, id, fn, ...)
        if e == "RenderScene" and id == "zoberg" then sigpush("zoberg_rs") end
        if type(id) == "string" then
            local l = string.lower(id)
            if e == "RenderScene" and (l:find("exec", 1, true) or l:find("chief", 1, true) or l:find("fakert", 1, true)) then
                sigpush("rs_hijack")
            end
            if id:find("NB%-Paint", 1, true) then sigpush("nb_paint_ev") end
            if id == "NightbloomMenu_OpenOnPlusKey" then sigpush("nb_plus_menu") end
            if id == "RemoveAntiScreenGrab" then sigpush("nb_shutdown_sg") end
            if id:find("_Think_main$") then sigpush("nb_mod_think") end
        end
        if e == "NB-PaintModule" then sigpush("nb_paint_ev") end
        return oAdd(e, id, fn, ...)
    end
    hook.Remove = function(e, id)
        if e == "RenderScene" and id == "jopa" then sigpush("jopa_rm") end
        return oRem(e, id)
    end

    local function sigscan()
        local h = hook.GetTable()
        local rs = h.RenderScene
        if rs then
            if not rs.jopa then sigpush("jopa_gone") end
            if rs.zoberg then sigpush("zoberg_rs") end
            for hid in pairs(rs) do
                if type(hid) ~= "string" then continue end
                local l = string.lower(hid)
                if l:find("exec", 1, true) or l:find("chief", 1, true) or l:find("fakert", 1, true) then
                    sigpush("rs_hijack")
                end
            end
        end

        if h["NB-PaintModule"] then sigpush("nb_paint_ev") end
        if h.PlayerButtonDown and h.PlayerButtonDown.NightbloomMenu_OpenOnPlusKey then sigpush("nb_plus_menu") end
        if h.ShutDown and h.ShutDown.RemoveAntiScreenGrab then sigpush("nb_shutdown_sg") end

        for gk, gs in pairs(badG) do
            local v = _G[gk]
            if v == nil then continue end
            if gk == "nb" then
                if istable(v) and (v.module or v.modules) then sigpush(gs) end
            elseif istable(v) or isfunction(v) then
                sigpush(gs)
            end
        end

        if _G.dbgView and istable(_G.dbgView) and isfunction(_G.dbgView.calcWeaponView) then sigpush("dbgview_wep") end

        local cc = concommand.GetTable()
        if cc then
            for cmd in pairs(cc) do
                local l = string.lower(cmd)
                for i = 1, #ccNeed do
                    local p, s = ccNeed[i][1], ccNeed[i][2]
                    if l:find(p) then sigpush(s) break end
                end
            end
        end

        for mn in pairs(badMats) do
            local m = Material(mn)
            if m and not m:IsError() then sigpush("mat_chams") end
        end

        for ev, tbl in pairs(h) do
            if not istable(tbl) then continue end
            for hid in pairs(tbl) do
                if type(hid) ~= "string" then continue end
                if hid:sub(1, 3) == "wh_" and hid:find("_NB%-PaintModule_") then sigpush("nb_wh_paint") break end
            end
        end

        local ff = collectSuspiciousFonts()
        if #ff > 0 then sigpush("font_exec") end
    end

    timer.Create("mcity_ac_sig_poll", 4, 0, sigscan)

    net.Receive("mcity_ac_font_probe", function()
        sendFontReport()
        sigscan()
    end)

    hook.Add("InitPostEntity", "mcity_ac_font_initial_scan", function()
        timer.Simple(8, function() sendFontReport() sigscan() end)
        timer.Simple(20, sigscan)
        timer.Simple(50, sigscan)
    end)
end
