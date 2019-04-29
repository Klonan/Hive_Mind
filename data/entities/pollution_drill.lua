local drill = util.copy(data.raw["mining-drill"]["burner-mining-drill"])
local name = names.pollution_drill

util.recursive_hack_make_hr(drill)
util.recursive_hack_scale(drill, 2)
util.recursive_hack_tint(drill, {r = 1, b = 1})

drill.name = name
drill.localised_name = name
drill.order = "noob"
drill.collision_box = util.area({0,0}, 2.01)
drill.selection_box = util.area({0,0}, 2)
drill.mining_speed = 0
drill.energy_source = {type = "void"}
drill.resource_searching_radius = 1
drill.emissions_per_second = 0.4
drill.collision_mask = util.buildable_on_creep_collision_mask()
drill.resource_categories = {"basic-fluid"}


local subgroup =
{
  type = "item-subgroup",
  name = "pollution-drill-subgroup",
  group = "combat",
  order = "b"
}

local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  localised_description = {"requires-pollution", names.required_pollution[name]},
  icons = drill.icons,
  icon = drill.icon,
  icon_size = drill.icon_size,
  flags = {},
  subgroup = subgroup.name,
  order = "aa-"..name,
  place_result = name,
  stack_size = 50
}

data:extend
{
  drill,
  item,
  subgroup
}
