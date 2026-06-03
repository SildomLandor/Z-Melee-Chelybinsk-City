hg.Appearance = hg.Appearance or {}

local IsValid = IsValid
local LocalPlayer = LocalPlayer
local CreateClientConVar = CreateClientConVar
local ConVarExists = ConVarExists
local GetConVar = GetConVar
local Color = Color
local IsColor = IsColor
local Next = next
local CurTime = CurTime
local Vector = Vector
local Angle = Angle
local LocalToWorld = LocalToWorld
local string_sub = string.sub
local string_Split = string.Split
local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs
local type = type
local istable = istable
local isfunction = isfunction
local file = file
local util = util
local net = net
local hook = hook
local timer = timer
local render = render
local hg = hg
local vector_origin = vector_origin
local angle_zero = angle_zero
local huy_addvec = Vector(0.4, 0, 0.4)
local flpos, flang = Vector(4, -1, 0), Angle(0, 0, 0)
local offsetVec, offsetAng = Vector(1, 0, 0), Angle(100, 90, 0)
local mat2 = Material("sprites/light_glow02_add_noz")
local mat3 = Material("effects/flashlight/soft")
local color_white = color_white

hg.Appearance.SelectedAppearance = ConVarExists("hg_appearance_selected") and GetConVar("hg_appearance_selected") or CreateClientConVar("hg_appearance_selected","main",true,false,"name of selected appearance json file")
hg.Appearance.ForcedRandom = ConVarExists("hg_appearance_force_random") and GetConVar("hg_appearance_force_random") or CreateClientConVar("hg_appearance_force_random","0",true,false,"forced appearance random",0,1)
hg.Appearance.MaxRenderDist = ConVarExists("hg_appearance_max_render_dist") and GetConVar("hg_appearance_max_render_dist") or CreateClientConVar("hg_appearance_max_render_dist", "750", true, false, "Maximum distance to render accessories", 0, 5000)

local dir = "zcity/appearances/"

function hg.Appearance.CreateAppearanceFile(strFile_name, tblAppearance)
	file.CreateDir(dir)
	file.Write(dir .. strFile_name .. ".json", util.TableToJSON(tblAppearance, true) )
end

function hg.Appearance.LoadAppearanceFile(strFile_name)
	if not file.Exists(dir .. strFile_name .. ".json", "DATA") then return false, "no file [data/zcity/appearances/" .. strFile_name .. ".json]" end
	local tblAppearance = util.JSONToTable(file.Read(dir .. strFile_name .. ".json"))

	if not hg.Appearance.AppearanceValidater(tblAppearance) then return false, "file is damaged [data/zcity/appearances/" .. strFile_name .. ".json]"  end

	if tblAppearance.AColor and not IsColor(tblAppearance.AColor) then
		tblAppearance.AColor = Color(tblAppearance.AColor.r or 180, tblAppearance.AColor.g or 0, tblAppearance.AColor.b or 0, tblAppearance.AColor.a or 255)
	end

	tblAppearance.AAttachments = tblAppearance.AAttachments or {}
	for i = 1, 3 do
		if not tblAppearance.AAttachments[i] or tblAppearance.AAttachments[i] == "" then
			tblAppearance.AAttachments[i] = "none"
		end
	end

	hg.Appearance.FixAppearanceNameSex(tblAppearance)

	return tblAppearance
end

function hg.Appearance.GetAppearanceList()
	return file.Find( dir .. "*.json" )
end

-- Send from client...
net.Receive("Get_Appearance", function()
    local forced_random = hg.Appearance.ForcedRandom:GetBool()
    net.Start("Get_Appearance")
        local tbl, reason

        if not forced_random then
            tbl, reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
        end

        if tbl and tbl.AColor and not IsColor(tbl.AColor) then
            tbl.AColor = Color(tbl.AColor.r, tbl.AColor.g, tbl.AColor.b, tbl.AColor.a or 255)
        end

        net.WriteTable(tbl or {})
        net.WriteBool(not tbl)
    net.SendToServer()

    if not tbl and not forced_random then
        local ply = LocalPlayer()
        if IsValid(ply) then ply:ChatPrint("[Appearance] file load failed - " .. reason) end
    end
end)

local function OnlyGetAppearance()
    local forced_random = hg.Appearance.ForcedRandom:GetBool()
    net.Start("OnlyGet_Appearance")
        local tbl, reason

        if not forced_random then
            tbl, reason = hg.Appearance.LoadAppearanceFile(hg.Appearance.SelectedAppearance:GetString())
        end
        if tbl and tbl.AColor and not IsColor(tbl.AColor) then
            tbl.AColor = Color(tbl.AColor.r, tbl.AColor.g, tbl.AColor.b, tbl.AColor.a or 255)
        end

        net.WriteTable(tbl or {})
    net.SendToServer()

    if not tbl and not forced_random then
        local ply = LocalPlayer()
        if IsValid(ply) then ply:ChatPrint("[Appearance] file load failed - " .. reason) end
    end
end

net.Receive("OnlyGet_Appearance", OnlyGetAppearance)

hook.Add("InitPostEntity", "HG_Appearance_SendCachedOnJoin", function()
    timer.Simple(0, function()
        if not IsValid(LocalPlayer()) then return end
        OnlyGetAppearance()
    end)
end)

-- Render things

local whitelist = {
    weapon_physgun = true,
    gmod_tool = true,
    gmod_camera = true,
    weapon_crowbar = true,
    weapon_pistol = true,
    weapon_crossbow = true
}

local hg_firstperson_death = ConVarExists("hg_firstperson_death") and GetConVar("hg_firstperson_death") or CreateClientConVar("hg_firstperson_death", "0", "first person death", true, false, 0, 1)

function RenderAccessories(ply, accessories, setup)
	if accessories == "none" or not accessories or not IsValid(ply) then return end
	
	local viewer = LocalPlayer()
	if ply ~= viewer then
		local entPos = (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply):GetPos()
		local dist = viewer:GetPos():Distance(entPos)
		local maxDist = hg.Appearance.MaxRenderDist:GetFloat()
		if dist > maxDist then
			local modelAccess = ply.modelAccess
			if modelAccess and Next(modelAccess) ~= nil then
				for k, v in pairs(modelAccess) do
					if IsValid(v) then v:Remove() end
				end
				ply.modelAccess = {}
			end
			return
		end
	end

	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	ent = IsValid(ply.OldRagdoll) and ply.OldRagdoll:IsRagdoll() and ply.OldRagdoll or ent

	local spectEnt = viewer:GetNWEntity("spect", viewer)
	local activeViewer = viewer:Alive() and viewer or spectEnt
	
	local isRagdollOwner = ply:IsRagdoll() and hg.RagdollOwner(ply)
	local targetCheck = isRagdollOwner and isRagdollOwner or ply
	
	local islply = (targetCheck == activeViewer) and (GetViewEntity() == activeViewer)
	
	local fountains = GetNetVar("fountains") or {}
	if ent == follow and hg_firstperson_death:GetBool() and not fountains[ent] then 
		islply = true 
	end

	local wep = ply:IsPlayer() and ply:GetActiveWeapon()
	if islply and IsValid(wep) and whitelist[wep:GetClass()] then
		local modelAccess = ent.modelAccess
		if modelAccess then
			for i = 1, #modelAccess do
				local v = modelAccess[i]
				if IsValid(v) then v:Remove() end
			end
			ent.modelAccess = {}
		end
		return
	end

	if not ent.shouldTransmit or ent.NotSeen then
		local modelAccess = ent.modelAccess
		if modelAccess then
			for i = 1, #modelAccess do
				local v = modelAccess[i]
				if IsValid(v) then v:Remove() end
			end
			ent.modelAccess = {}
		end
		return
	end

	if istable(accessories) then
		local count = #accessories
		for k = 1, count do
			local accessoriess = accessories[k]
			local accessData = hg.Accessories[accessoriess]
			if not accessData or accessData.needcoolRender then continue end

			DrawAccesories(ply, ent, accessoriess, accessData, islply, nil, setup)
		end
	else
		local accessData = hg.Accessories[accessories]
		if not accessData or accessData.needcoolRender then return end

		DrawAccesories(ply, ent, accessories, accessData, islply, nil, setup)
	end
end

function DrawAccesories(ply, ent, accessories, accessData, islply, force, setup)
	if not accessories or not accessData then return end

	ply.modelAccess = ply.modelAccess or {}
	local fem = ThatPlyIsFemale(ent)
	local model = ply.modelAccess[accessories]

	if not IsValid(model) then
		if not accessData["model"] then return end
		model = ClientsideModel(fem and accessData["femmodel"] or accessData["model"], RENDERGROUP_BOTH)
		if not IsValid(model) then return end
		
		ply.modelAccess[accessories] = model
		model:SetNoDraw(true)
		
		local posKey = fem and "fempos" or "malepos"
		local posData = accessData[posKey]
		if posData then model:SetModelScale(posData[3] or 1) end
		
		model:SetSkin(isfunction(accessData["skin"]) and accessData["skin"](ent) or accessData["skin"] or 0)
		model:SetBodyGroups(accessData["bodygroups"] or "")
		model:SetParent(ent, ent:LookupBone(accessData["bone"]))
		
		if accessData.bonemerge then
			model:AddEffects(EF_BONEMERGE)
		end
		
		if accessData["bSetColor"] then
			if ply.GetPlayerColor then 
				model:SetColor(ply:GetPlayerColor():ToColor())
			else
				model:SetColor(ply:GetNWVector("PlayerColor", Vector(1, 1, 1)):ToColor())
			end
		end

		if accessData["SubMat"] then
			model:SetSubMaterial(0, accessData["SubMat"])
		end

		local removeKey1 = "RemoveAccessories" .. accessories
		ply:CallOnRemove(removeKey1, function() 
			if IsValid(model) then model:Remove() end
		end)
		
		local removeKey2 = "RemoveAccessories2" .. accessories
		ent:CallOnRemove(removeKey2, function() 
			if IsValid(model) then model:Remove() end
		end)
	end

	local entModel = ent:GetModel()
	if entModel and ent.__cachedMdlName ~= entModel then
		ent.__cachedMdlName = entModel
		local tokens = string_Split(string_sub(entModel, 1, -5), "/")
		ent.__cachedMdl = tokens[#tokens]
	end
	
	local mdl = ent.__cachedMdl
	if mdl then
		local flexID = model:GetFlexIDByName(mdl)
		if flexID then model:SetFlexWeight(flexID, 1) end
	end

	model:SetSkin(isfunction(accessData["skin"]) and accessData["skin"](ent) or accessData["skin"] or 0)

	if not IsValid(model) then 
		ply.modelAccess[accessories] = nil 
		return 
	end

	if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then
		return
	end

	if not force and ((ent.NotSeen or not ent.shouldTransmit) or (ply:IsPlayer() and not ply:Alive())) then
		return
	end

	if ply.organism then
		local ampBone = hg.amputatedlimbs2[accessData["bone"]]
		if ampBone and ply.organism[ampBone .. "amputated"] then return end
	end

	if setup ~= false then
		local bone = ent:LookupBone(accessData["bone"])
		if not bone then return end
		if ent:GetManipulateBoneScale(bone):LengthSqr() < 0.1 then return end
		local matrix = ent:GetBoneMatrix(bone)
		if not matrix then return end

		local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
		local isSpecificMale = (entModel == "models/player/group01/male_06.mdl")
		local placement = accessData.placement
		local isHeadOrFace = (placement == "head" or placement == "face")
		
		local addvec = (isSpecificMale and isHeadOrFace) and huy_addvec or vector_origin

		local posKey = fem and "fempos" or "malepos"
		local posData = accessData[posKey]
		
		local pos, ang = LocalToWorld(posData[1], posData[2], bonePos, boneAng)
		pos = LocalToWorld(addvec, angle_zero, pos, ang)
		
		model:SetRenderOrigin(pos)
		model:SetRenderAngles(ang)
	end

	if model:GetParent() ~= ent then model:SetParent(ent, ent:LookupBone(accessData["bone"])) end
	
	if not (islply and accessData.norender) and (not setup or accessData.bonemerge) then
		local bSetColor = accessData["bSetColor"]
		if bSetColor then
			local colorDraw = accessData["vecColorOveride"] or (ply.GetPlayerColor and ply:GetPlayerColor() or ply:GetNWVector("PlayerColor", Vector(1, 1, 1)))
			render.SetColorModulation(colorDraw[1], colorDraw[2], colorDraw[3])
		end
		
		model:DrawModel()
		
		if bSetColor then
			render.SetColorModulation(1, 1, 1)
		end
	end
end

function DrawAppearance(ent, ply, setup)
    local Access = ent:GetNetVar("Accessories") or ent.PredictedAccessories
	
	if IsValid(ent) and Access then
		RenderAccessories(ply, Access, setup)
	end
	
	if setup then return end
	if not ply:IsPlayer() then return end
	
	local inv = ply:GetNetVar("Inventory", {})
	local wepInv = inv["Weapons"]
	if not wepInv or not wepInv["hg_flashlight"] then
		local pf = ply.flashlight
		if pf then
			pf:Remove()
			ply.flashlight = nil
		end
		local pm = ply.flmodel
		if pm then
			pm:Remove()
			ply.flmodel = nil
		end
		return
	end

	local wep = ply:GetActiveWeapon()
	local flashlightwep = false

	if IsValid(wep) then
	    local attachments = wep.attachments
	    local laser = attachments and attachments.underbarrel
	    local attachmentData
	    
	    if laser and Next(laser) ~= nil then
	        attachmentData = hg.attachments.underbarrel[laser[1]]
	    elseif wep.laser then
	        attachmentData = wep.laserData
	    end

	    if attachmentData then 
	        flashlightwep = attachmentData.supportFlashlight 
	    end
	end

	local flModel = ply.flmodel
	if IsValid(flModel) then
		flModel:SetNoDraw(not (ply:GetNetVar("flashlight") and (not wep.IsPistolHoldType or wep:IsPistolHoldType())) or wep.reload or flashlightwep)
	end

	if ply:GetNetVar("flashlight") and not flashlightwep and (not wep.IsPistolHoldType or wep:IsPistolHoldType() or ply.PlayerClassName == "Gordon") and not wep.reload then
		local hand = ent:LookupBone("ValveBiped.Bip01_L_Hand")
		if not hand then return end

		local handmat = ent:GetBoneMatrix(hand)
		if not handmat then return end

		local pos, ang = handmat:GetTranslation(), handmat:GetAngles()
		pos, ang = LocalToWorld(offsetVec, offsetAng, pos, ang)

		if not IsValid(flModel) then
			flModel = ClientsideModel("models/runaway911/props/item/flashlight.mdl")
			ply.flmodel = flModel
			if IsValid(flModel) then flModel:SetModelScale(0.75) end
		end

		if ent ~= ply then pos = handmat:GetTranslation() end

		local pos2, _ = LocalToWorld(flpos, flang, pos, handmat:GetAngles())

		if IsValid(flModel) and (ply ~= LocalPlayer() or ply ~= GetViewEntity()) then
			local veclh, lang = hg.FlashlightTransform(ply)
		end

		if IsValid(flModel) then flModel:DrawModel() end

		local flash = ply.flashlight
		if not IsValid(flash) then
			flash = ProjectedTexture()
			ply.flashlight = flash
		end
		
		local curT = CurTime()
		if flash and flash:IsValid() and (ply.FlashlightUpdateTime or 0) < curT then
			ply.FlashlightUpdateTime = curT + 0.01
			flash:SetTexture(mat3:GetTexture("$basetexture"))
			flash:SetFarZ(1500)
			flash:SetHorizontalFOV(60)
			flash:SetVerticalFOV(60)
			flash:SetConstantAttenuation(0.1)
			flash:SetLinearAttenuation(50)
			if IsValid(flModel) then
				flash:SetPos(flModel:GetPos() + flModel:GetAngles():Forward() * (ply:GetVelocity():Length() * 0.1 + 15))
				flash:SetAngles(flModel:GetAngles())
			end
			flash:Update()
		end

		if IsValid(flModel) then
			local view = render.GetViewSetup(true)
			local deg = flModel:GetAngles():Forward():Dot(view.angles:Forward())
			deg = math.ease.InBack(-deg + 0.05) * 2
			deg = -deg
			
			local chekvisible = util.TraceLine({
				start = flModel:GetPos() + flModel:GetAngles():Forward() * 6,
				endpos = view.origin,
				filter = {ply, ent, flModel, LocalPlayer()},
				mask = MASK_VISIBLE
			})

			if deg < 0 and not chekvisible.Hit then
				render.SetMaterial(mat2)
				render.DrawSprite(flModel:GetPos() + flModel:GetAngles():Forward() * 5 + flModel:GetAngles():Right() * -0.5, 50 * math.min(deg, 0), 50 * math.min(deg, 0), color_white)
			end
		end
	else
		local flash = ply.flashlight
		if flash and IsValid(flash) then
			flash:Remove()
			ply.flashlight = nil
		end
	end
end

hook.Add("RenderScreenspaceEffects", "AppearanceShitty", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or (not ply:Alive()) or LocalPlayer():GetViewEntity() ~= ply then return end
	
	local acsses = ply:GetNetVar("Accessories", "none")
	if acsses == "none" then return end

	if istable(acsses) then
		local count = #acsses
		for k = 1, count do
			local accessoriess = acsses[k]
			local accessData = hg.Accessories[accessories]
			if not accessData then continue end
			if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then continue end
			if accessData.ScreenSpaceEffects then
				accessData.ScreenSpaceEffects()
			end
		end
	elseif acsses then
		local accessData = hg.Accessories[acsses]
		if not accessData then return end
		if ply.armors and accessData["placement"] and ply.armors[accessData["placement"]] then return end
		if accessData.ScreenSpaceEffects then
			accessData.ScreenSpaceEffects()
		end
	end
end)

function CoolRenderAccessories(ply, accessories)
	if accessories == "none" or not accessories or not IsValid(ply) then return end

	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	local viewer = LocalPlayer()
	local spectEnt = viewer:GetNWEntity("spect", viewer)
	local activeViewer = viewer:Alive() and viewer or spectEnt
	
	local isRagdollOwner = ply:IsRagdoll() and hg.RagdollOwner(ply)
	local targetCheck = isRagdollOwner and isRagdollOwner or ply
	
	local islply = (targetCheck == activeViewer) and (GetViewEntity() == activeViewer)

	local wep = ply:IsPlayer() and ply:GetActiveWeapon()
	if islply and IsValid(wep) and whitelist[wep:GetClass()] then
		local modelAccess = ent.modelAccess
		if modelAccess then
			for i = 1, #modelAccess do
				local v = modelAccess[i]
				if IsValid(v) then v:Remove() end
			end
			ent.modelAccess = {}
		end
		return
	end

	if not ent.shouldTransmit or ent.NotSeen then
		local modelAccess = ent.modelAccess
		if modelAccess then
			for i = 1, #modelAccess do
				local v = modelAccess[i]
				if IsValid(v) then v:Remove() end
			end
			ent.modelAccess = {}
		end
		return
	end

	if istable(accessories) then
		local count = #accessories
		for k = 1, count do
			local accessoriess = accessories[k]
			local accessData = hg.Accessories[accessoriess]
			if not accessData or not accessData.needcoolRender then continue end

			DrawAccesories(ply, ent, accessoriess, accessData, islply)
		end
	else
		local accessData = hg.Accessories[accessories]
		if not accessData or not accessData.needcoolRender then return end

		DrawAccesories(ply, ent, accessories, accessData, islply)
	end
end

function RenderAccessoriesCool(ent, ply)
	if IsValid(ent) and ent:GetNetVar("Accessories") then
		CoolRenderAccessories(ent, ent:GetNetVar("Accessories", "none"))
	end
end