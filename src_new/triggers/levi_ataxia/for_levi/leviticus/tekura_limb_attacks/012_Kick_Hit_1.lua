--[[mudlet
type: trigger
name: Kick Hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Tekura Limb Attacks
- Tekura Kick 2
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
- pattern: ^\w+ connects to the (.+)!$
  type: 1
]]--

slc_last_limb = matches[2]
-- Guarded v4.7.261: callee lives in a script that is switched off, so a bare call throws.
if SLC_connects then SLC_connects(slc_last_limb,"tekurakick") end