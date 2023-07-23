local _G = GLOBAL
local UpvalueHacker = require("tools/upvaluehacker")

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

-- Light boats directly on fire
AddPrefabPostInit("burnable_locator_medium", function(inst)
	inst:DoTaskInTime(0, function(inst)
		inst:RemoveTag("NOCLICK")
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
local prefabs = { "merm", "mermguard" }

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
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function(inst) if inst.fadetime:value() <= 0 then inst:DoTaskInTime(1, GLOBAL.TheCamera:Snap()) end end, "RegisterNetListeners", "OnPlayerFadeDirty")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "OnPlayerHUDDirty")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "OnPlayerCameraSnap")

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

-- Activate Wilson skills
AddComponentPostInit("skilltreeupdater", function(self, inst)
	_G.TheInventory:SetGenericKVValue("fuelweaver_killed", "1")
	_G.TheInventory:SetGenericKVValue("celestialchampion_killed", "1")
	inst:DoTaskInTime(1, function(inst)
		if inst.prefab == "wilson" and inst == _G.ThePlayer then
			skills={"wilson_alchemy_1","wilson_alchemy_2","wilson_alchemy_3","wilson_alchemy_4","wilson_alchemy_5","wilson_alchemy_6","wilson_alchemy_7","wilson_alchemy_8","wilson_alchemy_9","wilson_alchemy_10","wilson_beard_4","wilson_beard_5","wilson_beard_6","wilson_beard_7","wilson_allegiance_shadow"}
			self.skilltree:AddSkillXP(160, "wilson")


			if self.skilltree.activatedskills.wilson ~= nil then
				for k, v in pairs(self.skilltree.activatedskills.wilson) do
					self:DeactivateSkill(k, "wilson")
				end
			end

			inst:DoTaskInTime(_G.FRAMES, function(inst)
				for i, skill in ipairs(skills) do
					self:ActivateSkill(skill, "wilson")
				end

				inst:PushEvent("unlockrecipe")

				inst:DoTaskInTime(_G.FRAMES, function(inst)
					for i, skill in ipairs(skills) do
						self:DeactivateSkill(skill, "wilson")
					end

					inst:DoTaskInTime(_G.FRAMES, function(inst)
						for i=1,7 do
							self:ActivateSkill("wilson_torch_"..i, "wilson")
							self:ActivateSkill("wilson_beard_"..i, "wilson")
						end

						self:ActivateSkill("wilson_allegiance_shadow", "wilson")
						inst:DoTaskInTime(1, function(inst) inst:PushEvent("unlockrecipe") end)
					end)
				end)
			end)
		end
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

-- Reset individual skills in-game
local ImageButton = require("widgets/imagebutton")

AddClassPostConstruct("widgets/redux/skilltreebuilder", function(self)
	self.inst:DoTaskInTime(0, function(inst)
		if _G.ThePlayer.userid == self.targetdata.userid then
			self.infopanel.respec_button:Show()
			self.infopanel.activatedtext = self.infopanel:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
			self.infopanel.activatedtext.image:SetScale(1)
			self.infopanel.activatedtext:SetFont(_G.CHATFONT)
			self.infopanel.activatedtext:SetPosition(0,-37)
			self.infopanel.activatedtext.text:SetColour(0,0,0,1)
			self.infopanel.activatedtext:SetScale(0.5)
			self.infopanel.activatedtext:SetText("Reset Skill")
			self.infopanel.activatedtext:SetOnClick(function()
				if self.selectedskill and _G.ThePlayer ~= nil and _G.ThePlayer.components.skilltreeupdater ~= nil then
					_G.ThePlayer.components.skilltreeupdater:DeactivateSkill(self.selectedskill, _G.ThePlayer.prefab)
					self:RefreshTree()
				end
			end)

			local _OnControl = self.skilltreewidget.OnControl
			self.skilltreewidget.OnControl = function(self, control, down, ...)
				if not down and not _G.TheInput:ControllerAttached() and control == _G.CONTROL_ACTION then
					local skilltree = self.root.tree

					if skilltree.selectedskill and skilltree.infopanel.activatedtext:IsVisible() then
						self.root.infopanel.activatedtext.onclick()
						return true
					end
				end

				return _OnControl(self, control, down, ...)
			end

			local _RefreshTree = self.RefreshTree
			self.RefreshTree = function(self, ...)
				_RefreshTree(self, ...)
				self.infopanel.respec_button:Show()
			end
		end
	end)
end)

-- Unlock full scrapbook
AddPrefabPostInit("world", function(inst)
	_G.TheScrapbookPartitions:DebugSeenEverything()
	_G.TheScrapbookPartitions:DebugUnlockEverything()
end)
