local function PredictRainStart()
	local MOISTURE_RATES = {
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

	local TheWorld = GLOBAL.TheWorld
	local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"
	local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (TheWorld.state.time * TUNING.TOTAL_DAY_TIME)
	local totalseconds = 0
	local rain = false

	local season = TheWorld.state.season
	local seasonprogress = TheWorld.state.seasonprogress
	local elapseddaysinseason = TheWorld.state.elapseddaysinseason
	local remainingdaysinseason = TheWorld.state.remainingdaysinseason
	local totaldaysinseason = remainingdaysinseason / (1 - seasonprogress)
	local _totaldaysinseason = elapseddaysinseason + remainingdaysinseason

	local moisture = TheWorld.state.moisture
	local moistureceil = TheWorld.state.moistureceil

	while elapseddaysinseason < _totaldaysinseason do
		local moisturerate

		if world == "Surface" and season == "winter" and elapseddaysinseason == 2 then
			moisturerate = 50
		else
			local p = 1 - math.sin(GLOBAL.PI * seasonprogress)
			moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
		end

		local _moisture = moisture + (moisturerate * remainingsecondsinday)
	
		if _moisture >= moistureceil then
			totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
			rain = true
			break
		else
			moisture = _moisture
			totalseconds = totalseconds + remainingsecondsinday
			remainingsecondsinday = TUNING.TOTAL_DAY_TIME
			elapseddaysinseason = elapseddaysinseason + 1
			remainingdaysinseason = remainingdaysinseason - 1
			seasonprogress = 1 - (remainingdaysinseason / totaldaysinseason)
		end
	end

	return world, totalseconds, rain
end

local function PredictRainStop()
	local PRECIP_RATE_SCALE = 10
	local MIN_PRECIP_RATE = .1

	local TheWorld = GLOBAL.TheWorld
	local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"
	local dbgstr = (TheWorld.net.components.weather ~= nil and TheWorld.net.components.weather:GetDebugString()) or TheWorld.net.components.caveweather:GetDebugString()
	local _, _, moisture, moisturefloor, moistureceil, moisturerate, preciprate, peakprecipitationrate = string.find(dbgstr, ".*moisture:(%d+.%d+)%((%d+.%d+)/(%d+.%d+)%) %+ (%d+.%d+), preciprate:%((%d+.%d+) of (%d+.%d+)%).*")

	moisture = GLOBAL.tonumber(moisture)
	moistureceil = GLOBAL.tonumber(moistureceil)
	moisturefloor = GLOBAL.tonumber(moisturefloor)
	preciprate = GLOBAL.tonumber(preciprate)
	peakprecipitationrate = GLOBAL.tonumber(peakprecipitationrate)

	local totalseconds = 0

	while moisture > moisturefloor do
		if preciprate > 0 then
			local p = math.max(0, math.min(1, (moisture - moisturefloor) / (moistureceil - moisturefloor)))
			local rate = MIN_PRECIP_RATE + (1 - MIN_PRECIP_RATE) * math.sin(p * GLOBAL.PI)

			preciprate = math.min(rate, peakprecipitationrate)
			moisture = math.max(moisture - preciprate * GLOBAL.FRAMES * PRECIP_RATE_SCALE, 0)

			totalseconds = totalseconds + GLOBAL.FRAMES
		else
			break
		end
	end

	return world, totalseconds
end

AddUserCommand("predictrain", {
	prettyname = "Predict Rain",
	desc = [[
Forecast rain start or stop.
Modes: 0 for global chat, 1 for whisper chat, 2 for local chat.
]],
	permission = GLOBAL.COMMAND_PERMISSION.USER,
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

		local TheWorld = GLOBAL.TheWorld

		local function Announce(msg)
			GLOBAL.TheNet:Say(string.format("%s %s", GLOBAL.STRINGS.LMB, msg))
		end

		if params.mode ~= nil then
			if params.mode == "1" then
				Announce = function(msg) GLOBAL.TheNet:Say(string.format("%s %s", GLOBAL.STRINGS.LMB, msg), true) end
			elseif params.mode == "2" then
				Announce = function(msg) GLOBAL.ChatHistory:SendCommandResponse(msg) end
			elseif params.mode ~= "0" then
				GLOBAL.ChatHistory:SendCommandResponse(string.format("Invalid mode '%s'; see /help predictrain.", params.mode))
				return
			end
		end


		if TheWorld.state.pop ~= 1 then
			local world, totalseconds, rain = PredictRainStart()

			if rain then
				local d = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
				local m = math.floor(totalseconds / 60)
				local s = totalseconds % 60
	
				Announce(string.format("%s will rain on day %.2f (%dm %ds).", world, d, m, s))
			else
				Announce(string.format("%s will no longer rain this %s.", world, TheWorld.state.season))
			end
		else
			local world, totalseconds = PredictRainStop()

			local d = TheWorld.state.cycles + 1 + TheWorld.state.time + (totalseconds / TUNING.TOTAL_DAY_TIME)
			local m = math.floor(totalseconds / 60)
			local s = totalseconds % 60

			Announce(string.format("%s will stop raining on day %.2f (%dm %ds).", world, d, m, s))
		end
	end,
})
