local MODE = MODE

local function playerHasBomb(ply)
	if not IsValid(ply) then return false end

	local wep = ply:GetWeapon("weapon_zb_bomb")
	if IsValid(wep) then return true end

	for _, item in ipairs(ply:GetWeapons()) do
		if IsValid(item) and item:GetClass() == "weapon_zb_bomb" then
			return true
		end
	end

	return false
end

local lastBombCarrier

local function getBombCarrier()
	for _, ply in ipairs(team.GetPlayers(0)) do
		if IsValid(ply) and ply:Alive() and playerHasBomb(ply) then
			return ply
		end
	end
end

local function updateBombCarrierChat()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local inBombRound = zb.CROUND == "cstrike" and zb.rtype == "bomb"
	if not inBombRound or lply:Team() ~= 0 then
		lastBombCarrier = nil
		return
	end

	local carrier = getBombCarrier()
	if carrier == lastBombCarrier then return end

	lastBombCarrier = carrier
	if IsValid(carrier) then
		chat.AddText(color_white, "У ", Color(255, 235, 160), carrier:Nick(), color_white, " бомба")
	end
end

local function drawSiteLabel(site, label, xFrac)
	local center = zb.GetBombSiteCenter(site)
	if not center then return end

	local ply = LocalPlayer()
	local inSite = zb.BombInSite(ply:EyePos(), site)
	local dist = math.Round(zb.InchesToMeters(center:Distance(ply:EyePos())))
	local maxM = math.Round(zb.InchesToMeters(zb.GetBombSiteRadius(site)))
	local clr = site == 1 and zb.Points.BOMB_ZONE_A.Color or zb.Points.BOMB_ZONE_B.Color

	local w, h = ScreenScale(60), ScreenScale(10)
	local scr = center:ToScreen()
	local x = scr.visible and scr.x or (ScrW() * xFrac)

	if inSite then
		surface.SetDrawColor(122, 0, 0, 255)
		surface.DrawRect(x - w / 2, 0, w, h * 2)
		surface.SetFont("ZCity_Veteran")
		surface.SetTextColor(255, 255, 255)
		local lx, ly = surface.GetTextSize("Вы на зоне!")
		surface.SetTextPos(x - lx / 2, h / 2 + ly / 2)
		surface.DrawText("Вы на зоне!")
	end

	surface.SetDrawColor(clr.r, clr.g, clr.b, 255)
	surface.DrawRect(x - w / 2, 0, w, h)

	local txt = "ЗОНА " .. label .. ": " .. dist .. " м (макс " .. maxM .. ")"
	surface.SetFont("ZCity_Veteran")
	surface.SetTextColor(255, 255, 255)
	local lx, ly = surface.GetTextSize(txt)
	surface.SetTextPos(x - lx / 2, h / 2 - ly / 2)
	surface.DrawText(txt)
end

function MODE:AddHudPaint()
	if zb.rtype == "bomb" then
		drawSiteLabel(1, "A", 0.35)
		drawSiteLabel(2, "B", 0.65)
	elseif zb.rtype == "hostage" then
		local pts = zb.ClPoints["HOSTAGE_DELIVERY_ZONE"]
		if not pts or #pts < 1 then return end

		local center = Vector(0, 0, 0)
		for _, pt in ipairs(pts) do
			center = center + pt.pos
		end
		center = center / #pts

		local w, h = ScreenScale(60), ScreenScale(10)
		local tscr = center:ToScreen()
		local clr = zb.Points["HOSTAGE_DELIVERY_ZONE"].Color

		surface.SetDrawColor(clr.r, clr.g, clr.b, 255)
		surface.DrawRect(tscr.x - w * 1.15, 0, w * 1.15 * 2, h)

		local txt = "ЗОНА ДОСТАВКИ ЗАЛОЖНИКОВ: " .. math.Round(zb.InchesToMeters(center:Distance(LocalPlayer():EyePos()))) .. " м"
		surface.SetFont("ZCity_Veteran")
		surface.SetTextColor(255, 255, 255)
		local lx, ly = surface.GetTextSize(txt)
		surface.SetTextPos(tscr.x - lx / 2, h / 2 - ly / 2)
		surface.DrawText(txt)
	end
end

local function drawBombSites3D()
	if zb.CROUND ~= "cstrike" or zb.rtype ~= "bomb" then return end

	render.SetColorMaterial()

	for site = 1, 2 do
		local center = zb.GetBombSiteCenter(site)
		if not center then continue end

		local radius = zb.GetBombSiteRadius(site)

		local label = "SITE " .. (site == 1 and "A" or "B")
		local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
		cam.Start3D2D(center + Vector(0, 0, math.min(radius * 0.5, 128)), ang, 0.15)
			draw.SimpleTextOutlined(label, "ChatFont", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		cam.End3D2D()
	end
end

hook.Add("PostDrawTranslucentRenderables", "ZB_CStrike_BombSites", function(_, skybox)
	if skybox then return end
	drawBombSites3D()
end)

hook.Add("Think", "ZB_CStrike_BombCarrierChat", updateBombCarrierChat)
