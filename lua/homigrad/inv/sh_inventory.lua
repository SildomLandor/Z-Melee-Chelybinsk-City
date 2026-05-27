hg.TraitorLoot = {
	["weapon_sogknife"] = 10,
	["weapon_buck200knife"] = 10,
	["weapon_hg_shuriken"] = 9,
	["weapon_p22"] = 9,
	["weapon_traitor_ied"] = 8,
	["weapon_traitor_poison1"] = 7,
	["weapon_traitor_poison2"] = 6,
	["weapon_traitor_poison3"] = 5,
	["weapon_hg_smokenade_tpik"] = 4,
	["weapon_hg_rgd_tpik"] = 3,
	["weapon_walkie_talkie"] = 2,
	["weapon_adrenaline"] = 1,
	["hg_flashlight"] = 1,
}

if CLIENT then
	hook.Add("Player_Death","foundloot",function(ply)
		if IsValid(ply.FakeRagdoll) then ply.FakeRagdoll.foundloot = table.Copy(ply.foundloot) end
		ply.foundloot = {}
	end)

	local OpenInv
	net.Receive("should_open_inv", function()
		local ent = net.ReadEntity()
		local inv = net.ReadTable()
		local armors = net.ReadTable()
		if not IsValid(ent) then return end
		OpenInv(ent, inv, armors)
	end)

	local buttons = {}

	local invCol = {
		frameBG       = Color(10, 10, 19, 235),
		frameBorder   = Color(90, 90, 95, 120),
		panelBG       = Color(8, 8, 16, 200),
		text          = Color(200, 200, 200, 255),
		textDim       = Color(160, 160, 165, 180),
		textMuted     = Color(100, 100, 108, 140),
		separator     = Color(255, 255, 255, 12),
		scrollTrack   = Color(255, 255, 255, 6),
		scrollGrip    = Color(200, 200, 200, 60),
		scrollGripHov = Color(200, 200, 200, 100),
	}

	local invNoiseMat = Material("vgui/noisevhs")
	if invNoiseMat:IsError() then invNoiseMat = Material("vgui/white") end

	local function InvStyleScrollbar(sbar)
		if not IsValid(sbar) then return end
		sbar:SetHideButtons(true)
		sbar.Paint = function(_, sw, sh)
			surface.SetDrawColor(invCol.scrollTrack)
			surface.DrawRect(0, 0, sw, sh)
		end
		sbar.btnGrip.Paint = function(grip, sw, sh)
			local c = grip:IsHovered() and invCol.scrollGripHov or invCol.scrollGrip
			surface.SetDrawColor(c)
			surface.DrawRect(2, 0, sw - 4, sh)
		end
	end
	local function BuildLootTakeKey(owner, tblIndex, thing)
		if not IsValid(owner) then return "" end
		return owner:EntIndex() .. "|" .. tblIndex .. "|" .. thing
	end

	net.Receive("ply_take_item_begin_ack", function()
		local key = net.ReadString()
		local duration = net.ReadFloat()
		local button = buttons[key]
		if not IsValid(button) then return end
		button.HoldDuration = math.max(duration, 0)
		button.HoldStart = CurTime()
		button.HoldReady = true
	end)

	local function BeginTakeRequest(button, tblIndex, thing, item, owner)
		if not IsValid(button) then return end
		button.HoldKey = BuildLootTakeKey(owner, tblIndex, thing)
		button.HoldReady = false
		button.HoldDuration = nil
		button.HoldStart = CurTime()
		button.HoldRequested = true
		buttons[button.HoldKey] = button
		net.Start("ply_take_item_begin")
			net.WriteString(tblIndex)
			net.WriteString(thing)
			net.WriteTable(istable(item) and item or {item})
			net.WriteEntity(owner)
		net.SendToServer()
	end

	local function nameThings(i, thing)
		local weps = weapons.Get(i)
		local entss = scripted_ents.Get(i)
		if weps then return weps.PrintName end
		if entss then return entss.PrintName end
		if hg.armor and hg.armor[i] and hg.armor[i][thing] then return thing end
		if hg.attachmentslaunguage and hg.attachmentslaunguage[thing] then return thing end
		if i == "Money" then return "Money, " .. tostring(thing) .. "$" end
		return tostring(i)
	end

	local function getIconThing(i, thing, tab)
		if tab == "Weapons" and weapons.Get(i) then
			local GunTable = weapons.Get(i)
				local Icon = (GunTable.WepSelectIcon2 ~= nil and GunTable.WepSelectIcon2) or GunTable.WepSelectIcon
			local Overide = GunTable.WepSelectIcon2 == nil and true or false
			local HaveIcon = true
			return Icon, HaveIcon, Overide, GunTable.WepSelectIcon2box
		end

		if tab == "Attachments" and hg.attachmentsIcons[thing] then
			local AttIcon = hg.attachmentsIcons[thing]
			local HaveIcon = true
			return AttIcon, HaveIcon, false, true
		end

		if tab == "Armor" then
			local AttIcon = hg.armorIcons[thing]
			local HaveIcon = true
			return AttIcon, HaveIcon, false, true
		end

		if tab == "Money" then
			local AttIcon = "scrappers/money_icon.png"
			local HaveIcon = true
			return AttIcon, HaveIcon, false
		end
	end

	local functions2 = {
		["Weapons"] = function(ply, ent, wep)
			if true then return true end
		end,
		["Ammo"] = function(ply, ent, ammo, amt)
			if true then return true end
		end,
		["Armor"] = function(ply, ent, placement, armor)
			local slot = hg.armor and hg.armor[placement]
			if slot and slot[armor] and slot[armor].nodrop then return false end
			return true
		end,
		["Attachments"] = function(ply, ent, att, tbl)
			if true then return true end
		end,
		["Money"] = function(ply, ent)
			if true then return true end
		end,
	}

	local functions = {
		["Weapons"] = function(ply, ent, wep)
			local weapon = weapons.Get(wep)
			if (ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon() == wep) then return end
			--if not hg.weaponInv.CanInsert(ply, weapon) or ply:HasWeapon(wep) then return false end
			return true
		end,
		["Ammo"] = function(ply, ent, ammo, amt)
			if true then return true end
		end,
		["Armor"] = function(ply, ent, placement, armor)
			local armors = ply:GetNetVar("Armor",{})
			if armors[placement] then return false end
			if true then return true end
		end,
		["Attachments"] = function(ply, ent, att, tbl)
			if true then return true end
		end,
		["Money"] = function(ply, ent)
			if true then return true end
		end,
	}

	local cooldown = 0

	local function TakeItem(tblIndex, thing, item, owner)
		local item = istable(item) and item or {item}

		net.Start("ply_take_item")
			net.WriteString(tblIndex)
			net.WriteString(thing)
			net.WriteTable(item)
			net.WriteEntity(owner)
		net.SendToServer()
	end

	local plyMenu

	hook.Add("OnNetVarSet","inventory_netvar",function(index,key,var)
		if key == "Inventory" then
			local ent = Entity(index)

			if IsValid(plyMenu) and plyMenu.entindex == index then
				timer.Simple(0,function()
					--OpenInv(ent)
				end)
			end
		end
	end)

	OpenInv = function(ent, invOverride, armorOverride)
		if IsValid(plyMenu) then
			plyMenu:Remove()
			plyMenu = nil
		end

		cooldown = CurTime() + 0
		if not IsValid(ent) then return end

		local ply = LocalPlayer()
		local inv = invOverride or ent:GetNetVar("Inventory")
		if not inv then return end

		if invOverride or armorOverride then
			local idx = ent:EntIndex()
			zb.net = zb.net or {}
			zb.net[idx] = zb.net[idx] or {}
			zb.net[idx].Inventory = inv
			if armorOverride then zb.net[idx].Armor = armorOverride end
		end

		inv = table.Copy(inv)
		inv["Money"] = {}
		inv["Armor"] = armorOverride or ent:GetNetVar("Armor") or {}

		local nameStr = "контейнер"
		if ent:IsPlayer() or ent:IsRagdoll() then
			nameStr = ent:GetPlayerName() or string.NiceName(ent:GetClass())
		end
		local title = nameStr .. " — инвентарь"

		local margin = ScreenScale(6)
		local topBarH = ScreenScaleH(34)
		local bottomBarH = ScreenScaleH(22)
		local gridCols = 5
		local gridPad = ScreenScale(8)
		local sizeX = math.floor(ScrW() * 0.44)
		local boxW = sizeX / 6
		local boxH = sizeX / 10
		local colWide = sizeX / gridCols - sizeX / 16 / 6
		local rowH = boxH + ScreenScale(6)

		local itemCount = 0
		for tab, things in pairs(inv) do
			if not istable(things) or not functions2[tab] then continue end
			for i, thing in pairs(things) do
				local thing1 = istable(thing) and thing or {thing}
				if not functions2[tab](ply, ent, i, unpack(thing1)) then continue end
				if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end
				itemCount = itemCount + 1
			end
		end

		local rows = math.max(1, math.ceil(itemCount / gridCols))
		local chromeH = topBarH + bottomBarH + margin * 2
		local contentH = rows * rowH + gridPad
		local minFrameH = chromeH + rowH + gridPad
		local maxFrameH = math.floor(ScrH() * 0.88)
		local sizeY = math.Clamp(chromeH + contentH, minFrameH, maxFrameH)

		local shakeX, shakeY = 0, 0
		local targetShakeX, targetShakeY = 0, 0
		local nextShakeSample = 0
		local shakeStrength = 0.45

		local bloodDrips = {}
		for i = 1, math.random(4, 7) do
			bloodDrips[i] = {
				x = math.random(margin, sizeX - margin),
				w = math.random(1, 2),
				h = math.random(ScreenScaleH(8), ScreenScaleH(28)),
				alpha = math.random(6, 22),
				speed = math.Rand(0.15, 0.6),
				offset = math.Rand(0, math.pi * 2),
			}
		end

		plyMenu = vgui.Create("ZFrame")
		plyMenu.ent = ent
		plyMenu.entindex = ent:EntIndex()
		plyMenu:SetTitle("")
		plyMenu:SetSize(sizeX, sizeY)
		plyMenu:Center()
		plyMenu:MakePopup()
		plyMenu:SetKeyboardInputEnabled(false)
		plyMenu:ShowCloseButton(false)
		plyMenu:SetDraggable(false)
		plyMenu:SetColorBG(invCol.frameBG)
		plyMenu:SetColorBR(invCol.frameBorder)
		plyMenu:SetAlpha(0)
		plyMenu:AlphaTo(255, 0.12, 0)
		plyMenu.Created = CurTime()

		plyMenu.Think = function(self)
			local t = CurTime()
			if t >= nextShakeSample then
				nextShakeSample = t + 0.035
				targetShakeX = math.Rand(-shakeStrength, shakeStrength)
				targetShakeY = math.Rand(-shakeStrength * 0.6, shakeStrength * 0.6)
			end
			local lerpRate = math.Clamp(FrameTime() * 22, 0, 1)
			shakeX = Lerp(lerpRate, shakeX, targetShakeX)
			shakeY = Lerp(lerpRate, shakeY, targetShakeY)

			local e = self.ent
			if not IsValid(e) then self:Close() return end
			local lp = LocalPlayer()
			local org = lp.organism
			if (org and org.otrub) or not lp:Alive() then self:Remove() return end
			if (e:GetPos() - LocalPlayer():GetPos()):LengthSqr() > 125 ^ 2 then self:Remove() return end
			if e:IsPlayer() and (not IsValid(e.FakeRagdoll) or (e.organism and not e.organism.otrub)) then self:Remove() return end
			if input.IsKeyDown(KEY_R) then self:Close() end
		end

		plyMenu.PaintOver = function(self, w, h)
			local t = CurTime()

			if not invNoiseMat:IsError() then
				surface.SetMaterial(invNoiseMat)
				surface.SetDrawColor(255, 255, 255, 6)
				local nx, ny = math.random(0, 512), math.random(0, 512)
				surface.DrawTexturedRectUV(0, 0, w, h, nx / 512, ny / 512, nx / 512 + w / 768, ny / 512 + h / 768)
			end

			for y = 0, h, 3 do
				surface.SetDrawColor(0, 0, 0, 12)
				surface.DrawRect(0, y, w, 1)
			end

			for _, drip in ipairs(bloodDrips) do
				local pulse = math.sin(t * drip.speed + drip.offset) * 0.3 + 0.7
				surface.SetDrawColor(100, 15, 12, math.floor(drip.alpha * pulse))
				surface.DrawRect(drip.x + shakeX, 0, drip.w, drip.h)
			end

			surface.SetDrawColor(invCol.frameBorder)
			surface.DrawOutlinedRect(0, 0, w, h, 1)

			surface.SetDrawColor(invCol.separator)
			surface.DrawRect(margin, topBarH - 1, w - margin * 2, 1)

			surface.SetFont("ZCity_Veteran")
			surface.SetTextColor(invCol.text)
			local titleW = surface.GetTextSize(title)
			surface.SetTextPos(w * 0.5 - titleW * 0.5 + shakeX, ScreenScaleH(6) + shakeY * 0.5)
			surface.DrawText(title)

			surface.SetFont("ZB_InterfaceSmall")
			surface.SetTextColor(invCol.textMuted)
			local hint = "R — закрыть | удерж. ЛКМ — взять | ПКМ — подсказка"
			local hintW = surface.GetTextSize(hint)
			surface.SetTextPos(w * 0.5 - hintW * 0.5 + shakeX * 0.3, h - bottomBarH + ScreenScaleH(4))
			surface.DrawText(hint)
		end

		local DScrollPanel = vgui.Create("DScrollPanel", plyMenu)
		DScrollPanel:Dock(FILL)
		DScrollPanel:DockMargin(margin, topBarH, margin, bottomBarH)
		InvStyleScrollbar(DScrollPanel:GetVBar())

		local grid = vgui.Create("DGrid", DScrollPanel)
		grid:Dock(TOP)
		grid:DockMargin(ScreenScale(4), ScreenScale(4), ScreenScale(4), ScreenScale(4))
		grid:SetCols(gridCols)
		grid:SetColWide(colWide)
		grid:SetRowHeight(rowH)
		grid:SetTall(rows * rowH + gridPad)
		local count = 0
		for tab, things in pairs(inv) do
			if not istable(things) then continue end
			for i, thing in pairs(things) do
				ent.foundloot = ent.foundloot or {}
				count = count + ((ent:IsPlayer() or ent:IsRagdoll()) and ((hg.TraitorLoot[i] and ent:IsPlayer()) and 2 or 0.5) or 1) * (not ent.foundloot[i] and 1 or 0)
			end
		end
		local searchCycle = CurTime() + 3
		function DScrollPanel:Paint(w, h)
			--draw.RoundedBox(0, 0, 0, w, h, invCol.panelBG)
			if (plyMenu.Created + count + 3) >= CurTime() then
				local txt = "обыск"
				for i = 1, 3 - math.Round(searchCycle - CurTime(), 0) do
					txt = txt .. "."
				end
				if searchCycle < CurTime() then searchCycle = CurTime() + 3 end
				draw.SimpleText(txt, "ZCity_Veteran", w * 0.5, h * 0.42, invCol.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		local count2 = 0
		
		for tab, things in pairs(inv) do
			if not istable(things) or not functions2[tab] then continue end
			local keys = table.GetKeys(things)
			table.sort(keys,function(a,b)
				local atbl = weapons.Get(a)
				local wep = atbl and atbl.holsteredBone and not atbl.shouldntDrawHolstered
				return (ent.foundloot[a] and 1 or 0) > (ent.foundloot[b] and 1 or 0)//(hg.TraitorLoot[a] or 0) < (hg.TraitorLoot[b] or (wep and 1 or 0) or 0)
			end)
			
			for k, i in ipairs(keys) do
				local thing = things[i]
				local thing1 = istable(thing) and thing or {thing}

				if not functions2[tab](ply, ent, i, unpack(thing1)) then continue end

				ent.foundloot = ent.foundloot or {}

				if ent:IsPlayer() and IsValid(ent:GetActiveWeapon()) and ent:GetActiveWeapon():GetClass() == i then continue end
				count2 = count2 + (!ent.foundloot[i] and 1 or 0)//((ent:IsPlayer() or ent:IsRagdoll()) and ((hg.TraitorLoot[i] and ent:IsPlayer()) and 2 or 0.5) or 1) * (not ent.foundloot[i] and 1 or 0)

				local button = vgui.Create("DButton", plyMenu)
				button:SetText("")
				button:DockMargin(5, 0, 2, 0)
				button:SetSize(0, 0)
				button.Created = CurTime() + (IsValid(ent.FakeRagdoll) and !ent.foundloot[i] and 2 or 0) + count2
				button.Think = function(self)
					if self.Created and self.Created < CurTime() then
						self:SetSize(boxW, boxH)
						self:SetAlpha(0)
						surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
						self:AlphaTo(255, 0.3, 0)
						ent.foundloot[i] = true
						self.Created = nil
					end

					local holding = self:IsHovered() and input.IsMouseDown(MOUSE_LEFT)
					if not holding then
						self.HoldPressed = false
						self.HoldRequested = false
						self.HoldReady = false
						self.HoldDuration = nil
						self.HoldStart = nil
						if self.HoldKey then
							buttons[self.HoldKey] = nil
						end
						return
					end

					if not self.HoldPressed then
						self.HoldPressed = true
						BeginTakeRequest(self, tab, i, thing, ent)
					end

					if not self.HoldReady or not self.HoldDuration or not self.HoldStart then return end
					if CurTime() < self.HoldStart + self.HoldDuration then return end
					if cooldown > CurTime() then return end

					cooldown = CurTime() + 0.3

					if not functions[tab](ply, ent, i, unpack(thing1)) then
						local OptionsMenu = DermaMenu()
							OptionsMenu:AddOption("У вас есть такой предмет", function() end)
						OptionsMenu:Open()
						self.HoldPressed = false
						self.HoldRequested = false
						self.HoldReady = false
						self.HoldDuration = nil
						self.HoldStart = nil
						return
					end

					if istable(thing) then
						thing["render"] = {}
					end

					surface.PlaySound("arc9_eft_shared/generic_mag_pouch_in" .. math.random(7) .. ".ogg")
					grid.SoundKD = CurTime() + 0.2
					self:Remove()
					TakeItem(tab, i, thing, ent)
				end

				button.DoClick = function() end

				button.DoRightClick = function()
					if cooldown > CurTime() then return end
					cooldown = CurTime() + 0.3

					if not functions[tab](ply, ent, i, unpack(thing1)) then
						local OptionsMenu = DermaMenu()
							OptionsMenu:AddOption("У вас есть такой предмет", function() end)
						OptionsMenu:Open()
						return
					end

					local OptionsMenu = DermaMenu()
						OptionsMenu:AddOption("Зажмите LMB для взятия", function() end)
					OptionsMenu:Open()
				end

				local itemName = nameThings(i, thing)
				button.col1 = 100
				button.Paint = function(self, w, h)
					self.col1 = Lerp(0.1, self.col1, self:IsHovered() and 255 or 100)

					if self:IsHovered() then
						self.SoundKD = self.SoundKD or 0
						if (grid.SoundKD or 0) < CurTime() and self.SoundKD < CurTime() then
							surface.PlaySound("arc9_eft_shared/generic_mag_pouch_out" .. math.random(7) .. ".ogg")
						end
						self.SoundKD = CurTime() + 0.1
					end

					surface.SetDrawColor(self.col1, 0, 0, 15)
					surface.DrawRect(0, 0, w, h)

					local Icon, HaveIcon, Overide, Quad = getIconThing(i, thing, tab)
					if Icon then
						self.Icon = self.Icon or (isstring(Icon) and Material(Icon)) or Icon
					end

					if HaveIcon and self.Icon then
						if Overide and isnumber(Icon) then
							surface.SetTexture(self.Icon)
						else
							surface.SetMaterial(self.Icon)
						end
						surface.SetDrawColor(255, 255, 255)
						surface.DrawTexturedRect(
							Quad and w / 5 + 5 or -5,
							5,
							Quad and (w / 2 + 2.5) or (w + 10),
							Quad and h / 1.3 or h - 10
						)
					end

					surface.SetDrawColor(self.col1, 0, 0, self.col1)
					surface.DrawOutlinedRect(0, 0, w, h, 1)

					if self.HoldPressed and self.HoldReady and self.HoldDuration and self.HoldStart and self.HoldDuration > 0 then
						local progress = math.Clamp((CurTime() - self.HoldStart) / self.HoldDuration, 0, 1)
						surface.SetDrawColor(255, 255, 255, 255)
						surface.DrawRect(0, h - 4, w * progress, 4)
					end

					local text = (tab == "Ammo" and game.GetAmmoName(itemName)) or language.GetPhrase(itemName)
					local subLine = utf8.sub(text, 18)
					text = utf8.sub(text, 1, 17) .. "\n" .. subLine
					local textY = HaveIcon and h / ((#subLine > 0 and 1.65) or 1.3) or h / 3
					draw.DrawText(text, "ZCity_VerySuperTiny", w / 2, textY, color_white, TEXT_ALIGN_CENTER)
				end
				button.OnRemove = function(self)
					if self.HoldKey then
						buttons[self.HoldKey] = nil
					end
				end
				grid:AddItem(button)
			end
		end

		grid:InvalidateLayout(true)
		local canvas = DScrollPanel:GetCanvas()
		if IsValid(canvas) then
			canvas:SetTall(math.max(grid:GetTall(), DScrollPanel:GetTall()))
		end
	end
end