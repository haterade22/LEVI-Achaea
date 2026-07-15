--[[mudlet
type: trigger
name: Denizen Recklessness Applied
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
- pattern: Your foe puffs up their chest and rushes headlong into danger.
  type: 3
]]--

-- Recklessness landed on our current target ("your foe" -- no name -> current target).
-- A reckless denizen can't shield for 15s AND takes bonus damage from Headstrike, so the
-- rotation cashes it in (exploitedBy = "headstrike"). Denizen + basher only.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "recklessness")
end
