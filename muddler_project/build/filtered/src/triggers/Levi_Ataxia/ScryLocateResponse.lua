-- multimatches[2][2] = name scried
-- multimatches[3][2] = area
-- multimatches[3][3] = location
if locateon == true then
  send("tell " .. locateperson .. " " .. multimatches[2][2] .. " is at " .. multimatches[3][3] .. " in " .. multimatches[3][2])
end
locateon = false
