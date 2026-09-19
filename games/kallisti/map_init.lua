local map_dir = os.getenv("HOME") .. "/.config/blightmud/games/kallisti/maps/"

function load_character_map(character_name)
	if not character_name or character_name == "" then
		print("Cannot load map: no character name supplied.")
		return nil
	end

	local map_file = map_dir .. character_name .. ".map"
	local map = Mapper.create(character_name)
	local file = io.open(map_file, "r")

	if file then
		file:close()
		map:load(map_file)
		print("Loaded " .. character_name .. ".map")
	else
		print("Creating " .. character_name .. ".map")
		map:save(map_file)
	end

	return map
end
