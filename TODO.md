# Misty Step

## MWSE

- [x] feat: claim spell effect id
- [x] feat: add magic effect
- [x] feat: create misty step spell
- [x] feat: implement "misty step" effect logic
  - [x] feat: get the caster from the effect event
  - [x] feat: derive a forward vector from the actor's facing
  - [x] feat: raycast forward from roughly eye level with `tes3.rayTest`, using a max distance of 60 ft to find the target location; ignore the caster so you do not hit your own model.
  - [x] feat: if the ray hits something, clamp the blink distance to hit.distance minus a safety buffer (e.g. 2 ft); if it does not hit, use the full blink distance
  - [x] feat: compute the candidate landing point and preserve the current orientation when calling `tes3.positionCell`; for player feel, `suppressFader = true` and `teleportCompanions = false`
  - [x] feat: validate the landing spot vertically; the main failure case is blinking into a ledge, stair, or uneven ground; do a short downward ray from candidate + upward offset to find the floor and set Z from that hit; if that ray misses, shorten the blink and try again, up to a maximum number of attempts (e.g. 5)
- [x] feat: add MCM settings to toggle between "camera" (default) and "facing" target modes
- [x] docs: add metadata.toml
- [x] feat: distribute the Misty Step spell
  - [x] feat: create Misty Step scroll
- [x] refactor: validate landing before magicka is consumed
- [x] refactor: extract magic-effect registration to `effects.lua`
- [x] fix: validate landing before scroll is consumed

## Icons
- [x] feat: add icon for effect

## Docs
- [x] docs: update README with spell distribution (vendors, scrolls, etc.)

# Wall of Force

- Creates a temporary planar barrier (vertical wall segment).
- Physically blocks actors and projectiles
- Subtle shimmer visual effect on the wall surface
- Duration-based. Limit to 1 active wall per caster.

## MWSE
- [x] chore: scaffold the mod layout
- [ ] chore: add spellMerchant and scrollMerchant distribution lists to MCM
- [x] feat: claim spell effect id
- [ ] feat: add magic effect
  - [ ] fix: tweak the base cost to be more balanced
- [ ] feat: create Wall of Force spell
- [ ] feat: implement "wall of force" effect logic
  - [ ] feat: derive wall position and orientation from the caster
  - [ ] feat: spawn a thin "invisible" box niTriShape visual
  - [ ] feat: enforce 1 active wall per caster; if the caster already has an active wall, despawn it before creating a new one
  - [ ] test: verify that the wall blocks actors and projectiles
  - [ ] test: verify that the wall is cleaned up after the duration expires or is replaced
- [ ] feat: add a shimmer visual effect on the wall surface
- [ ] docs: add metadata.toml

## Icons
- [ ] feat: add icon for effect

## Docs
- [ ] docs: update README with Wall of Force spell details and distribution