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
- [ ] feat: distribute the Misty Step spell

## Icons
- [ ] feat: add icon for effect
