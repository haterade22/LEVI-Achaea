if target == matches[2] then
selectCurrentLine() fg("red")
  if tAffs.burns == 0 then 
     tAffs.burns = 1
  elseif tAffs.burns == 1 then
    tAffs.burns = 2
  elseif tAffs.burns == 2 then
    tAffs.burns = 3
  elseif tAffs.burns == 3 then
    tAffs.burns = 4
  elseif tAffs.burns == 4 then
    tAffs.burns = 5
  elseif tAffs.burns == 5 then
    tAffs.burn = 5
  end
  if tburns == 0 or nil then
     tburns = 1
  elseif tburns == 1 then
    tburns = 2
  elseif tburns == 2 then
    tburns = 3
  elseif tburns == 3 then
    tburns = 4
  elseif tburns == 4 then
    tburns = 5
  elseif tburns == 5 then
    tAffs.burn = 5
  end
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end

if not magi.firestorm then
  magi.firestorm = gmcp.Room.Info.num
end

magi.firestormm = true

tarAffed("firestorm")