local IsValid = IsValid
local LocalPlayer = LocalPlayer
local Entity = Entity
local type = type
local isnumber = isnumber
local isbool = isbool
local istable = istable
local tostring = tostring
local pairs = pairs
local table_Copy = table.Copy
local table_Merge = table.Merge
local string_sub = string.sub
local string_format = string.format
local math_Round = math.Round
local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_Clamp = math.Clamp
local math_sin = math.sin
local math_cos = math.cos
local Lerp = Lerp
local LerpVector = LerpVector
local hook_Add = hook.Add
local hook_Run = hook.Run
local net_Receive = net.Receive
local CurTime = CurTime
local FrameTime = FrameTime
local ScrW = ScrW
local ScrH = ScrH
local ScreenScale = ScreenScale
local ScreenScaleH = ScreenScaleH
local Color = Color
local Vector = Vector
local Angle = Angle
local Matrix = Matrix
local CreateClientConVar = CreateClientConVar
local GetConVar = GetConVar
local ClientsideModel = ClientsideModel
local Material = Material
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local draw_DrawText = draw.DrawText
local render_PushFilterMag = render.PushFilterMag
local render_PushFilterMin = render.PushFilterMin
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin
local render_SetStencilWriteMask = render.SetStencilWriteMask
local render_SetStencilTestMask = render.SetStencilTestMask
local render_SetStencilReferenceValue = render.SetStencilReferenceValue
local render_SetStencilCompareFunction = render.SetStencilCompareFunction
local render_SetStencilPassOperation = render.SetStencilPassOperation
local render_SetStencilFailOperation = render.SetStencilFailOperation
local render_SetStencilZFailOperation = render.SetStencilZFailOperation
local render_ClearStencil = render.ClearStencil
local render_SetStencilEnable = render.SetStencilEnable
local render_SetMaterial = render.SetMaterial
local render_DrawSphere = render.DrawSphere
local render_ClearBuffersObeyStencil = render.ClearBuffersObeyStencil
local render_DrawWireframeBox = render.DrawWireframeBox
local render_SetColorMaterial = render.SetColorMaterial
local render_DrawBox = render.DrawBox
local cam_Start3D = cam.Start3D
local cam_End3D = cam.End3D
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix

hg = hg or {}
hg.organism_ents = hg.organism_ents or {}
hg.hits = hg.hits or {}

local function syncRagOrganism(ply)
	if not IsValid(ply) then return end
	local org = ply.organism
	local newOrg = ply.new_organism
	local rags = {
		ply:GetNWEntity("FakeRagdoll"),
		ply:GetNWEntity("RagdollDeath"),
		ply.FakeRagdoll,
	}
	for i = 1, 3 do
		local rag = rags[i]
		if IsValid(rag) then
			rag.organism = org
			rag.new_organism = newOrg
		end
	end
end
hg.syncRagOrganism = syncRagOrganism

net_Receive("organism_send", function()
	local oid, isBare = hg.orgNetReadHeader()
	local ply = Entity(oid)
	local keys = isBare and hg.orgBareKeys or hg.orgFullKeys
	local base = IsValid(ply) and (ply.new_organism or ply.organism) or nil
	local org, force, spectatov_ne_trogaem, moreinfopls, add = hg.orgReadPacket(base, keys)
	
	if not org then return end
	if not IsValid(org.owner) and IsValid(ply) then org.owner = ply end
	ply = org.owner

	if not IsValid(ply) then return end

	if ply:IsNPC() then
		hg.organism_ents[ply] = true
	end

	if add and org.owner.organism and org.owner.new_organism then
		hook_Run("HG_OrganismChanged", org.owner.organism, org)
		table_Merge(org.owner.organism, org, true)
		table_Merge(org.owner.new_organism, org, true)
		hg.orgEnsureDefaults(org.owner.organism)
		hg.orgEnsureDefaults(org.owner.new_organism)
		syncRagOrganism(org.owner)
		return 
	end

	local lply = LocalPlayer()
	if ply.is_lookedat and not moreinfopls then return end
	if spectatov_ne_trogaem and (ply == lply:GetNWEntity("spect", nil)) and not lply:Alive() then return end

	ply.new_organism = org

	if ply == lply then
		if not ply.organism or force then
			ply.organism = table_Copy(org)
		else
			table_Merge(ply.organism, org, true)
			hg.orgEnsureDefaults(ply.organism)
		end
	else
		local old_org = ply.organism and table_Copy(ply.organism) or nil
		if not old_org or force then
			ply.organism = org
		else
			ply.organism = old_org
		end
	end

	if ply:IsPlayer() and ply:Alive() then
		org.health = ply:Health()
	end

	if ply:IsRagdoll() then
		ply.organism = org
		ply.new_organism = org
		if hg.addbonecallback then hg.addbonecallback(ply) end
	else
		local rag = ply:GetNWEntity("FakeRagdoll")
		if IsValid(rag) then
			rag.organism = ply.organism
			rag.new_organism = org
			if hg.addbonecallback then hg.addbonecallback(rag) end
		end
	end

	syncRagOrganism(ply)
end)

hook_Add("Player_Death", "removeorg", function(ply)
	ply.organism = nil
	ply.new_organism = nil
	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll.organism = nil
		ply.FakeRagdoll.new_organism = nil
	end
end)

local white = Color(255, 255, 255)
local black = Color(0, 0, 0, 200)
local red = Color(255, 0, 0)
local green = Color(0, 255, 0)
local littleblack = Color(75, 75, 75, 255)
local trahalgmod = Color(0, 0, 0, 75)

local list = {
	"owner", "superfighter", "berserkActive2", "temperature", "tempchanging", "heatbuff", "blindness",
	"fear", "assimilated", "berserk", "noradrenaline", "fearadd", {"blood", 5000}, {"bleed", 100, true},
	"bloodtype", "hemotransfusionshock", {"internalBleed", 10, true}, "internalBleedHeal", {"arteria", 1, true},
	{"rarmartery", 1, true}, {"larmartery", 1, true}, {"rlegartery", 1, true}, {"llegartery", 1, true},
	{"spineartery", 1, true}, {"llegdislocation", true, true}, {"rlegdislocation", true, true},
	{"larmdislocation", true, true}, {"rarmdislocation", true, true}, {"jawdislocation", true, true},
	{"llegamputated", true, true}, {"rlegamputated", true, true}, {"larmamputated", true, true},
	{"rarmamputated", true, true}, 0, "likely_phrase", {"alive", true}, {"otrub", true, true},
	{"health", 100, false}, {"incapacitated", true, true}, {"critical", true, true}, false,
	{"pain", 90, true}, {"painadd", 90, true}, {"avgpain", 90, true}, {"immobilization", true},
	{"painkiller", 3, true}, {"analgesia", 0, true}, {"naloxone", 0, true}, {"shock", 10, true},
	{"hurt", 1, true}, {"tranquilizer", 1, true}, "wantToVomit", "satiety", 0, {"adrenaline", 5, true},
	{"adrenalineStorage", 5, false}, {"adrenalineAdd", 5, true}, 0, {"stamina", {"stamina", "range"}},
	{{"stamina.max", "stamina", "max"}, {"stamina", "range"}}, {{"stamina.regen", "stamina", "regen"}, 1},
	{{"stamina.sub", "stamina", "sub"}, 1, true}, 0, {"brain", 1, true}, {"eyeL", 1, true}, {"eyeR", 1, true},
	{"consciousness", 1, false}, {"coma", true, true}, {"coma_depth", 1, true}, {"coma_gcs", 15, false},
	{"skull", 1, true}, {"disorientation", 1, true}, {"jaw", 1, true}, false, {"spine1", 1, true},
	{"spine2", 1, true}, {"spine3", 1, true}, {"chest", 1, true}, {"pelvis", 1, true}, 0, {"heart", 1, true},
	{"heartstop", true, true}, {"pulse", 70}, {"heartbeat", 70}, false, {"spo2", 100, false},
	{"vfib", true, true}, {"vfib_severity", 1, true}, {"stomach", 1, true}, {"liver", 1, true},
	{"intestines", 1, true}, "thiamine", "vomitInThroat", 0, {"lungsL", 1, true}, {"lungsR", 1, true},
	{{"lungsL.penetrated", "lungsL", 2}, 1, true}, {{"lungsR.penetrated", "lungsR", 2}, 1, true},
	{"trachea", 1, true}, {"pneumothorax", 1, true}, {"needle", 1, true}, 0, {"o2", {"o2", "range"}},
	"CO", {"lungsfunction", true, false}, "COregen", "LodgedEntities", "holdingbreath",
	{{"o2.regen", "o2", "regen"}, 2}, {{"o2.curregen", "o2", "curregen"}, 0.4}, 0, {"lleg", 1, true},
	{"rleg", 1, true}, {"larm", 1, true}, {"rarm", 1, true}
}
local list_len = #list

local function LerpColor(lerp, source, set)
	return Lerp(lerp, source.r, set.r), Lerp(lerp, source.g, set.g), Lerp(lerp, source.b, set.b)
end

local function set(s)
	return s.r, s.g, s.b
end

local function formatStatValue(value)
	if isnumber(value) then return string_sub(string_format("%f", value), 1, -5) end
	if isbool(value) then return value and "true" or "false" end
	if istable(value) then
		local n = 0
		for _ in pairs(value) do n = n + 1 end
		return n > 0 and ("table(" .. n .. ")") or "table(0)"
	end
	return tostring(value)
end

local function getTextTable(org, textList)
	local count = 0
	for i = 1, list_len do
		local v = list[i]
		if v == 0 or v == false then goto skip end
		local text1, text2, value, r, g, b = "", "", nil, nil, nil, nil
		
		if type(v) == "table" then
			if type(v[1]) == "table" then
				if org[v[1][2]] == nil then goto skip end
				text1 = v[1][1]
				value = org[v[1][2]][v[1][3]]
			else
				if org[v[1]] == nil then goto skip end
				text1 = v[1]
				value = org[text1]
				if type(value) == "table" then value = value[1] end
			end

			if type(v[2]) == "boolean" then
				if value then
					r, g, b = set(v[3] and red or green)
				else
					r, g, b = set(v[3] and green or red)
				end
			elseif value then
				local max = v[2]
				if type(v[2]) == "string" then max = org[v[2]] end
				if type(v[2]) == "table" then max = org[v[2][1]][v[2][2]] end
				if not max then goto skip end
				local k = (value ~= 0 and max ~= 0) and (value / max) or 0
				if v[3] then
					r, g, b = LerpColor(1 - k, red, green)
				else
					r, g, b = LerpColor(k, red, green)
				end
			end
			text2 = isnumber(value) and string_sub(string_format("%f", value), 1, -5) or value
		else
			if not org[v] then goto skip end
			text1 = tostring(v)
			text2 = formatStatValue(org[v])
		end
		
		count = count + 1
		local entry = textList[count]
		if not entry then
			entry = {}
			textList[count] = entry
		end
		entry[1], entry[2], entry[3], entry[4], entry[5] = text1, text2, r, g, b
		::skip::
	end
	for i = count + 1, #textList do textList[i] = nil end
end

local function LerpVariables(lerp, org_source, org_target)
	if not org_source or not org_target then return end
	for i = 1, list_len do
		local v = list[i]
		if v == 0 or v == false then goto skip2 end
		
		if type(v) == "table" then
			if type(v[1]) == "table" then
				local k2, k3 = v[1][2], v[1][3]
				if not org_source[k2] then goto skip2 end
				org_source[k2][k3] = org_target[k2] and org_target[k2][k3] and Lerp(lerp, org_source[k2][k3] or org_target[k2][k3], org_target[k2][k3]) or nil
			else
				local k1 = v[1]
				if not org_source[k1] then org_source[k1] = org_target[k1] goto skip2 end
				
				if type(org_source[k1]) == "table" then
					org_source[k1][1] = org_target[k1] and org_target[k1][1] and Lerp(lerp, org_source[k1][1] or org_target[k1][1], org_target[k1][1]) or nil
				else
					org_source[k1] = isnumber(org_source[k1]) and isnumber(org_target[k1]) and Lerp(lerp, org_source[k1], org_target[k1]) or org_target[k1] or nil
				end
			end
		elseif type(org_target[v]) == "number" and type(org_source[v]) == "number" then
			org_source[v] = Lerp(lerp, org_source[v], org_target[v])
		else
			org_source[v] = org_target[v]
		end
		::skip2::
	end
end
hg.LerpVariables = LerpVariables

local weight = 200
local developer = GetConVar("developer")
local hg_stats = GetConVar("hg_stats") or CreateClientConVar("hg_stats", 1, true, false, "show stats", 0, 1)

local sharedTextList1 = {}
local sharedTextList2 = {}

hook_Add("HUDPaint", "homigrad-organism-debug", function()
	local lply = LocalPlayer()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local organism = lply:Alive() and lply.organism or (viewmode == 1 and IsValid(spect) and spect.organism) or {}
	
	if not organism.owner then return end
	if not developer:GetBool() or not lply:IsAdmin() or not hg_stats:GetBool() then return end

	getTextTable(organism, sharedTextList1)
	local list_len1 = #sharedTextList1
	
	local h = math_Round(ScreenScaleH(5.5))
	local scH = ScrH()
	local scW = ScrW()
	local cutoff = math_floor((scH - 200) / h)

	draw_RoundedBox(0, 15, 150, weight, cutoff * h, black)
	
	if cutoff < list_len1 then
		draw_RoundedBox(0, 30 + weight, 150, weight, (list_len1 - cutoff) * h, black)
	end

	for i = 1, list_len1 do
		local text = sharedTextList1[i]
		local y = i > cutoff and 150 + (i - 1 - cutoff) * h or 150 + (i - 1) * h
		local x = i > cutoff and 30 + weight or 15
		
		if i % 2 == 0 then draw_RoundedBox(0, x, y, weight, h, littleblack) end
		if text[3] then
			trahalgmod.r, trahalgmod.g, trahalgmod.b, trahalgmod.a = text[3], text[4], text[5], 75
			draw_RoundedBox(0, x, y, weight, h, trahalgmod)
		end

		draw_SimpleText(text[1], "DefaultFixedDropShadow", x, y, white)
		draw_SimpleText(text[2], "DefaultFixedDropShadow", x + weight, y, white, TEXT_ALIGN_RIGHT)
	end

	local tr = hg.eyeTrace and hg.eyeTrace(lply, 10000)
	if not tr or not IsValid(lply) then return end

	local trent = tr.Entity
	local organism_otherply = trent.organism
	if not organism_otherply or not organism_otherply.owner then return end

	getTextTable(organism_otherply, sharedTextList2)
	local list_len2 = #sharedTextList2
	local x_other = scW - 15 - weight
	
	draw_RoundedBox(0, x_other, 15, weight, list_len2 * h, black)
	for i = 1, list_len2 do
		local text = sharedTextList2[i]
		local y = 15 + (i - 1) * h
		if i % 2 == 0 then draw_RoundedBox(0, x_other, y, weight, h, littleblack) end
		if text[3] then
			trahalgmod.r, trahalgmod.g, trahalgmod.b, trahalgmod.a = text[3], text[4], text[5], 75
			draw_RoundedBox(0, x_other, y, weight, h, trahalgmod)
		end

		draw_SimpleText(text[1], "DefaultFixedDropShadow", scW - 15, y, white, TEXT_ALIGN_RIGHT)
		draw_SimpleText(text[2], "DefaultFixedDropShadow", x_other, y, white)
	end
end)

timeHuy = timeHuy or 0
local ent = NULL
local model = "models/Humans/group01/Female_03.mdl"
local pos = Vector(0, 0, 0)
local bones = {}
local tracePoses = {}
local hitBoxs = {}
local dmg = 0
local size = 0
local matpos, matang

if IsValid(csmodel) then csmodel:Remove() end
csmodel = ClientsideModel("models/Humans/group01/Female_03.mdl", RENDERMODE_TRANSCOLOR)
csmodel:SetNoDraw(true)

if IsValid(skiletmodel) then skiletmodel:Remove() end
skiletmodel = ClientsideModel("models/player/skeleton.mdl", RENDERMODE_TRANSCOLOR)
skiletmodel:SetNoDraw(true)
skiletmodel:SetSkin(2)
skiletmodel:AddEffects(EF_BONEMERGE)
skiletmodel:SetParent(csmodel)

if IsValid(bulletmodel) then bulletmodel:Remove() end
bulletmodel = ClientsideModel("models/bullets/w_pbullet1.mdl", RENDERMODE_TRANSCOLOR)
bulletmodel:SetNoDraw(true)

local organs, boxs, sphere
local angle = Angle(25, 0, 0)
local traveltime = 5
local hitorgans = {}
local angZero = Angle(0, 0, 0)
local vecFull = Vector(1, 1, 1)
local bone0 = Vector()
local ricochets = {}
local hg_max_hitshow = ConVarExists("hg_max_hitshow") and GetConVar("hg_max_hitshow") or CreateClientConVar("hg_max_hitshow", 40, true, false, "how many hits to track on your local pc (very bad idea to put this to more than 60)", 0, 150)

local iter = 1
local inf
local attacker

local function startPlayingHit(i)
	local curHit = hg.hits[i]
	if not curHit then return end
	
	tracePoses = curHit.tracePoses
	ent = curHit.ent
	hitBoxs = curHit.hitBoxs
	dmg = curHit.dmg
	size = curHit.size
	traveltime = curHit.traveltime
	attacker = curHit.att
	model = curHit.model
	bone0 = curHit.bone0
	bones = curHit.bones
	ricochets = curHit.ricochets
	inf = curHit.inf
	
	csmodel:SetPos(bone0:GetTranslation())
	csmodel:SetModel(model)
	csmodel.armors = curHit.armors or {}
	
	organs = hg.organism.GetHitBoxOrgans(model, csmodel)
	boxs, pos, sphere = hg.organism.ShootMatrix(csmodel, organs)
	if not boxs then return end

	curHit.organs = organs
	curHit.boxs = boxs
	hitorgans = {}
	
	for j = 1, #boxs do
		local box = boxs[j]
		local organ = box[6] and organs[box[6]][box[7]]
		if organ and hitBoxs[j] then hitorgans[j] = organ[1] end
	end

	local cbks = csmodel:GetCallbacks("BuildBonePositions")
	if cbks then
		for j, _ in pairs(cbks) do
			csmodel:RemoveCallback("BuildBonePositions", j)
		end
	end

	csmodel:AddCallback("BuildBonePositions", function()
		for j = 0, csmodel:GetBoneCount() do
			local bMat = bones[j]
			if not bMat or not csmodel:GetBoneMatrix(j) then goto skipbone end
			bMat:SetScale(vecFull)
			csmodel:SetBoneMatrix(j, bMat)
			::skipbone::
		end
	end)

	timeHuy = 0
end

hook_Add("Player_Death", "wowww", function(ply)
	if ply ~= LocalPlayer() or #hg.hits == 0 then return end
	iter = #hg.hits
	if iter > 0 then startPlayingHit(iter) end
end)

hook_Add("Player Spawn", "removehuys", function(ply)
	if ply ~= LocalPlayer() then return end
	hg.hits = {}
end)

function draw.RotatedText(text, x, y, font, color, ang)
	render_PushFilterMag(TEXFILTER.ANISOTROPIC)
	render_PushFilterMin(TEXFILTER.ANISOTROPIC)
	local m = Matrix()
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, ang, 0))
	surface_SetFont(font)
	local w, h = surface_GetTextSize(text)
	m:Translate(-Vector(w / 2, h / 2, 0))
	cam_PushModelMatrix(m)
	draw_DrawText(text, font, 0, 0, color)
	cam_PopModelMatrix()
	render_PopFilterMag()
	render_PopFilterMin()
end

function hg.DeathCamAvailable(ply)
	return timeHuy and ((timeHuy + traveltime) > CurTime()) and #hg.hits > 0
end

local delta = 0
hook_Add("CreateMove", "delta-counting-hg", function(cmd)
	delta = cmd:GetMouseWheel()
end)

local len = 50
function hg.DeathCam(ply, origin, angles, fov, znear, zfar)
	local lply = LocalPlayer()
	if not lply:Alive() then
		len = math_Clamp(len - delta * 10, 10, 50)
		local ct = CurTime()
		if timeHuy == 0 then timeHuy = ct end
		if lply:KeyDown(IN_RELOAD) then timeHuy = nil; hg.hits = {} end
		if timeHuy and ((timeHuy + traveltime) > ct) then
			local tbl = tracePoses
			local tLen = #tbl
			local part = 1 - ((timeHuy + traveltime) - ct) / traveltime
			local idx = math_floor(tLen * part)
			
			local firstpoint = tbl[math_min(idx + 1, tLen)]
			local secondpoint = tbl[math_min(idx + 2, tLen)]
			local nextfirstpoint = tbl[math_min(idx + 2, tLen)]
			local nextsecondpoint = tbl[math_min(idx + 3, tLen)]
			
			if not firstpoint or not secondpoint or not nextfirstpoint or not nextsecondpoint then return end

			local frac = (tLen * part) - idx
			local point2 = LerpVector(frac, secondpoint, nextsecondpoint)

			return {
				origin = point2 + angles:Forward() * -len,
				angles = angles,
				fov = fov,
				drawviewer = true
			}
		end
	end
end

local weight_hud = ScreenScale(100)
local colblack = Color(0, 0, 0, 255)
local colyellow = Color(255, 217, 0)
local colblacka = Color(22, 22, 22, 255)
local lineCol = Color(0, 0, 0, 100)
local mathuy = Material("color")

surface.CreateFont("DefaultFixedDropShadowBig", {
	font = "DefaultFixedDropShadow",
	size = ScreenScale(12),
})

local attpressed, attpressed2

hook_Add("HUDPaint", "homigrad-wound-debug", function()
	local lply = LocalPlayer()
	if not lply:Alive() then
		local ct = CurTime()
		if timeHuy == 0 then timeHuy = ct end
		if lply:KeyDown(IN_RELOAD) then timeHuy = nil; hg.hits = {} end

		local hitCnt = #hg.hits
		if (lply:KeyDown(IN_ATTACK2) or lply:KeyDown(IN_MOVERIGHT)) and timeHuy and hitCnt ~= 0 then
			if not attpressed then
				iter = (iter + 1 > hitCnt) and 1 or (iter + 1)
				startPlayingHit(iter)
				attpressed = true
			end
		else
			attpressed = nil
		end

		if (lply:KeyDown(IN_ATTACK) or lply:KeyDown(IN_MOVELEFT)) and timeHuy and hitCnt ~= 0 then
			if not attpressed2 then
				iter = (iter - 1 < 1) and hitCnt or (iter - 1)
				startPlayingHit(iter)
				attpressed2 = true
			end
		else
			attpressed2 = nil
		end
		
		if timeHuy and ((timeHuy + traveltime) > ct) then
			local tbl = tracePoses
			local tLen = #tbl
			local part = 1 - ((timeHuy + traveltime) - ct) / traveltime
			local alpha = ((timeHuy + traveltime) - ct) / 0.2
			local idx = math_floor(tLen * part)
					
			local firstpoint = tbl[math_min(idx + 1, tLen)]
			local secondpoint = tbl[math_min(idx + 2, tLen)]
			local nextfirstpoint = tbl[math_min(idx + 2, tLen)]
			local nextsecondpoint = tbl[math_min(idx + 3, tLen)]
			
			if not firstpoint or not secondpoint or not nextfirstpoint or not nextsecondpoint then return end
			
			local frac = (tLen * part) - idx
			local point2 = LerpVector(frac, secondpoint, nextsecondpoint)
			colblack.a = 255 * alpha
			angle.y = angle.y + 0.25
			
			local scW, scH = ScrW(), ScrH()
			
			cam_Start3D()
				render_SetStencilWriteMask(0xFF)
				render_SetStencilTestMask(0xFF)
				render_SetStencilReferenceValue(0)
				render_SetStencilCompareFunction(STENCIL_ALWAYS)
				render_SetStencilPassOperation(STENCIL_KEEP)
				render_SetStencilFailOperation(STENCIL_KEEP)
				render_SetStencilZFailOperation(STENCIL_KEEP)
				render_ClearStencil()
				
				render_SetStencilEnable(true)
				render_SetStencilReferenceValue(1)
				render_SetStencilPassOperation(STENCIL_REPLACE)

				csmodel:DrawModel()

				render_SetStencilCompareFunction(STENCIL_EQUAL)
				render_SetStencilPassOperation(STENCIL_INCR)
				render_SetStencilZFailOperation(STENCIL_INCR)
				
				local huyalpha = alpha * 0.2 / traveltime
				huyalpha = huyalpha > 0.2 and 1 or (huyalpha / 0.2)
				render_SetMaterial(mathuy)
				render_DrawSphere(point2, 7 * huyalpha, 50, 50, colblacka)
				
				render_SetStencilReferenceValue(2)
				render_SetStencilPassOperation(STENCIL_KEEP)
				render_SetStencilZFailOperation(STENCIL_KEEP)
				render_ClearBuffersObeyStencil(0, 0, 0, 0, true)

				cam_Start2D()
					surface_SetDrawColor(155, 0, 0, 15)
					surface_DrawTexturedRect(0, 0, scW, scH, 0)
					surface_SetDrawColor(155, 0, 0, 95)
					surface_DrawTexturedRect(0, 0, scW, scH, 0)
				cam_End2D()

				for j = 1, #boxs do
					if not hitBoxs[j] then goto skipbox end
					local box = boxs[j]
					local organ = box[6] and organs[box[6]][box[7]]
					local colTbl = organ and organ[6] or white
					local col = Color(colTbl.r, colTbl.g, colTbl.b, 50)
					render_DrawWireframeBox(box[1], box[2], box[3], box[4], col, false)
					::skipbox::
				end
				
				render_SetStencilEnable(false)

				white.r, white.g, white.b, white.a = 255, 255, 255, 255

				render_SetColorMaterial()
				local diff = nextsecondpoint - nextfirstpoint
				local s9 = size * 0.9
				local v1 = -Vector(0, size, size)
				local v2 = Vector(diff:Length(), s9, s9)
				local v3 = -Vector(0, s9, s9)
				
				render_DrawBox(nextfirstpoint, diff:Angle(), v1, v2, colyellow)
				render_DrawWireframeBox(nextfirstpoint, diff:Angle(), v3, v2, colyellow)
				
				for j = 1, tLen - 1 do
					local pdiff = tbl[j+1] - tbl[j]
					render_DrawWireframeBox(tbl[j], pdiff:Angle(), v3, Vector(pdiff:Length(), s9, s9), lineCol)
				end
			cam_End3D()
			
			draw_SimpleText("R to skip.", "HomigradFontBig", scW * 0.666, scH * 0.142, white)
			draw_SimpleText("Hit " .. tostring(iter) .. " of " .. tostring(hitCnt) .. " by " .. (inf or "unknown") .. " from " .. (attacker or "unknown"), "HomigradFontBig", scW * 0.666, scH * 0.1, white)
		end
	end
end)