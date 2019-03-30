--Basically, make them not collide with each other, and make them chart chunks.
names = require("shared")

local util = require("data/tf_util/tf_util")

local biter_names ={
  "small-biter",
  "medium-biter",
  "big-biter",
  "behemoth-biter",
}

local spitter_names =
{
  "small-spitter",
  "medium-spitter",
  "big-spitter",
  "behemoth-spitter"
}

local worm_names =
{
  "small-worm-turret",
  "medium-worm-turret",
  "big-worm-turret",
  "behemoth-worm-turret"
}

local make_biter_item = function(prototype, subgroup)
  local item =
  {
    type = "item",
    name = prototype.name,
    localised_name = prototype.localised_name,
    localised_description = prototype.pollution_to_join_attack,
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    stack_size = 1,
    order = prototype.order or prototype.name,
    subgroup = subgroup,
  }
  data:extend{item}
end

local make_biter_recipe = function(prototype, category)
  local recipe =
  {
    type = "recipe",
    name = prototype.name,
    localised_name = prototype.name,
    enabled = true,
    ingredients = {},
    energy_required = prototype.pollution_to_join_attack * 10,
    result = prototype.name,
    category = category
  }
  data:extend{recipe}
end


local worm_subgroup =
{
  type = "item-subgroup",
  name = "worm-subgroup",
  group = "combat",
  order = "d"
}
data:extend{worm_subgroup}

local make_worm_item = function(prototype)
  local item =
  {
    type = "item",
    name = prototype.name,
    localised_name = prototype.localised_name,
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    stack_size = 1,
    order = prototype.order or prototype.name,
    subgroup = worm_subgroup.name,
    place_result = prototype.name
  }
  data:extend{item}
end


local units = data.raw.unit


for k, name in pairs (biter_names) do
  local biter = units[name] or error("No Biter with name "..name)
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
  make_biter_item(biter, names.deployers.biter_deployer)
  make_biter_recipe(biter, names.deployers.biter_deployer)
  biter.friendly_map_color = {b = 1, g = 1}
end

for k, name in pairs (spitter_names) do
  local biter = units[name] or error("No Spitter with name "..name)
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
  make_biter_item(biter, names.deployers.spitter_deployer)
  make_biter_recipe(biter, names.deployers.spitter_deployer)
  biter.ai_settings.destroy_when_commands_fail = false
end

for k, name in pairs (worm_names) do
  local turret = data.raw.turret[name] or error("No worm with name "..name)
  make_worm_item(turret)
  table.insert(turret.flags, "player-creation")
end
