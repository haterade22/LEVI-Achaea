--[[mudlet
type: trigger
name: Mnemosyne Sense Lines
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
- pattern: ^You sense out the location of your prey
  type: 1
- pattern: ^You sense (.+) \(#(\d+)\) at (.+)\.$
  type: 1
]]--

-- Bloodscent recon rows (live-captured 2026-07-26):
--   You sense out the location of your prey...
--   You sense a shadowy basilisk (#371988) at Beneath an ancient tree.
-- One row per denizen in the ripple. The handlers batch rows and commit the
-- parsed recon ({name,id,room} + per-room counts) into the swarm module; both
-- self-gate on being in the tower. Sleuth's manual fullsense feeds the same
-- parser when its rows share this shape.
local S = ataxia.mnemosyne and ataxia.mnemosyne.swarm
if not S then return end
if matches[3] then
  if S.onSenseRow then S.onSenseRow(matches[2], matches[3], matches[4]) end
elseif S.onSenseStart then
  S.onSenseStart()
end
