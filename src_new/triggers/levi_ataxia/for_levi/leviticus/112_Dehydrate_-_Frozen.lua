--[[mudlet
type: trigger
name: Dehydrate - Frozen
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You rip the heat from (\w+)\.$
  type: 1
]]--

 if not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("shivering")
    haveAff("nausea")
  elseif not tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("nocaloric")
    haveAff("nausea")
  elseif tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    tarAffed("weariness")
    haveAff("nausea")
  end