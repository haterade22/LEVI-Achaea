--[[mudlet
type: trigger
name: Can't Jinx
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Jinx
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
- pattern: Your malign power dissipates back to normal levels.
  type: 3
- pattern: ^Summoning your malign power, you direct a twin assault of the curses \w+ and \w+ at (.+)$
  type: 1
- pattern: You have not built up enough malign power to unleash a jinx.
  type: 3
]]--

ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge or 0
ataxiaTemp.jinxCharge = ataxiaTemp.jinxCharge - 1
if ataxiaTemp.jinxCharge < 1 then
	ataxiaTemp.canJinx = false
	ataxiaTemp.jinxCharge = 0
end

if ataxiaBasher.enabled and not ataxiaBasher.manual then
	deleteFull()
end

if ataxiaBasher and found_target then
	--ataxiaBasher_attack()
  basher_needAction = true
end