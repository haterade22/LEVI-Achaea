-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Utilities > mconfig settings functions

function mmp.doLock(what, lock, filter)
  if what then mmp.echo(string.format("%s all %s...", (lock and "Locking" or "Unlocking"), what)) end
  local c = 0

  local getAreaRooms, getSpecialExits, lockSpecialExit, next = getAreaRooms, getSpecialExits, lockSpecialExit, next
  for _, area in pairs(getAreaTable()) do
    local rooms = getAreaRooms(area) or {}
    for i = 0, #rooms do
      local exits = getSpecialExits(rooms[i] or 0)

       if exits and next(exits) then
         for exit, cmd in pairs(exits) do
           if type(cmd) == "table" then cmd = next(cmd) end

           if (not filter and not (cmd:lower():find("pathfind", 1, true) or cmd:lower():find("worm warp", 1, true) or cmd:lower():find("enter grate", 1, true))) or (filter and cmd:lower():find(filter, 1, true)) then
             lockSpecialExit(rooms[i], exit, cmd, lock)
             c = c + 1
           end
         end
       end
    end
  end

  if what then mmp.echo(string.format("%s %s known %s.", (lock and "Locked" or "Unlocked"), c, what)) end
  return c
end

function mmp.changeEchoColour()
    mmp.echo("Now displaying echos in <"..mmp.settings.echocolour..">"..mmp.settings.echocolour )
end

function mmp.changeLaglevel()
    local laglevel = mmp.settings.laglevel
    local laginfo = mmp.lagtable[laglevel]
    mmp.echo(string.format("Lag level set to [%d]: %s (%ss timer)", laglevel, laginfo.description, tostring(laginfo.time)))
end

function mmp.verifyLaglevel(value)
  if mmp.lagtable[value] then return true end
  return false
end

function mmp.lockPathways()
  local lock = mmp.settings.lockpathways and true or false
  mmp.doLock("pathways", lock, "pathfind")
end

function mmp.lockSewers()
  local lock = mmp.settings.locksewers and true or false
  return mmp.doLock("sewer grates", lock, "enter grate")
end

function mmp.lockWormholes()
  local lock = mmp.settings.lockwormholes and true or false
  return mmp.doLock("wormholes", lock, "worm warp")
end
tempTimer(0, function() if mmp.firstRun then mmp.lockWormholes() end end)

function mmp.lockPebble()
  local disabled = (not mmp.settings.pebble) and true or false
  mmp.doLock(nil, disabled, "touch 116998")
  mmp.doLock(nil, disabled, "touch 277930")

  mmp.echo(string.format("Use of pebble %s.", disabled and "disabled" or "enabled"))
end

function mmp.lockSpecials()
  local lock = mmp.settings.lockspecials and true or false
  mmp.doLock("special exits", lock)
end

function mmp.setDuanathar()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.duanathar then mmp.echo("Okay, will see about using Eagle wings when you goto somewhere while outside!")
  else mmp.echo("Won't use Eagle wings anymore.") end
end

function mmp.setDuanatharan()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.duanatharan then mmp.echo("Okay, will see about using Atavian wings (both duanathar and duanatharan) when you goto somewhere while outside!")
  else mmp.echo("Won't use Atavian wings anymore.") end
end

function mmp.setDuanatharic()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.duanatharic then mmp.echo("Okay, will see about using Island wings when you goto somewhere while outside!")
  else mmp.echo("Won't use Island wings anymore.") end
end

function mmp.setDuantahar()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.duantahar then mmp.echo("Okay, will see about using Chenubian wings (duanathar, duanatharan, and duantahar) when you goto somewhere while outside!")
  else mmp.echo("Won't use Chenubian wings anymore.") end
end

function mmp.setSoar()
  mmp.clearpathcache() -- clear the cache so it'll use soar or will stop using soar

  if mmp.settings.soar then mmp.echo("Okay, will see about using Aero Soar when you goto somewhere while outside!")
  else mmp.echo("Won't use Aero Soar anymore.") end
end

function mmp.setUniverse()
  mmp.clearpathcache()
	
	if mmp.settings.universe then mmp.echo("Okay, will see about using the Universe tarot whenever it's faster.")
	else mmp.echo("Won't use Universe tarot anymore.") end

end

function mmp.setGare()
  mmp.clearpathcache() -- clear the cache so it'll use gare or stop using gare

  if mmp.settings.gare then mmp.echo("Okay, will see about using Gare when in Dragon form!")
  else mmp.echo("Won't use Gare anymore.") end
end

function mmp.changeMapSource()
  local use = mmp.settings.crowdmap and true or false
  if use and not (mmp.game == "achaea" or mmp.game == "starmourn" or mmp.game == "lusternia" or mmp.game == "stickmud") then
    mmp.echo("Sorry - the crowdsourced map is only available for use in Achaea, Starmourn, Lusternia and StickMUD. If you'd like to help start one for your game, please post at http://forums.mudlet.org/viewtopic.php?f=13&t=1696. If you are playing one of the games, then it is likely that you just downloaded the script - and it doesn't know what you are playing. Reconnect and it'll know.")
    mmp.settings.crowdmap = false
  elseif use and not loadMap then
   mmp.echo("Sorry - your Mudlet is too old and can't load maps. Please update: http://forums.mudlet.org/viewtopic.php?f=5&t=1874")
   mmp.settings.crowdmap = false
  elseif use then
    mmp.echo("Will use the crowdsourced map for updates instead!")
    mmp.checkforupdate()
  else
    mmp.echo("Will use the default game map for updates.")
  end
end

function mmp.setWingsLanguage()
  mmp.echo("Alright, will say Duanathar and Duanathar in "..mmp.settings.winglanguage:title()..".")
end

function mmp.setWingsRemoval()
  mmp.echo("Okay - "..(mmp.settings.removewings and "will" or "won't").." remove wings after using them.")
end

function mmp.setSlowWalk()
  if mmp.settings.slowwalk then
    mmp.echo("Will walk 'slowly' - that is, only try to move in a direction once per room, and move again once we've arrived. This will make us better walkers when it's very laggy, as we won't spam directions unnecessarily and miss certain turns - but it does mean that if we fail to move for some reason, we won't retry again either at all.")
  else
    mmp.echo("Will walk as quick as we can!")
  end
end

function mmp.disableWaterWalk()
  local c = 0
  local getRoomEnv, setRoomWeight = getRoomEnv, setRoomWeight
  for roomid, roomname in pairs(getRooms()) do
    if mmp.waterenvs[getRoomEnv(roomid)] then
      setRoomWeight(roomid, 3)
      c = c + 1
    end
  end

  return c
end

function mmp.enableWaterWalk()
  local c = 0
  local getRoomEnv, setRoomWeight = getRoomEnv, setRoomWeight
  for roomid, roomname in pairs(getRooms()) do
    if mmp.waterenvs[getRoomEnv(roomid)] then
      setRoomWeight(roomid, 1)
      c = c + 1
    end
  end

  return c
end

function mmp.setWaterWalk()
  if mmp.settings.waterwalk then
    mmp.echo("Enabled waterwalk for "..mmp.enableWaterWalk().." rooms - so we'll be treating land and water rooms the same now in terms of traverse speed over them.")
  else
    mmp.echo("Disabled waterwalk for "..mmp.disableWaterWalk().." rooms - so we'll be preferring land rooms over water ones wherever it's quicker.")
  end
end

function mmp.setMedallion()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.medallion then mmp.echo("Okay, will see about using Medallion whenever it's quicker")
  else mmp.echo("Won't use Medallion anymore.") end
end

function mmp.setFingerblade()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.fingerblade then mmp.echo("Okay, will see about using Fingerblade whenever it's quicker")
  else mmp.echo("Won't use Fingerblade anymore.") end
end

function mmp.setBlossom()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.blossom then mmp.echo("Okay, will see about using the Flame whenever it's quicker")
  else mmp.echo("Won't use the Flame anymore.") end
end

function mmp.setMandala()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.mandala then mmp.echo("Okay, will see about using Mandala whenever it's quicker")
  else mmp.echo("Won't use Mandala anymore.") end
end

function mmp.setBelt()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.belt then mmp.echo("Okay, will see about using Belt whenever it's quicker")
  else mmp.echo("Won't use Belt anymore.") end
end

function mmp.setCubix()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.cubix then mmp.echo("Okay, will see about using Cubix whenever it's quicker")
  else mmp.echo("Won't use Cubix anymore.") end
end

function mmp.setPrism()
	mmp.clearpathcache()
	if mmp.settings.prism then mmp.echo("Okay, will see about using Prism whenever it's quicker")
	else mmp.echo("Won't use Prism anymore.") end
end

function mmp.setScrewdriver()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.screwdriver then mmp.echo("Okay, will see about using Screwdriver whenever it's quicker")
  else mmp.echo("Won't use Screwdriver anymore.") end
end

function mmp.setWheel()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.wheel then mmp.echo("Okay, will see about using Wheel whenever it's quicker")
  else mmp.echo("Won't use Wheel anymore.") end
end

function mmp.setMud()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.mud then mmp.echo("Okay, will see about using Mud whenever it's quicker")
  else mmp.echo("Won't use Mud anymore.") end
end
function mmp.setSnowglobe()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.snowglobe then mmp.echo("Okay, will see about using Snowglobe whenever it's quicker")
  else mmp.echo("Won't use Snowglobe anymore.") end
end

function mmp.setCookie()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.cookie then mmp.echo("Okay, will see about using Cookie whenever it's quicker")
  else mmp.echo("Won't use Cookie anymore.") end
end

function mmp.setHead()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.head then mmp.echo("Okay, will see about using Doll's Head whenever it's quicker")
  else mmp.echo("Won't use Doll's Head anymore.") end
end

function mmp.setIcicle()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.icicle then mmp.echo("Okay, will see about using Icicle whenever it's quicker")
  else mmp.echo("Won't use Icicle anymore.") end
end

function mmp.setTibia()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.tibia then mmp.echo("Okay, will see about using Tibia whenever it's quicker")
  else mmp.echo("Won't use Tibia anymore.") end
end

function mmp.setBonecurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.bonecurio then mmp.echo("Okay, will see about using Bone Curio collection whenever it's quicker")
  else mmp.echo("Won't use Bone Curio collection anymore.") end
end

function mmp.setFlowercurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.flowercurio then mmp.echo("Okay, will see about using Flower Curio collection whenever it's quicker")
  else mmp.echo("Won't use Flower Curio collection anymore.") end
end

function mmp.setTorus()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.torus then mmp.echo("Okay, will see about using your Torus whenever it's quicker")
  else mmp.echo("Won't use your Torus anymore.") end
end

function mmp.setUtensilcurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.utensilcurio then mmp.echo("Okay, will see about using Utensil Curio collection whenever it's quicker")
  else mmp.echo("Won't use Utensil Curio collection anymore.") end
end

function mmp.setFluttercurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.fluttercurio then mmp.echo("Okay, will see about using Flutter Curio collection whenever it's quicker")
  else mmp.echo("Won't use Flutter Curio collection anymore.") end
end

function mmp.setToolcurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.toolcurio then mmp.echo("Okay, will see about using Tool Curio collection whenever it's quicker")
  else mmp.echo("Won't use Tool Curio collection anymore.") end
end

function mmp.setFacecurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.facecurio then mmp.echo("Okay, will see about using Face Curio collection whenever it's quicker")
  else mmp.echo("Won't use Face Curio collection anymore.") end
end

function mmp.setToycurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.toycurio then mmp.echo("Okay, will see about using Toy Curio collection whenever it's quicker")
  else mmp.echo("Won't use Toy Curio collection anymore.") end
end

function mmp.setFeathercurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.feathercurio then mmp.echo("Okay, will see about using Feather Curio collection whenever it's quicker")
  else mmp.echo("Won't use Feather Curio collection anymore.") end
end

function mmp.setFigurecurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.figurecurio then mmp.echo("Okay, will see about using Figure Curio collection whenever it's quicker")
  else mmp.echo("Won't use Figure Curio collection anymore.") end
end

function mmp.setVernalcurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.vernalcurio then mmp.echo("Okay, will see about using Vernal Curio collection whenever it's quicker")
  else mmp.echo("Won't use Vernal Curio collection anymore.") end
end
function mmp.setSoullesscurio()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.soullesscurio then mmp.echo("Okay, will see about using Soulless Curio collection whenever it's quicker")
  else mmp.echo("Won't use Soulless Curio collection anymore.") end
end

function mmp.setHarness() --PapaGuacamole
  mmp.clearpathcache() -- clear the cache so it'll use harness or will stop using harness

  if mmp.settings.harness then mmp.echo("Okay, will use Stratospheric Harness when on appropriate islands")
  else mmp.echo("Won't use Stratospheric Harness anymore.") end
end

function mmp.setMantle()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.mantle then mmp.echo("Okay, will see about using Mantle of Starlight whenever it's quicker")
  else mmp.echo("Won't use Mantle of Starlight anymore.") end
end

function mmp.setKey()
  mmp.clearpathcache() -- clear the cache so it'll use wings or will stop using wings

  if mmp.settings.key then mmp.echo("Okay, will see about using your Infernal Key whenever it's quicker")
  else mmp.echo("Won't use the Infernal Key anymore.") end
end