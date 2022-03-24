--[[
Auto-Save Manager v5 
By CossonWool 

Made with PersistentData v1.2 By Blueberrys 
PersistentData: http://forums.kleientertainment.com/files/file/1150-persistent-data/ 
Blueberrys: https://forums.kleientertainment.com/profile/484324-blueberrys/ 

Consider using the original PersistentData file if you make your own Auto-Save Manager. 
This file initially couldn't use it since it was storing nested tables, 
    and PersistentData doesn't have an easy way to access nested tables. 
    However now that everything has numerical keys it should be a practical option again. 
For WX-78 Charge Predictor's Auto-Save Manager it's still impractical to use PersistentData because it has old data, 
    and the old data can easily cause bugs (see checkcompatibility).
]]

--------------------------------------------------------------------------- trim, Set, Save, & Load functions from PersistentData

local function trim(s)
	return s:match'^%s*(.*%S)%s*$' or ''
end

local function Set(self, str)
	if str and trim(str) ~= "" then
		self.persistdata = json.decode(str)
	end
end

local function Save(self)
	local str = json.encode(self.persistdata)
	local insz, outsz = SavePersistentString(self.savename, str, ENCODE_SAVES)
end

local function Load(self)
	TheSim:GetPersistentString(self.savename,
		function(load_success, str)
			if load_success then
				Set(self, str)
			end
		end, false)
end

--------------------------------------------------------------------------- backward compatibility

-- There have been a few bugs regarding old data.
-- This amount of checking isn't required but it only runs on load so we make 100% sure things are ok here.
local function checkcompatibility(self)
	if type(self.persistdata) ~= "table" then
		self.persistdata = {}
	else
		-- Try save outdated shard data
		if self.persistdata.sd then
			self.persistdata[1] = self.persistdata.sd
			self.persistdata.sd = nil
		end
		-- Try save outdated rollback data
		if self.persistdata.rd then
			local num_saves = #self.persistdata.rd <= self.maxsaveslots and #self.persistdata.rd or self.maxsaveslots
			for i = 1, num_saves do
				self.persistdata[i + 1] = self.persistdata.rd[i]
			end
			self.persistdata.rd = nil
		end
		-- Delete any data that doesn't have a number index, isn't a table, or doesn't have an associated time
		for index, data in pairs(self.persistdata) do
			if type(index) ~= "number" or type(data) ~= "table" or type(data.time) ~= "number" then
				self.persistdata[index] = nil
			end
		end
		-- Make sure there aren't any holes in the list. Delete everything after a hole
		local do_delete = false
		for i = 1, #self.persistdata do
			if not self.persistdata[i] then
				do_delete = true
			elseif do_delete then
				self.persistdata[i] = nil
			end
		end
	end
end

--------------------------------------------------------------------------- private functions

local function caneditdata(self)
	if self.savenamevalid then
		return true
	end
	
	if TheWorld and TheWorld.net and TheWorld.net.components.shardstate then
		if BRANCH ~= "release" then
			self.savename = self.savename.."_"..BRANCH
		end
		
		self.savename = self.savename.."_save"..tostring(TheWorld.net.components.shardstate:GetMasterSessionId())
		self.savenamevalid = true
		
		Load(self)
		
		checkcompatibility(self)
		
		return true
	end
		
	return false
end

local function makesavedata(self)
	return {
		time 		= TheWorld.state.time + TheWorld.state.cycles,
		save_data 	= self.savefn(self.savefnargs),
	}
end

local function shardsave(self)
	if not caneditdata(self) then
		return
	end
	
	self.persistdata[1] = makesavedata(self)
	
	Save(self)
end

local function autosave(self)
	if not caneditdata(self) then
		return
	end
	
	local saves = #self.persistdata
	
	-- let self.maxsaveslots + 1 saves exist, because [1] is special
	if saves > self.maxsaveslots then
		saves = self.maxsaveslots
	end
	
	-- pull data towards [2] and save new data at [2]
	for i = saves, 2, -1 do
		self.persistdata[i + 1] = self.persistdata[i]
	end
	
	-- always save [1], autosave goes in [2] also
	self.persistdata[1] = makesavedata(self)
	self.persistdata[2] = self.persistdata[1]
	
	Save(self)
end

local function deletedatatoindex(self, index)
	if not caneditdata(self) then
		return
	end
	
	if index >= #self.persistdata then
		self.persistdata = {}
	else
		if index > 1 then -- index 1 only deletes shard data; [1]
			-- pull data to [2]..[#self.persistdata - index]
			for i = 1, #self.persistdata - index do
				self.persistdata[i + 1] = self.persistdata[i + index]
			end
			
			-- remove all old data
			for i = #self.persistdata - index + 1, #self.persistdata - 1 do
				self.persistdata[i + 1] = nil
			end
		end
		
		-- this "deletes" [1]. Since we need to maintain the list set it to be [2]
		self.persistdata[1] = self.persistdata[2]
	end
	
	Save(self)
end

--------------------------------------------------------------------------- class

local AutoSaveManager = Class(function(self, savename, autosavefn, savefnargs)
	assert(savename ~= nil, "AutoSaveManager requires a unique data key")
	assert(autosavefn ~= nil, "AutoSaveManager requires an autosave function")
	
	self.savename = savename
	self.persistdata = {}
	
	self.maxsaveslots = 7 -- game holds 6 rollbacks, store an extra saveslot by default for if something goes wrong
	self.futureallowance = -3 / TUNING.TOTAL_DAY_TIME
	
	self.savenamevalid = false
	self.setup = false
	
	self.savefn = autosavefn
	self.savefnargs = savefnargs
end)

--------------------------------------------------------------------------- main functions

function AutoSaveManager:LoadData()
	if not caneditdata(self) then
		return
	end
	
	local world_time = TheWorld.state.cycles + TheWorld.state.time
	local best_index = 0
	
	for i = 1, #self.persistdata do
		if world_time - self.persistdata[i].time < self.futureallowance then
			-- data that was created in the future, ignore it, deleted in deletedatatoindex
		elseif best_index == 0 then
			best_index = i
		elseif math.abs(world_time - self.persistdata[i].time) < math.abs(world_time - self.persistdata[best_index].time) then
			best_index = i
		else
			-- past the most current data point, everything else is older data
			break
		end
	end
	
	if best_index == 0 then	
		-- No valid data found, delete everything
		deletedatatoindex(self, #self.persistdata)
	elseif best_index == 1 then
		-- Best data is the most recent data, simply return
		return self.persistdata[1].save_data, self.persistdata[1].time
	elseif best_index > 1 then
		-- Rollback data is best, we should remove data from before it
		deletedatatoindex(self, best_index - 1)
		return self.persistdata[2].save_data, self.persistdata[2].time
	end
	
	return nil, nil
end

--------------------------------------------------------------------------- event listeners, setup stuff

function AutoSaveManager:StartAutoSave()
	if self.setup or not TheWorld then
		return
	else
		self.setup = true
	end
	
	-- calls when disconnected, calls when you're the host and ThePlayer.HUD.controls.saving doesn't call
	local old_DoRestart = DoRestart
	
	function DoRestart(save)
		if TheWorld then
			autosave(self)
		end
		
		old_DoRestart(save)
	end
	
	-- setup SavingIndicator, called when autosaves happen
	local function setupautosave()
		if not ThePlayer or not ThePlayer.HUD then
			return
		end
		
		local hud_saving = ThePlayer.HUD.controls.saving
		
		if not hud_saving.client_autosave_setup then
			hud_saving.client_autosave_setup = true
			
			local old_StartSave = hud_saving.StartSave
			
			hud_saving.StartSave = function(self)
				TheWorld:PushEvent("client_autosave")
				
				old_StartSave(self)
			end
		end
	end
	
	setupautosave()
	
	-- used for if StartAutoSave is called pre player, and portal spawn
	TheWorld:ListenForEvent("playeractivated", function(_TheWorld, _ThePlayer)
		if ThePlayer == _ThePlayer then
			setupautosave()
		end
	end)
	
	-- Main calls happen on shard change, portal despawn, and commands like c_rollback()
	TheWorld:ListenForEvent("playerdeactivated", function(_TheWorld, _ThePlayer)
		if ThePlayer and ThePlayer == _ThePlayer then
			shardsave(self)
		end
	end)
	
	-- Pushed by SavingIndicator, on autosaves
	TheWorld:ListenForEvent("client_autosave", function()
		autosave(self)
	end)
end

--------------------------------------------------------------------------- debug

function AutoSaveManager:PrintDebugInfo(delete_data)
	if not caneditdata(self) then
		print("[AutoSaveManager] Data couldn't be retrieved")
		return
	end
	
	if delete_data then
		print("[AutoSaveManager] Deleting data")
		self.persistdata = {}
		Save(self)
	end
	
	if self.persistdata[1] then
		print("[AutoSaveManager] Printing data in save "..self.savename)
		
		for i = 1, #self.persistdata do
			if self.persistdata[i] then
				print("[AutoSaveManager] Index: "..tostring(i).." Time: "..tostring(self.persistdata[i].time).." Data: "..tostring(self.persistdata[i].save_data))
			else
				print("[AutoSaveManager] Index: "..tostring(i).." WARNING: This index is a hole. Data was expected but nothing is saved.")
			end
		end
	else
		print("[AutoSaveManager] There is no saved data in save "..self.savename)
	end
end

--------------------------------------------------------------------------- return

return AutoSaveManager
