local _G = GLOBAL
local UIAnim = require "widgets/uianim"
local summonkey = _G["KEY_"..GetModConfigData("summonkey")]
local togglekey = _G["KEY_"..GetModConfigData("togglekey")]
local tiles = {}

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
					if not _G.TheWorld.ismastersim then
						return _G.TheNet:SendRPCToServer(_G.RPC.LeftClick, _G.ACTIONS.CASTAOE.code, pos.x, pos.z, nil, nil, nil, nil, nil, nil, false, item, k)
					else
						item.components.spellbook:SelectSpell(k)
						local buffaction = _G.BufferedAction(_G.ThePlayer, nil, _G.ACTIONS.CASTAOE, item, pos)
						return _G.ThePlayer.components.locomotor:PushAction(buffaction, true)
					end
				else
					item.components.spellbook:SelectSpell(k)
					return _G.ThePlayer.replica.inventory:CastSpellBookFromInv(item)
				end
			end
		end
	end

	return false
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
				--_G.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(item)
				-- the actual ControllerUseItemOnSelfFromInvTile function does not work when networked for some reason
				if not _G.TheWorld.ismastersim then
					_G.SendRPCToServer(_G.RPC.ControllerUseItemOnSelfFromInvTile, _G.ACTIONS.CASTSUMMON.code, item)
				else
					local buffaction = _G.BufferedAction(_G.ThePlayer, nil, _G.ACTIONS.CASTSUMMON, item)
					return _G.ThePlayer.components.locomotor:PushAction(buffaction, true)
				end
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
			local spell = _G.ThePlayer:HasTag("has_aggressive_follower") and _G.STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_DEFENSIVE or _G.STRINGS.ACTIONS.COMMUNEWITHSUMMONED.MAKE_AGGRESSIVE
			return CastSpell(spell, item)
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

		-- leave the frame out because I don't like it
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
	end
end)

local _stroverridefn = _G.ACTIONS.APPLYELIXIR.stroverridefn
_G.ACTIONS.APPLYELIXIR.stroverridefn = function(act, ...)
	if act.invobject then
		local doer = act.doer
		if doer.components.playercontroller ~= nil and doer.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_INSPECT) then
			local head = doer.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HEAD)
			-- disable for active item until a clean way can be found to do it
			if head ~= nil and head:HasTag("elixir_drinker") and act.invobject ~= doer.replica.inventory:GetActiveItem() then
				return _G.subfmt(_G.STRINGS.ACTIONS.GIVE.DRINK, {item = act.invobject:GetBasicDisplayName()})
			end
		end
	end

	return _stroverridefn(act, ...)
end

AddClassPostConstruct("components/inventory_replica", function(self, inst)
	local _UseItemFromInvTile = self.UseItemFromInvTile
	self.UseItemFromInvTile = function(self, item, ...)
		if item ~= nil and item:HasTag("ghostlyelixir") then
			if inst.components.playercontroller ~= nil and inst.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_INSPECT) then
				local head = self:GetEquippedItem(_G.EQUIPSLOTS.HEAD)
				if head ~= nil and head:HasTag("elixir_drinker") then
					return self:ControllerUseItemOnItemFromInvTile(head, item)
				end
			end
		end

		return _UseItemFromInvTile(self, item, ...)
	end
end)
