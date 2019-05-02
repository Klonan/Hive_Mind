
shared = require("shared")

local util = require("data/tf_util/tf_util")

local default_unlocked = shared.default_unlocked

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
    enabled = default_unlocked[prototype.name],
    ingredients = {},
    energy_required = prototype.pollution_to_join_attack * 5,
    result = prototype.name,
    category = category
  }
  data:extend{recipe}
end

local make_unlock_technology = function(prototype, cost)
  if default_unlocked[prototype.name] then return end
  local tech =
  {
    type = "technology",
    name = "hivemind-unlock-"..prototype.name,
    localised_name = {"hivemind-unlock", prototype.localised_name or {"entity-name."..prototype.name}},
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    icons = prototype.icons,
    enabled = false,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = prototype.name
      },
    },
    unit =
    {
      count = cost,
      ingredients = {{names.pollution_proxy, 1}},
      time = 1
    },
    prerequisites = {},
    order = prototype.type..prototype.order..prototype.name
  }
  data:extend({tech})
end

local worm_category =
{
  type = "recipe-category",
  name = "worm-crafting-category"
}

data:extend{worm_category}

local make_worm_recipe = function(prototype, category, energy)
  local recipe =
  {
    type = "recipe",
    name = prototype.name,
    localised_name = prototype.localised_name,
    enabled = default_unlocked[prototype.name],
    ingredients = {},
    energy_required = math.huge,
    result = prototype.name,
    category = worm_category.name
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
  make_unlock_technology(biter, biter.pollution_to_join_attack * 50)
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
  make_unlock_technology(biter, biter.pollution_to_join_attack * 50)
  biter.ai_settings = biter.ai_settings or {}
  biter.ai_settings.destroy_when_commands_fail = false
  biter.friendly_map_color = {b = 1, g = 1}
  biter.affected_by_tiles = biter.affected_by_tiles or true
  biter.localised_description = {"requires-pollution", biter.pollution_to_join_attack}
end

local worm_ammo_category = util.ammo_category("worm-biological")

local just_guess = function(turret)
  return turret.max_health * turret.attack_parameters.damage_modifier / 100
end

local make_worm = function(turret)
  make_worm_item(turret)
  make_worm_recipe(turret, worm_category, shared.required_pollution[turret.name])
  make_unlock_technology(turret, (shared.required_pollution[turret.name] or just_guess(turret)) * 50)
  table.insert(turret.flags, "player-creation")
  turret.create_ghost_on_death = false
  turret.friendly_map_color = {b = 1, g = 0.5}
  turret.localised_description = {"requires-pollution", shared.required_pollution[turret.name]}
  turret.collision_mask = {"water-tile", "player-layer", "train-layer"}
  if turret.attack_parameters.ammo_type.category == "biological" then
    turret.attack_parameters.ammo_type.category = worm_ammo_category
  end
  util.remove_from_list(turret.flags, "placeable-off-grid")
end


local units = data.raw.unit

for name, unit in pairs (units) do
  if unit.name:find("biter") then
    make_biter(unit)
  elseif unit.name:find("spitter") then
    make_spitter(unit)
  end
end

--The acid splashes are still OP.

for k, fire in pairs (data.raw.fire) do
  if fire.name:find("acid%-splash%-fire") then
    fire.on_damage_tick_effect = nil
  end
end

local turrets = data.raw.turret

--Overall, they just have too large a range.

--[[
range_worm_small    = 25
range_worm_medium   = 30
range_worm_big      = 38
range_worm_behemoth = 48
]]
--Laser turret is 24, flamethrower is 30, so lets make behemoth 40 and scale the rest accordingly

turrets["small-worm-turret"].attack_parameters.range = 25
turrets["medium-worm-turret"].attack_parameters.range = 30
turrets["big-worm-turret"].attack_parameters.range = 35
turrets["behemoth-worm-turret"].attack_parameters.range = 40

--Also the damage is ridiculous:
--[[damage_modifier_worm_small    = 36
damage_modifier_worm_medium   = 48
damage_modifier_worm_big      = 72
damage_modifier_worm_behemoth = 96]]

--lets say behemoth is 60

turrets["small-worm-turret"].attack_parameters.damage_modifier = 15
turrets["medium-worm-turret"].attack_parameters.damage_modifier = 30
turrets["big-worm-turret"].attack_parameters.damage_modifier = 45
turrets["behemoth-worm-turret"].attack_parameters.damage_modifier = 60
--error(serpent.block(turrets["behemoth-worm-turret"].attack_parameters))

for name, turret in pairs (turrets) do
  if turret.name:find("worm%-turret") then
    make_worm(turret)
  end
end

for name, spawner in pairs (data.raw["unit-spawner"]) do
  spawner.collision_mask = {"water-tile", "player-layer", "train-layer"}
end
