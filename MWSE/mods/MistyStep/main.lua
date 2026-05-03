local mod = "Misty Step"
local config = mwse.loadConfig(mod, {logLevel = 3, targetMode = "camera"})
local log = mwse.Logger.new({modName = mod, logLevel = config.logLevel})

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
        local pos = tes3.getPlayerEyePosition()
        local dir = tes3.getPlayerEyeVector()
        log:debug("getBlinkRay (camera): position=%s direction=%s", pos, dir)
        return {position = pos, direction = dir}
    end

    -- `facing` mode: use `caster.facing` and a horizontal forward vector
    local facing = caster.facing
    local pos = caster.position + tes3vector3.new(0, 0, caster.height * 0.93) -- roughly eye level
    local dir = tes3vector3.new(math.sin(facing), math.cos(facing), 0)
    log:debug("getBlinkRay (facing): position=%s direction=%s facing=%.3f", pos,
              dir, facing)
    return {position = pos, direction = dir}
end

--- The main logic of the misty step effect. This is called on every tick of the effect, but we only want to trigger on the first tick, which is when the spell is cast.
---@param e tes3magicEffectTickEventData
local function onTickMistyStep(e)
    if (not e:trigger()) then return end -- Only trigger on the first tick of the effect

    -- Misty Step: Blink forward (60 ft at most), stopping before collision
    -- The conversion factor used in the engine between units to feet is 22.1 units/foot.
    local casterRef = e.sourceInstance.caster
    if not casterRef then
        log:error("onTickMistyStep: missing caster reference, aborting")
        return
    end
    log:debug("onTickMistyStep called for %s",
              casterRef and (casterRef.id or "unknown-id") or "unknown-ref")
    local caster = casterRef.mobile
    if not caster then
        log:error("onTickMistyStep: casterRef.mobile is nil, aborting")
        return
    end
    log:debug("caster state: position=%s height=%.3f cell=%s", caster.position,
              caster.height or 0,
              caster.cell and (caster.cell.name or "unnamed") or "nil")
    ---@cast caster tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
    local blink = getBlinkRay(caster)
    log:debug("computed blink ray: origin=%s direction=%s", blink.position,
              blink.direction)
    local blinkHit = tes3.rayTest({
        position = blink.position,
        direction = blink.direction,
        ignore = {casterRef},
        maxDistance = MAX_BLINK_DISTANCE
    })
    if blinkHit then
        log:debug(
            "blinkHit: distance=%.3f units (%.3f ft) intersection=%s reference=%s",
            blinkHit.distance, blinkHit.distance / UNITS_PER_FOOT,
            blinkHit.intersection,
            blinkHit.reference and (blinkHit.reference.id or "nil") or "nil")
    else
        log:debug("blinkHit: none (clear to max distance)")
    end

    local blinkDistance = blinkHit and
                              math.max(0, blinkHit.distance - UNITS_PER_FOOT * 2) or
                              MAX_BLINK_DISTANCE -- Subtract 2 feet from the hit distance to avoid blinking into the obstacle; if no hit, use max distance
    local candidatePosition
    local foundFloor = false
    local maxAttempts = 5
    local attempts = 0
    local downOffset = tes3vector3.new(0, 0, caster.height)

    while attempts < maxAttempts and blinkDistance > 0 do
        attempts = attempts + 1
        candidatePosition = caster.position + blink.direction * blinkDistance
        log:debug(
            "attempt %d candidate lateral position=%s blinkDistance=%.3f (%.3f ft)",
            attempts, candidatePosition, blinkDistance,
            blinkDistance / UNITS_PER_FOOT)

        local floorHit = tes3.rayTest({
            position = candidatePosition + downOffset, -- start above candidate and cast down
            direction = tes3vector3.new(0, 0, -1),
            maxDistance = caster.height * 2
        })

        if floorHit then
            log:debug("floorHit on attempt %d: intersection=%s reference=%s",
                      attempts, floorHit.intersection, floorHit.reference and
                          (floorHit.reference.id or "nil") or "nil")
            candidatePosition.z = floorHit.intersection.z
            foundFloor = true
            break
        else
            log:debug(
                "no floorHit on attempt %d; reducing blink distance and retrying",
                attempts)
            blinkDistance = blinkDistance - UNITS_PER_FOOT * 2 -- shorten by ~2 ft and try again
        end
    end

    if not foundFloor then
        log:warn(
            "onTickMistyStep: unable to find valid landing surface after %d attempts, cancelling cast",
            attempts)
        if casterRef == tes3.player then
            tes3.messageBox("Misty Step failed: no safe landing spot found.")
        end
        e.effectInstance.state = tes3.spellState.retired
        return
    end
    local teleportParams = {
        reference = casterRef,
        position = candidatePosition,
        orientation = casterRef.orientation, -- Preserve current orientation
        suppressFader = true,
        teleportCompanions = false
    }

    if caster.cell.isInterior then teleportParams.cell = caster.cell end

    log:debug(
        "teleport params: position=%s cell=%s orientation=%s suppressFader=%s",
        candidatePosition, teleportParams.cell and
            (teleportParams.cell.name or "unnamed") or "nil",
        teleportParams.orientation, teleportParams.suppressFader)
    tes3.positionCell(teleportParams)
    log:debug("teleport executed for %s",
              casterRef and (casterRef.id or "unknown-id") or "unknown-ref")

    e.effectInstance.state = tes3.spellState.retired -- Retire the effect
end

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.mistyStep,
        name = "Misty Step",
        description = ("This spell effect allows the caster to teleport a short distance."),

        school = tes3.magicSchool.mysticism,
        baseCost = 150,

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
    local SPELL_ID = "misty step"
    local spell = tes3.getObject(SPELL_ID)
    if not spell then
        spell = tes3.createObject({
            id = SPELL_ID,
            objectType = tes3.objectType.spell
        })
        tes3.setSourceless(spell)
        spell.name = "Misty Step"

        local effect = spell.effects[1]
        effect.id = tes3.effect.mistyStep
        effect.rangeType = tes3.effectRange.self
    end
    ---@cast spell tes3spell
    -- Only add the spell if the player doesn't already have it
    if not tes3.hasSpell({reference = tes3.player, spell = SPELL_ID}) then
        tes3.addSpell({reference = tes3.player, spell = spell})
    end
end)

event.register(tes3.event.initialized,
               function() log:info("Misty Step initialized.") end)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({name = mod, config = config})
    template:register()
    template:saveOnClose(mod, config)
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
event.register(tes3.event.modConfigReady, registerModConfig)
