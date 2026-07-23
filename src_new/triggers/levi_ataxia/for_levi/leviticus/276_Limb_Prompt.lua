--[[mudlet
type: trigger
name: Limb Prompt
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Defence
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
- pattern: ''
  type: 7
]]--

cecho(" " ..lb.prompt())

if gmcp.Char and gmcp.Char.Status and (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and ataxia.vitals and ataxia.vitals.knight == "Dual Blunt" then
mymomentum = ataxia.vitals.class or 0
end

tarc.write()