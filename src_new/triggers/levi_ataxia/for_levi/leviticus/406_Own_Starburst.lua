--[[mudlet
type: trigger
name: Own Starburst
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^Your starburst tattoo flares as the world is momentarily tinted red\.$
  type: 1
]]--

-- We just died and starburst resurrected. Fire the death handler immediately
-- to shut down the basher before the next prompt can dispatch another attack.
-- A starburst is a death that happened: nothing held for the Wrath and Righteousness save
-- (v4.7.512; mnemosyne/009, S.deathHold) waits any longer, and this call is not held.
local S = ataxia.mnemosyne and ataxia.mnemosyne.swarm
if S and S.deathIsReal then S.deathIsReal("starburst") end
ataxiaBasher_onDeath(true)
