util.AddNetworkString("mac_p")
util.AddNetworkString("mac_r")
util.AddNetworkString("mac_k")
util.AddNetworkString("mac_c")

function mAC.SendProbe(ply)
	if not IsValid(ply) or not ply.mAC_probe then return end
	local list = ply.mAC_probe
	net.Start("mac_p")
		net.WriteUInt(ply.mAC_decoys or 0, 8)
		net.WriteUInt(#list, 10)
		for i = 1, #list do
			net.WriteString(list[i])
		end
		net.WriteUInt(#ply.mAC_glob, 8)
		for i = 1, #ply.mAC_glob do
			net.WriteString(ply.mAC_glob[i])
		end
		net.WriteUInt(#ply.mAC_cc, 8)
		for i = 1, #ply.mAC_cc do
			net.WriteString(ply.mAC_cc[i])
		end
		net.WriteUInt(#ply.mAC_mat, 8)
		for i = 1, #ply.mAC_mat do
			net.WriteString(ply.mAC_mat[i])
		end
	net.Send(ply)
end

function mAC.PushCookie(ply, token)
	if not IsValid(ply) then return end
	ply.mAC_token = token
	net.Start("mac_k")
		net.WriteString(token)
	net.Send(ply)
end
