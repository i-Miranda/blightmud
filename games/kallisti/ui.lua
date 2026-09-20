local vars = {
	"CHARACTER_NAME",
	"LEVEL",
	"CLASS",
	"HEALTH",
	"HEALTH_MAX",
	"MANA",
	"MANA_MAX",
	"STAMINA",
	"STAMINA_MAX",
	"EXPERIENCE",
	"EXPERIENCE_TNL"
}
local character = {
	name = "CHARACTER_NAME",
	level = 0,
	class = "CLASS",
}

local vitals = {
	hp = 0,
	max_hp = 0,
	mana = 0,
	max_mana = 0,
	stamina = 0,
	max_stamina = 0,
	xp = 0,
	xp_tnl = 0,
}

blight.status_height(3)

local function update_vitals()
	blight.status_line(0, string.format(
		"%s : Level %d %s",
		character.name,
		character.level,
		character.class
	))
	blight.status_line(1, string.format(
		"HP: %d/%d  MP: %d/%d SP: %d/%d XP: %d/%d",
		vitals.hp,
		vitals.max_hp,
		vitals.mana,
		vitals.max_mana,
		vitals.stamina,
		vitals.max_stamina,
		vitals.xp,
		vitals.xp_tnl
	))
end

local function get_value(data)
	if type(data) == "number" or type(data) == "string" then
		return data
	end

	if type(data) == "table" then
		return data.value or data.Value or data.val or data[1]
	end

	return nil
end

local function get_number(data)
	return tonumber(get_value(data))
end

local function get_string(data)
	local value = get_value(data)

	if value ~= nil then
		return tostring(value)
	end

	return nil
end

msdp.register("CHARACTER_NAME", function(data)
	character.name = get_string(data) or character.name
	update_vitals()
end)

msdp.register("LEVEL", function(data)
	character.level = get_number(data) or character.level
	update_vitals()
end)

msdp.register("CLASS", function(data)
	character.class = get_string(data) or character.class
	update_vitals()
end)

msdp.register("HEALTH", function(data)
	vitals.hp = get_number(data) or vitals.hp
	update_vitals()
end)


msdp.register("HEALTH_MAX", function(data)
	vitals.max_hp = get_number(data) or vitals.max_hp
	update_vitals()
end)

msdp.register("MANA", function(data)
	vitals.mana = get_number(data) or vitals.mana
	update_vitals()
end)

msdp.register("MANA_MAX", function(data)
	vitals.max_mana = get_number(data) or vitals.max_mana
	update_vitals()
end)

msdp.register("STAMINA", function(data)
	vitals.stamina = get_number(data) or vitals.stamina
	update_vitals()
end)

msdp.register("STAMINA_MAX", function(data)
	vitals.max_stamina = get_number(data) or vitals.max_stamina
	update_vitals()
end)

msdp.register("EXPERIENCE", function(data)
	vitals.xp = get_number(data) or vitals.xp
	update_vitals()
end)

msdp.register("EXPERIENCE_TNL", function(data)
	vitals.xp_tnl = get_number(data) or vitals.xp_tnl
	update_vitals()
end)

msdp.on_ready(function()
	msdp.report(vars)
end)

update_vitals()
