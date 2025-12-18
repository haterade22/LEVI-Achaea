-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Lusternia > Transverse and pathfind

local planes =
  {
    ["the Prime Material Plane"] = "prime",
    ["the Ethereal Plane"] = "ethereal",
    ["the Water Elemental Plane"] = "elemental",
    ["the Earth Elemental Plane"] = "elemental",
    ["the Air Elemental Plane"] = "elemental",
    ["the Fire Elemental Plane"] = "elemental",
    ["Celestia, Plane of Light"] = "cosmic",
    ["the Cosmic Plane of Vortex"] = "cosmic",
    ["the Cosmic Plane of Continuum"] = "cosmic",
    ["the Tainted Plane of Nil"] = "cosmic",
    ["the Astral Plane"] = "astral",
  }

function mmp.transverse(_, command)
  command = command:lower()
  if command:sub(0, 11) == "transverse " or command == "pathfind" then
    transverseCMD = command
    transversedFrom = gmcp.Room.Info.num
    lastPlane = planes[gmcp.Room.Info.details[1]]
    validTransverse = true
  end
end

registerAnonymousEventHandler("sysDataSendRequest", "mmp.transverse")

function mmp.registerTransverseExit()
  if transversedFrom ~= gmcp.Room.Info.num then
    addSpecialExit(transversedFrom, gmcp.Room.Info.num, transverseCMD)
    setExitWeight(transversedFrom, transverseCMD, 20)
    if lastPlane then
      addSpecialExit(gmcp.Room.Info.num, transversedFrom, "transverse " .. lastPlane)
      setExitWeight(gmcp.Room.Info.num, "transverse " .. lastPlane, 20)
    end
    validTransverse = false
  end
end

function mmp.clearTransverse()
  local otherSide = 0
  for room, command in pairs(getSpecialExits(gmcp.Room.Info.num)) do
    if next(command) == transverseCMD then
      otherSide = room
    end
  end
  for room, command in pairs(getSpecialExits(otherSide) or {}) do
    if room == gmcp.Room.Info.num and string.sub(next(command), 0, 11) == "transverse " then
      removeSpecialExit(otherSide, next(command))
    end
  end
  removeSpecialExit(gmcp.Room.Info.num, transverseCMD)
  if mmp.autowalking then
    mmp.autowalking = false
    mmp.gotoRoom(string.split(next(mmp.showpathcache()), "_")[2])
  end
end

function mmp.registerPathfind()
  addSpecialExit(transversedFrom, gmcp.Room.Info.num, "pathfind")
  setExitWeight(transversedFrom, "pathfind", 15)
  addSpecialExit(gmcp.Room.Info.num, transversedFrom, "pathfind")
  setExitWeight(gmcp.Room.Info.num, "pathfind", 15)
  validTransverse = false
end

function mmp.clearPathfind()
  local otherSide = 0
  for room, command in pairs(getSpecialExits(gmcp.Room.Info.num)) do
    if next(command) == "pathfind" then
      otherSide = room
    end
  end
  for room, command in pairs(getSpecialExits(otherSide) or {}) do
    if room == gmcp.Room.Info.num and next(command) == "pathfind" then
      removeSpecialExit(otherSide, next(command))
    end
  end
  removeSpecialExit(gmcp.Room.Info.num, "pathfind")
  if mmp.autowalking then
    mmp.autowalking = false
    mmp.gotoRoom(string.split(next(mmp.showpathcache()), "_")[2])
  end
end

function mmp.lockpaths(lock)
  local count = 0
  for area, areaname in pairs(mmp.areatabler) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)
      for room, command in pairs(exits or {}) do
        if next(command) == "pathfind" then
          count = count + 1
          lockSpecialExit(rooms[i], room, "pathfind", lock)
        end
      end
    end
  end
  mmp.echo((lock and "Locked " or "Unlocked ") .. count .. " pathfinding exits.")
end