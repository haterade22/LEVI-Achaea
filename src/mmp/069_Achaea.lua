-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Wings and other fast travel > Achaea

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsAchaea")



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

  --Achaea stuff!
  if mmp.game ~= "achaea" then
    return
  end
  local area = getRoomArea(mmp.currentroom)
  --WINGS!
  if
    (mmp.settings.duanathar or mmp.settings.duanatharan or mmp.settings.duantahar) and
    not mmp.inside
  then
    --Sarapis wings.
    if mmp.oncontinent(area, "Main") then
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
    elseif mmp.oncontinent(area, "Meropis") then
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
  end
  --Island wings.
  if mmp.settings.duanatharic and not mmp.inside then
    if
      mmp.oncontinent(area, "Main") or
      mmp.oncontinent(area, "Arcadia") or
      mmp.oncontinent(area, "Outer") or
      mmp.oncontinent(area, "Meropis") or
      mmp.oncontinent(area, "Island") or
      mmp.oncontinent(area, "North")
    then
      mmp.tempSpecialExit(47571, getcmd("duanatharic"))
    end
  end
  -- Stratospheric Harness support -- PapaGuacamole
  if mmp.settings.harness and not mmp.inside then
    -- eastern isles
    if mmp.oncontinent(area, "Eastern_Isles") then
      mmp.tempSpecialExit(54231, "Shake Harness")
      -- northern isles
    elseif mmp.oncontinent(area, "Northen_Isles") then
      mmp.tempSpecialExit(48719, "Shake Harness")
      -- western isles
    elseif mmp.oncontinent(area, "Western_Isles") then
      mmp.tempSpecialExit(54632, "Shake Harness")
    end
  end
  -- Air Elemental Aero Soar
  if mmp.settings.soar and not mmp.inside then
    --Sarapis soar.
    if mmp.oncontinent(area, "Main") then
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
    elseif mmp.oncontinent(area, "Meropis") then
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
  if mmp.settings.universe and mmp.oncontinent(area, "Main") then
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
      mmp.oncontinent(area, "Main") or
      mmp.oncontinent(area, "Meropis") or
      mmp.oncontinent(area, "Island") or
      mmp.oncontinent(area, "North") or
      mmp.oncontinent(area, "Arcadia")
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
  mmp.clearpathcache()
end