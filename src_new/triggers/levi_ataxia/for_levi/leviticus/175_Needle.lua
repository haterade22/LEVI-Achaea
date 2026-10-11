--[[mudlet
type: trigger
name: Needle
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
  isColorizerTrigger: 'yes'
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
- pattern: ^Reversing your grip on a warped black iron staff coated with rust, you drive the top of the weapon into the throat
    of (\w+).$
  type: 1
- pattern: ^With pinpoint precision, you drive a warped black iron staff coated with rust at the throat of (\w+).$
  type: 1
]]--
-- v4.7.414: guarded. No script in this package defines monk.shikudo, so this call threw
-- "attempt to index global 'monk'" on every strike line it matched.
if monk and monk.shikudo and monk.shikudo.limb_hit then monk.shikudo.limb_hit("head", "needle") end