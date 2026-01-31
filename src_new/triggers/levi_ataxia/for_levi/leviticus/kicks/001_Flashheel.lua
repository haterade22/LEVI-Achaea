--[[mudlet
type: trigger
name: Flashheel
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Shikudo Limb Attacks
- Kicks
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: ^Snapping \w+ leg out to its full extent, (\w+) drives a heel into your (\w+) knee\.$
  type: 1
- pattern: '1'
  type: 5
]]--


if multimatches[1][3] == "left" then
	slc_last_limb = "left leg"
elseif multimatches[1][3] == "right" then
	slc_last_limb = "right leg"
end