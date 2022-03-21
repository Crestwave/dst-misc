AddPlayerPostInit(function(inst)
	inst:ListenForEvent("isridingdirty", function(inst)
		if inst.replica.rider:IsRiding() then
			if inst.replica.rider.lastmounted == nil then
				inst.replica.rider.lastmounted = GLOBAL.GetTime()

				inst:DoTaskInTime(0, function(inst)
					mount = inst.replica.rider:GetMount()

					if type(mount) == "table" and mount.prefab == "beefalo" then
						moodmult = mount:HasTag("scarytoprey") and TUNING.BEEFALO_BUCK_TIME_MOOD_MULT or 1
						beardmult = not mount:HasTag("has_beard") and TUNING.BEEFALO_BUCK_TIME_NUDE_MULT or 1
						domesticmult = not mount:HasTag("domesticated") and TUNING.BEEFALO_BUCK_TIME_UNDOMESTICATED_MULT or 1
					end
				end)
			end
		else
			local ridetime = nil

			if inst.replica.rider.lastmounted ~= nil then
				ridetime = GLOBAL.GetTime() - inst.replica.rider.lastmounted
				inst.replica.rider.lastmounted = nil
			end

			if type(mount) == "table" and mount.prefab == "beefalo" and ridetime ~= nil then
				local basedelay = ridetime / moodmult / beardmult / domesticmult
				local domestication = GLOBAL.Remap(basedelay, TUNING.BEEFALO_MIN_BUCK_TIME, TUNING.BEEFALO_MAX_BUCK_TIME, 0, 1)

				if inst.AnimState:IsCurrentAnimation("buck") or inst.AnimState:IsCurrentAnimation("bucked") or inst.AnimState:IsCurrentAnimation("buck_pst") then
					inst.components.talker:Say(string.format("%.2f%%", domestication * 100))
					print(string.format("%s attained %.2fs ride time with \"%s\" (%s domestication)", inst.name, ridetime, mount.name, domestication))
				elseif not mount:HasTag("domesticated") and domestication > 0 then
					inst.components.talker:Say(string.format(">%.2f%%", domestication * 100))
				end
			end
		end
	end)
end)
