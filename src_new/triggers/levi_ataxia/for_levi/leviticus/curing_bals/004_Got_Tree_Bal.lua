--[[mudlet
type: trigger
name: Got Tree Bal
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
- Curing Bals
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
- pattern: You may utilise the tree tattoo again.
  type: 3
]]--

ataxiaTemp.usedTree = nil
-- The tattoo is available again. If a Seasone phial lock is being held open waiting for it,
-- spend it NOW rather than on the next timer tick (v4.7.213) -- during a truelock the seconds
-- between ticks are the ones that kill.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onTreeReady then
  ataxia.mnemosyne.onTreeReady()
end