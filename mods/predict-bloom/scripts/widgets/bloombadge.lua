local Badge = require("widgets/badge")
local UIAnim = require("widgets/uianim")

local BloomBadge = Class(Badge, function(self, owner, combined_status)
	self.owner = owner
	self.combined_status = combined_status or false
	self.max = 0
	self.rate = nil
	self.val = 0

	Badge._ctor(self, nil, owner, { 0 / 255, 127 / 255, 0 / 255, 1 })

	self.backing:GetAnimState():SetBank("status_meter")
	self.backing:GetAnimState():SetBuild("status_meter")
	self.backing:GetAnimState():SetBuild("status_wet")
	self.backing:GetAnimState():Hide("icon")

	self.anim:GetAnimState():SetBank("status_meter")
	self.anim:GetAnimState():SetBuild("status_meter")

	self.circleframe:GetAnimState():SetBank("status_meter")
	self.circleframe:GetAnimState():SetBuild("status_meter")

	self.head_anim = self.underNumber:AddChild(UIAnim())
	self.head_animstate = self.head_anim:GetAnimState()

	self.head_anim:SetScale(.15)
	self.head_anim:SetPosition(0, -35)
	self.head_anim:SetClickable(false)

	self.bloomarrow = self.underNumber:AddChild(UIAnim())
	self.bloomarrow:GetAnimState():SetBank("sanity_arrow")
	self.bloomarrow:GetAnimState():SetBuild("sanity_arrow")
	self.bloomarrow:GetAnimState():PlayAnimation("neutral")
	self.bloomarrow:GetAnimState():AnimateWhilePaused(false)
	self.bloomarrow:SetClickable(false)

	self:UpdateIcon()
end)

local RATE_SCALE_ANIM =
{
    [RATE_SCALE.INCREASE_HIGH] = "arrow_loop_increase_most",
    [RATE_SCALE.INCREASE_MED] = "arrow_loop_increase_more",
    [RATE_SCALE.INCREASE_LOW] = "arrow_loop_increase",
    [RATE_SCALE.DECREASE_HIGH] = "arrow_loop_decrease_most",
    [RATE_SCALE.DECREASE_MED] = "arrow_loop_decrease_more",
    [RATE_SCALE.DECREASE_LOW] = "arrow_loop_decrease",
}

function BloomBadge:SetPercent(val, max, rate, is_blooming)
	if is_blooming then
		val = max - val
	end

	self.val = val
	self.max = max

	Badge.SetPercent(self, val / max, max)

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

	local ratescale = self.owner.components._bloomness:GetRateScale()
	local anim = RATE_SCALE_ANIM[ratescale]

	if self.arrowdir ~= anim then
		self.arrowdir = anim
		self.bloomarrow:GetAnimState():PlayAnimation(anim, true)
	end
end

function BloomBadge:UpdateIcon()
	local client = TheNet:GetClientTableForUser(TheNet:GetUserID())
	if not self.head_anim or not self.head_animstate or not client then return end

	local state = client.userflags
	local bank, animation, skin_mode, scale, y_offset = GetPlayerBadgeData(client.prefab, false, state == USERFLAGS.CHARACTER_STATE_1, state == USERFLAGS.CHARACTER_STATE_2, state == USERFLAGS.CHARACTER_STATE_3)

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
end

return BloomBadge
