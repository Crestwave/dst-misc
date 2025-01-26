local _G = GLOBAL
local summonkey = _G["KEY_"..GetModConfigData("summonkey")]
local togglekey = _G["KEY_"..GetModConfigData("togglekey")]

local UIAnim = require "widgets/uianim"
local tiles = {}

-- debug
_G.itemtile = nil
_G.itemtiles = {}

local function IsDefaultScreen()
	return _G.ThePlayer ~= nil
		and _G.ThePlayer.components.playercontroller:IsEnabled()
		and _G.TheFrontEnd:GetActiveScreen().name == "HUD"
end

local function CastSpell(label, item, pos)
	if item.components.spellbook ~= nil then
		for k, v in pairs(item.components.spellbook.items) do
			if v.label == label then
				if pos ~= nil then
					_G.TheNet:SendRPCToServer(_G.RPC.LeftClick, _G.ACTIONS.CASTAOE.code, pos.x, pos.z, nil, nil, nil, nil, nil, nil, false, item, k)
					return true
				else
					item.components.spellbook:SelectSpell(k)
					item.components.spellbook:SetSpellName(v.label)
					item.components.spellbook:SetSpellFn(v.execute)
					item.components.spellbook:CastSpell(_G.ThePlayer)
					return false
				end
			end
		end
	end
end

local function GetItem(prefab, tag)
	local items = _G.ThePlayer.replica.inventory:GetItems()
	local containers = _G.ThePlayer.replica.inventory:GetOpenContainers()

	for k, v in pairs(_G.EQUIPSLOTS) do
		table.insert(items, _G.ThePlayer.replica.inventory:GetEquippedItem(v))
	end

	for k, v in pairs(containers) do
		for k, v in pairs(k.replica.container:GetItems()) do
			table.insert(items, v)
		end
	end

	for k, v in pairs(items) do
		if v.prefab == prefab and (tag == nil or v:HasTag(tag)) then
			return v
		end
	end
end

_G.TheInput:AddKeyDownHandler(summonkey, function()
	if IsDefaultScreen() and _G.ThePlayer:HasTag("ghostlyfriend") then
		local item = GetItem("abigail_flower")

		if item ~= nil then
			if not _G.ThePlayer:HasTag("ghostfriend_summoned") then
				_G.SendRPCToServer(_G.RPC.ControllerUseItemOnSelfFromInvTile, _G.ACTIONS.CASTSUMMON.code, item)
			else
				CastSpell(_G.STRINGS.GHOSTCOMMANDS.UNSUMMON, item)
			end
		end
	end
end)

_G.TheInput:AddKeyDownHandler(togglekey, function()
	if IsDefaultScreen() and _G.ThePlayer:HasTag("ghostfriend_summoned") then
		local item = GetItem("abigail_flower")

		if item ~= nil then
			return CastSpell(_G.STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_AGGRESSIVE, item) or CastSpell(_G.STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_DEFENSIVE, item)
		end
	end
end)

_G.TheInput:AddMouseButtonHandler(function(button, down)
	if IsDefaultScreen() and _G.ThePlayer:HasTag("ghostfriend_summoned") and down and _G.TheInput:GetHUDEntityUnderMouse() == nil then
		if _G.ThePlayer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand") ~= nil then return end

		local item = GetItem("abigail_flower")

		if item ~= nil then
			local ent = _G.TheInput:GetWorldEntityUnderMouse()
			if ent ~= nil and not _G.TheInput:IsControlPressed(_G.CONTROL_FORCE_ATTACK) then
				if button == _G.MOUSEBUTTON_MIDDLE then
					if ent.prefab == "abigail" and ent.replica.follower:GetLeader() == _G.ThePlayer then
						CastSpell(_G.STRINGS.GHOSTCOMMANDS.SCARE, item)
					else
						CastSpell(_G.STRINGS.GHOSTCOMMANDS.HAUNT_AT, item, ent:GetPosition())
					end
				elseif button == _G.MOUSEBUTTON_RIGHT then
					if ent.prefab == "abigail" and ent.replica.follower:GetLeader() == _G.ThePlayer then
						CastSpell(_G.STRINGS.GHOSTCOMMANDS.ESCAPE, item)
					end
				end
			else
				if button == _G.MOUSEBUTTON_MIDDLE then
					CastSpell(_G.STRINGS.GHOSTCOMMANDS.ATTACK_AT, item, _G.TheInput:GetWorldPosition())
				end
			end
		end
	end
end)

AddPrefabPostInit("spellbookcooldown", function(inst)
	if _G.ThePlayer:HasTag("ghostlyfriend") then
		for k, v in ipairs(tiles) do
			v:SetChargePercent(0)
		end

		inst:ListenForEvent("pctdirty", function(inst)
			local pct = 1 - inst:GetPercent()
			for k, v in ipairs(tiles) do
				if v.inst:IsValid() then
					-- sync only on >0.01 variance to prevent micro stutters
					if math.abs(pct - v.rechargepct) > 0.01 then
						print(pct .." VS ".. v.rechargepct)
						v:SetChargePercent(1 - inst:GetPercent())
					end
				else
					table.remove(tiles, k)
				end
			end
		end)
	end
		
	-- this method is left unused for optimization
	-- it may be useful if spell-specific cooldowns are implemented
	--inst:DoTaskInTime(0, function(inst)
	--	if inst:GetSpellName() == _G.hash("ghostcommand") then
	--		_G.itemtile:SetChargePercent(1 - inst:GetPercent())
	--		_G.itemtile:SetChargeTime(inst:GetLength())
	--	end
	--end)
end)

AddClassPostConstruct("widgets/itemtile", function(self, invitem)
	if invitem.prefab == "abigail_flower" and _G.ThePlayer:HasTag("ghostlyfriend") then
		-- hard-code spell cooldown for optimization
		self.rechargepct = 1
		self.rechargetime = TUNING.WENDYSKILL_COMMAND_COOLDOWN
		self.rechargeframe = self:AddChild(UIAnim())

		-- remove the frame because I don't like it
		--self.rechargeframe:GetAnimState():SetBank("recharge_meter")
		--self.rechargeframe:GetAnimState():SetBuild("recharge_meter")
		--self.rechargeframe:GetAnimState():PlayAnimation("frame")
		--self.rechargeframe:GetAnimState():AnimateWhilePaused(false)
		
		self.recharge = self:AddChild(UIAnim())
		self.recharge:GetAnimState():SetBank("recharge_meter")
		self.recharge:GetAnimState():SetBuild("recharge_meter")
		self.recharge:GetAnimState():SetMultColour(0, 0, 0.4, 0.64) -- 'Cooldown until' with BLUE colour.
		self.recharge:GetAnimState():AnimateWhilePaused(false)
		self.recharge:SetClickable(false)

		self:SetChargePercent(1 - (_G.ThePlayer.components.spellbookcooldowns:GetSpellCooldownPercent("ghostcommand") or 0))

		-- maintain a list of tiles
		table.insert(tiles, self)

		-- debug
		_G.itemtile = self
		_G.itemtiles = tiles
	end
end)
