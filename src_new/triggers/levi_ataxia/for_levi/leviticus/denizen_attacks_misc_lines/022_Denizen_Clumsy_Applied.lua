--[[mudlet
type: trigger
name: Denizen Clumsy Applied
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You rummage quickly through (.+)'s mind, finding the link to fine motor control before exerting a small amount
  type: 1
]]--

-- Our Scramble battlerage (MIND SCRAMBLE, 22 rage) landed -> the current denizen has CLUMSY
-- (misses 33% of its attacks, 7s) -- hit-prevention, so it matters on a no-flee climb.
-- The line names the mob but it is always the current `target`, so set it there directly
-- (no name-resolution ambiguity across same-named mobs). Pattern intentionally mirrors
-- 332_Battlerage_Special, which also matches this line to stamp the shared `special`
-- cooldown -- both fire, and they share no mutable state.
-- Denizen + basher only (numeric target guards it out of PvP).
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "clumsy")
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("CLUMSY on " .. tostring(target) .. " -- mob misses 33% of attacks (7s)", "light_cyan")
  end
end
