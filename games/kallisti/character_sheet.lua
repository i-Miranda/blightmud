----------------------------------------------------------------------
-- Kallisti character-sheet capture and tmux display
--
-- The pane is created the first time you type `att`.
-- It is removed when you type `logout`, `quit`, or `logoff`.
----------------------------------------------------------------------

local sheet_file = "/tmp/kallisti-sheet"
local sheet_tmp = sheet_file .. ".tmp"
local pane_id_file = "/tmp/kallisti-sheet-pane"

local capturing_sheet = false
local sheet_lines = {}

local body_trigger
local prompt_trigger


----------------------------------------------------------------------
-- tmux helpers
----------------------------------------------------------------------

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

	for listed_pane_id in process:lines() do
		if listed_pane_id == pane_id then
			process:close()
			return true
		end
	end

	process:close()
	return false
end


local function start_sheet_pane()
	if not os.getenv("TMUX") then
		print("Not running inside tmux; sheet pane was not created.")
		return
	end

	-- The pane runs a simple display loop. `-d` prevents tmux from
	-- switching focus away from the Blightmud pane.
	local command = [[
		tmux split-window -d -h -l 80 -P -F '#{pane_id}' \
		'sh -c "while :; do clear; \
		cat /tmp/kallisti-sheet 2>/dev/null; sleep 0.25; \
		done"'
	]]

	local process = io.popen(command, "r")

	if not process then
		print("Unable to create tmux sheet pane.")
		return
	end

	local pane_id = process:read("*l")
	process:close()

	if not pane_id or pane_id == "" then
		print("Unable to determine tmux sheet pane ID.")
		return
	end

	local file = io.open(pane_id_file, "w")

	if file then
		file:write(pane_id)
		file:close()
	end

	-- Make the pane display-only so it does not receive keyboard input.
	os.execute(
		"tmux select-pane -d -t " .. pane_id .. " 2>/dev/null"
	)
end


local function ensure_sheet_pane()
	local pane_id = read_pane_id()

	if pane_exists(pane_id) then
		return
	end

	start_sheet_pane()
end


local function stop_sheet_pane()
	local pane_id = read_pane_id()

	if pane_id and pane_id ~= "" then
		os.execute(
			"tmux kill-pane -t " .. pane_id .. " 2>/dev/null"
		)
	end

	os.remove(pane_id_file)
end


----------------------------------------------------------------------
-- Sheet-file handling
----------------------------------------------------------------------

local function finish_sheet_capture()
	if not capturing_sheet then
		return
	end

	capturing_sheet = false

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

	-- Keep the ANSI escape sequences so colors survive in tmux.
	file:write(table.concat(sheet_lines, "\n"))
	file:write("\n")
	file:close()

	-- Replace the previous sheet only after the new one is complete.
	os.remove(sheet_file)
	os.rename(sheet_tmp, sheet_file)

	sheet_lines = {}
end


----------------------------------------------------------------------
-- Capture the opening separator printed by `att`
----------------------------------------------------------------------

local start_trigger = trigger.add(
	"^[-]{80}$",
	{
		gag = true,
		raw = true
	},
	function(matches, line)
		if capturing_sheet then
			return
		end

		capturing_sheet = true
		sheet_lines = {
			line:raw()
		}

		body_trigger:enable()
		prompt_trigger:enable()
	end
)


----------------------------------------------------------------------
-- Capture and gag the ordinary sheet lines
----------------------------------------------------------------------

body_trigger = trigger.add(
	".*",
	{
		gag = true,
		raw = true,
		enabled = false
	},
	function(matches, line)
		if capturing_sheet then
			table.insert(sheet_lines, line:raw())
		end
	end
)


----------------------------------------------------------------------
-- Capture and gag the prompt after the sheet
----------------------------------------------------------------------

prompt_trigger = trigger.add(
	".*",
	{
		prompt = true,
		gag = true,
		enabled = false
	},
	function(matches, line)
		finish_sheet_capture()
	end
)


----------------------------------------------------------------------
-- Open the pane automatically when `att` is used
----------------------------------------------------------------------

alias.add("^att$", function()
	ensure_sheet_pane()
	mud.send("att")
end)


----------------------------------------------------------------------
-- Close the pane when leaving the game
----------------------------------------------------------------------

alias.add("^logout$", function()
	stop_sheet_pane()
	mud.send("logout")
end)

alias.add("^quit$", function()
	stop_sheet_pane()
	mud.send("quit")
end)

alias.add("^logoff$", function()
	stop_sheet_pane()
	mud.send("logoff")
end)
