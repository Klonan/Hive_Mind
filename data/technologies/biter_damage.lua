
local make_damage_tech = function(category, icons)
  local tech =
    {
    type = "technology",
    name = category.."-damage-1",
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
      count_formula = "2^(L-1)*100",
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

local make_damage_tech = function(category, icons)
  local tech =
    {
    type = "technology",
    name = category.."-damage-1",
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
      count_formula = "2^(L-1)*100",
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
    icon_size = 352,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-02.png"
  },
  {
    icon_size = 356,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-mask1-02.png",
    tint = {r = 1}
  }
})

make_damage_tech("biological",
{
  {
    icon_size = 352,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-02.png"
  },
  {
    icon_size = 356,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-mask1-02.png",
    tint = {r = 1}
  }
})

make_damage_tech("worm-biological",
{
  {
    icon_size = 352,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-02.png",
    shift = {16, 0}
  },
  {
    icon_size = 356,
    icon = "__base__/graphics/entity/biter/hr-biter-attack-mask1-02.png",
    tint = {r = 1},
    shift = {16, 0}
  }
})