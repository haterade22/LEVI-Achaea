-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > ZulahGUI - Saonji Edit > Room Items > showRoomItems

function zgui.showRoomItems()
  clearWindow("roomItemsDisplay")
  if zgui.roomGetItemList then
    for k,v in pairs(zgui.roomGetItemList) do
      cecho("roomItemsDisplay", " <gold>"..zgui.roomGetItemList[k].."\n")
    end
  end  
  if zgui.roomItemList then
    for k,v in pairs(zgui.roomItemList) do
      cecho("roomItemsDisplay", " <grey>"..zgui.roomItemList[k].."\n")
    end
  end    
end

--new Items list on moving rooms
function zgui.updateroomitems()
  zgui.roomGetItemList = {}
  zgui.roomItemList = {}
  zgui.roomDenizenList = {}
  for k,v in pairs(gmcp.Char.Items.List.items) do
    if v.attrib == "m" then
      if not table.contains(zgui.roomDenizenList, v.id) then
        zgui.roomDenizenList[v.id] = v.name
      end
    elseif v.attrib == "t" then
      if not table.contains(zgui.roomGetItemList, v.id) then
        zgui.roomGetItemList[v.id] = v.name
      end   
    else
      if not table.contains(zgui.roomItemList, v.id) then
        zgui.roomItemList[v.id] = v.name
      end           
    end
  end -- for
  zgui.showRoomItems()
  
end

registerAnonymousEventHandler("gmcp.Char.Items.List", "zgui.updateroomitems")

--item added to room
function zgui.addroomitem()
  --check if item was added to room
  if gmcp.Char.Items.Add.location == "room" then
    --check if item is already in roomitems table
    if gmcp.Char.Items.Add.item.attrib == "m" then
      if not table.contains(zgui.roomDenizenList, gmcp.Char.Items.Add.item.id) then
        zgui.roomDenizenList[gmcp.Char.Items.Add.item.id] = gmcp.Char.Items.Add.item.name
      end
    elseif gmcp.Char.Items.Add.item.attrib == "t" then
      if not table.contains(zgui.roomGetItemList, gmcp.Char.Items.Add.item.id) then
        zgui.roomGetItemList[gmcp.Char.Items.Add.item.id] = gmcp.Char.Items.Add.item.name
      end   
    else
      if not table.contains(zgui.roomItemList, gmcp.Char.Items.Add.item.id) then
        zgui.roomItemList[gmcp.Char.Items.Add.item.id] = gmcp.Char.Items.Add.item.name
      end  
    end
  end
  zgui.showRoomItems()
  
end

--manually add item to room
function zgui.manualAddItem(id, name)
  if not table.contains(zgui.roomItemList, id) then
    zgui.roomItemList[id] = name
  end      
  zgui.showRoomItems()     
end

registerAnonymousEventHandler("gmcp.Char.Items.Add", "zgui.addroomitem")

--item removed from room
function zgui.removeroomitem()
  if gmcp.Char.Items.Remove.location == "room" then
    if table.contains(zgui.roomGetItemList, gmcp.Char.Items.Remove.item.id) then   
      zgui.roomGetItemList[gmcp.Char.Items.Remove.item.id] = nil
    elseif table.contains(zgui.roomDenizenList, gmcp.Char.Items.Remove.item.id) then   
      zgui.roomDenizenList[gmcp.Char.Items.Remove.item.id] = nil
    elseif table.contains(zgui.roomItemList, gmcp.Char.Items.Remove.item.id) then   
      zgui.roomItemList[gmcp.Char.Items.Remove.item.id] = nil
    end
  end
  zgui.showRoomItems()
 
end

--manually remove person leaving room from people_here
function zgui.manualRemoveItem(id)
  if table.contains(zgui.roomItemList, id) then
    zgui.roomItemList[id] = nil
  elseif table.contains(zgui.roomDenizenList, id) then   
    zgui.roomDenizenList[id] = nil
  elseif table.contains(zgui.roomItemList, id) then   
    zgui.roomItemList[id] = nil 
  end
  zgui.showRoomItems()
 
end

registerAnonymousEventHandler("gmcp.Char.Items.Remove", "zgui.removeroomitem")