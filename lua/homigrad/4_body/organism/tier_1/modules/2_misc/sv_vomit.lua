util.AddNetworkString("vomit_squirt")

local bon = "ValveBiped.Bip01_Head1"

local function vomitSquirt(ent, org)
	if not IsValid(ent) then return end

	local bone = ent:LookupBone(bon)
	local mat = bone and ent:GetBoneMatrix(bone)
	if not mat then return end

	net.Start("vomit_squirt")
	hg.orgSquirtSend(ent, bon, mat,
		mat:GetTranslation() + mat:GetAngles():Right() * 6 + mat:GetAngles():Forward() * 1,
		mat:GetAngles():Right() * 2 * math.Clamp((org and org.pulse or 70) / 70, 0.4, 1))
	net.Broadcast()
end

function hg.organism.VomitFluid(owner, snd)
	if not hg.IsValidPlayer(owner) then return end

	local org = owner.organism
	local ent = hg.GetCurrentCharacter(owner)
	local bone = ent:LookupBone(bon)
	local mat = bone and ent:GetBoneMatrix(bone)
	if not mat then return end

	local on_spine = mat:GetAngles():Right()[3] > 0.25

	owner:SetNetVar("vomiting", CurTime() + 1.5)

	ent:EmitSound(snd or "zcitysnd/real_sonar/" .. (ThatPlyIsFemale(ent) and "female" or "male") .. "_cough" .. math.random(4) .. ".mp3")
	if not on_spine then ent:EmitSound("vomit/vomit5.mp3") end

	if owner.armors and owner.armors.face and hg.armor.face[owner.armors.face].voice_change then
		owner:SetNetVar("zableval_masku", true)
	elseif not on_spine then
		vomitSquirt(ent, org)
	end
end
