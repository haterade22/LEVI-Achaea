--[[mudlet
type: trigger
name: Paralysis Or No
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- SNB
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
- pattern: ^(\w+) stands up\.$
  type: 1
]]--

if target == matches[2] then
 tAffs.paralysis = false
 if removeAffV3 then removeAffV3("paralysis") end
  if tAffs.slickness then
  tarAffed("slickness")
  if applyAffV3 then applyAffV3("slickness") end
  end
end