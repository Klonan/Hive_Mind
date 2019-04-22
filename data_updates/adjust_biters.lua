
shared = require("shared")

local util = require("data/tf_util/tf_util")

local make_biter_item = function(prototype, subgroup)
  local item =
  {
    type = "item",
    name = prototype.name,
    localised_name = prototype.localised_name,
    localised_description = {"requires-pollution", prototype.pollution_to_join_attack},
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    stack_size = 1,
    order = prototype.order or prototype.name,
    subgroup = subgroup,
    place_result = prototype.name
  }
  data:extend{item}
end

local make_biter_recipe = function(prototype, category)
  local recipe =
  {
    type = "recipe",
    name = prototype.name,
    localised_name = prototype.localised_name,
    enabled = true,
    ingredients = {},
    energy_required = prototype.pollution_to_join_attack * 5,
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
    localised_description = {"requires-pollution", shared.required_pollution[prototype.name]},
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    stack_size = 1,
    order = prototype.order or prototype.name,
    subgroup = worm_subgroup.name,
    place_result = prototype.name
  }
  data:extend{item}
end

local make_biter = function(biter)
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
  make_biter_item(biter, names.deployers.biter_deployer)
  make_biter_recipe(biter, names.deployers.biter_deployer)
  biter.ai_settings = biter.ai_settings or {}
  biter.ai_settings.destroy_when_commands_fail = false
  biter.friendly_map_color = {b = 1, g = 1}
  biter.affected_by_tiles = biter.affected_by_tiles or true
  biter.localised_description = {"requires-pollution", biter.pollution_to_join_attack}
end

local make_spitter = function(biter)
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
  make_biter_item(biter, names.deployers.spitter_deployer)
  make_biter_recipe(biter, names.deployers.spitter_deployer)
  biter.ai_settings = biter.ai_settings or {}
  biter.ai_settings.destroy_when_commands_fail = false
  biter.friendly_map_color = {b = 1, g = 1}
  biter.affected_by_tiles = biter.affected_by_tiles or true
  biter.localised_description = {"requires-pollution", biter.pollution_to_join_attack}
end

local make_worm = function(turret)
  make_worm_item(turret)
  table.insert(turret.flags, "player-creation")
  turret.create_ghost_on_death = false
  turret.friendly_map_color = {b = 1, g = 0.5}
  turret.localised_description = {"requires-pollution", shared.required_pollution[name]}
  turret.collision_mask = util.buildable_on_creep_collision_mask()
end


local units = data.raw.unit

for name, unit in pairs (units) do
  if unit.name:find("biter") then
    make_biter(unit)
  elseif unit.name:find("spitter") then
    make_spitter(unit)
  end
end

local turrets = data.raw.turret

for name, turret in pairs (turrets) do
  if turret.name:find("worm%-turret") then
    make_worm(turret)
  end
end

for name, spawner in pairs (data.raw["unit-spawner"]) do
  spawner.collision_mask = {"water-tile", "player-layer", "train-layer"}
end
