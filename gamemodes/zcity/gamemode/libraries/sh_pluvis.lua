if CLIENT then
	local fade = 0

	net.Receive("FadeScreen", function()
		local lply = LocalPlayer()
		if not IsValid(lply) or lply:Team() == TEAM_SPECTATOR then return end

		fade = 0
		timer.Simple(6, function()
			hook.Add("RenderScreenspaceEffects", "ZB_ScreenFade", function()
				surface.SetDrawColor(0, 0, 0, 255 * fade)
				surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
				fade = Lerp(FrameTime() * 10, fade, 2)
			end)
			timer.Simple(2, function()
				zb.RemoveFade()
			end)
		end)
	end)

	function zb.RemoveFade()
		hook.Remove("RenderScreenspaceEffects", "ZB_ScreenFade")
	end
end
