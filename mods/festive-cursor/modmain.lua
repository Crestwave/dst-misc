local _G = GLOBAL
local UIAnim = require "widgets/uianim"

local function KillFX(inst)
	if inst:GetTimeAlive() > 0 then
		inst.killed = true
	else
		inst:Remove()
	end
end

local function IsMovingStep(step)
	return step ~= 0 and step ~= 3
end

local function OnSnowflakeAnimOver(inst)
	inst:Remove()
end

local function CreateSnowflake(snowflakeemitter, variation, step)
	local anim = _G.TheFrontEnd.overlayroot:AddChild(UIAnim())
	local inst = anim.inst

	anim:SetScale(.35, .35)

	inst:AddTag("FX")
	inst.AnimState:SetBank("lantern_winter_fx")
	inst.AnimState:SetBuild("lantern")
	inst.AnimState:OverrideItemSkinSymbol("snowflake", "lantern_winter", "snowflake", 0, "lantern")
	inst.AnimState:SetFinalOffset(1)

	inst.snowflakeemitter = snowflakeemitter
	inst.anim = "snowfall"..tostring(variation)
	inst.step = step
	inst:ListenForEvent("animover", OnSnowflakeAnimOver)
	inst.AnimState:PlayAnimation(inst.anim)
	anim:SetPosition(snowflakeemitter.widget:GetPosition())

	return inst
end

local function CheckMoving(inst)
	local newpos = _G.TheInput:GetScreenPosition()
	inst.ismoving = inst.prevpos ~= nil and inst.prevpos ~= newpos
	inst.prevpos = newpos
end

AddGamePostInit(function()
	local anim = _G.TheFrontEnd.overlayroot:AddChild(UIAnim())
	local inst = anim.inst

	inst:AddTag("FX")
		inst.ismoving = false
		inst:DoPeriodicTask(0, CheckMoving)

	inst:DoTaskInTime(3, function(inst)
		local variation = 1
		local step = 1

		_G.TheInput:AddMoveHandler(function(x, y)
			variation = (variation + 1) % 8
			step = (step + 1) % 6
			CreateSnowflake(inst, variation, step)
			anim:SetPosition(x, y)
		end)
	end)
end)
