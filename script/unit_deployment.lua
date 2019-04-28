local util = require("script/script_util")
local shared = require("shared")
local data =
{
  spawner_tick_check = {},
  ghost_tick_check = {},
  not_idle_units = {},
  proxies = {},
  destroy_factor = 0.002,
  enemy_attack_pollution_consumption_modifier = 1,
  can_spawn = false,
  pop_count = {}
}

local get_destroy_factor = function()
  return data.destroy_factor
end

local get_enemy_attack_pollution_consumption_modifier = function()
  return data.enemy_attack_pollution_consumption_modifier
end

local max_pop_count = 1000
local can_spawn_units = function(force_index)
  return data.pop_count[force_index] < max_pop_count
end

local names = names.deployers
local units = names.units
--todo allow other mods to add deployers
local spawner_map = {}
for k, deployer in pairs (names) do
  spawner_map[deployer] = true
end

local direction_enum =
{
  [defines.direction.north] = {0, -2},
  [defines.direction.south] = {0, 2},
  [defines.direction.east] = {2, 0},
  [defines.direction.west] = {-2, 0}
}

local deploy_unit = function(source, prototype)
  if not (source and source.valid) then return end
  local direction = source.direction
  local offset = direction_enum[direction]
  local name = prototype.name
  local deploy_bounding_box = prototype.collision_box
  local bounding_box = source.bounding_box
  local position = {source.position.x + offset[1], source.position.y + offset[2]}
  local surface = source.surface
  local force = source.force
  local find_non_colliding_position = surface.find_non_colliding_position
  local create_entity = surface.create_entity
  local on_flow = force.item_production_statistics.on_flow
  local deploy_position = find_non_colliding_position(name, position, 0, 1)
  local blood = {name = "blood-explosion-big", position = deploy_position}
  local create_param = {name = name, position = deploy_position, force = force, direction = direction}
  create_entity(blood)
  local unit = create_entity(create_param)
  on_flow(name, 1)
  script.raise_event(defines.events.on_entity_spawned, {entity = unit, spawner = source})
  local index = force.index
  data.pop_count[index] = data.pop_count[index] + 1
  return deployed
end


-- so if it takes 2 pollution to send a unit, the energy required is 10
local pollution_scale = 5

--Max pollution each spawner can absorb is 10% of whatever the chunk has.
local pollution_percent_to_take = 0.1

local min_to_take = 1

local prototype_cache = {}

local get_prototype = function(name)
  local prototype = prototype_cache[name]
  if prototype then return prototype end
  prototype = game.entity_prototypes[name]
  prototype_cache[name] = prototype
  return prototype
end

local min = math.min

local progress_color = {r = 0.8, g = 0.8}

local check_spawner = function(spawner_data)
  local entity = spawner_data.entity
  if not (entity and entity.valid) then return true end
  --entity.surface.create_entity{name = "flying-text", position = entity.position, text = game.tick % 60}

  local recipe = entity.get_recipe()
  if not recipe then
    if spawner_data.progress and rendering.is_valid(spawner_data.progress) then
      rendering.destroy(spawner_data.progress)
      spawner_data.progress = nil
    end
    return
  end

  local force = entity.force

  if can_spawn_units(force.index) then
    local recipe_name = recipe.name
    local item_count = entity.get_item_count(recipe_name)
    if item_count > 0 then
      deploy_unit(entity, get_prototype(recipe_name))
      entity.remove_item{name = recipe_name, count = 1}
    end
  end

  local surface = entity.surface
  local position = entity.position

  local current_energy = entity.crafting_progress

  if current_energy < 1 then

    local pollution = surface.get_pollution(position)
    local pollution_to_take = pollution * pollution_percent_to_take
    if pollution_to_take < min_to_take then
      pollution_to_take = min(min_to_take, pollution)
    end

    local energy = recipe.energy
    local total_pollution_needed_to_spawn = energy * pollution_scale * get_enemy_attack_pollution_consumption_modifier()
    local current_pollution = current_energy * total_pollution_needed_to_spawn

    pollution_to_take = min(pollution_to_take, (total_pollution_needed_to_spawn - current_pollution))

    current_energy = current_energy + ((pollution_to_take / pollution_scale) / get_enemy_attack_pollution_consumption_modifier())
    entity.crafting_progress = current_energy

    surface.pollute(position, -pollution_to_take)
    game.pollution_statistics.on_flow(entity.name, -pollution_to_take)
    force.item_production_statistics.on_flow(shared.pollution_proxy, -pollution_to_take)
  end


  local progress = spawner_data.progress
  if type(progress) == "table" then
    if progress.valid then
      progress.destroy()
    end
    --Old time it was a flying text... can remove in a while
    progress = nil
    spawner_data.progress = nil
  end

  if progress and rendering.is_valid(progress) then
    rendering.set_text(progress, math.floor(current_energy * 100) .. "%")
  else
    progress = rendering.draw_text
    {
      text = math.floor(current_energy * 100) .. "%",
      surface = surface,
      target = entity,
      --target_offset = {0, 1},
      color = progress_color,
      alignment = "center",
      forces = {force},
      scale = 3
    }
    spawner_data.progress = progress
  end


end

--[[    text :: LocalisedString: The text to display.
    surface :: SurfaceSpecification
    target :: Position or LuaEntity
    target_offset :: Vector (optional): Only used if target is a LuaEntity.
    color :: Color
    scale :: double (optional)
    font :: string (optional): Name of font to use. Defaults to the same font as flying-text.
    time_to_live :: uint (optional): In ticks. Defaults to living forever.
    forces :: array of ForceSpecification (optional): The forces that this object is rendered to.
    players :: array of PlayerSpecification (optional): The players that this object is rendered to.
    orientation :: float (optional): The orientation of the text. Default is 0.
    alignment :: string (optional): Defaults to "left". Other options are "right" and "center".
    scale_with_zoom :: boolean (optional): Defaults to false. If true, the text is always the same size, regardless of player zoom.]]

local teleport_unit_away = function(unit, area)
  local center = util.center(area)
  local position = unit.position
  local dx = position.x - center.x
  local dy = position.y - center.y
  local radius = (util.radius(area) + unit.get_radius())
  local current_distance = ((dx * dx) + (dy * dy) ) ^ 0.5
  if current_distance == 0 then
    dx = radius
    dy = radius
  else
    local scale_factor = radius / current_distance
    dx = dx * scale_factor
    dy = dy * scale_factor
  end
  local new_position = {x = center.x + dx, y = center.y + dy}
  --[[

    game.print(serpent.block
    {
      dx = dx, dy = dy,
      center = center,
      new_position = new_position,
      radius = radius,
      current_distance = current_distance
    })

    ]]

  local non_collide = unit.surface.find_non_colliding_position(unit.name, new_position, 0, 0.1)
  unit.teleport(non_collide)
end

local try_to_revive_entity = function(entity)
  local force = entity.force
  local name = entity.ghost_name
  local revived = entity.revive({raise_revive = true})
  if revived then
    force.entity_build_count_statistics.on_flow(name, 1)
    return true
  end
  local prototype = get_prototype(entity.ghost_name)
  local box = prototype.collision_box
  local origin = entity.position
  local area = {{box.left_top.x + origin.x, box.left_top.y + origin.y},{box.right_bottom.x + origin.x, box.right_bottom.y + origin.y}}
  local units = {}
  for k, unit in pairs (entity.surface.find_entities_filtered{area = area, force = force, type = "unit"}) do
    teleport_unit_away(unit, area)
  end
  local revived = entity.revive({raise_revive = true})
  if revived then
    force.entity_build_count_statistics.on_flow(name, 1)
    return true
  end
end

local is_idle = function(unit_number)
  return not (data.not_idle_units[unit_number]) --and remote.call("unit_control", "is_unit_idle", unit.unit_number)
end

local required_pollution = shared.required_pollution

local distance = util.distance

local get_sacrifice_radius = function()
  return 24
end

local needs_creep = shared.needs_creep
local creep_name = shared.creep

local check_ghost = function(ghost_data)
  local entity = ghost_data.entity
  if not (entity and entity.valid) then return true end
  local surface = entity.surface
  --entity.surface.create_entity{name = "flying-text", position = entity.position, text = ghost_data.required_pollution}

  if needs_creep[entity.ghost_name] then
    if surface.get_tile(entity.position).name ~= creep_name then
      if not (ghost_data.creep_notice and rendering.is_valid(ghost_data.creep_notice)) then
        ghost_data.creep_notice = rendering.draw_text
        {
          text = {"needs-creep"},
          surface = surface,
          target = entity,
          --target_offset = {0, 1},
          color = {r = 0.5, b = 0.5},
          alignment = "center",
          forces = {entity.force},
          scale = 2
        }
      end
      return
    else
      if ghost_data.creep_notice and rendering.is_valid(ghost_data.creep_notice) then
        rendering.destroy(ghost_data.creep_notice)
      end
    end
  end

  if ghost_data.required_pollution > 0 then
    for k, unit in pairs (surface.find_units{area = entity.bounding_box, force = entity.force, condition = "same"}) do
      local prototype = get_prototype(unit.name)
      local pollution = prototype.pollution_to_join_attack
      if unit.destroy({raise_destroy = true}) then
        ghost_data.required_pollution = ghost_data.required_pollution - pollution
        if ghost_data.required_pollution <= 0 then break end
      end
    end
  end

  if ghost_data.required_pollution <= 0 then
    return try_to_revive_entity(entity)
  end

  local origin = entity.position
  local r = get_sacrifice_radius()
  local area = {{x = origin.x - r, y = origin.y - r}, {x = origin.x + r, y = origin.y + r}}
  local command =
  {
    type = defines.command.go_to_location,
    destination_entity = entity,
    distraction = defines.distraction.none,
    radius = 0.2
  }

  local needed_pollution = ghost_data.required_pollution
  for k, unit in pairs (surface.find_units{area = area, force = entity.force, condition = "same"}) do
    local unit_number = unit.unit_number
    if is_idle(unit_number) and distance(origin, unit.position) <= r then
      --entity.surface.create_entity{name = "flying-text", position = unit.position, text = "IDLE"}
      unit.set_command(command)
      local pollution = unit.prototype.pollution_to_join_attack
      needed_pollution = needed_pollution - pollution
      data.not_idle_units[unit_number] = {tick = game.tick, ghost_data = ghost_data}
      if needed_pollution <= 0 then break end
    else
      --entity.surface.create_entity{name = "flying-text", position = unit.position, text = "NOT IDLE"}
    end
  end

  local progress = ghost_data.progress
  if type(progress) == "table" then
    if progress.valid then
      progress.destroy()
    end
    --Old time it was a flying text... can remove in a while
    progress = nil
    ghost_data.progress = nil
  end

  if progress and rendering.is_valid(progress) then
    rendering.set_text(progress, math.floor((1 - (ghost_data.required_pollution / required_pollution[entity.ghost_name])) * 100) .. "%")
  else
    progress = rendering.draw_text
    {
      text = math.floor((1 - (ghost_data.required_pollution / required_pollution[entity.ghost_name])) * 100) .. "%",
      surface = surface,
      target = entity,
      --target_offset = {0, 1},
      color = progress_color,
      alignment = "center",
      forces = {entity.force},
      scale = 3
    }
    ghost_data.progress = progress
  end


  local radius = ghost_data.radius
  if not (radius and rendering.is_valid(radius)) then
    radius = rendering.draw_circle
    {
      color = {r = 0.8, g = 0.8},
      width = 2,
      target = entity,
      surface = entity.surface,
      forces = {entity.force},
      draw_on_ground = true,
      filled = false,
      radius = r
    }
    ghost_data.radius = radius
  end

end

-- So, 59, so that its not exactly 60. Which means over a minute or so, each spawner will 'go first' at the pollution.
local spawners_update_interval = 59

local spawner_built = function(entity, tick)
  local radar_prototype = get_prototype(entity.name.."-radar") or error("Spawner being built does not have a radar proxy prototype "..entity.name)
  local radar_proxy = entity.surface.create_entity
  {
    name = radar_prototype.name,
    position = entity.position,
    force = entity.force
  } or error("Couldn't build radar proxy for some reason...")
  entity.destructible = false

  local spawner_data = {entity = entity, proxy = radar_proxy}
  data.proxies[radar_proxy.unit_number] = spawner_data
  local update_tick = entity.unit_number % spawners_update_interval
  data.spawner_tick_check[update_tick] = data.spawner_tick_check[update_tick] or {}
  data.spawner_tick_check[update_tick][entity.unit_number] = spawner_data
end

local ghost_update_interval = 60

local spawner_ghost_built = function(entity, tick)
  local pollution = required_pollution[entity.ghost_name]
  local ghost_data = {entity = entity, required_pollution = pollution}
  local update_tick = entity.unit_number % ghost_update_interval
  data.ghost_tick_check[update_tick] = data.ghost_tick_check[update_tick] or {}
  data.ghost_tick_check[update_tick][entity.unit_number] = ghost_data
  check_ghost(ghost_data)
end

local on_built_entity = function(event)
  local entity = event.created_entity or event.entity
  if not (entity and entity.valid) then return end

  if (spawner_map[entity.name]) then
    return spawner_built(entity, event.tick)
  end

  if entity.type == "entity-ghost" then
    local ghost_name = entity.ghost_name
    if required_pollution[ghost_name] then
      return spawner_ghost_built(entity, event.tick)
    end
  end

end

local check_spawners_on_tick = function(tick)

  local mod = tick % spawners_update_interval
  local entities = data.spawner_tick_check[mod]
  if not entities then return end

  for unit_number, spawner_data in pairs (entities) do
    --count = count + 1
    if check_spawner(spawner_data) then
      entities[unit_number] = nil
    end
  end
end

local check_ghosts_on_tick = function(tick)

  local mod = tick % ghost_update_interval
  local entities = data.ghost_tick_check[mod]
  if not entities then return end

  for unit_number, ghost_data in pairs (entities) do
    if check_ghost(ghost_data) then
      entities[unit_number] = nil
    end
  end
end

local expiry_time = 180
local check_not_idle_units = function(tick)
  if tick % expiry_time ~= 0 then return end
  local expiry_tick = tick - expiry_time
  local max = sanity_max
  for unit_number, unit_data in pairs (data.not_idle_units) do
    if unit_data.tick <= expiry_tick then
      data.not_idle_units[unit_number] = nil
    end
  end
end

local check_update_map_settings = function(tick)
  if tick and tick % 6 ~= 0 then return end
  data.destroy_factor = game.map_settings.enemy_evolution.destroy_factor
  data.enemy_attack_pollution_consumption_modifier = game.map_settings.pollution.enemy_attack_pollution_consumption_modifier
end

local unit_list

local get_units = function()
  if unit_list then return unit_list end
  unit_list = {}
  for name, prototype in pairs (game.entity_prototypes) do
    if prototype.type == "unit" then
      table.insert(unit_list, name)
    end
  end
  return unit_list
end

local check_update_pop_cap = function(tick)
  if tick and tick % 60 ~= 0 then return end
  --local profiler = game.create_profiler()
  local list = get_units()
  data.pop_count = {}
  for name, force in pairs (game.forces) do
    local total = 0
    local get_entity_count = force.get_entity_count
    for k = 1, #list do
      total = total + get_entity_count(list[k])
    end
    local index = force.index
    data.pop_count[index] = total
  end
  --game.print({"", game.tick, profiler})
end

local on_tick = function(event)
  check_spawners_on_tick(event.tick)
  check_ghosts_on_tick(event.tick)
  check_not_idle_units(event.tick)
  check_update_map_settings(event.tick)
  check_update_pop_cap(event.tick)
end

local on_entity_died = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local unit_number = entity.unit_number
  if not unit_number then return end
  local spawner_data = data.proxies[unit_number]
  if not spawner_data then return end
  entity.destroy()
  data.proxies[unit_number] = nil

  local spawner = spawner_data.entity
  if spawner and spawner.valid then
    spawner.destructible = true
    spawner.force.evolution_factor = spawner.force.evolution_factor + (1 * get_destroy_factor())
    spawner.die()
  end
end

local on_ai_command_completed = function(event)
  local command_data = data.not_idle_units[event.unit_number]
  if command_data then
    return check_ghost(command_data.ghost_data)
  end
end

local redistribute_on_tick_checks = function()

  local new_spawner_tick_check = {}
  for k, array in pairs (data.spawner_tick_check) do
    for unit_number, data in pairs (array) do
      local mod = unit_number % spawners_update_interval
      new_spawner_tick_check[mod] = new_spawner_tick_check[mod] or {}
      new_spawner_tick_check[mod][unit_number] = data
    end
  end
  data.spawner_tick_check = new_spawner_tick_check

  local new_ghost_tick_check = {}
  for k, array in pairs (data.ghost_tick_check) do
    for unit_number, data in pairs (array) do
      local mod = unit_number % ghost_update_interval
      new_ghost_tick_check[mod] = new_ghost_tick_check[mod] or {}
      new_ghost_tick_check[mod][unit_number] = data
    end
  end
  data.ghost_tick_check = new_ghost_tick_check

end

local events =
{
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_entity_died] = on_entity_died,
  [defines.events.on_ai_command_completed] = on_ai_command_completed
}

local unit_deployment = {}

unit_deployment.get_events = function() return events end

unit_deployment.on_init = function()
  global.unit_deployment = global.unit_deployment or data
  check_update_map_settings()
  check_update_pop_cap()
end

unit_deployment.on_load = function()
  data = global.unit_deployment
end

unit_deployment.on_configuration_changed = function()
  check_update_map_settings()
  check_update_pop_cap()
  rendering.clear()
  redistribute_on_tick_checks()
end

return unit_deployment