z = z or {} -- ахуенно zb.afk = zb.afk or {}
-- да все сакай хуй
if SERVER then
	util.AddNetworkString("zb_afk_state")
	local function f(p,a,m)
		if not IsValid(p) then return end
		p:SetNWBool("ZB_AFK",a and true or false)
		p:SetNWBool("ZB_AFK_Minimized",m and true or false)
	end
	net.Receive("zb_afk_state",function(_,p)
		if not IsValid(p) or p:IsBot() then return end
		local a=net.ReadBool()
		local m=net.ReadBool()
		if p:Team()==TEAM_SPECTATOR then a=false m=false end
		p.l=CurTime()
		f(p,a,m)
	end)
	hook.Add("PlayerInitialSpawn","afk",function(p) p.l=CurTime() f(p,false,false) end)
	hook.Add("PlayerSpawn","afk2",function(p) p.l=CurTime() f(p,false,false) end)
	hook.Add("PlayerDisconnected","afk3",function(p) p.l=nil end)
	timer.Create("afk4",2,0,function()
		local n=CurTime()
		for _,p in player.Iterator() do
			if not IsValid(p) or p:IsBot() then continue end
			if p:Team()==TEAM_SPECTATOR then f(p,false,false) continue end
			if n-(p.l or 0)<=10 then continue end
			f(p,true,true)
		end
	end)
else
	local a=CurTime()
	local l
	local m
	local g=0
	local w=false
	local function u() a=CurTime() end
	hook.Add("CreateMove","afk",function(c) if c:GetButtons()==0 and c:GetMouseX()==0 and c:GetMouseY()==0 then return end u() end)
	hook.Add("PlayerBindPress","afk1",u)
	hook.Add("OnContextMenuOpen","afk2",u)
	hook.Add("OnContextMenuClose","afk3",u)
	hook.Add("StartChat","afk4",u)
	hook.Add("FinishChat","afk5",u)
	timer.Create("afk6",1,0,function()
		local p=LocalPlayer()
		if not IsValid(p) or p:IsBot() then return end
		local v=p:Alive()
		if v and not w then g=CurTime()+20 u() end
		w=v
		local sp=p:Team()==TEAM_SPECTATOR
		local min=system and system.HasFocus and not system.HasFocus() or false
		local af=false
		if not sp then af=min or (CurTime()>=g and CurTime()-a>=12) end
		if l==af and m==min then return end
		l=af m=min
		net.Start("zb_afk_state")
		net.WriteBool(af)
		net.WriteBool(min)
		net.SendToServer()
	end)
end
