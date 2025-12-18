-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Wings and other fast travel > Achaea

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsAchaea")

function mmp.orbed()
	-- orb of confinement - PapaGuacamole
  local areaID = getRoomArea(mmp.currentroom)
  return
		(mmp.game == "achaea" and
  		(
    		(mmp.settings.orbashtan and areaID == 49) or
    		(mmp.settings.orbcyrene and areaID == 57) or
    		(mmp.settings.orbeleusis and areaID == 51) or
    		(mmp.settings.orbhashan and areaID == 55) or
    		(mmp.settings.orbmhaldor and areaID == 44) or
    		(
    			mmp.settings.orbtargossas and
    			((mmp.settings.crowdmap and areaID == 368) or (not mmp.settings.crowdmap and areaID == 271))
    		)
  		)
		)
end

function mmp.addWingsAchaea()
  --Trimmed down version of the original function, meant to only be used for wings. (Where the command varies based on several MCONFIGS)

  local function getcmd(word)
    return
      mmp.settings.removewings and
      string.format(
        [[script:sendAll("wear wings", "say *%s %s", "remove wings", false)]],
        (mmp.settings.winglanguage and mmp.settings.winglanguage or ""),
        word
      ) or
      string.format(
        [[script:send("say *%s %s", false)]],
        (mmp.settings.winglanguage and mmp.settings.winglanguage or ""),
        word
      )
  end
  --creates a special exit from your current room to a destination, and adds it to a table so it can be easily cleared later.
  --Achaea stuff!
  if mmp.game ~= "achaea" then
    return
  end
  --WINGS!
  if
    (mmp.settings.duanathar or mmp.settings.duanatharan or mmp.settings.duantahar) and
    gmcp.Room and
    not table.contains(gmcp.Room.Info.details, "indoors") and
    not mmp.orbed()
  then
    --Sarapis wings.
    if mmp.oncontinent(getRoomArea(mmp.currentroom), "Main") then
      if mmp.settings.duanatharan then
        mmp.tempSpecialExit(4882, getcmd("duanatharan"))
        mmp.tempSpecialExit(3885, getcmd("duanathar"))
      elseif mmp.settings.duantahar then
        mmp.tempSpecialExit(42319, getcmd("duanathar"))
        mmp.tempSpecialExit(4882, getcmd("duanatharan"))
      else
        mmp.tempSpecialExit(3885, getcmd("duanathar"))
      end
      --Meropis Wings
    elseif mmp.oncontinent(getRoomArea(mmp.currentroom), "Meropis") then
      if mmp.settings.duanatharan then
        mmp.tempSpecialExit(51603, getcmd("duanatharan"))
        mmp.tempSpecialExit(51188, getcmd("duanathar"))
      elseif mmp.settings.duantahar then
        mmp.tempSpecialExit(42319, getcmd("duanathar"))
        mmp.tempSpecialExit(51603, getcmd("duanatharan"))
      else
        mmp.tempSpecialExit(51188, getcmd("duanathar"))
      end
    end
    if
      mmp.settings.duanatharic and
      gmcp.Room and
      not table.contains(gmcp.Room.Info.details, "indoors") and
      not mmp.orbed()
    then
      --Island wings.
      if
        mmp.oncontinent(getRoomArea(mmp.currentroom), "Main") or
        mmp.oncontinent(getRoomArea(mmp.currentroom), "Arcadia") or
        mmp.oncontinent(getRoomArea(mmp.currentroom), "Outer") or
        mmp.oncontinent(getRoomArea(mmp.currentroom), "Meropis") or
        mmp.oncontinent(getRoomArea(mmp.currentroom), "Island") or
        mmp.oncontinent(getRoomArea(mmp.currentroom), "North")
      then
        mmp.tempSpecialExit(47571, getcmd("duanatharic"))
      end
    end
  end
  -- Stratospheric Harness support -- PapaGuacamole
  if
    mmp.settings.harness and gmcp.Room and not table.contains(gmcp.Room.Info.details, "indoors")
  then
    -- eastern isles
    if mmp.oncontinent(getRoomArea(mmp.currentroom), "Eastern_Isles") then
      mmp.tempSpecialExit(54231, "Shake Harness")
      -- northern isles
    elseif mmp.oncontinent(getRoomArea(mmp.currentroom), "Northen_Isles") then
      mmp.tempSpecialExit(48719, "Shake Harness")
      -- western isles
    elseif mmp.oncontinent(getRoomArea(mmp.currentroom), "Western_Isles") then
      mmp.tempSpecialExit(54632, "Shake Harness")
    end
  end
  -- Air Elemental Aero Soar
  if
    mmp.settings.soar and
    gmcp.Room and
    not table.contains(gmcp.Room.Info.details, "indoors") and
    not mmp.orbed()
  then
    --Sarapis soar.
    if mmp.oncontinent(getRoomArea(mmp.currentroom), "Main") then
      if
        gmcp.Char.Status.class == "air Elemental Lord" or
        gmcp.Char.Status.class == "air Elemental Lady"
      then
        mmp.tempSpecialExit(4882, "aero soar high", 10)
        -- duanatharan
        mmp.tempSpecialExit(3885, "aero soar low", 10)
        -- duanathar
        mmp.tempSpecialExit(54173, "aero soar stratosphere", 10)
        -- Stratosphere!
      end
      --Meropis soar
    elseif mmp.oncontinent(getRoomArea(mmp.currentroom), "Meropis") then
      if
        gmcp.Char.Status.class == "air Elemental Lord" or
        gmcp.Char.Status.class == "air Elemental Lady"
      then
        mmp.tempSpecialExit(51603, "aero soar high", 10)
        -- duanatharan
        mmp.tempSpecialExit(51188, "aero soar low", 10)
        -- duanathar
        mmp.tempSpecialExit(54173, "aero soar stratosphere", 10)
        -- Stratosphere!
      end
    end
  end
  --universe tarot
  if mmp.settings.universe and mmp.oncontinent(getRoomArea(mmp.currentroom), "Main") then
    local tarotLocations =
      {
        azdun = 1772,
        blackrock = 10573,
        bitterfork = 25093,
        genji = 10091,
        manusha = 8730,
        newthera = 20386,
        caerwitrin = 17678,
        shastaan = 2855,
        mannaseh = 1745,
        manara = 9124,
        brasslantern = 30383,
        mhojave = 39103,
        thraasi = 35703,
        newhope = 25581,
      }
    for village, roomnum in pairs(tarotLocations) do
      mmp.tempSpecialExit(
        roomnum,
        [=[script:
        mmp.customwalkdelay(4.5)
        send("fling universe at ground",false)
        tempTimer(4,[[send("touch ]=] ..
        village ..
        [=[",false)]])
        ]=],
        10
      )
    end
  end
  --gare
  if mmp.settings.gare and gmcp.Char and string.match(gmcp.Char.Status.race, "Dragon") then
    if
      mmp.oncontinent(getRoomArea(mmp.currentroom), "Main") or
      mmp.oncontinent(getRoomArea(mmp.currentroom), "Meropis") or
      mmp.oncontinent(getRoomArea(mmp.currentroom), "Island") or
      mmp.oncontinent(getRoomArea(mmp.currentroom), "North") or
      mmp.oncontinent(getRoomArea(mmp.currentroom), "Arcadia")
    then
      mmp.tempSpecialExit(
        12695,
        [=[script:
        mmp.customwalkdelay(4.5)
        send("pierce the veil",false)
        ]=],
        20
      )
    end
  end
  --clears the path cache so it calculates a new route.
  mmp.clearpathcache()
end