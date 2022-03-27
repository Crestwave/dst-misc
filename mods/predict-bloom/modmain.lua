local _G = GLOBAL
local AutoSaveManager = require("autosavemanager")
local BloomBadge = require("widgets/bloombadge")
_G.bb = nil
local Text = require("widgets/text")
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
	if _G.bb then
		_G.bb:Update()
	end
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

	_G.bb:Update()
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

			inst:ListenForEvent("dressedup", function(inst, data)
				_G.bb:Update()
			end)

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

_G.ww_debug = function(delete, sync)
	if BloomSaver then
		BloomSaver:PrintDebugInfo(delete)
	end
	if _G.ThePlayer.components._bloomness then
		print(_G.ThePlayer.components._bloomness:GetDebugString())
	end

	if sync then
		SyncBloomStage(_G.ThePlayer)
	end
end

-- Mod compatibility stuff by rezecib (https://steamcommunity.com/profiles/76561198025931302)
local CHECK_MODS = {
	["workshop-376333686"] = "COMBINED_STATUS",
	["workshop-343753877"] = "STATUS_ANNOUNCEMENTS",
}
local HAS_MOD = {}
--If the mod is already loaded at this point
for mod_name, key in pairs(CHECK_MODS) do
	HAS_MOD[key] = HAS_MOD[key] or (GLOBAL.KnownModIndex:IsModEnabled(mod_name) and mod_name)
end
--If the mod hasn't loaded yet
for k, v in pairs(GLOBAL.KnownModIndex:GetModsToLoad()) do
	local mod_type = CHECK_MODS[v]
	if mod_type then
		HAS_MOD[mod_type] = v
	end
end

if GetModConfigData("meter") then
	AddClassPostConstruct("widgets/statusdisplays", function(self)
		if not self.owner or self.owner.prefab ~= "wormwood" then return end
		
		self.UpdateBoatChargePosition = function(self) -- Charge badge is at the top. Boat badge goes as high as possible.
			if not self.boatmeter then return end
			
			if HAS_MOD.COMBINED_STATUS then -- Values based off combined status
				if self.charge.shown then self.boatmeter:SetPosition(-62, -139) -- temp position until status announcements is updated
				else self.boatmeter:SetPosition(-62, -52) end -- temp position until status announcements is updated
				--print("BOAT METER")
				--print(self.charge.shown)
				--self.boatmeter:SetPosition(-62, -139)
				--self.boatmeter:SetPosition(-62, -139)
			else -- values based off defaults 
				--print("BOAT METER 2")
				--print(self.charge.shown)
				if self.charge.shown then self.boatmeter:SetPosition(-80, -113)
				else self.boatmeter:SetPosition(-80, -40) end
			end
		end
		
		--self.charge = self:AddChild(BloomBadge(self, MOD_SETTINGS.FORMAT_CHARGE))
		--self.charge = self:AddChild(BloomBadge(self, "hour"))
		--self.charge = self:AddChild(BloomBadge(self, "second"))
		self.charge = self:AddChild(BloomBadge(self, HAS_MOD.COMBINED_STATUS))
		--self.charge.combined_status = HAS_MOD.COMBINED_STATUS
		_G.bb = self.charge
		self.charge:SetPosition(-80, -40)
		--self.charge:Hide()
		self.charge:Show()
		
		--self.onchargedelta = function(owner, data) self:ChargeDelta(data) end
		--self.inst:ListenForEvent("chargechange", self.onchargedelta, self.owner)
		self.onchargedelta = function(owner, data) self:ChargeDelta(data) end
		self.inst:ListenForEvent("bloomdelta", self.onchargedelta, self.owner)
		
		function self:SetChargePercent(val, max, stuck)
			if _G.ThePlayer.components._bloomness ~= nil then
				self.charge:SetPercent(val, max, _G.ThePlayer.components._bloomness.rate, _G.ThePlayer.components._bloomness.is_blooming)
			else
				self.charge:SetPercent(val, max, nil)
			end
		end
	
		--self:SetChargePercent(100, 100, false)
		
		function self:ChargeDelta(data)
			if not self.charge.shown then
				self.charge:Show()
			end
			self:SetChargePercent(data.newval, data.max, data.stuck)
			
			if data.jump then
				self.charge:PulseRed()
				
				if self.owner then
					self.owner.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
				end
			end
			
			if data.newval <= 0 then
				--self.charge:Hide()
			elseif data.newval > data.oldval then
				--[[
				if not self.charge.shown then
					self.charge:Show()
				end
				--]]
				
				self.charge:PulseGreen()
				_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
			end
		end
		
		local old_SetGhostMode = self.SetGhostMode
		self.SetGhostMode = function(self, ghostmode)
			if not self.isghostmode == not ghostmode then
				-- pass on to old_SetGhostMode
			elseif ghostmode then
				self.charge:Hide()
				self.charge:StopWarning()
			end
			
			old_SetGhostMode(self, ghostmode)
		end
		
		if self.boatmeter then -- Lazy way to make the boatmeter look good with the charge
			if not self.boatmeter.owner then self.boatmeter.owner = self end
			print(self.boatmeter.inst)
			print(self.inst)
			self.boatmeter.inst:ListenForEvent("open_meter", function() self:UpdateBoatChargePosition() end)
			self.boatmeter.inst:ListenForEvent("close_meter", function() self:UpdateBoatChargePosition() end)
			--self.boatmeter.OnHide = function(self) self.owner:UpdateBoatChargePosition() end
			--self.boatmeter.OnShow = function(self) self.owner:UpdateBoatChargePosition() end
			self.charge.OnHide = function(self) self.owner:UpdateBoatChargePosition() end
			self.charge.OnShow = function(self) self.owner:UpdateBoatChargePosition() end
			self:UpdateBoatChargePosition()
		end
		
		if HAS_MOD.COMBINED_STATUS then
			self.charge:SetPosition(-62, -52)
		
				--self.charge.bg:SetScale(.5, .7, 0)
				--self.charge.bg:SetPosition(-.5, -40, 0)
				--self.charge.num:SetPosition(2, -40.5, 0)
			--badges[self.charge] = self.charge
			--self.charge.rate = self.charge.bg:AddChild(Text(_G.NUMBERFONT, SHOWMAXONNUMBERS and 25 or 33))
			self.charge.rate = self.charge:AddChild(Text(_G.NUMBERFONT, 28))
			self.charge.rate:SetPosition(2, -40.5, 0)
			--self.charge.rate:SetSize(25)
			--self.charge.rate:SetPosition(6, 0, 0)
			self.charge.rate:MoveToFront()
			self.charge.rate:Hide()
			self.charge.rate:SetScale(1,.78,1)
			self.charge.rate:MoveToFront()
			
			if self.maxnum then
				self.maxnum:MoveToFront()
			end
			local OldOnGainFocus = self.charge.OnGainFocus
			function self.charge:OnGainFocus()
				OldOnGainFocus(self)
				self.num:Hide()
				if self.active then
					self.rate:Show()
				end
			end
		
			local OldOnLoseFocus = self.charge.OnLoseFocus
			function self.charge:OnLoseFocus()
				OldOnLoseFocus(self)
				self.rate:Hide()
				if self.active then
					self.num:Show()
				end
			end
		else
			self.charge.num:SetSize(25)
			--self.charge.num:SetScale(1,.78,1)
			self.charge.num:SetScale(1,.9,1)
			self.charge.num:SetPosition(3, 3)
		end
	end)
end



--[[
if HAS_MOD.STATUS_ANNOUNCEMENTS then
	AddPrefabPostInit("world", function()
		local StatusAnnouncer = require("statusannouncer")
		
		local S = _G.STRINGS._STATUS_ANNOUNCEMENTS
		S._.STAT_NAMES.Charge = "Charge"
		S._.STAT_EMOJI.Charge = "lightbulb"
		S.WX78.CHARGE = {
			FULL = "POWER STATUS: OVERLOADED",
			HIGH = "POWER STATUS: SUFFICIENT",
			MID = "POWER STATUS: DRAINING",
			LOW = "POWER STATUS: NEAR DEPLETION",
			EMPTY = "POWER STATUS: CONCERNING",
			DYING = "POWER STATUS: DYING",
			STUCK = "POWER STATUS: AWAITING DEMISE",
		}
		S.UNKNOWN.CHARGE = { -- no one else should have charge
			FULL = "Fully charged.",
			HIGH = "Highly charged.",
			MID = "Roughly half charged.",
			LOW = "Slightly charged.",
			EMPTY = "Barely charged.",
			DYING = "Lights fading, limbs growing cold.",
			STUCK = "Charge unknown. At least a minute remains.",
		}
		
		--                     {"STUCK",  "DYING",  "EMPTY",  "LOW",  "MID",  "HIGH",  "FULL"}
		local realthresholds = {         0,        0,      .15,    .35,     .55,    .75,     }
		local thresholds = {}
		local metatable = { __index = function(_, key)
			if not _G.ThePlayer or not _G.ThePlayer.components._bloomness then return 1 end 
			local charge = _G.ThePlayer.components._bloomness.timer
			
			if key == 1 and charge == 60 then
				return 1
			elseif key == 2 and charge < 60 then
				return 1
			else
				return realthresholds[key]
			end
		end}
		_G.setmetatable(thresholds, metatable)
		
		-- Status Announcements clears stats before calling RegisterCommonStats, so we hijack RegisterCommonStats.
		local old_RegisterCommonStats = StatusAnnouncer.RegisterCommonStats
		StatusAnnouncer.RegisterCommonStats = function(self, HUD, prefab, hunger, sanity, health, moisture, beaverness, ...)
			old_RegisterCommonStats(self, HUD, prefab, hunger, sanity, health, moisture, beaverness, ...)
			
			-- This is kinda lazy however ThePlayer is nil at this point, we can't check if we have the charge component.
			if prefab == "wormwood" then
				self:RegisterStat(
					"Charge",
					HUD.controls.status.charge,
					_G.CONTROL_ROTATE_LEFT, -- Left Bumper, same as log meter
					thresholds,
				  --{       1/0,      1/0,      .15,    .35,     .55,    .75,     }
					{"STUCK",  "DYING",  "EMPTY",  "LOW",  "MID",  "HIGH",  "FULL"},
					function(ThePlayer)
						return	ThePlayer.components._bloomness.timer,
								ThePlayer.components._bloomness.max
					end,
					nil
				)
			end
		end
	end)
end
--]]
