local require = function(name) return require("data/entities/"..name) end

require("biter_player")
require("deploy_machine/deploy_machine")
require("pollution_proxy")
require("creep_tumor")
require("creep_landmine")
--require("pollution_lab")