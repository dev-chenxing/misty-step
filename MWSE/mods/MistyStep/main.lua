local constants = require("MistyStep.constants")
local log = require("MistyStep.log")
local blink = require("MistyStep.blink")

-- Cache failed validations between `spellMagickaUse` and `spellCast` events.
local pendingFailedCasts = {}

tes3.claimSpellEffectId("mistyStep", 8377)

--- Misty Step: Blink forward (60 ft at most), stopping before collision
---@param e tes3magicEffectTickEventData
local function onTickMistyStep(e)
    if (not e:trigger()) then return end -- Only trigger on the first tick of the effect

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
    local ray = blink.getBlinkRay(caster)
    log:debug("computed blink ray: origin=%s direction=%s", ray.position,
              ray.direction)

    local candidatePosition = blink.findLandingPosition(casterRef, ray)
    if not candidatePosition then
        log:warn(
            "onTickMistyStep: unable to find valid landing surface, cancelling cast")
        if casterRef == tes3.player then
            tes3.messageBox("Misty Step failed: no safe landing spot found.")
        end
        e.effectInstance.state = tes3.spellState.retired
        return
    end

    if blink.performTeleport(casterRef, candidatePosition) then
        log:debug("teleport executed for %s",
                  casterRef and (casterRef.id or "unknown-id") or "unknown-ref")
    end

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
    local spell = tes3.getObject(constants.SPELL_ID)
    if not spell then
        spell = tes3.createObject({
            id = constants.SPELL_ID,
            objectType = tes3.objectType.spell
        })
        tes3.setSourceless(spell)
        spell.name = "Misty Step"
        spell.magickaCost = 21

        local effect = spell.effects[1]
        effect.id = tes3.effect.mistyStep
        effect.rangeType = tes3.effectRange.self
    end
    ---@cast spell tes3spell
    -- Only add the spell if the player doesn't already have it
    if not tes3.hasSpell({reference = tes3.player, spell = constants.SPELL_ID}) then
        tes3.addSpell({reference = tes3.player, spell = spell})
    end
end)

event.register(tes3.event.initialized,
               function() log:info("Misty Step initialized.") end)

-- Pre-validate landing during spellMagickaUse and prevent magicka spending on failure.
event.register(tes3.event.spellMagickaUse, function(e)
    if not e.spell or e.spell.id ~= constants.SPELL_ID then return end
    log:debug("spellMagickaUse event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then
        log:debug("spellMagickaUse: missing caster reference")
        return
    end

    local mobile = casterRef.mobile
    if not mobile then
        log:debug("spellMagickaUse: caster has no mobile component")
        return
    end
    ---@cast mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer

    local magickaCost = e.cost or 0
    if mobile.magicka and mobile.magicka.current and mobile.magicka.current <
        magickaCost then
        log:debug(
            "spellMagickaUse: insufficient magicka (have=%.0f need=%.0f), skipping landing validation",
            mobile.magicka.current, magickaCost)
        return
    end

    local ray = blink.getBlinkRay(mobile)
    local landing = blink.findLandingPosition(casterRef, ray)
    if not landing then
        log:info(
            "spellMagickaUse: no valid landing, preventing magicka cost for %s",
            casterRef.id or "unknown")
        e.cost = 0
        pendingFailedCasts[casterRef] = "no-landing"
    end
end)

-- Cancel the cast in spellCast if pre-validation failed, and show player-facing message.
event.register(tes3.event.spellCast, function(e)
    if not e.source or e.source.id ~= constants.SPELL_ID then return end
    log:debug("spellCast event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then return end

    log:debug("spellCast: source=%s castChance=%.2f",
              e.source and (e.source.id or "unknown") or "nil",
              e.castChance or 0)
    local reason = pendingFailedCasts[casterRef]
    if reason then
        pendingFailedCasts[casterRef] = nil
        log:info("spellCast: cancelling Misty Step cast for %s due to %s",
                 casterRef.id or "unknown", tostring(reason))
        if casterRef == tes3.player then
            tes3.messageBox("Misty Step failed: no safe landing spot found.")
        end
        e.castChance = 0
    else
        if (e.castChance or 0) == 0 then
            log:warn(
                "spellCast: castChance is 0 for %s but no pre-validation flag set; cast failed for another reason",
                casterRef.id or "unknown")
        end
    end
end)

require("MistyStep.mcm")
