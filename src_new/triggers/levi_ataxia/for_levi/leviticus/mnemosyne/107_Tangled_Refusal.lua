--[[mudlet
type: trigger
name: Tangled Refusal
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: You are too tangled up to do that.
  type: 3
]]--

-- ENTANGLED -- the command was refused (the death log, 2026-09-30: a claw fiend's tentacle, and
-- the wall pull's point + leap both answered with this line). If it was the swarm's tactical move,
-- the move is parked and re-sent on the first prompt we are no longer bound (v4.7.370, user:
-- "retry the command when we are free"). Anything else refusing -- an attack -- is ignored there.
if ataxia.mnemosyne and ataxia.mnemosyne.swarm and ataxia.mnemosyne.swarm.onMoveRefusedBound then
  ataxia.mnemosyne.swarm.onMoveRefusedBound()
end
