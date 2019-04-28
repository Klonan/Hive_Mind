
local make_damage_tech = function(category, icons)
  local tech =
    {
    type = "technology",
    name = category.."-damage-1",
    localised_name = {category.."-damage"},
    icons = icons,
    effects =
    {
      {
        type = "ammo-damage",
        ammo_category = category,
        modifier = 0.1
      }
    },
    prerequisites = {},
    unit =
    {
      count_formula = "2^(L-1)*500",
      ingredients =
      {
        {names.pollution_proxy, 1}
      },
      time = 1
    },
    max_level = "infinite",
    upgrade = true,
    order = catagory
  }
  data:extend{tech}
end

make_damage_tech("melee",
{
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/behemoth-biter.png",
    scale = 1
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/big-biter.png",
    shift = {-24, 32},
    scale = 0.7
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/medium-biter.png",
    shift = {0, 32},
    scale = 0.5
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/small-biter.png",
    shift = {24, 32},
    scale = 0.3
  },
})

make_damage_tech("biological",
{
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/behemoth-spitter.png",
    scale = 1
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/big-spitter.png",
    shift = {-24, 32},
    scale = 0.7
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/medium-spitter.png",
    shift = {0, 32},
    scale = 0.5
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/small-spitter.png",
    shift = {24, 32},
    scale = 0.3
  },
})

make_damage_tech("worm-biological",
{
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/behemoth-worm.png",
    scale = 1
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/big-worm.png",
    shift = {-24, 32},
    scale = 0.7
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/medium-worm.png",
    shift = {0, 32},
    scale = 0.5
  },
  {
    icon_size = 32,
    icon = "__base__/graphics/icons/small-worm.png",
    shift = {24, 32},
    scale = 0.3
  },
})