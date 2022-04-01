local _Bloomness = Class(function(self, inst)
	self.inst = inst
	self.max = 3
	self.level = 0
	self.is_blooming = false
	self.onlevelchangedfn = nil

	self.timer = 0
	self.stage_duration = 0
	self.full_bloom_duration = 0

	self.rate = 1
	self.fertilizer = 0
	self._fertilizer = 0
end)

function _Bloomness:SetLevel(level)
	level = math.min(level, self.max)
	if self.level == level then
		return
	end

	self.fertilizer = 0

	if level == 0 then
		self.level = 0
		self.is_blooming = false
		self:DoDelta(-self.timer)
		self:UpdateRate()
		self.inst:StopUpdatingComponent(self)
	else
		local prev_level = self.level

		self.is_blooming = level ~= self.max and level > self.level
		self.level = level

		if level == self.max then
			self.timer = self.full_bloom_duration
		else
			self.timer = self.stage_duration
		end

		if self._fertilizer > 0 then
			self.fertilizer = self._fertilizer
			self._fertilizer = 0
		end

		self:UpdateRate()

		if prev_level == 0 then
			self.inst:StartUpdatingComponent(self)
		end
	end
	self.onlevelchangedfn(self.inst, level)
end

function _Bloomness:SetDurations(stage, full)
	self.stage_duration = stage
	self.full_bloom_duration = full
end

function _Bloomness:GetLevel()
	return self.level
end

function _Bloomness:UpdateRate()
	if self.level > 0 then
		self.rate = self.calcratefn ~= nil and self.calcratefn(self.inst, self.level, self.is_blooming, self.fertilizer) or 1
	end
end

function _Bloomness:Fertilize(value)
	value = value or 0

	if self.level == self.max then
		self:DoDelta((self.calcfullbloomdurationfn ~= nil and self.calcfullbloomdurationfn(self.inst, value, self.timer, self.full_bloom_duration) or self.timer) - self.timer)
		self:UpdateRate()
	else
		if not self.is_blooming then
			self.is_blooming = true
			self.timer = self.stage_duration
		end

		self.fertilizer = self.fertilizer + value
		self:UpdateRate()

		if self.level == 0 then
			self.inst:StartUpdatingComponent(self)
			self._fertilizer = self.fertilizer
		end
	end
end

function _Bloomness:OnUpdate(dt)
	self:DoDelta(-dt * self.rate)
end

function _Bloomness:LongUpdate(dt)
	if self.timer ~= 0 then
		self:OnUpdate(dt)
	end
end

function _Bloomness:Save()
	return self.level > 0 and {
		level = self.level,
		timer = self.timer,
		rate = self.rate,
		is_blooming = self.is_blooming,
		fertilizer = self.fertilizer,
	} or nil
end

function _Bloomness:Load(data)
	if data ~= nil then
		self.timer = data.timer or 0
		self.rate = data.rate or 1
		self.is_blooming = data.is_blooming or false
		self.fertilizer = data.fertilizer or 0
		self.level = data.level or 0

		if self.level > 0 then
			self.inst:StartUpdatingComponent(self)
			self.onlevelchangedfn(self.inst, self.level)
		else
			self.inst:StopUpdatingComponent(self)
		end
	end
end

function _Bloomness:DoDelta(amount)
	local oldval = self.timer
	local max_timer = self.level == self.max and TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION or self.stage_duration
	self.timer = self.timer + amount
	self.inst:PushEvent("bloomdelta", { oldval = oldval, newval = self.timer, max = max_timer, rate = self.rate, is_blooming = self.is_blooming, level = self.level })
end

function _Bloomness:GetDebugString()
	return string.format("L: %d, B: %s, T: %0.2f (x%0.2f)", self.level, tostring(self.is_blooming), self.timer, self.rate)
end

return _Bloomness
