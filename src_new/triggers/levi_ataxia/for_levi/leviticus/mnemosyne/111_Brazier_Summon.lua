--[[mudlet
type: trigger
name: Brazier Summon
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
- pattern: ^You wave your hand over the brazier tattoo and summon (.+) to you\.
  type: 1
]]--

-- Convocation boon: the brazier tattoo pulled a denizen to us. Re-learn its keyword.
if ataxia.mnemosyne and ataxia.mnemosyne.onBrazierSummon then
  ataxia.mnemosyne.onBrazierSummon(matches[2])
end
