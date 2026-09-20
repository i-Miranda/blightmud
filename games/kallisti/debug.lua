local function print_list(data)
	print("=== MSDP REPORTABLE VARIABLES ===")

	if type(data) == "table" then
		for key, value in pairs(data) do
			if type(value) == "table" then
				print(tostring(key) .. ":")
				for index, item in pairs(value) do
					print("  " .. tostring(index) .. " = " .. tostring(item))
				end
			else
				print(tostring(key) .. " = " .. tostring(value))
			end
		end
	else
		print("Received:", tostring(data))
	end

	print("=== END MSDP VARIABLES ===")
end

-- Register before making the request.
msdp.register("REPORTABLE_VARIABLES", print_list)

msdp.on_ready(function()
	print("MSDP is ready; requesting reportable variables")

	local ok, err = pcall(function()
		msdp.list("REPORTABLE_VARIABLES")
	end)

	if not ok then
		print("Could not request MSDP list:", err)
	end
end)

-- 1. Register callbacks
msdp.register("REPORTABLE_VARIABLES", print_list)

-- 2. Wait for MSDP negotiation
msdp.on_ready(function()
	-- 3. Request the list after login/negotiation
	msdp.list("REPORTABLE_VARIABLES")
end)
