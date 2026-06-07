local mouthFlexNames = {
    "jaw_drop",
    "left_part",
    "right_part",
    "left_mouth_drop",
    "right_mouth_drop",
    "talk", 
    "voice", 
    "phoneme", 
    "mouth",
    "mouth_open",
    "open",
    "open_mouth",
    "jaw_open",
    "shrug_mouth",
    "jaw_down",
    "lower_lip_depressor",
    "lip_part",
    "AA", "O", "CH", "AO", "ah", "oh",
    "AU25", "AU26", "AU27",
    "phoneme_aa", "phoneme_ao", "phoneme_oh", "phoneme_o",
    "jaw_drop_low", "mouth_drop", "lips_part", "chin_raiser", "upper_lip_raiser",
    "uh", "ae", "aw", "er", "oo", "AU26Z", "AU22", "AU17", "AU16", "AU10",
    "phoneme_uh", "phoneme_aw", "phoneme_ah"
}

local flexKeywords = {
    "open", "jaw", "mouth", "phoneme", "v_aa", "v_ao"
}

local mouthTargets = {}
local mouthCurrents = {}
local cachedBones = {}
local cachedKeywordFlexIDs = {}

hook.Add("Initialize", "VoiceFix_KillMouthAutopilot", function()
    function GAMEMODE:MouthMoveAnimation(ply)
    end
end)

local function UpdateMouthVariable(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local entID = ply:EntIndex()
    mouthTargets[entID] = mouthTargets[entID] or 0
    mouthCurrents[entID] = mouthCurrents[entID] or 0

    local volume = ply:VoiceVolume() or 0
    
    if volume > 0 then
        mouthTargets[entID] = math.Clamp(volume * 5, 0, 1)
    else
        mouthTargets[entID] = 0
    end

    mouthCurrents[entID] = Lerp(FrameTime() * 15, mouthCurrents[entID], mouthTargets[entID])

    if mouthCurrents[entID] < 0.01 then 
        mouthCurrents[entID] = 0 
    end
end

local function ApplyExactFlexMouth(ply)
    local flexNum = ply:GetFlexNum() or 0
    if flexNum <= 0 then return false end

    local currentLevel = mouthCurrents[ply:EntIndex()] or 0
    local appliedAny = false

    for i = 1, #mouthFlexNames do
        local flexID = ply:GetFlexIDByName(mouthFlexNames[i])
        if flexID and flexID >= 0 and flexID < flexNum then
            ply:SetFlexWeight(flexID, currentLevel)
            appliedAny = true
        end
    end

    return appliedAny
end

local function ApplyKeywordFlexMouth(ply)
    local flexNum = ply:GetFlexNum() or 0
    if flexNum <= 0 then return false end

    local mdl = ply:GetModel()
    local currentLevel = mouthCurrents[ply:EntIndex()] or 0

    if cachedKeywordFlexIDs[mdl] == nil then
        local cache = {}
        for i = 0, flexNum - 1 do
            local name = ply:GetFlexName(i)
            if name then
                local lowerName = string.lower(name)
                for _, keyword in ipairs(flexKeywords) do
                    if string.find(lowerName, keyword) then
                        table.insert(cache, i)
                        break
                    end
                end
            end
        end
        cachedKeywordFlexIDs[mdl] = cache
    end

    local validFlexs = cachedKeywordFlexIDs[mdl]
    if #validFlexs > 0 then
        for _, flexID in ipairs(validFlexs) do
            ply:SetFlexWeight(flexID, currentLevel)
        end
        return true
    end

    return false
end

local function GetModelBoneCache(ply)
    local mdl = ply:GetModel()
    if cachedBones[mdl] then return cachedBones[mdl] end

    local cache = {
        jaw = {},
        lowLip = {},
        upLip = {}
    }

    local count = ply:GetBoneCount() or 0
    for i = 0, count - 1 do
        local name = ply:GetBoneName(i)
        if name then
            local lowerName = string.lower(name)

            if string.find(lowerName, "jaw") or string.find(lowerName, "chin") or string.find(lowerName, "facelower") or string.find(lowerName, "mandible") then
                table.insert(cache.jaw, i)

            elseif string.find(lowerName, "lip2") or string.find(lowerName, "lip_2") or
                   (string.find(lowerName, "lip") and (string.find(lowerName, "_d_") or string.find(lowerName, "low") or string.find(lowerName, "inf"))) or
                   (string.find(lowerName, "mouth") and (string.find(lowerName, "_l") or string.find(lowerName, "bot"))) or
                   string.find(lowerName, "tongue") or (string.find(lowerName, "teeth") and (string.find(lowerName, "_d_") or string.find(lowerName, "low"))) then
                table.insert(cache.lowLip, i)

            elseif string.find(lowerName, "lip1") or string.find(lowerName, "lip_1") or
                   (string.find(lowerName, "lip") and (string.find(lowerName, "_t_") or string.find(lowerName, "up") or string.find(lowerName, "sup"))) or
                   (string.find(lowerName, "mouth") and (string.find(lowerName, "_u") or string.find(lowerName, "top"))) or
                   (string.find(lowerName, "teeth") and (string.find(lowerName, "_t_") or string.find(lowerName, "up"))) then
                table.insert(cache.upLip, i)
            end
        end
    end

    cachedBones[mdl] = cache
    return cache
end

local function ApplyBoneMouth(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local entID = ply:EntIndex()
    local currentLevel = mouthCurrents[entID] or 0
    local bones = GetModelBoneCache(ply)

    local maxJawAngle = 3 
    local currentJawAngle = currentLevel * maxJawAngle

    if currentJawAngle > 0 then
        for _, boneID in ipairs(bones.jaw) do ply:ManipulateBoneAngles(boneID, Angle(0, 0, currentJawAngle)) end
        for _, boneID in ipairs(bones.lowLip) do ply:ManipulateBoneAngles(boneID, Angle(0, 0, currentJawAngle * 0.8)) end
        for _, boneID in ipairs(bones.upLip) do ply:ManipulateBoneAngles(boneID, Angle(0, 0, -currentJawAngle * 0.25)) end
    else
        for _, boneID in ipairs(bones.jaw) do ply:ManipulateBoneAngles(boneID, Angle(0,0,0)) end
        for _, boneID in ipairs(bones.lowLip) do ply:ManipulateBoneAngles(boneID, Angle(0,0,0)) end
        for _, boneID in ipairs(bones.upLip) do ply:ManipulateBoneAngles(boneID, Angle(0,0,0)) end
    end
end

local function ProcessPlayerLipSync(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    UpdateMouthVariable(ply)
    
    local success = ApplyExactFlexMouth(ply)
    
    if not success then
        success = ApplyKeywordFlexMouth(ply)
    end
    
    if not success then
        ApplyBoneMouth(ply)
    end
end

hook.Add("PrePlayerDraw", "vcfix_lipsync2", function(ply)
    ProcessPlayerLipSync(ply)
end)

hook.Add("PostPlayerDraw", "vcfix_lipsync1", function(ply)
    ProcessPlayerLipSync(ply)
end)

hook.Add("PostDrawOpaqueRenderables", "vcfix_lipsync", function()
    local lp = LocalPlayer()
    if IsValid(lp) and lp:IsPlayer() then
        ProcessPlayerLipSync(lp)
    end
end)