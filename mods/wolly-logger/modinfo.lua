name = "Wolly Logger" -- This is the name of the mod.
description =
    "Server side mod that provides better logging of events." -- This is the description of our mod.
author = "ipsiq" -- This is the author of our mod.
version = "0.3.2" -- This is the version of our mod. It's used for the Steam Workshop, you cannot upload a version which is the same or less than the currently uploaded mod.

forumthread = "" -- This is a link directed to a forum thread of the mod.
api_version = 10 -- This is the latest Don't Starve Together api version and is only used for Don't Starve Together.

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dont_starve_compatible = false -- This is used to denote that the mod is compatible with Don't Starge.
reign_of_giants_compatible = true -- This is used to denote that the mod is compatible with Don't Starve: Reign of Giants.
dst_compatible = true -- This is used to denote that the mod is compatible with Don't Starve Together.

all_clients_require_mod = false -- This is used to denote that players should be forced to download the mod from the Steam Workshop or use a cached version on the clients computer. Setting this to false makes it so that a client does not download this mod. Server only or client only mods should set this to false, all other mods should have this set as true.

client_only_mod = false -- This is used to denote that this mod is for clent use only. If all_clients_require_mod is set to true this variable must be set to false.

configuration_options = {
    {
        name = "1",
        label = "Log location: server_log.txt   ",
        options = {
            {
                description = "",
                data = ""
            }
        },
        default = ""
    },
    {
        name = "1",
        label = "Log the following:  ",
        options = {
            {
                description = "",
                data = ""
            }
        },
        default = ""
    },
    {
        name = "fire",
        label = "Fires",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "Ignore Trees",
                data = "ignoretree"
            },
            {
                description = "All Fires",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "lighting",
        label = "Lighting On Fire",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "hammering",
        label = "Hammering/Destroying",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "Player Built Only",
                data = "playerbuilt"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "dying",
        label = "Death Events",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "All Deaths",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "building",
        label = "Building",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "crafting",
        label = "Crafting",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "mining",
        label = "Mining",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "chopping",
        label = "Chopping",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "digging",
        label = "Digging",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "stealing",
        label = "Adding/Removing from Chest",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Player Involved",
                data = "player"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "crockpot",
        label = "Crock Pot/Bird Cage Theft",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "pickup",
        label = "Picking item up",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "If not prev owner",
                data = "theft"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "eating",
        label = "Eating",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Valuables Only",
                data = "valuables"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "picking",
        label = "Picking (Flowers)",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "Flowers Only",
                data = "flower"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "reading",
        label = "Casting Spells",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            },
        },
        default = "off"
    },
    {
        name = "gift",
        label = "Gift Opening",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "dice",
        label = "Dice Roll",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "leavejoin",
        label = "Player Join/Leave",
        options = {
            {
                description = "None",
                data = "off"
            },
            {
                description = "All",
                data = "all"
            }
        },
        default = "off"
    },
    {
        name = "",
        label = "",
        options = {
            {
                description = "",
                data = ""
            }
        },
        default = ""
    },
}