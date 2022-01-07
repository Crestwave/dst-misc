AddGamePostInit(
    function()
        if GLOBAL.LootTables and GLOBAL.LootTables.walrus then
            GLOBAL.LootTables.walrus = {
                {'meat',            1.00},
                {'blowdart_pipe',   1.00},
                {'walrushat',       0.50},
                {'walrus_tusk',     0.75},
            }
        end
    end
)
GLOBAL.TUNING.MAX_SANITY_GHOST_PLAYER_DRAIN_MULT = 0.1

--[[ AddComponentPostInit("touchstonetracker", function(self, inst)
    self.IsUsed = function(self, touchstone)
        return false
    end
end) ]]



