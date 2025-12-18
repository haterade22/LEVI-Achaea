-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > Mapper > WildWalker > WildernessCoords

function WildernessCoords(...)
 local displayRoomsWithin = 100
 if gmcp.Room.Info.ohmap and gmcp.Room.Info.environment ~= "Vessel" then
    local posx,posy,chunkx,chunky,x,y = translateWilderness()
    cecho("Wilderness", "<gray>-----[ Wilderness Coords ]----")
    cecho("Wilderness", "\n<gray>-- <ansiLightBlack>Chunk: <ansiLightRed>"..chunk)
--    cehco("\n<ansiLightBlack>Cx:<ansiLightRed>" .. chunkx .. " <ansiLightBlack>Cy:<ansiLightRed>".. chunky)
--    cecho("\n<ansiLightBlack>X:<ansiLightRed>"..x .. "<ansiLightBlack> Y:<ansiLightRed>"..y)
    cecho("Wilderness", " : <ansiLightBlack>X:<ansiLightRed>".. posx .. "<ansiLightBlack> Y:<ansiLightRed>"..posy.." <gray>--".."\n")
    --cecho("\n<ansiGreen>------------------------")
    for k,v in pairsByKeys(wildernessExits) do
    local dir,dash = directionsTo(k)
    local color = "<ansiWhite>"
      if dir == "enter" then dir = "<ansiGreen>all around you!" else dir = "to the " .. dir end
      if k == wildernessWhere then color = "<ansiLightRed>" end
      if k == wildernessWhere or (math.abs(posx-v.x)<displayRoomsWithin  and 
                                  math.abs(posy-v.y)<displayRoomsWithin) then
        cecho("\n".. color.. v.name .. " is " .. dir .. "")
      end -- if
    end-- for
  end-- if
end-- func

function translateWilderness(num)
  local info = gmcp.Room.Info
  local num = num or info.num
  local posx,posy,chunkx,chunky,x,y
  if info.ohmap then
    --wilderness rooms always have 6 digits for x and y, but can have
    --1, 2, or theoretically 3 digits for their chunk number
    chunk,x,y = string.match(num, "(.?.?.)(...)(...)")
    --4 chunks per row, so let's change the chunk number into a chunk position instead
    chunkx = chunk%4
    chunky = math.ceil(chunk/4)
    --set an actual x/y grid position based on our chunk and our current x/y
    posx = (chunkx-1)*250 + x 
    posy = ((chunky-1)*250 + y)*-1 --invert our y so grid math works right,
                                   --because Achaea y pos is top to bottom
  end
  return posx, posy, chunkx, chunky, x*1, y*1
end

local firstSpace, secondSpace = 25,30 