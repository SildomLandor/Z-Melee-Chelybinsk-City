gasparticles = gasparticles or {}

local MAX_PARTS = 96

function addGasPart(pos, vel)
	if #gasparticles >= MAX_PARTS then return end

	local pos2 = Vector()
	pos2:Set(pos)
	gasparticles[#gasparticles + 1] = {Vector(pos[1], pos[2], pos[3]), pos2, Vector(vel[1], vel[2], vel[3])}
end

net.Receive("gas particle", function()
	addGasPart(net.ReadVector(), net.ReadVector())
	net.ReadEntity()
end)
