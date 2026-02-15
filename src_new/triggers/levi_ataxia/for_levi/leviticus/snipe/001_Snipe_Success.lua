--[[mudlet
type: trigger
name: Snipe Success
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Snipe
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You train your expert eye on (\w+) and let fly an arrow with breathtaking precision\.$
  type: 1
- pattern: Your arrow strikes true!
  type: 3
]]--

snipe.onSuccess(multimatches[1][2])
