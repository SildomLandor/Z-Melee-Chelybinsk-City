local CLASS = player.RegClass("police")

function CLASS.Off(self)
    if CLIENT then return end
end

local models = {
    -- Male
    ["male 01"] = "models/player/kerry/policeru_01_patrol.mdl",
    ["male 02"] = "models/player/kerry/policeru_02_patrol.mdl",
    ["male 03"] = "models/player/kerry/policeru_03_patrol.mdl",
    ["male 04"] = "models/player/kerry/policeru_04_patrol.mdl",
    ["male 05"] = "models/player/kerry/policeru_05_patrol.mdl",
    ["male 06"] = "models/player/kerry/policeru_06_patrol.mdl",
    ["male 07"] = "models/player/kerry/policeru_07_patrol.mdl",
    -- FEMKI
}

local ranks = {
    {name = "Ряд", chance = 25, rankbg = 0},      -- Рядовой
    {name = "М.С", chance = 20, rankbg = 0},      -- Младший сержант
    {name = "Сер", chance = 18, rankbg = 0},      -- Сержант
    {name = "С.С", chance = 12, rankbg = 0},      -- Старший сержант
    {name = "Ста", chance = 8, rankbg = 0},       -- Старшина
    {name = "Пра", chance = 7, rankbg = 0},       -- Прапорщик
    {name = "С.П", chance = 4, rankbg = 1},       -- Старший прапорщик
    {name = "М.Л", chance = 2.5, rankbg = 1},     -- Младший лейтенант
    {name = "Лей", chance = 1.2, rankbg = 1},     -- Лейтенант
    {name = "С.Л", chance = 0.8, rankbg = 1},     -- Старший лейтенант
    {name = "Кап", chance = 0.5, rankbg = 1},     -- Капитан
    {name = "Май", chance = 0.3, rankbg = 1},     -- Майор
    {name = "П.П", chance = 0.1, rankbg = 1},     -- Подполковник
    {name = "Пол", chance = 0.3, rankbg = 2},     -- Полковник
    {name = "Г.М", chance = 0.2, rankbg = 2},     -- Генерал-майор
    {name = "Г.Л", chance = 0.08, rankbg = 2},    -- Генерал-лейтенант
    {name = "Г.П", chance = 0.02, rankbg = 2},    -- Генерал-полковник
    {name = "Г.Р", chance = 0.01, rankbg = 2},    -- Генерал РФ
}


local clr = Color(10, 10, 100):ToVector()
function CLASS.On(self)
    if CLIENT then return end
    ApplyAppearance(self,nil,nil,nil,true)
    local Appearance = self.CurAppearance
    Appearance.AAttachments = ""
    Appearance.AColthes = ""

    local randomValue = math.random(100)
    local cumulativeChance = 0
    local rank = "ЛОХ"
    local rankBg = 0

    for _, rankInfo in ipairs(ranks) do
        cumulativeChance = cumulativeChance + rankInfo.chance
        if randomValue <= cumulativeChance then
            rank = rankInfo.name
            rankBg = rankInfo.rankbg or 0
            break
        end
    end

    self:SetNWString("PlayerName", rank .. " " .. Appearance.AName)
    self:SetPlayerColor(clr)
        local modelList = {}
    for _, mdl in pairs(models) do
        table.insert(modelList, mdl)
    end
    local selectedModel = modelList[math.random(#modelList)]
    self:SetModel(selectedModel)
    self:SetBodygroup(3, rankBg)
    self:SetSubMaterial()
    self:SetNetVar("Accessories", Appearance.AAttachmets or "none")
    self.CurAppearance = Appearance
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

