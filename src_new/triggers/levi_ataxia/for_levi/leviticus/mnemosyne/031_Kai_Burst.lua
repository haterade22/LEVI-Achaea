--[[mudlet
type: trigger
name: Mnemosyne Kai Burst
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
- pattern: ^Your surroundings ripple like a lake's surface struck as a transparent wave of kai energy surges
  type: 1
]]--

-- Kai Unleashed burst CONFIRMED (live-captured 2026-07-27, 8472 magical AoE): the
-- boon's 30s cooldown starts from THIS line, not from the choke send -- an eaten
-- choke retries instead of locking the burst out. Self-proving: the line only
-- prints with the boon up, so it also (re)sets mnemKaiUnleashed.
if ataxiaBasher_kaiUnleashedBurst then
  ataxiaBasher_kaiUnleashedBurst()
end
