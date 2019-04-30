local names = require("shared")
local lab_name = names.pollution_lab

local script_data =
{
  labs = {}
}

local lab_update_rate = 89

local pollution_cache = {}

local get_required_pollution = function(technology)
  local name = technology.name
  if pollution_cache[name] then return pollution_cache[name] end

  local count = 0
  for k, ingredient in pairs (technology.research_unit_ingredients) do
    if ingredient.type == "item" and ingredient.name == names.pollution_proxy then
      count = count + ingredient.amount
    end
  end
  count = count * technology.research_unit_count
  pollution_cache[name] = count
  return count
end

local pollution_absorb_percent = 0.2
local pollution_absorb_min = 1

local update_lab = function(entity)
  if not (entity and entity.valid) then return true end
  local force = entity.force

  local surface = entity.surface
  local position = entity.position
  local available_pollution = surface.get_pollution(position)

  local pollution_to_take = math.max(pollution_absorb_min, available_pollution * pollution_absorb_percent)
  pollution_to_take = math.floor(math.min(available_pollution, pollution_to_take))
  if pollution_to_take < pollution_absorb_min then return end

  pollution_to_take  = entity.insert({name = names.pollution_proxy, count = pollution_to_take})
  game.pollution_statistics.on_flow(entity.name, -pollution_to_take)
  surface.pollute(position, -pollution_to_take)

end

local update_labs = function(tick)
  local mod = tick % lab_update_rate
  local labs = script_data.labs[mod]
  if not labs then return end

  for unit_number, lab in pairs (labs) do
    if update_lab(lab) then
      labs[unit_number] = nil
    end
  end
end

local lab_built = function(entity)
  local unit_number = entity.unit_number
  local mod = unit_number % lab_update_rate
  local labs = script_data.labs[mod]
  if not labs then
    labs = {}
    script_data.labs[mod] = labs
  end
  labs[unit_number] = entity
  update_lab(entity)
end

local on_built_entity = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end

  if entity.name == lab_name then
    return lab_built(entity)
  end
end

local on_tick = function(event)
  update_labs(event.tick)
end

local events =
{
  --[defines.events.on_chunk_generated] = on_chunk_generated,
  [defines.events.script_raised_revive] = on_built_entity,
  --[defines.events.script_raised_built] = on_built_entity,
  --[defines.events.on_built_entity] = on_built_entity,
  --[defines.events.on_biter_base_built] = on_built_entity,
  [defines.events.on_tick] = on_tick,
  --[defines.events.on_trigger_created_entity] = on_trigger_created_entity,
  --[defines.events.script_raised_destroy] = on_entity_died,
  --[defines.events.on_entity_died] = on_entity_died

}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.pollution_lab = global.pollution_lab or script_data
end

lib.on_load = function()
  script_data = global.pollution_lab or script_data
end

lib.on_configuration_changed = function()

end

return lib