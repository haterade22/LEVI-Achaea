if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Burning (ablaze)") end
  if tburns == 0 or nil then
     tburns = 2
  elseif tburns == 1 then
    tburns = 3
  elseif tburns == 2 then
    tburns = 4
  elseif tburns == 3 then
    tburns = 5
  elseif tburns == 4 then
    tburns = 5
  elseif tburns == 5 then
	tburns= 5
  end
cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")