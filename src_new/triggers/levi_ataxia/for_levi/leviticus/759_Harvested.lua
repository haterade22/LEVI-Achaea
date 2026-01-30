--[[mudlet
type: trigger
name: Harvested
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Harvesting
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
- pattern: 'You reach out and carefully '
  type: 2
]]--

if not autoHarvesting then return end
deleteFull()

bashConsoleEchom("HERB", harvest_in_room[1]:gsub("harvest", "Harvested")..".", "SeaGreen", "a_darkgreen")
table.remove(harvest_in_room, 1)
if harvest_in_room[1] then
	send("queue addclear free "..harvest_in_room[1])
else

  if ataxiaExtraction[gmcp.Room.Info.area] then
    send("queue addclear free extract "..ataxiaExtraction[gmcp.Room.Info.area],false)
  end

  if ataxiaHarvester_manual_harvesting then
    if zgui then
      cecho("bashDisplay", " <green>"..string.char(8))
    else
      ataxiagui.bashConsole:cecho(" <green>"..string.char(8))
    end
  end
end
