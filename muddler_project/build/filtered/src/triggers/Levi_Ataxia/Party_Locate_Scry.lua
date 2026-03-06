-- multimatches[2][2] = name scried
-- multimatches[3][2] = area
-- multimatches[3][3] = location
if locateon == true then
  local roomName = multimatches[3][3]
  local areaName = multimatches[3][2]
  local t = mmp.searchRoomExact(roomName)
  if areaName then
    t = mmp.filterRooms(t, areaName)
  end
  local roomId = ""
  if next(t) then
    local k, v = next(t)
    roomId = " (" .. (type(k) == "number" and k or v) .. ")"
  end
  send("tell " .. locateperson .. " " .. multimatches[2][2] .. " is at " .. roomName .. " in " .. areaName .. roomId)
end
locateon = false
