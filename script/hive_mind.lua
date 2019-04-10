local names = require("shared")

local script_data =
{
  player_lights = {}
}

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
  enemy_force.set_friend(force, true)
  enemy_force.share_chart = true
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
  local index = script_data.player_lights[player.index]
  if index and rendering.is_valid(index) then return end
  script_data.player_lights[player.index] = rendering.draw_light{
    sprite = "utility/light_medium",
    scale = 50,
    intensity = 0.8,
    color = {r = 0.8, b = 0.2, g = 0.2},
    target = player.character,
    surface = player.surface,
    forces = {player.force},
    minimum_darkness = 0
  }
end

local quickbar =
{
  names.deployers.biter_deployer,
  names.deployers.spitter_deployer,
  "small-worm-turret",
  "medium-worm-turret",
  "big-worm-turret",
  "behemoth-worm-turret"
}

local characters = 
{
  [names.players.behemoth_biter_player] = 0.75,
  [names.players.big_biter_player] = 0.5,
  [names.players.medium_biter_player] = 0.25,
  [names.players.small_biter_player] = 0
}

local create_character = function(player)

  local force = player.force
  local factor = force.evolution_factor
  local name
  for character, minimum_factor in pairs (characters) do
    if factor > minimum_factor then 
      name = character
      break
    end
  end
  local surface = player.surface
  player.character = surface.create_entity
  {
    name = name,
    position = surface.find_non_colliding_position(name, force.get_spawn_position(surface), 0, 1),
    force = force
  }
  player.character.get_inventory(defines.inventory.player_guns).insert(player.character.name.."-gun")
  player.character.get_inventory(defines.inventory.player_ammo).insert(player.character.name.."-ammo")
  add_biter_light(player)

  player.set_active_quick_bar_page(1, 1)
  for k, filter in pairs (quickbar) do
    player.set_quick_bar_slot(k, filter)
  end

end

local area = function(position, radius)
  return {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}
end

local get_hive_entities = function(entity)
  local map = {}
  local surface = entity.surface
  local find = surface.find_entities_filtered
  local params = {force = "enemy"}
  local radius = 8
  local count = 1
  local function recursive_find_neighbors(entity)
    if map[entity.unit_number] then return end
    map[entity.unit_number] = entity
    params.area = area(entity.position, radius)
    for k, nearby in pairs (find(params)) do
      recursive_find_neighbors(nearby)
      count = count + 1
    end
  end
  recursive_find_neighbors(entity)
  game.print(count)
  return map
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
    local spawners = surface.find_entities_filtered{area = area, type = "unit-spawner", force = "enemy", limit = nil}
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
  local entities = get_hive_entities(spawner)
  for k, nearby in pairs (entities) do
    local deploy_name = deploy_map[nearby.name]
    if deploy_name then
      surface.create_entity{name = deploy_name, position = nearby.position, force = force, direction = (math.random(4) - 1) * 2, raise_built = true}
      nearby.destroy()
    elseif nearby.type == "unit" or nearby.type == "turret" then
      nearby.force = force
    end
  end

  player.character = nil
  player.force = force
  create_character(player)

end

local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if player.force ~= get_hivemind_force() then return end

  player.character.destroy()
  create_character(player)

end

local on_tick = function(event)
  if game.forces["hivemind"] then
    if event.tick % 297 == 0 then
      check_recipes(game.forces["hivemind"])
    end
  end
end

local pollution_values =
{
  wood = 1,
  coal = 1.5,
  stone = 0.1
}

local on_player_mined_entity = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local force = player.force

  if not (force and force.valid and force == get_hivemind_force()) then return end

  local entity = event.entity
  if not (entity and entity.valid) then return end

  local buffer = event.buffer
  if not (buffer and buffer.valid) then return end
  local surface = entity.surface
  local position = entity.position
  local remove = buffer.remove
  local total_pollution = 0
  for name, count in pairs (buffer.get_contents()) do
    local pollution = pollution_values[name]
    if pollution then
      total_pollution = total_pollution + (pollution * count)
    end
    remove{name = name, count = count}
  end
  if total_pollution == 0 then return end

  surface.create_entity{name = "flying-text", position = position, text = "Pollution +"..total_pollution, color = {r = 1, g = 0.2, b = 0.2}}
  surface.pollute(position, total_pollution)

end

local on_player_joined_game = function(event)
  local player = game.get_player(event.player_index)
  if player.force.name == "hivemind" then
    add_biter_light(player)
  end
end


remote.add_interface("hive_mind",
{
  test = function(player) return join_hive(player) end
})

local events =
{
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_player_joined_game] = on_player_joined_game,

}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.hive_mind = global.hive_mind or script_data
  lib.on_event = handler(events)
end

lib.on_load = function()
  script_data = global.hive_mind or script_data
  lib.on_event = handler(events)
end

return lib