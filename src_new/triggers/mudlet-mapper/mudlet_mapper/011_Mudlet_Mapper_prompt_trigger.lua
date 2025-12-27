--[[mudlet
type: trigger
name: Mudlet Mapper prompt trigger
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
- pattern: ''
  type: 7
]]--

-- to be enabled by functions that need it and disabled after it's done. Sort of like a cheap prompttrigger from Svo.
mmp.firstAlert = false
-- handle alertness
if mmp.alertness and next(mmp.alertness) then

  local dirs = {}
  for direction, _ in pairs(mmp.alertness) do dirs[#dirs+1] = direction end
  local people = select(2, next(mmp.alertness)) or {}

  moveCursor(0, getLineNumber())

  if ndb then
    local getcolor = ndb.getcolor
    for i = 1, #people do
      people[i] = getcolor(people[i])..people[i]
    end
  end

  cinsertText("<red>[<cyan>" .. table.concat(dirs, ', ') .. " <red>-"..(#dirs > 1 and ("\n  ") or '').." <white>" .. ((svo and svo.concatand) and svo.concatand(people) or table.concat(people, ', ')) .. "<cyan> ("..#people..")<red>]\n")

  moveCursorEnd()

  mmp.alertness = nil

  raiseEvent("mmapper updated pdb")
end

-- reset names we last seen, so scripts can be efficient
-- not finished yet
--if next(mmp.pdb_lastupdate) then
--  mmp.pdb_lastupdate = {}
--end

disableTrigger"Mudlet Mapper prompt trigger"