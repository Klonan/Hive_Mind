local names = require("shared")
local get_hivemind_force = function()
  if game.forces["hivemind"] then return game.forces["hivemind"] end
  local force = game.create_force("hivemind")
  local enemy_force = game.forces.enemy
  enemy_force.set_cease_fire(force, true)
  force.set_cease_fire(enemy_force, true)
  return force
end

local deploy_map =
{
  ["biter-spawner"] = names.deployers.biter_deployer,
  ["spitter-spawner"] = names.deployers.spitter_deployer,
}

local join_hive = function(player)
  local surface = player.surface
  local origin = player.force.get_spawn_position(surface)
  local radius = 100
  local spawner
  while true do
    local area = {{origin.x - radius, origin.y - radius},{origin.x + radius, origin.y + radius}}
    local spawners = surface.find_entities_filtered{area = area, type = "unit-spawner", force = "enemy", limit = 20}
    local count = #spawners
    if count > 0 then
      spawner = spawners[math.random(count)]
      break
    end
    radius = radius + 100
    if radius > 2000 then
      --idk
      return
    end
  end

  local position = spawner.position
  local force = get_hivemind_force()
  force.set_spawn_position(position, surface)
  local radius = 64
  local area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}
  for k, nearby in pairs (surface.find_entities_filtered{force = "enemy", area = area}) do
    local deploy_name = deploy_map[nearby.name]
    if deploy_name then
      surface.create_entity{name = deploy_name, position = nearby.position, force = force, direction = nearby.direction, raise_built = true}
      nearby.destroy()
    elseif nearby.type == "unit" or nearby.type == "turret" then
      nearby.force = force
    end
  end

  player.character = nil
  player.force = force
  player.character = surface.create_entity
  {
    name = names.players.biter_player,
    position = surface.find_non_colliding_position(names.players.biter_player, position, 0, 1),
    force = force
  }


end

local on_player_respawned = function(event)
  local player = game.get_player(event.player_index)
  if player.force ~= get_hivemind_force() then return end

  player.character.destroy()
  player.character = player.surface.create_entity
  {
    name = names.players.biter_player,
    position = player.surface.find_non_colliding_position(names.players.biter_player, player.position, 0, 1),
    force = player.force
  }


end


remote.add_interface("hive_mind",
{
  test = function(player) return join_hive(player) end
})

local events =
{
  [defines.events.on_player_respawned] = on_player_respawned,
}

local lib = {}

lib.get_events = function() return events end

lib.on_init = function()
  global.hive_mind = global.hive_mind or data
  lib.on_event = handler(events)
end

lib.on_load = function()
  data = global.hive_mind
  lib.on_event = handler(events)
end

return lib