--[[mudlet
type: trigger
name: Frontkick
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MONK 1
- Monk
- Start Shikudo
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
mStayOpen: 2
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You lash out with a straight kick at the (\w+) shoulder of (\w+).$
  type: 1
]]--
-- v4.7.414: guarded. No script in this package defines monk.shikudo, so this call threw
-- "attempt to index global 'monk'" on every strike line it matched.
local limb = matches[2].. " arm"
if monk and monk.shikudo and monk.shikudo.limb_hit then monk.shikudo.limb_hit(limb, "frontkick") end