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
data.creep_radius = 16
data.creep_sticker = "creep-sticker"
data.creep_landmine = "creep-landmine"

data.required_pollution =
{
  [data.deployers.biter_deployer] = 100,
  [data.deployers.spitter_deployer] = 200,
  [data.creep_tumor] = 20,
  ["small-worm-turret"] = 50,
  ["medium-worm-turret"] = 150,
  ["big-worm-turret"] = 400,
  ["behemoth-worm-turret"] = 1000
}

return data
