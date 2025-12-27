--[[mudlet
type: trigger
name: Mind Lock Gone
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Allies/Enemies
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
- pattern: ^Your mental lock on (\w+) is shattered as (her|his) mind rejects your psychic intrusion.$
  type: 1
- pattern: Your mind lock has been severed because your target is no longer in the same area.
  type: 3
- pattern: Your mindlock with (.+) shatters!
  type: 1
]]--

mindlocked = false
deleteFull()
ataxia_boxEcho("MIND LOCK GONE", "red")