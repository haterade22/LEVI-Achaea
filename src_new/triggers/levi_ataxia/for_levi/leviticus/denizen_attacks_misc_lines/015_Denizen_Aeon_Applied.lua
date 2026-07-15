--[[mudlet
type: trigger
name: Denizen Aeon Applied
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
- pattern: Your foe blurs and begins to move slower in time.
  type: 3
]]--

-- Aeon landed on our current target ("your foe") -- the denizen attacks at 66% speed
-- for 6s (a mitigation aff; no bonus-damage exploit). Record it. Denizen + basher only.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "aeon")
end
