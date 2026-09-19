dofile(os.getenv("HOME") .. "/.config/blightmud/games/kallisti/map_init.lua")

local account = current_account
local waiting_for_password = false
local logged_in = false

if not account then
	print("No Legends of Kallisti account configured.")
	return
end

print(account.username .. " account loaded.")

trigger.add([=[^Enter your account name\..*$]=], {}, function()
	if not logged_in then
		waiting_for_password = true
		mud.send(account.username)
	end
end)

trigger.add([=[^Account exists\.$]=], {}, function()
	if not logged_in and waiting_for_password then
		waiting_for_password = false
		mud.send(account.password)
	end
end)

trigger.add([=[^Top Nobility]=], {}, function()
	logged_in = true
	print(account.username .. " logged in successfully.")
end)

trigger.add([=[^Active Character:\s*(\S+)\s+\[]=], {}, function(matches)
	local character_name = matches[1]
	print("Active Character: " .. character_name)
	active_map = load_character_map(character_name)
end)
