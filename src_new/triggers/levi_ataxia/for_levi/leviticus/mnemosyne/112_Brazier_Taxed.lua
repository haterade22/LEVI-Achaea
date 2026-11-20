--[[mudlet
type: trigger
name: Brazier Taxed
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
- pattern: The colour is leeched from your brazier tattoo as it is greatly taxed.
  type: 3
]]--

-- Convocation boon: the tattoo is on its 60 s cooldown from this line.
if ataxia.mnemosyne and ataxia.mnemosyne.onBrazierTaxed then
  ataxia.mnemosyne.onBrazierTaxed()
end
