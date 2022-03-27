local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local BloomBadge = Class(Badge, function(self, owner)
	self.owner = owner
	self.combined_status = false
	self.rate = nil

	Badge._ctor(self, nil, owner, { 174 / 255, 21 / 255, 21 / 255, 1 }, "status_health", nil, nil, true)

	self.head_anim = self:AddChild(UIAnim())
	self.head_animstate = self.head_anim:GetAnimState()

	self.head_anim:SetScale(.15)
	self.head_anim:SetPosition(0, -35)
	self.head_anim:SetClickable(false)
end)

function BloomBadge:SetPercent(val, max, rate, is_blooming)
	if is_blooming then
		val = max - val
	end

	Badge.SetPercent(self, (val / max), max)

	if self.combined_status then
		self.num:SetString(string.format("%d", val))
		if self.rate ~= nil and rate ~= nil then
			self.rate:SetString(string.format("%.2f", rate))
		end
	elseif rate ~= nil then
		self.num:SetString(string.format("%d\nx%.2f", val, rate))
	else
		self.num:SetString(string.format("%d", val))
	end
end

function BloomBadge:Update()
	if not self.head_anim or not self.head_animstate then return end

	local client = TheNet:GetClientTableForUser(TheNet:GetUserID())
	local state = client.userflags
	local bank, animation, skin_mode, scale, y_offset = GetPlayerBadgeData( client.prefab, false, state == USERFLAGS.CHARACTER_STATE_1, state == USERFLAGS.CHARACTER_STATE_2, state == USERFLAGS.CHARACTER_STATE_3)

	self.head_animstate:SetBank(bank)
	self.head_animstate:PlayAnimation(animation, true)
	self.head_animstate:SetTime(0)
	self.head_animstate:Pause()

	local skindata = GetSkinData(client.base_skin or client.prefab.."_none")
	local base_build = client.prefab

	if skindata.skins ~= nil then
		base_build = skindata.skins[skin_mode]
	end

	SetSkinsOnAnim(self.head_animstate, client.prefab, base_build, {}, skin_mode)

	if self.maxnum then
		self.maxnum:MoveToFront()
	else
		self.num:MoveToFront()
	end
end

return BloomBadge
