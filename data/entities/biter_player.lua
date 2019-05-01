local shared = require("shared")

local ugly_hack = function(layers)
  for k, layer in pairs (layers) do
    layer.direction_count = 18
    layer.frame_count = 9
    if layer.hr_version then
      layer.hr_version.direction_count = 18
      layer.hr_version.frame_count = 9
    end
  end
end

local make_biter_player = function(name, graphics)
  local player = util.copy(data.raw.character.character)
  local biter_walk = graphics.run_animation
  biter_walk.layers[2].apply_runtime_tint = true
  biter_walk.layers[2].hr_version.apply_runtime_tint = true
  biter_walk.layers[3].apply_runtime_tint = true
  biter_walk.layers[3].hr_version.apply_runtime_tint = true
  local biter_attack = graphics.attack_parameters.animation
  biter_attack.layers[2].apply_runtime_tint = true
  biter_attack.layers[2].hr_version.apply_runtime_tint = true
  biter_attack.layers[3].apply_runtime_tint = true
  biter_attack.layers[3].hr_version.apply_runtime_tint = true

  local running_with_gun = util.copy(biter_attack)
  ugly_hack(running_with_gun.layers)


  local idle = util.copy(biter_walk)
  for k, layer in pairs (idle.layers) do
    layer.animation_speed = 0.0000000000000001
    if layer.hr_version then
      layer.hr_version.animation_speed = 0.0000000000000001
    end
  end

  player.name = name
  player.localised_name = {name}
  player.icon = graphics.icon
  player.icon_size = graphics.icon_size
  player.animations =
  {
    {
      idle = idle,
      idle_with_gun = biter_attack,
      running = biter_walk,
      mining_with_tool = biter_attack,
      running_with_gun = running_with_gun
    }
  }
  player.resistances = graphics.resistances
  player.running_speed = graphics.movement_speed * 0.75
  player.distance_per_frame = graphics.distance_per_frame
  player.crafting_categories = nil

  player.build_distance = 100
  player.drop_item_distance = 100
  player.reach_distance = 100
  player.reach_resource_distance = 100
  player.item_pickup_distance = 0
  player.loot_pickup_distance = 0
  player.enter_vehicle_distance = 0

  player.collision_box = graphics.collision_box
  player.selection_box = graphics.selection_box
  player.inventory_size = 0
  player.light = nil
  local old_light = {
    {
      minimum_darkness = 0,
      intensity = 0.8,
      size = 150,
      color = {r=1.0, g = 0.2, b = 0.2}
    }
  }
  player.character_corpse = nil
  player.corpse = graphics.corpse
  player.dying_explosion = graphics.dying_explosion
  player.max_health = graphics.max_health * 1.5
  player.healing_per_tick = graphics.healing_per_tick
  player.tool_attack_distance = graphics.attack_parameters.range + 1
  player.tool_attack_result = graphics.attack_parameters.ammo_type.action
  player.ticks_to_keep_gun = graphics.attack_parameters.cooldown + 1
  player.ticks_to_keep_aiming_direction = 0
  player.ticks_to_stay_in_combat = 0
  player.collision_mask = util.ground_unit_collision_mask()
  player.mining_speed = 0
  graphics.attack_parameters.animation = nil
  local gun =
  {
    type = "gun",
    name = name.."-gun",
    localised_name = {"biter-gun"},
    icon = graphics.icon,
    icon_size = graphics.icon_size,
    subgroup = "gun",
    order = name.."-gun",
    attack_parameters = util.copy(graphics.attack_parameters),
    stack_size = 1
  }
  gun.attack_parameters.ammo_consumption_modifier = 0
  gun.attack_parameters.ammo_category = util.ammo_category(name)
  gun.attack_parameters.ammo_type = nil
  local ammo =
  {
    type = "ammo",
    name = name.."-ammo",
    localised_name = {"biter-gun"},
    icon = graphics.icon,
    icon_size = graphics.icon_size,
    ammo_type = graphics.attack_parameters.ammo_type,
    magazine_size = 1,
    subgroup = "ammo",
    order = name.."-ammo",
    stack_size = 1
  }
  ammo.ammo_type.category = util.ammo_category(name)
  data:extend
  {
    player,
    gun,
    ammo,
  }

end

make_biter_player(names.players.small_biter_player, util.copy(data.raw.unit["small-biter"]))
make_biter_player(names.players.medium_biter_player, util.copy(data.raw.unit["medium-biter"]))
make_biter_player(names.players.big_biter_player, util.copy(data.raw.unit["big-biter"]))
make_biter_player(names.players.behemoth_biter_player, util.copy(data.raw.unit["behemoth-biter"]))

--local flame = util.copy(data.raw.fire["fire-flame"])
--flame.name = "firestarter-flame"
--flame.initial_lifetime = 600
--flame.damage_per_tick.amount = 0
--flame.spawn_entity = flame.name

local fire_on_tree = data.raw.fire["fire-flame-on-tree"]
fire_on_tree.emissions_per_second = 0.05
fire_on_tree.damage_per_tick.amount = 3 / 60
fire_on_tree.spread_delay = 300
fire_on_tree.initial_lifetime = 600
fire_on_tree.tree_dying_factor = 0.98
fire_on_tree.maximum_spread_count = (2 ^ 16) - 1
fire_on_tree.light = {intensity = 0.25, size = 20, color = {r = 1, g = 0.5}}

local icon = "__base__/graphics/technology/refined-flammables.png"
local icon_size = 128


local firestarter_attack_parameters = {
  cooldown = 60 * 20,
  range = 5,
  type = "projectile",
  ammo_category = util.ammo_category("firestarter-gun"),
  ammo_consumption_modifier = 0,
  movement_slow_down_cooldown = 30
}

local firestarter_ammo_type =
{
  action = {
    action_delivery = {
      target_effects =
      {
        type = "create-fire",
        entity_name = fire_on_tree.name
      },
      type = "instant"
    },
    type = "direct"
  },
  category = util.ammo_category("firestarter-gun"),
  target_type = "entity",
}

local firestarter_gun =
{
  type = "gun",
  name = shared.firestarter_gun,
  localised_name = {shared.firestarter_gun},
  icon = icon,
  icon_size = icon_size,
  subgroup = "gun",
  order = shared.firestarter_gun,
  attack_parameters = firestarter_attack_parameters,
  stack_size = 1
}

local firestarter_ammo =
{
  type = "ammo",
  name = shared.firestarter_ammo,
  localised_name = {shared.firestarter_gun},
  icon = icon,
  icon_size = icon_size,
  ammo_type = firestarter_ammo_type,
  magazine_size = 1,
  subgroup = "ammo",
  order = shared.firestarter_gun,
  stack_size = 1
}

data:extend
{
  firestarter_gun,
  firestarter_ammo,
  --flame
}
