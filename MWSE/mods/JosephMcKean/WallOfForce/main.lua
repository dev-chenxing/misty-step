local constants = require("JosephMcKean.WallOfForce.constants")
local log = require("JosephMcKean.WallOfForce.log")

require("JosephMcKean.WallOfForce.effects")

event.register(tes3.event.initialized, function()
    require("JosephMcKean.WallOfForce.spell")
    log:info("%s initialized", constants.MOD_NAME)
end)

require("JosephMcKean.WallOfForce.mcm")
