--[[mudlet
type: trigger
name: GAGS
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK
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
- pattern: The instep of your foot smashes into
  type: 2
- pattern: 'The staff cracks across the '
  type: 2
- pattern: ^The staff connects to the .+ with a resounding crack, the limb flopping uselessly.$
  type: 1
- pattern: You are not currently riding anything.
  type: 3
- pattern: You may not flow from
  type: 2
]]--

deleteFull()