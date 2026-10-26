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
-- while you possess the satiation defence." The defence comes from the Survival skill SATIATION
-- (4s equilibrium, 100 mana) followed by a meal inside its short window, so while the flag is up
-- `ataxia_satiationTick` (misc_scripts/022, v4.7.452) sends `satiation;eat <food>` whenever the
-- defence is absent and equilibrium is free -- a corpse under Obligate Carnivore, else the horn.
-- Cleared on run start/end. Type BOONS to re-sync.
mnemHealingMetabolism = true
