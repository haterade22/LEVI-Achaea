--[[mudlet
type: trigger
name: Hiru
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
- pattern: ^Whirling a warped black iron staff coated with rust in a tight arc, you bring the weapon around to crash into
    the side of the head of (\w+).$
  type: 1
- pattern: ^Snapping back into a ready stance, you whirl a warped black iron staff coated with rust in a long sweep at the
    head of (\w+).$
  type: 1
]]--

monk.shikudo.limb_hit("head", "hiru")