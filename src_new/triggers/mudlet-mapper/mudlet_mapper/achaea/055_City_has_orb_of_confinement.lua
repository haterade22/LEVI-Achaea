--[[mudlet
type: trigger
name: City has orb of confinement
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
attributes:
  isActive: 'no'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: A shimmering orb covers the city
  type: 2
- pattern: A shimmering orb covers the city, preventing you from rising to the skies.
  type: 3
]]--

 -- disabled since the orb is now an rng chance and not a 100% blocker

local orbTable = mmp.getAchaeaOrbTable()
local areaID = getRoomArea(mmp.currentroom) or 0
if areaID == 0 or mmp.game ~= "achaea" then
  return
end
--don't know where we are
for city, areas in pairs(orbTable) do
  if table.contains(areas, areaID) then
    if not mmp.settings["orb" .. city] then
      mmp.settings:setOption("orb" .. city, true)
      mmp.inside = true
      raiseEvent("mmapper went inside")
      if mmp.autowalking then
        mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath])
      end
    end
    return
  end
end
if mmp.autowalking then
  mmp.stop()
end