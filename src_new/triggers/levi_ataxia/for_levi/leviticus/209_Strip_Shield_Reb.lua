--[[mudlet
type: trigger
name: Strip Shield Reb
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- 2H
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^Lunging forward, you bring Apocalypse, a blackrock sword of black-hued steel down in a savage diagonal blow, carving
    through (\w+)'s aura of rebounding\.$
  type: 1
- pattern: ^You lunge toward (\w+) with Apocalypse, a blackrock sword of black-hued steel, but finding no resistance, you
    stumble hopelessly off balance\.$
  type: 1
- pattern: ^Planting your feet, you whirl a Hellforge Hammer over your head before bringing it down with terrible force upon
    (\w+), shattering (\w+) aura of rebounding\.$
  type: 1
]]--

targreb = false
targshield = false

tAffs.rebounding = false
tAffs.shield = false
removeAffV3("rebounding")