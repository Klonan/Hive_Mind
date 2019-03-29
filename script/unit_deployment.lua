local data =
{
  machines = {},
  tick_check = {}
}

local names = names.deployers
local units = names.units
--todo allow other mods to add deployers
local map = {}
for k, deployer in pairs (names) do
  map[deployer] = true
end

local direction_enum = {
  [defines.direction.north] = {0, -1},
  [defines.direction.south] = {0, 1},
  [defines.direction.east] = {1, 0},
  [defines.direction.west] = {-1, 0}
}

local deploy_unit = function(source, prototype, count)
  if not (source and source.valid) then return end
  local direction = source.direction
  local offset = direction_enum[direction]
  local name = prototype.name
  local deploy_bounding_box = prototype.collision_box
  local bounding_box = source.bounding_box
  local offset_x = offset[1] * ((bounding_box.right_bottom.x - bounding_box.left_top.x) / 2) + ((deploy_bounding_box.right_bottom.x - deploy_bounding_box.left_top.x) / 2)
  local offset_y = offset[2] * ((bounding_box.right_bottom.y - bounding_box.left_top.y) / 2) + ((deploy_bounding_box.right_bottom.y - deploy_bounding_box.left_top.y) / 2)
  local position = {source.position.x + offset_x, source.position.y + offset_y}
  local surface = source.surface
  local force = source.force
  local deployed = 0
  local can_place_entity = surface.can_place_entity
  local find_non_colliding_position = surface.find_non_colliding_position
  local create_entity = surface.create_entity
  for k = 1, count do
    if not surface.valid then break end
    local deploy_position = can_place_entity{name = name, position = position, direction = direction, force = force, build_check_type = defines.build_check_type.manual} and position or find_non_colliding_position(name, position, 0, 1)
    local unit = create_entity{name = name, position = deploy_position, force = force, direction = direction}
    script.raise_event(defines.events.on_entity_spawned, {entity = unit, spawner = source})
    deployed = deployed + 1
  end
  return deployed
end


-- so if it takes 2 pollution to send a unit, the energy required is 2,000,000
local pollution_scale = 10

--Max pollution each spawner can absorb is 10% of whatever the chunk has.
local pollution_max_percent = 0.1
local min_to_take = 1

local prototype_cache = {}

local get_prototype = function(name)
  local prototype = prototype_cache[name]
  if prototype then return prototype end
  prototype = game.entity_prototypes[name]
  prototype_cache[name] = prototype
  return prototype
end

local check_spawner = function(spawner_data)

  local entity = spawner_data.entity
  if not (entity and entity.valid) then return end

  entity.surface.create_entity{name = "flying-text", position = entity.position, text = game.tick % 60}

  local recipe = entity.get_recipe()
  if not recipe then
    return
  end
  local prototype = get_prototype(recipe.name)
  local pollution = entity.surface.get_pollution(entity.position)
    --[[
  if pollution == 0 then
    --entity.active = false
    --return
  end]]

  --entity.active = true

  local pollution_to_take = math.max(math.min(pollution, min_to_take), pollution * pollution_max_percent)

  local added_progress = pollution_to_take * pollution_scale
  local max_progress = recipe.energy

  local progress_percent = entity.crafting_progress
  local progress_amount = progress_percent * max_progress
  local new_progress = progress_amount + added_progress
  while new_progress >= max_progress do
    new_progress = new_progress - max_progress
    -- Fragile!
    deploy_unit(entity, prototype, 1)
    entity.force.item_production_statistics.on_flow(recipe.name, 1)
  end

  local item_count = entity.get_item_count(recipe.name)
  if item_count > 0 then
    deploy_unit(entity, prototype, item_count)
    entity.remove_item{name = recipe.name, count = item_count}
  end

  entity.crafting_progress = new_progress / max_progress
  entity.surface.pollute(entity.position, -pollution_to_take)

  local progress_bar = spawner_data.progress_bar
  if not progress_bar then
    local background = rendering.draw_line
    {
      color = {r = 0, b = 0, g = 0},
      width = 10,
      from = entity,
      from_offset = {-33/32, 1},
      to = entity,
      to_offset = {33/32, 1},
      surface = entity.surface,
      forces = {entity.force}
    }
    progress_bar = rendering.draw_line
    {
      color = {r = 1, g = 0.5},
      width = 8,
      from = entity,
      from_offset = {-1, 1},
      to = entity,
      to_offset = {1, 1},
      surface = entity.surface,
      forces = {entity.force}
    }
    spawner_data.progress_bar = progress_bar
  end
  rendering.set_to(spawner_data.progress_bar, entity, {(2 * (new_progress / max_progress)) - 1, 1})

end

-- So, 59, so that its not exactly 60. Which means over a minute or so, each spawner will 'go first' at the pollution.
local update_interval = 59

local on_built_entity = function(event)
  local entity = event.created_entity or event.entity
  if not (entity and entity.valid) then return end
  if not (map[entity.name]) then return end

  local spawner_data = {entity = entity}
  local update_tick = 1 + event.tick + (entity.unit_number % update_interval)
  data.tick_check[update_tick] = data.tick_check[update_tick] or {}
  data.tick_check[update_tick][entity.unit_number] = spawner_data
end

local on_tick = function(event)
  local tick = event.tick
  local entities = data.tick_check[tick]
  if not entities then return end
  data.tick_check[tick + update_interval] = entities
  for unit_number, spawner_data in pairs (entities) do
    check_spawner(spawner_data)
  end
  data.tick_check[tick] = nil
end

local events =
{
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_robot_built_entity] = on_built_entity,
  [defines.events.on_tick] = on_tick
}

local unit_deployment = {}

unit_deployment.get_events = function() return events end

unit_deployment.on_init = function()
  global.unit_deployment = global.unit_deployment or data
  unit_deployment.on_event = handler(events)
end

unit_deployment.on_load = function()
  data = global.unit_deployment
  unit_deployment.on_event = handler(events)
end

return unit_deployment