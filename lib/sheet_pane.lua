----------------------------------------------------------------------
-- sheet_pane.lua
--
-- Reusable Blightmud character-sheet capture and tmux display module.
--
-- Expected configuration:
--
-- sheet_pane.setup({
--     open_command = "att",
--     close_command = false,
--     start_pattern = "^[-]+$",
--     logout_pattern = "^Goodbye!$",
--     pane_width = 80,
-- })
----------------------------------------------------------------------

local M = {}


local function escape_lua_pattern(value)
	return tostring(value):gsub(
		"([%(%)%.%%%+%-%*%?%[%]%^%$])",
		"%%%1"
	)
end


local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end


function M.setup(game)
	assert(game, "sheet_pane.setup requires a configuration table")
	assert(game.sheet.open_command, "sheet_pane.setup requires config.command")
	assert(game.sheet.start_pattern, "sheet_pane.setup requires config.start_pattern")

	local open_command = game.sheet.open_command or "opensheet"
	local close_command = game.sheet.close_command or "closesheet"
	local sheet_file = "/tmp/" .. (game.id or "sheet") .. ".sheet"
	local sheet_tmp = "/tmp/" .. (game.id or "sheet") .. ".tmp"
	local pane_id_file = "/tmp/" .. (game.id or "sheet") .. ".pane"
	local pane_width = game.sheet.pane_width or 80

	local capturing_sheet = false
	local capture_requested = false
	local capture_timeout = nil

	local sheet_lines = {}

	local body_trigger
	local prompt_trigger

	local open_alias = "opensheet"
	local close_alias = "closesheet"

	------------------------------------------------------------------
	-- tmux functions
	------------------------------------------------------------------

	local function read_pane_id()
		local file = io.open(pane_id_file, "r")

		if not file then
			return nil
		end

		local pane_id = file:read("*l")
		file:close()

		return pane_id
	end


	local function pane_exists(pane_id)
		if not pane_id or pane_id == "" then
			return false
		end

		local process = io.popen(
			"tmux list-panes -a -F '#{pane_id}' 2>/dev/null"
		)

		if not process then
			return false
		end

		for existing_id in process:lines() do
			if existing_id == pane_id then
				process:close()
				return true
			end
		end

		process:close()
		return false
	end

	local function cancel_capture()
		capture_requested = false
		capturing_sheet = false
		sheet_lines = {}

		if capture_timeout then
			timer.remove(capture_timeout)
			capture_timeout = nil
		end

		if body_trigger then
			body_trigger:disable()
		end

		if prompt_trigger then
			prompt_trigger:disable()
		end
	end

	local function start_sheet_pane()
		if not os.getenv("TMUX") then
			print("Not running inside tmux; sheet pane was not created.")
			return
		end

		local display_command =
			"while :; do "
			.. "clear; "
			.. "cat " .. shell_quote(sheet_file) .. " 2>/dev/null; "
			.. "sleep 0.25; "
			.. "done"

		local pane_command = "sh -c " .. shell_quote(display_command)

		local tmux_command = string.format(
			"tmux split-window -d -h -l %d -P -F '#{pane_id}' %s",
			pane_width,
			shell_quote(pane_command)
		)

		local process = io.popen(tmux_command, "r")

		if not process then
			print("Unable to create sheet pane.")
			return
		end

		local pane_id = process:read("*l")
		process:close()

		if not pane_id or pane_id == "" then
			print("Unable to determine sheet pane ID.")
			return
		end

		local file = io.open(pane_id_file, "w")

		if file then
			file:write(pane_id)
			file:close()
		end

		-- Make the sheet pane display-only.
		os.execute(
			"tmux select-pane -d -t "
			.. shell_quote(pane_id)
			.. " 2>/dev/null"
		)
	end


	local function ensure_sheet_pane()
		local pane_id = read_pane_id()

		if not pane_exists(pane_id) then
			start_sheet_pane()
		end
	end


	local function stop_sheet_pane()
		cancel_capture()

		local pane_id = read_pane_id()

		if pane_id and pane_id ~= "" then
			os.execute(
				"tmux kill-pane -t "
				.. shell_quote(pane_id)
				.. " 2>/dev/null"
			)
		end

		os.remove(pane_id_file)
	end


	------------------------------------------------------------------
	-- Capture functions
	------------------------------------------------------------------

	local function finish_sheet_capture()
		if not capturing_sheet then
			return
		end

		capturing_sheet = false
		capture_requested = false

		if capture_timeout then
			timer.remove(capture_timeout)
			capture_timeout = nil
		end

		if body_trigger then
			body_trigger:disable()
		end

		if prompt_trigger then
			prompt_trigger:disable()
		end

		local file, err = io.open(sheet_tmp, "w")

		if not file then
			print("Unable to open character sheet file: " .. tostring(err))
			sheet_lines = {}
			return
		end

		-- Preserve ANSI color escape sequences.
		file:write(table.concat(sheet_lines, "\n"))
		file:write("\n")
		file:close()

		-- Replace the previous sheet only after the new sheet is complete.
		os.remove(sheet_file)
		os.rename(sheet_tmp, sheet_file)

		sheet_lines = {}
	end



	------------------------------------------------------------------
	-- Detect the first line of the character sheet
	--
	-- This trigger intentionally does not use raw = true. The pattern
	-- should match the normal display/plain-text version of the line.
	----------------------------------------------------------------------

	trigger.add(
		game.sheet.start_pattern,
		{
			gag = true
		},
		function(_, line)
			if not capture_requested or capturing_sheet then
				return
			end

			capture_requested = false

			if capture_timeout then
				timer.remove(capture_timeout)
				capture_timeout = nil
			end

			capturing_sheet = true

			-- Preserve colors in the saved output.
			sheet_lines = {
				line:raw()
			}

			body_trigger:enable()
			prompt_trigger:enable()
		end
	)


	------------------------------------------------------------------
	-- Capture the rest of the character sheet
	----------------------------------------------------------------------

	body_trigger = trigger.add(
		".*",
		{
			gag = true,
			raw = true,
			enabled = false
		},
		function(_, line)
			if capturing_sheet then
				table.insert(sheet_lines, line:raw())
			end
		end
	)


	------------------------------------------------------------------
	-- Detect the prompt after the character sheet
	----------------------------------------------------------------------

	prompt_trigger = trigger.add(
		".*",
		{
			prompt = true,
			gag = true,
			enabled = false
		},
		function()
			finish_sheet_capture()
		end
	)


	------------------------------------------------------------------
	-- Register the actual game command as the Blightmud alias
	--
	-- Example:
	--     command = "att"
	--
	-- Typing "att" opens the pane and sends "att" to the game.
	----------------------------------------------------------------------


	local function open_sheet()
		ensure_sheet_pane()

		if capture_timeout then
			timer.remove(capture_timeout)
			capture_timeout = nil
		end

		capture_requested = true

		capture_timeout = timer.add(3, 1, function()
			capture_requested = false
			capture_timeout = nil
		end)

		mud.send(open_command, { gag = true })
	end

	alias.add("^" .. escape_lua_pattern(open_command) .. "$", open_sheet)

	if open_alias ~= open_command then
		alias.add("^" .. escape_lua_pattern(open_alias) .. "$", open_sheet)
	end

	------------------------------------------------------------------
	-- Close the pane when leaving the game
	----------------------------------------------------------------------
	if game.sheet.logout_pattern then
		trigger.add(
			game.sheet.logout_pattern,
			{
				gag = false,
				raw = false,
			},
			stop_sheet_pane
		)
	end

	alias.add("^" .. escape_lua_pattern(close_command) .. "$", stop_sheet_pane)

	if close_alias ~= close_command then
		alias.add("^" .. escape_lua_pattern(close_alias) .. "$", stop_sheet_pane)
	end
end

return M
