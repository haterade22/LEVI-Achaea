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

    CORRECTED (v4.7.416): ONE hindered leg DOES trip this line. Mystor's logs (2026-10-11) show
    it 10 times out of 10 with a single damaged or broken leg ("rl1", "RL2"), each time in the
    STAND slot of his alias, while the kick in the same alias still landed. So the line is
    STAND's refusal: the game checks the legs before "You are not fallen or kneeling.". Our
    moves send "stand;<dir>" and "stand;leap <dir>", so with one bad leg this line comes from
    the STAND and the move itself goes through; parking and re-sending it then moved us twice.
    v4.7.448 (a death): that holds for a WALK, not a LEAP. With one broken leg and prone, the line
    printed twice -- the stand AND the leap -- and no move happened. The swarm therefore TUMBLES
    on one leg (S.moveVerb, user), so its moves do not reach this refusal.
    Everything below therefore runs only when our afflictions say BOTH legs are out, which is
    when the move itself is refused.
]]--

local function legOut(side)
	local a = ataxia and ataxia.afflictions
	if not a then return false end
	for _, k in ipairs({ "broken" .. side .. "leg", "damaged" .. side .. "leg", "mangled" .. side .. "leg" }) do
		local v = a[k]
		if v and v ~= 0 then return true end
	end
	return false
end
if not (legOut("left") and legOut("right")) then return end

-- A refused round did not execute: drop every owned rotation's in-flight replay.
for _, k in ipairs({"rwBrPending", "dwBrPending", "psionBrPending", "gdragonBrPending"}) do
	ataxiaTemp[k] = nil
end

-- A SWARM ESCAPE OR PULL: park the move and re-send it the moment both legs work again (v4.7.378,
-- the entanglement rule of v4.7.370). Only acts when the swarm has a move waiting; it disarms the
-- explorer's timeout itself, so the generic release below then finds nothing in flight.
local M = ataxia and ataxia.mnemosyne
if M and M.swarm and M.swarm.onMoveRefusedBound then
	pcall(M.swarm.onMoveRefusedBound, "both legs broken")
end

-- If a tactical/explorer move was in flight, it was this command -- release it so the
-- next tick re-decides instead of burning the move timeout.
if M and M.explore and M.explore.moving and M._disarmMove then
	M._disarmMove()
	if M.echo then M.echo("<indian_red>legs broken<reset> -- the leap was refused; re-deciding.") end
end

if ataxiaEcho and ataxiaBasher and ataxiaBasher.enabled then
	ataxiaEcho("<red>Both legs broken<reset> -- movement/attack refused.")
end
