local Badge = require "widgets/badge"
local Image = require "widgets/image"

local BloomBadge = Class(Badge, function(self, owner, text_format)
    Badge._ctor(self, "charge_meter", owner)
	self.owner = owner
	
	--[[
	self.bg_stuck = self:AddChild(Image("images/charge_meter_stuck_bg.xml", "charge_meter_stuck_bg.tex"))
	self.bg_stuck:SetClickable(false)
	self.bg_stuck:MoveToBack()
	self.bg_stuck:Hide()
	--]]
	
	self.text_format = text_format
	self.day_format = string.find(self.text_format, "day")

	if self.day_format and TUNING.TOTAL_DAY_TIME < 60 * 10 then
		self.leading_zero = false
	else
		self.leading_zero = true
	end
end)

function BloomBadge:SetPercent(val, max, stuck, rate)
	local str = "0"
		
	--[[
	if stuck then
		if not self.bg_stuck.shown then
			self.bg_stuck:Show()
		end
	elseif self.bg_stuck.shown then
		self.bg_stuck:Hide()
	end
	--]]
	
	if max > 0 then
		Badge.SetPercent(self, (val / max), max)
		
		local days = "0"
		local minutes = "0"
		local seconds = "0"
		
		if stuck then
			if self.text_format == "second" then
				--str = ">60"
				str = val
			else
				str = ">1:00"
			end
		else
			if self.day_format then
				days = tostring(math.floor(val / TUNING.TOTAL_DAY_TIME))
				minutes = tostring(math.floor((val % TUNING.TOTAL_DAY_TIME) / 60))
				seconds = tostring(math.floor((val % TUNING.TOTAL_DAY_TIME) % 60))
			elseif self.text_format == "hour" then
				days = tostring(math.floor(val / 3600))
				minutes = tostring(math.floor((val % 3600) / 60))
				seconds = tostring(math.floor((val % 3600) % 60))
			elseif self.text_format == "minute" then
				minutes = tostring(math.floor(val / 60))
				seconds = tostring(math.floor(val % 60))
			else
				seconds = tostring(math.floor(val))
			end
			
			str = days
			
			if str ~= "0" then
				if string.len(minutes) < 2 and self.leading_zero then
					minutes = "0"..minutes
				end
				
				if self.text_format == "daydash" then
					str = str.."d-"..minutes
				else
					str = str..":"..minutes
				end
			else
				str = minutes
			end
			
			if str ~= "0" then
				if string.len(seconds) < 2 then
					seconds = "0"..seconds
				end
				
				str = str..":"..seconds
			else
				str = seconds
			end
		end
	else
		Badge.SetPercent(self, 0, max)
	end

	--[[
	if rate ~= nil then
		str = string.format("%s\nx%.2f", str, rate)
	end
	--]]
	
	--self.num:SetScale(1, .78, 1)
	--self.num:SetSize(25)
	--self.num:SetSize(23)
	self.num:SetString(str)
	if self.rate ~= nil and rate ~= nil then
		self.rate:SetString(string.format("%.2f", rate))
	end
end

return BloomBadge
