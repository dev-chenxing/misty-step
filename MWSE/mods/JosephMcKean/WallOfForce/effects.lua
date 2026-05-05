local constants = require("JosephMcKean.WallOfForce.constants")
local log = require("JosephMcKean.WallOfForce.log")
local wall = require("JosephMcKean.WallOfForce.wall")

tes3.claimSpellEffectId("wallOfForce", 8378)

-- Natural expiry does not fire `magicEffectRemoved`, so onTick also needs to
-- watch for the effect/source transitioning into their shutdown states.
local function shouldDespawn(e)
    return e.effectInstance.state == tes3.spellState.ending or
               e.effectInstance.state == tes3.spellState.retired or
               e.sourceInstance.state == tes3.spellState.ending or
               e.sourceInstance.state == tes3.spellState.retired
end

---@param e tes3magicEffectTickEventData
local function onTickWallOfForce(e)
    local casterRef = e.sourceInstance.caster
    if not casterRef then
        log:error("onTickWallOfForce: missing caster reference, aborting")
        e.effectInstance.state = tes3.spellState.retired
        return
    end

    -- `e:trigger()` returns true on the first tick that applies the effect.
    -- Spawn the wall there, then let later ticks serve only as lifecycle checks.
    local eventResult = e:trigger()
    if eventResult and not wall.isActive(e.sourceInstance, casterRef) then
        wall.spawn(casterRef, e.sourceInstance)
    end

    if wall.isActive(e.sourceInstance, casterRef) and shouldDespawn(e) then
        wall.despawn(e.sourceInstance, casterRef)
    end
end

event.register(tes3.event.magicEffectRemoved, function(e)
    if not e.effect or e.effect.id ~= tes3.effect.wallOfForce then return end
    wall.despawn(e.sourceInstance, e.caster)
end)

event.register(tes3.event.magicEffectsResolved, function()
    tes3.addMagicEffect({
        id = tes3.effect.wallOfForce,
        name = constants.MOD_NAME,
        description = "Creates a temporary planar barrier.",

        school = tes3.magicSchool.alteration,
        baseCost = 3,

        canCastTarget = false,
        canCastTouch = false,
        casterLinked = false,
        hasContinuousVFX = false,
        hasNoDuration = false,
        hasNoMagnitude = true,
        illegalDaedra = false,
        isHarmful = false,
        nonRecastable = true,
        targetsAttributes = false,
        targetsSkills = false,
        unreflectable = true,
        usesNegativeLighting = false,

        icon = "s\\tx_s_shield.dds",
        particleTexture = "vfx_alt_glow02.tga",
        castSound = "alteration cast",
        castVFX = "VFX_ShieldCast",
        boltSound = "alteration bolt",
        boltVFX = "VFX_DefaultBolt",
        hitSound = "alteration hit",
        hitVFX = "VFX_ShieldHit",
        areaSound = "alteration area",
        areaVFX = "VFX_DefaultArea",

        onTick = onTickWallOfForce
    })
end)

return nil
