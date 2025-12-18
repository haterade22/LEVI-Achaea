-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Aetolia > mmp.aetContinentCheck

local oldArea = oldArea or ""
function mmp.aetContinentCheck()
  if mmp.game ~= "aetolia" then return end
  
  if oldArea ~= gmcp.Room.Info.area then
    oldArea = gmcp.Room.Info.area
    enableTrigger("Aetolia Gag Survey")
    send("survey",false)
    tempTimer(5,function() disableTrigger("Aetolia Gag Survey") end)
  end
end