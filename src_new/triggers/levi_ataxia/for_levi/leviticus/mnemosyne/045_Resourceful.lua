--[[mudlet
type: trigger
name: Mnemosyne Resourceful
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
- pattern: ^Resourceful\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Resourceful is active: "Your endurance and willpower
-- costs are reduced by 10% and defeating a denizen restores 10% of your class resources."
--
-- For INFERNAL the class resource is LIFE ESSENCE, so every kill refunds more than three
-- Tyrannies cost (3% each). Held together with Army of the Dead this removes the reason to
-- save Tyranny for a crowd -- the basher then summons gravehands in EVERY room that has a
-- denizen, and the essence floor drops with it (ataxiaBasher_infGravehands, basher/002).
-- Cleared on run start/end; type BOONS to re-sync.
mnemResourceful = true
