local _G = GLOBAL
local AutoSaveManager = require("autosavemanager")
local BloomSaver

local function CalcBloomRateFn(inst, level, is_blooming, fertilizer)
	local season_mult = 1
	if _G.TheWorld.state.season == "spring" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_SPRING_BLOOM_MOD
		else
			return TUNING.WORMWOOD_SPRING_BLOOMDRAIN_RATE
		end
	elseif _G.TheWorld.state.season == "winter" then
		if is_blooming then
			season_mult = TUNING.WORMWOOD_WINTER_BLOOM_MOD
		else
			return TUNING.WORMWOOD_WINTER_BLOOMDRAIN_RATE
		end
	end

	local rate = (is_blooming and fertilizer > 0) and (season_mult * (1 + fertilizer * TUNING.WORMWOOD_FERTILIZER_RATE_MOD)) or 1
	return rate
end

local function CalcFullBloomDurationFn(inst, value, remaining, full_bloom_duration)
	value = value * TUNING.WORMWOOD_FERTILIZER_BLOOM_TIME_MOD

	return math.min(remaining + value, TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION)
end

local function OnSeasonChange(inst, season)
	if season == "spring" and not inst:HasTag("playerghost") then
		inst.components._bloomness:Fertilize()
	else
		inst.components._bloomness:UpdateRate()
	end
end

local function UpdateBloomStage(inst, stage)
	print("Stage: " .. tostring(stage or inst.components._bloomness:GetLevel()))
end

local function SyncBloomStage(inst, force)
	local mult = inst.player_classified.runspeed:value() / TUNING.WILSON_RUN_SPEED
	local stage = _G.RoundBiasedUp(_G.Remap(mult, 1, 1.2, 0, 3))
	local level = inst.components._bloomness:GetLevel()
	if stage ~= level or force then
		--local timer = inst.components._bloomness.timer
		inst.components._bloomness:SetLevel(stage)
		--inst.components._bloomness.timer = inst.components._bloomness.timer - timer
		if _G.TheWorld.state.isspring then
			inst.components._bloomness:Fertilize()
		end
	else
		inst.components._bloomness:UpdateRate()
	end
end

local function OnBloomFXDirty(inst)
	inst:DoTaskInTime(1, SyncBloomStage, true)
		--inst.components._bloomness:SetLevel(_G.RoundBiasedUp(_G.Remap(inst.player_classified.runspeed:value() / TUNING.WILSON_RUN_SPEED, 1, 1.2, 0, 3)))
end

local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
local act = false
local active = false
local fert = nil
local _SendRPCToServer = _G.SendRPCToServer
_G.SendRPCToServer = function(...)
	arg = { ... }

	if arg[2] == _G.ACTIONS.FERTILIZE.code and not _G.ThePlayer:HasTag("busy") then
		act = true

		if arg[1] == _G.RPC.LeftClick then
			active = true
			fert = _G.ThePlayer.replica.inventory:GetActiveItem()
		elseif arg[1] == _G.RPC.UseItemFromInvTile then
			fert = arg[3]
		else
			act = false
		end
	elseif act then
		if arg[1] == _G.RPC.InspectItemFromInvTile then
			act = false
		elseif arg[1] == _G.RPC.ClearActionHold then
			active = false
		elseif not active and not _G.ThePlayer:HasTag("busy") then
			act = false
		end
	end

	_SendRPCToServer(...)
end

AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function(inst)
		if inst == _G.ThePlayer and inst:HasTag("self_fertilizable") and inst.player_classified ~= nil then
			inst:AddComponent("_bloomness")
			inst.components._bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, TUNING.WORMWOOD_BLOOM_FULL_DURATION)
			inst.components._bloomness.onlevelchangedfn = UpdateBloomStage
			inst.components._bloomness.calcratefn = CalcBloomRateFn
			inst.components._bloomness.calcfullbloomdurationfn = CalcFullBloomDurationFn
			inst:ListenForEvent("bloomfxdirty", OnBloomFXDirty)
			inst:WatchWorldState("season", OnSeasonChange)

			BloomSaver = AutoSaveManager("bloomness", inst.components._bloomness.Save, inst.components._bloomness)
			BloomSaver:StartAutoSave()
			inst.components._bloomness:Load(BloomSaver:LoadData())
			SyncBloomStage(inst)

			inst.player_classified:ListenForEvent("isghostmodedirty", function(inst)
				if inst.isghostmode:value() then
					_G.ThePlayer.components._bloomness:SetLevel(0)
				elseif _G.TheWorld.state.isspring then
					_G.ThePlayer.components._bloomness:Fertilize()
				end
			end)

			inst.player_classified:ListenForEvent("isperformactionsuccessdirty", function(inst)
				if inst.isperformactionsuccess:value() and act then
					if _G.ThePlayer.AnimState:IsCurrentAnimation(fert:HasTag("slowfertilize") and "fertilize" or "short_fertilize") then
						local val = FERTILIZER_DEFS[fert.fertilizerkey or fert.prefab].nutrients[TUNING.FORMULA_NUTRIENTS_INDEX]
						print("FERTILIZE SUCCESS: " ..tostring(val))
						if val > 0 then
							_G.ThePlayer.components._bloomness:Fertilize(val)
						end
						--act = false
						if not active then
							act = false
							fert = nil
						end
					end
				end
			end)
		end
	end)
end)

_G.ww_debug = function(delete)
	if BloomSaver then
		BloomSaver:PrintDebugInfo(delete)
	end
end
