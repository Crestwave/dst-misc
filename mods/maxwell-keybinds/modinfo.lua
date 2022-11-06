name = "Maxwell Keybinds"
author = "Crestwave"
description = [[
Lets Maxwell use X to cast his Codex Umbra and R to access his Magician's Top Hat.

Keybinds are configurable.
]]

version = "1.0"
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
		name = "waxwelljournalkey",
		label = "Codex Umbra Keybind",
		hover = "Open and refuels the Codex Umbra",
		options = {
			--fill later
		},
		default = "X",
	},
	{
		name = "tophatkey",
		label = "Top Hat Keybind",
		hover = "Open the Magician's Top Hat",
		options = {
			--fill later
		},
		default = "R",
	},
}

local keys = {
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"LSHIFT","LALT","LCTRL","TAB","BACKSPACE","PERIOD","SLASH","TILDE",
}

for i=1, 2 do
	for j=1, #keys do
		configuration_options[i].options[j] = { description = keys[j], data = keys[j] }
	end
end
