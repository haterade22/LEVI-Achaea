if matches[2] then
  local showThis = matches[2]
  if zgui[matches[2]] and zgui[matches[2]].adjustable then
    zgui[matches[2]].adjustable = Adjustable.Container:new({name="zgui."..matches[2]..".adjustable", autoLoad=false})
    cecho("\n<purple> -NEW ADJUSTABLE CREATED:\n")
    cecho("\n<purple> -<red>\[zgui."..showThis..".adjustable\]\n")    
  elseif zgui[matches[2]] and zgui[matches[2]].window then
    zgui[matches[2]].window = Adjustable.Container:new({name="zgui."..matches[2]..".window", autoLoad=false})    
    cecho("\n<purple> -NEW WINDOW CREATED:\n")
    cecho("\n<purple> -<red>\[zgui."..showThis..".window\]\n")        
  else
    cecho("\n<purple> -No Version of Either:\n")
    cecho("\n<purple> -<white>\[zgui.<red>"..showThis.."<white>.adjustable\]\n")
    cecho("\n<purple> -<white>\[zgui.<red>"..showThis.."<white>.window\]\n")
  end
else
  cecho("\n<purple> --------------------------------------------------------")
  cecho("\n<purple> -To type: <white>\n")
  for k,v in pairs(zgui) do
    if type(zgui[k]) == "table" then
      if  zgui[k].window then
        cecho("\n<purple> -<white>\[zgui.<red>"..k.."<white>.window\]")
      end
      if  zgui[k].adjustable then
        cecho("\n<purple> -<white>\[zgui.<red>"..k.."<white>.adjustable\]")
      end      
    end
  end
  cecho("\n\n<purple> -To Fix a Window Type:")
  cecho("\n<white>    zfix map")
  cecho("\n<white>    zfix logger")
  cecho("\n<white>    zfix targetaffliction")  
  cecho("\n<purple> --------------------------------------------------------\n")
end