--[[mudlet
type: trigger
name: Broken Legs Block
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
- pattern: Both of your legs must be free and unhindered to do that.
  type: 3
]]--

--[[
    THE LEG TWIN OF 344 (v4.7.167) -- and the more dangerous of the two.

    Nothing matched this line anywhere in the package (verified with five phrasings:
    "unhindered", "legs must", "free and unhi", "hinder", "both of your").

    A lost weapon swing is the cheap failure. The expensive one is LEAP: the Mnemosyne
    swarm module moves with `stand;leap <dir>` on its escape and pull paths
    (009_Swarm_Tactics:236 low-HP retreat, :258/:266 the wall escape decorator, :385
    the re-entry). A leap refused for broken legs is SILENT to that machinery -- the
    move sits "in flight" until M._tacticalArm's timeout expires, which stalls the
    low-HP escape ladder at exactly the moment it is holding us alive. It degrades to
    a delay rather than a livelock, but it is strictly worse than a wasted attack.

    So: tell the explorer the move never happened (it re-decides on the next decidable
    tick rather than waiting out the timeout), and roll back the owned battlerage
    replay the same way 344 and 329_Battlerage_Global_Cooldown do.

    NOTE: one broken leg does not trip this -- Achaea lets you stand and walk on one.
    The refusal means BOTH, which is also when the swarm most needs to move.
]]--

-- A refused round did not execute: drop every owned rotation's in-flight replay.
for _, k in ipairs({"rwBrPending", "dwBrPending", "psionBrPending", "gdragonBrPending"}) do
	ataxiaTemp[k] = nil
end

-- If a tactical/explorer move was in flight, it was this command -- release it so the
-- next tick re-decides instead of burning the move timeout.
local M = ataxia and ataxia.mnemosyne
if M and M.explore and M.explore.moving and M._disarmMove then
	M._disarmMove()
	if M.echo then M.echo("<indian_red>legs broken<reset> -- the leap was refused; re-deciding.") end
end

if ataxiaEcho and ataxiaBasher and ataxiaBasher.enabled then
	ataxiaEcho("<red>Both legs broken<reset> -- movement/attack refused.")
end
