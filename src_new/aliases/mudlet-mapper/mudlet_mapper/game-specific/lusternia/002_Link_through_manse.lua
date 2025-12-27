--[[mudlet
type: alias
name: Link through manse
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Game-specific
- Lusternia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: (?i)^manselink (\w+) (\w+)$
command: ''
packageName: ''
]]--

local portalRooms = {
gaudiguch="19861",
glomdoring="7747",
celest="6834",
serenwilde="6833",
hallifax="19937",
magnagora="6832",
aetherplex="6831",
}

if mmp.game ~= "lusternia" then return end
matches[2]=matches[2]:lower()
matches[3]=matches[3]:lower()
local manse, city
if portalRooms[matches[2]] then
	city=matches[2]
	manse=matches[3]
elseif portalRooms[matches[3]] then
	city=matches[3]
	manse=matches[2]
else
	mmp.echo("Invalid city")
	return
end
if not gmcp.Room.Info.area:find("(manse)") then
	mmp.echo("You are not in a manse")
else
	if	searchRoom(gmcp.Room.Info.num):sub(0,11)=="searchRoom:" then
		addRoom(gmcp.Room.Info.num)
	end
	if getRoomArea(gmcp.Room.Info.num)==-1 then
		setRoomArea(gmcp.Room.Info.num,addAreaName(manse:title().." Manse"))
	end
	setRoomChar(gmcp.Room.Info.num,"A")
	addSpecialExit(portalRooms[city],gmcp.Room.Info.num,"Portal enter "..manse)
	addSpecialExit(portalRooms["aetherplex"],gmcp.Room.Info.num,"Portal enter "..manse)
	addSpecialExit(gmcp.Room.Info.num,portalRooms["aetherplex"],"portal exit aetherplex")
	addSpecialExit(gmcp.Room.Info.num,portalRooms[city],"portal exit "..city)
	mmp.echo(city:title().." has been linked to the Aetherplex through "..manse:title())
end