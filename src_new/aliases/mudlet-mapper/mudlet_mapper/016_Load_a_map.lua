--[[mudlet
type: alias
name: Load a map
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^map load(?: (.+))?$'
command: ''
packageName: ''
]]--

local function s(loc)
  if string.ends(loc, ".json") and not loadJsonMap then
    mmp.echo("Your Mudlet can't load maps in JSON, please upgrade first.")
    return
  end

  local allok = true
  if string.ends(loc, ".json") then
    allok = loadJsonMap(loc)
  else
    allok = loadMap(loc)
  end

  if not allok then
    mmp.echo("Couldn't load the map :(")
  else
    mmp.lockWormholes();
    mmp.lockSewers();
    mmp.lockPebble();
    if mmp.settings.waterwalk then
      mmp.enableWaterWalk()
    else
      mmp.disableWaterWalk()
    end
    if loc ~= "" then
      mmp.echo("Map loaded.")
    else
      mmp.echo("Loaded the default map.")
    end
    raiseEvent("mmapper updated map")
  end
end

if matches[2] and matches[2] == "custom" then
  s(invokeFileDialog(true, "Please select the map file and click Open to load it"))
elseif matches[2] then
  s(getMudletHomeDir() .. "/map/" .. matches[2])
else
  s("")
end