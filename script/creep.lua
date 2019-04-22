local util = require("script/script_util")

local script_data =
{
  active_creep_spread_entities = {}
}

local names = require("shared")


local on_chunk_generated = function(event)
  local area = event.area
  local surface = event.surface
  for k, entity in pairs (surface.find_entities_filtered{type = "unit-spawner", area = area}) do
    script_data.active_creep_spread_entities[entity.unit_number] = {entity = entity, radius = 1, spawning = true}
    entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
  end
end

local creep_spread_names =
{
  ["biter-deployer"] = true,
  ["spitter-deployer"] = true,
  ["biter-spawner"] = true,
  ["spitter-spawner"] = true,
  ["creep-tumor"] = true
}

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

  if creep_spread_names[entity.name] then
    script_data.active_creep_spread_entities[entity.unit_number] = {entity = entity, radius = 1, spawning = true}
    entity.surface.create_entity{name = names.creep_landmine, position = entity.position, force = entity.force}
  end

end

local max_radius = names.creep_radius
local update_rate = 64

local on_tick = function(event)
  --if event.tick % 60 ~= 0 then return end

  --local radius = 8
  local get_area = util.area
  local distance = util.distance
  local tick = event.tick
  local mod = tick % update_rate
  for k, spawner_data in pairs (script_data.active_creep_spread_entities) do
    local spawner = spawner_data.entity
    if spawner.valid and spawner_data.spawning then
      if spawner.unit_number % update_rate == mod then
        local surface = spawner.surface
        local position = spawner.position
        while true do
          for k, tile in pairs (shuffle_table(surface.find_tiles_filtered{area = get_area(position, spawner_data.radius), collision_mask = "ground-tile"})) do
            local tile_position = tile.position
            if distance(tile_position, position) <= spawner_data.radius then
              surface.set_tiles{{position = tile_position, name = "creep"}}
              return
            end
          end
          if spawner_data.radius < max_radius then
            spawner_data.radius = spawner_data.radius + 0.5
          else
            script_data.active_creep_spread_entities[k] = nil
            return
          end
        end
      end
    else
      script_data.active_creep_spread_entities[k] = nil
    end
  end

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

local events =
{
  [defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.script_raised_revive] = on_built_entity,
  [defines.events.script_raised_built] = on_built_entity,
  [defines.events.on_built_entity] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  [defines.events.on_trigger_created_entity] = on_trigger_created_entity,

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