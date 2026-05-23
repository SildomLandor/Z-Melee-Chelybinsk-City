MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start", function()
	surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start("swat4")
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190, 0, 0),
		color2 = Color(190, 0, 0),
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0, 120, 190),
		color2 = Color(0, 120, 190),
	},
}

hook.Add("StartCommand", "TDM_DisallowMoveOrShoting", function(ply, mv)
	if zb.CROUND ~= "tdm" and zb.CROUND ~= "cstrike" then return end
	if (zb.ROUND_START or 0) + 20 > CurTime() then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
	local startTime = zb.ROUND_START or CurTime()
	if startTime + 7.5 < CurTime() then return end
	local fade = math.Clamp(startTime + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:AddHudPaint()
end

function MODE:HUDPaint()
	local startTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()

	if startTime + 20 > CurTime() then
		draw.SimpleText(string.FormattedTime(startTime + 20 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Press F3 to open buymenu", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime(math.max(startTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if startTime + 20 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()
	local fade = math.Clamp(startTime + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
	draw.SimpleText("ZBattle | " .. (self.PrintName or "Team Deathmatch"), "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local role = teams[team_]
	if not role then return end

	local colorRole = role.color1
	colorRole.a = 255 * fade
	draw.SimpleText("You are " .. role.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorObj = role.color2
	colorObj.a = 255 * fade
	draw.SimpleText(role.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local CreateEndMenu

net.Receive("tdm_roundend", function()
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local col = Color(255, 255, 255, 255)
local colSpect2 = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	hmcdEndMenu = vgui.Create("ZFrame")
	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	hmcdEndMenu:SetPos(ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end
	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local scroll = vgui.Create("DScrollPanel", hmcdEndMenu)
	scroll:SetPos(10, 80)
	scroll:SetSize(sizeX - 20, sizeY - 90)
	scroll.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local but = vgui.Create("DButton", scroll)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
			local col1 = ply:Alive() and colRed or colGray
			local col2 = ply:Alive() and colRedUp or colSpect1
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local nameCol = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(nameCol.r, nameCol.g, nameCol.b, nameCol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")

			lengthX, lengthY = surface.GetTextSize(ply:Frags() or "He quited...")
			surface.SetTextPos(w - lengthX - 15, h / 2 - lengthY / 2)
			surface.DrawText(ply:Frags() or "He quited...")
		end
		but.DoClick = function()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end
		scroll:AddItem(but)
	end
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end

surface.CreateFont("ZB_TDM_MENU", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	extended = true,
	weight = 400,
	antialias = true,
})
surface.CreateFont("ZB_TDM_DESC", {
	font = "Bahnschrift",
	size = ScreenScale(7),
	extended = true,
	weight = 400,
	antialias = true,
})
surface.CreateFont("ZB_TDM_CATEGORY", {
	font = "Bahnschrift",
	size = ScreenScale(6),
	extended = true,
	weight = 400,
	antialias = true,
})
surface.CreateFont("ZB_TDM_DESCSMALL", {
	font = "Bahnschrift",
	size = ScreenScale(5),
	extended = true,
	weight = 400,
	antialias = true,
})

local function PaintFrame(self, w, h)
	BlurBackground(self)
	surface.SetDrawColor(255, 0, 0, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
end

local function PaintPanel(self, w, h)
	surface.SetDrawColor(0, 0, 0, 155)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(255, 0, 0, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
end

local gradient_l = Material("vgui/gradient-l")

local function PaintPanel1(self, w, h)
	surface.SetDrawColor(0, 0, 0, 155)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(255, 0, 0, 128)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	draw.RoundedBox(0, 2.5, 2.5, w - 5, h - 5, Color(0, 0, 0, 140))
	surface.SetDrawColor(155, 0, 0, 55)
	surface.SetMaterial(gradient_l)
	surface.DrawTexturedRect(0, 0, w / 1.5, h)
end

local function PaintPanel2(self, w, h)
	surface.SetDrawColor(55, 155, 55, 25)
	surface.SetMaterial(gradient_l)
	surface.DrawTexturedRect(0, 0, w * 1.2, h)
end

local rtabFunc = function(self)
	local inset = 10
	if self.Image then inset = inset + self.Image:GetWide() end
	self:SetTextInset(inset, 2)
	local w = self:GetContentSize()
	self:SetSize(w + 10, self:GetTabHeight() + 7)
	DLabel.ApplySchemeSettings(self)
end

local function OpenBuyMenu()
	if IsValid(TDM_OpenedBuyMenu) then
		TDM_OpenedBuyMenu:Remove()
		TDM_OpenedBuyMenu = nil
	end

	local startTime = zb.ROUND_START or CurTime()
	if not LocalPlayer():Alive() or startTime + 40 < CurTime() then return end

	local buyItems = (CurrentRound() and CurrentRound().BuyItems) or MODE.BuyItems
	if not buyItems then return end

	local frame = vgui.Create("ZFrame")
	TDM_OpenedBuyMenu = frame
	frame:SetSize(ScrW() * 0.35, ScrH() * 0.85)
	frame:Center()
	frame:MakePopup()
	frame:SetTitle("Buy menu")
	frame.Paint = PaintFrame

	local sheet = vgui.Create("DPropertySheet", frame)
	sheet:Dock(FILL)
	sheet.Paint = function() end
	sheet.tabScroller:SetOverlap(0)
	sheet.tabScroller:DockMargin(8, 0, 8, 0)
	sheet:SetFadeTime(0.1)

	for categoryName, category in SortedPairsByMemberValue(buyItems, "Priority") do
		local categoryPanel = vgui.Create("DScrollPanel", sheet)
		categoryPanel.Paint = function() end

		for itemName, item in pairs(category) do
			if itemName == "Priority" then continue end
			if item.TeamBased and item.TeamBased ~= LocalPlayer():Team() then continue end

			local weapon = weapons.GetStored(item.ItemClass)
			local ent = scripted_ents.GetStored(item.ItemClass)

			local itemPanel = vgui.Create("DPanel", categoryPanel)
			itemPanel:SetSize(0, ScrH() * 0.1)
			itemPanel:Dock(TOP)
			itemPanel:DockMargin(0, 8, 0, 0)
			itemPanel.Paint = PaintPanel1

			if (weapon and ((weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName()) or weapon.IconOverride)) or (ent and ent.t.IconOverride) then
				local icon = vgui.Create("DImage", itemPanel)
				local boxed = (ent and ent.t.IconOverride) or (weapon and weapon.WepSelectIcon2box)
				icon:SetSize(ScrH() * (boxed and 0.1 or 0.17), ScrH() * 0.1)
				icon:Dock(LEFT)
				local pad = ScrH() * 0.07 / 2
				icon:DockMargin(5 + (boxed and pad or 0), 5, 5 + (boxed and pad or 0), 5)
				icon:SetImage((weapon and ((weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName() .. ".png") or weapon.IconOverride)) or (ent and ent.t.IconOverride) or "none")
			end

			local info = vgui.Create("DPanel", itemPanel)
			info:Dock(FILL)
			info:DockMargin(0, 5, 0, 0)
			info.Paint = function() end

			local nameLbl = vgui.Create("DLabel", info)
			nameLbl:SetText(itemName)
			nameLbl:DockMargin(10, 0, 5, 0)
			nameLbl:Dock(TOP)
			nameLbl:SetFont("ZB_TDM_MENU")
			nameLbl:SetSize(ScrW() * 0.5, ScrH() * 0.04)

			local priceLbl = vgui.Create("DLabel", info)
			priceLbl:SetText("Price: $" .. item.Price)
			priceLbl:DockMargin(10, 0, 5, 0)
			priceLbl:Dock(TOP)
			priceLbl:SetTextColor(Color(155, 200, 155))
			priceLbl:SetFont("ZB_TDM_DESC")
			priceLbl:SetSize(ScrW() * 0.5, ScrH() * 0.02)

			local buyBtn = vgui.Create("DButton", info)
			buyBtn:DockMargin(10, 5, 10, 10)
			buyBtn:Dock(LEFT)
			buyBtn:SetText("Buy")
			buyBtn:SetTextColor(Color(200, 200, 200))
			buyBtn:SetFont("ZB_TDM_DESC")
			buyBtn:SetHeight(ScrH() * 0.025)
			buyBtn.Paint = PaintPanel
			buyBtn.Item = {categoryName, itemName}
			buyBtn.DoClick = function()
				net.Start("tdm_buyitem")
				net.WriteTable(buyBtn.Item)
				net.SendToServer()
			end

			if weapon then
				local ammoType = weapon.Primary.Ammo ~= "none" and weapon.Primary.Ammo or weapon.Ammo or (weapons.GetStored(weapon.Base) and weapons.GetStored(weapon.Base).Primary.Ammo)
				if hg.ammotypeshuy[ammoType] then
					local ammoBtn = vgui.Create("DButton", info)
					ammoBtn:DockMargin(10, 5, 10, 10)
					ammoBtn:Dock(LEFT)
					ammoBtn:SetText(ammoType)
					ammoBtn:SetTextColor(Color(200, 200, 200))
					ammoBtn:SetFont("ZB_TDM_DESCSMALL")
					surface.SetFont("ZB_TDM_DESCSMALL")
					local tw = surface.GetTextSize(ammoType)
					ammoBtn:SetHeight(ScrH() * 0.025)
					ammoBtn:SetWidth(tw + 7)
					ammoBtn.Paint = PaintPanel

					local ammoEnt = "ent_ammo_" .. hg.ammotypeshuy[ammoType].name
					local ammoItemName
					for name2, ammoItem in pairs(buyItems["Ammo"] or {}) do
						if istable(ammoItem) and ammoItem.ItemClass == ammoEnt then
							ammoItemName = name2
							break
						end
					end

					if ammoItemName then
						ammoBtn.huy = {"Ammo", ammoItemName}
						ammoBtn.DoClick = function()
							net.Start("tdm_buyitem")
							net.WriteTable(ammoBtn.huy)
							net.SendToServer()
						end
					end
				end
			end

			if item.Attachments and #item.Attachments > 0 then
				local attGrid = vgui.Create("DGrid", itemPanel)
				local iconSize = math.ceil(ScrH() * 0.06)
				attGrid:Dock(RIGHT)
				attGrid:DockMargin(0, 5, 0, 0)
				attGrid:SetCols(4)
				attGrid:SetColWide(iconSize)
				attGrid:SetRowHeight(iconSize)
				attGrid.Paint = function() end

				for _, attachName in pairs(item.Attachments) do
					local attachBtn = vgui.Create("DImageButton")
					attachBtn:SetImage(hg.attachmentsIcons[attachName])
					attachBtn:SetSize(iconSize - 5, iconSize - 5)
					attachBtn.Attachment = {categoryName, itemName, attachName}
					attachBtn.DoClick = function()
						net.Start("tdm_buyitem")
						net.WriteTable(attachBtn.Attachment)
						net.SendToServer()
					end
					attachBtn.Paint = PaintPanel2
					attGrid:AddItem(attachBtn)
				end
			end
		end

		local tab = sheet:AddSheet(categoryName, categoryPanel)
		local rTab = tab.Tab
		rTab.Paint = PaintPanel
		rTab:SetFont("ZB_TDM_CATEGORY")
		rTab.ApplySchemeSettings = rtabFunc
	end

	local timeLbl = vgui.Create("DLabel", frame)
	timeLbl:SetText("Time Left: " .. string.FormattedTime(startTime + 40 - CurTime(), "%02i:%02i:%02i"))
	timeLbl:DockMargin(10, 0, 10, 10)
	timeLbl:Dock(BOTTOM)
	timeLbl:SetTextColor(color_white)
	timeLbl:SetFont("ZB_TDM_DESC")
	timeLbl:SetSize(0, ScrH() * 0.015)
	timeLbl.Think = function(self)
		if not LocalPlayer():Alive() or startTime + 40 < CurTime() then
			if IsValid(TDM_OpenedBuyMenu) then TDM_OpenedBuyMenu:Remove() end
			return
		end
		self:SetText("Time Left: " .. string.FormattedTime(startTime + 40 - CurTime(), "%02i:%02i:%02i"))
	end

	local cashLbl = vgui.Create("DLabel", frame)
	cashLbl:SetText("Cash: $" .. LocalPlayer():GetNWInt("TDM_Money", 0))
	cashLbl:DockMargin(10, 5, 10, 5)
	cashLbl:Dock(BOTTOM)
	cashLbl:SetTextColor(Color(61, 173, 61))
	cashLbl:SetFont("ZB_TDM_DESC")
	cashLbl:SetSize(0, ScrH() * 0.02)
	cashLbl.Think = function(self)
		self:SetText("Cash: $" .. LocalPlayer():GetNWInt("TDM_Money", 0))
	end
end

net.Receive("tdm_open_buymenu", function()
	OpenBuyMenu()
end)

TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil
