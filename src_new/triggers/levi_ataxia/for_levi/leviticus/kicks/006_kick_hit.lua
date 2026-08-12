--[[mudlet
type: trigger
name: kick hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Shikudo Limb Attacks
- Kicks
- Frontkick
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
- pattern: ^Pain blossoms as the instep of (\w+)'s foot smashes into the vulnerable cluster of nerves beneath your (.*), sending
    you spinning to the ground\.$
  type: 1
]]--

slc_last_limb = matches[3]
-- Guarded v4.7.261: callee lives in a script that is switched off, so a bare call throws.
if SLC_connects then SLC_connects(slc_last_limb,"frontkick") end