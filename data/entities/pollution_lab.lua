
local name = names.pollution_lab
local util = require("data/tf_util/tf_util")
local graphics = util.copy(data.raw["unit-spawner"]["biter-spawner"])

util.recursive_hack_scale(graphics, 3/5)

local lab = util.copy(data.raw.lab.lab)

data:extend{lab}
