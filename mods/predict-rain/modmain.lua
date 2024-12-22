local _G = GLOBAL
-- Note: true dt is 0.033333335071802, which makes FRAMES accurate up to 8 decimals of precision
local dt = _G.FRAMES
local easing = require('easing')
local UpvalueHacker = require("tools/upvaluehacker")

local _moisture
local _moisturefloor
local _moistureceil
local _moisturerate
local _preciprate
local _peakprecipitationrate

-- Get direct upvalues to avoid debug string rounding
local function GetUpvalues(self)
	-- Delay by a frame to let Island Adventures' postinit load first
	self.inst:DoTaskInTime(0, function(inst)
		if _G.TheWorld:HasTag("island") or _G.TheWorld:HasTag("volcano") then
			_moisture = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_moisture_island")
			_moisturefloor = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_moisturefloor_island")
			_moistureceil = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_moistureceil_island")
			_moisturerate = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_moisturerate_island")
			_peakprecipitationrate = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_peakprecipitationrate_island")

			_hurricane_timer = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_hurricane_timer")
			_hurricane_duration = UpvalueHacker.GetUpvalue(self.GetIADebugString, "_hurricane_duration")
		else
			_moisture = UpvalueHacker.GetUpvalue(self.GetDebugString, "_moisture")
			_moisturefloor = UpvalueHacker.GetUpvalue(self.GetDebugString, "_moisturefloor")
			_moistureceil = UpvalueHacker.GetUpvalue(self.GetDebugString, "_moistureceil")
			_moisturerate = UpvalueHacker.GetUpvalue(self.GetDebugString, "_moisturerate")
			_peakprecipitationrate = UpvalueHacker.GetUpvalue(self.GetDebugString, "_peakprecipitationrate")
		end
	end)
end

AddClassPostConstruct("components/weather", GetUpvalues)
AddClassPostConstruct("components/caveweather", GetUpvalues)

local function PredictRainStart(world)
	local MOISTURE_RATES
	local moisture
	local moistureceil

	if world == "Island" or world == "Volcano" then
		MOISTURE_RATES = {
		    MIN = {
		        autumn = 0,
		        winter = 3,
		        spring = 3,
		        summer = 0,
		    },
		    MAX = {
		        autumn = 0.1,
		        winter = 3.75,
		        spring = 3.75,
		        summer = -0.2,
		    }
		}

		moisture = _G.TheWorld.state.islandmoisture
		moistureceil = _G.TheWorld.state.islandmoistureceil
	else
		MOISTURE_RATES = {
		    MIN = {
		        autumn = .25,
		        winter = .25,
		        spring = 3,
		        summer = .1,
		    },
		    MAX = {
		        autumn = 1.0,
		        winter = 1.0,
		        spring = 3.75,
		        summer = .5,
		    }
		}

		moisture = _G.TheWorld.state.moisture
		moistureceil = _G.TheWorld.state.moistureceil
	end

	local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (_G.TheWorld.state.time * TUNING.TOTAL_DAY_TIME)
	local totalseconds = 0

	local season = _G.TheWorld.state.season
	local seasonprogress = _G.TheWorld.state.seasonprogress
	local elapseddaysinseason = _G.TheWorld.state.elapseddaysinseason
	local remainingdaysinseason = _G.TheWorld.state.remainingdaysinseason
	local totaldaysinseason = remainingdaysinseason / (1 - seasonprogress)
	local _totaldaysinseason = elapseddaysinseason + remainingdaysinseason

	while elapseddaysinseason < _totaldaysinseason do
		local moisturerate

		if world == "Surface" and season == "winter" and elapseddaysinseason == 2 then
			moisturerate = 50
		else
			local p = 1 - math.sin(_G.PI * seasonprogress)
			moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
		end

		local _moisture = moisture + (moisturerate * remainingsecondsinday)

		if _moisture >= moistureceil then
			totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
			return totalseconds
		else
			moisture = _moisture
			totalseconds = totalseconds + remainingsecondsinday
			remainingsecondsinday = TUNING.TOTAL_DAY_TIME
			elapseddaysinseason = elapseddaysinseason + 1
			remainingdaysinseason = remainingdaysinseason - 1
			seasonprogress = 1 - (remainingdaysinseason / totaldaysinseason)
		end
	end

	return false
end

local function PredictRainStop(world)
	local PRECIP_RATE_SCALE = 10
	local MIN_PRECIP_RATE = .1

	if _G.TheWorld.state.islunarhailing then
		local LUNARHAIL_CEIL = 100
		return _G.TheWorld.state.lunarhaillevel * (TUNING.LUNARHAIL_EVENT_TIME / LUNARHAIL_CEIL)
	end

	if _G.TheWorld.state.hurricane then
		local hurricane_timer = _hurricane_timer:value()
		local hurricane_duration = _hurricane_duration:value()
		return hurricane_duration - hurricane_timer
	end

	local moisture = _moisture:value()
	local moisturefloor = _moisturefloor:value()
	local moistureceil = _moistureceil:value()
	local moisturerate = _moisturerate:value()
	local peakprecipitationrate = _peakprecipitationrate:value()

	-- Temporarily set preciprate to 1 to kickstart the first loop
	local preciprate = 1
	local totalseconds = 0

	while moisture > moisturefloor do
		if preciprate > 0 then
			local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
			local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * _G.PI)

			preciprate = math.min(rate, peakprecipitationrate)
			moisture = math.max(moisture - preciprate * dt * PRECIP_RATE_SCALE, 0)

			totalseconds = totalseconds + dt
		else
			break
		end
	end

	return totalseconds
end

AddUserCommand("predictrain", {
	prettyname = "Predict Rain",
	desc = [[
Forecast rain start or stop.
Modes: 0 for global chat, 1 for whisper chat, 2 for local chat.
]],
	permission = _G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"mode"},
	paramsoptional = {true},
	vote = false,
	localfn = function(params, caller)
		if caller == nil or caller.HUD == nil then
			return
		end

		local function Announce(msg)
			_G.TheNet:Say(string.format("%s %s", _G.STRINGS.LMB, msg))
		end

		if params.mode ~= nil then
			if params.mode == "1" then
				Announce = function(msg) _G.TheNet:Say(string.format("%s %s", _G.STRINGS.LMB, msg), true) end
			elseif params.mode == "2" then
				Announce = function(msg) _G.ChatHistory:SendCommandResponse(msg) end
			elseif params.mode ~= "0" then
				_G.ChatHistory:SendCommandResponse(string.format("Invalid mode '%s'; see /help predictrain.", params.mode))
				return
			end
		end

		local world = _G.TheWorld:HasTag("island") and "Island" or
				_G.TheWorld:HasTag("volcano") and "Volcano" or
				_G.TheWorld.net.components.weather ~= nil and "Surface" or
				_G.TheWorld.net.components.caveweather ~= nil and "Caves"

		if _G.TheWorld.state.pop ~= 1 then
			local totalseconds = PredictRainStart(world)

			if totalseconds then
				local d = _G.TheWorld.state.cycles + 1 + _G.TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
				local m = math.floor(totalseconds / 60)
				local s = totalseconds % 60

				Announce(string.format("%s will rain on day %.2f (%dm %ds).", world, d, m, s))
			else
				Announce(string.format("%s will no longer rain this %s.", world, _G.TheWorld.state.season))
			end
		else
			local totalseconds = PredictRainStop(world)

			local d = _G.TheWorld.state.cycles + 1 + _G.TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
			local m = math.floor(totalseconds / 60)
			local s = totalseconds % 60

			Announce(string.format("%s will stop raining on day %.2f (%dm %ds).", world, d, m, s))
		end
	end,
})

if GetModConfigData("predicthail") then
	local lunarrift = nil

	AddPrefabPostInit("globalmapicon", function(inst)
		inst:DoTaskInTime(1, function(inst)
			if (lunarrift == nil or not lunarrift:IsValid()) and
				_G.TheWorld:HasTag("forest") and
				_G.TheWorld.Map:GetTileAtPoint(inst.Transform:GetWorldPosition()) == _G.WORLD_TILES.RIFT_MOON then
				lunarrift = inst
			end
		end)
	end)

	AddPrefabPostInit("world", function(inst)
		inst:DoTaskInTime(0, function(inst)
			if inst.components.riftspawner == nil then
				inst.components.riftspawner = {}
			end

			if inst.components.riftspawner.IsLunarPortalActive == nil then
				inst.components.riftspawner.IsLunarPortalActive = function()
					return lunarrift ~= nil and lunarrift:IsValid()
				end
			end
		end)
	end)

	AddUserCommand("predicthail", {
		prettyname = "Predict Hail",
		desc = [[
Forecast lunar hail start or stop.
Modes: 0 for global chat, 1 for whisper chat, 2 for local chat.
]],
		permission = _G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {"mode"},
		paramsoptional = {true},
		vote = false,
		localfn = function(params, caller)
			if caller == nil or caller.HUD == nil or not _G.TheWorld:HasTag("forest") then
				return
			end

			local function Announce(msg)
				_G.TheNet:Say(string.format("%s %s", _G.STRINGS.LMB, msg))
			end

			if params.mode ~= nil then
				if params.mode == "1" then
					Announce = function(msg) _G.TheNet:Say(string.format("%s %s", _G.STRINGS.LMB, msg), true) end
				elseif params.mode == "2" then
					Announce = function(msg) _G.ChatHistory:SendCommandResponse(msg) end
				elseif params.mode ~= "0" then
					_G.ChatHistory:SendCommandResponse(string.format("Invalid mode '%s'; see /help predicthail.", params.mode))
					return
				end
			end

			if not _G.TheWorld.components.riftspawner:IsLunarPortalActive() then
				Announce("Lunar rift is currently inactive.")
			elseif not _G.TheWorld.state.islunarhailing then
				local LUNAR_HAIL_CEIL = 100
				local totalseconds = ((LUNAR_HAIL_CEIL - _G.TheWorld.state.lunarhaillevel) / 100) * TUNING.LUNARHAIL_EVENT_COOLDOWN

				if totalseconds then
					local d = _G.TheWorld.state.cycles + 1 + _G.TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
					local m = math.floor(totalseconds / 60)
					local s = totalseconds % 60
	
					Announce(string.format("Lunar hail will start on day %.2f (%dm %ds).", d, m, s))
				end
			else
				local totalseconds = PredictRainStop("Surface")

				local d = _G.TheWorld.state.cycles + 1 + _G.TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
				local m = math.floor(totalseconds / 60)
				local s = totalseconds % 60

				Announce(string.format("Lunar hail will stop on day %.2f (%dm %ds).", d, m, s))
			end
		end,
	})
end
