local _G = GLOBAL
local waxwelljournalkey = _G["KEY_"..GetModConfigData("waxwelljournalkey")]
local tophatkey = _G["KEY_"..GetModConfigData("tophatkey")]

local function IsDefaultScreen()
	return _G.ThePlayer ~= nil
		and _G.ThePlayer.components.playercontroller:IsEnabled()
		and _G.TheFrontEnd:GetActiveScreen().name == "HUD"
end

local function GetItem(prefab, tag)
	local items = _G.ThePlayer.replica.inventory:GetItems()
	local containers = _G.ThePlayer.replica.inventory:GetOpenContainers()

	for k, v in pairs(_G.EQUIPSLOTS) do
		table.insert(items, _G.ThePlayer.replica.inventory:GetEquippedItem(v))
	end

	for k, v in pairs(containers) do
		_G.ConcatArrays(items, k.replica.container:GetItems())
	end

	for k, v in pairs(items) do
		if v.prefab == prefab and (tag == nil or v:HasTag(tag)) then
			return v
		end
	end
end

_G.TheInput:AddKeyDownHandler(waxwelljournalkey, function()
	if IsDefaultScreen() then
		-- TODO: Automatically refuel when empty
		-- TODO: Add keybinds for picking spells
		if _G.ThePlayer.HUD ~= nil and _G.ThePlayer.HUD:GetCurrentOpenSpellBook() ~= nil then
			_G.ThePlayer.HUD:CloseSpellWheel()
		else
			local item = GetItem("waxwelljournal")

			if item ~= nil then
				if item.replica.inventoryitem.classified.percentused:value() == 0 then
					local fuel = GetItem("nightmarefuel")

					if fuel ~= nil then
						_G.ThePlayer.replica.inventory:ControllerUseItemOnItemFromInvTile(item, fuel)
					else
						_G.ThePlayer.replica.inventory:InspectItemFromInvTile(item)
					end
				else
					for k, v in pairs(_G.ThePlayer.components.playeractionpicker:GetInventoryActions(item)) do
						if v.action == _G.ACTIONS.USESPELLBOOK then
							_G.ThePlayer.replica.inventory:UseItemFromInvTile(item)
							item.components.spellbook:OpenSpellBook(_G.ThePlayer)
						end
					end
				end
			end
		end
	end
end)

_G.TheInput:AddKeyDownHandler(tophatkey, function()
	if IsDefaultScreen() then
		if _G.ThePlayer:HasTag("usingmagiciantool") then
			local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
			_G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.STOPUSINGMAGICTOOL.code, x, z, _G.ThePlayer)
		else
			local item = GetItem("tophat", "magiciantool")

			if item ~= nil  then
				_G.ThePlayer.replica.inventory:UseItemFromInvTile(item)
			end
		end
	end
end)
