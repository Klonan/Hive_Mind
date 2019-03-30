local require = function(str) return require("data/entities/deploy_machine/"..str) end

require("biter_deployer")
require("spitter_deployer")
--require("circuit_deploy_machine")
