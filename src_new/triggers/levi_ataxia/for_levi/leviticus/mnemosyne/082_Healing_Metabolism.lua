--[[mudlet
type: trigger
name: Mnemosyne Healing Metabolism
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
- pattern: ^Healing Metabolism\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Healing Metabolism: "Your health elixirs are 50% more effective
-- while you possess the satiation defence." That makes satiation an UPKEEP rather than a hunger
-- floor: with Obligate Carnivore also held the kill trigger tops it up off the fresh corpse
-- (`ataxia_carnivoreTopUp`); ALONE (v4.7.303) the horn of plenty is the food source -- the SCORE
-- hunger row, the satiation defence leaving GMCP, or a kill with a stale reading all feed off it
-- whenever hunger reads below "utterly satiated" (`ataxia_hornSatiate`, misc_scripts/022).
-- Cleared on run start/end. Type BOONS to re-sync.
mnemHealingMetabolism = true
