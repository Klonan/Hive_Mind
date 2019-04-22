local util = require("script/script_util")

local script_data =
{
  creep_spread_entities = {}
}

local names = require("shared")


local on_chunk_generated = function(event)
  local area = event.area
  local surface = event.surface
  for k, spawner in pairs (surface.find_entities_filtered{type = "unit-spawner", area = area}) do
    script_data.creep_spread_entities[spawner.unit_number] = {entity = spawner, radius = 1}
  end
end

local creep_spread_names =
{
  ["biter-deployer"] = true,
  ["spitter-deployer"] = true,
}

local on_built_entity = function(event)

  local entity = event.created_entity or event.entity

  if creep_spread_names[entity.name] then
    script_data.creep_spread_entities[entity.unit_number] = {entity = entity, radius = 1}
  end

end

local on_tick = function(event)
  --if event.tick % 60 ~= 0 then return end

  --local radius = 8
  local get_area = util.area
  local distance = util.distance
  local tick = event.tick
  local mod = tick % 64
  local insert = table.insert
  local map = {}
  for k, spawner_data in pairs (script_data.creep_spread_entities) do
    local spawner = spawner_data.entity
    if spawner.valid then
      if spawner.unit_number % 64 == mod then
        local surface = spawner.surface
        local i = surface.index
        map[i] = map[i] or {}
        local position = spawner.position
        for k, tile in pairs (surface.find_tiles_filtered{area = get_area(position, spawner_data.radius), collision_mask = "ground-tile"}) do
          local tile_position = tile.position
          if distance(tile_position, position) <= spawner_data.radius then
            insert(map, {position = tile_position, name = "creep"})
          end
        end
        spawner_data.radius = math.min(spawner_data.radius + 0.5, 20)
      end
    else
      script_data.creep_spread_entities[k] = nil
    end
  end

  local surfaces = game.surfaces
  for surface, table in pairs (map) do
    local tiles = {}
    for x, array in pairs (table) do
      for y, bool in pairs (array) do
        insert(tiles, {name = names.creep, position = {x, y}})
      end
    end
    surfaces[surface].set_tiles(tiles)
  end
end

local events =
{
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_tick] = on_tick,

}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.creep = global.creep or script_data
end

lib.on_load = function()
  script_data = global.creep or script_data
  register_wave_defense()
end

lib.on_configuration_changed = function()

end

return lib