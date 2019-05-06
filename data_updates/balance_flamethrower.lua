local action =
{
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      target_effects =
      {
        {
          type = "create-fire",
          entity_name = "fire-flame",
          initial_ground_flame_count = 1
        }
      }
    }
  }
}

local handheld_stream = data.raw.stream["handheld-flamethrower-fire-stream"]
handheld_stream.action = action
handheld_stream.target_position_deviation = 1.5

local stream = data.raw.stream["flamethrower-fire-stream"]
stream.action = action
stream.target_position_deviation = 1

local fire = data.raw.fire["fire-flame"]
fire.damage_per_tick.amount = 15 / 60
--fire.flags = {"placeable-off-grid"}
--fire.enemy_map_color = {r = 1, g = 1, b = 0.5}
--fire.friendly_map_color = {r = 1, g = 1, b = 0.5}
--fire.map_color = {r = 1, g = 1, b = 0.5}
