local util = require("script/script_util")

local script_data =
{
  active_creep_spread_entities = {},
  creep_landmines = {},
  active_creep_landmines = {}
}

local names = require("shared")


local on_chunk_generated = function(event)
  local area = event.area
  local surface = event.surface
  for k, entity in pairs (surface.find_entities_filtered{type = "unit-spawner", area = area}) do
    local unit_number = entity.unit_number
    script_data.active_creep_spread_entities[unit_number] = {entity = entity, radius = 1}
    local landmine = entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
    landmine.destructible = false
    script_data.creep_landmines[unit_number] = landmine
  end
end

local creep_spread_map =
{
  ["biter-deployer"] = true,
  ["spitter-deployer"] = true,
  ["biter-spawner"] = true,
  ["spitter-spawner"] = true,
  ["creep-tumor"] = true
}

local creep_spread_list = {}
for name, bool in pairs (creep_spread_map) do
  table.insert(creep_spread_list, name)
end

local shuffle_table = function(table)
  local size = #table
  local random = math.random
  for k = size, 1, -1 do
    local i = random(size)
    table[i], table[k] = table[k], table[i]
  end
  return table
end

local on_built_entity = function(event)

  local entity = event.created_entity or event.entity

  if creep_spread_map[entity.name] then
    local unit_number = entity.unit_number
    script_data.active_creep_spread_entities[unit_number] = {entity = entity, radius = 1}
    local landmine = entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
    landmine.destructible = false
    script_data.creep_landmines[unit_number] = landmine
  end

end

local max_radius = names.creep_radius
local creep_spread_update_rate = 64
local get_area = util.area
local distance = util.distance

local check_creep_spread = function(event)
  --local mod = event.tick % creep_spread_update_rate
  local tick = event.tick
  for unit_number, spawner_data in pairs (script_data.active_creep_spread_entities) do
    local spawner = spawner_data.entity
    if spawner.valid then
      if (unit_number + tick) % creep_spread_update_rate == 0 then
        local surface = spawner.surface
        local position = spawner.position
        while true do
          for k, tile in pairs (shuffle_table(surface.find_tiles_filtered{area = get_area(position, spawner_data.radius), collision_mask = "ground-tile"})) do
            local tile_position = tile.position
            if distance(tile_position, position) <= spawner_data.radius then
              local hidden = tile.name
              surface.set_tiles{{position = tile_position, name = "creep"}}
              surface.set_hidden_tile(tile_position, hidden)
              return
            end
          end
          if spawner_data.radius < max_radius then
            spawner_data.radius = spawner_data.radius + 0.5
          else
            script_data.active_creep_spread_entities[unit_number] = nil
            return
          end
        end
      end
    else
      script_data.active_creep_spread_entities[unit_number] = nil
    end
  end
end

local creep_unspread_update_rate = 64

local unspread_creep = function(creep_data)
  local landmine = creep_data.entity
  if not (landmine and landmine.valid) then return end

  --tiles are shuffled when we create find them.
  --We want to kill one tile every update.

  local surface = landmine.surface
  local tiles = creep_data.tiles
  if not tiles then
    local radius = creep_data.radius
    if radius <= 0 then
      landmine.destructible = true
      landmine.destroy()
      game.print("HHRUAHA")
      return true
    end
    local position = landmine.position
    tiles = shuffle_table(surface.find_tiles_filtered{area = get_area(position, max_radius), name = names.creep})
    for k, tile in pairs (tiles) do
      local tile_position = tile.position
      local tile_distance = distance(tile_position, position)
      if tile_distance > max_radius then
        tiles[k] = nil
      elseif tile_distance < radius then
        tiles[k] = nil
      end
    end
    radius = radius - 0.5
    creep_data.radius = radius
    creep_data.tiles = tiles
    game.print(radius)
  end

  local nearby_creep_spread_entities = surface.find_entities_filtered{name = creep_spread_list, area = get_area(landmine.position, max_radius * 2)}
  local any = #nearby_creep_spread_entities > 0
  local get_closest = surface.get_closest

  local creep_to_remove

  for k, tile in pairs (tiles) do
    if not any then
      creep_to_remove = tile
      tiles[k] = nil
      break
    end
    local position = tile.position
    local closest = get_closest(position, nearby_creep_spread_entities)
    if distance(position, closest.position) <= (max_radius - 0.5) then
      tiles[k] = nil
    else
      creep_to_remove = tile
      tiles[k] = nil
      break
    end
  end

  if table_size(tiles) == 0 then creep_data.tiles = nil end

  if creep_to_remove then
    surface.set_tiles
    {
      {position = creep_to_remove.position, name = creep_to_remove.hidden_tile or "grass-1"}
    }
  end

end

local check_creep_unspread = function(event)

  local mod = event.tick % creep_unspread_update_rate
  for unit_number, creep_data in pairs (script_data.active_creep_landmines) do
    if unit_number % creep_unspread_update_rate == mod then
      if unspread_creep(creep_data) then
        script_data.active_creep_landmines[unit_number] = nil
      end
    end
  end

end

local on_tick = function(event)
  check_creep_spread(event)
  check_creep_unspread(event)
end

local on_trigger_created_entity = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  if entity.name ~= names.creep_sticker then return end

  local tile = entity.surface.get_tile(entity.position)
  if tile.name ~= names.creep then
    entity.destroy()
  end

end

local on_entity_died = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local unit_number = entity.unit_number
  local creep_landmine = script_data.creep_landmines[unit_number]
  if not (creep_landmine and creep_landmine.valid) then return end
  script_data.creep_landmines[unit_number] = nil
  script_data.active_creep_landmines[creep_landmine.unit_number] = {entity = creep_landmine, radius = max_radius}

end

local events =
{
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_trigger_created_entity] = on_trigger_created_entity,
  [defines.events.on_entity_died] = on_entity_died

}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.creep = global.creep or script_data
end

lib.on_load = function()
  script_data = global.creep or script_data
end

lib.on_configuration_changed = function()

end

return lib