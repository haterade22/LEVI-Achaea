--[[mudlet
type: trigger
name: Freeze
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

if matches[2] ~= target then return end

 if not haveAff("shivering") and haveAff("nocaloric") then
    tarAffed("weariness")
    tarAffed("shivering")
    tarAffed("nausea")
  elseif not haveAff("nocaloric") then
    tarAffed("weariness")
    tarAffed("nocaloric")
    tarAffed("nausea")
  elseif haveAff("shivering") and haveAff("nocaloric") and not haveAff("frozen") then
    tarAffed("frozen")
    tarAffed("weariness")
    tarAffed("nausea")
  end
