--[[mudlet
type: trigger
name: Mnemosyne Righteous Fire Save
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
- pattern: ^Fire surges about you, restoring you from death's cold brink
  type: 1
]]--

-- WRATH AND RIGHTEOUSNESS: the save's own line (the maintainer's paste, 2026-11-24, v4.7.518):
-- "Fire surges about you, restoring you from death's cold brink and bringing holy wrath down upon
-- <name> in a brilliant conflagration." The pattern stops at an early phrase, so the server's wrap
-- and the name cannot break it. The line is the proof (the game line outranks our bookkeeping): it
-- drops a held death (S.deathHold) at once, defs up and fights on (S.onRighteousFire, 009). The jump
-- in health (S._checkRighteousFire) stays the backstop; a save it already saw is not counted twice.
local S = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
if not (S and S.onRighteousFire) then
  ataxiaEcho("Righteous Fire save line seen, but the Mnemosyne swarm is not loaded -- nothing to do.")
  return
end
if S._rfAt and (getEpoch() - S._rfAt) < 3 then return end -- the health jump already ran it
S.onRighteousFire("the fire line")
