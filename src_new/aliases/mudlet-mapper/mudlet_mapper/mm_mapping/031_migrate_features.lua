--[[mudlet
type: alias
name: migrate features
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- mm Mapping
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^feature migrate$
command: ''
packageName: ''
]]--

local translation
if mmp.game == "starmourn" then
  translation =
  {
    ["@"] = "landing dock",
    ["C"] = "cloning",
    ["R"] = "repair",
    ["$"] = "denizen shop",
    ["I"] = "insurance office",
    ["T"] = "transport",
    ["J"] = "junk",
    ["M"] = "mail",
    ["L"] = "lift",
    ["P"] = "ptp",
    ["TT"] = "trade terminal",
  }
else
  mmp.echo("Sorry, don't know which room character maps to which map feature for your game. Please contact us at https://discord.gg/PPUNnc3 to get this sorted out.")
	return
end
mmp.echo("Migrating room characters to map features...")
for char, feature in pairs(translation) do
  mmp.createMapFeature(feature, char)
end
for key in pairs(getRooms()) do
  local char = getRoomChar(key)
  if char ~= "" then
    if translation[char] then
      if not mmp.roomCreateMapFeature(translation[char], key) then
			  mmp.echo("An error occurred when migrating room characters, see messages above for details. Migration incomplete!")
			  return
			end
    end
  end
end
mmp.echo("Migration done.")