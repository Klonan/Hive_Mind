--Shared data interface between data and script, notably prototype names.

local data = {}

data.deployers =
{
  biter_deployer = "biter-deployer",
  spitter_deployer = "spitter-deployer"
}

data.players =
{
  small_biter_player = "small-biter-player",
  medium_biter_player = "medium-biter-player",
  big_biter_player = "big-biter-player",
  behemoth_biter_player = "behemoth-biter-player",
}

data.pollution_proxy = "pollution-proxy"

data.firestarter_gun = "firestarter-gun"
data.firestarter_ammo = "firestarter-ammo"

data.creep = "creep"
data.creep_tumor = "creep-tumor"
data.creep_radius = 10
data.creep_sticker = "creep-sticker"
data.creep_landmine = "creep-landmine"
data.pollution_lab = "pollution-lab"
data.pollution_drill = "pollution-drill"
data.sticker_proxy = "sticker-proxy"

data.required_pollution =
{
  [data.deployers.biter_deployer] = 100,
  [data.deployers.spitter_deployer] = 200,
  [data.creep_tumor] = 50,
  [data.pollution_lab] = 150,
  [data.pollution_drill] = 100,
  ["small-worm-turret"] = 200,
  ["medium-worm-turret"] = 400,
  ["big-worm-turret"] = 800,
  ["behemoth-worm-turret"] = 1600
}

data.needs_proxy_type =
{
  ["assembling-machine"] = true,
  ["lab"] = true,
  ["mining-drill"] = true
}

data.default_unlocked =
{
  ["small-biter"] = true,
  ["small-spitter"] = true,
  ["small-worm-turret"] = true
}

data.needs_creep =
{
  ["small-worm-turret"] =true,
  ["medium-worm-turret"] = true,
  ["big-worm-turret"] = true,
  ["behemoth-worm-turret"] = true,
  [data.creep_tumor] = true,
  [data.pollution_drill] = true,
  [data.pollution_lab] = true,
}

data.pollution_recipe_scale = 2
data.pollution_progress_scale = 2

return data
