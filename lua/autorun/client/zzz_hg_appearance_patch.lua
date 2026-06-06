local PATCH_ID = "HG_AppearanceDedicatedCompatibility"

local function GetAppearanceModule()
    hg = hg or {}
    hg.Appearance = hg.Appearance or {}

    return hg.Appearance
end

local function GetFallbackModelData()
    local appearance = GetAppearanceModule()
    local playerModels = appearance.PlayerModels
    if istable(playerModels) then
        for sexIdx = 1, 2 do
            local sexModels = playerModels[sexIdx]
            if not istable(sexModels) then continue end

            local name, data = next(sexModels)
            if isstring(name) and istable(data) then
                return name, data
            end
        end
    end

    return "Male 01", {
        mdl = "models/player/group01/male_01.mdl",
        sex = false,
        submatSlots = {}
    }
end

local function ResolveModelDataForAppearance(tbl)
    if not istable(tbl) then return nil end

    local appearance = GetAppearanceModule()
    local playerModels = appearance.PlayerModels
    if not istable(playerModels) then return nil end

    local function byName(name)
        if not isstring(name) or name == "" then return nil end
        return (playerModels[1] and playerModels[1][name]) or (playerModels[2] and playerModels[2][name])
    end

    local tMdl = byName(tbl.AModel)
    if tMdl then return tMdl end

    local lply = LocalPlayer()
    if IsValid(lply) then
        local mdlPath = string.lower(lply:GetModel() or "")
        if mdlPath ~= "" then
            for sexIdx = 1, 2 do
                local sexModels = playerModels[sexIdx]
                if not istable(sexModels) then continue end

                for name, data in pairs(sexModels) do
                    if istable(data) and isstring(data.mdl) and string.lower(data.mdl) == mdlPath then
                        tbl.AModel = name
                        return data
                    end
                end
            end
        end
    end

    local skeleton = appearance.SkeletonAppearanceTable
    if istable(skeleton) and isstring(skeleton.AModel) then
        tMdl = byName(skeleton.AModel)
        if tMdl then
            tbl.AModel = skeleton.AModel
            return tMdl
        end
    end

    for sexIdx = 1, 2 do
        local sexModels = playerModels[sexIdx]
        if not istable(sexModels) then continue end

        local name, data = next(sexModels)
        if isstring(name) and istable(data) then
            tbl.AModel = name
            return data
        end
    end

    return nil
end

local function EnsureAppearanceTableDefaults(tbl)
    if not istable(tbl) then return tbl end

    local appearance = GetAppearanceModule()
    local skeleton = appearance.SkeletonAppearanceTable
    if not istable(skeleton) then return tbl end

    if not isstring(tbl.AName) or tbl.AName == "" then
        local lply = LocalPlayer()
        local nwName = IsValid(lply) and lply:GetNWString("PlayerName", "") or ""
        tbl.AName = nwName ~= "" and nwName or ""
    end

    tbl.AColor = tbl.AColor or skeleton.AColor or Color(255, 255, 255)

    if not istable(tbl.AClothes) then
        tbl.AClothes = table.Copy(skeleton.AClothes or {})
    else
        tbl.AClothes.main = tbl.AClothes.main or skeleton.AClothes.main
        tbl.AClothes.pants = tbl.AClothes.pants or tbl.AClothes.main or skeleton.AClothes.main
        tbl.AClothes.boots = tbl.AClothes.boots or tbl.AClothes.main or skeleton.AClothes.main
    end

    if not istable(tbl.AAttachments) then
        tbl.AAttachments = {"none", "none", "none"}
    end

    tbl.ABodygroups = tbl.ABodygroups or {}
    tbl.AFacemap = tbl.AFacemap or skeleton.AFacemap or "Default"

    return tbl
end

local function SanitizeAppearanceTableAgainstCatalog(tbl, modelData)
    if not istable(tbl) then return tbl end

    local appearance = GetAppearanceModule()
    appearance.Clothes = appearance.Clothes or { [1] = {}, [2] = {} }
    appearance.Bodygroups = appearance.Bodygroups or {}
    appearance.FacemapsSlots = appearance.FacemapsSlots or {}

    local sexIndex = (istable(modelData) and modelData.sex) and 2 or 1
    local clothesBySex = appearance.Clothes[sexIndex]
    if not istable(clothesBySex) then
        clothesBySex = {}
        appearance.Clothes[sexIndex] = clothesBySex
    end

    tbl.AClothes = istable(tbl.AClothes) and tbl.AClothes or {}
    for _, part in ipairs({"main", "pants", "boots"}) do
        local selected = tbl.AClothes[part]
        if not isstring(selected) or selected == "" or clothesBySex[selected] == nil then
            tbl.AClothes[part] = clothesBySex.normal and "normal" or next(clothesBySex) or selected or "normal"
        end
    end

    tbl.AAttachments = istable(tbl.AAttachments) and tbl.AAttachments or {}
    for i = 1, 3 do
        if not isstring(tbl.AAttachments[i]) or tbl.AAttachments[i] == "" then
            tbl.AAttachments[i] = "none"
        end
    end

    tbl.ABodygroups = istable(tbl.ABodygroups) and tbl.ABodygroups or {}
    for bodygroupName, selected in pairs(tbl.ABodygroups) do
        local bodygroupCatalog = appearance.Bodygroups[bodygroupName]
        local bodygroupSexCatalog = istable(bodygroupCatalog) and bodygroupCatalog[sexIndex] or nil
        if not isstring(selected) or not istable(bodygroupSexCatalog) or bodygroupSexCatalog[selected] == nil then
            tbl.ABodygroups[bodygroupName] = nil
        end
    end

    if not isstring(tbl.AFacemap) or tbl.AFacemap == "" then
        tbl.AFacemap = "Default"
    end

    return tbl
end

local function NormalizeAppearanceTable(tbl)
    if not istable(tbl) then return tbl end

    EnsureAppearanceTableDefaults(tbl)
    local modelData = ResolveModelDataForAppearance(tbl)
    if not modelData then
        local fallbackName, fallbackData = GetFallbackModelData()
        tbl.AModel = fallbackName
        modelData = fallbackData
    end

    SanitizeAppearanceTableAgainstCatalog(tbl, modelData)

    return tbl
end

local function FindFirstChildByClass(parent, className)
    if not IsValid(parent) or not parent.GetChildren then return nil end

    for _, child in ipairs(parent:GetChildren()) do
        if child.GetClassName and child:GetClassName() == className then
            return child
        end

        local nested = FindFirstChildByClass(child, className)
        if IsValid(nested) then
            return nested
        end
    end
end

local function PatchAppearanceViewer(panel)
    if not IsValid(panel) or panel.__DedicatedViewerPatchApplied then return false end

    local viewer = FindFirstChildByClass(panel, "DModelPanel")
    if not IsValid(viewer) then return false end

    panel.__DedicatedViewerPatchApplied = true

    local oldLayoutEntity = viewer.LayoutEntity
    function viewer:LayoutEntity(ent, ...)
        if IsValid(panel) then
            NormalizeAppearanceTable(panel.AppearanceTable)
        end

        local ok, result = xpcall(function()
            if isfunction(oldLayoutEntity) then
                return oldLayoutEntity(self, ent)
            end
        end, debug.traceback)

        if ok then
            return result
        end

        if not IsValid(ent) or not IsValid(panel) then return end

        NormalizeAppearanceTable(panel.AppearanceTable)
        local tbl = panel.AppearanceTable or {}
        local modelData = ResolveModelDataForAppearance(tbl)
        if not modelData then
            local fallbackName, fallbackData = GetFallbackModelData()
            tbl.AModel = fallbackName
            modelData = fallbackData
        end
        if not modelData or not isstring(modelData.mdl) or modelData.mdl == "" then return end

        local drawColor = tbl.AColor or Color(255, 255, 255)
        ent:SetNWVector("PlayerColor", Vector(drawColor.r / 255, drawColor.g / 255, drawColor.b / 255))

        if ent:GetModel() ~= modelData.mdl and util.IsValidModel(tostring(modelData.mdl)) then
            ent:SetModel(modelData.mdl)
            self:SetModel(modelData.mdl)
            tbl.AFacemap = "Default"
        end
    end

    local oldPostDrawModel = viewer.PostDrawModel
    function viewer:PostDrawModel(ent, ...)
        if IsValid(panel) then
            NormalizeAppearanceTable(panel.AppearanceTable)
        end

        local ok, result = xpcall(function()
            if isfunction(oldPostDrawModel) then
                return oldPostDrawModel(self, ent)
            end
        end, debug.traceback)

        if ok then
            return result
        end

        if not IsValid(ent) or not IsValid(panel) then return end

        local tbl = panel.AppearanceTable or {}
        for _, attach in ipairs(tbl.AAttachments or {}) do
            DrawAccesories(ent, ent, attach, hg.Accessories and hg.Accessories[attach], false, true)
        end

        ent:SetupBones()
    end

    return true
end

local function PatchLoadAppearanceFile()
    local appearance = GetAppearanceModule()
    if appearance.__DedicatedLoadPatchApplied or not isfunction(appearance.LoadAppearanceFile) then return false end

    appearance.__DedicatedLoadPatchApplied = true

    local oldLoadAppearanceFile = appearance.LoadAppearanceFile
    function appearance.LoadAppearanceFile(...)
        local tbl, reason = oldLoadAppearanceFile(...)
        if istable(tbl) then
            NormalizeAppearanceTable(tbl)
        end

        return tbl, reason
    end

    return true
end

local function PatchAppearancePanelControl()
    local control = vgui.GetControlTable("HG_AppearanceMenu")
    if not istable(control) or control.__DedicatedCompatibilityPatchApplied then return false end

    control.__DedicatedCompatibilityPatchApplied = true

    local oldSetAppearance = control.SetAppearance
    function control:SetAppearance(tbl, ...)
        NormalizeAppearanceTable(tbl)

        if isfunction(oldSetAppearance) then
            return oldSetAppearance(self, tbl, ...)
        end

        self.AppearanceTable = tbl
    end

    local oldPostInit = control.PostInit
    function control:PostInit(...)
        local appearance = GetAppearanceModule()
        local explicit = self.AppearanceTable
        local fromFile = isfunction(appearance.LoadAppearanceFile) and appearance.LoadAppearanceFile(appearance.SelectedAppearance and appearance.SelectedAppearance:GetString() or "main") or nil
        local useExplicit = false

        if istable(explicit) and next(explicit) ~= nil then
            if isfunction(appearance.AppearanceValidater) then
                useExplicit = appearance.AppearanceValidater(explicit)
            else
                useExplicit = true
            end
        end

        self.AppearanceTable = (useExplicit and explicit) or fromFile or (isfunction(appearance.GetRandomAppearance) and appearance.GetRandomAppearance()) or {}
        NormalizeAppearanceTable(self.AppearanceTable)

        local result
        if isfunction(oldPostInit) then
            result = oldPostInit(self, ...)
        end

        NormalizeAppearanceTable(self.AppearanceTable)
        PatchAppearanceViewer(self)

        return result
    end

    local oldThink = control.Think
    function control:Think(...)
        NormalizeAppearanceTable(self.AppearanceTable)
        PatchAppearanceViewer(self)

        if isfunction(oldThink) then
            return oldThink(self, ...)
        end
    end

    return true
end

hook.Add("Think", PATCH_ID, function()
    PatchLoadAppearanceFile()
    PatchAppearancePanelControl()

    local appearance = GetAppearanceModule()
    local control = vgui.GetControlTable("HG_AppearanceMenu")

    if appearance.__DedicatedLoadPatchApplied and istable(control) and control.__DedicatedCompatibilityPatchApplied then
        hook.Remove("Think", PATCH_ID)
    end
end)

