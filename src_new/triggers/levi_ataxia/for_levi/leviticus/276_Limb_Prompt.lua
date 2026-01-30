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

if (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" or gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then 
mymomentum = ataxia.vitals.class
end

tarc.write()