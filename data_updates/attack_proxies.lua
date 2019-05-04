error("Not used")

local make_proxy = function(prototype)

  local radar = util.copy(data.raw.radar.radar)
  radar.name = prototype.name.."-radar"
  radar.pictures = {layers = {util.empty_sprite()}}
  radar.energy_source = {type = "void"}
  radar.collision_box = prototype.collision_box
  radar.selection_box = prototype.selection_box
  radar.selectable_in_game = false
  radar.integration_patch = nil
  radar.working_sound = nil
  radar.vehicle_impact_sound = nil
  radar.max_distance_of_sector_revealed = 1
  radar.max_distance_of_nearby_sector_revealed = 1
  radar.resistances = prototype.resistances
  radar.icon = prototype.icon
  radar.icon_size = prototype.icon_size
  radar.icons = prototype.icons
  radar.max_health = prototype.max_health
  radar.healing_per_tick = prototype.healing_per_tick
  radar.corpse = nil
  radar.order = prototype.name.."-radar"
  radar.flags =  {--[["placeable-off-grid",]] "placeable-neutral", "player-creation", "no-automated-item-removal", "not-blueprintable", "hidden"}
  radar.collision_mask = {}

  --only needed to make deconstruction work...
  local radar_item = {
    type = "item",
    name = radar.name,
    localised_name = {prototype.name},
    localised_description = {"requires-pollution", shared.required_pollution[name]},
    icon = prototype.icon,
    icon_size = prototype.icon_size,
    icons = prototype.icons,
    flags = {"hidden"},
    subgroup = prototype.subgroup,
    order = "aa-"..prototype.name,
    place_result = radar.name,
    stack_size = 50
  }
  data:extend
  {
    radar,
    radar_item
  }

end

local types = names.needs_proxy_type
local required_pollution = names.required_pollution

for type, bool in pairs (types) do
  local entities = data.raw[type]
  for name, entity in pairs (entities) do
    if required_pollution[name] then
      make_proxy(entity)
    end
  end
end