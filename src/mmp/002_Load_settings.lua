-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Load settings

-- mmp = mudlet mapper namespace
mmp =
  mmp or
  {
    paused = false,
    autowalking = false,
    currentroom = 0,
    currentroomname = "(unknown)",
    firstRun = true,
    specials = {},
    ferry_rooms = {},
  }
speedWalkWatch = createStopWatch()
-- populated by Mudlet from getPath() and gotoRoom()
speedWalkPath = speedWalkPath or {}
speedWalkDir = speedWalkDir or {}
speedWalkCounter = 0
-- actually used by the mapper for walking
mmp.speedWalk = mmp.speedWalk or {}
mmp.speedWalkPath = mmp.speedWalkPath or {}
mmp.speedWalkDir = mmp.speedWalkDir or {}
mmp.lagtable = {
    [1] = {
        description = "Normal, default level.",
        time = 0.5
    },
    [2] = {
        description = "Decent, but slightly laggy.",
        time = 1
    },
    [3] = {
        description = "Noticeably laggy with occasional spikes.",
        time = 2
    },
    [4] = {
        description = "Bad. Terrible. Terribad.",
        time = 5
    },
    [5] = {
        description = "Carrier Pigeon",
        time = 10
    }
}
local newversion = "21.4.1"
if mmp.version and mmp.version ~= newversion then
  if not mmp.game then
    mmp.echo(
      "Mapper script updated - Thanks! I don't know what game are you connected to, though - so please reconnect, if you could."
    )
  else
    mmp.echo("Mapper script updated - thanks! You don't need to restart.")
  end
end
mmp.version = newversion

function mmp.startup()
  if not mmp.firstRun then
    return
  end
  local private_settings = {}
  --General settings
  private_settings["echocolour"] =
    createOption(
      "cyan",
      mmp.changeEchoColour,
      {"string"},
      "Set the color for room number echos?",
      function(newSetting)
        return color_table[newSetting] ~= nil
      end
    )
  private_settings["crowdmap"] =
    createOption(
      false,
      mmp.changeMapSource,
      {"boolean"},
      "Use a crowd-sourced map instead of IREs default?",
      nil,
      {achaea = true, starmourn = true, lusternia = true, stickmud = true}
    )
  private_settings["showcmds"] =
    createOption(true, mmp.changeBoolFunc, {"boolean"}, "Show walking commands?")
  private_settings["laglevel"] =
    createOption(1, mmp.changeLaglevel, {"number"}, "How laggy is your connection, (fast 1<->5 slow)?", mmp.verifyLaglevel)
  private_settings["slowwalk"] =
    createOption(
      false, mmp.setSlowWalk, {"boolean"}, "Walk slowly instead of as quick as possible?"
    )
  private_settings["updatemap"] =
    createOption(true, mmp.changeUpdateMap, {"boolean"}, "Check for new maps from your MUD?")
  private_settings["waterwalk"] =
    createOption(
      true,
      mmp.setWaterWalk,
      {"boolean"},
      "Have waterwalk (don't avoid water)?",
      nil,
      {achaea = true}
    )
  --locking things
  private_settings["lockpathways"] =
    createOption(
      true, mmp.lockPathways, {"boolean"}, "Lock pathway exits?", nil, {lusternia = true}
    )
  private_settings["locksewers"] =
    createOption(false, mmp.lockSewers, {"boolean"}, "Lock all sewers?", nil, {achaea = true})
  private_settings["lockspecials"] =
    createOption(false, mmp.lockSpecials, {"boolean"}, "Lock all special exits?")
  private_settings["lockwormholes"] =
    createOption(
      true,
      mmp.lockWormholes,
      {"boolean"},
      "Lock all wormholes?",
      nil,
      {achaea = true, imperian = true, aetolia = true}
    )
  --Sprint movement
  private_settings["dash"] =
    createOption(
      false,
      mmp.changeBoolFunc,
      {"boolean"},
      "Use Dash?",
      nil,
      {achaea = true, imperian = true, aetolia = true}
    )
  private_settings["sprint"] = createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Sprint?")
  private_settings["gallop"] = createOption(false, mmp.changeBoolFunc, {"boolean"}, "Use Gallop?")
  private_settings["runaway"] =
    createOption(
      false, mmp.changeBoolFunc, {"boolean"}, "Use Jester Runaway?", nil, {achaea = true}
    )
  --Achaea wings and things
  private_settings["winglanguage"] =
    createOption(
      "",
      mmp.setWingsLanguage,
      {"string"},
      "Speak non-default language for wings:",
      nil,
      {achaea = true}
    )
  private_settings["pebble"] =
    createOption(
      false, mmp.lockPebble, {"boolean"}, "Make use of your enchanted pebble?", nil, {achaea = true}
    )
  private_settings["removewings"] =
    createOption(
      true,
      mmp.setWingsRemoval,
      {"boolean"},
      "Remove Wings after using them?",
      nil,
      {achaea = true, imperian = true}
    )
  private_settings["harness"] =
    createOption(
      false, mmp.setHarness, {"boolean"}, "Use Stratospheric Harness?", nil, {achaea = true}
    )
  --PapaGuacamole
  private_settings["duantahar"] =
    createOption(false, mmp.setDuantahar, {"boolean"}, "Use Chenubian Wings?", nil, {achaea = true})
  private_settings["duanatharan"] =
    createOption(false, mmp.setDuanatharan, {"boolean"}, "Use Atavian Wings?", nil, {achaea = true})
  private_settings["duanathar"] =
    createOption(false, mmp.setDuanathar, {"boolean"}, "Use Eagle Wings?", nil, {achaea = true})
  private_settings["duanatharic"] =
    createOption(false, mmp.setDuanatharic, {"boolean"}, "Use Island Wings?", nil, {achaea = true})
  private_settings["soar"] =
    createOption(false, mmp.setSoar, {"boolean"}, "Use Aero Soar?", nil, {achaea = true})
  private_settings["shackle"] =
    createOption(false, mmp.changeBoolFunc, {"boolean"}, "Take off shackle?", nil, {achaea = true})
  private_settings["universe"] =
    createOption(false, mmp.setUniverse, {"boolean"}, "Use Universe Tarot?", nil, {achaea = true})
  private_settings["gare"] =
    createOption(false, mmp.setGare, {"boolean"}, "Use Gare?", nil, {achaea = true})
  --Achaea Orb of Confinement
  private_settings["orbashtan"] =
    createOption(
      false,
      function()
        mmp.setOrb("ashtan")
      end,
      {"boolean"},
      "Orb of Confinement active in Ashtan?",
      nil,
      {achaea = true}
    )
  private_settings["orbcyrene"] =
    createOption(
      false,
      function()
        mmp.setOrb("cyrene")
      end,
      {"boolean"},
      "Orb of Confinement active in Cyrene?",
      nil,
      {achaea = true}
    )
  private_settings["orbeleusis"] =
    createOption(
      false,
      function()
        mmp.setOrb("eleusis")
      end,
      {"boolean"},
      "Orb of Confinement active in Eleusis?",
      nil,
      {achaea = true}
    )
  private_settings["orbhashan"] =
    createOption(
      false,
      function()
        mmp.setOrb("hashan")
      end,
      {"boolean"},
      "Orb of Confinement active in Hashan?",
      nil,
      {achaea = true}
    )
  private_settings["orbmhaldor"] =
    createOption(
      false,
      function()
        mmp.setOrb("mhaldor")
      end,
      {"boolean"},
      "Orb of Confinement active in Mhaldor?",
      nil,
      {achaea = true}
    )
  private_settings["orbtargossas"] =
    createOption(
      false,
      function()
        mmp.setOrb("targossas")
      end,
      {"boolean"},
      "Orb of Confinement active in Targossas?",
      nil,
      {achaea = true}
    )
  --Imperian wings
  private_settings["shekinah"] =
    createOption(false, mmp.setShekinah, {"boolean"}, "Use Seraphim Wings?", nil, {imperian = true})
  private_settings["suriel"] =
    createOption(false, mmp.setSuriel, {"boolean"}, "Use Orphanim Wings?", nil, {imperian = true})
  --Lusternia bixes
  private_settings["torus"] =
    createOption(
      false, mmp.setTorus, {"boolean"}, "Make use of your Torus?", nil, {lusternia = true}
    )
  private_settings["prism"] =
    createOption(
      false,
      mmp.setPrism,
      {"boolean"},
      "Make use of your transplanar prism?",
      nil,
      {lusternia = true}
    )
  private_settings["cubix"] =
    createOption(
      false, mmp.setCubix, {"boolean"}, "Make use of your Cubix?", nil, {lusternia = true}
    )
  private_settings["medallion"] =
    createOption(
      false, mmp.setMedallion, {"boolean"}, "Make use of your Medallion?", nil, {lusternia = true}
    )
  --Lusternia Bubblixes
  private_settings["tibia"] =
    createOption(
      false, mmp.setTibia, {"boolean"}, "Make use of your Tibia?", nil, {lusternia = true}
    )
  private_settings["mud"] =
    createOption(false, mmp.setMud, {"boolean"}, "Make use of your Mud?", nil, {lusternia = true})
  private_settings["cookie"] =
    createOption(
      false, mmp.setCookie, {"boolean"}, "Make use of your Cookie?", nil, {lusternia = true}
    )
  private_settings["icicle"] =
    createOption(
      false, mmp.setIcicle, {"boolean"}, "Make use of your Icicle?", nil, {lusternia = true}
    )
  private_settings["screwdriver"] =
    createOption(
      false,
      mmp.setScrewdriver,
      {"boolean"},
      "Make use of your Screwdriver?",
      nil,
      {lusternia = true}
    )
  private_settings["snowglobe"] =
    createOption(
      false, mmp.setSnowglobe, {"boolean"}, "Make use of your Snowglobe?", nil, {lusternia = true}
    )
  private_settings["head"] =
    createOption(
      false, mmp.setHead, {"boolean"}, "Make use of your Doll's Head?", nil, {lusternia = true}
    )
  private_settings["wheel"] =
    createOption(
      false, mmp.setWheel, {"boolean"}, "Make use of your Quartz Wheel?", nil, {lusternia = true}
    )
  --Lusternia Curio collections
  private_settings["bonecurio"] =
    createOption(
      false, mmp.setBonecurio, {"boolean"}, "Make use of your Bone curios?", nil, {lusternia = true}
    )
  private_settings["facecurio"] =
    createOption(
      false, mmp.setFacecurio, {"boolean"}, "Make use of your Face curios?", nil, {lusternia = true}
    )
  private_settings["feathercurio"] =
    createOption(
      false,
      mmp.setFeathercurio,
      {"boolean"},
      "Make use of your Feather curios?",
      nil,
      {lusternia = true}
    )
  private_settings["figurecurio"] =
    createOption(
      false,
      mmp.setFigurecurio,
      {"boolean"},
      "Make use of your Figure curios?",
      nil,
      {lusternia = true}
    )
  private_settings["flowercurio"] =
    createOption(
      false,
      mmp.setFlowercurio,
      {"boolean"},
      "Make use of your Flower curios?",
      nil,
      {lusternia = true}
    )
  private_settings["fluttercurio"] =
    createOption(
      false,
      mmp.setFluttercurio,
      {"boolean"},
      "Make use of your Flutter curios?",
      nil,
      {lusternia = true}
    )
  private_settings["toolcurio"] =
    createOption(
      false,
      mmp.setToolcurio,
      {"boolean"},
      "Make use of your Tool curios]?",
      nil,
      {lusternia = true}
    )
  private_settings["vernalcurio"] =
    createOption(
      false,
      mmp.setVernalcurio,
      {"boolean"},
      "Make use of your Vernal curios?",
      nil,
      {lusternia = true}
    )
  private_settings["utensilcurio"] =
    createOption(
      false,
      mmp.setUtensilcurio,
      {"boolean"},
      "Make use of your Utensil curios?",
      nil,
      {lusternia = true}
    )
  private_settings["toycurio"] =
    createOption(
      false, mmp.setToycurio, {"boolean"}, "Make use of your Toy curios?", nil, {lusternia = true}
    )
  private_settings["soullesscurio"] =
    createOption(
      false,
      mmp.setSoullesscurio,
      {"boolean"},
      "Make use of your Soulless curios?",
      nil,
      {lusternia = true}
    )
  --Lusternia epic
  private_settings["fingerblade"] =
    createOption(
      false,
      mmp.setFingerblade,
      {"boolean"},
      "Make use of your Fingerblade?",
      nil,
      {lusternia = true}
    )
  private_settings["blossom"] =
    createOption(
      false,
      mmp.setBlossom,
      {"boolean"},
      "Make use of your Flame of dae'Seren?",
      nil,
      {lusternia = true}
    )
  private_settings["belt"] =
    createOption(false, mmp.setBelt, {"boolean"}, "Make use of your Belt?", nil, {lusternia = true})
  private_settings["mandala"] =
    createOption(
      false, mmp.setMandala, {"boolean"}, "Make use of your Mandala?", nil, {lusternia = true}
    )
  private_settings["mantle"] =
    createOption(
      false, mmp.setMantle, {"boolean"}, "Make use of your Mantle?", nil, {lusternia = true}
    )
  private_settings["key"] =
    createOption(false, mmp.setKey, {"boolean"}, "Make use of your Key?", nil, {lusternia = true})
  --misc
  private_settings["caravan"] =
    createOption(false, mmp.changeBoolFunc, {"boolean"}, "Walk caravans?", nil, {imperian = true})
  mmp.settings = createOptionsTable(private_settings)
  mmp.settings.disp = mmp.echo
  mmp.game = false
  mmp.settings.dispOption =
    function(opt, val)
      cecho(
        "<green>" ..
        val.use ..
        "<white> (" ..
        opt ..
        ") " ..
        string.rep(" ", 50 - val.use:len() - opt:len()) ..
        tostring(val.value) ..
        "\n"
      )
    end
  mmp.settings.dispDefaultWriteError =
    function()
      mmp.echo("Please use the mconfig alias to set options!")
    end
  raiseEvent("mmp areas changed")
  mmp.firstRun = false
  mmp.echon("Mudlet Mapper script for IREs (" .. tostring(mmp.version) .. ") loaded! (")
  echoLink(
    "homepage",
    "(openUrl or openURL)'http://wiki.mudlet.org/w/IRE_mapping_script'",
    "Clicky clicky to read up on what's this about"
  )
  echo(")\n")
end