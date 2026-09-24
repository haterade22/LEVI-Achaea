--[[mudlet
type: trigger
name: Mnemosyne Famine
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
- pattern: '^Famine:\s+Taking damage has a chance to make you more hungry'
  type: 1
]]--

-- Ongoing-effect line in the Mnemosyne status screen (live 2026-09-24):
--   Famine:   Taking damage has a chance to make you more hungry, and your healing received from
--             elixirs, moss, and potash is reduced by 20%.
-- Hunger normally arrives on a slow clock; this drives it off damage taken, which in a wade never
-- stops. `onFamineSeen()` latches the affix and feeds once; from then on `ataxia_famineTopUp` runs
-- on every room's last kill (trigger 340). Idempotent and gated on being in a run.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onFamineSeen then
  ataxia.mnemosyne.onFamineSeen()
end
