--[[mudlet
type: trigger
name: Mnemosyne Dragged From Sky
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
- pattern: ^A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth\.$
  type: 1
]]--

--[[
    A DENIZEN CAN PULL US OUT OF THE AIR (live 2026-07-30).

    This is the third way flight fails in the tower, after the Deluge affix (no flying
    underwater) and an eaten FLY command. It is the nastiest of the three because it
    is SILENT to the state machine: the recovery hover keeps `S.flying` optimistically
    true until a flight line confirms, and after a drag that confirmation never comes
    -- so the hover re-sends `fly` every single tick while a tentacle yanks us straight
    back down, holding us attack-GATED at crash HP with the swarm still on us, until
    RECOVER_MAX finally expires. Strictly worse than never having flown at all.

    Per-RIPPLE, not per-run: the thing that dragged us lives on this ripple and will do
    it again, but the next ripple is a different room set. S.onRipple clears it.

    -> S.onDraggedDown(): latch grounded (so S._canFly and hence S._canHover both go
       false and the ladder takes the grounded retreat), correct the flight state, and
       convert an in-progress hover into that retreat instead of letting it spin.
]]--

local S = ataxia and ataxia.mnemosyne and ataxia.mnemosyne.swarm
if S and S.onDraggedDown then
	S.onDraggedDown()
end
