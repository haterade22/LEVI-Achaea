--[[mudlet
type: trigger
name: Tree(U)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) touches a tree of life tattoo.$
  type: 1
]]--

local name = matches[2]

if isTargeted(name) and tBals.tree then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end

	-- V3 integration: one tree is ONE cure. With V3 on, ataxia_targetTreeV3 (curing/002) lets
	-- onTargetTreeV3 charge it, branching over every tree-curable affliction (blackout included
	-- since v4.7.416), then clears in tAffs what V3 took for certain and charges a broken limb V3
	-- cannot see. tSingleRandom() erasing its own pick on top charged one tree twice: asthma +
	-- slickness + blackout read 4/3 afflictions after one tree, where the truth is 2. With V3 on
	-- it now only computes its pick (noErase); with V3 off it erases, as before.
	-- Paralysis blocks the tree, so the tree proves it absent. With V3 on, onTargetTreeV3 owns that
	-- proof, and it needs the branches as they are: an erase before it stripped paralysis from every
	-- branch, so the branches the tree rules out kept their weight. The erase after it only catches
	-- a paralysis that tAffs alone held (ataxia_targetTreeV3 has reported the one V3 held).
	if onTargetTreeV3 and affConfigV3 and affConfigV3.enabled then
		ataxia_targetTreeV3()
		if tAffs.paralysis then erAff("paralysis") end
		tSingleRandom({ noErase = true })
	else
		if tAffs.paralysis then erAff("paralysis") end
		if onTargetTreeV3 then onTargetTreeV3() end
		tSingleRandom()
	end
  	selectString(line, 1)
	fg("green")
	resetFormat()
	tBals.tree = false
	-- When this target last treed: a reader takes 13 s minus its age as the cooldown left. Trees
	-- came 13-16 s apart (FceAmb0o:359 onwards); the 13 s re-arm is below. A target switch resets
	-- tBals.tree (016) but not this stamp, so read it only while tBals.tree is false.
	ataxiaTemp.targetTreeAt = getEpoch()
  if tBals.timers.tree then killTimer(tBals.timers.tree) end
	tBals.timers.tree = tempTimer(13, [[tBals.tree = true; tBals.timers.tree = nil]])
	targetIshere = true
	-- The tree leaves the Magi burn count (magi.offense.state.burns, tburns) alone. It used to take
	-- one burn off on every tree, whatever the tree cured; burning is not a tree cure in V3
	-- (treeCurableAffsV3), and the game's own lines own the count: general/025 lowers it on "The
	-- fires consuming X diminish somewhat." A tree on burning Kalys left burning at 1.00 while the
	-- tree branched over frozen, weariness and nausea
	-- (kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt:359-361). Deep review F19.
-- A new tree starts a new countdown. The old code returned while any echo was still pending, so a
-- tree that came just before the 14 s echo got no countdown at all: in the 2026-11-07 spar,
-- Saibel's tree came 12 ms before that echo, and that tree never got its own echoes. Now the pending
-- echoes are killed and four new ones start. The 13 s tBals.tree re-arm above does not change.
-- Each one is checked by itself: the 0 s echo is nil by then, and ipairs over a list would stop
-- at that nil.
if treeTimer0 then killTimer(treeTimer0) end
if treeTimer4 then killTimer(treeTimer4) end
if treeTimer9 then killTimer(treeTimer9) end
if treeTimer then killTimer(treeTimer) end
treeTimer0 = tempTimer(0,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>14 seconds...\n") treeTimer0 = nil]])
treeTimer4 = tempTimer(4,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>10 seconds...\n") treeTimer4 = nil]])
treeTimer9 = tempTimer(9,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>5 seconds...\n") treeTimer9 = nil]])
treeTimer = tempTimer(14, [[cecho("<orange>\n[TREE]: <red>"..target.." <yellow>can now use tree!!!\n") treeTimer = nil]])
 

end