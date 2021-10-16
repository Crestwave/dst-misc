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
		local remainingsecondsinday = TUNING.TOTAL_DAY_TIME - (TheWorld.state.time * TUNING.TOTAL_DAY_TIME)
		local totalseconds = 0
		local rain = false

		local season = TheWorld.state.season
		local elapseddaysinseason = TheWorld.state.elapseddaysinseason
		local totaldaysinseason = elapseddaysinseason + TheWorld.state.remainingdaysinseason

		local moisture = TheWorld.state.moisture
		local moistureceil = TheWorld.state.moistureceil

		while elapseddaysinseason <= totaldaysinseason do
			local moisturerate

			if world == "Surface" and season == "winter" and elapseddaysinseason == 2 then
				moisturerate = 50
			else
				local p = 1 - math.sin(GLOBAL.PI * (elapseddaysinseason / totaldaysinseason))
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
			end
		end

		if rain then
			GLOBAL.TheNet:Say(string.format("%s %s will rain in %d seconds.", GLOBAL.STRINGS.LMB, world, totalseconds))
		else
			GLOBAL.TheNet:Say(string.format("%s %s will no longer rain this %s.", GLOBAL.STRINGS.LMB, world, season))
		end
		--print(string.format("%s, %s, %s, %s, %s", moisturerate, moisture, moistureceil, remainingsecondsinday, totaldaysinseason))
	end)
end)
