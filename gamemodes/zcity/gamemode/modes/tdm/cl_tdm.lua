MODE.name = "tdm"

local MODE = MODE

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()
	hg.DynaMusic:Start( "swat4" )
	zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}

hook.Add( "StartCommand", "TDM_DisallowMoveOrShoting", function( ply, mv )
	--; BLYAT NY NAXUA PISAT VSE V ODNY LINIY BLYAAA
	if (zb.CROUND == "tdm" or zb.CROUND == "cstrike") and (zb.ROUND_START or 0) + 20 > CurTime() then 
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

function MODE:RenderScreenspaceEffects()
    local StartTime = zb.ROUND_START or CurTime()
	if StartTime + 7.5 < CurTime() then return end
    local fade = math.Clamp(StartTime + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end

function MODE:HUDPaint()
    local StartTime = zb.ROUND_START or CurTime()
	self:AddHudPaint()
	if StartTime + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(StartTime + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText( "Нажмите F3 чтобы открыть магазин", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime( math.max(StartTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i" )
		draw.SimpleText( time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

    if StartTime + 20 < CurTime() then return end
	 
	if not lply:Alive() then return end
	zb.RemoveFade()
    local fade = math.Clamp(StartTime + 8 - CurTime(),0,1)
	local team_ = lply:Team()
    draw.SimpleText("ZBattle | "..(self.PrintName or "Командный Бой"), "ZCity_Veteran_big", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local Rolename = teams[team_].name
    local ColorRole = teams[team_].color1
    ColorRole.a = 255 * fade
    draw.SimpleText("Вы - "..Rolename , "ZCity_Veteran", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local Objective = teams[team_].objective
    local ColorObj = teams[team_].color2
    ColorObj.a = 255 * fade
    draw.SimpleText( Objective, "ZCity_Veteran_hmcdobj", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function MODE:AddHudPaint()
end

net.Receive("tdm_roundend", function()
	zb.EndMenu.Open({ title = zb.EndMenu.TitleForRound() })
end)

function MODE:RoundStart()
	zb.EndMenu.Close()
end

surface.CreateFont("ZB_TDM_MENU", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    extended = true,
    weight = 400,
    antialias = true
})
surface.CreateFont("ZB_TDM_DESC", {
    font = "Bahnschrift",
    size = ScreenScale(7),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_CATEGORY", {
    font = "Bahnschrift",
    size = ScreenScale(6),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_DESCSMALL", {
    font = "Bahnschrift",
    size = ScreenScale(5),
    extended = true,
    weight = 400,
    antialias = true
})

local function PaintFrame(self,w,h)
	BlurBackground(self)

	surface.SetDrawColor( 255, 0, 0, 128)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local function PaintPanel(self,w,h)
	surface.SetDrawColor( 0, 0, 0,155)
    surface.DrawRect( 0, 0, w, h, 2.5 )
	surface.SetDrawColor( 255, 0, 0, 128)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local gradient_l = Material("vgui/gradient-l")

local function PaintPanel1(self,w,h)
	surface.SetDrawColor( 0, 0, 0,155)
    surface.DrawRect( 0, 0, w, h, 2.5 )
	surface.SetDrawColor( 255, 0, 0, 128)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, Color( 0, 0, 0, 140) )
    surface.SetDrawColor(155, 0, 0, 55)
    surface.SetMaterial(gradient_l)
    surface.DrawTexturedRect( 0, 0, w/1.5, h )
end

local function PaintPanel2(self,w,h)
	--surface.SetDrawColor( 15, 15, 15,25)
    --surface.DrawRect( 0, 0, w, h, 2.5 )
	--draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, Color( 0, 0, 0, 140) )
    surface.SetDrawColor(55, 155, 55, 25)
    surface.SetMaterial(gradient_l)
    surface.DrawTexturedRect( 0, 0, w*1.2, h )
end

local rtabFunc = function(self)

	local ExtraInset = 10

	if ( self.Image ) then
		ExtraInset = ExtraInset + self.Image:GetWide()
	end

	self:SetTextInset( ExtraInset, 2 )
	local w, h = self:GetContentSize()
	h = self:GetTabHeight()

	self:SetSize( w + 10, h + 7 )

	DLabel.ApplySchemeSettings( self )

end

local function OpenBuyMenu()
	if TDM_OpenedBuyMenu then
		TDM_OpenedBuyMenu:Remove()
		TDM_OpenedBuyMenu = nil
	end
	local StartTime = zb.ROUND_START or CurTime()
	if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then return end
	TDM_OpenedBuyMenu = vgui.Create("ZFrame")
	local Frame = TDM_OpenedBuyMenu
	Frame:SetSize(ScrW() * 0.35,ScrH() * 0.85)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetTitle("Buy menu")
	Frame.Paint = PaintFrame
	
	local Sheet = vgui.Create( "DPropertySheet", Frame )
	Sheet:Dock( FILL )
	Sheet:SetTextInset(50)
	Sheet.Paint = function() end
	Sheet.tabScroller:SetOverlap( 0 )
	Sheet.tabScroller:DockMargin( 8, 0, 8, 0 )
	Sheet:SetFadeTime(0.1)

	for k,category in SortedPairsByMemberValue(MODE.BuyItems, "Priority") do
		local CategoryPanel = vgui.Create( "DScrollPanel", Sheet )
		--CategoryPanel:Dock()
		CategoryPanel.Paint = function() end
		for n,Item in pairs(category) do
			if n == "Priority" then continue end
			local weapon = weapons.GetStored( Item.ItemClass )
			local ent = scripted_ents.GetStored( Item.ItemClass )

			local ItemPanel = vgui.Create("DPanel",CategoryPanel)
			ItemPanel:SetSize(0,ScrH()*0.1)
			ItemPanel:Dock(TOP)
			ItemPanel:DockMargin(0,8,0,0)
			ItemPanel.Paint = PaintPanel1
			--print(Item.ItemClass,weapon)
			if ( weapon ~= nil and ( (weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName()) or (weapon.IconOverride)) ) or ((ent and ent.t.IconOverride)) then
				local ItemButton = vgui.Create("DImage",ItemPanel)
				local bBox = ((ent and ent.t.IconOverride) or weapon~=nil and weapon.WepSelectIcon2box)
				ItemButton:SetSize(ScrH() * ( (bBox and 0.1) or 0.17), ScrH() * 0.1)
				ItemButton:Dock(LEFT)
				local boxed = ScrH()*0.07/2
				ItemButton:DockMargin(5 + (bBox and boxed or 0),5,5 + (bBox and boxed or 0),5)
				ItemButton:SetImage( ( weapon ~= nil and ( (weapon.WepSelectIcon2 and weapon.WepSelectIcon2:GetName() .. ".png") or weapon.IconOverride) ) or ((ent and ent.t.IconOverride) or "none") )
			end

			local ItemButton = vgui.Create("DPanel",ItemPanel)
			ItemButton:Dock(FILL)
			ItemButton:DockMargin(0,5,0,0)
			ItemButton.Paint = function() end

			local lbl = vgui.Create("DLabel", ItemButton)
			lbl:SetText(n)
			lbl:DockMargin(10,0,5,0)
			lbl:Dock(TOP)
			lbl:SetFont("ZB_TDM_MENU")
			lbl:SetSize(ScrW()*0.5,ScrH()*0.04)

			local lbl = vgui.Create("DLabel", ItemButton)
			lbl:SetText("Price: $"..Item.Price)
			lbl:DockMargin(10,0,5,0)
			lbl:Dock(TOP)
			lbl:SetTextColor(Color(155,200,155))
			lbl:SetFont("ZB_TDM_DESC")
			lbl:SetSize(ScrW()*0.5,ScrH()*0.02)

			local BuyBtn = vgui.Create("DButton", ItemButton)
			BuyBtn:DockMargin(10,5,10,10)
			BuyBtn:Dock(LEFT)
			BuyBtn:SetText("Buy")
			BuyBtn:SetTextColor(Color(200,200,200))
			BuyBtn:SetFont("ZB_TDM_DESC")
			BuyBtn:SetHeight(ScrH()*0.025)
			BuyBtn.Paint = PaintPanel
			BuyBtn.Item = {k,n}

			function BuyBtn:DoClick()
				net.Start("tdm_buyitem")
					net.WriteTable(self.Item)
				net.SendToServer()
			end
			
			if weapon then
				local ammo = weapon.Primary.Ammo != "none" and weapon.Primary.Ammo or weapon.Ammo or (weapons.GetStored( weapon.Base ) and weapons.GetStored( weapon.Base ).Primary.Ammo)
				
				if hg.ammotypeshuy[ammo] then
					local amm = vgui.Create( "DButton", ItemButton)
					amm:DockMargin(10,5,10,10)
					amm:Dock(LEFT)
					amm:SetText(ammo)
					amm:SetTextColor(Color(200,200,200))
					amm:SetFont("ZB_TDM_DESCSMALL")
					
					surface.SetFont("ZB_TDM_DESCSMALL")
					local w, h = surface.GetTextSize(ammo)

					amm:SetHeight(ScrH()*0.025)
					amm:SetWidth(w + 7)
					local ammo2 = "ent_ammo_"..hg.ammotypeshuy[ammo].name
					local name
					for name2, ammo in pairs(MODE.BuyItems["Ammo"]) do
						if not istable(ammo) then continue end
						if ammo.ItemClass == ammo2 then
							name = name2
						end
					end
					
					amm.huy = {"Ammo", name}

					function amm:DoClick()
						net.Start("tdm_buyitem")
							net.WriteTable(amm.huy)
						net.SendToServer()
					end

					amm.Paint = PaintPanel
				end
			end

			if Item.Attachments and #Item.Attachments > 0 then
				local ItemAtt = vgui.Create("DGrid",ItemPanel)
				local ItemIcon = math.ceil(ScrH()*0.06)
				ItemAtt:Dock(RIGHT)
				ItemAtt:DockMargin(0,5,0,0)
				ItemAtt:SetCols( 4 )
				ItemAtt:SetColWide(ItemIcon)
				ItemAtt:SetRowHeight(ItemIcon)
				ItemAtt.Paint = function() end
				for id,AttachN in pairs(Item.Attachments) do
					local ico = hg.attachmentsIcons[AttachN]
					local Attach = vgui.Create( "DImageButton" )
					Attach:SetImage(ico)
					Attach:SetSize(ItemIcon-5,ItemIcon-5)

					Attach.Attachment = {k,n,AttachN}

					function Attach:DoClick()
						net.Start("tdm_buyitem")
							net.WriteTable(self.Attachment)
						net.SendToServer()
					end

					Attach.Paint = PaintPanel2
					ItemAtt:AddItem(Attach)
				end
			end
		end
		local tab = Sheet:AddSheet(k,CategoryPanel)
		local rTab = tab["Tab"]
		rTab.Paint = PaintPanel
		rTab:SetFont("ZB_TDM_CATEGORY")
		rTab.ApplySchemeSettings = rtabFunc
		--rTab:SetTextInset(50)
	end

	local StartTime = zb.ROUND_START or CurTime()
	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	lbl:DockMargin(10,0,10,10)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(255,255,255))
	lbl:SetFont("ZB_TDM_DESC")
	lbl:SetSize(0,ScrH()*0.015)

	function lbl:Think()
		if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then TDM_OpenedBuyMenu:Remove() end
		self:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	end

	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Cash: $"..LocalPlayer():GetNWInt("TDM_Money",0))
	lbl:DockMargin(10,5,10,5)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(61,173,61))
	lbl:SetFont("ZB_TDM_DESC")
	lbl:SetSize(0,ScrH()*0.02)

	function lbl:Think()
		self:SetText("Cash: $"..LocalPlayer():GetNWInt("TDM_Money",0))
	end

end

net.Receive("tdm_open_buymenu", function()
	OpenBuyMenu()
end)

function zb.OpenBuyMenu()
	OpenBuyMenu()
end

hook.Add("zbOpenBuyMenu", "tdm", function()
	OpenBuyMenu()
end)

TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil