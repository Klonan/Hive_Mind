local make_biter_player = function(name, graphics)
  local player = util.copy(data.raw.player.player)
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


  local idle = util.copy(biter_walk)
  for k, layer in pairs (idle.layers) do
    layer.animation_speed = 0.0000000000000001
  end

  player.name = name
  player.animations =
  {
    {
      idle = idle,
      idle_with_gun = idle,
      running = biter_walk,
      mining_with_tool = biter_attack,
      running_with_gun = player.animations[1].running_with_gun
    }
  }
  player.resistances = graphics.resistances
  player.running_speed = graphics.movement_speed * 0.75
  player.distance_per_frame = graphics.distance_per_frame
  player.crafting_categories = nil

  player.collision_box = graphics.collision_box
  player.selection_box = graphics.selection_box
  player.ticks_to_stay_in_combat = 0
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
  player.ticks_to_keep_gun = 0
  player.ticks_to_keep_aiming_direction = 0
  player.character_corpse = nil
  player.corpse = graphics.corpse
  player.dying_explosion = graphics.dying_explosion
  player.max_health = graphics.max_health
  player.healing_per_tick = graphics.healing_per_tick
  player.tool_attack_distance = graphics.attack_parameters.range + 1
  player.tool_attack_result = graphics.attack_parameters.ammo_type.action
  player.collision_mask = util.ground_unit_collision_mask()
  data:extend{player}
end

make_biter_player(names.players.biter_player, util.copy(data.raw.unit["medium-biter"]))
