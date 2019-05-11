
local name = names.pollution_lab
local util = require("data/tf_util/tf_util")

local graphics = util.copy(data.raw.lab.lab)
--error(serpent.block(graphics))
--local animation = graphics.animations[1]
local lab_scale = 1

local tint = {r = 1, b = 1, g = 0.5}
util.recursive_hack_tint(graphics, tint)
util.recursive_hack_make_hr(graphics)
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
util.recursive_hack_make_hr(spawner_graphics)
util.recursive_hack_scale(spawner_graphics, 6/5)
util.recursive_hack_tint(spawner_graphics, tint)

local on_animation = {layers = {}}

for k, layer in pairs (spawner_graphics.animations[2].layers) do
  if layer.frame_count == 8 then
    layer.repeat_count = 1
  end
  table.insert(on_animation.layers, layer)
end

for k, layer in pairs (graphics.on_animation.layers or graphics.on_animation) do
  if layer.frame_count == 33 then
    layer.frame_count = 16
  end
  if layer.repeat_count == 33 then
    layer.repeat_count = 16
  end
  util.shift_layer(layer, {0, -2.2})
  table.insert(on_animation.layers, layer)
end


--error(serpent.block(on_animation))

local off_animation = {layers = {}}

for k, layer in pairs (spawner_graphics.animations[2].layers) do
  local new = util.copy(layer)
  new.frame_count = 1
  new.run_mode = nil
  new.repeat_count = 1
  table.insert(off_animation.layers, new)
end

for k, layer in pairs (graphics.off_animation.layers or graphics.off_animation) do
  util.shift_layer(layer, {0, -2.2})
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
      scale = 0.5,
      shift = {0, -8}
    }
  },
  flags = {"placeable-player", "player-creation", --[["placeable-off-grid"]]},
  minable = nil,
  max_health = 150,
  corpse = nil,
  dying_explosion = spawner_graphics.dying_explosion,
  collision_box = util.area({0,0}, 3),
  selection_box = util.area({0,0}, 3),
  collision_mask = util.buildable_on_creep_collision_mask(),
  light = {intensity = 1, size = 20, color = tint},
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
  }
}

local subgroup =
{
  type = "item-subgroup",
  name = "pollution-lab-subgroup",
  group = "enemies",
  order = "b"
}

local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  localised_description = {"requires-pollution", names.required_pollution[name] * names.pollution_cost_multiplier},
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
