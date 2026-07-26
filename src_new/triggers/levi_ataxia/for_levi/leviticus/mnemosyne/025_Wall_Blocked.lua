--[[mudlet
type: trigger
name: Mnemosyne Wall Blocked
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
- pattern: A wall blocks your way.
  type: 3
- pattern: A wall bars your path.
  type: 3
]]--

-- An icewall rejected the explorer's walk (ours from the swarm tactic, or any
-- affix/denizen wall). The exit is REAL -- onWallBlocked leaps it with the
-- chitin greaves instead of condemning it (user-directed). Self-gated on an
-- in-flight explorer move, so manual play is untouched (766_Wall handles that).
if ataxia.mnemosyne and ataxia.mnemosyne.onWallBlocked then
  ataxia.mnemosyne.onWallBlocked()
end
