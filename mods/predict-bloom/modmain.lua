local _G = GLOBAL
local AutoSaveManager = require("autosavemanager")
local BloomBadge = require("widgets/bloombadge")
local BloomSaver = nil
local badge = nil
local inittask = false

local function _OnFertilizedWithFormula(inst, value)
	if value > 0 and inst.components._bloomness then
		if inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") then
			value = value * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT
		end
		inst.components._bloomness:Fertilize(value)
	end
end

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

	local actual_maximum = (inst.components.skilltreeupdater and
					inst.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade") and
					TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION_UPGRADED)
				or TUNING.WORMWOOD_BLOOM_FULL_MAX_DURATION
	return math.min(remaining + value, actual_maximum)
end

local function OnSeasonChange(inst, season)
	if season == "spring" and not inst:HasTag("playerghost") then
		inst.components._bloomness:Fertilize()
	else
		inst.components._bloomness:UpdateRate()
	end
end

local function UpdateBloomStage(inst, stage)
	if badge ~= nil then
		badge:UpdateIcon()
	end

	if stage then
		if not GetModConfigData("stage") and badge ~= nil then
			if stage == 0 then
				inst.HUD.controls.status.bloombadge:Hide()
			elseif not inst.HUD.controls.status.bloombadge.shown then
				inst.HUD.controls.status.bloombadge:Show()
			end
		end

		print("Stage: " .. stage)
	end
end

local function SyncBloomStage(inst)
	local mult = inst.player_classified.runspeed:value() / TUNING.WILSON_RUN_SPEED
	local stage = _G.RoundBiasedUp(_G.Remap(mult, 1, 1.2, 0, 3))
	local level = inst.components._bloomness:GetLevel()
	if stage ~= level then
		inst.components._bloomness:SetLevel(stage)

		if badge ~= nil then
			if stage > level then
				badge:PulseGreen()
			elseif stage < level then
				badge:PulseRed()
			end
		end
	end
end

local function OnBloomFXDirty(inst)
	inst:DoTaskInTime(0, SyncBloomStage)
end

local function OnNewSpawn(inst)
	inittask = false
	if _G.TheWorld.state.isspring then
		inst.components._bloomness:Fertilize()
	end
end

local function OnLoad(inst)
	if inst.components.bloomness == nil then
		inst.components._bloomness:Load(BloomSaver:LoadData())
	else
		inst.components._bloomness:Load(inst.components.bloomness:OnSave())
	end
end

AddPlayerPostInit(function(inst)
	inst:DoTaskInTime(0, function(inst)
		if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.player_classified ~= nil then
			inst:AddComponent("_bloomness")
			inst.components._bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION, TUNING.WORMWOOD_BLOOM_FULL_DURATION)
			inst.components._bloomness.onlevelchangedfn = UpdateBloomStage
			inst.components._bloomness.calcratefn = CalcBloomRateFn
			inst.components._bloomness.calcfullbloomdurationfn = CalcFullBloomDurationFn
			inst.components._bloomness:DoDelta(0)

			inst._OnFertilizedWithFormula = _OnFertilizedWithFormula

			inst:ListenForEvent("bloomfxdirty", OnBloomFXDirty)
			inst:ListenForEvent("bloomdelta", function(inst, data) SyncBloomStage(inst) end)
			inst:WatchWorldState("season", OnSeasonChange)

			inst:ListenForEvent("onactivateskill_client", function(inst, data)
				local bloomness = inst.components._bloomness
				local skilltreeupdater = inst.components.skilltreeupdater

				if data.skill == "wormwood_blooming_speed1" then
					if not (skilltreeupdater:IsActivated("wormwood_blooming_speed2")
						or skilltreeupdater:IsActivated("wormwood_blooming_speed3")) then
						bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION_UPGRADED1, bloomness.full_bloom_duration)
					end
				elseif data.skill == "wormwood_blooming_speed2" then
					if not skilltreeupdater:IsActivated("wormwood_blooming_speed3") then
						bloomness:SetDurations(TUNING.WORMWOOD_BLOOM_STAGE_DURATION_UPGRADED2, bloomness.full_bloom_duration)
					end
				else
					return
				end

				bloomness:DoDelta(0)
			end)

			if inst.components.bloomness == nil then
				BloomSaver = AutoSaveManager("bloomness", inst.components._bloomness.Save, { inst.components._bloomness })
				BloomSaver:StartAutoSave()
			end

			if inittask then
				OnNewSpawn(inst)
			else
				OnLoad(inst)
			end

			SyncBloomStage(inst)
			UpdateBloomStage(inst, inst.components._bloomness:GetLevel())

			local function OnGhostModeDirty(inst)
				if inst.isghostmode:value() then
					inst._parent.components._bloomness:SetLevel(0)
					if badge ~= nil then
						badge:Hide()
					end
				elseif _G.TheWorld.state.isspring then
					inst._parent.components._bloomness:Fertilize()
					if badge ~= nil then
						badge:Show()
					end
				else
					if GetModConfigData("stage") and badge ~= nil then
						badge:Show()
					end
				end
			end

			inst.player_classified:ListenForEvent("isghostmodedirty", OnGhostModeDirty)
			OnGhostModeDirty(inst.player_classified)

			if GetModConfigData("acidrain") then
				local pulsetime
				local _Flash = inst.HUD.bloodover.Flash
				local Flash = function(...)
					pulsetime = _G.GetTime()
					return _Flash(...)
				end

				local function OnHealthDelta(inst, data)
					if pulsetime == _G.GetTime() then
						return
					end

					if not data.overtime and
							(not inst.player_classified.istakingfiredamage:value() or inst.player_classified.istakingfiredamagelow:value()) and
							(not inst.player_classified.isinmiasma:value()) then
						local damage = inst.replica.health:Max() * (data.oldpercent - data.newpercent)
						inst:_OnFertilizedWithFormula(damage)
					end
				end

				local function OnIsAcidSizzling(isacidsizzling)
					if isacidsizzling then
						inst.components._bloomness:Fertilize()
						inst:ListenForEvent("healthdelta", OnHealthDelta)
						inst.HUD.bloodover.Flash = Flash
					else
						inst:RemoveEventCallback("healthdelta", OnHealthDelta)
						inst.HUD.bloodover.Flash = _Flash
					end
				end

				inst:ListenForEvent("isacidsizzling", OnIsAcidSizzling)
				OnIsAcidSizzling(inst:IsAcidSizzling())
			end
		end
	end)
end)

AddPrefabPostInit("world", function(inst)
	inst:ListenForEvent("entercharacterselect", function() inittask = true end)

	if not inst.ismastersim then
		local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
		local _SendRPCToServer = nil
		local act = false
		local active = false
		local chain = false
		local fert = nil

		AddPlayerPostInit(function(inst)
			inst:DoTaskInTime(0, function(inst)
				if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.player_classified ~= nil then
					if _SendRPCToServer == nil then
						_SendRPCToServer = _G.SendRPCToServer

						_G.SendRPCToServer = function(...)
							local arg = { ... }

							if arg[2] == _G.ACTIONS.FERTILIZE.code and (not _G.ThePlayer:HasTag("busy") or chain) then
								act = true
								chain = false

								if arg[1] == _G.RPC.LeftClick then
									active = true
									fert = _G.ThePlayer.replica.inventory:GetActiveItem()
								elseif arg[1] == _G.RPC.UseItemFromInvTile or arg[1] == _G.RPC.ControllerUseItemOnSceneFromInvTile or arg[1] == _G.RPC.ControllerUseItemOnSelfFromInvTile then
									fert = arg[3]
								else
									act = false
								end
							elseif act then
								if arg[1] == _G.RPC.InspectItemFromInvTile then
									act = false
								elseif active and arg[1] == _G.RPC.ClearActionHold then
									active = false
								end
							end

							return _SendRPCToServer(...)
						end

						local _CloseWardrobe = _G.POPUPS.WARDROBE.Close
						_G.POPUPS.WARDROBE.Close = function(...)
							if inst == _G.ThePlayer and inst.components._bloomness ~= nil then
								inst:DoTaskInTime(1, UpdateBloomStage)
							end
							return _CloseWardrobe(...)
						end

						local _CloseGiftItem = _G.POPUPS.GIFTITEM.Close
						_G.POPUPS.GIFTITEM.Close = function(...)
							if inst == _G.ThePlayer and inst.components._bloomness ~= nil then
								inst:DoTaskInTime(1, UpdateBloomStage)
							end
							return _CloseGiftItem(...)
						end
					end

					inst.player_classified:ListenForEvent("isperformactionsuccessdirty", function(inst)
						if not act then return end

						if inst._parent.AnimState:IsCurrentAnimation(fert:HasTag("slowfertilize") and
													(inst._parent.components.skilltreeupdater:IsActivated("wormwood_quick_selffertilizer") and
													"shortest_fertilize" or
													"fertilize") or
												"short_fertilize") then
							if inst.isperformactionsuccess:value() then
								local defs = FERTILIZER_DEFS[fert.fertilizerkey or fert.prefab]
								if defs ~= nil and defs.nutrients ~= nil then
									local value = defs.nutrients[TUNING.FORMULA_NUTRIENTS_INDEX]

									inst._parent:_OnFertilizedWithFormula(value)
								end
							end

							chain = true
						else
							chain = false
						end

						if not active then
							act = false
							fert = nil
						end
					end)
				end
			end)
		end)
	else
		AddPlayerPostInit(function(inst)
			inst:DoTaskInTime(0, function(inst)
				if inst == _G.ThePlayer and inst.prefab == "wormwood" and inst.components.bloomness ~= nil then
					local _Fertilize = inst.components.bloomness.Fertilize
					inst.components.bloomness.Fertilize = function(self, value)
						self.inst.components._bloomness:Fertilize(value)
						return _Fertilize(self, value)
					end

					if inst.components.skinner ~= nil then
						local _SetSkinMode = inst.components.skinner.SetSkinMode
						inst.components.skinner.SetSkinMode = function(...)
							local r = { _SetSkinMode(...) }
							UpdateBloomStage(inst)
							return _G.unpack(r)
						end
					end
				end
			end)
		end)
	end
end)

_G.ww_debug = function(delete, sync, fert)
	if BloomSaver then
		BloomSaver:PrintDebugInfo(delete)
	end

	if _G.ThePlayer.components._bloomness then
		if fert then
			_G.ThePlayer.components._bloomness:Fertilize(fert)
		end

		if sync then
			SyncBloomStage(inst)
		end

		print(_G.ThePlayer.components._bloomness:GetDebugString())
	end
end

if GetModConfigData("meter") then
	-- Mod compatibility stuff by rezecib (https://steamcommunity.com/profiles/76561198025931302)
	local CHECK_MODS = {
		["workshop-376333686"] = "COMBINED_STATUS",
		["CombinedStatus"] = "COMBINED_STATUS",
		["workshop-343753877"] = "STATUS_ANNOUNCEMENTS",
		["StatusAnnouncements"] = "STATUS_ANNOUNCEMENTS",
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

	AddClassPostConstruct("widgets/statusdisplays", function(self)
		if not self.owner or self.owner.prefab ~= "wormwood" then return end

		self.bloombadge = self:AddChild(BloomBadge(self.owner, HAS_MOD.COMBINED_STATUS))
		self.bloombadge:SetPosition(-120, 20)
		self._custombadge = self.bloombadge
		badge = self.bloombadge

		self.onbloomdelta = function(owner, data) self:BloomDelta(data) end
		self.inst:ListenForEvent("bloomdelta", self.onbloomdelta, self.owner)

		function self:BloomDelta(data)
			self.bloombadge:SetPercent(math.max(data.newval, 0), data.max, data.rate, data.is_blooming)

			if (data.newval - data.oldval) > 0 and data.level == 3 then
				self.bloombadge:PulseGreen()
				_G.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/health_up")
			end
		end

		if HAS_MOD.COMBINED_STATUS then
			local Text = require("widgets/text")
			self.bloombadge:SetPosition(-62, -52)
			self.bloombadge.rate = self.bloombadge:AddChild(Text(_G.NUMBERFONT, 28))
			self.bloombadge.rate:SetPosition(2, -40.5, 0)
			self.bloombadge.rate:SetScale(1,.78,1)
			self.bloombadge.rate:Hide()

			self.inst:DoTaskInTime(0, function(inst)
				local _ShowStatusNumbers = self.ShowStatusNumbers
				function self:ShowStatusNumbers()
					_ShowStatusNumbers(self)
					if self.bloombadge ~= nil then
						self.bloombadge.rate:Show()
						self.bloombadge.num:Hide()
					end
				end

				local _HideStatusNumbers = self.HideStatusNumbers
				function self:HideStatusNumbers()
					_HideStatusNumbers(self)
					if self.bloombadge ~= nil then
						self.bloombadge.rate:Hide()
						self.bloombadge.num:Show()
					end
				end
			end)

			local _OnLoseFocus = self.bloombadge.OnLoseFocus
			function self.bloombadge:OnLoseFocus()
				_OnLoseFocus(self)
				self.rate:Hide()
				if self.active then
					self.num:Show()
				end
			end

			local _OnGainFocus = self.bloombadge.OnGainFocus
			function self.bloombadge:OnGainFocus()
				_OnGainFocus(self)
				self.num:Hide()
				if self.active then
					self.rate:Show()
				end
			end

			function self.bloombadge:OnHide()
				if self.parent.boatmeter then
					self.parent.boatmeter:SetPosition(-62, -52)
				end
			end

			function self.bloombadge:OnShow()
				if self.parent.boatmeter then
					self.parent.boatmeter:SetPosition(-124, -52)
				end
			end

			if self.boatmeter then
				self.boatmeter.inst:ListenForEvent("open_meter", function(inst)
					if inst.widget.parent.bloombadge.shown then
						inst.widget:SetPosition(-124, -52)
					else
						inst.widget:SetPosition(-62, -52)
					end
				end)
			end
		else
			self.bloombadge.num:SetSize(25)
			self.bloombadge.num:SetScale(1,.9,1)
			self.bloombadge.num:SetPosition(3, 3)

			local _ShowStatusNumbers = self.ShowStatusNumbers
			function self:ShowStatusNumbers()
				_ShowStatusNumbers(self)
				if self.bloombadge ~= nil then
					self.bloombadge.num:Show()
				end
			end

			local _HideStatusNumbers = self.HideStatusNumbers
			function self:HideStatusNumbers()
				_HideStatusNumbers(self)
				if self.bloombadge ~= nil then
					self.bloombadge.num:Hide()
				end
			end
		end
	end)

	if HAS_MOD.STATUS_ANNOUNCEMENTS then
		local PlayerHud = require("screens/playerhud")
		local PlayerHud_SetMainCharacter = PlayerHud.SetMainCharacter
		function PlayerHud:SetMainCharacter(maincharacter, ...)
			PlayerHud_SetMainCharacter(self, maincharacter, ...)
			if maincharacter.prefab == "wormwood" then
				_G.STRINGS._STATUS_ANNOUNCEMENTS._.STAT_NAMES.Bloom = "Bloom"
				_G.STRINGS._STATUS_ANNOUNCEMENTS._.STAT_EMOJI.Bloom = "poop"
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_0 = { BLOOM = { ANY = "Need smelly stuff." } }
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_1 = { BLOOM = { ANY = "Feeling bloomy!" } }
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_2 = { BLOOM = { ANY = "Grow!" } }
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_3 = { BLOOM = { ANY = "Blooming!" } }
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_4 = { BLOOM = { ANY = "Drooping..." } }
				_G.STRINGS._STATUS_ANNOUNCEMENTS.UNKNOWN.STAGE_5 = { BLOOM = { ANY = "Feeling droopy..." } }

				self.inst:DoTaskInTime(0, function()
					if self._StatusAnnouncer then
						self._StatusAnnouncer:RegisterStat(
							"Bloom",
							self.controls.status.bloombadge,
							_G.CONTROL_ROTATE_LEFT,
							{},
							{"ANY"},
							function(ThePlayer)
								return	self.controls.status.bloombadge.val,
										self.controls.status.bloombadge.max
							end,
							function(ThePlayer)
								local level = ThePlayer.components._bloomness:GetLevel()
								if (level == 1 or level == 2) and not ThePlayer.components._bloomness.is_blooming then
									level = level + 3
								end

								return	"STAGE_" .. level
							end
						)
					end
				end)
			end
		end
	end
end
