--[[mudlet
type: trigger
name: Fulminated Paralysis
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Magi
- Magi Offense Tracking
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
- pattern: ^Horror overcomes (\w+)'s face as \w+ body stiffens into paralysis\.$
  type: 1
]]--

-- 420_Paralysis matches the same Horror line and gives the same paralysis. Whichever runs first
-- gives it, and the other sees it certain (isAffCertainV3, 007), so one line is one "tar afflicted".
if isTargeted(matches[2]) then
  if not (isAffCertainV3 and isAffCertainV3("paralysis")) then
    tarAffed("paralysis")
  end
end
