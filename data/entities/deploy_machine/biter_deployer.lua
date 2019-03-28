local machine = util.copy(data.raw["assembling-machine"]["assembling-machine-2"])
local graphics = util.copy(data.raw["unit-spawner"]["biter-spawner"])

for k, animation in pairs (graphics.animations) do
  for k, layer in pairs (animation.layers) do
    layer.animation_speed = 100
    layer.hr_version.animation_speed = 100
  end
end

local name = names.deployers.biter_deployer
machine.name = name
machine.localised_name = name
machine.icon = graphics.icon
machine.icon_size = graphics.icon_size
machine.collision_box = {{-2.8, -2.8},{2.8, 2.8}}
machine.selection_box = {{-3, -3},{3, 3}}
machine.crafting_categories = {name}
machine.crafting_speed = 0.01
machine.ingredient_count = 100
machine.module_specification = nil
machine.minable = {result = name, mining_time = 5}
machine.flags = {"placeable-neutral", "player-creation", "no-automated-item-removal"}
machine.is_deployer = true
machine.next_upgrade = nil
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

local item = {
  type = "item",
  name = name,
  icon = machine.icon,
  icon_size = machine.icon_size,
  flags = {},
  subgroup = "biter-deployer",
  order = "aa-"..name,
  place_result = name,
  stack_size = 50
}

local category = {
  type = "recipe-category",
  name = "biter-deployer"
}

local subgroup =
{
  type = "item-subgroup",
  name = "biter-deployer",
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