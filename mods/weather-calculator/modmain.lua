-- 1. Calculate the seconds remaining in day and how much moisture will be gained
-- 2. If that is >= moistureceil then the time is (moistureceil-moisture)/moisturerate
-- 3. If it isn't, then add moistureinday to moisture and seconds to totalseconds and repeat for the next day.

-- components/weather.lua


--min = MOISTURE_RATES.MIN[season]
--max = MOISTURE_RATES.MAX[season]




AddPlayerPostInit(function(inst)
	inst:ListenForEvent("predictrain", function(inst)
		-- components/weather.lua
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

		local TheWorld = GLOBAL.TheWorld
		local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"

		local season = TheWorld.state.season
		local elapseddaysinseason = TheWorld.state.elapseddaysinseason
		local daysinseason = elapseddaysinseason + TheWorld.state.remainingdaysinseason
		local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (TheWorld.state.time * TUNING.TOTAL_DAY_TIME)

		local moisture = TheWorld.state.moisture
		local moistureceil = TheWorld.state.moistureceil
		local totalseconds = 0

		while elapseddaysinseason <= daysinseason do
			local p = 1 - math.sin(GLOBAL.PI * (elapseddaysinseason/daysinseason))
			local moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])

			local _moisture = moisture + (moisturerate * remainingsecondsinday)
		
			if _moisture >= moistureceil then
				totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
				break
			else
				moisture = _moisture
				totalseconds = totalseconds + remainingsecondsinday
				remainingsecondsinday = 480
				elapseddaysinseason = elapseddaysinseason + 1
			end
		end

		GLOBAL.TheNet:Say(string.format("%s %s will rain in %d seconds.", GLOBAL.STRINGS.LMB, world, totalseconds))
		print(string.format("%s, %s, %s, %s, %s", moisturerate, moisture, moistureceil, remainingsecondsinday, daysinseason))
	end)
end)
