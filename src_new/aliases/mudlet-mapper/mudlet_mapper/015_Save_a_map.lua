--[[mudlet
type: alias
name: Save a map
hierarchy:
- mudlet-mapper
- Mudlet Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: '^map save(?: (json|all))?(?: (.+))?$'
command: ''
packageName: ''
]]--

local function s(location, format)
  local savednormal, savedjson = "not saved", "not saved"
  if format == "json" then
    savedjson = saveJsonMap(location)
  elseif format == "all" then
    savedjson = saveJsonMap(location)
    savednormal = saveMap(location)
  elseif format == nil or format == "" then
    savednormal = saveMap(location)
  end

  if savednormal == nil then
    mmp.echo("Couldn't save the map :(")
  elseif savednormal == true then
    mmp.echo(location ~= "" and "Map saved." or "Saved the default map.")
  end
  if savedjson == nil then
    mmp.echo("Couldn't save the JSON map :(")
  elseif savedjson == true then
    mmp.echo(location ~= "" and "Map saved in JSON." or "Saved the default map in JSON.")
  end
end

if matches[2] and (matches[2] == "json" or matches[2] == "all") and not saveJsonMap then
  mmp.echo("Your Mudlet can't save maps in JSON, please upgrade first.")
  return
end
if matches[3] and matches[3] == "custom" then
  s(
    invokeFileDialog(false, "Please select the folder to save the map in and hit Open") ..
    "/Mudlet map from " ..
    os.date("%A %d, %b '%y") ..
    ".dat",
    matches[2]
  )
elseif matches[3] then
  s(getMudletHomeDir() .. "/map/" .. matches[3], matches[2])
else
  s("", matches[2])
end