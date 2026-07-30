--[[mudlet
type: trigger
name: Mnemosyne Falconers Tactics
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
- pattern: ^Falconer's Tactics\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "The cooldown for commanding your falcon to rake a denizen is reduced by
-- 66%." The Runewarden twin of Daemon Jaws. The game's own ready-line comes sooner, so the
-- rotation needs no change -- but the missed-line SAFETY timer must shrink to match or it
-- becomes the gate at 30s while the real cooldown is ~10s
-- (ataxiaBasher_falconRakeCooldown, basher/005). Cleared on run start/end.
mnemFalconersTactics = true
