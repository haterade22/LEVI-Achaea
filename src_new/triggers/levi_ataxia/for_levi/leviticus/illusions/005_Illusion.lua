--[[mudlet
type: trigger
name: Illusion
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Illusions
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
- pattern: '** Illusion **'
  type: 3
- pattern: Illusion
  type: 1
]]--

tAffs.rebounding = false
tAffs.shield = false
tshield = false
trebounding = false
tAffs.curseward = false

-- Flag that an illusion was detected; ignore next 2 lines
ataxia_illusionActive = true
if ataxia_illusionClear then killTimer(ataxia_illusionClear) end
ataxia_illusionClear = tempLineTrigger(2, 1, [[ataxia_illusionActive = false; ataxia_illusionClear = nil]])