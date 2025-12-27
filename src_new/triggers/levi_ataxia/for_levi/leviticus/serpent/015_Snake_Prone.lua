--[[mudlet
type: trigger
name: Snake Prone
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^A .+ tangles itself in the legs of (\w+), sending \w+ sprawling to the ground\.$
  type: 1
]]--

if isTargeted(matches[2]) then
incommingsnakeprone = false
tempTimer(2,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 6 seconds")]])
tempTimer(4,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 4 seconds")]])
tempTimer(6,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): Snake Prone in 2 seconds")]])
tempTimer(7,[[cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<white>): Snake Prone in 1.2 seconds")]])
tempTimer(7.5,[[incommingsnakeprone = true]])

end