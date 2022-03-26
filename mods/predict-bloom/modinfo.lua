name = "Wormwood Bloom Predictor"
author = "Crestwave"
description = [[
Predict Wormwood's bloom.
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
		name = "meter",
		label = "Show Meter",
		options = {
				{ description = "Yes", data = true },
				{ description = "No", data = false },
		},
        	default = true,
	},
}
