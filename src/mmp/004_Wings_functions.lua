-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Wings and other fast travel > Wings functions

local exitsCreated = exitsCreated or {}

function mmp.tempSpecialExit(start, destination, command, weight)
  if type(destination) == "string" then
    -- no start room given, so shift all arguments one to the right
    start, destination, command, weight = mmp.currentroom, start, destination, command
  end
  table.insert(exitsCreated, {room = start, command = command})
  addSpecialExit(start, destination, command)
  if weight then
    setExitWeight(start, command, weight)
  end
end

function mmp.removeWings()
  --remove all special exits that were created by addWings, then resets the table.
  for _, exit in ipairs(exitsCreated) do
    removeSpecialExit(exit.room, exit.command)
  end
  exitsCreated = {}
end

registerAnonymousEventHandler("mmp clear externals", "mmp.removeWings")