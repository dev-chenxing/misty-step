local constants = require("JosephMcKean.MistyStep.constants")
local config = require("JosephMcKean.MistyStep.config")
local log = require("JosephMcKean.MistyStep.log")

local function createTemplate()
    local template = mwse.mcm.createTemplate({
        name = constants.MOD_NAME,
        config = config
    })
    template:register()
    template:saveOnClose(constants.MOD_NAME, config)
    local settings = template:createSideBarPage({label = "Settings"})
    settings:createDropdown{
        label = "Should Misty Step use camera aim (includes up/down) or character facing (horizontal only)?",
        description = "- Camera: uses camera aim (including up/down). \n\n- Facing: uses character facing and ignores vertical aim.",
        options = {
            {label = "Camera Mode", value = "camera"},
            {label = "Facing Mode", value = "facing"}
        },
        variable = mwse.mcm.createTableVariable {
            id = "targetMode",
            table = config
        }
    }
    settings:createLogLevelOptions{
        config = config,
        configKey = "logLevel",
        logger = log
    }
end
event.register(tes3.event.modConfigReady, createTemplate)
