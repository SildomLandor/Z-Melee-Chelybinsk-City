local fps = 1 / 24
local delay = 0
local math_min = math.min
local CurTime = CurTime

gasparticles_hook = gasparticles_hook or {}
local gasparticles_hook = gasparticles_hook

hook.Add("PostDrawOpaqueRenderables", "gasparticles", function()
	local t = CurTime()
	if delay > t then
		local draw = gasparticles_hook[1]
		if draw then draw(math_min((delay - t) / fps, 1)) end
	else
		delay = t + fps
		local step = gasparticles_hook[2]
		if step then step(fps) end
	end
end)
