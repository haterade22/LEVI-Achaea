--[[mudlet
type: trigger
name: Mnemosyne Daemon Jaws
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
- pattern: ^Daemon Jaws\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Daemon Jaws is active: "The cooldown for commanding
-- your hyena to maul a denizen is reduced by 66%." The maul reset is normally driven by
-- the game's own ready-line, which simply arrives sooner -- but the SAFETY timer that
-- covers a missed line must shrink to match, or it becomes the thing gating us at 30s
-- while the real cooldown is ~10s (ataxiaBasher_hyenaMaulCooldown, basher/005).
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
infDaemonJaws = true
