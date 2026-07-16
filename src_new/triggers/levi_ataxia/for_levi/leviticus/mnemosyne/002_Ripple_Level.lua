--[[mudlet
type: trigger
name: Mnemosyne Ripple Level
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
- pattern: ^You wade (\d+) ripples? deep into the tides of memory
  type: 1
]]--

-- "You wade N ripples deep..." only prints inside a wade, so it proves we are in it whatever
-- gmcp claims (Creville's Legacy / incurable dementia fakes the room wholesale). Assert BEFORE
-- onRipple: its context guard requires in-Mnemosyne context to bootstrap a run, so without
-- this a missed run-start (e.g. reconnecting mid-climb) could never recover.
if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("wade status") end

ataxia.mnemosyne.onRipple(tonumber(matches[2]))
