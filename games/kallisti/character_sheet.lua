----------------------------------------------------------------------
-- Kallisti character sheet capture and tmux display
--
-- Type `att` to:
--   1. Open the tmux sheet pane if it is not already open.
--   2. Send att to Kallisti.
--   3. Capture and gag the returned character sheet.
--   4. Display the colorized sheet in the tmux pane.
--
-- Type logout, quit, or logoff to close the sheet pane.
----------------------------------------------------------------------

local sheet_file = "/tmp/kallisti-sheet"
local sheet_tmp = "/tmp/kallisti-sheet.tmp"
local pane_id_file = "/tmp/kallisti-sheet-pane"

local capturing_sheet = false
local sheet_lines = {}

local body_trigger
local prompt_trigger


----------------------------------------------------------------------
-- tmux functions
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

	for existing_id in process:lines() do
		if existing_id == pane_id then
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

	local command = [[
		tmux split-window -d -h -l 42 -P -F '#{pane_id}' \
		'sh -c "while :; do clear; cat /tmp/kallisti-sheet 2>/dev/null; sleep 0.25; done"'
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

	-- Make the sheet pane display-only.
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
-- Character-sheet file handling
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

	-- Use the raw lines so ANSI color escape sequences are preserved.
	file:write(table.concat(sheet_lines, "\n"))
	file:write("\n")
	file:close()

	-- Replace the old file only after the new file is complete.
	os.remove(sheet_file)
	os.rename(sheet_tmp, sheet_file)

	sheet_lines = {}
end


----------------------------------------------------------------------
-- Start of the `att` output
--
-- Do not use raw = true here. The separator may contain ANSI codes,
-- and we want the trigger to match the display/plain version.
----------------------------------------------------------------------

local start_trigger = trigger.add(
	"^[-]+$",
	{
		gag = true
	},
	function(matches, line)
		if capturing_sheet then
			return
		end

		capturing_sheet = true

		-- Preserve colors in the saved file.
		sheet_lines = {
			line:raw()
		}

		body_trigger:enable()
		prompt_trigger:enable()
	end
)


----------------------------------------------------------------------
-- Capture the rest of the sheet
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
-- Detect the prompt after the sheet
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
-- Replace the normal `att` command with an alias that opens the pane
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
