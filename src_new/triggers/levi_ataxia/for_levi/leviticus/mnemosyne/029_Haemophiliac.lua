--[[mudlet
type: trigger
name: Mnemosyne Haemophiliac
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
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
- pattern: '^Haemophiliac:\s+Defeating a denizen causes you to bleed'
  type: 1
]]--

-- Ongoing-effect line in the Mnemosyne status screen: "Defeating a denizen causes
-- you to bleed significantly and your mana costs are increased by 20%." -- live
-- report: THOUSANDS of bleed after every kill. onHaemophiliacSeen() arms the
-- explorer's wade-slower pacing (post-clear moves hold until HP recovers).
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onHaemophiliacSeen then
  ataxia.mnemosyne.onHaemophiliacSeen()
end
