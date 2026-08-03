--[[mudlet
type: trigger
name: Denizen Clumsy Proc
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Highlighting
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
- pattern: ^(.+) flails about clumsily\.$
  type: 1
]]--

-- "A Hriddan hunter flails about clumsily." -- CLUMSY paying off: the mob wasting an attack
-- (it misses 33% of them for 7s). User asked for it to be highlighted, 2026-08-03.
--
-- This is the PROC, not the apply. `denizen_attacks_misc_lines/022` owns the apply line
-- ("You rummage quickly through <mob>'s mind, finding the link to fine motor control...")
-- and is what records the affliction and fires the `(BR):` alert. Deliberately a separate
-- trigger rather than a second pattern on 022: they mean different things, and folding them
-- together would re-announce "CLUMSY applied" on every fumble.
--
-- HIGHLIGHT ONLY -- it records nothing. It is tempting to treat a proc as proof the aff is
-- still up and re-stamp it, but `ataxiaBasher_BR_AFFS.clumsy` runs its 7s duration from the
-- APPLY, and refreshing on a proc would quietly extend our model past the real thing. The
-- proc is evidence clumsy is live; it is not evidence of when it started.
--
-- `light_cyan` matches the CLUMSY alert colour in 022, so the apply and its payoff read as
-- the same effect. Bold, like every other "our thing worked" line. Not the orange family
-- (reserved). Type 1 anchored regex, never type 3 -- the mob name varies.
--
-- ECHOED as well as highlighted (user, 2026-08-03). The highlight tells you where to look if
-- you happen to be looking; the echo is what survives a screen moving at hundreds of lines a
-- minute. Throttled to once every 3s -- clumsy misses 33% of a mob's attacks, so in a crowded
-- room this line can fire several times a second and an unthrottled echo would bury the
-- console it is meant to clarify.
selectString(line, 1)
setBold(true)
fg("light_cyan")
deselect()
resetFormat()
ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or 0
if nowT ~= ataxiaTemp.clumsyEchoAt then
  ataxiaTemp.clumsyEchoAt = nowT
  if ataxiaBasher_dsAlert then
    ataxiaBasher_dsAlert("CLUMSY paying off -- " .. tostring(matches[2]) .. " wasted an attack", "light_cyan")
  end
end
