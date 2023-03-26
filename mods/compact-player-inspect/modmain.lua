local _G = GLOBAL

AddClassPostConstruct("screens/playerhud", function(self)
	local PlayerAvatarPopup = require "widgets/_playeravatarpopup"

	self._TogglePlayerInfoPopup = self.TogglePlayerInfoPopup
	self.TogglePlayerInfoPopup = function(self, player_name, data, show_net_profile, force)
		if (data.userid ~= nil and data.userid == self.owner.userid) or (data.inst ~= nil and data.inst:HasTag("dressable")) then
			return self:_TogglePlayerInfoPopup(player_name, data, show_net_profile, force)
		end

		if self.playeravatarpopup ~= nil and
			self.playeravatarpopup.started and
			self.playeravatarpopup.inst:IsValid() then
			self.playeravatarpopup:Close()
			if player_name == nil or
				data == nil or
				(data.userid ~= nil and self.playeravatarpopup.userid == data.userid) or --if we have a userid, test for that
				(data.userid == nil and self.playeravatarpopup.target == data.inst) then --if no userid, then compare inst
				self.playeravatarpopup = nil
				return
			end
		end

		if not force and _G.GetGameModeProperty("no_avatar_popup") then
			return
		end

		-- Don't show steam button for yourself or targets without a userid(skeletons)
		self.playeravatarpopup = self.controls.right_root:AddChild(
			PlayerAvatarPopup(self.owner, player_name, data, show_net_profile and data.userid ~= nil and data.userid ~= self.owner.userid)
		)
	end

	self._IsPlayerInfoPopupOpen = self.IsPlayerInfoPopupOpen
	self.IsPlayerInfoPopupOpen = function(...)
		return self:IsPlayerAvatarPopUpOpen() or self:_IsPlayerPopupOpen()
	end
end)
