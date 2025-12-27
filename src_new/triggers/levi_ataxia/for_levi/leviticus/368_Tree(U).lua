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
	tSingleRandom()
  	selectString(line, 1)
	fg("green")
	resetFormat()
	tBals.tree = false
  if tBals.timers.tree then killTimer(tBals.timers.tree) end
	tBals.timers.tree = tempTimer(13, [[tBals.tree = true; tBals.timers.tree = nil]])
	targetIshere = true
	
  if tburns >= 1 then
    if tburns == 1 then
      tburns = 0
    elseif tburns == 2 then
      tburns = 1
    elseif tburns == 3 then
      tburns = 2
    elseif tburns == 4 then
      tburns = 3
    elseif tburns == 5 then
      tburns = 4
    end
  end
if treeTimer0 then return end
if treeTimer4 then return end
if treeTimer9 then return end
if treeTimer then return end
treeTimer0 = tempTimer(0,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>14 seconds...\n") treeTimer0 = nil]])
treeTimer4 = tempTimer(4,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>10 seconds...\n") treeTimer4 = nil]])
treeTimer9 = tempTimer(9,[[cecho("<orange>\n[TREE]: <yellow>tree down on <red>"..target.." <yellow>for <white>5 seconds...\n") treeTimer9 = nil]])
treeTimer = tempTimer(14, [[cecho("<orange>\n[TREE]: <red>"..target.." <yellow>can now use tree!!!\n") treeTimer = nil]])
 

end