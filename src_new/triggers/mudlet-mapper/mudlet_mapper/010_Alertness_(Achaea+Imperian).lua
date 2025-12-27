--[[mudlet
type: trigger
name: Alertness (Achaea+Imperian)
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'no'
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
- pattern: ^Your enhanced senses inform you that (\w+) has entered (.+?)(?:, to the| at your) (\w+)\.$
  type: 1
]]--

mmp.alertness = mmp.alertness or {}
local alertness = mmp.alertness

local roomexists, getRoomName, anytolong, matches, deleteLine = mmp.roomexists, getRoomName, mmp.anytolong, matches, deleteLine

if mmp.debug then
 mmp.alertnessTime = mmp.alertnessTime or createStopWatch()
 startStopWatch(mmp.alertnessTime)
end

if matches[4] ~= "location" then
  local longexitname = matches[4]
  alertness[longexitname] = alertness[longexitname] or {}
  alertness[longexitname][#alertness[longexitname]+1] = matches[2]
  deleteLine()
elseif matches[4] == "location" then
  local currentroomname = mmp.cleanroomname(mmp.currentroomname)
  if matches[3] == currentroomname then
    alertness.here = alertness.here or {}
    alertness.here[#alertness.here+1] = matches[2]
    deleteLine()
  end
end


if not mmp.firstAlert then
	mmp.firstAlert = true
	mmp.pdb_lastupdate = {}
end

mmp.pdb[matches[2]] = matches[3]
mmp.pdb_lastupdate[matches[2]] = true

enableTrigger"Mudlet Mapper prompt trigger"

if mmp.debug then mmp.echo("alertness trigger for "..matches[2].." took "..stopStopWatch(mmp.alertnessTime).."s.") end