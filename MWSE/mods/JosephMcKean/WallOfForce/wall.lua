local constants = require("JosephMcKean.WallOfForce.constants")
local log = require("JosephMcKean.WallOfForce.log")

local wall = {}
local activeWalls = {}

-- Key wall state by magic-source serial when possible so each cast gets its own
-- lifecycle. Fall back to caster id only when a source instance is unavailable.
---@param sourceInstance tes3magicSourceInstance|nil
---@param casterRef tes3reference|nil
---@return number|string|nil
local function getWallKey(sourceInstance, casterRef)
    if sourceInstance and sourceInstance.serialNumber then
        return sourceInstance.serialNumber
    end

    return casterRef and casterRef.id or nil
end

---Returns whether this cast currently has a tracked wall instance.
---@param sourceInstance tes3magicSourceInstance|nil
---@param casterRef tes3reference|nil
---@return boolean
function wall.isActive(sourceInstance, casterRef)
    local key = getWallKey(sourceInstance, casterRef)
    return key ~= nil and activeWalls[key] ~= nil or false
end

---Tracks wall state for a cast. The actual scene node/collision object will be
---attached here once the real wall implementation exists.
---@param casterRef tes3reference|nil
---@param sourceInstance tes3magicSourceInstance|nil
---@return boolean
function wall.spawn(casterRef, sourceInstance)
    if not casterRef then
        log:error("wall.spawn: missing caster reference")
        return false
    end

    local key = getWallKey(sourceInstance, casterRef)
    if not key then
        log:error("wall.spawn: missing wall key")
        return false
    end

    if activeWalls[key] then
        log:debug("wall.spawn: wall already active for %s",
                  casterRef.id or "unknown")
        return true
    end

    activeWalls[key] = {
        casterId = casterRef.id,
        sourceSerial = sourceInstance and sourceInstance.serialNumber or nil
    }

    -- Derive wall transform from caster position and facing.
    -- Position: in front of the caster at a configurable distance.
    -- Orientation: align to caster orientation so the wall faces outward.

    local facing = nil
    if casterRef and casterRef.mobile and casterRef.mobile.facing then
        facing = casterRef.mobile.facing
    else
        log:error(
            "wall.spawn: missing caster facing; cannot derive wall orientation")
        activeWalls[key] = nil
        return false
    end

    local forward = tes3vector3.new(math.sin(facing), math.cos(facing), 0)

    -- Anchor the wall at bottom-center (caster's position + forward offset)
    local position = casterRef.position + forward * constants.WALL_DISTANCE

    activeWalls[key].bottomCenter = position
    activeWalls[key].facing = facing

    return true
end

---Clears the tracked wall state for a cast and will later own the real wall
---object cleanup when the visual/collision implementation lands.
---@param sourceInstance tes3magicSourceInstance|nil
---@param casterRef tes3reference|nil
---@return boolean
function wall.despawn(sourceInstance, casterRef)
    local key = getWallKey(sourceInstance, casterRef)
    if not key or not activeWalls[key] then return false end

    local wallData = activeWalls[key]
    activeWalls[key] = nil
    log:info("Wall of Force despawned for %s", wallData.casterId or "unknown")

    -- If we had created any runtime objects they would be cleaned up here.
    return true
end

return wall
