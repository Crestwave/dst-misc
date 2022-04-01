local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local BloomBadge = Class(Badge, function(self, owner, combined_status)
	self.owner = owner
	self.combined_status = combined_status or false
	self.max = 0
	self.rate = nil
	self.val = 0

	Badge._ctor(self, nil, owner, { 0 / 255, 127 / 255, 0 / 255, 1 })

	self.backing = self:AddChild(UIAnim())
	self.backing:GetAnimState():SetBank("status_meter")
	self.backing:GetAnimState():SetBuild("status_wet")
	self.backing:GetAnimState():Hide("frame")
	self.backing:GetAnimState():Hide("icon")
	self.backing:GetAnimState():AnimateWhilePaused(false)
	self.backing:SetClickable(true)

	self.anim = self:AddChild(UIAnim())
	self.anim:GetAnimState():SetBank("status_meter")
	self.anim:GetAnimState():SetBuild("status_meter")
	self.anim:Hide("icon")
	self.anim:GetAnimState():AnimateWhilePaused(false)
	self.anim:GetAnimState():SetMultColour(0 / 255, 127 / 255, 0 / 255, 1)
	self.anim:SetClickable(true)

	self.circleframe = self:AddChild(UIAnim())
	self.circleframe:GetAnimState():SetBank("status_meter")
	self.circleframe:GetAnimState():SetBuild("status_meter")
	self.circleframe:GetAnimState():Hide("bg")
	self.circleframe:GetAnimState():AnimateWhilePaused(false)
	self.circleframe:SetClickable(true)

	self.head_anim = self:AddChild(UIAnim())
	self.head_animstate = self.head_anim:GetAnimState()

	self.head_anim:SetScale(.15)
	self.head_anim:SetPosition(0, -35)
	self.head_anim:SetClickable(false)

	self.anim:Show()
	self.backing:GetAnimState():PlayAnimation("open")
	self.circleframe:GetAnimState():PlayAnimation("open")
	self.circleframe:MoveToFront()

	if self.combined_status then
		self.bg:MoveToFront()
		self.num:MoveToFront()
	end
end)

function BloomBadge:SetPercent(val, max, rate, is_blooming)
	if is_blooming then
		val = max - val
	end

	self.val = val
	self.max = max

	self.anim:GetAnimState():SetPercent("anim", 1 - val / max)
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
	local client = TheNet:GetClientTableForUser(TheNet:GetUserID())
	if not self.head_anim or not self.head_animstate or not client then return end

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
