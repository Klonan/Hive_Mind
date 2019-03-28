--Basically, make them not collide with each other, and make them chart chunks.
names = require("shared")

local util = require("data/tf_util/tf_util")

local biter_names ={
  "small-biter",
  "medium-biter",
  "big-biter",
  "behemoth-biter",
  "small-spitter",
  "medium-spitter",
  "big-spitter",
  "behemoth-spitter"
}

local make_biter_item = function(prototype)
  local item =
  {
    type = "item",
    name = prototype.name,
    localised_name = prototype.localised_name,
    localised_description = prototype.pollution_to_join_attack,
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    stack_size = 10,
    order = prototype.order or prototype.name,
    subgroup = "biter-deployer",
  }
  data:extend{item}
end

local make_biter_recipe = function(prototype)
  local recipe =
  {
    type = "recipe",
    name = prototype.name,
    localised_name = prototype.name,
    enabled = true,
    ingredients = {},
    energy_required = prototype.pollution_to_join_attack / 10,
    result = prototype.name,
    category = "biter-deployer"
  }
  data:extend{recipe}
end


local units = data.raw.unit


for k, name in pairs (biter_names) do
  local biter = units[name]
  if not biter then error("No Biter with name "..name) end
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
  make_biter_item(biter)
  make_biter_recipe(biter)
end
