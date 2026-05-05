local constants = require("JosephMcKean.WallOfForce.constants")

local defaults = {
    logLevel = 3,
    scrollMerchants = {
        ["alenus vendu"] = true,
        ["crulius pontanian"] = true,
        ["faras thirano"] = true,
        ["folms mirel"] = true,
        ["hlendrisa seleth"] = true,
        miun_gei = true
    },
    spellMerchants = {
        ["ethasi rilvayn"] = true,
        ["farena arelas"] = true,
        gildan = true,
        imare = true,
        ["nelso salenim"] = true,
        ["ranis athrys"] = true,
        ["sharn gra-muzgob"] = true,
        ["sonummu zabamat"] = true,
        ["tunila omavel"] = true,
        tyermaillin = true
    }
}

local config = mwse.loadConfig(constants.MOD_NAME, defaults)

return config
