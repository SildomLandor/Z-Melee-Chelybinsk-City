local math_Clamp = math.Clamp

hook.Add("InitPostEntity", "PepperSpray_PatchConsciousness", function()
    if not hg or not hg.CalculateConsciousnessMul then return end

    hg.CalculateConsciousnessMul = function()
        local consciousness = 1
        local org = LocalPlayer().organism
        if org and org.consciousness then
            consciousness = consciousness * org.consciousness
            consciousness = consciousness * math_Clamp((org.blood or 5000) / 4000, 0.5, 1)
            consciousness = consciousness * math_Clamp((org.o2 and org.o2[1] or 100) / 20, 0.5, 1)
            consciousness = consciousness * (1 - (org.disorientation or 0) / 10)
        end
        return math_Clamp((consciousness - 1) * 3 + 1, 0.4, 1)
    end
end)

local pepperspray_irritation = {
    "ГЛАЗА!! БЛЯТЬ!!",
    "ЧТО ЗА ХЕРНЯ - ГЛАЗА!",
    "ЖЖЁТ!! ПРОСТО НЕВЫНОСИМО ЖЖЁТ!!",
    "Я НИЧЕГО НЕ ВИЖУ!!",
    "ЛИЦО ПОЛЫХАЕТ!!",
    "АААА - СМЫЙТЕ ЭТО! СМЫЙТЕ С ЛИЦА!!",
    "БЛЯТЬ БЛЯТЬ БЛЯТЬ, ГЛАЗА!!",
    "ОН В ГЛАЗАХ! ГОСПОДИ, КАК ЖЖЁТ!",
    "НЕ МОГУ ДЫШАТЬ - ГЛАЗА - БЛЯТЬ!",
    "ПОМОГИТЕ, Я НИЧЕГО НЕ ВИЖУ!",
    "ГОСПОДИ, ПУСТЬ ПЕРЕСТАНЕТ ЖЕЧЬ!",
    "ГЛАЗА ПЛАВЯТСЯ!! ЧЁРТ!!",
    "Я ЩА СДОХНУ - Я НЕ ВИЖУ!",
    "ВОДЫ! ДАЙТЕ ВОДЫ! ГЛАЗА!!",
}

local pepperspray_blind = {
    "Я ничего не вижу... Совсем ничего не вижу...",
    "Всё темно... Глаза не открываются...",
    "Всё ещё жжёт... даже с закрытыми глазами...",
    "Почему я не могу открыть глаза... Блядь...",
    "Я ослеп? Господи, я что, реально ослеп??",
    "Жжение не проходит. Я вообще ничего не вижу.",
    "Я даже не могу заставить глаза открыться...",
    "Одна только тьма... и огонь на лице...",
    "Пожалуйста... Мне нужна вода... Мои глаза...",
    "Я полностью ослеп. Чёрт. Чёрт. ЧЁРТ.",
}

local pepperspray_recovery = {
    "Кажется... я что-то начинаю видеть...",
    "Становится чуть-чуть легче...",
    "Глаза всё ещё адски жжёт...",
    "Я едва различаю очертания...",
    "Никогда больше... ни за что...",
    "Лицо до сих пор будто горит...",
    "Зрение возвращается... медленно...",
    "Это было самое ужасное, что я когда-либо чувствовал.",
}

local nextThoughtTime = {}
local THOUGHT_COOLDOWN = 10

hook.Add("InitPostEntity", "PepperSpray_ThoughtMessages", function()
    if not hg or not hg.get_status_message then return end

    local originalFunc = hg.get_status_message
    hg.get_status_message = function(ply)
        if not IsValid(ply) then return originalFunc(ply) end

        local exposure   = ply:GetNWFloat("PS_Exposure", 0)
        local blindEnd   = ply:GetNWFloat("PS_BlindEndTime", 0)
        local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
        local tint       = ply:GetNWFloat("PS_LingeringTint", 0)

        local isPhase1 = (exposure > 0.3 or tint > 0) and (blindEnd <= 0 or CurTime() >= blindEnd) and (recovStart <= 0 or CurTime() - recovStart >= 5)
        local isPhase2 = blindEnd > 0 and CurTime() < blindEnd
        local isPhase3 = recovStart > 0 and CurTime() - recovStart < 5

        if isPhase1 or isPhase2 or isPhase3 then
            local id = ply:SteamID()
            if (nextThoughtTime[id] or 0) > CurTime() then
                return ""
            end
            nextThoughtTime[id] = CurTime() + THOUGHT_COOLDOWN

            if isPhase1 then
                return pepperspray_irritation[math.random(#pepperspray_irritation)]
            elseif isPhase2 then
                return pepperspray_blind[math.random(#pepperspray_blind)]
            elseif isPhase3 then
                return pepperspray_recovery[math.random(#pepperspray_recovery)]
            end
        end

        return originalFunc(ply)
    end

    local originalLikely = hg.likely_to_phrase
    if originalLikely then
        hg.likely_to_phrase = function(ply)
            if not IsValid(ply) then return originalLikely(ply) end

            local exposure   = ply:GetNWFloat("PS_Exposure", 0)
            local blindEnd   = ply:GetNWFloat("PS_BlindEndTime", 0)
            local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
            local tint       = ply:GetNWFloat("PS_LingeringTint", 0)

            if exposure > 0.3 or tint > 0 or (blindEnd > 0 and CurTime() < blindEnd) then
                return 100
            end
            if recovStart > 0 and CurTime() - recovStart < 5 then
                return 1.5
            end

            return originalLikely(ply)
        end
    end
end)