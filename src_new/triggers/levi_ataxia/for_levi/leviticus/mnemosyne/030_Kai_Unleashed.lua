--[[mudlet
type: trigger
name: Mnemosyne Kai Unleashed
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
- pattern: ^Kai Unleashed\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list (name / echoes / rarity) confirms Kai Unleashed is
-- active: kai choking a denizen bursts magic damage on ALL denizens in the room
-- (30s cooldown). The Shikudo basher fires KAI CHOKE in Rain form when 2+
-- denizens share the room (ataxiaBasher_kaiUnleashedChoke, basher/002). Cleared
-- on Mnemosyne run start/end (mirrors the other boon flags). Type BOONS to
-- re-sync if needed.
mnemKaiUnleashed = true
