local session = {}

local state = {
	host = store.session_read("cur_host"),
	port = tonumber(store.session_read("cur_port") or "0"),
}

function session.find_game(games, host, port)
	for id, game in pairs(games) do
		if game.host == host and game.port == port then
			return id, game
		end
	end
	return nil, nil
end

function session.on_connect(games, accounts, host, port)
	store.session_write("cur_host", host)
	store.session_write("cur_port", tostring(port))

	local id, game = session.find_game(games, host, port)

	if game then
		print("Loading game: \"" .. game.name .. "\" (" .. id .. ")")

		-- Make this account available to game config
		_G.current_account = accounts[id]

		script.load(game.config)
	else
		print("No configuration found for " .. host .. ":" .. tostring(port))
	end
end

function session.disconnect()
	state.host = nil
	state.port = nil
	store.session_write("cur_host", tostring(nil))
	store.session_write("cur_port", tostring(nil))
end

function session.restore(games, accounts)
	if state.host and state.port then
		session.on_connect(games, accounts, state.host, state.port)
	end
end

return session
