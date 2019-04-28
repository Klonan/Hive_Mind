
local name = names.pollution_lab
local util = require("data/tf_util/tf_util")
local graphics = util.copy(data.raw.lab.lab)
--local animation = graphics.animations[1]
local lab_scale = 0.5

local tint = {r = 0.8, b = 0.8, g = 0.2}
util.recursive_hack_tint(graphics, tint)
util.recursive_hack_scale(graphics, lab_scale)
--for k, animation in pairs ({graphics.on_animation, graphics.off_animation}) do
--  for k, layer in pairs (animation.layers) do
--      layer.tint = tint
--      if layer.hr_version then
--        layer.hr_version.tint = tint
--      end
--  end
--end

local spawner_graphics = util.copy(data.raw["unit-spawner"]["biter-spawner"])
util.recursive_hack_scale(spawner_graphics, 3/5)
util.recursive_hack_tint(spawner_graphics, tint)

local on_animation = {layers = {}}

for k, layer in pairs (spawner_graphics.animations[2].layers) do
  if layer.frame_count == 8 then
    layer.repeat_count = 1
    layer.hr_version.repeat_count = 1
  end
  table.insert(on_animation.layers, layer)
end

for k, layer in pairs (graphics.on_animation.layers) do
  if layer.frame_count == 33 then
    layer.frame_count = 16
    layer.hr_version.frame_count = 16
  end
  if layer.repeat_count == 33 then
    layer.repeat_count = 16
    layer.hr_version.repeat_count = 16
  end
  util.shift_layer(layer, {0, -1.1})
  table.insert(on_animation.layers, layer)
end


--error(serpent.block(on_animation))

local off_animation = {layers = {}}

for k, layer in pairs (spawner_graphics.animations[2].layers) do
  local new = util.copy(layer)
  new.frame_count = 1
  new.hr_version.frame_count = 1
  new.run_mode = nil
  new.hr_version.run_mode = 1
  new.repeat_count = 1
  new.hr_version.repeat_count = 1
  table.insert(off_animation.layers, new)
end

for k, layer in pairs (graphics.off_animation.layers) do
  util.shift_layer(layer, {0, -1.1})
  table.insert(off_animation.layers, layer)
end





local lab =
{
  type = "lab",
  name = name,
  localised_name = name,
  icons =
  {
    {
      icon = spawner_graphics.icon,
      icon_size = spawner_graphics.icon_size,
      tint = tint
    },
    {
      icon = graphics.icon,
      icon_size = graphics.icon_size,
      tint = tint,
      scale = lab_scale,
      shift = {0, -8}
    }
  },
  flags = {"placeable-player", "player-creation", "placeable-off-grid"},
  minable = nil,
  max_health = 150,
  corpse = nil,
  dying_explosion = spawner_graphics.dying_explosion,
  collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  collision_mask = util.buildable_on_creep_collision_mask(),
  light = {intensity = 0.5, size = 8, color = {r = 0.5, g = 0.5, b = 0}},
  on_animation = on_animation,
  off_animation = off_animation,
  working_sound = spawner_graphics.working_sound,
  vehicle_impact_sound = spawner_graphics.vehicle_impact_sound,
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
