--[[mudlet
type: trigger
name: Stun Gone
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Curing Stuff
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
- pattern: You are no longer stunned.
  type: 3
]]--

-- Clears the flag, kills the failsafe, DROPS THE STALE 0.3s re-queue cooldown (armed before
-- the stun and still ticking, so the follow-up prompt dispatch was serving out a window it
-- had no reason to), and dispatches. See ataxiaBasher_stunEnd in basher/001.
if ataxiaBasher_stunEnd then
  ataxiaBasher_stunEnd()
else
  -- Load-order fallback: never leave the flag latched, because nothing else clears it.
  ataxia.afflictions.stun = nil
  if ataxiaBasher.enabled then ataxiaBasher_attack() end
end