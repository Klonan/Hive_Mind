local util = require("data/tf_util/tf_util")
local machine = util.copy(data.raw["assembling-machine"]["assembling-machine-2"])
local graphics = util.copy(data.raw["unit-spawner"]["biter-spawner"])
local shared = require("shared")

for k, animation in pairs (graphics.animations) do
  for k, layer in pairs (animation.layers) do
    layer.animation_speed = 0.5
    layer.hr_version.animation_speed = 0.5
  end
end

local name = names.deployers.biter_deployer
machine.name = name
machine.localised_name = {name}
machine.localised_description = {"requires-pollution", shared.required_pollution[name]}
machine.icon = graphics.icon
machine.icon_size = graphics.icon_size
machine.collision_box = util.area({0,0}, 2.5)
machine.selection_box = util.area({0,0}, 2)
machine.crafting_categories = {name}
machine.crafting_speed = 1
machine.ingredient_count = 100
machine.module_specification = nil
machine.minable = {result = name, mining_time = 5}
machine.flags = {--[["placeable-off-grid",]] "placeable-neutral", "player-creation", "no-automated-item-removal", "not-deconstructable"}
machine.is_deployer = true
machine.next_upgrade = nil
machine.dying_sound = graphics.dying_sound
machine.corpse = graphics.corpse
machine.dying_explosion = graphics.dying_explosion
machine.collision_mask = {"water-tile", "player-layer", "train-layer"}

machine.open_sound =
{
  {filename = "__base__/sound/creatures/worm-standup-small-1.ogg"},
  {filename = "__base__/sound/creatures/worm-standup-small-2.ogg"},
  {filename = "__base__/sound/creatures/worm-standup-small-3.ogg"},
}
machine.close_sound =
{
  {filename = "__base__/sound/creatures/worm-folding-1.ogg"},
  {filename = "__base__/sound/creatures/worm-folding-2.ogg"},
  {filename = "__base__/sound/creatures/worm-folding-3.ogg"},
}

machine.always_draw_idle_animation = true
machine.animation =
{
  north = graphics.animations[1],
  east = graphics.animations[2],
  south = graphics.animations[3],
  west = graphics.animations[4],
}
machine.working_sound = graphics.working_sound
machine.fluid_boxes =
{
  {
    production_type = "output",
    pipe_picture = nil,
    pipe_covers = nil,
    base_area = 1,
    base_level = 1,
    pipe_connections = {{ type= "output", position = {0, -3} }},
  },
  off_when_no_fluid_recipe = false
}
machine.scale_entity_info_icon = true
machine.energy_source = {type = "void"}
machine.create_ghost_on_death = false
machine.friendly_map_color = {g = 1}

local item = {
  type = "item",
  name = name,
  localised_name = {name},
  localised_description = {"requires-pollution", shared.required_pollution[name]},
  icon = machine.icon,
  icon_size = machine.icon_size,
  flags = {},
  subgroup = name,
  order = "aa-"..name,
  place_result = name,
  stack_size = 50
}

local category = {
  type = "recipe-category",
  name = name
}

local subgroup =
{
  type = "item-subgroup",
  name = name,
  group = "combat",
  order = "b"
}
--[[

  local recipe = {
    type = "recipe",
    name = name,
    localised_name = name,
    enabled = true,
    ingredients =
    {
      {names.items.biological_structure, 120},
    },
    energy_required = 100,
    result = name
  }

  ]]


data:extend
{
  machine,
  item,
  category,
  subgroup,
  --recipe
}
