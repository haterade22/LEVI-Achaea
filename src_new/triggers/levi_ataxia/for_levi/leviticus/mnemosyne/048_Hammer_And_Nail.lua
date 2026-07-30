--[[mudlet
type: trigger
name: Mnemosyne Hammer And Nail
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
- pattern: ^Hammer and Nail\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "While a sowulu rune is present, your attacks will cause damage to another
-- random denizen in the location." Every ordinary swing becomes a two-target hit, so the
-- rune is laid BEFORE attacking and only when there is a second denizen to splash onto:
-- the Runewarden basher sketches sowulu on the ground at 2+ denizens, once per room
-- (ataxiaBasher_rwSowulu, basher/002 -- ataxiaBasher.sowuluAt to tune). Sketching is a
-- FREE-queue action, so it costs no balance. Cleared on run start/end.
--
-- NOTE: distinct from `mnemHammerAnvil` (Hammer and Anvil -- attacks bypass denizen
-- shields). Two different boons, similar names.
mnemHammerAndNail = true
