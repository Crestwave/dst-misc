name = "Wendy Keybinds+"
author = "Crestwave"
description = [[
Lets Wendy use X to summon/unsummon Abigail and R to rile/soothe her.

Keybinds are configurable.

Additional features:
- Spell cooldown display on Abigail's Flower
- Drink elixir directly with Alt+Right Click
- Middle click on the ground/while holding Ctrl to cast Attack At (Shift-R)
- Middle click on an entity to cast Haunt At (Ctrl-R)
- Middle click on Abigail to cast Scare (Ctrl-R)
- Right click on Abigail to cast Escape (Shift-R)
]]

version = "1.3"
api_version = 10

dst_compatible = true
dont_starve_compatible = false

client_only_mod = true
server_only_mod = false
all_clients_require_mod = false

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {
	{
		name = "summonkey",
		label = "Summon Keybind",
		hover = "Summon and Unsummon Abigail",
		options = {
			--fill later
		},
		default = "X",
	},
	{
		name = "togglekey",
		label = "Rile Up Keybind",
		hover = "Rile Up and Soothe Abigail",
		options = {
			--fill later
		},
		default = "R",
	},
}

local keys = {
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"LSHIFT","LALT","LCTRL","TAB","BACKSPACE","PERIOD","SLASH","TILDE"
}

for i=1, 2 do
	for j=1, #keys do
		configuration_options[i].options[j] = { description = keys[j], data = keys[j] }
	end
end
