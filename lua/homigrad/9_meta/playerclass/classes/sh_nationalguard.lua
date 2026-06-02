local CLASS = player.RegClass("nationalguard")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    {"models/player/bm_rosguard/male_02.mdl"},
    {"models/player/bm_rosguard/male_04.mdl"},
    {"models/player/bm_rosguard/male_06.mdl"},
    {"models/player/bm_rosguard/male_07.mdl"},
    {"models/player/bm_rosguard/male_08.mdl"},
    {"models/player/bm_rosguard/male_09.mdl"},
}

-- Добавили поле bg для каждого ранга от 0 до 17
local ranks = {
    {name = "Ряд", chance = 25, bg = 0},
    {name = "Ефр", chance = 20, bg = 1},
    {name = "М.С", chance = 18, bg = 2},
    {name = "Сер", chance = 12, bg = 3},
    {name = "С.С", chance = 8,  bg = 4},
    {name = "Ста", chance = 7,  bg = 5},
    {name = "Пра", chance = 4,  bg = 6},
    {name = "С.П", chance = 2.5,bg = 7},
    {name = "Лей", chance = 1.2,bg = 8},
    {name = "С.Л", chance = 0.8,bg = 9},
    {name = "Кап", chance = 0.5,bg = 10},
    {name = "Май", chance = 0.3,bg = 11},
    {name = "П.П", chance = 0.1,bg = 12},
    {name = "Пол", chance = 0.3,bg = 13},
    {name = "Г.М", chance = 0.2,bg = 14},
    {name = "Г.Л", chance = 0.08,bg = 15},
    {name = "Г.П", chance = 0.02,bg = 16},
    {name = "Г.А", chance = 0.01,bg = 17},
}

local clr = Color(5, 65, 0):ToVector()
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local randomValue = math.random() * 100
    local cumulativeChance = 0
    local rank = "PVT"
    local rankBg = 0 -- Переменная для хранения бодигруппы

    for _, rankInfo in ipairs(ranks) do
        cumulativeChance = cumulativeChance + rankInfo.chance
        if randomValue <= cumulativeChance then
            rank = rankInfo.name
            rankBg = rankInfo.bg -- Запоминаем бодигруппу выпавшего ранга
            break
        end
    end

    self:SetNWString("PlayerName", rank .. " " .. Appearance.AName)
    self:SetPlayerColor(clr)
    
    local selectedModelTable = models[math.random(#models)]
    self:SetModel(selectedModelTable[1])
    
    --local top = math.random(0,1) -- я глупый и не знаю как по-другому сделать
    self:SetBodygroup(05)   --self:SetBodygroup(05,2,top,3,rankBg,81)  -- сделайте пж когда нибудь нормальный рандом для рангов и рукавов
    -- top = 2 рукава rang = 3 ранг vest = 8 жилтка хочу чтобы они рандомились, но пока так, потому что я глупый и не знаю как по-другому сделать
    self:SetSubMaterial()
    self.CurAppearance = Appearance
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8 
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end

    if Victim:GetPlayerClass() == self:GetPlayerClass() then
        --self:ChatPrint("You killed your teammate!")
        return 1
    end

    if CurrentRound().name == "hmcd" then
        return zb.ForcesAttackedInnocent(self, Victim)
    end

    return 1
end

hook.Add("HG_PlayerFootstep", "nationalguard_footsteps", function(ply, pos, foot, sound, volume, rf)
	local chr = hg.GetCurrentCharacter(ply)
	if ply:Alive() and ply.PlayerClassName == "nationalguard" then
		local ent = hg.GetCurrentCharacter(ply)

		if not (ply:IsWalking() or ply:Crouching()) and ent == ply then
			local snd = "zcitysnd/" .. string.Replace(sound, "player/footsteps", "player/footsteps_military/")
			if SoundDuration(snd) <= 0 then
				snd = sound -- missing footsteps fix
			end
			EmitSound(snd, pos, ply:EntIndex(), CHAN_AUTO, volume, 75, nil, changePitch(math.random(95,105)) )

			return true
		end
	end
end)
