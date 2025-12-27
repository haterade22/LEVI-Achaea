--[[mudlet
type: trigger
name: Deliverance Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
- Deliverance
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
- pattern: ^([A-Z][a-z]+) slowly raises (\w+) head and you see (\w+) eyes glowing bright white\.$
  type: 1
]]--

cecho("\n<white:blue>DELIVERANCE UP, DON'T HIT <yellow:blue>" .. matches[2] .. "!\n<white:blue>DELIVERANCE UP, DON'T HIT <yellow:blue>" .. matches[2] .. "!\n<white:blue>DELIVERANCE UP, DON'T HIT <yellow:blue>" .. matches[2] .. "!")
ataxia_setWarning(matches[2].." has deliverance", 2)


if matches[2] == target then
tdeliverance = true
end