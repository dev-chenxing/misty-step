local mod = "Misty Step"
local config = mwse.loadConfig(mod, {logLevel = "INFO", targetMode = "camera"})
local log = mwse.Logger.new()

local UNITS_PER_FOOT = 22.1
local MAX_BLINK_DISTANCE = 60 * UNITS_PER_FOOT

tes3.claimSpellEffectId("mistyStep", 8377)

---@class getBlinkRayResult
---@field position tes3vector3 The starting position of the blink ray.
---@field direction tes3vector3 The normalized direction vector of the blink ray.

--- Gets the origin and direction for the misty step blink based on the caster's facing and a configurable mode (camera vs facing).
--- @param caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer The caster of the spell.
--- @return getBlinkRayResult The origin and direction for the blink ray.
local function getBlinkRay(caster)
    -- `camera` mode: only when the caster is the player, use `tes3.getPlayerEyePosition()` and `tes3.getPlayerEyeVector()` to give the blink a more "aimed" feel based on camera direction; this is the default option for the spell and can be toggled in the MCM
    if config.targetMode == "camera" and caster == tes3.mobilePlayer then
        return {
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector()
        }
    end

    -- `facing` mode: use `caster.facing` and a horizontal forward vector
    local facing = caster.facing
    return {
        position = caster.position + tes3vector3.new(0, 0, caster.height * 0.93), -- roughly eye level
        direction = tes3vector3.new(math.sin(facing), math.cos(facing), 0)
    }
end

--- The main logic of the misty step effect. This is called on every tick of the effect, but we only want to trigger on the first tick, which is when the spell is cast.
---@param e tes3magicEffectTickEventData
local function onTickMistyStep(e)
    if (not e:trigger()) then return end -- Only trigger on the first tick of the effect

    -- Misty Step: Blink forward (60 ft at most), stopping before collision
    -- The conversion factor used in the engine between units to feet is 22.1 units/foot.
    local casterRef = e.sourceInstance.caster
    log:debug("onTickMistyStep called for %s",
              casterRef and casterRef.object and casterRef.object.name or
                  "unknown caster")
    local caster = casterRef.mobile
    ---@cast caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
    local blink = getBlinkRay(caster)
    local blinkHit = tes3.rayTest({
        position = blink.position,
        direction = blink.direction,
        ignore = {casterRef},
        maxDistance = MAX_BLINK_DISTANCE
    })
    local blinkDistance = blinkHit and
                              math.max(0, blinkHit.distance - UNITS_PER_FOOT) or
                              MAX_BLINK_DISTANCE -- Subtract a safety buffer of 1 ft to avoid landing inside the hit object; ensure that travel distance is not negative
    local candidatePosition = caster.position + blink.direction * blinkDistance
    local floorHit = tes3.rayTest({
        position = candidatePosition + tes3vector3.new(0, 0, caster.height), -- Start the raycast from above the candidate position to ensure it can detect the floor even if the candidate position is slightly inside the ground
        direction = tes3vector3.new(0, 0, -1),
        maxDistance = caster.height * 2 -- Cast downwards for a distance equal to twice the caster's height to ensure it can find the floor even if the candidate position is above a ledge or stair
    })
    if floorHit then candidatePosition.z = floorHit.intersection.z end

    local teleportParams = {
        reference = casterRef,
        position = candidatePosition,
        orientation = casterRef.orientation, -- Preserve current orientation
        suppressFader = true,
        teleportCompanions = false
    }

    if caster.cell.isInterior then teleportParams.cell = caster.cell end

    tes3.positionCell(teleportParams)

    e.effectInstance.state = tes3.spellState.retired -- Retire the effect
end

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

        onTick = onTickMistyStep
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

local function registerModConfig()
    local template = mwse.mcm.createTemplate({name = mod, config = config})
    template:register()
    template:saveOnClose(mod, config)
    local settings = template:createPage({label = "Settings"})
    settings:createDropdown{
        label = "Should Misty Step use camera aim (includes up/down) or character facing (horizontal only)?",
        description = "Camera: uses camera aim (including up/down). Facing: uses character facing and ignores vertical aim.",
        options = {
            {label = "Camera Mode", value = "camera"},
            {label = "Facing Mode", value = "facing"}
        },
        variable = mwse.mcm.createTableVariable {
            id = "targetMode",
            table = config
        }
    }
    settings:createLogLevelOptions{config = config, configKey = "logLevel"}
end
event.register(tes3.event.modConfigReady, registerModConfig)
