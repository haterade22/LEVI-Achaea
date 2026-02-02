--[[mudlet
type: trigger
name: Freeze (elementalism/bracers)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Magi
- Pummel-related
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
- pattern: ^You raise a hand towards (\w+)+ and blast \w+ with cold, frigid air\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  for _, aff in pairs({"nocaloric", "shivering", "frozen"}) do
    if not haveAff(aff) then
      tarAffed(aff)
      if applyAffV3 then applyAffV3(aff) end
      break
    end
  end
end