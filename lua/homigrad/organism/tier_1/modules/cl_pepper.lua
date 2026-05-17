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
    "MY EYES!! FUCK!!",
    "WHAT THE FUCK- MY EYES!",
    "IT BURNS!! IT FUCKING BURNS!!",
    "I CAN'T SEE SHIT!!",
    "MY FACE IS ON FIRE!!",
    "AAGH- GET IT OFF!! GET IT OFF MY FACE!!",
    "FUCK FUCK FUCK MY EYES!!",
    "IT'S IN MY EYES! OH GOD IT BURNS!",
    "I CAN'T BREATHE- MY EYES- FUCK!",
    "SOMEONE HELP ME I CAN'T SEE!",
    "OH GOD MAKE IT STOP BURNING!",
    "MY EYES ARE MELTING!! HOLY SHIT!!",
    "I'M GONNA FUCKING DIE- I CAN'T SEE!",
    "WATER! I NEED WATER! MY EYES!!",
}

local pepperspray_blind = {
    "I can't see... I can't see anything...",
    "Everything is dark... My eyes won't open...",
    "It still burns... even with my eyes closed...",
    "Why can't I open my eyes... Fuck...",
    "Am I blind? Oh god am I blind??",
    "The burning won't stop. I can't see shit.",
    "I can't even force my eyes open...",
    "Just darkness... and fire on my face...",
    "Please... I need water... My eyes...",
    "I'm completely blind. Shit. Shit. SHIT.",
}

local pepperspray_recovery = {
    "I think... I can see something...",
    "It's getting a bit better...",
    "My eyes still burn like hell...",
    "I can barely make things out...",
    "Never again... Never fucking again...",
    "My face still feels like it's on fire...",
    "Vision's coming back... slowly...",
    "That was the worst thing I've ever felt.",
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