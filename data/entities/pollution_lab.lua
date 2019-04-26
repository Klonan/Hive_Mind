
local name = names.pollution_lab
local util = require("data/tf_util/tf_util")
local graphics = util.copy(data.raw.lab.lab)
--local animation = graphics.animations[1]

local tint = {r = 0.5, b = 0.5}

for k, animation in pairs ({graphics.on_animation, graphics.off_animation}) do
  for k, layer in pairs (animation.layers) do
      layer.tint = tint
      if layer.hr_version then
        layer.hr_version.tint = tint
      end
  end
end

--util.recursive_hack_scale(graphics, 3/5)


local lab =
{
  type = "lab",
  name = name,
  localised_name = name,
  icons = 
  {
    {
      icon = graphics.icon,
      icon_size = graphics.icon_size,
      tint = tint
    }
  },
  flags = {"placeable-player", "player-creation", "placeable-off-grid"},
  minable = nil,
  max_health = 150,
  corpse = nil,
  dying_explosion = graphics.dying_explosion,
  collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  collision_mask = util.buildable_on_creep_collision_mask(),
  light = {intensity = 0.5, size = 8, color = {r = 0.5, g = 0.5, b = 0}},
  on_animation = graphics.on_animation,
  off_animation = graphics.off_animation,
  working_sound =
  {
    sound =
    {
      filename = "__base__/sound/lab.ogg",
      volume = 0.7
    },
    apparent_volume = 1
  },
  vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
  energy_source =
  {
    type = "void",
    usage_priority = "secondary-input"
  },
  energy_usage = "1W",
  researching_speed = 1,
  inputs =
  {
    names.pollution_proxy
  },
  old_module_specification =
  {
    module_slots = 2,
    max_entity_info_module_icons_per_row = 3,
    max_entity_info_module_icon_rows = 1,
    module_info_icon_shift = {0, 0.9}
  }
}

local subgroup =
{
  type = "item-subgroup",
  name = "pollution-lab-subgroup",
  group = "combat",
  order = "b"
}

local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  localised_description = {"requires-pollution", names.required_pollution[name]},
  icons = lab.icons,
  flags = {},
  subgroup = subgroup.name,
  order = "aa-"..name,
  place_result = name,
  stack_size = 50
}

data:extend
{
  lab,
  item,
  subgroup
}
