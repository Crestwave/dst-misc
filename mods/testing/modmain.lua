local _G = GLOBAL
local UpvalueHacker = require("tools/upvaluehacker")
_G.battlesongs = {}

-- Remove name obfuscation for Wagstaff tools
for i=1,5 do
	AddPrefabPostInit("wagstaff_tool_" ..i, function(inst)
		inst.displaynamefn = nil
	end)
end

-- Remove name obfuscation for hiding worms
AddPrefabPostInit("worm", function(inst)
	inst.displaynamefn = function(inst)
		return _G.STRINGS.NAMES[(inst:HasTag("dirt") and "WORM_DIRT") or "WORM"]
	end
end)

-- Remove name obfuscation for hiding carrats
AddPrefabPostInit("carrat_planted", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:SetPrefabNameOverride("CARRAT")
	end)
end)

-- Remove name obfuscation for mutating hounds
AddPrefabPostInit("houndcorpse", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:SetPrefabNameOverride("MUTATEDHOUND")
	end)
end)

-- Remove name obfuscation for ornery chests
AddPrefabPostInit("chest_mimic", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:SetPrefabNameOverride("chest_mimic_revealed")
	end)
end)

-- Mark buried moon altars
for i=1,2 do
	AddPrefabPostInit("moon_altar_astral_marker_"..i, function(inst)
		inst:DoTaskInTime(0, function(inst)
			local x, y, z = inst.Transform:GetWorldPosition()
			local mark = _G.SpawnPrefab(inst.product)
			mark.Transform:SetPosition(x, y, z)
			mark.AnimState:SetMultColour(1, 1, 1, .5)
			mark:AddTag("NOBLOCK")
			_G.RemovePhysicsColliders(mark)
			inst:ListenForEvent("onremove", function(inst)
				mark:Remove()
			end)
		end)
	end)
end

-- Show Pipspook lost toys
for i in ipairs({ 1, 2, 7, 10, 11, 14, 18, 19, 42, 43}) do
	AddPrefabPostInit("lost_toy_"..i, function(inst)
		inst:DoTaskInTime(1, function(inst)
			inst.AnimState:SetMultColour(1, 1, 1, 1)
		end)
	end)
end

-- Light boats directly on fire
AddPrefabPostInit("burnable_locator_medium", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:RemoveTag("NOCLICK")
	end)
end)

-- Attack Rictus directly
AddPrefabPostInit("shadowthrall_mouth", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst.CanMouseThrough = function()
			return false, true
		end
	end)
end)

-- Prevent WINbot pickup
AddPrefabPostInit("winona_storage_robot", function(inst)
	inst:DoTaskInTime(0, function(inst)
		if not _G.ThePlayer:HasTag("handyperson") then
			inst:AddTag("NOCLICK")
		end
	end)
end)

-- Hide waterlogged biome god rays
AddPrefabPostInit("lightrays_canopy", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:Hide()
		inst:ListenForEvent("raysdirty", function(inst)
			inst:Hide()
		end)
	end)
end)

-- Hide waterlogged biome decor vines
AddPrefabPostInit("oceanvine_deco", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:Hide()
	end)
end)

-- Merm fluency
local prefabs = { "merm", "mermguard", "merm_lunar", "mermguard_lunar", "merm_shadow", "mermguard_shadow" }

for i, prefab in ipairs(prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		inst:DoTaskInTime(0, function(inst)
			inst.components.talker.resolvechatterfn = function(inst, strid, strtbl)
				-- prefabs/merm.lua, ResolveMermChatter()
				local stringtable = _G.STRINGS[strtbl:value()]
				if stringtable then
					if stringtable[strid:value()] ~= nil then
						return stringtable[strid:value()][1] -- First value is always the translated one
					end
				end
			end
		end)
	end)
end

-- Hungry/starving adjectives for critters
local prefabs = { "critter_lamb", "critter_puppy", "critter_kitten", "critter_perdling", "critter_dragonling", "critter_glomling", "critter_lunarmothling", "critter_eyeofterror" }

for i, prefab in ipairs(prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		inst.displayadjectivefn = function(self)
			local STRINGS = _G.STRINGS
			for k,_ in pairs(TUNING.CRITTER_TRAITS) do
				if self:HasTag("trait_"..k) then
					return ((self:HasTag("stale") and STRINGS.UI.HUD.HUNGRY.." "..STRINGS.UI.HUD.CRITTER_TRAITS[k]) or
						(self:HasTag("spoiled") and STRINGS.UI.HUD.STARVING.." "..STRINGS.UI.HUD.CRITTER_TRAITS[k]))
						or STRINGS.UI.HUD.CRITTER_TRAITS[k]
				else
					return ((self:HasTag("stale") and STRINGS.UI.HUD.HUNGRY) or
						(self:HasTag("spoiled") and STRINGS.UI.HUD.STARVING))
						or nil
				end
			end
		end
	end)
end

-- Prevent screen blackouts and inventory hiding
AddPrefabPostInit("world", function(inst)
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function(inst) if inst.fadetime:value() <= 0 then inst:DoTaskInTime(1, GLOBAL.TheCamera:Snap()) end end, "RegisterNetListeners", "RegisterNetListeners_common", "OnPlayerFadeDirty")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "RegisterNetListeners_local", "OnPlayerHUDDirty")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "RegisterNetListeners_common", "OnPlayerCameraSnap")

	_DoRecipeClick = GLOBAL.DoRecipeClick
	GLOBAL.DoRecipeClick = function(owner, recipe, skin)
		if recipe ~= nil and owner ~= nil and owner.replica.builder ~= nil then
			if recipe.placer == nil and owner:HasTag("busy") then
				owner.replica.builder:MakeRecipeFromMenu(recipe, skin)
				return true
			else
				return _DoRecipeClick(owner, recipe, skin)
			end
		end
	end
end)

AddClassPostConstruct("widgets/controls", function(self)
	self._HideCraftingAndInventory = self.HideCraftingAndInventory
	self.HideCraftingAndInventory = function() end
end)

-- Disable lazy explorer telepoofs unless CONTROL_FORCE_STACK is held
local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(_G.EntityScript.CollectActions, "COMPONENT_ACTIONS")
local _blinkstaff = COMPONENT_ACTIONS.POINT.blinkstaff
COMPONENT_ACTIONS.POINT.blinkstaff = function(inst, doer, ...)
	if doer.components.playercontroller ~= nil and doer.components.playercontroller:IsControlPressed(_G.CONTROL_FORCE_STACK) then
		return _blinkstaff(inst, doer, ...)
	end
end

-- WX-78 speech
AddPrefabPostInit("wx78", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst.components.talker.mod_str_fn = nil
	end)
end)

-- Unlock full skill tree
AddComponentPostInit("skilltreeupdater", function(self, inst)
	_G.TheInventory:SetGenericKVValue("fuelweaver_killed", "1")
	_G.TheInventory:SetGenericKVValue("celestialchampion_killed", "1")
	_G.TheGenericKV:SetKV("wathgrithr_instantsong_uses", "10")
	_G.TheGenericKV:SetKV("wathgrithr_container_unlocked", "1")
	_G.TheGenericKV:SetKV("wathgrithr_horn_played", "1")
	inst:DoTaskInTime(1, function(inst)
		if inst ~= _G.ThePlayer then return end
		self.skilltree:AddSkillXP(160, _G.ThePlayer.prefab)
	end)
end)

AddClassPostConstruct("widgets/skilltreetoast", function(self) self:Hide() end)

-- Sanity rate calculator
-- Estimates your sanity rate after passively losing or gaining sanity.
AddClassPostConstruct("components/sanity_replica", function(self)
	self.inst:ListenForEvent("sanitydelta", function(inst, data)
		if data.overtime then
			local delta = (data.newpercent - data.oldpercent) * self:Max()
			local time = 60 / (_G.GetTime() - (self.lastdeltatime or 0))
			print("SANITY RATE: " .. tostring(delta * time))
			self.lastdeltatime = _G.GetTime()
		end
	end)
end)

-- Unlock full scrapbook
AddPrefabPostInit("world", function(inst)
	_G.TheScrapbookPartitions:DebugSeenEverything()
	_G.TheScrapbookPartitions:DebugUnlockEverything()
end)

-- Mark Wagstaff scrap hints
AddPrefabPostInit("wagstaff_npc_wagpunk", function(inst)
	inst:DoTaskInTime(0, function(inst)
		local _Say = inst.components.talker.Say
		inst.components.talker.Say = function(self, script, ...)
			for k,v in pairs(_G.STRINGS.WAGSTAFF_GOTTOHINT) do
				if v == script then
					local x, y, z = inst.Transform:GetWorldPosition()
					local angle = inst.Transform:GetRotation()
					local mark = _G.SpawnPrefab("archive_resonator_base")
					mark.Transform:SetPosition(x, y, z)
					mark.AnimState:SetMultColour(0, 1, 1, 1)
					mark.Transform:SetRotation(angle - 90)
					print(string.format("Recorded Wagstaff hint at {%.2f,%.2f} (%.2f degrees)", x, z, angle))
					_G.ThePlayer.components.talker:Say(tostring(angle))
				end
			end

			return _Say(self, script, ...)
		end
	end)
end)

-- Detect active battlesong buffs
local song_defs = require("prefabs/battlesongdefs").song_defs
for k, v in pairs(song_defs) do
	if v.LOOP_FX ~= nil then
		AddPrefabPostInit(v.LOOP_FX, function(inst)
			inst:DoTaskInTime(0, function(inst)
				-- NOTE: if the player momentarily detaches then stays between the attach and detach radius while another Wigfrid song is within range,
				-- the song may still be listed as attached.
				if (_G.battlesongs[k] ~= nil and _G.ThePlayer:GetDistanceSqToInst(inst) <= (TUNING.BATTLESONG_DETACH_RADIUS * TUNING.BATTLESONG_DETACH_RADIUS)) or
					(_G.ThePlayer.player_classified.hasinspirationbuff:value() and _G.ThePlayer:GetDistanceSqToInst(inst) <= (TUNING.BATTLESONG_ATTACH_RADIUS ^ TUNING.BATTLESONG_ATTACH_RADIUS)) then
					local time = _G.GetTime()
					_G.battlesongs[k] = time

					_G.ThePlayer:DoTaskInTime(5, function(inst)
						if _G.battlesongs[k] == time then
							_G.battlesongs[k] = nil
						end
					end)
				end
			end)
		end)
	end
end

AddPlayerPostInit(function(player)
	player:DoTaskInTime(0, function(player)
		if player == _G.ThePlayer then
			player:ListenForEvent("hasinspirationbuff", function(inst, data)
				if not data.on then
					for k in pairs(_G.battlesongs) do
						_G.battlesongs[k] = nil
					end
				end
			end)
		end
	end)
end)

-- Multi-line support
AddClassPostConstruct("widgets/textedit", function(self)
	self.inst:DoTaskInTime(0, function(inst)
		local _OnTextEntered = self.OnTextEntered
		if _OnTextEntered ~= nil then
			self.OnTextEntered = function(...)
				if _G.TheInput:IsKeyDown(_G.KEY_ALT) then
					self:SetEditing(true)
					self.inst.TextEditWidget:OnTextInput("\n")
				else
					_OnTextEntered(...)
				end
			end
		end
	end)
end)

AddClassPostConstruct("widgets/writeablewidget", function(self)
	self.inst:DoTaskInTime(0, function(inst)
		local function onaccept(inst, doer, widget)
			if not widget.isopen then
				return
			end

			local msg = widget:GetText()
			widget.edit_text:SetString(msg)

			local writeable = inst.replica.writeable
			if writeable ~= nil then
				writeable:Write(doer, msg)
			end

			if widget.config.acceptbtn.cb ~= nil then
				widget.config.acceptbtn.cb(inst, doer, widget)
			end

			doer.HUD:CloseWriteableWidget()
		end

		local config = self.config
		self.menu.items[3].onclick = function() onaccept(self.writeable, self.owner, self) end
	end)
end)

-- Fade out blueprints that are already learned
AddPrefabPostInit("blueprint", function(inst)
	inst:DoTaskInTime(0, function(inst)
		name = inst.replica.named._name:value()
		name = string.sub(name, 1, #name - (#_G.STRINGS.NAMES.BLUEPRINT+1))

		for k, v in pairs(_G.STRINGS.NAMES) do
		        if v == name then
		                if _G.ThePlayer.replica.builder:KnowsRecipe(string.lower(k)) then
					inst.AnimState:SetMultColour(1, 1, 1, 1/3)
				end
		        end
		end
	end)
end)
