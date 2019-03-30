local names = require("shared")

local recipe_evolution_factors =
{
  ["small-biter"] = 0,
  ["medium-biter"] = 0.25,
  ["big-biter"] = 0.5,
  ["behemoth-biter"] = 0.75,
  ["small-spitter"] = 0,
  ["medium-spitter"] = 0.25,
  ["big-spitter"] = 0.5,
  ["behemoth-spitter"] = 0.75,
}

local check_recipes = function(force)
  local current_evolution_factor = force.evolution_factor
  local recipes = force.recipes
  for name, evolution_factor in pairs (recipe_evolution_factors) do
    if current_evolution_factor >= evolution_factor then
      recipes[name].enabled = true
    end
  end
end


local get_hivemind_force = function()
  if game.forces["hivemind"] then return game.forces["hivemind"] end
  local force = game.create_force("hivemind")
  local enemy_force = game.forces.enemy
  enemy_force.set_cease_fire(force, true)
  force.set_cease_fire(enemy_force, true)
  force.disable_research()
  force.evolution_factor = enemy_force.evolution_factor
  for k, recipe in pairs (force.recipes) do
    recipe.enabled = false
  end
  check_recipes(force)
  return force
end

local deploy_map =
{
  ["biter-spawner"] = names.deployers.biter_deployer,
  ["spitter-spawner"] = names.deployers.spitter_deployer,
}

local add_biter_light = function(player)
  rendering.draw_light{
    sprite = "utility/light_medium",
    scale = 50,
    intensity = 0.8,
    color = {r = 0.8, b = 0.2, g = 0.2},
    target = player.character,
    surface = player.surface,
    players = {player},
    minimum_darkness = 0
  }
end

local join_hive = function(player)
  local surface = player.surface
  local origin = player.force.get_spawn_position(surface)
  local radius = 100
  local spawner
  local keep_going = true
  while keep_going do
    local area = {{origin.x - radius, origin.y - radius},{origin.x + radius, origin.y + radius}}
    radius = radius + 100
    if radius > 2000 then
      area = nil
      keep_going = false
    end
    local spawners = surface.find_entities_filtered{area = area, type = "unit-spawner", force = "enemy", limit = 20}
   local count = #spawners
   if count > 0 then
     spawner = spawners[math.random(count)]
     break
    end
  end
  if not spawner then return end
  local position = spawner.position
  local force = get_hivemind_force()
  force.set_spawn_position(position, surface)
  local radius = 64
  local area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}
  for k, nearby in pairs (surface.find_entities_filtered{force = "enemy", area = area}) do
    local deploy_name = deploy_map[nearby.name]
    if deploy_name then
      surface.create_entity{name = deploy_name, position = nearby.position, force = force, direction = nearby.direction, raise_built = true}
      nearby.destroy()
    elseif nearby.type == "unit" or nearby.type == "turret" then
      nearby.force = force
    end
  end

  player.character = nil
  player.force = force
  player.character = surface.create_entity
  {
    name = names.players.biter_player,
    position = surface.find_non_colliding_position(names.players.biter_player, position, 0, 1),
    force = force
  }
  add_biter_light(player)


end

local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if player.force ~= get_hivemind_force() then return end

  player.character.destroy()
  player.character = player.surface.create_entity
  {
    name = names.players.biter_player,
    position = player.surface.find_non_colliding_position(names.players.biter_player, player.position, 0, 1),
    force = player.force
  }
  add_biter_light(player)


end

local on_tick = function(event)
  if game.forces["hivemind"] then
    if event.tick % 297 == 0 then
      check_recipes(game.forces["hivemind"])
    end
  end
end

local on_player_mined_entity = function(event)
  local player = game.get_player(event.player_index)


end


remote.add_interface("hive_mind",
{
  test = function(player) return join_hive(player) end
})

local events =
{
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_player_mined_entity] = on_player_mined_entity
}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.hive_mind = global.hive_mind or data
  lib.on_event = handler(events)
end

lib.on_load = function()
  data = global.hive_mind
  lib.on_event = handler(events)
end

return lib