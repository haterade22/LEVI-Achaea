--[[mudlet
type: trigger
name: Kuro
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
- pattern: ^Falling back into a low crouch, you lash out with a warped black iron staff coated with rust at the (\w+) thigh
    of (\w+).$
  type: 1
- pattern: ^Falling back into a low crouch, you lash out with a swift strike at the (\w+) thigh of (\w+).$
  type: 1
- pattern: ^Dropping into a lower stance, you sweep a warped black iron staff coated with rust at the (\w+) thigh of (\w+).$
  type: 1
]]--

local limb = matches[2].." leg"
monk.shikudo.limb_hit(limb, "kuro")