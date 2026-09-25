--[[mudlet
type: trigger
name: Earthquake
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
- pattern: ^Earthquake\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Earthquake is active (v4.7.357):
--
--   "Your emulation upheaval ability deals significant blunt damage to all denizens in the
--    location when it summons rubble."
--
-- ENACT UPHEAVAL (AB 2730, 2.30s of equilibrium) then rides the Psion round on idle equilibrium,
-- in a crowd, above half health -- `ataxiaBasher_psionUpheaval`, basher/002.
--
-- Only inside the tower (the gate every boon row carries since v4.7.351). Cleared on Mnemosyne run
-- start/end. Type BOONS to re-sync if needed.
if ataxiaBasher and ataxiaBasher.inMnemosyne then psionEarthquake = true end
