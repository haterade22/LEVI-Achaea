--[[mudlet
type: trigger
name: Already Harvested
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
- pattern: You have already harvested
  type: 2
- pattern: That plant has been fully harvested.
  type: 3
- pattern: An outraged squeal is all you hear before a dropbear
  type: 2
- pattern: What do you wish to harvest?
  type: 3
]]--

if not autoHarvesting then return end
	if harvest_in_room[1] then
		local xxx = harvest_in_room[1]
		deleteFull()
		
		bashConsoleEchom("HERB", "Already done "..harvest_in_room[1]..".", "DimGrey", "DarkSlateBlue")
		
		if #harvest_in_room > 0 and table.contains(harvest_in_room, xxx) then
			table.remove(harvest_in_room, table.index_of(harvest_in_room, xxx))
		end
	end
	if #harvest_in_room == 0 and canBals() then
    
    if ataxiaExtraction[gmcp.Room.Info.area] then
      send("queue addclear free extract "..ataxiaExtraction[gmcp.Room.Info.area],false)
    end
		if ataxiaHarvester_manual_harvesting then
      if zgui then
        cecho("bashDisplay", " <green>"..string.char(8))
      else
        ataxiagui.bashConsole:cecho(" <green>"..string.char(8))
      end
		else
			ataxiaHarvester_check()
		end
	end