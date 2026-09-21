local session = dofile(blight.config_dir() .. "/lib/session.lua")

dofile(blight.config_dir() .. "/lib/chat_tabs.lua")
dofile(blight.config_dir() .. "/plugins/mapper/main.lua")

local function reload_scripts()
	print("Reloading scripts")
	blight.status_height(1)
	blight.status_line(0, "")
	script.reset()
	script.load(blight.config_dir() .. "/init.lua")
end

alias.add("^reload$", reload_scripts)

mud.on_connect(function(host, port)
	session.on_connect(host, port)
end)

mud.on_disconnect(function()
	session.disconnect()
	reload_scripts()
end)

session.restore()
