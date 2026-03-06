if not capturing_defences then return end
if not matches[2]:find("experience") and not matches[2]:find("critical") then
  deleteLine()
end