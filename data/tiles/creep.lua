local util = require("data/tf_util/tf_util")
local name = names.creep
local creep_color = {r = 1, b = 0.6, g = 0.1}
local creep = util.copy(data.raw.tile["sand-1"])
creep.name = name
creep.localised_name = name
creep.collision_mask = util.creep_collision_mask()

--util.recursive_hack_tint(creep, creep_color)
creep.tint = creep_color
creep.map_color = creep_color
--creep.allowed_neighbors = nil
creep.pollution_absorption_per_second = 0
creep.walking_sound = {}
for k = 1, 8 do
  table.insert(creep.walking_sound, {filename = util.path("data/tiles/creep-0"..k..".ogg")})
end
creep.walking_speed_modifier = 1.6
creep.autoplace = data.raw["unit-spawner"]["biter-spawner"].autoplace
creep.needs_correction = false



data:extend
{
  creep
}