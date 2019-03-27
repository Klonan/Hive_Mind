--Basically, make them not collide with each other, and make them chart chunks.

local util = require("data/tf_util/tf_util")

local biter_names ={
  "small-biter",
  "medium-biter",
  "big-biter",
  "behemoth-biter",
  "small-spitter",
  "medium-spitter",
  "big-spitter",
  "behemoth-spitter"
}

local units = data.raw.unit

for k, name in pairs (biter_names) do
  local biter = units[name]
  if not biter then error("No Biter with name "..name) end
  biter.collision_mask = util.ground_unit_collision_mask()
  biter.radar_range = biter.radar_range or 2
end
