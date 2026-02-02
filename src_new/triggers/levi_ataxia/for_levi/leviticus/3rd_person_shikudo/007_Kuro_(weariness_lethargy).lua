--[[mudlet
type: trigger
name: Kuro (weariness/lethargy)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
- 3rd Person Shikudo
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
- pattern: ^The staff cracks across the (\w+) thigh of (.+).$
  type: 1
]]--

if isTargeted(matches[3]) then
  if not ignoreThirdPerson then
    if haveAff("weariness") then
      tarAffed("lethargy")
      if applyAffV3 then applyAffV3("lethargy") end
    else
      tarAffed("weariness")
      if applyAffV3 then applyAffV3("weariness") end
    end
  else
    ignoreThirdPerson = nil    
  end
end