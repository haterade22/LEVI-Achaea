--[[mudlet
type: trigger
name: Mnemosyne Splinterbark
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
- pattern: '^Splinterbark:\s+Your tree tattoo is tainted with fell magic'
  type: 1
]]--

-- Ongoing-effect line in the Mnemosyne status screen. With Splinterbark active, touching the tree
-- tattoo bleeds us and inflicts a random malady, so onSplinterbarkSeen() turns the game's tree
-- curing off (idempotent, gated on being in a run). onRunEnd turns it back on.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onSplinterbarkSeen then
  ataxia.mnemosyne.onSplinterbarkSeen()
end
