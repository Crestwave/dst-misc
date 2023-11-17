local _G = GLOBAL

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

	local dbgstr = (world == "Island" or world == "Volcano") and _G.TheWorld.net.components.weather:GetIADebugString() or
			world == "Surface" and _G.TheWorld.net.components.weather:GetDebugString() or
			world == "Caves" and _G.TheWorld.net.components.caveweather:GetDebugString()

	if _G.TheWorld.state.islunarhailing then
		local LUNARHAIL_CEIL = 100
		return _G.TheWorld.state.lunarhaillevel * (TUNING.LUNARHAIL_EVENT_TIME / LUNARHAIL_CEIL)
	end

	if _G.TheWorld.state.hurricane then
		local _, _, hurricane_timer, hurricane_duration = string.find(dbgstr, ".*hurricane:(%d+.%d+)/(%d+.%d+).*")
		return hurricane_duration - hurricane_timer
	end

	local _, _, moisture, moisturefloor, moistureceil, moisturerate, preciprate, peakprecipitationrate = string.find(dbgstr, ".*moisture:%s?(%d+.%d+)%s?%((%d+.%d+)/(%d+.%d+)%) %+ (%-?%d+.%d+).*preciprate:%s?%((%d+.%d+) of (%d+.%d+)%).*")

	moisture = _G.tonumber(moisture)
	moistureceil = _G.tonumber(moistureceil)
	moisturefloor = _G.tonumber(moisturefloor)
	preciprate = _G.tonumber(preciprate)
	peakprecipitationrate = _G.tonumber(peakprecipitationrate)

	local totalseconds = 0

	while moisture > moisturefloor do
		if preciprate > 0 then
			local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
			local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * _G.PI)

			preciprate = math.min(rate, peakprecipitationrate)
			moisture = math.max(moisture - preciprate * _G.FRAMES * PRECIP_RATE_SCALE, 0)

			totalseconds = totalseconds + _G.FRAMES
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
	AddPrefabPostInit("world", function(inst)
		inst:DoTaskInTime(1, function(inst)
			if inst:HasTag("forest") then
				local GOOD_ARENA_SQUARE_SIZE = 6
				local w, h = inst.Map:GetSize()

				w = w * _G.TILE_SCALE / 2
				h = h * _G.TILE_SCALE / 2

				local tiles = {}
				local cache = false
				local time = 0
				local pt = nil

				for x=-w,w,4 do
					for y=-h,h,4 do
						if inst.Map:IsAboveGroundInSquare(x, 0, y, GOOD_ARENA_SQUARE_SIZE, inst.Map.IsTileLandNoDocks) then
							table.insert(tiles, _G.Vector3(x, 0, y))
						end
					end
				end

				inst.components.riftspawner = {
					IsLunarPortalActive = function()
						if cache then
							if inst.Map:GetTileAtPoint(pt:Get()) ~= _G.WORLD_TILES.RIFT_MOON then
								cache = false
								time = _G.GetTime()
								pt = nil
								return false
							else
								return true
							end
						else
							if _G.GetTime() - time < 1 then
								return false
							end

							for k, v in pairs(tiles) do
								if inst.Map:GetTileAtPoint(v:Get()) == _G.WORLD_TILES.RIFT_MOON then
									cache = true
									time = _G.GetTime()
									pt = v
									return true
								end
							end

							time = _G.GetTime()
							return false
						end
					end
				}
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
					_G.ChatHistory:SendCommandResponse(string.format("Invalid mode '%s'; see /help predictrain.", params.mode))
					return
				end
			end

			if not _G.TheWorld.components.riftspawner:IsLunarPortalActive() then
				Announce("Lunar rift is currently inactive")
			elseif not _G.TheWorld.islunarhailing then
				local LUNARHAIL_CEIL = 100
				local totalseconds = ((LUNARHAIL_CEIL - _G.TheWorld.state.lunarhaillevel) / 100) * TUNING.LUNARHAIL_EVENT_COOLDOWN

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
