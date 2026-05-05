local constants = require("JosephMcKean.WallOfForce.constants")

local defaults = {logLevel = 3, scrollMerchants = {}, spellMerchants = {}}

local config = mwse.loadConfig(constants.MOD_NAME, defaults)

return config
