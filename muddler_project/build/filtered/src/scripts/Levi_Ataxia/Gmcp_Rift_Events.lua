function outRift_addedItem()
  if gmcp.Char.Items.Add.location == "inv" then
		ataxiaTemp.ignoreOutrift = tempTimer(2, [[ataxiaTemp.ignoreOutrift = nil]])
    local herbName = returnHerbName(gmcp.Char.Items.Add.item.name)
		
    if herbName then
      local herbAmount = extractNumberFromString(gmcp.Char.Items.Add.item.name) or 1

      ataxiaTemp.outrifted[herbName] = ataxiaTemp.outrifted[herbName] + herbAmount
      ataxiaTemp.addedHerbID = tonumber(gmcp.Char.Items.Add.item.id)
      
      if ataxiaTemp.outriftTimer then killTimer(ataxiaTemp.outriftTimer) end
      ataxiaTemp.outriftTimer = tempTimer(2, [[ataxiaTemp.outriftTimer = nil]])
    end
  end
end
registerAnonymousEventHandler("gmcp.Char.Items.Add", "outRift_addedItem")

function outRift_removedItem()
  if gmcp.Char.Items.Remove.location == "inv" then
		ataxiaTemp.ignoreOutrift = tempTimer(2, [[ataxiaTemp.ignoreOutrift = nil]])
    local herbName = returnHerbName(gmcp.Char.Items.Remove.item.name)
    
    if herbName then
      local herbAmount = extractNumberFromString(gmcp.Char.Items.Remove.item.name) or 1
      ataxiaTemp.outrifted[herbName] = ataxiaTemp.outrifted[herbName] - herbAmount
      ataxiaTemp.removedHerbID = tonumber(gmcp.Char.Items.Remove.item.id)

      if ataxiaTemp.removedHerbID == ataxiaTemp.addedHerbID then
        ataxiaTemp.outrifted[herbName] = ataxiaTemp.outrifted[herbName] - 1
        ataxiaTemp.addedHerbID = 1
      end
			
      if ataxiaTemp.outrifted[herbName] < 0 then
       ataxiaTemp.outrifted[herbName] = 0
      end
      if not ataxiaTemp.outriftTimer then ataxia_precacheQueue() end
    end
  end
end

registerAnonymousEventHandler("gmcp.Char.Items.Remove", "outRift_removedItem")