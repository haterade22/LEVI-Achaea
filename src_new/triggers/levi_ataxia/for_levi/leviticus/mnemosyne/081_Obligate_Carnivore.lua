--[[mudlet
type: trigger
name: Mnemosyne Obligate Carnivore
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
- pattern: ^Obligate Carnivore\s+\d+\s+\w+
  type: 1
]]--

-- A row in the BOONS list confirms Obligate Carnivore: "You can EAT corpses, restoring hunger and
-- small amounts of endurance and willpower." Corpses arrive by themselves (`340_Slain` retrieves
-- one per kill), so this turns food from a horn charge into something free -- and
-- `ataxia_hornOnHungry` prefers a corpse over the horn while it is held. Cleared on run start/end
-- like every other boon flag. Type BOONS to re-sync.
mnemObligateCarnivore = true
