local game_dir = os.getenv("HOME") .. "/.config/blightmud/games/"

return {
	["LoK"] = {
		name = "Legends of Kallisti",
		host = "legendsofkallisti.com",
		port = 4000,
		config = game_dir .. "kallisti/config.lua",
	},
}
