--[[mudlet
type: trigger
name: Hammer raze
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
- pattern: ^You lunge toward (\w+) with a Hellforge Hammer, but finding no resistance, you stumble hopelessly off balance\.$
  type: 1
- pattern: ^Planting your feet, you whirl a Hellforge Hammer over your head before bringing it down with terrible force upon
    (\w+), shattering (\w+) aura of rebounding\.$
  type: 1
]]--

targreb = false
targshield = false
tAffs.shield = false
if removeAffV3 then removeAffV3("shield") end
tAffs.rebounding = false
if removeAffV3 then removeAffV3("rebounding") end




