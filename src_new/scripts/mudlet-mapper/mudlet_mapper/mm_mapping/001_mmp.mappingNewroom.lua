--[[mudlet
type: script
name: mmp.mappingNewroom
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- gmcp.Room.Info
- RoomNum
]]--

--mmp.mappingNewroom

local function makeroom(oldid, newid, x, y, z)
  assert(oldid, "makeroom: need the ID of the original room")
  assert(newid, "makeroom: need the ID of the room to create")
  assert(x and y and z, "makeroom: need all 3 coordinates")
  addRoom(newid)
  setRoomCoordinates(newid, x, y, z)
  setRoomArea(newid, getRoomArea(oldid))
  -- in case we are in a hash-based game and the room ID already got created to store a hash, clear the flag
  clearRoomUserDataItem(newid, "hashonly")
  local fgr, fgg, fgb = unpack(color_table.red)
  local bgr, bgg, bgb = unpack(color_table.blue)
  highlightRoom(newid, fgr, fgg, fgb, bgr, bgg, bgb, 1, 100, 100)
  if mmp.envids[gmcp.Room.Info.environment] then
    setRoomEnv(newid, mmp.envids[gmcp.Room.Info.environment])
  else
    setRoomEnv(newid, getRoomEnv(oldid))
  end
  return string.format("Created new room %d at %dx,%dy,%dz.", newid, x, y, z)
end

-- gives the reverse shifted coordinates, ie asking for the sw exit + coords will give the coords at ne

local function getshiftedcoords(original, ox, oy, oz)
  local x, y, z
  local has = table.contains
  -- reverse the exit
  w = mmp.ranytolong(original)
  if has({"west", "left", "w", "l"}, w) then
    x = (x or ox) - 1
    y = (y or oy)
    z = (z or oz)
  elseif has({"east", "right", "e", "r"}, w) then
    x = (x or ox) + 1
    y = (y or oy)
    z = (z or oz)
  elseif has({"north", "top", "n", "t"}, w) then
    x = (x or ox)
    y = (y or oy) + 1
    z = (z or oz)
  elseif has({"south", "bottom", "s", "b"}, w) then
    x = (x or ox)
    y = (y or oy) - 1
    z = (z or oz)
  elseif has({"northwest", "topleft", "nw", "tl"}, w) then
    x = (x or ox) - 1
    y = (y or oy) + 1
    z = (z or oz)
  elseif has({"northeast", "topright", "ne", "tr"}, w) then
    x = (x or ox) + 1
    y = (y or oy) + 1
    z = (z or oz)
  elseif has({"southeast", "bottomright", "se", "br"}, w) then
    x = (x or ox) + 1
    y = (y or oy) - 1
    z = (z or oz)
  elseif has({"southwest", "bottomleft", "sw", "bl"}, w) then
    x = (x or ox) - 1
    y = (y or oy) - 1
    z = (z or oz)
  elseif has({"up", "u"}, w) then
    x = (x or ox)
    y = (y or oy)
    z = (z or oz) + 1
  elseif has({"down", "d"}, w) then
    x = (x or ox)
    y = (y or oy)
    z = (z or oz) - 1
  elseif has({"in", "i"}, w) then
    x = (x or ox)
    y = (y or oy)
    z = (z or oz) - 1
  elseif has({"out", "o"}, w) then
    x = (x or ox)
    y = (y or oy)
    z = (z or oz) + 1
  else
    mmp.echo(
      "Don't know where to shift the coordinates for a " ..
      tostring(w) ..
      " (" ..
      tostring(original) ..
      ") exit."
    )
  end
  return x, y, z
end

-- returns a room ID for a given hash
-- if a room doesn't exist, it'll create it in order to bind the hash to a certain createRoomID
-- at the same time, it'll mark the userdata "hashonly" as "true" so mmp.roomExists won't say this room exists
-- this preserves the same logic in the code as non-hash games
function mmp.roomidFromHash(hash)
  local id = getRoomIDbyHash(hash)
  if id == -1 then 
    id = createRoomID()
    addRoom(id)
    setRoomIDbyHash(id, hash)
    setRoomUserData(id, "hashonly", "true")
  end
  
  return id
end

function mmp.mappingNewroom(_, num)
  local s, m =
    xpcall(
      function()
        if not mmp.editing then
          return
        end
        if not gmcp.Room then
          mmp.echo(
            "You need to have GMCP turned on (see preferences on a recent Mudlet) for mapping stuff."
          )
          return
        end
        -- wilderness mapping right now is UNFINISHED! It does not handle the grid breakup. So, please don't try it, and please won't whine about it.

        local function inwilderness()
          return (gmcp.Room.Info.coords == "" and gmcp.Room.Info.area == "")
        end

        local getRoomName, getRoomCoordinates, getRoomsByPosition =
          getRoomName, getRoomCoordinates, getRoomsByPosition
        local num = tonumber(num) or tonumber(gmcp.Room.Info.num)
        if not num and gmcp.Room.Info.roomhash then
          num = mmp.roomidFromHash(gmcp.Room.Info.roomhash)
        end
        local currentexits = gmcp.Room.Info.exits
        local s = ""
        if not mmp.roomexists(num) then
          -- see if we can create and link this room with an existing one
          -- wilderness and non-wilderness rooms require different methods of calculating relative coordinates
          if not inwilderness() then
            for exit, id in pairs(currentexits) do
              if gmcp.Room.Info.roomhash then
                -- in a hash-based game, the 'id' is actually a hash, not an id
                -- turn it into a proper id:
                id = mmp.roomidFromHash(id)
              end
              
              if mmp.roomexists(id) then
                s = makeroom(id, num, getshiftedcoords(exit, getRoomCoordinates(id)))
              end
            end
          else
            local x, y = tostring(num):match(".-(%d%d%d)(%d%d%d)$")
            -- Achaea's coordinates seem to be in the 4th quadrant, while Mudlets 0,0 is in the middle of the map. Invert y so going north-south looks alright
            s = makeroom(mmp.previousroom, num, x, y * -1, 0)
          end
        end
        -- if we created it, and some data could be filled in
        if mmp.roomexists(num) then
          -- cleanup the room name
          local rootroomname = mmp.cleanroomname(gmcp.Room.Info.name)
          -- match exact case, so mappers alertness' works properly
          if getRoomName(num) ~= rootroomname then
            setRoomName(num, rootroomname)
            unHighlightRoom(num)
            s = s .. (#s > 0 and " " or "") .. "Updated room name to '" .. rootroomname .. "'."
          end
          -- autolink exits
          if not inwilderness() then
            local x = getRoomExits(num) or {}
            -- check for missing exits
            for exit, id in pairs(currentexits) do
              if gmcp.Room.Info.roomhash then
                -- in a hash-based game, the 'id' is actually a hash, not an id
                -- turn it into a proper id:
                id = mmp.roomidFromHash(id)
              end
              
              if id == 0 then
                s =
                  s ..
                  (#s > 0 and " " or "") ..
                  "Can't link to the " ..
                  exit ..
                  ", it leads to a room with ID 0 (and that's not supported yet)."
              else
                if not x[mmp.anytolong(exit)] then
                  if not mmp.roomexists(id) then
                    s =
                      makeroom(
                        num, id, getshiftedcoords(mmp.ranytolong(exit), getRoomCoordinates(num))
                      )
                  end
                  if mmp.setExit(num, id, exit) then
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      "Added missing exit " ..
                      exit ..
                      " to " ..
                      (getRoomName(id) ~= "" and getRoomName(id) or "''") ..
                      " (" ..
                      id ..
                      ")."
                  else
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      string.format(
                        "Failed to link %d with %d via %s exit for some reason :/", num, id, exit
                      )
                  end
                end
              end
            end
          else
            local function getshiftedcoords(direction, ox, oy, oz)
              if direction == 'n' or direction == 'north' then
                return ox, oy + 1, oz
              elseif direction == 'e' or direction == 'east' then
                return ox + 1, oy, oz  
              elseif direction == 's' or direction == 'south' then
                return ox, oy - 1, oz
              elseif direction == 'w' or direction == 'west' then
                return ox - 1, oy, oz
              elseif direction == 'ne' or direction == 'northeast' then
                return ox + 1, oy + 1, oz
              elseif direction == 'se' or direction == 'southeast' then
                return ox + 1, oy - 1, oz
              elseif direction == 'sw' or direction == 'southwest' then
                return ox - 1, oy - 1, oz
              elseif direction == 'nw' or direction == 'northwest' then
                return ox - 1, oy + 1, oz
              else
                error("getshiftedcoords: direction " .. direction .. " isn't supported yet.")
              end
            end

            local x, y, z = getRoomCoordinates(num)
            local currentexits = getRoomExits(num) or {}
            for _, exit in ipairs({'n', 'e', 's', 'w', 'ne', 'se', 'sw', 'nw'}) do
              local roomatdir =
                getRoomsByPosition(getRoomArea(num), getshiftedcoords(exit, x, y, z))
              if roomatdir[0] then
                local id = roomatdir[0]
                if not currentexits[mmp.anytolong(exit)] then
                  if mmp.setExit(num, id, exit) then
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      "Added missing exit " ..
                      exit ..
                      " to " ..
                      (getRoomName(id) ~= "" and getRoomName(id) or "''") ..
                      " (" ..
                      id ..
                      ")."
                  else
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      string.format(
                        "Failed to link %d with %d via %s exit for some reason :/", num, id, exit
                      )
                  end
                  local exit = mmp.anytoshort(mmp.ranytolong(exit))
                  if mmp.setExit(id, num, exit) then
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      "Added missing exit " ..
                      exit ..
                      " to " ..
                      (getRoomName(id) ~= "" and getRoomName(id) or "''") ..
                      " (" ..
                      id ..
                      ")."
                  else
                    s =
                      s ..
                      (#s > 0 and " " or "") ..
                      string.format(
                        "Failed to link %d with %d via %s exit for some reason :/", num, id, exit
                      )
                  end
                end
              end
            end
          end
          -- check for unexisting exits
          if mmp.settings["autoclear"] then
            for exit, id in pairs(getRoomExits(num)) do
              if not currentexits[mmp.anytoshort(exit)] then
                mmp.setExit(num, -1, exit)
                s =
                  s ..
                  (#s > 0 and " " or "") ..
                  exit ..
                  " exit to " ..
                  id ..
                  " doesn't actually exist, removed it."
              end
            end
          end
          -- check for environment update, if we have environments mapped out
          if
            mmp.envids[gmcp.Room.Info.environment] and
            mmp.envids[gmcp.Room.Info.environment] ~= getRoomEnv(num)
          then
            setRoomEnv(num, mmp.envids[gmcp.Room.Info.environment])
            s =
              s ..
              (#s > 0 and " " or "") ..
              "Updated environment name to " ..
              gmcp.Room.Info.environment ..
              "."
          end
          -- check indoors status
          if mmp.game ~= "asteria" or mmp.game ~= "ashyria" then
            local indoors = table.contains(gmcp.Room.Info.details, "indoors")
            if indoors and (getRoomUserData(num, "indoors") == '' or getRoomUserData(num,"outdoors") ~= '') then
            setRoomUserData(num, "indoors", "y")
            clearRoomUserDataItem(num, "outdoors")
            s = s .. (#s > 0 and " " or "") .. "Updated room to be indoors."
          elseif not indoors and (getRoomUserData(num, "indoors") ~= '' or getRoomUserData(num, "outdoors") == '') then
            clearRoomUserDataItem(num, "indoors")
            setRoomUserData(num, "outdoors", "y")
            s = s .. (#s > 0 and " " or "") .. "Updated room to be outdoors."
          end
        end

          -- check server area name (Achaea only for now)
          if mmp.game == "achaea" then
            local serverArea = gmcp.Room.Info.area
            if serverArea ~= getRoomUserData(num, "Game Area") then
              setRoomUserData(num, "Game Area", serverArea)
              s = s .. (#s > 0 and " " or "") .. "Updated game area to " .. serverArea .. "."
            end
          end
          -- check for wilderness exits
          if getRoomChar(num) ~= "W" and table.contains(gmcp.Room.Info.details, "wilderness") then
            setRoomChar(num, "W")
            s = s .. (#s > 0 and " " or "") .. "Added the wilderness mark."
          end
        end
        if #s > 0 then
          mmp.echo(s)
          centerview(mmp.currentroom)
        end
      end,
      function(error)
        mmp.echo("Oops! Had a small problem (" .. error .. ").")
        echo("  ")
        echoLink(
          "view steps",
          'echo[[' .. debug.traceback() .. ']]',
          "View steps of code that led up to it"
        )
      end
    )
  if not s then
    mmp.echo(m)
  end
end