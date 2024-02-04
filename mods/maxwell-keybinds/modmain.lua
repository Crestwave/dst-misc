local _G = GLOBAL
local waxwelljournalkey = _G["KEY_"..GetModConfigData("waxwelljournalkey")]
local tophatkey = _G["KEY_"..GetModConfigData("tophatkey")]
local refuelpercent = GetModConfigData("refuelpercent")

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

_G.TheInput:AddKeyDownHandler(waxwelljournalkey, function()
	if IsDefaultScreen() then
		if _G.ThePlayer.HUD ~= nil and _G.ThePlayer.HUD:GetCurrentOpenSpellBook() ~= nil and _G.ThePlayer.HUD:GetCurrentOpenSpellBook().prefab == "waxwelljournal" then
			_G.ThePlayer.HUD:CloseSpellWheel()
		else
			local item = GetItem("waxwelljournal")

			if item ~= nil then
				if item.replica.inventoryitem.classified.percentused:value() <= refuelpercent then
					local fuel = GetItem("nightmarefuel")

					if fuel ~= nil then
						_G.ThePlayer.replica.inventory:ControllerUseItemOnItemFromInvTile(item, fuel)
					else
						_G.ThePlayer.replica.inventory:InspectItemFromInvTile(item)
					end
				end

				item.components.spellbook:OpenSpellBook(_G.ThePlayer)
			end
		end
	end
end)

_G.TheInput:AddKeyDownHandler(tophatkey, function()
	if IsDefaultScreen() and _G.ThePlayer:HasTag("magician") then
		if _G.ThePlayer:HasTag("usingmagiciantool") then
			local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
			_G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.STOPUSINGMAGICTOOL.code, x, z, _G.ThePlayer)
		else
			local item = GetItem("tophat", "magiciantool")

			if item ~= nil then
				_G.SendRPCToServer(_G.RPC.UseItemFromInvTile, _G.ACTIONS.USEMAGICTOOL.code, item, 1, nil)
			end
		end
	end
end)
