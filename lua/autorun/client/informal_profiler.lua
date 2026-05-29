if not CLIENT then return end

CreateClientConVar('informal_profiler_interval', '400000', true, false, 'Lua samples', 5000, 5000000)

local active = false
local samples = {}
local profStart = 0
local lastInterval = 400000

local corePatterns = {
    'lua/includes/',
    'lua/derma/',
    'lua/vgui/',
    'lua/menu/',
    'lua/postprocess/',
    'lua/matproxy/',
    'lua/autorun/server/gmod_',
    'gamemodes/base/',
}

local dispatchPatterns = {
    'hook%.Call',
    'hook%.Run',
    'timer%.Simple',
    'timer%.Create',
    'net%.Receive',
    'concommand%.',
    'RunConsoleCommand',
}

local function hookIntervalNow()
    local c = GetConVar('informal_profiler_interval')
    return math.Clamp(math.floor(c and c:GetInt() or 400000), 5000, 5000000)
end

local function isCorePath(src)
    for i = 1, #corePatterns do
        if src:find(corePatterns[i], 1, true) then
            return true
        end
    end
    return false
end

local function classifySource(src)
    if not src or src == '' or src == '=[C]' then return 'engine', src or '=[C]' end

    local addon = src:match('^addons/([^/]+)/')
    if addon then return 'addon: ' .. addon, src end

    local gm = src:match('^gamemodes/([^/]+)/')
    if gm then
        if gm == 'base' or gm == 'menu' then
            return 'gmod core', src
        end
        return 'gamemode: ' .. gm, src
    end

    if isCorePath(src) then return 'gmod core', src end

    if src:find('^lua/') then return 'lua', src end

    return 'unknown', src
end

local function resolveStack()
    local bestOrigin, bestSrc, bestLine, bestFunc
    local firstNonCore, firstNonCoreSrc, firstNonCoreLine, firstNonCoreFunc
    local deepestAddon, deepestAddonSrc, deepestAddonLine, deepestAddonFunc

    for i = 3, 20 do
        local info = debug.getinfo(i, 'Sln')
        if not info then break end

        local src = info.short_src or ''
        if src == '' or src == '=[C]' then continue end
        if src:find('informal_profiler', 1, true) then continue end

        local origin = classifySource(src)
        local line = info.currentline
        if not line or line < 0 then line = info.linedefined or 0 end
        local funcName = info.name or ''

        if not firstNonCore and origin ~= 'gmod core' and origin ~= 'engine' then
            firstNonCore = origin
            firstNonCoreSrc = src
            firstNonCoreLine = line
            firstNonCoreFunc = funcName
        end

        if not deepestAddon and (origin:find('^addon:') or (origin:find('^gamemode:') and origin ~= 'gamemode: base')) then
            deepestAddon = origin
            deepestAddonSrc = src
            deepestAddonLine = line
            deepestAddonFunc = funcName
        end
    end

    if deepestAddon then
        bestOrigin = deepestAddon
        bestSrc = deepestAddonSrc
        bestLine = deepestAddonLine
        bestFunc = deepestAddonFunc
    elseif firstNonCore then
        bestOrigin = firstNonCore
        bestSrc = firstNonCoreSrc
        bestLine = firstNonCoreLine
        bestFunc = firstNonCoreFunc
    else
        local info = debug.getinfo(3, 'Sln')
        if info and info.short_src then
            bestOrigin = classifySource(info.short_src)
            bestSrc = info.short_src
            bestLine = info.currentline or info.linedefined or 0
            bestFunc = info.name or ''
        end
    end

    if not bestOrigin then return nil end
    return bestOrigin, bestSrc, bestLine, bestFunc
end

local function buildChain()
    local chain = {}
    for i = 3, 16 do
        local info = debug.getinfo(i, 'Sln')
        if not info then break end
        local src = info.short_src or ''
        if src == '' or src == '=[C]' then continue end
        if src:find('informal_profiler', 1, true) then continue end
        local origin = classifySource(src)
        local line = info.currentline or info.linedefined or 0
        local funcName = info.name or ''
        chain[#chain + 1] = { origin = origin, src = src, line = line, func = funcName }
    end
    return chain
end

local sampleChains = {}

local function profileHook()
    local origin, src, line, funcName = resolveStack()
    if not origin then return end

    local key
    if funcName ~= '' then
        key = origin .. ' | ' .. src .. ':' .. line .. ' (' .. funcName .. ')'
    else
        key = origin .. ' | ' .. src .. ':' .. line
    end

    samples[key] = (samples[key] or 0) + 1

    if not sampleChains[key] then
        sampleChains[key] = buildChain()
    end
end

local function startProfiling()
    if active then return end
    samples = {}
    sampleChains = {}
    active = true
    profStart = SysTime()
    lastInterval = hookIntervalNow()
    debug.sethook(profileHook, '', lastInterval)
end

local function stopProfiling()
    if not active then return end
    active = false
    debug.sethook()
end

local function getSorted()
    local rows = {}
    local sum = 0
    for k, v in pairs(samples) do
        sum = sum + v
        rows[#rows + 1] = { location = k, count = v }
    end
    table.sort(rows, function(a, b) return a.count > b.count end)
    return rows, sum
end

local function buildReport()
    local rows, sum = getSorted()
    local dur = math.max(0, SysTime() - profStart)
    local lines = {
        string.rep('=', 90),
        '  informal-profiler  |  Client Lua Sampling Report',
        string.rep('=', 90),
        string.format('  Duration    : %.2f s', dur),
        string.format('  Total hits  : %d', sum),
        string.format('  Hook every  : %d instructions', lastInterval),
        string.format('  Unique locs : %d', #rows),
        string.rep('-', 90),
        string.format('  %-8s  %-6s  %s', 'Hits', '%', 'Source / Location'),
        string.rep('-', 90),
    }
    local limit = math.min(200, #rows)
    for i = 1, limit do
        local pct = sum > 0 and (rows[i].count / sum * 100) or 0
        lines[#lines + 1] = string.format('  %-8d  %5.1f%%  %s', rows[i].count, pct, rows[i].location)
    end
    if #rows > limit then
        lines[#lines + 1] = ''
        lines[#lines + 1] = string.format('  ... and %d more locations', #rows - limit)
    end
    lines[#lines + 1] = string.rep('=', 90)
    return table.concat(lines, '\n')
end

hook.Add('ShutDown', 'informal_profiler.cleanup', function()
    if active then
        active = false
        debug.sethook()
    end
end)

local COLOR_BG         = Color(20, 20, 20, 255)
local COLOR_BG_HEADER  = Color(30, 30, 30, 255)
local COLOR_ACCENT     = Color(80, 160, 255, 255)
local COLOR_TEXT       = Color(220, 220, 220, 255)
local COLOR_TEXT_DIM   = Color(140, 140, 140, 255)
local COLOR_RED        = Color(255, 90, 90, 255)
local COLOR_ORANGE     = Color(255, 180, 60, 255)
local COLOR_YELLOW     = Color(220, 220, 80, 255)
local COLOR_GREEN      = Color(100, 220, 100, 255)
local COLOR_WHITE      = Color(255, 255, 255, 255)
local COLOR_BAR_BG     = Color(40, 40, 40, 255)
local COLOR_BORDER     = Color(60, 60, 60, 255)
local COLOR_BTN        = Color(50, 50, 50, 255)
local COLOR_BTN_HOVER  = Color(70, 70, 70, 255)
local COLOR_BTN_ACTIVE = Color(40, 120, 200, 255)
local COLOR_RECORDING  = Color(255, 60, 60, 255)
local COLOR_CHAIN_BG   = Color(25, 25, 25, 255)

local function getHeatColor(pct)
    if pct >= 10 then return COLOR_RED end
    if pct >= 5  then return COLOR_ORANGE end
    if pct >= 2  then return COLOR_YELLOW end
    if pct >= 0.5 then return COLOR_GREEN end
    return COLOR_TEXT_DIM
end

local function makeStyledButton(parent, text, w)
    local btn = vgui.Create('DButton', parent)
    btn:SetText('')
    btn:SetWide(w or 100)
    btn._label = text
    btn.Paint = function(s, bw, bh)
        local col = COLOR_BTN
        if s:IsDown() then
            col = COLOR_BTN_ACTIVE
        elseif s:IsHovered() then
            col = COLOR_BTN_HOVER
        end
        draw.RoundedBox(4, 0, 0, bw, bh, col)
        draw.SimpleText(s._label, 'DermaDefaultBold', bw / 2, bh / 2, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return btn
end

local VIEW_ALL = 1
local VIEW_ADDONS = 2
local VIEW_CORE = 3

local profilerFrame

local function openProfilerWindow()
    if IsValid(profilerFrame) then
        profilerFrame:Remove()
    end

    local frame = vgui.Create('DFrame')
    frame:SetTitle('')
    frame:SetSize(950, 620)
    frame:Center()
    frame:MakePopup()
    frame:SetSizable(true)
    frame:SetMinWidth(700)
    frame:SetMinHeight(420)
    frame:SetDeleteOnClose(true)
    frame:SetDraggable(true)
    profilerFrame = frame

    frame.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, COLOR_BG)
        draw.RoundedBoxEx(6, 0, 0, w, 28, COLOR_BG_HEADER, true, true, false, false)
        surface.SetDrawColor(COLOR_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local title = 'Informal Profiler'
        if active then
            local pulse = math.abs(math.sin(CurTime() * 3))
            draw.SimpleText('*', 'DermaDefaultBold', 10, 14, Color(255, 60, 60, 120 + 135 * pulse), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            title = '  ' .. title .. string.format('  —  recording %.1fs', SysTime() - profStart)
            draw.SimpleText(title, 'DermaDefaultBold', 20, 14, COLOR_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(title, 'DermaDefaultBold', 10, 14, COLOR_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    frame.btnClose.Paint = function(s, w, h)
        draw.SimpleText('X', 'DermaDefaultBold', w / 2, h / 2, s:IsHovered() and COLOR_RED or COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    frame.btnMaxim:SetVisible(false)
    frame.btnMinim:SetVisible(false)

    local mainPanel = vgui.Create('DPanel', frame)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(6, 4, 6, 6)
    mainPanel.Paint = nil

    local statusBar = vgui.Create('DPanel', mainPanel)
    statusBar:Dock(TOP)
    statusBar:SetTall(24)
    statusBar:DockMargin(0, 0, 0, 4)
    statusBar.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLOR_BAR_BG)
        local txt, col
        if active then
            local dur = SysTime() - profStart
            local _, sum = getSorted()
            txt = string.format('Recording  |  %.1fs  |  %d samples  |  interval: %d', dur, sum, lastInterval)
            col = COLOR_RECORDING
        else
            local rows, sum = getSorted()
            if sum > 0 then
                txt = string.format('Stopped  |  %.2fs  |  %d samples  |  %d locations', math.max(0, SysTime() - profStart), sum, #rows)
                col = COLOR_GREEN
            else
                txt = 'Ready'
                col = COLOR_TEXT_DIM
            end
        end
        draw.SimpleText(txt, 'DermaDefault', 8, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local btnRow = vgui.Create('DPanel', mainPanel)
    btnRow:Dock(TOP)
    btnRow:SetTall(30)
    btnRow:DockMargin(0, 0, 0, 4)
    btnRow.Paint = nil

    local btnStart = makeStyledButton(btnRow, 'Start', 70)
    btnStart:Dock(LEFT)
    btnStart:DockMargin(0, 0, 4, 0)

    local btnStop = makeStyledButton(btnRow, 'Stop', 70)
    btnStop:Dock(LEFT)
    btnStop:DockMargin(0, 0, 4, 0)

    local btnClear = makeStyledButton(btnRow, 'Clear', 70)
    btnClear:Dock(LEFT)
    btnClear:DockMargin(0, 0, 4, 0)

    local btnCopyAll = makeStyledButton(btnRow, 'Copy Report', 100)
    btnCopyAll:Dock(LEFT)
    btnCopyAll:DockMargin(0, 0, 4, 0)

    local btnCopySelected = makeStyledButton(btnRow, 'Copy Selected', 110)
    btnCopySelected:Dock(LEFT)
    btnCopySelected:DockMargin(0, 0, 4, 0)

    local intervalPanel = vgui.Create('DPanel', btnRow)
    intervalPanel:Dock(FILL)
    intervalPanel:DockMargin(8, 0, 0, 0)
    intervalPanel.Paint = nil

    local intervalLabel = vgui.Create('DLabel', intervalPanel)
    intervalLabel:Dock(LEFT)
    intervalLabel:SetWide(55)
    intervalLabel:SetText('Interval:')
    intervalLabel:SetTextColor(COLOR_TEXT_DIM)

    local intervalSlider = vgui.Create('DNumSlider', intervalPanel)
    intervalSlider:Dock(FILL)
    intervalSlider:SetText('')
    intervalSlider:SetMin(5000)
    intervalSlider:SetMax(5000000)
    intervalSlider:SetDecimals(0)
    intervalSlider:SetConVar('informal_profiler_interval')
    intervalSlider:SetDark(false)
    intervalSlider.Label:SetTextColor(COLOR_TEXT_DIM)
    if IsValid(intervalSlider.TextArea) then
        intervalSlider.TextArea:SetTextColor(COLOR_TEXT)
    end

    local filterRow = vgui.Create('DPanel', mainPanel)
    filterRow:Dock(TOP)
    filterRow:SetTall(26)
    filterRow:DockMargin(0, 0, 0, 4)
    filterRow.Paint = nil

    local currentView = VIEW_ALL
    local currentFilter = ''

    local viewAll = makeStyledButton(filterRow, 'All', 60)
    viewAll:Dock(LEFT)
    viewAll:DockMargin(0, 0, 4, 0)

    local viewAddons = makeStyledButton(filterRow, 'Addons Only', 100)
    viewAddons:Dock(LEFT)
    viewAddons:DockMargin(0, 0, 4, 0)

    local viewCore = makeStyledButton(filterRow, 'Core Only', 90)
    viewCore:Dock(LEFT)
    viewCore:DockMargin(0, 0, 4, 0)

    local searchEntry = vgui.Create('DTextEntry', filterRow)
    searchEntry:Dock(FILL)
    searchEntry:DockMargin(8, 1, 0, 1)
    searchEntry:SetPlaceholderText('Filter...')
    searchEntry:SetTextColor(COLOR_TEXT)
    searchEntry:SetCursorColor(COLOR_ACCENT)
    searchEntry.Paint = function(s, w, h)
        draw.RoundedBox(3, 0, 0, w, h, Color(30, 30, 30, 255))
        s:DrawTextEntryText(COLOR_TEXT, COLOR_ACCENT, COLOR_TEXT)
    end

    local contentPanel = vgui.Create('DPanel', mainPanel)
    contentPanel:Dock(FILL)
    contentPanel.Paint = nil

    local listView = vgui.Create('DListView', contentPanel)
    listView:Dock(FILL)
    listView:SetMultiSelect(true)
    listView:SetSortable(true)

    local colHits = listView:AddColumn('Hits')
    colHits:SetFixedWidth(70)
    local colPct = listView:AddColumn('%')
    colPct:SetFixedWidth(55)
    local colBar = listView:AddColumn('Heat')
    colBar:SetFixedWidth(70)
    local colOrigin = listView:AddColumn('Source')
    colOrigin:SetFixedWidth(150)
    local colLoc = listView:AddColumn('Location')

    listView.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLOR_BAR_BG)
    end

    local chainPanel = vgui.Create('DPanel', contentPanel)
    chainPanel:Dock(BOTTOM)
    chainPanel:SetTall(0)
    chainPanel:DockMargin(0, 4, 0, 0)
    chainPanel.Paint = function(s, w, h)
        if h < 5 then return end
        draw.RoundedBox(4, 0, 0, w, h, COLOR_CHAIN_BG)
        surface.SetDrawColor(COLOR_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText('Call Stack', 'DermaDefaultBold', 8, 4, COLOR_ACCENT)
    end

    local chainList = vgui.Create('DListView', chainPanel)
    chainList:Dock(FILL)
    chainList:DockMargin(4, 22, 4, 4)
    chainList:SetMultiSelect(false)
    chainList:AddColumn('#'):SetFixedWidth(30)
    chainList:AddColumn('Source'):SetFixedWidth(150)
    chainList:AddColumn('File')
    chainList:AddColumn('Line'):SetFixedWidth(60)
    chainList:AddColumn('Function'):SetFixedWidth(120)
    chainList.Paint = function(s, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(18, 18, 18, 255))
    end

    chainList.OnRowRightClick = function(s, idx, line)
        if not IsValid(line) then return end
        local menu = DermaMenu()
        menu:AddOption('Copy File', function()
            SetClipboardText(line:GetColumnText(3) or '')
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddOption('Copy Source', function()
            SetClipboardText(line:GetColumnText(2) or '')
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddOption('Copy Full Chain', function()
            local buf = {}
            local lines = s:GetLines()
            for _, l in ipairs(lines) do
                buf[#buf + 1] = string.format('#%s  [%s]  %s:%s  %s', l:GetColumnText(1), l:GetColumnText(2), l:GetColumnText(3), l:GetColumnText(4), l:GetColumnText(5))
            end
            SetClipboardText(table.concat(buf, '\n'))
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:Open()
    end

    local function showChain(key)
        chainList:Clear()
        local chain = sampleChains[key]
        if not chain or #chain == 0 then
            chainPanel:SetTall(0)
            return
        end
        chainPanel:SetTall(math.min(26 + #chain * 20, 180))
        for i, entry in ipairs(chain) do
            local line = chainList:AddLine(i, entry.origin, entry.src, entry.line, entry.func ~= '' and entry.func or '-')
            for ci = 1, 5 do
                local label = line.Columns and line.Columns[ci]
                if IsValid(label) then
                    if ci == 2 then
                        local isAddon = entry.origin:find('^addon:') or (entry.origin:find('^gamemode:') and entry.origin ~= 'gmod core')
                        label:SetTextColor(isAddon and COLOR_ACCENT or COLOR_TEXT_DIM)
                    else
                        label:SetTextColor(COLOR_TEXT)
                    end
                end
            end
        end
    end

    listView.OnRowSelected = function(s, idx, line)
        if IsValid(line) and line._location then
            showChain(line._location)
        end
    end

    local function matchesView(origin)
        if currentView == VIEW_ALL then return true end
        if currentView == VIEW_ADDONS then
            return origin:find('^addon:') or (origin:find('^gamemode:') and origin ~= 'gmod core')
        end
        if currentView == VIEW_CORE then
            return origin == 'gmod core' or origin == 'engine'
        end
        return true
    end

    local function populateList()
        if not IsValid(listView) then return end
        local rows, sum = getSorted()
        local vbar = listView.VBar
        local scrollPos = IsValid(vbar) and vbar:GetScroll() or 0

        listView:Clear()
        chainPanel:SetTall(0)
        chainList:Clear()
        if sum == 0 then return end

        local filter = string.lower(currentFilter)
        local limit = 300
        local shown = 0
        local topCount = rows[1] and rows[1].count or 1

        for i = 1, #rows do
            if shown >= limit then break end
            local loc = rows[i].location

            local originPart, filePart = loc:match('^(.-)%s*|%s*(.+)$')
            if not originPart then
                originPart = ''
                filePart = loc
            end

            if not matchesView(originPart) then continue end
            if filter ~= '' and not string.find(string.lower(loc), filter, 1, true) then continue end

            shown = shown + 1
            local count = rows[i].count
            local pct = count / sum * 100

            local line = listView:AddLine(count, string.format('%.1f%%', pct), '', originPart, filePart)
            line._location = loc
            line._count = count
            line._pct = pct
            line._origin = originPart
            line._file = filePart

            local heatCol = getHeatColor(pct)

            for ci = 1, 5 do
                local label = line.Columns and line.Columns[ci]
                if IsValid(label) then
                    if ci == 5 then
                        label:SetTextColor(COLOR_TEXT)
                    elseif ci == 4 then
                        local isAddon = originPart:find('^addon:') or (originPart:find('^gamemode:') and originPart ~= 'gmod core')
                        label:SetTextColor(isAddon and COLOR_ACCENT or COLOR_TEXT_DIM)
                    else
                        label:SetTextColor(heatCol)
                    end
                end
            end

            local heatLabel = line.Columns and line.Columns[3]
            if IsValid(heatLabel) then
                heatLabel:SetText('')
                local barPct = pct
                local maxPct = topCount / sum * 100
                heatLabel.Paint = function(sl, w, h)
                    draw.RoundedBox(2, 2, 4, w - 4, h - 8, Color(30, 30, 30, 255))
                    local bw = math.max(1, (w - 4) * math.Clamp(barPct / math.max(maxPct, 0.01), 0, 1))
                    draw.RoundedBox(2, 2, 4, bw, h - 8, ColorAlpha(heatCol, 200))
                end
            end

            local rowIdx = shown
            line.Paint = function(sl, w, h)
                if sl:IsSelected() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(80, 160, 255, 40))
                elseif sl:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 10))
                elseif rowIdx % 2 == 0 then
                    draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 3))
                end
            end
        end

        timer.Simple(0, function()
            if IsValid(vbar) then vbar:SetScroll(scrollPos) end
        end)
    end

    listView.OnRowRightClick = function(s, idx, line)
        if not IsValid(line) then return end
        local menu = DermaMenu()
        menu:AddOption('Copy Location', function()
            SetClipboardText(line._file or '')
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddOption('Copy Source', function()
            SetClipboardText(line._origin or '')
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddOption('Copy Full Line', function()
            SetClipboardText(string.format('%d  (%.1f%%)  [%s]  %s', line._count or 0, line._pct or 0, line._origin or '', line._file or ''))
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddSpacer()
        menu:AddOption('Copy Call Stack', function()
            local chain = sampleChains[line._location]
            if not chain then return end
            local buf = {}
            for ci, entry in ipairs(chain) do
                buf[#buf + 1] = string.format('#%d  [%s]  %s:%d  %s', ci, entry.origin, entry.src, entry.line, entry.func ~= '' and entry.func or '-')
            end
            SetClipboardText(table.concat(buf, '\n'))
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:AddSpacer()
        menu:AddOption('Copy All Selected', function()
            local sel = s:GetSelected()
            if not sel or #sel == 0 then return end
            local buf = {}
            for _, sl in ipairs(sel) do
                buf[#buf + 1] = string.format('%d  (%.1f%%)  [%s]  %s', sl._count or 0, sl._pct or 0, sl._origin or '', sl._file or '')
            end
            SetClipboardText(table.concat(buf, '\n'))
            surface.PlaySound('buttons/button15.wav')
        end)
        menu:Open()
    end

    searchEntry.OnChange = function(s)
        currentFilter = s:GetValue() or ''
        populateList()
    end

    viewAll.DoClick = function()
        currentView = VIEW_ALL
        populateList()
    end
    viewAddons.DoClick = function()
        currentView = VIEW_ADDONS
        populateList()
    end
    viewCore.DoClick = function()
        currentView = VIEW_CORE
        populateList()
    end

    local rtName
    local function stopRefreshTimer()
        if rtName then
            timer.Remove(rtName)
            rtName = nil
        end
    end

    btnStart.DoClick = function()
        stopRefreshTimer()
        startProfiling()
        listView:Clear()
        chainPanel:SetTall(0)
        rtName = 'informal_profiler_rt_' .. tostring(frame) .. '_' .. SysTime()
        timer.Create(rtName, 0.6, 0, function()
            if not active or not IsValid(frame) then
                stopRefreshTimer()
                return
            end
            populateList()
        end)
    end

    btnStop.DoClick = function()
        stopProfiling()
        stopRefreshTimer()
        populateList()
    end

    btnClear.DoClick = function()
        stopProfiling()
        stopRefreshTimer()
        samples = {}
        sampleChains = {}
        listView:Clear()
        chainPanel:SetTall(0)
        chainList:Clear()
    end

    btnCopyAll.DoClick = function()
        local report = buildReport()
        if report == '' then
            surface.PlaySound('buttons/button10.wav')
            return
        end
        SetClipboardText(report)
        surface.PlaySound('buttons/button15.wav')
        btnCopyAll._label = 'Copied!'
        timer.Simple(1.5, function()
            if IsValid(btnCopyAll) then btnCopyAll._label = 'Copy Report' end
        end)
    end

    btnCopySelected.DoClick = function()
        local sel = listView:GetSelected()
        if not sel or #sel == 0 then
            surface.PlaySound('buttons/button10.wav')
            return
        end
        local buf = {}
        for _, sl in ipairs(sel) do
            buf[#buf + 1] = string.format('%d  (%.1f%%)  [%s]  %s', sl._count or 0, sl._pct or 0, sl._origin or '', sl._file or '')
        end
        SetClipboardText(table.concat(buf, '\n'))
        surface.PlaySound('buttons/button15.wav')
        btnCopySelected._label = 'Copied!'
        timer.Simple(1.5, function()
            if IsValid(btnCopySelected) then btnCopySelected._label = 'Copy Selected' end
        end)
    end

    frame.OnRemove = function()
        stopRefreshTimer()
    end

    if next(samples) then
        populateList()
    end
end

concommand.Add('informal_profiler', function()
    openProfilerWindow()
end)

concommand.Add('informal_profiler_start', function()
    startProfiling()
    print('[informal-profiler] Started')
end)

concommand.Add('informal_profiler_stop', function()
    stopProfiling()
    print('[informal-profiler] Stopped')
    print(buildReport())
end)

concommand.Add('informal_profiler_report', function()
    print(buildReport())
end)

hook.Add('PopulateToolMenu', 'informal_profiler.menu', function()
    spawnmenu.AddToolMenuOption('Utilities', 'User', 'informal_profiler_panel', 'Informal Profiler', '', '', function(cp)
        cp:Button('Open Profiler Window', 'informal_profiler')
    end)
end)