function travelTo(where,dash) -- Tries to get where we are going. Does a decent job.
  local dash = dash or ""
  local dir, num = directionsTo(where:lower())
  if dir == false then
    return false
  elseif dir == "enter" then
    send("enter",false)
  end
  num = num or ""
  dir = closestDir(dir)
  send(dash .. " " .. dir .. " " .. num,false)
end

function closestDir(dir) -- gives us the closest dir in case of impassable exits
  local rexits = gmcp.Room.Info.exits
  if (rexits[translateDir[dir]] or dir == "enter") then return dir end
  local dir = translateDir[dir]
  local compass = {"n","ne","e","se","s","sw","w","nw"}
  local translateDir = {
    north = "n", northeast = "ne", east = "e", southeast = "se", 
    south = "s", southwest = "sw", west = "w", northwest = "nw" } 
  local untranslateDir = { 
    nw = "northwest", w = "west", se = "southeast", s = "south",
    sw = "southwest", ne = "northeast", e = "east", n = "north" }
  local exit
  --populate possible exits
  local want = table.index_of(compass,dir)
  
  for i = 1,4 do
    local ccw, cw = 0,0
    --these circle past the respective ends to the next exit on the circle
    if want-i < 1 then
      ccw = 8
    end
    if want+i > 8 then
      cw = 8
    end
    -- check if the exit exists, use it if it does
    exit = rexits[compass[want-i+ccw]] and compass[want-i+ccw]
    if exit then break end
    exit = rexits[compass[want+i-cw]] and compass[want+i-cw]
    if exit then break end 
  end
  
  return untranslateDir[exit]
  
end

function directionsTo(where)
  local going
  if wildernessExits[where] then
    going = wildernessExits[where]
  else
    echo("Don't know how to get there\n")
    return false
  end
  local x,y = translateWilderness()
  local riseDist,runDist
  riseDist = going.y-y
  runDist = going.x-x
  local rise,run = riserun(riseDist,runDist)
  riseDist = math.abs(riseDist)
  runDist = math.abs(runDist)
  currentHead = math.max(riseDist,runDist)
  local directionToGo = ""
  --More precise directional code
  if rise == 0 then
      if run > 0 then -- directly east or west of us (or at us)
        directionToGo = "east"
      elseif run < 0 then
        directionToGo = "west"
	  else
	    return "enter"
      end
  elseif run == 0 then
      if rise > 0 then --directly north or south of us
        directionToGo = "north"
      elseif rise < 0 then
        directionToGo = "south"
	else
	  cecho("<red>UNTRAPPED DIRECTION run 0")
      end
  -- if it's negative, it's southeast or northwest
  elseif rise/run < -2 then -- at an angle, but a steep one
    if rise < 0 then
      directionToGo = "south" -- south-southeast
    elseif run < 0 then
      directionToGo = "north" -- north-northwest
	else
	  cecho("<red>UNTRAPPED DIRECTION < -2")
    end
  elseif rise/run < -0.5 then -- at a normal angle
    if rise < 0 then
      directionToGo = "southeast"
    elseif run < 0 then
      directionToGo = "northwest"
	else
	  cecho("<red>UNTRAPPED DIRECTION < -0.5")
    end
  elseif rise/run < 0 then -- at an angle, but a shallow one
      if rise < 0 then
      directionToGo = "east" -- east-southeast
    elseif run < 0 then
      directionToGo = "west" -- west-northwest
	else
	  cecho("<red>UNTRAPPED DIRECTION < 0")
    end
  -- if it's positive, it's southwest or northeast
  elseif rise/run > 2 then -- steep angle
    if rise < 0 then
      directionToGo = "south" -- south-southwest
    elseif rise > 0 then
      directionToGo = "north" -- north-northeast
	else
	  cecho("<red>UNTRAPPED DIRECTION > 2")
    end  
  elseif rise/run > 0.5 then -- normal angle
    if rise < 0 then
      directionToGo = "southwest"
    elseif rise > 0 then
      directionToGo = "northeast"
	else
	  cecho("<red>UNTRAPPED DIRECTION > 0.5")
    end  
  elseif rise/run > 0 then -- shallow angle
    if rise < 0 then
      directionToGo = "west" -- west-southwest
    elseif rise > 0 then
      directionToGo = "east" -- east-northeast
	else
	  cecho("<red>UNTRAPPED DIRECTION > 0")
    end  
  else
    cecho("<red>UNTRAPPED DIRECTION")
  end
  --[[ old directional code
  --north south
  if y < going.y then
    directionToGo = directionToGo .. "north"
  elseif y > going.y then
    directionToGo = directionToGo .. "south"
  end
  --east west
  if x > going.x then
    directionToGo = directionToGo .. "west"
  elseif x < going.x then
    directionToGo = directionToGo .. "east"
  end  --]]
  return directionToGo, currentHead
end
