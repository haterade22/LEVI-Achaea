--[[mudlet
type: trigger
name: Denizen Stun Applied
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
- pattern: ^You hurl a precise blast of Shin energy at (.+)'s eyes\.$
  type: 1
]]--

-- Our Daze landed -> the current denizen is Stunned (does nothing for 4s -- the key
-- hit-prevention aff in Mnemosyne). The line names the mob but it is always the current
-- `target`, so set it there directly (no name-resolution ambiguity across same-named mobs).
-- Trigger 332 also matches this line to stamp the shared `special` cooldown -- both fire.
-- Denizen + basher only (numeric target guards it out of PvP).
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "stun")
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("STUN on " .. tostring(target) .. " -- mob does nothing (4s)", "magenta")
  end
end
