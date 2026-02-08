if isTargeted(matches[2]) then
  if tAffs.burns == 0 or tAffs.burns == nil then 
     tAffs.burns = 1
  else
    tAffs.burns = tAffs.burns + 1
  end


  if tburns == 0 or nil then
     tburns = 1
  else
    tburns = tburns + 1
  end
timmolation = false
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
end
