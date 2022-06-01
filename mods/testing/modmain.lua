local _G = GLOBAL

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
			mark.AnimState:SetMultColour(1, 1, 1, .1)
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

AddPrefabPostInit("world", function(inst)
	local UpvalueHacker = GLOBAL.require("tools/upvaluehacker")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "OnPlayerFadeDirty")
	UpvalueHacker.SetUpvalue(GLOBAL.Prefabs.player_classified.fn, function() end, "RegisterNetListeners", "OnPlayerHUDDirty")

	_DoRecipeClick = GLOBAL.DoRecipeClick
	GLOBAL.DoRecipeClick = function(owner, recipe, skin)
		if recipe ~= nil and owner ~= nil and owner.replica.builder ~= nil then
			if owner:HasTag("busy") then
				owner.replica.builder:MakeRecipeFromMenu(recipe, skin)
			else
				_DoRecipeClick(owner, recipe, skin)
			end
		end
	end
end)
