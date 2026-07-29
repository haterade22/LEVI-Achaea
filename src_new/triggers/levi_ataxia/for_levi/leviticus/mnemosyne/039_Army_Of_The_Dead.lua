--[[mudlet
type: trigger
name: Mnemosyne Army Of The Dead
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
- pattern: ^Army of the Dead\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Army of the Dead is active: "When summoning the
-- hands of the grave, you will deal damage to all denizens in the location." That turns
-- an Oppression hinder into a room nuke, so the Infernal basher casts SUMMON HANDS OF
-- THE GRAVE whenever 2+ denizens share the room (ataxiaBasher_infGravehands, basher/002).
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
infArmyOfDead = true
