--[[mudlet
type: script
name: Achaea betterWings
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Wings and other fast travel
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--builds a table based on current orb settings, then returns a function which can be used to quickly check that table.

local function orbedBlackList()
  local bannedAreas = {}
  local areaTable = mmp.getAchaeaOrbTable()
  for org, areas in pairs(areaTable) do
    for _, area in pairs(areas) do
      bannedAreas[area] = mmp.settings["orb" .. org]
    end
  end
  return
    function(roomId)
      return not bannedAreas[getRoomArea(roomId)]
    end
end

--searches for closest room that meets requirements.
--does stuff to handle weighted rooms, locked rooms, special exits.

local function closestOutdoors(startRoom)
--visited is rooms which have already been found by the search.
  local visited = {[startRoom] = true}
  --checking is the rooms that it is currently checking to see if they meet the desired conditions.
  local checking = {[startRoom] = true}
  --nextCheck is a list of rooms which will be checked once the algorithm is finished with the rooms in checking.
  local nextCheck = {}
  --weightedRooms contains rooms with greater than 1 weight, so that they can be handled differently.
  local weightedRooms = {}
  local orbed = orbedBlackList()

  --functions for handling weighted rooms.
  local function addWeighted(room, weight)
    if not weightedRooms[room] or weight < weightedRooms[room] then
      weightedRooms[room] = weight
    end
  end

  --this function subtracts 1 from every room weight in the weighted room list.
  --if they hit zero then it will add them to the checking table and removes them from weightedRooms

  local function reduceWeights()
    --display(weightedRooms)
    local toDelete = {}
    for room, weight in pairs(weightedRooms) do
      weightedRooms[room] = weightedRooms[room] - 1
      if weightedRooms[room] <= 0 then
        if not visited[room] then
          checking[room] = true
          visited[room] = true
        end
        toDelete[room] = true
      end
    end
    --cleans up the weighted stuff.
    for room, _ in pairs(toDelete) do
      weightedRooms[room] = nil
    end
  end

  local stopwatch = createStopWatch()
  startStopWatch(stopwatch)
  --only willing to search for 500ms. Will abort in longer cases,
  while getStopWatchTime(stopwatch) < .5 do
    for room, val in pairs(checking) do
      --if these conditions are met, returns a roomid and exits out.
      --probably doesn't work great on weird planes, as when off plane, the room returned may not work for wings.
      if getRoomUserData(room, "outdoors") == "y" and orbed(room) then
        return room
      end
      local weights = getExitWeights(room)
      --loops through all exits in the room, doing stuff.
      for direction, destRoom in pairs(getRoomExits(room)) do
        if not mmp.hasExitLock(room, direction) and not visited[destRoom] then
          --if the exit+roomweight is higher than 1 (the default, for 1 room weight + 0 exit weight), then do a room weight subroutine
          if
            (((weights[direction] or 0) + getRoomWeight(destRoom)) > 1) and not roomLocked(destRoom)
          then
            addWeighted(destRoom, (weights[direction] or 0) + getRoomWeight(destRoom))
          else
            --add it to visited, so it doesn't double back on it in the future.
            visited[destRoom] = true
            --if it's not locked, add it to nextCheck, which are the rooms that it searches through next cycle.
            --if it is locked, just ignore it.
            if not roomLocked(destRoom) then
              nextCheck[destRoom] = true
            end
          end
        end
      end
      --same as above loop, but for specialExits
      for destRoom, specialExits in pairs(getSpecialExits(room)) do
        for specialExit, locked in pairs(specialExits) do
          if locked == "0" and not visited[destRoom] then
            if
              (((weights[direction] or 0) + getRoomWeight(destRoom)) > 1) and
              not roomLocked(destRoom)
            then
              addWeighted(destRoom, (weights[direction] or 0) + getRoomWeight(destRoom))
            else
              visited[destRoom] = true
            end
            if not roomLocked(destRoom) then
              nextCheck[destRoom] = true
            end
          end
        end
      end
    end
    --replaces checking with the next set of rooms to check, and clears nextCheck.
    checking, nextCheck = nextCheck, {}
    reduceWeights()
    --if no rooms on checking and weightedRooms, exits out.
    --If no rooms in checking but there are rooms in weightedRooms, it will iterate down the weights until something is in checking.
    if not next(checking) then
      if next(weightedRooms) then
        while next(weightedRooms) and not next(checking) do
          reduceWeights()
        end
      else
        return
      end
    end
  end
end

--does the actual linking and stuff. Mostly copied over from the main wings script.
--however, half of the checks have been removed because they were already done in the process
--of searching for a valid outdoors room.

local function linkWingsRemote(room)
  local function getcmd(word)
    return
      mmp.settings.removewings and
      string.format(
        [[script:sendAll("wear wings", "say *%s %s", "remove wings", false)]],
        (mmp.settings.winglanguage and mmp.settings.winglanguage or ""),
        word
      ) or
      string.format(
        [[script:send("say *%s %s", false)]],
        (mmp.settings.winglanguage and mmp.settings.winglanguage or ""),
        word
      )
  end

  --decided to pull this out and set it as a local variable instead of calling it 20x throughout the script.
  local area = getRoomArea(room)
  --sarapis wings
  if (mmp.settings.duanathar or mmp.settings.duanatharan or mmp.settings.duantahar) then
    if mmp.oncontinent(area, "Main") then
      if mmp.settings.duanatharan then
        mmp.tempSpecialExit(room, 4882, getcmd("duanatharan"))
        mmp.tempSpecialExit(room, 3885, getcmd("duanathar"))
      elseif mmp.settings.duantahar then
        mmp.tempSpecialExit(room, 42319, getcmd("duanathar"))
        mmp.tempSpecialExit(room, 4882, getcmd("duanatharan"))
      else
        mmp.tempSpecialExit(room, 3885, getcmd("duanathar"))
      end
      --Meropis Wings
    elseif mmp.oncontinent(area, "Meropis") then
      if mmp.settings.duanatharan then
        mmp.tempSpecialExit(room, 51603, getcmd("duanatharan"))
        mmp.tempSpecialExit(room, 51188, getcmd("duanathar"))
      elseif mmp.settings.duantahar then
        mmp.tempSpecialExit(room, 42319, getcmd("duanathar"))
        mmp.tempSpecialExit(room, 51603, getcmd("duanatharan"))
      else
        mmp.tempSpecialExit(room, 51188, getcmd("duanathar"))
      end
    end
  end
  --island wings
  if
    mmp.settings.duanatharic and
    (
      mmp.oncontinent(area, "Main") or
      mmp.oncontinent(area, "Arcadia") or
      mmp.oncontinent(area, "Outer") or
      mmp.oncontinent(area, "Meropis") or
      mmp.oncontinent(area, "Island") or
      mmp.oncontinent(area, "North")
    )
  then
    mmp.tempSpecialExit(room, 47571, getcmd("duanatharic"))
  end
  if mmp.settings.harness then
    -- eastern isles
    if mmp.oncontinent(area, "Eastern_Isles") then
      mmp.tempSpecialExit(room, 54231, "Shake Harness")
      -- northern isles
    elseif mmp.oncontinent(area, "Northen_Isles") then
      mmp.tempSpecialExit(room, 48719, "Shake Harness")
      -- western isles
    elseif mmp.oncontinent(area, "Western_Isles") then
      mmp.tempSpecialExit(room, 54632, "Shake Harness")
    end
  end
  if mmp.settings.soar then
    --Sarapis soar.
    if mmp.oncontinent(area, "Main") then
      if
        gmcp.Char.Status.class == "air Elemental Lord" or
        gmcp.Char.Status.class == "air Elemental Lady"
      then
        mmp.tempSpecialExit(room, 4882, "aero soar high", 10)
        -- duanatharan
        mmp.tempSpecialExit(room, 3885, "aero soar low", 10)
        -- duanathar
        mmp.tempSpecialExit(room, 54173, "aero soar stratosphere", 10)
        -- Stratosphere!
      end
      --Meropis soar
    elseif mmp.oncontinent(area, "Meropis") then
      if
        gmcp.Char.Status.class == "air Elemental Lord" or
        gmcp.Char.Status.class == "air Elemental Lady"
      then
        mmp.tempSpecialExit(room, 51603, "aero soar high", 10)
        -- duanatharan
        mmp.tempSpecialExit(room, 51188, "aero soar low", 10)
        -- duanathar
        mmp.tempSpecialExit(room, 54173, "aero soar stratosphere", 10)
        -- Stratosphere!
      end
    end
  end
  mmp.clearpathcache()
end

--is called when you do pathfinding.

function mmp.achaeaBetterWings()
  --if you're not on achaea, or the crowdmap is not enabled, or the room you're in is flagged as outdoors, exit out.
  if
    (mmp.game ~= "achaea") or
    (not mmp.settings.betterwings) or
    (not mmp.settings.crowdmap) or
    (getRoomUserData(mmp.currentroom, "outdoors") == "y" and orbedBlackList()(mmp.currentroom))
  then
    return
  end
  --if none of the shortcut items are enabled, return.
  if
    not (
      mmp.settings.duanathar or
      mmp.settings.duantahar or
      mmp.settings.duanatharan or
      mmp.settings.soar or
      mmp.settings.harness or
      mmp.settings.duanatharic
    )
  then
    return
  end
  --find closest room, if that function returned something useful, call above function to create temporary remote special exits depending on settings.
  local closestRoom = closestOutdoors(mmp.currentroom)
  if closestRoom then
    if mmp.debug then
      mmp.echo("Closest outdoors room found at "..closestRoom)
    end
    linkWingsRemote(closestRoom)
  end
end

registerAnonymousEventHandler("mmp link externals", "mmp.achaeaBetterWings")