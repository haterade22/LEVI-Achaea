--[[mudlet
type: trigger
name: Brazier Ready
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: Power returns to your brazier tattoo in a muted flash.
  type: 3
]]--

-- Convocation boon: the tattoo is ready again. The game line ends the cooldown, not our 60 s count.
if ataxia.mnemosyne and ataxia.mnemosyne.onBrazierReady then
  ataxia.mnemosyne.onBrazierReady()
end
