--[[mudlet
type: trigger
name: Graveborn
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: ^Graveborn\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Graveborn is active (v4.7.348):
--
--   "While standing in gravehands, your attacks will command them to ravage your enemies,
--    damaging all denizens in your location. This can only trigger every 15 seconds."
--
-- It is the END of the necromancy combo path -- Army of the Dead + Maliceborn + Necrotic Aura --
-- and it changes what the gravehands ARE. Without it the summon is one AoE hit, worth holding
-- back for a crowd. With it the hands are a room engine that fires every 15 seconds for as long
-- as we stand in them and keep swinging, so the basher summons in EVERY room with a denizen
-- (user: "We need to ensure we gravehands every room to maximize this").
--
-- Cleared on Mnemosyne run start/end. Type BOONS to re-sync if needed.
-- Only inside the tower (v4.7.351, deep review) -- the same gate the generic row trigger
-- (mnemosyne/013) applies, so a list printed outside a run arms nothing.
if ataxiaBasher and ataxiaBasher.inMnemosyne then mnemGraveborn = true end
