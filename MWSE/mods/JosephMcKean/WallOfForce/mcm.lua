local constants = require("JosephMcKean.WallOfForce.constants")
local config = require("JosephMcKean.WallOfForce.config")
local log = require("JosephMcKean.WallOfForce.log")

local function createTemplate()
    local template = mwse.mcm.createTemplate({
        name = constants.MOD_NAME,
        config = config
    })
    template:register()
    template:saveOnClose(constants.MOD_NAME, config)

    local settings = template:createSideBarPage({label = "Settings"})
    settings:createInfo({
        text = "Adds the Wall of Force spell and Scroll of Wall of Force, and lets you choose which merchants can sell each one."
    })
    settings:createLogLevelOptions({
        config = config,
        configKey = "logLevel",
        logger = log
    })

    template:createExclusionsPage({
        label = "Spell Merchants",
        description = "Select which spell merchants should sell the Wall of Force spell.",
        leftListLabel = "Merchants Selling Wall of Force",
        rightListLabel = "All Spell Merchants",
        variable = mwse.mcm.createTableVariable({
            id = "spellMerchants",
            table = config
        }),
        filters = {
            {
                label = "Spell Merchants",
                callback = function()
                    local merchants = {}
                    for merchant in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast merchant tes3npc
                        if merchant:offersService(tes3.merchantService.spells) then
                            table.insert(merchants, merchant.id)
                        end
                    end
                    table.sort(merchants)
                    return merchants
                end
            }
        }
    })

    template:createExclusionsPage({
        label = "Scroll Merchants",
        description = "Select which scroll merchants should sell the Scroll of Wall of Force.",
        leftListLabel = "Merchants Selling Scroll of Wall of Force",
        rightListLabel = "All Scroll Merchants",
        variable = mwse.mcm.createTableVariable({
            id = "scrollMerchants",
            table = config
        }),
        filters = {
            {
                label = "Scroll Merchants",
                callback = function()
                    local merchants = {}
                    for merchant in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast merchant tes3npc
                        if merchant.aiConfig.bartersBooks then
                            table.insert(merchants, merchant.id)
                        end
                    end
                    table.sort(merchants)
                    return merchants
                end
            }
        }
    })
end

event.register(tes3.event.modConfigReady, createTemplate)
