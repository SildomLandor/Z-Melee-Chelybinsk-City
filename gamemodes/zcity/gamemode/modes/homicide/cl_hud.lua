local MODE = MODE
local vgui_color_main = Color(150, 80, 0, 255)
local vgui_color_warning = Color(150, 0, 0, 255)
local vgui_color_bg = Color(50, 50, 50, 255)
local vgui_color_ready = Color(0, 150, 50, 255)
local vgui_color_notready = Color(0, 50, 0, 255)
local vgui_color_text_main = Color(150, 50, 0, 255)
local vgui_color_text_shadow = Color(0, 0, 0, 255)

local mat_gradientdown = Material("vgui/gradient_down")

local function draw_shadow_text(text, cx, cy)
	draw.DrawText(text, "HomigradFontMedium", cx + 1, cy + 1, vgui_color_text_shadow, TEXT_ALIGN_CENTER)
	draw.DrawText(text, "HomigradFontMedium", cx, cy, vgui_color_text_main, TEXT_ALIGN_CENTER)
end

local vector_one = Vector(1, 1, 1)

local function draw_RotatedText(text, font, x, y, color, ang, scale)
	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	local m = Matrix()
	
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, ang, 0))
	m:Scale(vector_one * (scale or 1))

	surface.SetFont(font)
	
	local w, h = surface.GetTextSize(text)

	m:Translate(Vector(-w / 2, -h / 2, 0))

	cam.PushModelMatrix(m, true)
		draw.DrawText(text, font, 0, 0, color)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

hook.Add("HUDPaint", "HMCD_SubRoles_Abilities", function()
	local ply = LocalPlayer()
	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply)
	local after_text_offset = 5
	local y_offset = 30
	y_offset = y_offset + ScreenScale(15)
	
	surface.SetFont("HomigradFontMedium")
	
	if(ply:Alive())then
		if(ply.isTraitor)then
			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe" or ply.SubRole == "traitor_martial_artist" or ply.SubRole == "traitor_martial_artist_soe")then
				local text = "(HOLD)[ALT + E] Break Neck"
				local tw, th = surface.GetTextSize(text)
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
				cy = cy + y_offset
				
				if((IsValid(aim_ent) and other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent)) or ply.Ability_NeckBreak)then
					draw_shadow_text(text, cx, cy)
					
					if(ply.Ability_NeckBreak)then
						local frac = ply.Ability_NeckBreak.Progress / 100
						
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy, tw * frac, th)
					end
				
					y_offset = y_offset + th + after_text_offset
				end
				
				if(IsValid(aim_ent))then
					if(aim_ent:IsRagdoll())then
						local text = "[ALT + R] Exchange Appearances"
						local tw, th = surface.GetTextSize(text)
						local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
						
						draw_shadow_text(text, cx, cy + y_offset)
						
						y_offset = y_offset + th + after_text_offset
					end
				end
			end
			
			if(ply.SubRole == "traitor_assasin" or ply.SubRole == "traitor_assasin_soe" or ply.SubRole == "traitor_martial_artist" or ply.SubRole == "traitor_martial_artist_soe" or ply.PlayerClassName == "sc_infiltrator")then
				local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
				local text = "(HOLD)[ALT + E] Disarm"
				local tw, th = surface.GetTextSize(text)
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
				cy = cy + y_offset
				
				if((IsValid(aim_ent) and other_ply and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach) and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach)) or ply.Ability_Disarm)then
					draw_shadow_text(text, cx, cy)
					
					if(ply.Ability_Disarm)then
						local frac = ply.Ability_Disarm.Progress / 100
						
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy, tw * frac, th)
					end
					
					y_offset = y_offset + th + after_text_offset
				end
			end

			if MODE.IsTraitorDiversant and MODE.IsTraitorDiversant(ply) then
				local text = "(HOLD)[ALT + E] Slit Throat"
				local tw, th = surface.GetTextSize(text)
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
				cy = cy + y_offset

				if ((IsValid(aim_ent) and other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent) and MODE.PlyHasSharpWeapon(ply)) or ply.Ability_ThroatSlit) then
					draw_shadow_text(text, cx, cy)

					if ply.Ability_ThroatSlit then
						local frac = ply.Ability_ThroatSlit.Progress / 100
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy, tw * frac, th)
					end

					y_offset = y_offset + th + after_text_offset
				end

				if IsValid(aim_ent) then
					if aim_ent:IsRagdoll() then
						local ragText = "[ALT + R] Exchange Appearances"
						local rtw, rth = surface.GetTextSize(ragText)
						draw_shadow_text(ragText, trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y + y_offset)
						y_offset = y_offset + rth + after_text_offset
					elseif other_ply and other_ply:IsPlayer() and other_ply:Alive() and MODE.CanPlayerStealFromBack(ply, other_ply, aim_ent) then
						local stealText = "[ALT + R] Steal From Back"
						local stw, sth = surface.GetTextSize(stealText)
						draw_shadow_text(stealText, trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y + y_offset)
						y_offset = y_offset + sth + after_text_offset
					end
				end
			end
			
			if(ply.SubRole == "traitor_chemist")then
				local after_side_bar_offset = 5
				local bar_border = 5
				local bar_width = ScreenScale(20)
				local bar_height = ScreenScale(80)
				local bar_y = (ScrH() - bar_height) / 2
				local bar_x = ScrW() - after_side_bar_offset
				ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
				ply.PassiveAbility_VGUI_ChemicalAccumulation = ply.PassiveAbility_VGUI_ChemicalAccumulation or {}
				
				for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
					ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] or 0
					ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = Lerp(FrameTime() * 3, ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name], amt)
					if(ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] > 0.1)then
						surface.SetDrawColor(vgui_color_bg)
						surface.DrawRect(bar_x - bar_width, bar_y, bar_width, bar_height)
						
						local frac = math.min(ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] / 100, 1)
						local y_end = bar_y + bar_border + bar_height - bar_border * 2
						local y_start = y_end - ((bar_height - bar_border * 2) * frac)
						local height = y_end - y_start
						
						surface.SetDrawColor(vgui_color_main)
						surface.DrawRect(bar_x - bar_width + bar_border, y_start, bar_width - bar_border * 2, height)
						
						render.SetScissorRect(bar_x - bar_width + bar_border, y_start, bar_x - bar_border, y_start + height, true)
							surface.SetDrawColor(vgui_color_warning)
							surface.SetMaterial(mat_gradientdown)
							surface.DrawTexturedRect(bar_x - bar_width + bar_border, bar_y + bar_border, bar_width - bar_border * 2, bar_height - bar_border * 2)
						render.SetScissorRect(0, 0, 0, 0, false)
						
						local tcx, tcy = bar_x - bar_width / 2, bar_y + bar_height / 2
						
						draw_RotatedText(chemical_name, "HomigradFontMedium", tcx, tcy, vgui_color_text_shadow, 90, 1)
						
						bar_x = bar_x - bar_width - after_side_bar_offset
					end
				end
			end
		end
		
		--\\Professions
		if ply.Profession == "surgeon" and ply:Alive() then
			local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.SurgeonReach)

			if ply.Ability_SurgeonAnalyze and trace then
				local text = "Осмотр..."
				local tw, th = surface.GetTextSize(text)
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y + y_offset
				draw_shadow_text(text, cx, cy)
				local frac = ply.Ability_SurgeonAnalyze.Progress / 100
				surface.SetDrawColor(vgui_color_text_main)
				surface.DrawRect(cx - tw / 2, cy + th, tw * frac, 4)
				y_offset = y_offset + th + after_text_offset + 8
			end

			if IsValid(other_ply) and other_ply ~= ply and other_ply:Alive() and trace then
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
				cy = cy + y_offset
				local can_cut = MODE.SurgeonWantsSharpCut(ply, ply:GetActiveWeapon())
					and MODE.SurgeonTraceArtery(ply, other_ply)
					and MODE.SurgeonCanSeeTarget(ply, other_ply)
					and (MODE.SurgeonCanTouchTarget(ply, aim_ent or other_ply, other_ply) or ply.Ability_SurgeonArteryCut)

				if can_cut then
					local text = "(HOLD)[ALT + E] Вскрыть артерию"
					local tw, th = surface.GetTextSize(text)
					draw_shadow_text(text, cx, cy)

					if ply.Ability_SurgeonArteryCut then
						local frac = ply.Ability_SurgeonArteryCut.Progress / 100
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy + th, tw * frac, th)
					end

					y_offset = y_offset + th + after_text_offset
				end
			end
		end
		--//
	end
end)


--// traitor panel (scoreboard / esc-menu style)

local tp_scale = ScreenScaleH or ScreenScale

local traitor_panel = {
	assistants = {},
	dead_anim = {},
	width = math.Clamp(math.floor(ScrW() * 0.17), 260, 380),
	height = tp_scale(152),
	assist_height = tp_scale(96),
	padding = tp_scale(8),
	left_padding = tp_scale(44),
	avatar_size = tp_scale(17),
	fade_speed = 3,
	visible = true,
	smooth_toggle = 0,
	last_toggle_time = 0,
	toggle_cooldown = 0.3,
	assistant_status_cache = {},
	assistant_avatars = {},
	noise_mat = Material("vgui/noisevhs"),
	col = {
		frameBG     = Color(10, 10, 19, 238),
		frameBorder = Color(90, 90, 95, 120),
		panelBG     = Color(8, 8, 16, 245),
		panelBorder = Color(255, 255, 255, 25),
		separator   = Color(255, 255, 255, 12),
		text        = Color(200, 200, 200, 255),
		textDim     = Color(160, 160, 165, 180),
		textMuted   = Color(100, 100, 108, 140),
		textBlood   = Color(180, 40, 35, 255),
		textTitle   = Color(200, 200, 200, 255),
		rowDead     = Color(160, 35, 35, 255),
	},
	blood_drips = {},
}

if traitor_panel.noise_mat:IsError() then
	traitor_panel.noise_mat = Material("vgui/white")
end

for i = 1, math.random(4, 7) do
	traitor_panel.blood_drips[i] = {
		x = math.random(0, traitor_panel.width),
		w = math.random(1, 2),
		h = math.random(tp_scale(8), tp_scale(28)),
		alpha = math.random(8, 22),
		speed = math.Rand(0.15, 0.5),
		offset = math.Rand(0, math.pi * 2),
	}
end

local function tp_fit_text(font, text, maxW)
	if not text or maxW <= 0 then return "" end
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxW then return text end
	local dots = "..."
	local dotsW = surface.GetTextSize(dots)
	if dotsW >= maxW then return "" end
	local lo, hi = 0, #text
	while lo < hi do
		local mid = math.floor((lo + hi + 1) * 0.5)
		if surface.GetTextSize(string.sub(text, 1, mid) .. dots) <= maxW then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return string.sub(text, 1, lo) .. dots
end

local function tp_paint_bloody_title(text, cx, cy)
	local font = "ZCity_Veteran"
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(text)
	local bx, by = cx - tw * 0.5, cy - th * 0.5
	local t = CurTime()
	local pulse = math.sin(t * 1.5) * 0.15 + 0.85

	draw.SimpleText(text, font, bx + 2, by + 2, Color(40, 4, 2, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx + 1, by + 1, Color(90, 8, 6, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(text, font, bx, by, Color(140 * pulse, 15 * pulse, 12 * pulse, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	if math.random() > 0.96 then
		draw.SimpleText(text, font, bx + math.random(-2, 2), by + math.random(-1, 1), Color(180, 20, 15, math.random(25, 60)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

local function tp_get_traitor_words(ply)
	local w1 = IsValid(ply) and ply:GetNWString("HMCD_TraitorWord", "") or ""
	local w2 = IsValid(ply) and ply:GetNWString("HMCD_TraitorWord2", "") or ""

	if w1 == "" and IsValid(ply) then w1 = ply.HMCD_TraitorWord or "" end
	if w2 == "" and IsValid(ply) then w2 = ply.HMCD_TraitorWordSecond or "" end

	local mode = zb and zb.modes and zb.modes.hmcd
	if w1 == "" and mode then w1 = mode.TraitorWord or "" end
	if w2 == "" and mode then w2 = mode.TraitorWordSecond or "" end

	return w1, w2
end

local function tp_paint_frame(x, y, w, h)
	local col = traitor_panel.col
	local mat = traitor_panel.noise_mat

	draw.RoundedBox(0, x, y, w, h, col.frameBG)

	if not mat:IsError() then
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, 6)
		local nx, ny = math.random(0, 512), math.random(0, 512)
		surface.DrawTexturedRectUV(x, y, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
	end

	for ly = y, y + h, 3 do
		surface.SetDrawColor(0, 0, 0, 12)
		surface.DrawRect(x, ly, w, 1)
	end

	local t = CurTime()
	for _, drip in ipairs(traitor_panel.blood_drips) do
		local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
		surface.SetDrawColor(100, 15, 12, math.floor(drip.alpha * pulse))
		surface.DrawRect(x + drip.x % w, y, drip.w, math.min(drip.h, h))
	end

	surface.SetDrawColor(col.frameBorder)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(col.panelBorder)
	surface.DrawOutlinedRect(x + 2, y + 2, w - 4, h - 4, 1)
end


local function CreateAvatarPanel(steamid)
    if not steamid or steamid == "" then return nil end
    
    if traitor_panel.assistant_avatars[steamid] and IsValid(traitor_panel.assistant_avatars[steamid]) then
        return traitor_panel.assistant_avatars[steamid]
    end
    

    local avatar = vgui.Create("AvatarImage")
    avatar:SetSize(traitor_panel.avatar_size, traitor_panel.avatar_size)
    avatar:SetVisible(false) 
    
    local ply = player.GetBySteamID(steamid)
    if IsValid(ply) then
        avatar:SetPlayer(ply, traitor_panel.avatar_size)
    end
    
    traitor_panel.assistant_avatars[steamid] = avatar
    return avatar
end


hook.Add("PlayerButtonDown", "TraitorPanelToggle", function(ply, btn)
    if ply ~= LocalPlayer() or btn ~= KEY_F4 then return end
    if not LocalPlayer().isTraitor then return end 
    

    local current_time = CurTime()
    if current_time - traitor_panel.last_toggle_time < traitor_panel.toggle_cooldown then
        return
    end
    
    traitor_panel.last_toggle_time = current_time
    traitor_panel.visible = not traitor_panel.visible
    
    if traitor_panel.visible then
        surface.PlaySound("buttons/button14.wav")
    end
end)




net.Receive("HMCD_UpdateTraitorAssistants", function()
    local count = net.ReadUInt(8)
    MODE.TraitorsLocal = {}
    
    for i = 1, count do
        local color = net.ReadColor()
        local name = net.ReadString()
        local steamID = net.ReadString()
        
        table.insert(MODE.TraitorsLocal, {color, name, steamID})
    end
end)


net.Receive("HMCD_TraitorDeathState", function()
    local traitor_name = net.ReadString()
    local is_alive = net.ReadBool()
    
    if traitor_name and traitor_name ~= "" then
        traitor_panel.assistant_status_cache[traitor_name] = is_alive
    end
end)

hook.Add("HUDPaint", "DrawTraitorPanel", function()
	local ply = LocalPlayer()
	if not ply.isTraitor or not ply:Alive() then
		traitor_panel.visible = false
		for _, avatar in pairs(traitor_panel.assistant_avatars) do
			if IsValid(avatar) then avatar:SetVisible(false) end
		end
		return
	end

	local col = traitor_panel.col
	local pad = traitor_panel.padding
	local pw = math.Clamp(math.floor(ScrW() * 0.17), 260, 380)
	traitor_panel.width = pw

	local target = traitor_panel.visible and 0 or pw + 40
	traitor_panel.smooth_toggle = Lerp(FrameTime() * 10, traitor_panel.smooth_toggle, target)

	local is_main = ply.MainTraitor
	local height = is_main and traitor_panel.height or traitor_panel.assist_height
	local x = ScrW() - pw - ScreenScale(10) + traitor_panel.smooth_toggle
	local y = ScrH() * 0.5 - height * 0.5
	local cx = x + pw * 0.5

	if traitor_panel.smooth_toggle > pw + 30 then
		for _, avatar in pairs(traitor_panel.assistant_avatars) do
			if IsValid(avatar) then avatar:SetVisible(false) end
		end
		return
	end

	tp_paint_frame(x, y, pw, height)

	local headerH = tp_scale(34)
	tp_paint_bloody_title(is_main and "ПРЕДАТЕЛЬ" or "ПОМОЩНИК", cx, y + headerH * 0.5)

	surface.SetDrawColor(col.separator)
	surface.DrawRect(x + pad, y + headerH, pw - pad * 2, 1)

	local hintY = y + headerH + tp_scale(10)
	draw.SimpleText("F4 — свернуть", "ZB_InterfaceSmall", cx, hintY, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local word_y = hintY + tp_scale(16)
	draw.SimpleText("Кодовые слова", "ZB_ScoreboardHeader", cx, word_y, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	word_y = word_y + tp_scale(14)
	local word1, word2 = tp_get_traitor_words(ply)
	if word1 == "" then word1 = "—" end
	if word2 == "" then word2 = "—" end
	draw.SimpleText("\"" .. word1 .. "\"", "ZCity_Veteran", cx, word_y, col.textBlood, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	word_y = word_y + tp_scale(18)
	draw.SimpleText("\"" .. word2 .. "\"", "ZCity_Veteran", cx, word_y, col.textBlood, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if not is_main then
		for _, avatar in pairs(traitor_panel.assistant_avatars) do
			if IsValid(avatar) then avatar:SetVisible(false) end
		end
		return
	end

	for _, avatar in pairs(traitor_panel.assistant_avatars) do
		if IsValid(avatar) then avatar:SetVisible(false) end
	end

	local assist_y = word_y + tp_scale(22)
	MODE.TraitorsLocal = MODE.TraitorsLocal or {}
	local has_assistants = #MODE.TraitorsLocal > (ply.MainTraitor and 1 or 0)

	if not has_assistants then
		draw.SimpleText("Нет сообщников", "ZB_InterfaceSmall", cx, assist_y, col.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	draw.SimpleText("Сообщники", "ZB_ScoreboardHeader", cx, assist_y, col.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	assist_y = assist_y + tp_scale(18)

	local rowH = tp_scale(22)
	local avSz = traitor_panel.avatar_size
	local nameMaxW = pw - traitor_panel.left_padding - pad
	local rowIdx = 0

	for _, traitor_info in ipairs(MODE.TraitorsLocal) do
		if not traitor_info or #traitor_info < 2 then continue end
		if ply.MainTraitor and ply.CurAppearance and traitor_info[2] == ply.CurAppearance.AName then continue end

		local color = traitor_info[1]
		local name = traitor_info[2]
		local steamID = traitor_info[3] or ""

		local player_found
		for _, v in player.Iterator() do
			if v.isTraitor and v.CurAppearance and v.CurAppearance.AName == name then
				player_found = v
				break
			end
		end

		local is_alive = traitor_panel.assistant_status_cache[name] ~= false
		if player_found then
			is_alive = player_found:Alive() and (not player_found.organism or not player_found.organism.incapacitated)
			traitor_panel.assistant_status_cache[name] = is_alive
		end

		if not is_alive then
			traitor_panel.dead_anim[name] = traitor_panel.dead_anim[name] or 255
			traitor_panel.dead_anim[name] = math.max(traitor_panel.dead_anim[name] - FrameTime() * 100 * traitor_panel.fade_speed, 0)
			if traitor_panel.dead_anim[name] <= 0 then continue end
		else
			traitor_panel.dead_anim[name] = nil
		end

		local alpha = traitor_panel.dead_anim[name] or 255
		local rowColor = is_alive and Color(color.r, color.g, color.b, alpha) or Color(col.rowDead.r, col.rowDead.g, col.rowDead.b, alpha)
		local display_name = tp_fit_text("ZCity_Veteran", name, nameMaxW)
		local status = is_alive and "" or " [мёртв]"

		rowIdx = rowIdx + 1
		local rowY = assist_y
		if rowIdx % 2 == 0 then
			surface.SetDrawColor(255, 255, 255, 4)
			surface.DrawRect(x + pad, rowY - rowH * 0.5, pw - pad * 2, rowH)
		end

		local avX, avY = x + pad, rowY - avSz * 0.5
		if steamID ~= "" and IsValid(player.GetBySteamID(steamID)) then
			local avatar = CreateAvatarPanel(steamID)
			if avatar then
				avatar:SetPos(avX, avY)
				avatar:SetSize(avSz, avSz)
				avatar:SetAlpha(alpha)
				avatar:SetVisible(true)
				surface.SetDrawColor(col.panelBorder.r, col.panelBorder.g, col.panelBorder.b, alpha)
				surface.DrawOutlinedRect(avX, avY, avSz, avSz, 1)
			end
		end

		draw.SimpleText(display_name .. status, "ZCity_Veteran", x + traitor_panel.left_padding, rowY, rowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		assist_y = assist_y + rowH
		if assist_y > y + height - tp_scale(12) then break end
	end
end)


local function resetTraitorPanel()
	traitor_panel.dead_anim = {}
	traitor_panel.smooth_toggle = traitor_panel.width + 40
	traitor_panel.visible = false
	for _, avatar in pairs(traitor_panel.assistant_avatars) do
		if IsValid(avatar) then
			avatar:SetVisible(false)
		end
	end
end

hook.Add("zbClientModeCleanup", "HMCD_ResetTraitorPanel", function(rnd)
	if rnd == "hmcd" then return end
	resetTraitorPanel()
end)

hook.Add("PostPlayerDeath", "ClearTraitorPanel", function(ply)
	if ply == LocalPlayer() then
		resetTraitorPanel()
	end
end)


hook.Add("Think", "UpdateTraitorAssistants", function()
	if not LocalPlayer().isTraitor or not LocalPlayer().MainTraitor then return end

	if not traitor_panel.next_assistant_check or traitor_panel.next_assistant_check < CurTime() then
		traitor_panel.next_assistant_check = CurTime() + 0.5
		
		for name, alpha in pairs(traitor_panel.dead_anim) do
			local is_alive = false
			for _, v in player.Iterator() do
				if v.isTraitor and v.CurAppearance and v.CurAppearance.AName == name then
					is_alive = v:Alive() and (not v.organism or not v.organism.incapacitated)
					break
				end
			end
			
			if is_alive then
				traitor_panel.dead_anim[name] = nil
			end
		end
	end
end)


hook.Add("Think", "RequestTraitorStatus", function()
	if not LocalPlayer().isTraitor or not LocalPlayer().MainTraitor then return end
	
	if not traitor_panel.next_status_request or traitor_panel.next_status_request < CurTime() then
		traitor_panel.next_status_request = CurTime() + 2
		
		net.Start("HMCD_RequestTraitorStatuses")
		net.SendToServer()
	end
end)
