--[[mudlet
type: trigger
name: Legslash
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Blademaster Limb Attacks
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
- pattern: ^With a smooth lunge to the (\w+), (\w+) draws \w+ \w+ from its scabbard and delivers a powerful slash across your
    legs\.$
  type: 1
- pattern: '1'
  type: 5
]]--

if multimatches[1][2] == "left" then 
	slc_last_limb = "left leg"
elseif multimatches[1][2] == "right" then
	slc_last_limb = "right leg"
end