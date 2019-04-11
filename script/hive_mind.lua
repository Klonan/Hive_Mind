local names = require("shared")
local mod_gui = require("mod-gui")

local script_data =
{
  player_lights = {},
  hive_mind_forces = {},
  previous_life_data = {}
}

local recipe_evolution_factors =
{
  ["small-biter"] = 0,
  ["medium-biter"] = 0.2,
  ["big-biter"] = 0.5,
  ["behemoth-biter"] = 0.9,
  ["small-spitter"] = 0,
  ["medium-spitter"] = 0.2,
  ["big-spitter"] = 0.5,
  ["behemoth-spitter"] = 0.9,
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

local max_hivemind_forces = 10
local can_create_hivemind_force = function()
  return table_size(script_data.hive_mind_forces) < max_hivemind_forces
end

local convert_nest

local create_hivemind_force = function(player)
  local current_count = table_size(script_data.hive_mind_forces)
  local force = game.create_force("hivemind-"..current_count.."-"..game.tick)
  force.share_chart = true

  local enemy_force = game.forces.enemy
  enemy_force.set_cease_fire(force, true)
  enemy_force.set_friend(force, true)
  enemy_force.share_chart = true
  force.set_cease_fire(enemy_force, true)
  force.set_friend(enemy_force, true)

  for index, other_force in pairs (script_data.hive_mind_forces) do
    other_force.set_cease_fire(force, true)
    other_force.set_friend(force, true)
    force.set_cease_fire(other_force, true)
    force.set_friend(other_force, true)
  end

  force.disable_research()
  force.evolution_factor = enemy_force.evolution_factor
  for k, recipe in pairs (force.recipes) do
    recipe.enabled = false
  end
  check_recipes(force)

  convert_nest(player, force)

  script_data.hive_mind_forces[force.index] = force
  return force
end

choose_hivemind_force = function(player)
  if can_create_hivemind_force() then
    return create_hivemind_force(player)
  end
  local array = {}
  local count = 1
  for index, force in pairs (script_data.hive_mind_forces) do
    array[count] = force
    count = count + 1
  end
  return array[1 + (player.index % count)]
end

local is_hivemind_force = function(force)
  return script_data.hive_mind_forces[force.index] ~= nil
end

local deploy_map =
{
  ["biter-spawner"] = names.deployers.biter_deployer,
  ["spitter-spawner"] = names.deployers.spitter_deployer,
}

local add_biter_light = function(player)
  local index = script_data.player_lights[player.index]
  if index and rendering.is_valid(index) then return end
  script_data.player_lights[player.index] = rendering.draw_light
  {
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
  local name = names.players.small_biter_player
  for character, minimum_factor in pairs (characters) do
    if factor >= minimum_factor then
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
  --local count = 1
  local function recursive_find_neighbors(entity)
    local unit_number = entity.unit_number
    if (not unit_number) or map[unit_number] then return end
    map[entity.unit_number] = entity
    params.area = area(entity.position, radius)
    for k, nearby in pairs (find(params)) do
      recursive_find_neighbors(nearby)
      --count = count + 1
    end
  end
  recursive_find_neighbors(entity)
  --game.print(count)
  return map
end

convert_nest = function(player, force)
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
end


local join_hive_button =
{
  type = "button",
  name = "join-hive-button",
  caption = "JOIN THE HIVE"
}

local leave_hive_button =
{
  type = "button",
  name = "leave-hive-button",
  caption = "LEAVE THE HIVE :("
}

local join_hive
local leave_hive

local actions =
{
  [join_hive_button.name] = function(event) join_hive(game.get_player(event.player_index)) end,
  [leave_hive_button.name] = function(event) leave_hive(game.get_player(event.player_index)) end,
}
local gui_init = function(player)
  local gui = mod_gui.get_button_flow(player)

  for name, action in pairs (actions) do
    if gui[name] then gui[name].destroy() end
  end

  local element
  if is_hivemind_force(player.force) then
    element = leave_hive_button
  else
    element = join_hive_button
  end

  gui.add(element)
end

join_hive = function(player)
  local force = choose_hivemind_force(player)
  local previous_life_data =
  {
    force = player.force,
    character = player.character,
    character_name = player.character and player.character.name,
    controller = player.controller_type,
    position = player.position
  }
  script_data.previous_life_data[player.index] = previous_life_data
  player.character = nil
  player.force = force
  --player.game_view_settings.show_controller_gui = false
  create_character(player)
  gui_init(player)
end

local check_hivemind_disband = function(force)
  game.print("checking disband of force "..force.name)

  if #force.players > 0 then
    --still players on this force, so its alright.
    return
  end

  --We just need to turn the crafting machines back into spawners.

  local map = {}
  for k, v in pairs (deploy_map) do
    map[v] = k
  end

  local destroy_map_type =
  {
    radar = true
  }

  local params = {force = force}
  for surface_index, surface in pairs(game.surfaces) do
    for k, entity in pairs (surface.find_entities_filtered(params)) do
      if map[entity.name] then
        surface.create_entity{name = map[entity.name], position = entity.position, force = entity.force}
        entity.destroy()
      elseif destroy_map_type[entity.type] then
        entity.destroy()
      end
    end
  end

  script_data.hive_mind_forces[force.index] = nil

  game.print("Disbanding "..force.name)
  game.merge_forces(force, game.forces.enemy)


end

leave_hive = function(player)
  local current_hivemind_force = player.force

  local previous_life_data = script_data.previous_life_data[player.index]
  local force = previous_life_data.force
  local character = previous_life_data.character
  local controller = previous_life_data.controller
  local character_name = previous_life_data.character_name

  local biter = player.character
  player.character = nil
  if biter and biter.valid then biter.die() end

  player.force = force
  if character then
    --he used to have a character
    if character.valid then
      player.character = character
    else
      --however his old character died or something...
      player.character = surface.create_entity
      {
        name = character_name,
        position = player.surface.find_non_colliding_position(character_name, force.get_spawn_position(player.surface), 0, 1),
        force = force
      }
    end
  else
    player.teleport(previous_life_data.position)
  end
  gui_init(player)
  --player.game_view_settings.show_controller_gui = true
  check_hivemind_disband(current_hivemind_force)

end

local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if not is_hivemind_force(player.force) then return end
  player.character.destroy()
  create_character(player)

end

local on_tick = function(event)
  if event.tick % 297 ~= 0 then return end
  for index, force in pairs (script_data.hive_mind_forces) do
    if force.valid then
      check_recipes(force)
    else
      script_data.hive_mind_forces[index] = nil
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

  if not (force and force.valid and is_hivemind_force(force)) then return end

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

local on_gui_click = function(event)
  local gui = event.element
  if not (gui and gui.valid) then return end
  local name = gui.name
  if name and actions[name] then return actions[name](event) end
end

local on_player_joined_game = function(event)
  local player = game.get_player(event.player_index)
  if is_hivemind_force(player.force) then
    add_biter_light(player)
  end
  gui_init(player)
end

local on_player_created = function(event)
  local player = game.get_player(event.player_index)
  gui_init(player)
end

remote.add_interface("hive_mind",
{
  --test = function(player) return join_hive(player) end
})

local events =
{
  [defines.events.on_player_respawned] = on_player_respawned,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_player_joined_game] = on_player_joined_game,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_gui_click] = on_gui_click,
}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.hive_mind = global.hive_mind or script_data
  lib.on_event = handler(events)
  for k, player in pairs (game.players) do
    gui_init(player)
  end
end

lib.on_load = function()
  script_data = global.hive_mind or script_data
  lib.on_event = handler(events)
end

return lib