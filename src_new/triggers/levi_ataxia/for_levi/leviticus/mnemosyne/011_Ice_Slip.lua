--[[mudlet
type: trigger
name: Mnemosyne Ice Slip
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
- pattern: ^You slip and fall on the ice
  type: 1
- pattern: ^Your mount slips and falls on the ice
  type: 1
]]--

-- Icy room: the move failed (you fell prone) but the exit is fine. Let the
-- explorer re-send the move instead of condemning the exit.
--
-- MOUNTED (v4.7.369): "Your mount slips and falls on the ice as you try to leave." was not matched,
-- so a mounted slip waited out the 5s move timeout, retried once, and then CONDEMNED a good exit.
-- User: "we need to keep trying, it doesn't cost balance to move on ice." It is the same event, so
-- it gets the same re-send -- and it proves we are in the saddle, so the jump verb learns it too.
if line and line:find("^Your mount slips") and ataxiaBasher_mountedSet then
  ataxiaBasher_mountedSet(true, "your mount slipped on the ice")
end
if ataxia.mnemosyne and ataxia.mnemosyne.onIceSlip then ataxia.mnemosyne.onIceSlip() end
