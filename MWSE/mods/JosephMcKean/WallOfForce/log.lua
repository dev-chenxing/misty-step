local constants = require("JosephMcKean.WallOfForce.constants")
local config = require("JosephMcKean.WallOfForce.config")

local log = mwse.Logger.new({
    modName = constants.MOD_NAME,
    logLevel = config.logLevel
})

return log
