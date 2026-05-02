local mod = "Misty Step"
local logger = require("logging.logger")
local config = mwse.loadConfig(mod, {logLevel = "INFO"})
local log = logger.new({name = mod, logLevel = config.logLevel})

tes3.claimSpellEffectId("mistyStep", 8377)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.mistyStep,
        name = "Misty Step",
        description = ("This spell effect allows the caster to teleport a short distance."),

        school = tes3.magicSchool.mysticism,
        baseCost = 150,

        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        canCastSelf = true,
        canCastTarget = false,
        canCastTouch = false,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = true,
        hasNoMagnitude = true,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = true,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = false, -- For some reason, setting unreflectable to true causes the "can't re-cast" bug to occur
        usesNegativeLighting = false,

        icon = "s\\Tx_S_fire_damage.tga", -- for testing; will be changed later
        lighting = tes3vector3.new(0.99, 0.95, 0.67),
        particleTexture = "vfx_particle064.tga",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",

        onTick = function(e)
            if (not e:trigger()) then return end

            -- Misty Step logic will go here. 
            -- For now, we'll just teleport the caster to a hardcoded position for testing purposes.

            local teleportParams = {
                reference = e.sourceInstance.caster,
                position = tes3vector3.new(0, 0, 0),
                cell = tes3.getCell({id = "Balmora, South Wall Cornerclub"})
            }
            tes3.positionCell(teleportParams)

            e.effectInstance.state = tes3.spellState.retired
        end
    })
end)

event.register(tes3.event.loaded, function()
    local spell = tes3.createObject({objectType = tes3.objectType.spell})
    ---@cast spell tes3spell
    tes3.setSourceless(spell)
    spell.name = "Misty Step"
    spell.magickaCost = 1

    local effect = spell.effects[1]
    effect.id = tes3.effect.mistyStep
    effect.rangeType = tes3.effectRange.self

    tes3.addSpell({reference = tes3.mobilePlayer, spell = spell})
end)

event.register(tes3.event.initialized,
               function() log:info("Misty Step initialized.") end)

