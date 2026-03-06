mmp.locateAndEcho(matches[3], matches[2])
if locateon == true then
  local t = mmp.searchRoomExact(matches[3])
  local roomId = ""
  if next(t) then
    local k, v = next(t)
    roomId = " (" .. (type(k) == "number" and k or v) .. ")"
  end
  send("tell " .. locateperson .. " " .. matches[2] .. " is at " .. matches[3] .. roomId)
end
locateon = false