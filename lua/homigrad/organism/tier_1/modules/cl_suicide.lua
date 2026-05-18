local active = false
local startTime = 0
local suicideSound = nil
local cancelRequested = false
local cancelMessageEnd = 0
local nextPhraseTime = 0

local phrases = {
    "Мне страшно",
    "Вдруг будет больно?",
    "Трясутся руки",
    "Я не хочу умирать",
    "Вдруг ад реален?",
    "Вдруг я выживу?",
    "Я не готов",
    "Зачем я это делаю?",
    "Ты слабак",
    "Ты ничтожество",
    "Трус",
    "Тряпка",
    "Позор",
    "Беглец",
    "Ошибка природы",
    "Никчёмный",
    "Жалкое зрелище",
    "Твоя семья опозорится",
    "Никто не вспомнит",
    "Ты не смог",
    "Слабый",
    "Пустое место",
    "Ты проиграл",
    "Остановись",
    "Это не конец",
    "Не сдавайся",
    "Ты сильнее, чем думаешь",
    "Дыши",
    "Успокойся",
    "Это позорная смерть",
    "Ты будешь жалеть",
    "Это не выход",
    "Тебя никто не спасёт",
    "Ты сам загнал себя",
    "Я не могу",
    "Это конец",
}

local activePhrases = {}
local phraseMinInterval = 0.3
local phraseMaxInterval = 1.2

local function PlaySuicideMusic()
    if suicideSound then suicideSound:Stop() end

    suicideSound = CreateSound(LocalPlayer(), "aftermath.mp3")
    suicideSound:Play()
    suicideSound:ChangeVolume(1, 0)

    timer.Simple(30, function()
        if active and IsValid(LocalPlayer()) then
            PlaySuicideMusic()
        end
    end)
end

net.Receive("HG_SuicideCutscene", function()
    local start = net.ReadBool()
    if start then
        active = true
        startTime = CurTime()
        cancelRequested = false
        activePhrases = {}
        nextPhraseTime = CurTime() + 0.5
        PlaySuicideMusic()
    else
        if active and cancelRequested then
            cancelMessageEnd = CurTime() + 2.0
            surface.PlaySound("goodbye.mp3")
        end
        active = false
        cancelRequested = false
        activePhrases = {}
        if suicideSound then
            suicideSound:Stop()
            suicideSound = nil
        end
        nextPhraseTime = 0
    end
end)

surface.CreateFont("SuicideFont", {
    font = "TrixiePro-Heavy",
    size = ScreenScale(20),
    weight = 1000,
    extended = true,
    antialias = true
})

surface.CreateFont("SuicideHintFont", {
    font = "TrixiePro-Heavy",
    size = ScreenScale(10),
    weight = 600,
    extended = true,
    antialias = true
})

hook.Add("StartCommand", "HG_SuicideCutsceneInput", function(ply, cmd)
    if active then
        cmd:ClearMovement()
        if not cancelRequested and cmd:KeyDown(IN_USE) then
            net.Start("HG_SuicideCancel")
            net.SendToServer()
            cancelRequested = true
        end
        if cancelRequested then
            cmd:ClearButtons()
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "HG_SuicideCutsceneOverlay", function()
    if not active then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local elapsed = CurTime() - startTime
    local alpha = math.Clamp(elapsed * 0.85, 0, 0.85)
    local finalFade = math.Clamp((elapsed - 6.0) / 2.0, 0, 1)
    local redTint = 0
    if finalFade > 0 then
        redTint = finalFade * 30
    end

    local darkColor = Color(redTint * 0.5, 0, 0, alpha * 255)

    cam.Start2D()
        surface.SetDrawColor(darkColor)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        for i = 1, 5 do
            local t = i / 5
            surface.SetDrawColor(Color(0, 0, 0, alpha * 50 * (1 - t)))
        end
    cam.End2D()
end)

hook.Add("HUDShouldDraw", "HG_HideHUDSuicide", function(name)
    if active then
        return false
    end
end)

hook.Add("CalcView", "HG_SuicideCutsceneView", function(ply, origin, angles, fov)
    if active then
        local view = {}
        view.origin = origin
        view.angles = Angle(60, angles[2], 0)
        view.fov = fov
        return view
    end
end)

hook.Add("DrawOverlay", "HG_SuicideCutsceneText", function()
    if active and not cancelRequested then
        local hint = "Всегда есть путь назад    E"
        surface.SetFont("SuicideHintFont")
        local w, h = surface.GetTextSize(hint)
        local x = ScrW() / 2 - w / 2
        local y = ScrH() - h - 20
        draw.SimpleText(hint, "SuicideHintFont", x, y, Color(255, 255, 255, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    if active then
        local curTime = CurTime()
        if curTime >= nextPhraseTime then
            local text = table.Random(phrases)
            local margin = ScrW() * 0.1
            local x = math.random(margin, ScrW() - margin)
            local y = math.random(ScrH() * 0.1, ScrH() * 0.85)

            local colors = {
                Color(255, 255, 255),
                Color(255, 0, 0),
                Color(255, 251, 0),
                Color(43, 255, 0),
                Color(71, 0, 252),
            }
            local color = table.Random(colors)

            table.insert(activePhrases, {
                text = text,
                x = x,
                y = y,
                color = color,
                startTime = curTime,
                duration = math.random(25, 40)
            })

            sound.PlayFile("sound/snd_jack_hmcd_poof.wav", "", function(channel)
                if IsValid(channel) then
                    channel:Play()
                    channel:SetVolume(3)
                end
            end)

            nextPhraseTime = curTime + math.random(phraseMinInterval * 100, phraseMaxInterval * 100) / 100
        end

        for i = #activePhrases, 1, -1 do
            local phrase = activePhrases[i]
            local age = curTime - phrase.startTime

            if age > phrase.duration then
                table.remove(activePhrases, i)
            else
                local fadeInTime = 0.5
                local fadeOutTime = 2.0
                local alpha = 255

                if age < fadeInTime then
                    alpha = (age / fadeInTime) * 255
                elseif age > phrase.duration - fadeOutTime then
                    alpha = ((phrase.duration - age) / fadeInTime) * 255
                end

                local shakeX = 0
                local shakeY = 0
                if age < 0.2 then
                    shakeX = math.random(-3, 3)
                    shakeY = math.random(-3, 3)
                end

                surface.SetFont("SuicideFont")
                local drawColor = Color(phrase.color.r, phrase.color.g, phrase.color.b, math.Clamp(alpha, 0, 255))
                draw.SimpleText(phrase.text, "SuicideFont", phrase.x + shakeX, phrase.y + shakeY, drawColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end

    if CurTime() < cancelMessageEnd then
        local text = "Я... боюсь..."
        surface.SetFont("SuicideFont")
        local w, h = surface.GetTextSize(text)
        local shakeX = math.random(-6, 6)
        local shakeY = math.random(-6, 6)
        local x = ScrW() / 2 - w / 2 + shakeX
        local y = ScrH() / 2 - h / 2 + shakeY
        draw.SimpleText(text, "SuicideFont", x, y, Color(95, 19, 19), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end)