-- burned is a table of items and structures that have been burned away, indexed by GUID
burned = {}

local function OnSave(self)
    data = {}
	if self.OldOnSave ~= nil then
		data = self.OldOnSave(self)
    end
	if self.inst.builtbyid ~= nil and self.inst.builtbyname ~= nil then
        data.builtbyname = self.inst.builtbyname
        data.builtbyid = self.inst.builtbyid
    end
    return data
end

local function OnLoad(self, data)
	if self.OldOnLoad ~= nil then
		self.OldOnLoad(self, data)
	end
	if data ~= nil and data.builtbyid ~= nil and data.builtbyname ~= nil then
        self.inst.builtbyid = data.builtbyid
        self.inst.builtbyname = data.builtbyname
	end
end

-- this is to save/load items waiting for a rollback
local function WorldOnSave(self)
    data = {}
	if self.OldOnSave ~= nil then
		data = self.OldOnSave(self)
    end
    if burned ~= nil then
        data.burned = burned
    end
    return data
end

local function WorldOnLoad(self, data)
	if self.OldOnLoad ~= nil then
		self.OldOnLoad(self, data)
    end
    if data ~= nil and data.burned ~= nil then
        burned = data.burned
	end
end

-- regrowthmanager is going to keep track of all entities that have been burned away (the burned table)
-- aka my global variables are going to be saved here.
AddComponentPostInit("regrowthmanager", function(self, inst)
    self.OldOnSave = self.OnSave
    self.OnSave = WorldOnSave
    self.OldOnLoad = self.OnLoad
    self.OnLoad = WorldOnLoad
end)

local old_DefaultBurnt = GLOBAL.DefaultBurntFn
local old_DefaultBurntStructure = GLOBAL.DefaultBurntStructureFn

-- when an item burns (ashes are left)
GLOBAL.DefaultBurntFn = function(inst)
    GLOBAL.pcall(function(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local burnedobject = {}
        burnedobject.prefab = inst.prefab
        if inst.components.stackable then
            burnedobject.amount = inst.components.stackable.stacksize
        end
        burnedobject.builtbyid = inst.builtbyid
        burnedobject.builtbyname = inst.builtbyname
        burnedobject.x = x
        burnedobject.z = z
        burned[inst.GUID] = burnedobject
    end, inst)
    return old_DefaultBurnt(inst)
end

-- when a structure burns (black burnt structure is left)
GLOBAL.DefaultBurntStructureFn = function(inst)
    GLOBAL.pcall(function(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local burnedobject = {}
        burnedobject.prefab = inst.prefab
        burnedobject.builtbyid = inst.builtbyid
        burnedobject.builtbyname = inst.builtbyname
        burnedobject.x = x
        burnedobject.z = z
        burned[inst.GUID] = burnedobject
    end, inst)
    return old_DefaultBurntStructure(inst)
end