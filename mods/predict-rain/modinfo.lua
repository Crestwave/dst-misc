name = "Predict Rain"
author = "Crestwave"
description = [[
/predictrain to forecast rain start or stop.
/help predictrain for more info.

Compatible with Island Adventures.
]]

version = "1.4"
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
		name = "predicthail",
		label = "Predict Hail",
		options = {
			{ description = "Enabled", data = true },
			{ description = "Disabled", data = false },
		},
		default = false,
		hover = "[EXPERIMENTAL] Enables /predicthail; may cause performance issues",
	},
}
