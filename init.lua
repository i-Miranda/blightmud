local config_dir = os.getenv("HOME") .. "/.config/blightmud/"

local games = dofile(config_dir .. "games/games.lua")
local session = dofile(config_dir .. "lib/session.lua")
local accounts = dofile(config_dir .. "accounts.lua")

dofile(config_dir .. "plugins/mapper/main.lua")

local function reload_scripts()
	blight.status_height(1)
	blight.status_line(0, "")
	script.reset()
	script.load(config_dir .. "init.lua")
end

alias.add("^reload$", reload_scripts)

mud.on_connect(function(host, port)
	session.on_connect(games, accounts, host, port)
end)

mud.on_disconnect(function()
	session.disconnect()
	reload_scripts()
end)

session.restore(games, accounts)
