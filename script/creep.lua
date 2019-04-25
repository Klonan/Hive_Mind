local util = require("script/script_util")

local script_data =
{
  spreading_landmines = {},
  idle_landmines = {},
  shrinking_landmines = {},
  tiles_to_set = {}
}

local names = require("shared")


local on_chunk_generated = function(event)
  local area = event.area
  local surface = event.surface
  for k, entity in pairs (surface.find_entities_filtered{type = "unit-spawner", area = area}) do
    local unit_number = entity.unit_number
    if not script_data.spreading_landmines[unit_number] then
      local landmine = entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
      landmine.destructible = false
      script_data.spreading_landmines[unit_number] = {entity = landmine, radius = 1}
    end
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
  if not (entity and entity.valid) then return end

  if creep_spread_map[entity.name] then
    local unit_number = entity.unit_number
    local landmine = entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
    landmine.destructible = false
    script_data.spreading_landmines[unit_number] = {entity = landmine, radius = 1}
  end

end

local max_radius = names.creep_radius
local creep_spread_update_rate = 1
local get_area = util.area
local distance = util.distance
local insert = table.insert

local register_to_set_tiles = function(surface, tile)

  local register = script_data.tiles_to_set
  if not register then
    register = {}
    script_data.tiles_to_set = register
  end

  local index = surface.index

  local surface_register = register[index]
  if not surface_register then
    surface_register = {}
    register[index] = surface_register
  end

  insert(surface_register, tile)

end


local root_2 = 2 ^ 0.5

local spread_creep
spread_creep = function(unit_number, spawner_data)

  local spawner = spawner_data.entity

  if not spawner.valid then
    script_data.spreading_landmines[unit_number] = nil
    return
  end

  local surface = spawner.surface
  local position = spawner.position

  local tiles = spawner_data.tiles
  local radius = spawner_data.radius
  if not tiles then

    if radius == max_radius then
      script_data.idle_landmines[unit_number] = spawner_data
      script_data.spreading_landmines[unit_number] = nil
      return
    end

    radius = math.min(radius + root_2, max_radius)
    tiles = shuffle_table(surface.find_tiles_filtered{area = get_area(position, radius), collision_mask = "ground-tile"})
    spawner_data.tiles = tiles
    spawner_data.radius = radius

  end


  local tile_to_set

  for k, tile in pairs (tiles) do
    tiles[k] = nil
    if tile.valid and (tile.name ~= names.creep) and (tile.name ~= "out-of-map") and (distance(tile.position, position) <= spawner_data.radius) then
      tile_to_set = tile
      break
    end
  end


  if tile_to_set then
    local hidden = tile_to_set.name
    local tile_position = tile_to_set.position
    register_to_set_tiles(surface, {position = tile_position, name = "creep"})
  else
    spawner_data.tiles = nil
    return spread_creep(unit_number, spawner_data)
  end


end

local check_creep_spread = function(event)
  local mod = event.tick % creep_spread_update_rate
  for unit_number, spawner_data in pairs (script_data.spreading_landmines) do
    if (unit_number % creep_spread_update_rate) == mod then
      spread_creep(unit_number, spawner_data)
    end
  end
end

local creep_unspread_update_rate = 64
local unspread_creep
unspread_creep = function(unit_number, landmine_data)
  local landmine = landmine_data.entity
  if not (landmine and landmine.valid) then
    script_data.shrinking_landmines[unit_number] = nil
    return
  end

  --tiles are shuffled when we create find them.
  --We want to kill one tile every update.

  local surface = landmine.surface
  local tiles = landmine_data.tiles
  if not tiles then
    local radius = landmine_data.radius

    if radius <= 0 then
      landmine.destructible = true
      landmine.destroy()
      script_data.shrinking_landmines[unit_number] = nil
      return
    end

    local new_radius = radius - root_2

    local position = landmine.position
    tiles = shuffle_table(surface.find_tiles_filtered{area = get_area(position, radius), name = names.creep})
    for k, tile in pairs (tiles) do
      local tile_position = tile.position
      local tile_distance = distance(tile_position, position)
      if tile_distance > (radius + root_2) then
        tiles[k] = nil
      elseif tile_distance < (new_radius - root_2) then
        tiles[k] = nil
      end
    end
    landmine_data.radius = new_radius
    landmine_data.tiles = tiles
  end

  local nearby_shrinking_landmines = surface.find_entities_filtered{name = names.creep_landmine, area = get_area(landmine.position, max_radius * 2)}
  local nearby_active_landmines = {}
  local any_active = false
  for k, v in pairs (nearby_shrinking_landmines) do
    if not script_data.shrinking_landmines[v.unit_number] then
      nearby_active_landmines[k] = v
      any_active = true
      nearby_shrinking_landmines[k] = nil
    end
  end
  local present = false
  for k, v in pairs (nearby_shrinking_landmines) do
    if v == landmine then
      present = true
    end
  end

  local get_closest = surface.get_closest

  local creep_to_remove

  for k, tile in pairs (tiles) do
    tiles[k] = nil
    local position = tile.position
    if get_closest(position, nearby_shrinking_landmines) == landmine
      and (not any_active or distance(position, get_closest(position, nearby_active_landmines).position) >= max_radius) then
      creep_to_remove = tile
      break
    end
  end

  if creep_to_remove then
    register_to_set_tiles(surface, {position = creep_to_remove.position, name = creep_to_remove.hidden_tile or "out-of-map"})
  else
    landmine_data.tiles = nil
    return unspread_creep(unit_number, landmine_data)
  end

end

local check_creep_unspread = function(event)

  local mod = event.tick % creep_unspread_update_rate
  for unit_number, landmine_data in pairs (script_data.shrinking_landmines) do
    if (unit_number % creep_unspread_update_rate) == mod then
      unspread_creep(unit_number, landmine_data)
    end
  end

end

local check_set_tile_register = function()
  local register = script_data.tiles_to_set
  local surfaces = game.surfaces
  for surface_index, tiles in pairs (register) do
    surfaces[surface_index].set_tiles(tiles, true)
    register[surface_index] = {}
  end
end

local on_tick = function(event)
  check_creep_spread(event)
  check_creep_unspread(event)
  check_set_tile_register()
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
  local landmine_data = script_data.idle_landmines[unit_number] or script_data.spreading_landmines[unit_number]
  if not landmine_data then return end

  script_data.idle_landmines[unit_number] = nil
  script_data.spreading_landmines[unit_number] = nil

  local creep_landmine = landmine_data.entity
  if not (creep_landmine and creep_landmine.valid) then return end

  --We need to notify nearby shrinking ones to reexpand their radius, as they may have already checked the nearby tiles and determined they should be left as creep.
  
  local nearby_shrinking_landmines = creep_landmine.surface.find_entities_filtered{name = names.creep_landmine, area = get_area(creep_landmine.position, max_radius * 2)}
  for k, v in pairs (nearby_shrinking_landmines) do
    local nearby_data = script_data.shrinking_landmines[v.unit_number] 
    if nearby_data then
      nearby_data.radius = max_radius
    end
  end
  
  landmine_data.radius = max_radius
  script_data.shrinking_landmines[creep_landmine.unit_number] = landmine_data
end

local events =
{
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_biter_base_built] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_trigger_created_entity] = on_trigger_created_entity,
  [defines.events.script_raised_destroy] = on_entity_died,
  [defines.events.on_entity_died] = on_entity_died

}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.creep = global.creep or script_data
  for k, surface in pairs (game.surfaces) do
    for k, v in pairs (surface.find_entities_filtered{name = creep_spread_list}) do
      on_built_entity({entity = v})
    end
  end
end

lib.on_load = function()
  script_data = global.creep or script_data
end

lib.on_configuration_changed = function()

end

return lib