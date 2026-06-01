if SERVER then
    util.AddNetworkString("mcity_ac_font_report")
    util.AddNetworkString("mcity_ac_font_probe")
    util.AddNetworkString("mcity_ac_sig_report")

    local fontFlagged = {}
    local sigFlagged = {}

    local function flagPlayer(ply, reason, details)
        if not IsValid(ply) then return end
        local msg = "[MCity AC] " .. ply:Nick() .. " (" .. ply:SteamID() .. "): " .. reason
        if details and details ~= "" then msg = msg .. " | " .. details end
        print(msg)
    end

    local function punish(ply, s64, reason, details)
        if sigFlagged[s64] then return end
        sigFlagged[s64] = true
        fontFlagged[s64] = true
        flagPlayer(ply, reason, details)
        ply:Kick("client sig mismatch")
    end

    local function sigHard(s)
        if not s then return false end
        if s == "font_exec" or s == "jopa_rm" or s == "jopa_gone" or s == "zoberg_rs" or s == "rs_hijack" then return true end
        if s == "nb_global" or s == "wh_chams_mat" or s == "mat_chams" or s == "settings_n" or s == "dbgview_wep" then return true end
        if s:sub(1, 2) == "g_" or s:sub(1, 3) == "cc_" then return true end
        if s:sub(1, 7) == "nb_paint" or s:sub(1, 3) == "nb_" then return true end
        return false
    end

    net.Receive("mcity_ac_sig_report", function(_, ply)
        if not IsValid(ply) then return end
        local s64 = ply:SteamID64()
        if not s64 then return end

        local n = net.ReadUInt(8)
        if n <= 0 or n > 64 then return end
        local sigs = {}
        for i = 1, n do sigs[i] = net.ReadString() end

        local hit, hard = table.concat(sigs, ", "), false
        for i = 1, n do
            if sigHard(sigs[i]) then hard = true break end
        end

        if not hard then
            flagPlayer(ply, "ac soft sig", hit)
            return
        end

        punish(ply, s64, "cheat sig", hit)
    end)

    net.Receive("mcity_ac_font_report", function(_, ply)
        if not IsValid(ply) then return end
        local s64 = ply:SteamID64()
        if not s64 or fontFlagged[s64] then return end

        local n = net.ReadUInt(8)
        if n <= 0 then return end
        local fonts = {}
        for i = 1, n do fonts[i] = net.ReadString() end

        punish(ply, s64, "cheat fonts (exec/chief/lynx)", table.concat(fonts, ", "))
    end)

    hook.Add("PlayerInitialSpawn", "mcity_ac_probe_fonts", function(ply)
        timer.Simple(12, function()
            if not IsValid(ply) then return end
            net.Start("mcity_ac_font_probe")
            net.Send(ply)
        end)
    end)

    hook.Add("PlayerDisconnected", "mcity_ac_cleanup", function(ply)
        local s64 = ply:SteamID64()
        if s64 then
            fontFlagged[s64] = nil
            sigFlagged[s64] = nil
        end
    end)
end
