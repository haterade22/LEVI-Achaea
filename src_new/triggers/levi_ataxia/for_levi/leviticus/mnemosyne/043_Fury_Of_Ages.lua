--[[mudlet
type: trigger
name: Mnemosyne Fury Of Ages
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
- pattern: ^Fury of Ages\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Fury of Ages is active: "You can now use your fury
-- ability for 45 minutes out of every hour, and it grants an additional 8 strength and 20%
-- faster balance recovery, but endurance costs are quadrupled under its effect."
--
-- Base FURY (+2 str, 500 willpower after the first daily use, 4 uses/Achaean day) is
-- deliberately never automated. This boon changes that: the basher holds FURY ON while
-- endurance allows, and drops it before the quadrupled EP cost strands us
-- (ataxiaBasher_infFury, basher/002 -- thresholds infFuryOnAt/infFuryOffAt).
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
infFuryOfAges = true
