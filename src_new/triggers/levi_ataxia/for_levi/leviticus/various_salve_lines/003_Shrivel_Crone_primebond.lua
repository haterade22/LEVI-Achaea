--[[mudlet
type: trigger
name: Shrivel/Crone primebond
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Various Salve Lines
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
- pattern: ^You touch (\w+)'s (.+), and it shrivels away.$
  type: 1
- pattern: ^A withered crone reaches out to caress the (.+) of (\w+), the limb withering away under \w+ \w+ grasp.
  type: 1
- pattern: ^The crone withers (\w+)'s (.+) into uselessness.$
  type: 1
]]--

local limb = ""
if isTargeted(matches[2]) then
  limb = matches[3]
elseif isTargeted(matches[3]) then
  limb = matches[2]
else
  return
end
tarAffed("broken"..limb:gsub(" ", ""))