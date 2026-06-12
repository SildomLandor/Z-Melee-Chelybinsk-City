-- Убедись, что "scaf" задан выше (например, "homigrad")
local pp_scaf = CreateClientConVar("pp_scaf", "1", true, false, "Enable/Disable chromatic aberration filter.", 0, 1)
local pp_scaf_intensity = CreateClientConVar("pp_scaf_intensity", "0", true, false, "How intense the chromatic aberration will be.", 0, 200)
local pp_scaf_redx = CreateClientConVar("pp_scaf_redx", "8", true, false, "Mixing in red channel along X.", 0, 128)
local pp_scaf_redy = CreateClientConVar("pp_scaf_redy", "4", true, false, "Mixing in red channel along Y.", 0, 128)
local pp_scaf_greenx = CreateClientConVar("pp_scaf_greenx", "4", true, false, "...", 0, 128)
local pp_scaf_greeny = CreateClientConVar("pp_scaf_greeny", "2", true, false, "...", 0, 128)
local pp_scaf_bluex = CreateClientConVar("pp_scaf_bluex", "0", true, false, "...", 0, 128)
local pp_scaf_bluey = CreateClientConVar("pp_scaf_bluey", "0", true, false, "...", 0, 128)

-- Глобальная таблица для внешнего управления
scaf = scaf or {}
local externalIntensity = 0

function scaf.SetIntensity(val)
	externalIntensity = val or 0
end

local enabled = pp_scaf:GetBool()
cvars.AddChangeCallback(pp_scaf:GetName(), function(_, __, new)
	enabled = new == "1"
end, "scaf")

local Run = hook.Run
local function isPostProcessPermitted()
	return enabled and Run("PostProcessPermitted", "scafilter") ~= false
end

-- Локальные переменные для множителей конваров (без учёта интенсивности)
local redXMul, greenXMul, blueXMul = 0, 0, 0
local redYMul, greenYMul, blueYMul = 0, 0, 0
local baseIntensity = 0

hook.Add("Think", "scaf", function()
	if isPostProcessPermitted() then
		baseIntensity = pp_scaf_intensity:GetFloat()
		redXMul = pp_scaf_redx:GetInt()
		greenXMul = pp_scaf_greenx:GetInt()
		blueXMul = pp_scaf_bluex:GetInt()
		redYMul = pp_scaf_redy:GetInt()
		greenYMul = pp_scaf_greeny:GetInt()
		blueYMul = pp_scaf_bluey:GetInt()
	else
		baseIntensity = 0
		redXMul, greenXMul, blueXMul = 0, 0, 0
		redYMul, greenYMul, blueYMul = 0, 0, 0
	end
end)

local width, height = ScrW(), ScrH()
hook.Add("OnScreenSizeChanged", "scaf", function()
	width, height = ScrW(), ScrH()
end)

local SetMaterial = render.SetMaterial
local DrawScreenQuad = render.DrawScreenQuad
local DrawScreenQuadEx = render.DrawScreenQuadEx
local UpdateScreenEffectTexture = render.UpdateScreenEffectTexture

-- Материалы создаём при загрузке, но текстуру экрана получим позже
local red = Material("color/red")
local green = Material("color/green")
local blue = Material("color/blue")
local black = Material("vgui/black")

-- Флаг первого обновления текстуры
local screenTexReady = false

hook.Add("RenderScreenspaceEffects", "scaf", function()
	local finalIntensity = math.max(baseIntensity, externalIntensity)
	if finalIntensity <= 0 then return end

	-- Однократно получаем и задаём текстуру экрана, когда она гарантированно существует
	if not screenTexReady then
		local screenTex = render.GetScreenEffectTexture(0)
		if screenTex then
			red:SetTexture("$basetexture", screenTex)
			green:SetTexture("$basetexture", screenTex)
			blue:SetTexture("$basetexture", screenTex)
			screenTexReady = true
		else
			return -- ещё не готово
		end
	end

	UpdateScreenEffectTexture()

	local floor = math.floor
	local rX = floor(redXMul * finalIntensity)
	local gX = floor(greenXMul * finalIntensity)
	local bX = floor(blueXMul * finalIntensity)
	local rY = floor(redYMul * finalIntensity)
	local gY = floor(greenYMul * finalIntensity)
	local bY = floor(blueYMul * finalIntensity)

	-- Заливаем чёрным дважды (особенность оригинального шейдера)
	SetMaterial(black)
	DrawScreenQuad()
	SetMaterial(black)
	DrawScreenQuad()

	-- Рисуем цветовые каналы со смещением
	SetMaterial(red)
	DrawScreenQuadEx(-rX / 2, -rY / 2, width + rX, height + rY)

	SetMaterial(green)
	DrawScreenQuadEx(-gX / 2, -gY / 2, width + gX, height + gY)

	SetMaterial(blue)
	DrawScreenQuadEx(-bX / 2, -bY / 2, width + bX, height + bY)
end)