local util = require("data/tf_util/tf_util")

local landmine =
{
  type = "land-mine",
  name = names.creep_landmine,
  icon = "__base__/graphics/icons/land-mine.png",
  icon_size = 32,
  flags =
  {
    "placeable-player",
    "placeable-enemy",
    "player-creation",
    "placeable-off-grid",
    "not-on-map"
  },
  --minable = {mining_time = 0.5, result = "land-mine"},
  --mined_sound = { filename = "__core__/sound/deconstruct-small.ogg" },
  max_health = 9999999,
  --corpse = "small-remnants",
  collision_box = nil,
  selection_box = nil,
  selectable_in_game = false,
  collision_mask = {},
  timeout = 0,
  --dying_explosion = "explosion-hit",
  picture_safe = util.empty_sprite(),
  picture_set = util.empty_sprite(),
  trigger_radius = names.creep_radius + 1,
  force_die_on_attack = false,
  ammo_category = "landmine",
  order = "noob",
  action =
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      source_effects =
      {
        {
          type = "nested-result",
          affects_target = true,
          action =
          {
            type = "area",
            radius = names.creep_radius + 1,
            force = "enemy",
            action_delivery =
            {
              type = "instant",
              target_effects =
              {
                {
                  type = "create-entity",
                  entity_name = names.creep_sticker,
                  trigger_created_entity = true
                }
              }
            }
          }
        }
      }
    }
  }
}

local sticker =
{
  type = "sticker",
  name = names.creep_sticker,
  --icon = "__base__/graphics/icons/slowdown-sticker.png",
  flags = {},
  animation = util.empty_sprite(),
  duration_in_ticks = 20,
  target_movement_modifier = 1/1.3
}

data:extend
{
  landmine,
  sticker
}