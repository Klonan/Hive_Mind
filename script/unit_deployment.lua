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

local no_recipe_check_again = 300
local update_interval = 60

-- so if it takes 2 pollution to send a unit, the energy required is 2,000,000
local pollution_scale = 1000000

--Max pollution each spawner can absorb is 10% of whatever the chunk has.
local pollution_max_percent = 0.25
local min_to_take = 1

local check_deployer = function(entity)
  if not (entity and entity.valid) then return end
  --game.print("Checking entity: "..entity.name)
  local recipe = entity.get_recipe()
  if not recipe then
    --No recipe, so lets check this guy again in some ticks
    local check_tick = game.tick + no_recipe_check_again
    data.tick_check[check_tick] = data.tick_check[check_tick] or {}
    data.tick_check[check_tick][entity.unit_number] = entity
    return
  end

  local pollution = entity.surface.get_pollution(entity.position)
  local pollution_to_take = math.max(math.min(pollution, min_to_take), pollution * pollution_max_percent)

  local added_progress = pollution_to_take * pollution_scale
  local max_progress = recipe.energy

  local progress_percent = entity.crafting_progress
  local progress_amount = progress_percent * max_progress
  local new_progress = progress_amount + added_progress
  while new_progress >= max_progress do
    new_progress = new_progress - max_progress
    -- Fragile!
    local prototype = game.entity_prototypes[recipe.name]
    deployed_count = deploy_unit(entity, prototype, 1)
  end

  entity.crafting_progress = new_progress / max_progress
  entity.surface.pollute(entity.position, -pollution_to_take)

  local check_tick = game.tick + update_interval
  data.tick_check[check_tick] = data.tick_check[check_tick] or {}
  data.tick_check[check_tick][entity.unit_number] = entity


end

local on_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end
  if not (map[entity.name]) then return end
  data.machines[entity.unit_number] = entity
  check_deployer(entity)
end

local on_tick = function(event)
  local entities = data.tick_check[event.tick]
  if not entities then return end
  for unit_number, entity in pairs (entities) do
    check_deployer(entity)
  end
  data.tick_check[event.tick] = nil
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