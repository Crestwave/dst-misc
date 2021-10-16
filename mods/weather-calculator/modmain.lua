-- 1. Calculate the seconds remaining in day and how much moisture will be gained
-- 2. If that is >= moistureceil then the time is (moistureceil-moisture)/moisturerate
-- 3. If it isn't, then add moistureinday to moisture and seconds to totalseconds and repeat for the next day.

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


--min = MOISTURE_RATES.MIN[season]
--max = MOISTURE_RATES.MAX[season]




AddPlayerPostInit(function(inst)
	inst:ListenForEvent("predictrain", function(inst)
		_G = GLOBAL
		TheWorld = _G.TheWorld
		local function CalculateMoistureRate(elapseddaysinseason, daysinseason, season)
			p = 1 - math.sin(_G.PI * (elapseddaysinseason/daysinseason))
			moisturerate = MOISTURE_RATES.MIN[season] + p * (MOISTURE_RATES.MAX[season] - MOISTURE_RATES.MIN[season])
			return moisturerate
		end
		moisture = TheWorld.state.moisture
		moistureceil = TheWorld.state.moistureceil
		remainingsecondsinday = 480 - (TheWorld.state.time*480)
		elapseddaysinseason = TheWorld.state.elapseddaysinseason
		daysinseason = elapseddaysinseason + TheWorld.state.remainingdaysinseason
		season = TheWorld.state.season
		totalseconds = 0

		while elapseddaysinseason <= daysinseason do
			moisturerate = CalculateMoistureRate(elapseddaysinseason, daysinseason, season)
			_moisture = moisture + (moisturerate * remainingsecondsinday)
		
			if _moisture >= moistureceil then
				totalseconds = totalseconds + ((moistureceil - moisture) / moisturerate)
				break
			else
				moisture = _moisture
				remainingsecondsinday = 480
				elapseddaysinseason = elapseddaysinseason + 1
			end
		end

		GLOBAL.TheNet:Say(string.format("%s It will rain in %d seconds", _G.STRINGS.LMB, totalseconds))
	end)
end)
