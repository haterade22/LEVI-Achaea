--[[mudlet
type: trigger
name: Visions
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Priest
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
- pattern: ^You condemn (\w+) to see the fate of the enemies of creation.$
  type: 1
- pattern: ^(\w+) begins to tremble uncontrollably as \w+ turns \w+ righteous gaze upon \w+.$
  type: 1
]]--

if isTargeted(matches[2]) then
  if haveAff("dementia") then
    tarAffed("shyness")
  else
    tarAffed("dementia")
	end
end