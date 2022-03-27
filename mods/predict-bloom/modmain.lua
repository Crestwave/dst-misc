local _G = GLOBAL
local AutoSaveManager = require("autosavemanager")
local BloomBadge = require("widgets/bloombadge")
local BloomSaver = nil

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
	inst.HUD.controls.status.bloom:Update()
end

local function SyncBloomStage(inst, force)
	local badge = inst.HUD.controls.status.bloom
	local mult = inst.player_classified.runspeed:value() / TUNING.WILSON_RUN_SPEED
	local stage = _G.RoundBiasedUp(_G.Remap(mult, 1, 1.2, 0, 3))
	local level = inst.components._bloomness:GetLevel()
	if stage ~= level or force then
		inst.components._bloomness:SetLevel(stage)

		if _G.TheWorld.state.isspring then
			inst.components._bloomness:Fertilize()
		end

		if level == 0 then
			badge:Hide()
		end

		if stage > level then
			badge:PulseGreen()
		elseif stage < level then
			badge:PulseRed()
		end
	else
		inst.components._bloomness:UpdateRate()
	end

	badge:Update()
end

local function OnBloomFXDirty(inst)
	inst:DoTaskInTime(1, SyncBloomStage, true)
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
		if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.player_classified ~= nil then
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
		
		self.UpdateBoatBloomPosition = function(self) -- Bloom badge is at the top. Boat badge goes as high as possible.
			if not self.boatmeter then return end
			
			if HAS_MOD.COMBINED_STATUS then -- Values based off combined status
				if self.bloom.shown then self.boatmeter:SetPosition(-62, -139) -- temp position until status announcements is updated
				else self.boatmeter:SetPosition(-62, -52) end -- temp position until status announcements is updated
			else -- values based off defaults 
				if self.bloom.shown then self.boatmeter:SetPosition(-80, -113)
				else self.boatmeter:SetPosition(-80, -40) end
			end
		end
		
		self.bloom = self:AddChild(BloomBadge(self, HAS_MOD.COMBINED_STATUS))
		self.bloom:SetPosition(-80, -40)
		self._custombadge = self.bloom
		
		self.onchargedelta = function(owner, data) self:ChargeDelta(data) end
		self.inst:ListenForEvent("bloomdelta", self.onchargedelta, self.owner)
		
		function self:SetChargePercent(val, max, stuck)
			if _G.ThePlayer.components._bloomness ~= nil then
				self.bloom:SetPercent(val, max, _G.ThePlayer.components._bloomness.rate, _G.ThePlayer.components._bloomness.is_blooming)
			else
				self.bloom:SetPercent(val, max, nil)
			end
		end
	
		function self:ChargeDelta(data)
			if not self.bloom.shown then
				self.bloom:Show()
			end
			self:SetChargePercent(data.newval, data.max, data.stuck)
			
			if data.jump then
				self.bloom:PulseRed()
				
				if self.owner then
					self.owner.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
				end
			end
			
			if data.newval <= 0 then
				--self.bloom:Hide()
			elseif data.newval > data.oldval then
				--[[
				if not self.bloom.shown then
					self.bloom:Show()
				end
				--]]
				
				self.bloom:PulseGreen()
				_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
			end
		end
		
		local old_SetGhostMode = self.SetGhostMode
		self.SetGhostMode = function(self, ghostmode)
			if not self.isghostmode == not ghostmode then
				-- pass on to old_SetGhostMode
			elseif ghostmode then
				self.bloom:Hide()
				self.bloom:StopWarning()
			end
			
			old_SetGhostMode(self, ghostmode)
		end
		
		if self.boatmeter then -- Lazy way to make the boatmeter look good with the charge
			if not self.boatmeter.owner then self.boatmeter.owner = self end
			self.boatmeter.inst:ListenForEvent("open_meter", function() self:UpdateBoatBloomPosition() end)
			self.boatmeter.inst:ListenForEvent("close_meter", function() self:UpdateBoatBloomPosition() end)
			self.bloom.OnHide = function(self) self.owner:UpdateBoatBloomPosition() end
			self.bloom.OnShow = function(self) self.owner:UpdateBoatBloomPosition() end
			self:UpdateBoatBloomPosition()
		end
		
		if HAS_MOD.COMBINED_STATUS then
			local Text = require("widgets/text")
			self.bloom:SetPosition(-62, -52)
			self.bloom.rate = self.bloom:AddChild(Text(_G.NUMBERFONT, 28))
			self.bloom.rate:SetPosition(2, -40.5, 0)
			self.bloom.rate:SetScale(1,.78,1)
			self.bloom.rate:Hide()
			
			local OldOnGainFocus = self.bloom.OnGainFocus
			function self.bloom:OnGainFocus()
				OldOnGainFocus(self)
				self.num:Hide()
				if self.active then
					self.rate:Show()
				end
			end
		
			local OldOnLoseFocus = self.bloom.OnLoseFocus
			function self.bloom:OnLoseFocus()
				OldOnLoseFocus(self)
				self.rate:Hide()
				if self.active then
					self.num:Show()
				end
			end
		else
			self.bloom.num:SetSize(25)
			self.bloom.num:SetScale(1,.9,1)
			self.bloom.num:SetPosition(3, 3)
		end
	end)

	if HAS_MOD.STATUS_ANNOUNCEMENTS then
		local PlayerHud = require("screens/playerhud")
		local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
		function PlayerHud:SetMainCharacter(maincharacter, ...)
			PlayerHud_SetMainCharacter(self, maincharacter, ...)
			self.inst:DoTaskInTime(0, function()
				if self._StatusAnnouncer and maincharacter.prefab == "wormwood" then
					_G.STRINGS._STATUS_ANNOUNCEMENTS._.STAT_NAMES.Bloom = "Bloom"
					_G.STRINGS._STATUS_ANNOUNCEMENTS._.STAT_EMOJI.Bloom = "poop"
					_G.STRINGS._STATUS_ANNOUNCEMENTS.WORMWOOD.STAGE_0 = { BLOOM = { ANY = "Feeling droopy." } }
					_G.STRINGS._STATUS_ANNOUNCEMENTS.WORMWOOD.STAGE_1 = { BLOOM = { ANY = "Feeling bloomy!" } }
					_G.STRINGS._STATUS_ANNOUNCEMENTS.WORMWOOD.STAGE_2 = { BLOOM = { ANY = "Grow!" } }
					_G.STRINGS._STATUS_ANNOUNCEMENTS.WORMWOOD.STAGE_3 = { BLOOM = { ANY = "Blooming!" } }
	
					self._StatusAnnouncer:RegisterStat(
						"Bloom",
						self.controls.status._custombadge,
						_G.CONTROL_ROTATE_LEFT,
						{},
						{"ANY"},
						function(ThePlayer)
							return	self.controls.status._custombadge.val,
									self.controls.status._custombadge.max
						end,
						function(ThePlayer)
							return	"STAGE_" .. ThePlayer.components._bloomness:GetLevel()
						end
					)
				end
			end)
		end
	end
end
