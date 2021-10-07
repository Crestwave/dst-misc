AddPlayerPostInit(function(inst)
	inst:ListenForEvent("isridingdirty", function(inst)
		if inst.replica.rider._isriding:value() then
			if lastmounted == nil then
				lastmounted = GLOBAL.GetTime()

				inst:DoTaskInTime(GLOBAL.FRAMES, function(inst)
					mount = inst.replica.rider.classified ~= nil and inst.replica.rider.classified.ridermount:value()
				end)
			end
		else
			local ridetime = nil

			if lastmounted ~= nil then
				ridetime = GLOBAL.GetTime() - lastmounted
				lastmounted = nil
			end

			if mount ~= nil and type(mount) ~= "boolean" and ridetime ~= nil then
				if mount.prefab ~= "beefalo" then return end

				local moodmult = mount:HasTag("scarytoprey") and TUNING.BEEFALO_BUCK_TIME_MOOD_MULT or 1
				local beardmult = not mount:HasTag("has_beard") and TUNING.BEEFALO_BUCK_TIME_NUDE_MULT or 1
				local domesticmult = not mount:HasTag("domesticated") and TUNING.BEEFALO_BUCK_TIME_UNDOMESTICATED_MULT or 1

				local basedelay = ridetime / moodmult / beardmult / domesticmult
				local domestication = GLOBAL.Remap(basedelay, TUNING.BEEFALO_MIN_BUCK_TIME, TUNING.BEEFALO_MAX_BUCK_TIME, 0, 1)

				if inst.AnimState:IsCurrentAnimation("buck") or inst.AnimState:IsCurrentAnimation("buck_pst") then
					inst.components.talker:Say(string.format("%.2f%%", domestication * 100))
					print(string.format("Recorded %.2f second ride time for \"%s\" (%s domestication)", ridetime, mount.name, domestication))
				elseif not mount:HasTag("domesticated") and domestication > 0 then
					inst.components.talker:Say(string.format(">%.2f%%", domestication * 100))
				end
			end
		end
	end)
end)
