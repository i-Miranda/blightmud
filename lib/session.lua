local games = dofile(blight.config_dir() .. "/games/games.lua")
local accounts = dofile(blight.config_dir() .. "/accounts.lua")
local sheet_pane = dofile(blight.config_dir() .. "/lib/sheet_pane.lua")

local session = {}

local state = {
	host = store.session_read("cur_host"),
	port = tonumber(store.session_read("cur_port") or "0"),
}

function session.find_game(host, port)
	for id, game in pairs(games) do
		if game.host == host and game.port == port then
			return id, game
		end
	end
	return nil, nil
end

function session.on_connect(host, port)
	store.session_write("cur_host", host)
	store.session_write("cur_port", tostring(port))

	local id, game = session.find_game(host, port)

	if game and id then
		print("Loading game: \"" .. game.name .. "\" (" .. id .. ")")

		-- Make this account available to game config
		_G.current_account = accounts[id]

		script.load(game.config)
		sheet_pane.setup(game)
		print("Starting \"" .. game.name .. "\" session")
	else
		print("No configuration found for " .. host .. ":" .. tostring(port))
	end
end

function session.disconnect()
	local id, game = session.find_game(state.host, state.port)
	if game and id then
		print("Ending " .. game.name .. " session")
	end
	state.host = nil
	state.port = nil
	store.session_write("cur_host", tostring(nil))
	store.session_write("cur_port", tostring(nil))
end

function session.restore()
	if state.host and state.port then
		session.on_connect(state.host, state.port)
	end
end

return session
