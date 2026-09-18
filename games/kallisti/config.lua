local account = current_account
local waiting_for_password = false
local login_event_active = false

if not account then
	print("No Legends of Kallisti account configured.")
	return
end

print(account.username .. " account loaded.")

trigger.add([=[^Enter your account name\..*$]=], {}, function()
	if not login_event_active then
		login_event_active = true
		waiting_for_password = true
		mud.send(account.username)
	end
end)

trigger.add([=[^Account exists\.$]=], {}, function()
	if login_event_active and waiting_for_password then
		waiting_for_password = false
		mud.send(account.password)
	end
end)

trigger.add([=[^Top Nobility]=], {}, function()
	login_event_active = false
	print(account.username .. " logged in successfully.")
end)
