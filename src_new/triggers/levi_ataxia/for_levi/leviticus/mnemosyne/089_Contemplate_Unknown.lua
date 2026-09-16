--[[mudlet
type: trigger
name: Mnemosyne Contemplate Unknown
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
- pattern: ^You consider for a time, but no information comes to you on such a boon\.$
  type: 1
]]--

-- BOON CONTEMPLATE refused the name (captured live 2026-09-16). Until v4.7.308 nothing heard this
-- line, so the catalogue trickle asked the same unrecognised name at every boon screen forever.
-- `M.onContemplateUnknown` (004_Parsers) marks the name in flight as unknown to the game, skips it
-- from the gap list, says which name it was, and finishes the capture so a batch moves on.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onContemplateUnknown then
  ataxia.mnemosyne.onContemplateUnknown()
end
