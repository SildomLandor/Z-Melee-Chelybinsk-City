local labels = {
	none = "Нет",
	all = "Все (игнор)",
	combine = "Combine",
	rebel = "Повстанцы",
}

local order = {"none", "all", "combine", "rebel"}

local function ownRagdoll(_, ent, ply)
	if not IsValid(ent) then return false end
	local owner = hg.RagdollOwner(ent)
	return IsValid(owner) and owner == ply
end

properties.Add("hg_npc_faction", {
	MenuLabel = "NPC фракция",
	Order = 50,
	MenuIcon = "icon16/group.png",
	Filter = ownRagdoll,
	Action = function() end,
	Faction = function(self, ent, id)
		self:MsgStart()
			net.WriteEntity(ent)
			net.WriteString(id)
		self:MsgEnd()
	end,
	Receive = function(self, _, ply)
		local ent = net.ReadEntity()
		local faction = net.ReadString()
		if not self:Filter(ent, ply) then return end

		local owner = hg.RagdollOwner(ent)
		if not IsValid(owner) or not hg.SetPlayerNPCFaction then return end

		hg.SetPlayerNPCFaction(owner, faction)
		ply:ChatPrint("NPC фракция: " .. (labels[faction] or faction))
	end,
	MenuOpen = function(self, option, ent)
		local owner = hg.RagdollOwner(ent)
		local current = IsValid(owner) and owner:GetNWString("hg_npc_faction", "") or ""
		local submenu = option:AddSubMenu()

		for _, id in ipairs(order) do
			local opt = submenu:AddOption(labels[id])
			opt:SetRadio(true)
			opt:SetChecked(current == id)
			opt:SetIsCheckable(true)
			opt.OnChecked = function(_, checked)
				if checked then self:Faction(ent, id) end
			end
		end
	end,
})
