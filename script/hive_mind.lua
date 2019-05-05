local names = require("shared")
local mod_gui = require("mod-gui")

local script_data =
{
  player_lights = {},
  previous_life_data = {},
  player_spawns = {},
  force_balance = false
}

local convert_nest

local be_friends = function(force_1, force_2)
  force_1.set_cease_fire(force_2, true)
  force_1.set_friend(force_2, true)
  force_2.set_cease_fire(force_1, true)
  force_2.set_friend(force_1, true)
end

local is_hivemind_technology = function(technology)
  local ingredients = technology.research_unit_ingredients
  for k, ingredient in pairs (ingredients) do
    if ingredient.type == "item" and ingredient.name == names.pollution_proxy then
      return true
    end
  end
  return false
end

local reset_hivemind_force = function()
  local force = game.forces.hivemind
  if not force then return end
  force.reset()

  force.share_chart = true

  local enemy_force = game.forces.enemy
  enemy_force.share_chart = true
  be_friends(force, enemy_force)

  if game.forces.spectator then
    be_friends(force, game.forces.spectator)
  end

  for k, tech in pairs (force.technologies) do
    tech.enabled = is_hivemind_technology(tech)
  end

  force.evolution_factor = enemy_force.evolution_factor
  for k, recipe in pairs (force.recipes) do
    recipe.enabled = names.default_unlocked[recipe.name]
  end

end


local create_hivemind_force = function()

  local force = game.create_force("hivemind")
  reset_hivemind_force()
  return force
end

local get_hivemind_force = function()
  return game.forces.hivemind or create_hivemind_force()
end

local is_hivemind_force = function(force)
  return force.name == "hivemind"
end

local deploy_map =
{
  ["biter-spawner"] = names.deployers.biter_deployer,
  ["spitter-spawner"] = names.deployers.spitter_deployer,
}

local light_color = {r = 1, b = 0, g = 0.6}

local add_biter_light = function(player)
  if not player.character then return end
  local index = script_data.player_lights[player.index]
  if index and rendering.is_valid(index) then return end
  script_data.player_lights[player.index] = rendering.draw_light
  {
    sprite = "utility/light_medium",
    scale = 50,
    intensity = 0.5,
    color = light_color,
    target = player.character,
    surface = player.surface,
    forces = {player.force},
    minimum_darkness = 0
  }
end

local reset_gun_inventory = function(player)
  if not player.character then return end
  local gun_inventory = player.character.get_inventory(defines.inventory.character_guns)
  local ammo_inventory = player.character.get_inventory(defines.inventory.character_ammo)
  gun_inventory.clear()
  ammo_inventory.clear()
  gun_inventory.insert(player.character.name.."-gun")
  ammo_inventory.insert(player.character.name.."-ammo")
  gun_inventory.insert(names.firestarter_gun)
  ammo_inventory.insert(names.firestarter_ammo)
end

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
  local origin = script_data.player_spawns[player.index] or {0,0}
  local closest = surface.get_closest(origin, surface.find_entities_filtered{force = player.force, type = "assembling-machine"})
  local position
  if closest then
    position = surface.find_non_colliding_position(name, closest.position, 64, 1)
  else
    position = surface.find_non_colliding_position(name, origin, 64, 1)
  end
  if not position then return end
  player.character = surface.create_entity
  {
    name = name,
    position = position,
    force = force
  }
  reset_gun_inventory(player)
  add_biter_light(player)

end

local get_hive_entities = function(entity)
  local map = {}
  local surface = entity.surface
  local find = surface.find_entities_filtered
  local params = {force = "enemy", type = {"turret", "unit", "unit-spawner"}, radius = 20}
  --local count = 1
  local function recursive_find_neighbors(entity)
    local unit_number = entity.unit_number
    if (not unit_number) or map[unit_number] then return end
    map[entity.unit_number] = entity
    params.position = entity.position
    if entity.type == "unit-spawner" then
      for k, nearby in pairs (find(params)) do
        recursive_find_neighbors(nearby)
        --count = count + 1
      end
    end
  end
  recursive_find_neighbors(entity)
  --game.print(count)
  return map
end

local get_root_spawner = function(surface, position)
  local radius = 100
  local spawner
  local params = {position = position, radius = radius, type = "unit-spawner", force = "enemy", limit = nil}
  while true do
    local spawners = surface.find_entities_filtered(params)
    local count = #spawners
    if count > 0 then
      return spawners[math.random(count)]
    end
    params.radius = params.radius * 1.5
    if params.radius > 5000 then
      return
    end
  end
end

convert_nest = function(player, spawner)
  local surface = player.surface
  --local origin = player.force.get_spawn_position(surface)
  local origin = player.position
  local force = player.force
  local position = spawner.position
  script_data.player_spawns[player.index] = position
  local entities = get_hive_entities(spawner)
  local create_entity = surface.create_entity
  local find_entities_filtered = surface.find_entities_filtered
  local teleport_unit_away = util.teleport_unit_away
  for k, nearby in pairs (entities) do
    local deploy_name = deploy_map[nearby.name]
    if deploy_name then
      local deployer = create_entity{name = deploy_name, position = nearby.position, force = force, direction = (math.random(4) - 1) * 2, raise_built = true}
      nearby.destroy({raise_destroy = true})
      local area = deployer.bounding_box
      for k, unit in pairs (find_entities_filtered{area = area, type = "unit"}) do
        teleport_unit_away(unit, area)
      end
    elseif nearby.type == "unit" or nearby.type == "turret" then
      nearby.force = force
    end
  end
end


local join_hive_button =
{
  type = "button",
  name = "join-hive-button",
  caption = {"join-hive"},
  style = mod_gui.button_style
}

local leave_hive_button =
{
  type = "button",
  name = "leave-hive-button",
  caption = {"leave-hive"},
  style = mod_gui.button_style
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


local biter_quickbar ={}
for name, pollution in pairs (names.required_pollution) do
  table.insert(biter_quickbar, name)
end

join_hive = function(player)

  local force = get_hivemind_force()
  if script_data.force_balance then
    local max = 0
    local name
    for k, force in pairs (game.forces) do
      local count = #force.connected_players
      if count > max then
        max = count
        name = force.name
      end
    end
    if name == force.name then
      player.print({"cant-join-force-balance"})
      return
    end
  end

  local position = player.position
  local surface = player.surface

  if remote.interfaces["pvp"] then
    local battle_surface = game.surfaces["battle_surface_1"] or game.surfaces["battle_surface_2"]
    if battle_surface then
      surface = battle_surface
      local teams = remote.call("pvp", "get_teams")
      for k, team in pairs (teams) do
        local force = game.forces[team.name]
        if force and force.valid then
          position = force.get_spawn_position(surface)
          break
        end
      end
    else
      player.print({"cant-join-pvp"})
      return
    end
  end

  local spawner = get_root_spawner(surface, position)
  if not spawner then
    player.print({"cant-find-spawner"})
    return
  end
  if position then
    player.teleport(position, surface)
  end
  local get_quick_bar_slot = player.get_quick_bar_slot
  local set_quick_bar_slot = player.set_quick_bar_slot
  local quickbar = {}
  for k = 1, 100 do
    local item = get_quick_bar_slot(k)
    if item then quickbar[k] = item.name end
    set_quick_bar_slot(k, biter_quickbar[k])
  end
  player.set_active_quick_bar_page(1, 1)
  player.set_active_quick_bar_page(2, 2)
  local previous_life_data =
  {
    force = player.force,
    character = player.character,
    character_name = player.character and player.character.name,
    controller = player.controller_type,
    position = player.position,
    quickbar = quickbar,
    tag = player.tag,
    color = player.color,
    chat_color = player.chat_color
  }
  script_data.previous_life_data[player.index] = previous_life_data
  player.character = nil
  player.force = force
  convert_nest(player, spawner)
  --player.game_view_settings.show_controller_gui = false
  create_character(player)
  player.color = {r = 255, g = 100, b = 100}
  player.chat_color = {r = 255, g = 100, b = 100}
  player.tag = "[color=255,100,100]HIVE[/color]"
  gui_init(player)
  game.print{"joined-hive", player.name}
end

local check_hivemind_disband = function()

  local force = get_hivemind_force()
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
    ["entity-ghost"] = true,
    lab = true,
    ["mining-drill"] = true
  }

  local params = {force = force, type = {"turret", "unit", "unit-spawner", "entity-ghost", "radar", "assembling-machine"}}
  local enemy_force = game.forces.enemy
  for surface_index, surface in pairs(game.surfaces) do
    for k, entity in pairs (surface.find_entities_filtered(params)) do
      if entity.valid then
        if map[entity.name] then
          surface.create_entity{name = map[entity.name], position = entity.position, force = entity.force, raise_built = true}
          entity.destroy()
        elseif destroy_map_type[entity.type] then
          entity.destroy()
        else
          if entity.type == "unit" then
            entity.ai_settings.allow_try_return_to_spawner = true
          end
          entity.force = enemy_force
        end
      end
    end
  end

  --game.merge_forces(force, game.forces.enemy)

end

leave_hive = function(player)

  local previous_life_data = script_data.previous_life_data[player.index]
  local force = previous_life_data.force
  local character = previous_life_data.character
  local controller = previous_life_data.controller
  local character_name = previous_life_data.character_name
  local color = previous_life_data.color or {r = 255, g = 255, b = 255}
  local chat_color = previous_life_data.chat_color or color

  local biter = player.character
  player.character = nil
  if biter and biter.valid then biter.die() end

  player.force = force
  player.color = color
  player.chat_color = chat_color
  local surface = player.surface
  if character then
    --he used to have a character
    if character.valid then
      player.character = character
    else
      --however his old character died or something...
      player.character = surface.create_entity
      {
        name = character_name,
        position = surface.find_non_colliding_position(character_name, force.get_spawn_position(surface), 0, 1),
        force = force
      }
    end
  else
    player.teleport(previous_life_data.position)
  end
  gui_init(player)

  local set_quick_bar_slot = player.set_quick_bar_slot
  local old_quickbar = previous_life_data.quickbar
  for k = 1, 100 do
    set_quick_bar_slot(k, old_quickbar[k])
  end

  player.tag = previous_life_data.tag or ""

  game.print{"left-hive", player.name}
  check_hivemind_disband()

end

local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if not is_hivemind_force(player.force) then return end
  player.character.destroy()
  create_character(player)

end

local on_tick = function(event)

end

local pollution_values =
{
  --wood = 1,
  --coal = 1.5,
  --stone = 0.1
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
  set_force_balance = function(bool)
    script_data.force_balance = bool
  end
})

local on_marked_for_deconstruction = function(event)
  if not event.player_index then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local force = player.force
  if not is_hivemind_force(force) then return end
  local entity = event.entity
  if not (entity and entity.valid) then return end
  if entity.force == force then
    entity.die()
  end
end

local on_player_changed_force = function(event)
  local old_force = event.force
  check_hivemind_disband()

  local player = game.get_player(event.player_index)
  gui_init(player)
end

local allowed_types =
{
  ["blueprint"] = true,
  ["copy-paste-tool"] = true,
  ["selection-tool"] = true,
  ["deconstruction-item"] = true,
  ["gun"] = true,
  ["ammo"] = true,

}

local on_player_cursor_stack_changed = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not is_hivemind_force(player.force) then return end
  local stack = player.cursor_stack
  if not stack.valid_for_read then return end
  if allowed_types[stack.type] then return end

  player.print({"biters-cant-hold", stack.prototype.localised_name})
  player.surface.spill_item_stack(player.position, stack, false, nil, false)
  stack.clear()
end

local on_player_gun_inventory_changed = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not is_hivemind_force(player.force) then return end
  reset_gun_inventory(player)
end

local on_player_ammo_inventory_changed = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not is_hivemind_force(player.force) then return end
  reset_gun_inventory(player)
end

local on_player_ammo_inventory_changed = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not is_hivemind_force(player.force) then return end
  reset_gun_inventory(player)
end

local on_player_armor_inventory_changed = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  if not is_hivemind_force(player.force) then return end
  if not player.character then return end
  local armor_inventory = player.get_inventory(defines.inventory.player_armor)
  armor_inventory.clear()
end

local set_map_settings = function()
  game.map_settings.pollution.enabled = true
  game.map_settings.pollution.min_to_diffuse = 10
  game.map_settings.pollution.diffusion_ratio = 0.03
  game.map_settings.pollution.expected_max_per_chunk = 500
  game.map_settings.pollution.min_to_show_per_chunk = 100
end

local allowed_gui_types =
{
  ["assembling-machine"] = true,
  ["lab"] = true,
}

local on_gui_opened = function(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local player = game.get_player(event.player_index)
  if not is_hivemind_force(player.force) then return end
  local entity = event.entity
  if not (entity and entity.valid) then return end
  if not allowed_gui_types[entity.type] then
    player.opened = nil
  end
end

local on_forces_merging = function(event)
  local source = event.source
  local destination = event.destination

  if not (source and source.valid and destination and destination.valid) then
    return
  end

  for k, data in pairs (script_data.previous_life_data) do
    if data.force == source then
      data.force = destination
    end
  end

end

local events =
{
  [defines.events.on_player_respawned] = on_player_respawned,
  --[defines.events.on_tick] = on_tick,
  [defines.events.on_player_mined_entity] = on_player_mined_entity,
  [defines.events.on_player_joined_game] = on_player_joined_game,
  [defines.events.on_player_created] = on_player_created,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_marked_for_deconstruction] = on_marked_for_deconstruction,
  [defines.events.on_player_changed_force] = on_player_changed_force,
  [defines.events.on_player_cursor_stack_changed] = on_player_cursor_stack_changed,
  [defines.events.on_player_gun_inventory_changed] = on_player_gun_inventory_changed,
  [defines.events.on_player_ammo_inventory_changed] = on_player_ammo_inventory_changed,
  [defines.events.on_player_armor_inventory_changed] = on_player_armor_inventory_changed,
  [defines.events.on_forces_merging] = on_forces_merging,
  [defines.events.on_gui_opened] = on_gui_opened

}

local on_wave_defense_round_started = function(event)
  reset_hivemind_force()
  set_map_settings()
end

local on_pvp_round_start = function(event)
  reset_hivemind_force()
end

local register_wave_defense = function()
  if not remote.interfaces["wave_defense"] then return end
  local wave_defense_events = remote.call("wave_defense", "get_events")
  events[wave_defense_events.on_round_started] = on_wave_defense_round_started
end

local register_pvp = function()
  if not remote.interfaces["pvp"] then return end
  local pvp_events = remote.call("pvp", "get_events")
  events[pvp_events.on_round_start] = on_pvp_round_start
end

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.hive_mind = global.hive_mind or script_data
  for k, player in pairs (game.players) do
    gui_init(player)
  end
  set_map_settings()
  register_wave_defense()
  register_pvp()
  get_hivemind_force()
end

lib.on_load = function()
  script_data = global.hive_mind or script_data
  register_wave_defense()
  register_pvp()
end

lib.on_configuration_changed = function()
  if script_data.hive_mind_forces then
    local target = get_hivemind_force()
    for k, force in pairs (script_data.hive_mind_forces) do
      game.merge_forces(force, target)
    end
    script_data.hive_mind_forces = nil
  end
  script_data.player_spawns = script_data.player_spawns or {}
  set_map_settings()
end

return lib