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
	if tAffs.paralysis then
		erAff("paralysis")
	end
  if passiveFailsafe then restorePassiveCure() end

	-- V3 integration: one tree is ONE cure. With V3 on, ataxia_targetTreeV3 (curing/002) lets
	-- onTargetTreeV3 charge it, branching over every tree-curable affliction (blackout included
	-- since v4.7.416), then clears in tAffs what V3 took for certain and charges a broken limb V3
	-- cannot see. tSingleRandom() erasing its own pick on top charged one tree twice: asthma +
	-- slickness + blackout read 4/3 afflictions after one tree, where the truth is 2. With V3 on
	-- it now only computes its pick (noErase); with V3 off it erases, as before.
	if onTargetTreeV3 and affConfigV3 and affConfigV3.enabled then
		ataxia_targetTreeV3()
		tSingleRandom({ noErase = true })
	else
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
	
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}
  magi.offense.state.burns = math.max((magi.offense.state.burns or 0) - 1, 0)
  tburns = magi.offense.state.burns
if treeTimer0 then return end
if treeTimer4 then return end
if treeTimer9 then return end
if treeTimer then return end
treeTimer0 = tempTimer(0,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>14 seconds...\n") treeTimer0 = nil]])
treeTimer4 = tempTimer(4,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>10 seconds...\n") treeTimer4 = nil]])
treeTimer9 = tempTimer(9,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>5 seconds...\n") treeTimer9 = nil]])
treeTimer = tempTimer(14, [[cecho("<orange>\n[TREE]: <red>"..target.." <yellow>can now use tree!!!\n") treeTimer = nil]])
 

end