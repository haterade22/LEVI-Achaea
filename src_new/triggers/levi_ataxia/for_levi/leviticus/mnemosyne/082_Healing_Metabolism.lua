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
-- floor, so with Obligate Carnivore also held the kill trigger tops it up off the fresh corpse
-- (`ataxia_carnivoreTopUp`). Alone it changes nothing -- there is no way to hold satiation without
-- a food source. Cleared on run start/end. Type BOONS to re-sync.
mnemHealingMetabolism = true
