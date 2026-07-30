--[[mudlet
type: trigger
name: Runewarden Etch Landed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: You trace the outline of a rune in the air with
  type: 3
]]--

--[[
    Runewarden ETCH fire line (captured live 2026-07-30):

      "You trace the outline of a rune in the air with Valafar, a crimson-tinged
       hellforged longsword. The edges catch fire as it hurtles towards a decaying
       zombie, clipping him slightly as it dissipates."

    Substring match on the opening clause -- the weapon name and the target vary.

    Etch is the ONE ability in RW_BR with no fire-line trigger, so its in-flight pick
    replay (ataxiaTemp.rwBrPending, ~3s) had nothing to release it: after the queued
    etch actually fired, the next two rebuilds re-queued the SAME etch and the server
    rejected both with "You must wait a short time before you can use a battlerage
    ability again." (live log 2026-07-30, two wasted cycles in a row). Confirming here
    releases the hold and restarts the 23s cooldown from the moment it landed.
]]--

if ataxiaBasher_rwConfirm then
    ataxiaBasher_rwConfirm("etch")
end
