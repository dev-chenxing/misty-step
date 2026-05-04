local constants = require("MistyStep.constants")
local defaults = {logLevel = 3, targetMode = "camera"}
local config = mwse.loadConfig(constants.MOD_NAME, defaults)
return config
