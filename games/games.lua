local game_dir = blight.config_dir() .. "/games/"

local function game(id, data)
	data.id = id
	data.config = game_dir .. id .. "/config.lua"
	return data
end

return {
	["LoK"] = game("kallisti", {
		name = "Legends of Kallisti",
		host = "legendsofkallisti.com",
		port = 4000,

		sheet = {
			open_command = "att",
			close_command = false,
			start_pattern = "^[-]+$",
			logout_pattern = "^Goodbye!$",
			pane_width = 80
		}
	}),
}
