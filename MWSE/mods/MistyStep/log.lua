local constants = require("MistyStep.constants")
local config = require("MistyStep.config")
local log = mwse.Logger.new({
    modName = constants.MOD_NAME,
    logLevel = config.logLevel
})
return log
