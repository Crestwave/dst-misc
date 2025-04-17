AddClassPostConstruct("widgets/redux/balatrowidget", function(self)
	local _OnUpdate = self.OnUpdate
	-- Process a queue item on every single frame instead of waiting for the delay.
	self.OnUpdate = function(...)
		if #self.queue > 0 then
			if self.queue[1].time >= 0 then
				self.queue[1].time = 0
			end
		end

		_OnUpdate(...)
	end

	local _TryToCloseWithAnimations = self.parentscreen.TryToCloseWithAnimations
	self.parentscreen.TryToCloseWithAnimations = function(...)
		if self.root.machine:GetAnimState():IsCurrentAnimation("confetti") then
			-- Delay the closing by a second so the player can admire their score!
			-- Players in a rush can still instantly close the screen if they
			-- click the Back button before the confetti animation.
			self.inst:DoTaskInTime(1, function(...)
				_TryToCloseWithAnimations(...)
			end)
		else
			_TryToCloseWithAnimations(...)
		end
	end
end)
