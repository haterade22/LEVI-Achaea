--[[mudlet
type: trigger
name: Mnemosyne Go
hierarchy:
- Levi_Ataxia
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
- pattern: ^GO!$
  type: 1
]]--

ataxia.mnemosyne.onGo()
-- Auto-resume the explorer on the new wave: after picking a boon + wading, GO marks the next
-- ripple starting, so LOOK (holding-room down exit) and un-pause the sweep. No-op if not paused.
if ataxia.mnemosyne.exploreOnGo then ataxia.mnemosyne.exploreOnGo() end
-- Sleuth boon recon: fullsense reveals ALL denizens in the ripple -- scan it from the
-- holding room before the sweep drops in. No-op unless mnemSleuth is set (009).
if ataxia.mnemosyne.swarm and ataxia.mnemosyne.swarm.onGo then ataxia.mnemosyne.swarm.onGo() end
