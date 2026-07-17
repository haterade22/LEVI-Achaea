--[[mudlet
type: trigger
name: Mnemosyne Aspect Of Kkractle
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
- pattern: ^Aspect of Kkractle\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Aspect of Kkractle is active: it makes ELEMENTAL SURGE
-- (Magi's Artificing ashbeast command) deal FIRE damage to ALL denizens in the room (an AoE
-- nuke, 3.6s eq cooldown). While magiKkractle is set the Magi basher swaps its single-target
-- staff attack to `elemental surge`. Cleared on Mnemosyne run start/end (mirrors bardWarmarch /
-- bmShatteredStar). Needs a summoned ashbeast up (kept off the target list via ownDenizens).
-- Type BOONS to re-sync if needed.
magiKkractle = true
