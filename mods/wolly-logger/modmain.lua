--modimport("tweaks.lua")
modimport("persistent.lua")
--modimport("extracommands.lua")

io = GLOBAL.require("io")

GLOBAL.global("fileopened")
GLOBAL.global("logfile")
GLOBAL.fileopened = false
GLOBAL.logfile = false

local discord_enabled = false

-- UNUSED: nature_destroyed is a table of strictly naturally occuring objects that have been removed by players (eg. trees, grass, twigs, flowers, carrots)
-- perhaps an effort will be made in the future to restore them periodically
local nature_destroyed = {}

-- UNUSED: artificial_destroyed is a table of artificial structures (built, planted) by players. It is a table of tables, indexed by userid of the person that removed the object
-- the idea is to be able to restore a base if it gets hammered
local artificial_destroyed = {}

--UNUSED: 
local player_inventory = {}
-- item cache of containers that are currently open
-- when they are closed, it does a diff and sees what items were added and removed
local container_cache = {}

local valuables = {}
valuables["deerclops_eyeball"] = true
valuables["minotaurhorn"] = true
valuables["gears"] = true
valuables["mandrake"] = true
valuables["cookedmandrake"] = true

if (GetModConfigData("discord") == "yes") then
    discord_enabled = true
end

AddSimPostInit(function()
    -- Initialization of the log file --
    GLOBAL.pcall(function()
        if (not GLOBAL.fileopened and GLOBAL.TheWorld.ismastersim) then
            local servername = GLOBAL.TheNet:GetServerName()
            servername = GLOBAL.string.gsub(servername, ':','')
            -- TODO: add code to backup files here
            local filename = servername .. "-caveslog.txt"
            if (GLOBAL.TheShard:IsMaster()) then
                filename = servername .. "-overworldlog.txt"
            end
            GLOBAL.logfile = io.open(filename, "w")
            io.output(GLOBAL.logfile)
            GLOBAL.fileopened = true
        end
    end)
    
    -- called when an announcement gets printed
    local old_Announce = GLOBAL.Networking_Announcement
    GLOBAL.Networking_Announcement = function(message, colour, announce_type)
        GLOBAL.pcall(function(message, colour, announce_type)
            local logstring = message
            logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
            if (GetModConfigData("leavejoin") == "all") then
            print(logstring)
            end
            if discord_enabled and (GetModConfigData("discordleavejoin") == "all") then
                io.write("[" .. GLOBAL.os.date("%x %X") .. "] :loudspeaker: " .. logstring .. "\n")
            end
        end, message, colour, announce_type)
        return old_Announce(message, colour, announce_type)
    end
    -- announce gift
    local old_AnnounceGift = GLOBAL.Networking_SkinAnnouncement
    GLOBAL.Networking_SkinAnnouncement = function(user_name, user_colour, skin_name)
        GLOBAL.pcall(function(user_name, user_colour, skin_name)
            local logstring = user_name .. " opens gift: " .. skin_name
            logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
            if (GetModConfigData("gift") == "all") then
            print(logstring)
            end
            if discord_enabled and (GetModConfigData("discordgift") == "all") then
                io.write("[" .. GLOBAL.os.date("%x %X") .. "] :gift: " .. logstring .. "\n")
            end
        end, user_name, user_colour, skin_name)
        return old_AnnounceGift(user_name, user_colour, skin_name)
    end
    -- announce diceroll
    local old_AnnounceRoll = GLOBAL.Networking_RollAnnouncement
    GLOBAL.Networking_RollAnnouncement = function(userid, name, prefab, colour, rolls, max)
        GLOBAL.pcall(function(userid, name, prefab, colour, rolls, max)
            local logstring = name .. " rolls " .. table.concat(rolls, ", ")
            logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
            if (GetModConfigData("dice") == "all") then
            print(logstring)
            end
            if discord_enabled and (GetModConfigData("discorddice") == "all") then
                io.write("[" .. GLOBAL.os.date("%x %X") .. "] :dice: " .. logstring .. "\n")
            end
        end, userid, name, prefab, colour, rolls, max)
        return old_AnnounceRoll(userid, name, prefab, colour, rolls, max)
    end

    -- this is to make player inventories accessible even after they log off
   --[[  GLOBAL.TheWorld:ListenForEvent("ms_playerleft", function(world, player)
        if player.components ~= nil and player.components.inventory ~= nil then
            player_inventory[player.userid] = {}
            local inv = player.components.inventory
            local i = 0
            print("item slots: " .. #inv.itemslots)
            for k,v in pairs(inv.itemslots) do
                print("saving " .. v.prefab)
                if v.components ~= nil and v.components.stackable ~= nil then
                    player_inventory[player.userid][i] = {prefab = v.prefab, amount = v.components.stackable.stacksize}
                else
                    player_inventory[player.userid][i] = {prefab = v.prefab}
                end
                i = i + 1
            end
            print("saved inventory successfully")
        else
            print("no inventory")
        end
        --local logstring = player:GetDisplayName() .. "[" .. player.userid .. "] has left the game."
        --io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. logstring .. "\n")
        --print(logstring)
    end) ]]
end)

-- helper function to log actions from the actions.lua file
local function logdebugaction(act, obj, desc, emoji)
    local theemoji = ""
    local id = "[" ..act.doer.GUID .. "]"
    local otherid = "[" .. obj.GUID .. "]"
    local amount = ""
    local ownedby = ""
    local discord_ownedby = ""
    local chef = ""
    local discord_chef = ""
    if (act.doer ~= nil and act.doer:GetDisplayName() ~= nil and obj ~= nil and obj:GetDisplayName() ~= nil) then
        if act.doer.userid ~= nil then
            id = "[" .. act.doer.userid .. "]"
        end
        if obj.components.stackable then
            amount = " (x" .. obj.components.stackable.stacksize .. ")"
        end
        if (emoji ~= nil) then
            theemoji = emoji
        end
        if (obj.builtbyid ~= nil and obj.builtbyname ~= nil) then
            ownedby = " Owner: " .. obj.builtbyname .. "[" .. obj.builtbyid .. "]"
            discord_ownedby = " :key: " .. ownedby
        end
        if (obj.cookedbyid ~= nil and obj.cookedbyname ~= nil) then
            chef = " Chef: " .. obj.cookedbyname .. "[" .. obj.cookedbyid .. "]"
            discord_chef = " :man_cook: " .. chef
        end

        local pos = tostring(act:GetActionPoint() or string.format("(%.2f, %.2f, %.2f)", obj.Transform:GetWorldPosition()))
        local logstring = act.doer:GetDisplayName() .. id .. desc .. obj:GetDisplayName() .. otherid .. amount .. ownedby .. chef .. " @" .. pos
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = theemoji .. act.doer:GetDisplayName() .. id .. desc .. obj:GetDisplayName() .. otherid .. amount .. discord_ownedby .. discord_chef
        if (desc == " eats " and (GetModConfigData("eating") == "all" or GetModConfigData("eating") == "valuables" and valuables[obj.prefab] ~= nil) or
            (desc == " lights " or desc == " uses firestaff on ") and GetModConfigData("lighting") == "all" or
            desc == " picks up " and (GetModConfigData("pickup") == "all" or GetModConfigData("pickup") == "theft" and obj.builtbyid ~= nil and act.doer.userid ~= nil and obj.builtbyid ~= act.doer.userid) or
            desc == " casts spell " and GetModConfigData("reading") == "all" or
            desc == " casts " or
            desc == " picks " and (GetModConfigData("picking") == "all" or GetModConfigData("picking") == "flower" and obj:HasTag("flower")) or 
            desc == " steals from " and GetModConfigData("crockpot") == "all") then
        print(logstring)
        end
        --if desc ~= " eats " and (desc ~= " picks up " or (act.doer.userid == nil or (obj.builtbyid ~= nil and act.doer.userid ~= nil and obj.builtbyid ~= act.doer.userid))) then
        if discord_enabled and 
            (desc == " eats " and (GetModConfigData("discordeating") == "all" or GetModConfigData("discordeating") == "valuables" and valuables[obj.prefab] ~= nil) or
            (desc == " lights " or desc == " uses firestaff on ") and GetModConfigData("discordlighting") == "all" or
            desc == " picks up " and (GetModConfigData("discordpickup") == "all" or GetModConfigData("discordpickup") == "theft" and obj.builtbyid ~= nil and act.doer.userid ~= nil and obj.builtbyid ~= act.doer.userid) or
            desc == " casts spell " and GetModConfigData("discordreading") == "all" or
            desc == " casts " or
            desc == " picks " and (GetModConfigData("discordpicking") == "all" or GetModConfigData("discordpicking") == "flower" and obj:HasTag("flower")) or 
            desc == " steals from " and GetModConfigData("discordcrockpot") == "all") then
                io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
    end
end




-- when something is ignited
local function newOnIgnite(self, immediate, source, doer)
    GLOBAL.pcall(function(self, immediate, source, doer)
        local causer = "unknown"
        local ownedby = ""
        -- check if it's some random source like a torch or firepit that doesn't cause a fire on its own, don't want to hear it every time a torch is equipped
        if self.inst.prefab == "lighter" or self.inst.prefab == "torch" or self.inst.prefab == "nightstick"
        or self.inst.prefab == "campfire" or self.inst.prefab == "nightlight" or self.inst.prefab == "pigtorch" 
        or self.inst.prefab == "firepit" or self.inst.prefab == "coldfirepit" or self.inst.prefab == "coldfire" then
            return
        end
        if self.inst.litbyid == nil then
            -- don't know what lit the object
            if source ~= nil and source:GetDisplayName() ~= nil then
                self.inst.litbyid = source.userid or source.GUID
                self.inst.litbyname = source:GetDisplayName()
                self.inst.originalid = self.inst.GUID
                self.inst.originalname = self.inst:GetDisplayName()
                causer = self.inst.litbyname .. "[" .. self.inst.litbyid .. "]" .. " lighting " .. self.inst:GetDisplayName() .. "[" .. self.inst.GUID .. "]"
            end
        else
            causer = self.inst.litbyname .. "[" .. self.inst.litbyid .. "]" .. " lighting " .. self.inst.originalname .. "[" .. self.inst.originalid .. "]"
        end
        if self.inst.builtbyname ~= nil and self.inst.builtbyid ~= nil then
            ownedby = " Owner: " .. self.inst.builtbyname .. "[" .. self.inst.builtbyid .. "]"
        end
        local source_string =  " Source: " .. causer .. ownedby
        local logstring = self.inst:GetDisplayName() .. "[" .. self.inst.GUID .. "]" .. " combusts!"
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = ":fire: " .. logstring .. " :oil: " .. source_string
        logstring = logstring .. source_string
        if (ownedby ~= "") then
            discord_logstring = "**" .. discord_logstring .. "**"
        end
        if (self.inst.components and self.inst.components.burnable and not self.inst.components.burnable:IsBurning()) then
            if GetModConfigData("fire") == "all" 
                or (GetModConfigData("fire") == "player" and source ~= nil and source.userid ~= nil)
                or (GetModConfigData("fire") == "playerbuilt" and ownedby ~= "")
                or (GetModConfigData("fire") == "ignoretree" and (self.inst.prefab ~= "evergreen" and self.inst.prefab ~= "deciduoustree")) then
            print(logstring)
            end
            if discord_enabled and (GetModConfigData("discordfire") == "all"
                or (GetModConfigData("discordfire") == "player" and source ~= nil and source.userid ~= nil)
                or (GetModConfigData("discordfire") == "playerbuilt" and ownedby ~= "")
                or (GetModConfigData("discordfire") == "ignoretree" and (self.inst.prefab ~= "evergreen" and self.inst.prefab ~= "deciduoustree"))) then
                    io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
        end
    end, self, immediate, source, doer)
end

-- TODO: Check the actual propagation range for each ent
local function newOnSmolder(self)
    GLOBAL.pcall(function(self)
        local prop_range = 8 
        local x,y,z = self.inst.Transform:GetWorldPosition()
        -- check to see what entities may have started the fire
        local ents = GLOBAL.TheSim:FindEntities(x, y, z, prop_range, nil, { "INLIMBO" })
        local causer = "unknown"
        local foundSource = false
        if #ents > 0 then
            for i, v in ipairs(ents) do
                if (v.litbyid ~= nil and v.litbyname ~= nil and v.components and (v.components.burnable and v.components.burnable:IsBurning() or v.prefab == "campfire")) then
                    causer = v.litbyname .. "[" .. v.litbyid .. "]"
                    self.inst.litbyname = v.litbyname
                    self.inst.litbyid = v.litbyid
                    self.inst.originalid = v.originalid
                    self.inst.originalname = v.originalname
                    foundSource = true
                end
            end
        end
        -- this is probably not necessary
        if not foundSource then
            self.inst.litbyname = nil
            self.inst.litbyid = nil
            self.inst.originalid = nil
            self.inst.originalname = nil
        end
    end, self)
end

AddComponentPostInit("burnable", function(self, inst)
    local oldWildfire = self.StartWildfire
    self.StartWildfire = function(self)
        newOnSmolder(self)
        return oldWildfire(self)
    end

    local oldIgnite = self.Ignite
    self.Ignite = function(self, immediate, source, doer)
        newOnIgnite(self, immediate, source, doer)
        return oldIgnite(self, immediate, source, doer)
    end
end)

local function newExplosion(self)
    -- possible bug: this function is setting the lit flags within all objects in range but there's no check afterwards for the object actually being ignited
    GLOBAL.pcall(function(self)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, self.explosiverange, nil, { "INLIMBO" })
        for i, v in ipairs(ents) do
            if v ~= self.inst and v:IsValid() and not v:IsInLimbo() then
                if v:IsValid() and not v:IsInLimbo() then
                    if self.lightonexplode and
                        v.components.fueled == nil and
                        v.components.burnable ~= nil and
                        not v.components.burnable:IsBurning() and
                        not v:HasTag("burnt") then
                            v.litbyname = self.inst.litbyname
                            v.litbyid = self.inst.litbyid
                            v.originalname = self.inst:GetDisplayName()
                            v.originalid = self.inst.GUID
                    end
                end
            end
        end
    end, self)
end

AddComponentPostInit("explosive", function(self, inst)
    local old_onBurnt = self.OnBurnt
    self.OnBurnt = function(self)
        newExplosion(self)
        return old_onBurnt(self)
    end
end)

--
-- MODIFIED ACTIONS
--

local old_READ = GLOBAL.ACTIONS.READ.fn
local old_LIGHT = GLOBAL.ACTIONS.LIGHT.fn
local old_PICK = GLOBAL.ACTIONS.PICK.fn
local old_COOK = GLOBAL.ACTIONS.COOK.fn
local old_HARVEST = GLOBAL.ACTIONS.HARVEST.fn
local old_ATTACK = GLOBAL.ACTIONS.ATTACK.fn
local old_PICKUP = GLOBAL.ACTIONS.PICKUP.fn
local old_CASTSPELL = GLOBAL.ACTIONS.CASTSPELL.fn
local old_BLINK = GLOBAL.ACTIONS.BLINK.fn

GLOBAL.ACTIONS.READ.fn = function(act)
    -- wurt can read books so fix this later
    local successful = old_READ(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.target or act.invobject
        if successful then
            if obj.prefab == "book_brimstone" then
                logdebugaction(act, obj, " casts spell ", ":sparkles: ")
                local x,y,z = act.doer.Transform:GetWorldPosition()
                local ents = GLOBAL.TheSim:FindEntities(x, y, z, 30, {"player"}, { "INLIMBO" })
                local victim_count = 0
                for i,v in ipairs(ents) do
                    if (v.prefab ~= "wx78" and v ~= act.doer) then
                        victim_count = victim_count + 1
                    end
                end
                if victim_count > 0 then
                    if GetModConfigData("reading") == "all" then
                    print(victim_count .. " non-WX78 players were nearby!**")
                    end
                    if discord_enabled and GetModConfigData("discordreading") == "all" then
                    io.write("[" .. GLOBAL.os.date("%x %X") .. "] ** :sparkles: " .. victim_count .. " non-WX78 players were nearby!**\n")
                end
                end
            elseif (obj.prefab == "book_tentacles") then
                logdebugaction(act, obj, " casts spell ", ":sparkles: ")
                local x,y,z = act.doer.Transform:GetWorldPosition()
                local ents = GLOBAL.TheSim:FindEntities(x, y, z, 30, nil, { "INLIMBO" })
                for i,v in ipairs(ents) do
                    if (v.prefab == "multiplayer_portal") then
                        if GetModConfigData("reading") == "all" then
                        print("Tentacles were spawned near the portal!")
                        end
                        if discord_enabled and GetModConfigData("discordreading") == "all" then
                        io.write("[" .. GLOBAL.os.date("%x %X") .. "] ** :sparkles: Tentacles were spawned near the portal!**\n")
                    end
                end
            end
        end
        end
    end, successful, act)
    return successful
end


GLOBAL.ACTIONS.LIGHT.fn = function(act)
    -- have to set the burn flags early because the ignite() function will print who burned them and that happens DURING the actions.light() function
    GLOBAL.pcall(function(act)
        local obj = act.target
        obj.litbyname = act.doer:GetDisplayName()
        obj.litbyid = act.doer.userid
        obj.originalid = obj.GUID
        obj.originalname = obj:GetDisplayName()
        -- bug: the ACTIONS.LIGHT will get printed even if it fails
        -- I see no way around this, because if the light action gets printed AFTER it completes, it will look weird with the object igniting before it gets lit on fire
        -- ex. it will look like this:
        -- Object X combusts!
        -- Player Y lights object X
        -- it should be in the opposite order
        logdebugaction(act, obj, " lights ", ":candle: ")
    end, act)
    local successful = old_LIGHT(act)
    GLOBAL.pcall(function(successful, act)
        if successful then
            local obj = act.target
            if (obj.builtbyid ~= nil) then
                act.doer.griefer = true
            end
        else
            -- if the light action fails
            obj.litbyname = nil
            obj.litbyid = nil
            obj.originalid = nil
            obj.originalname = nil
        end
    end, successful, act)
    return successful
end

-- this just checks to see if the player is picking flowers planted by other people

GLOBAL.ACTIONS.PICK.fn = function(act)
    local successful = old_PICK(act)
    GLOBAL.pcall(function(successful, act)
        if successful then
            local obj = act.target
                logdebugaction(act, obj, " picks ", ":arrow_heading_up: ")
            end
    end, successful, act)
    return successful
end


GLOBAL.ACTIONS.COOK.fn = function(act)
    local successful = old_COOK(act)
    GLOBAL.pcall(function(successful, act)
        if successful then
            local obj = act.target
            obj.cookedbyid = act.doer.userid or act.doer.GUID
            obj.cookedbyname = act.doer:GetDisplayName()
        end
    end, successful, act)
    return successful
end


GLOBAL.ACTIONS.HARVEST.fn = function(act)
    local successful = old_HARVEST(act)
    GLOBAL.pcall(function(successful, act)
        if successful then
            local obj = act.target
            if obj.cookedbyid ~= nil and obj.cookedbyname ~= nil and obj.cookedbyid ~= act.doer.userid or obj.prefab == "birdcage" then
                logdebugaction(act, obj, " steals from ", ":spy: ")
            end
        end
    end, successful, act)
    return successful
end

local old_EATITEM = GLOBAL.ACTIONS.EAT.fn
GLOBAL.ACTIONS.EAT.fn = function(act)
    local successful = old_EATITEM(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.target or act.invobject
        if successful then
            logdebugaction(act, obj, " eats ", ":fork_and_knife: ")
        end
    end, successful, act)
    return successful
end

-- this function is pretty much just used for listening in on firestaff actions
GLOBAL.ACTIONS.ATTACK.fn = function(act)
    GLOBAL.pcall(function(act)
        local obj = act.target
        if obj ~= nil and act.doer ~= nil and act.doer.components ~= nil and act.doer.components.combat ~= nil then
            local weapon = act.doer.components.combat:GetWeapon()
            if weapon ~= nil and weapon.prefab == "firestaff" then
                obj.litbyname = act.doer:GetDisplayName()
                obj.litbyid = act.doer.userid
                obj.originalid = obj.GUID
                obj.originalname = obj:GetDisplayName()
            end
        end
    end, act)
    local successful = old_ATTACK(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.target
        if successful then
            local weapon = nil
            if act.doer ~= nil and act.doer.components ~= nil and act.doer.components.combat ~= nil then
                weapon = act.doer.components.combat:GetWeapon()
            end
            if weapon ~= nil and weapon.prefab == "firestaff" then
                logdebugaction(act, obj, " uses firestaff on ", ":fire:")
            end
        else
            obj.litbyname = nil
            obj.litbyid = nil
            obj.originalid = nil
            obj.originalname = nil
        end
    end, successful, act)
    return successful
end

-- detects if someone picks up something that does not belong to them

GLOBAL.ACTIONS.PICKUP.fn = function(act)
    local successful = old_PICKUP(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.target
        if successful then
            logdebugaction(act, obj, " picks up ", ":arrow_up: ")
        end
    end, successful, act)
    return successful
end

GLOBAL.ACTIONS.CASTSPELL.fn = function(act)
    local successful = old_CASTSPELL(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if successful then
            logdebugaction(act, obj, " casts ", ":magic_wand: ")
        end
    end, successful, act)
    return successful
end

GLOBAL.ACTIONS.BLINK.fn = function(act)
    local successful = old_BLINK(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.invobject or act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if successful and obj ~= nil then
            logdebugaction(act, obj, " casts ", ":magic_wand: ")
        end
    end, successful, act)
    return successful
end

GLOBAL.ACTIONS.PLAY.fn = function(act)
    local successful = old_PLAY(act)
    GLOBAL.pcall(function(successful, act)
        local obj = act.invobject
        if successful and obj ~= nil then
            logdebugaction(act, obj, " casts ", ":magic_wand: ")
        end
    end, successful, act)
    return successful
end

AddPlayerPostInit(function(inst)
    inst:ListenForEvent("done_embark_movement", function(inst)
        local platform = inst.components.embarker.embarkable
        local logstring = GLOBAL.string.format("%s[%s] embarks %s @(%.2f, %.2f, %.2f)", inst:GetDisplayName(), inst.userid or inst.GUID, platform ~= nil and platform:GetDisplayName() .. "[" .. platform.GUID .. "]" or "land", inst.Transform:GetWorldPosition())
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        print(logstring)
    end)
end)

AddComponentPostInit("hullhealth", function(self, inst)
    local _OnCollide = self.OnCollide
    self.OnCollide = function(self, data)
        local oldpercent = self.inst.components.health:GetPercent()
        _OnCollide(self, data)
        local newpercent = self.inst.components.health:GetPercent()

        if oldpercent ~= newpercent then
            local logstring = GLOBAL.string.format("%s[%s] collides @(%.2f, %.2f, %.2f)", self.inst:GetDisplayName(), self.inst.GUID, self.inst.Transform:GetWorldPosition())
            logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
            print(logstring)
        end
    end
end)

AddPrefabPostInit("boat_leak", function(inst)
    inst:DoTaskInTime(0, function(inst)
        local boat = inst.components.boatleak.boat
        local logstring = GLOBAL.string.format("%s[%s] springs a leak @(%.2f, %.2f, %.2f)", boat:GetDisplayName(), boat.GUID, boat.Transform:GetWorldPosition())
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        print(logstring)
    end)
end)

AddComponentPostInit("unwrappable", function(self, inst)
    self.Unwrap = function(self, doer)
        local pos = self.inst:GetPosition()
        pos.y = 0
        if self.itemdata ~= nil then
            if doer ~= nil and
                self.inst.components.inventoryitem ~= nil and
                self.inst.components.inventoryitem:GetGrandOwner() == doer then
                local doerpos = doer:GetPosition()
                local offset = GLOBAL.FindWalkableOffset(doerpos, doer.Transform:GetRotation() * GLOBAL.DEGREES, 1, 8, false, true, self.NoHoles)
                if offset ~= nil then
                    pos.x = doerpos.x + offset.x
                    pos.z = doerpos.z + offset.z
                else
                    pos.x, pos.z = doerpos.x, doerpos.z
                end
            end
            local creator = self.origin ~= nil and GLOBAL.TheWorld.meta.session_identifier ~= self.origin and { sessionid = self.origin } or nil
            for i, v in ipairs(self.itemdata) do
                local item = GLOBAL.SpawnPrefab(v.prefab, v.skinname, v.skin_id, creator)
                local stack = v.data ~= nil and v.data.stackable ~= nil and v.data.stackable.stack or 1
                local logstring = GLOBAL.string.format("%s[%s] unwraps %s[%d] (x%d) from %s[%s]", doer:GetDisplayName(), doer.userid or doer.GUID, item:GetDisplayName(), item.GUID, stack, self.inst:GetDisplayName(), self.inst.GUID)
                logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
                print(logstring)
                if item ~= nil and item:IsValid() then
                    if item.Physics ~= nil then
                        item.Physics:Teleport(pos:Get())
                    else
                        item.Transform:SetPosition(pos:Get())
                    end
                    item:SetPersistData(v.data)
                    if item.components.inventoryitem ~= nil then
                        item.components.inventoryitem:OnDropped(true, .5)
                    end
                end
            end
            self.itemdata = nil
        end
        if self.onunwrappedfn ~= nil then
            self.onunwrappedfn(self.inst, pos, doer)
        end
    end
end)

-- listen for items being dropped
-- so when someone picks up a dropped item, the previous owner is printed
AddComponentPostInit("inventory", function(self, inst)
    local old_DropItem = self.DropItem
    self.DropItem = function(self, item, wholestack, randomdir, pos)
        local successful = old_DropItem(self, item, wholestack, randomdir, pos)
        GLOBAL.pcall(function(successful)
            if successful then
                if (self.inst ~= nil and self.inst.userid ~= nil) then
                    successful.builtbyname = self.inst:GetDisplayName()
                    successful.builtbyid = self.inst.userid
                end
            end
        end, successful)
        return successful
    end
end)

-- death event
local function OnDeathEv(inst, data)
    GLOBAL.pcall(function(inst, data)
        local cause = data.cause or "Nothing"
        local afflicter = data.afflicter
        local afflicter_name = cause
        local afflicter_id = ""
        if afflicter ~= nil then
            afflicter_name = afflicter:GetDisplayName()
            afflicter_id = data.afflicter.userid or data.afflicter.GUID
        end
        local selfid = inst.userid or inst.GUID
        local logstring = inst:GetDisplayName() .. "[" .. selfid .. "]" .. " was killed by " .. afflicter_name .. "[" .. afflicter_id .. "]"
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = ":skull: " .. logstring
        if (GetModConfigData("dying") == "all" or 
            GetModConfigData("dying") == "player" and (inst.userid ~= nil or afflicter ~= nil and afflicter.userid ~= nil)) then
        print(logstring)
        end
        if discord_enabled and (GetModConfigData("discorddying") == "all" or
            GetModConfigData("discorddying") == "player" and (inst.userid ~= nil or afflicter ~= nil and afflicter.userid ~= nil)) then
                io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
    end, inst, data)
end

AddComponentPostInit("health", function(Health, self)
    self:ListenForEvent("death", OnDeathEv)
end)

-- craft inventory item event (torch, spear, hambat, etc.)
local function OnBuildEv(inst, data)
    GLOBAL.pcall(function(inst, data)
        local theitem = data.item
        local id = inst.userid or inst.GUID
        theitem.builtbyid = inst.userid
        theitem.builtbyname = inst:GetDisplayName()
        local logstring = inst:GetDisplayName() .. "[" .. id .. "]" .. " crafts " .. theitem:GetDisplayName() .. "[" .. theitem.GUID .. "]"
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = ":hammer: " .. logstring
        if GetModConfigData("building") == "all" then
            print(logstring)
        end
        if discord_enabled and GetModConfigData("discordbuilding") == "all" then
            io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
        
    end, inst, data)
end

-- build object event (science machine, crock pot, etc.)
local function OnBuildStructureEv(inst, data)
    GLOBAL.pcall(function(inst, data)
        local theitem = data.item
        local id = inst.userid or inst.GUID
        local logstring = inst:GetDisplayName() .. "[" .. id .. "]" .. " builds " .. theitem:GetDisplayName() .. "[" .. theitem.GUID .. "]"
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = ":classical_building: " .. logstring
        theitem.builtbyid = inst.userid
        theitem.builtbyname = inst:GetDisplayName()
        if theitem.prefab == "campfire" then
            theitem.litbyname = theitem.builtbyname
            theitem.litbyid = theitem.builtbyid
            theitem.originalid = theitem.GUID
            theitem.originalname = theitem:GetDisplayName()
        end
        if GetModConfigData("building") == "all" then
            print(logstring)
        end
        if discord_enabled and GetModConfigData("discordbuilding") == "all" then
            io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
    end, inst, data)
end


AddComponentPostInit("builder", function(Builder, self)
    self:ListenForEvent("builditem", OnBuildEv)
    self:ListenForEvent("buildstructure", OnBuildStructureEv)
end)

-- deploy item (this could be plants, portable crock pots, etc)
AddComponentPostInit("deployable", function(self, inst)
    local old_DEPLOY = self.Deploy
    self.Deploy = function(self, pt, deployer, rot)
        local successful = old_DEPLOY(self, pt, deployer, rot)
        GLOBAL.pcall(function(self, pt, deployer, rot, successful)
            if (successful) then
                local ents = GLOBAL.TheSim:FindEntities(pt.x, pt.y, pt.z, 0.1, nil, {"INLIMBO", "player"})
                if #ents > 0 then
                    for i, v in ipairs(ents) do
                        v.builtbyid = deployer.userid or deployer.GUID
                        v.builtbyname = deployer:GetDisplayName()
                        local logstring = deployer:GetDisplayName() .. "[" .. v.builtbyid .. "] places a " .. v:GetDisplayName() .. "[" .. v.GUID .."]"
                        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
                        local discord_logstring = ":arrow_heading_down: " .. logstring
                        if GetModConfigData("building") == "all" then
                        print(logstring)
                        end
                        if discord_enabled and GetModConfigData("discordbuilding") == "all" then
                            io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
                        end
                    end
                    return successful
                end
            end
        end, self, pt, deployer, rot, successful)
        return successful
    end
end)

-- deconstruction staff
local function OnDeconstruct(self, caster)
    GLOBAL.pcall(function(self, caster)
        local doerid = caster.userid or caster.GUID
        local logstring = caster:GetDisplayName() .. "[" .. doerid .. "] deconstructs " .. self:GetDisplayName() .. "[" .. self.GUID .. "]"
        logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
        local discord_logstring = ":boom: " .. logstring
        if GetModConfigData("hammering") == "all" then
        print(logstring)
        end
        if discord_enabled and GetModConfigData("discordhammering") == "all" then
            io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
    end, self, caster)
end

local function OnOpenBox(self, data)
    GLOBAL.pcall(function(self, data, container_cache)
        local id = self.GUID
        container_cache[id] = {}
        for k,v in pairs(self.components.container.slots) do
            if container_cache[id][v:GetDisplayName()] == nil then
                container_cache[id][v:GetDisplayName()] = 0
            end
            if v.components.stackable ~= nil then
                container_cache[id][v:GetDisplayName()] = container_cache[id][v:GetDisplayName()] + v.components.stackable.stacksize
            else
                container_cache[id][v:GetDisplayName()] = container_cache[id][v:GetDisplayName()] + 1
            end
        end
    end, self, data, container_cache)
end

local function OnCloseBox(self, data)
    GLOBAL.pcall(function(self, data, container_cache)
        local doer = data.doer
        local id = self.GUID
        local new_cache = {}
        local old_cache = container_cache[id]
        local doerid = doer.userid or doer.GUID
        for k,v in pairs(self.components.container.slots) do
            if new_cache[v:GetDisplayName()] == nil then
                new_cache[v:GetDisplayName()] = 0
            end
            if v.components.stackable ~= nil then
                new_cache[v:GetDisplayName()] = new_cache[v:GetDisplayName()] + v.components.stackable.stacksize
            else
                new_cache[v:GetDisplayName()] = new_cache[v:GetDisplayName()] + 1
            end
        end
        -- compute the differences between the old cache and new cache
        for k,v in pairs(new_cache) do
            local old_amount = 0
            if old_cache[k] ~= nil then old_amount = old_cache[k] end
            if v > old_amount then
                local logstring =  doer:GetDisplayName() .. "[" .. doerid .. "]" .. " adds " .. v - old_amount .. " " .. k .. " to " .. self:GetDisplayName() .. "[" .. self.GUID .. "]"
                logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
                local discord_logstring =  ":briefcase: " .. logstring
                if GetModConfigData("stealing") == "all" then
                print(logstring)
                end
                if discord_enabled and GetModConfigData("discordstealing") == "all" then
                    io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
                end
            end
        end
        for k,v in pairs(old_cache) do
            local new_amount = 0
            if new_cache[k] ~= nil then new_amount = new_cache[k] end
            if v > new_amount then
                local logstring = doer:GetDisplayName() .. "[" .. doerid .. "]" .. " removes " .. v - new_amount.. " " .. k .. " from " .. self:GetDisplayName() .. "[" .. self.GUID .. "]"
                logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
                local discord_logstring =  ":briefcase: " .. logstring
                if GetModConfigData("stealing") == "all" then
                print(logstring)
                end
                if discord_enabled and GetModConfigData("discordstealing") == "all" then
                    io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
                end
            end
        end
    end, self, data, container_cache)
end

AddComponentPostInit("container", function(self, inst)
    inst:ListenForEvent("onopen", OnOpenBox)
    inst:ListenForEvent("onclose", OnCloseBox)
end)
-- this will be called when an object is 'worked'
-- its purpose is to keep track of all objects that have been destroyed.
--[[ local function onDestroyed(self, worker)
    if self.inst.builtbyid == nil and self.inst.builtbyname == nil then

    end
end ]]


-- this will get called if trees are felled, rocks are mined, anything is hammered down, etc.
-- right now it just reports that x destroys y, will add more descriptive actions later
-- TODO: replace with self.inst:PushEvent("workfinished", { worker = worker })
AddComponentPostInit("workable", function(self, inst)
    local old_WorkedBy = self.WorkedBy
    self.WorkedBy = function(self, worker, numworks)
        GLOBAL.pcall(function(self, worker, numworks)
            if numworks >= self.workleft then
                local workerid = worker.userid or worker.GUID 
                workerid =  "[" .. workerid .. "]"
                local workedid = "[" .. self.inst.GUID .. "]"
                local ownedby = ""
                local discord_ownedby = ""
                local target = ""
                local discord_target = ""
                if (self.inst.builtbyid ~= nil and self.inst.builtbyname ~= nil) then
                    ownedby = " Owner: " .. self.inst.builtbyname .. "[" .. self.inst.builtbyid .. "]"
                    discord_ownedby =  " :key:" .. ownedby 
                end
                if (worker.components ~= nil and worker.components.combat ~= nil and worker.components.combat.target ~= nil) then
                    local targetname = worker.components.combat.target:GetDisplayName() or ""
                    local targetid = worker.components.combat.target.userid or worker.components.combat.target.GUID
                    target = " Targetting: " .. targetname .. "[" .. targetid .. "]"
                    discord_target = " :crossed_swords: " .. target
                end
                local action = self.action.str:lower()
                local logstring = worker:GetDisplayName() .. workerid .. " " .. action .. "s " .. self.inst:GetDisplayName() .. workedid .. ownedby .. target
                logstring = GLOBAL.string.gsub(logstring, '@admin','@ admin')
                local discord_logstring = worker:GetDisplayName() .. workerid .. " " .. action .. "s " .. self.inst:GetDisplayName() .. workedid .. discord_ownedby .. discord_target
                
                --if ((action ~= "chop" or self.inst.prefab == "livingtree" or self.inst.prefab == "livingtree_halloween") and (action ~= "dig" or self.inst.prefab == "livingtree" or self.inst.prefab == "livingtree_halloween" or not self.inst:HasTag("tree"))  and (action ~= "mine" or not self.inst:HasTag("boulder"))) then
                if (action == "chop") then
                    if discord_enabled and (GetModConfigData("discordchopping") == "all" or (GetModConfigData("discordchopping") == "player" and worker.userid ~= nil)) then
                        io.write("[" .. GLOBAL.os.date("%x %X") .. "] :boom: " .. discord_logstring .. "\n")
                    end
                    if (GetModConfigData("chopping") == "all" or (GetModConfigData("chopping") == "player" and worker.userid ~= nil)) then
                        print(logstring)
                    end
                elseif (action == "hammer") then
                    if discord_enabled and (GetModConfigData("discordhammering") == "all" or (GetModConfigData("discordhammering") == "player" and worker.userid ~= nil)
                        or (GetModConfigData("discordhammering") == "playerbuilt" and ownedby ~= "")) then
                        io.write("[" .. GLOBAL.os.date("%x %X") .. "] :boom: " .. discord_logstring .. "\n")
                    end
                    if (GetModConfigData("hammering") == "all" or (GetModConfigData("hammering") == "player" and worker.userid ~= nil)
                        or (GetModConfigData("hammering") == "playerbuilt" and ownedby ~= "")) then
                        print(logstring)
                    end
                elseif (action == "mine") then
                    if discord_enabled and (GetModConfigData("discordmining") == "all" or (GetModConfigData("discordmining") == "player" and worker.userid ~= nil)) then
                        io.write("[" .. GLOBAL.os.date("%x %X") .. "] :boom: " .. discord_logstring .. "\n")
                    end
                    if (GetModConfigData("mining") == "all" or (GetModConfigData("mining") == "player" and worker.userid ~= nil)) then
                        print(logstring)
                    end
                elseif (action == "dig") then
                    if discord_enabled and (GetModConfigData("discorddigging") == "all" or (GetModConfigData("discorddigging") == "player" and worker.userid ~= nil)) then
                        io.write("[" .. GLOBAL.os.date("%x %X") .. "] :boom: " .. discord_logstring .. "\n")
                end
                    if (GetModConfigData("digging") == "all" or (GetModConfigData("digging") == "player" and worker.userid ~= nil)) then
                print(logstring)
                    end
                end
                
            end
        end, self, worker, numworks)
        --return 
        return old_WorkedBy(self, worker, numworks)
    end
end)

AddComponentPostInit("inspectable", function(self, inst)
    -- this is to save/load objects with their original builder
    self.OldOnSave = self.OnSave
    self.OnSave = OnSave
    self.OldOnLoad = self.OnLoad
    self.OnLoad = OnLoad
    -- deconstruction staff
    inst:ListenForEvent("ondeconstructstructure", OnDeconstruct)
end)

-- when a player says something
local old_SAY = GLOBAL.Networking_Say
GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    GLOBAL.pcall(function(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
        local name = GLOBAL.string.gsub(name, '@admin','@ admin') -- this is so no one abuses @admin discord ping by naming themselves @admin
        local logstring =  name .. "[" .. userid .. "]: " .. message
        local discord_logstring =  ":speech_balloon: " .. logstring
        print(logstring)
        if discord_enabled then
            io.write("[" .. GLOBAL.os.date("%x %X") .. "] " .. discord_logstring .. "\n")
        end
    end, guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    return old_SAY(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
end

--[[ function getPlayer(nameOrID)
    local client = GLOBAL.TheNet:GetClientTableForUser(nameOrId)
    if (client == nil) then
        client = GLOBAL.UserToClientID(nameOrId)
        return GLOBAL.TheNet:GetClientTableForUser(client)
    else
        return client
    end
end ]]

-- A work in progress user command to restore burned entities
-- it currently restores ALL burned entities within a 30 block radius, even if they have been removed by other means
