-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Check for map updates > Check for updates

local downloadfolder = getMudletHomeDir() .. "/map downloads/"

-- this should get called at start and every hour after that

function mmp.checkforupdate()
  if not mmp.game or mmp.checkingupdates then
    return
  end
  local game = mmp.game
  mmp.mapfile = downloadfolder .. "MD5"
  mmp.mapperfile = downloadfolder .. "mapper"
  if not downloadFile then
    mmp.echo("Your version of Mudlet doesn't support downloading files - please upgrade to 2.0+")
  else
    if not lfs.attributes(downloadfolder) then
      if lfs and lfs.mkdir then
        local t, s = lfs.mkdir(downloadfolder)
        if not t and s ~= "File exists" then
          mmp.echo("Couldn't make the '" .. downloadfolder .. "' folder; " .. s)
          return
        end
      else
        mmp.echo(
          "Sorry, but you need LuaFileSystem (lfs) installed, or have the '" ..
          downloadfolder ..
          "' folder exist."
        )
        return
      end
    end
    if mmp.settings.crowdmap then
      if game == "achaea" then
        downloadFile(
          mmp.mapfile, "http://ire-mudlet-mapping.github.io/AchaeaCrowdmap/Map/version.txt"
        )
      elseif game == "starmourn" then
        downloadFile(
          mmp.mapfile, "http://ire-mudlet-mapping.github.io/StarmournCrowdmap/Map/version.txt"
        )
      elseif game == "lusternia" then
        downloadFile(
          mmp.mapfile, "http://ire-mudlet-mapping.github.io/LusterniaCrowdmap/Map/version.txt"
        )
      elseif game == "imperian" then
        downloadFile(
          mmp.mapfile, "http://ire-mudlet-mapping.github.io/ImperianCrowdmap/Map/version.txt"
        )
      elseif game == "aetolia" then
        downloadFile(
          mmp.mapfile, "http://ire-mudlet-mapping.github.io/AetoliaCrowdmap/Map/version.txt"
        )
      elseif game == "asteria" then
        downloadFile(
          mmp.mapfile, "http://asteria-ui.github.io/AsteriaCrowdmap/Map/version.txt"
        )
      elseif game == "ashyria" then
      downloadFile(
        mmp.mapfile, "https://ashyria.github.io/ashyria-crowdmap/Map/version.txt"
      )
      elseif game == "stickmud" then
        downloadFile(
          mmp.mapfile, "http://stickmud.github.io/StickMUDCrowdmap/Map/version.txt"
        )
      end
    elseif mmp.settings.updatemap then
      downloadFile(mmp.mapfile, "http://www." .. game .. ".com/maps/MD5SUM")
    end
    downloadFile(
      mmp.mapperfile, "http://ire-mudlet-mapping.github.io/ire-mapping-script/downloads/version"
    )
    mmp.checkingupdates = true
  end
end

-- called by the user when the map is updated to register the fact that it was

function mmp.updatedmap(currentmd5)
  assert(currentmd5, "need md5 sum to write to file")
  local f, err = io.open(downloadfolder .. "current", "w")
  if not f then
    return mmp.echo("Couldn't write to the update file, because: " .. err)
  end
  f:write(currentmd5)
  f:close()
  local t = {"Go you for updating!", "Thanks for updating the map!", "Alright, map updated!"}
  mmp.echo(t[math.random(1, #t)])
end

-- downloads the latest changelog for the mapper if it was updated

function mmp.retrievechangelog()
  mmp.changelogfile = downloadfolder .. "changelog"
  downloadFile(
    mmp.changelogfile, "http://ire-mudlet-mapping.github.io/ire-mapping-script/downloads/changelog"
  )
end

function mmp.retrievecrowdchangelog()
  mmp.crowdchangelogfile = downloadfolder .. "crowdchangelogfile"
  if mmp.game == "achaea" then
    downloadFile(
      mmp.crowdchangelogfile, "http://ire-mudlet-mapping.github.io/AchaeaCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "starmourn" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://ire-mudlet-mapping.github.io/StarmournCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "lusternia" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://ire-mudlet-mapping.github.io/LusterniaCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "imperian" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://ire-mudlet-mapping.github.io/ImperianCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "aetolia" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://ire-mudlet-mapping.github.io/AetoliaCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "asteria" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://asteria-ui.github.io/AsteriaCrowdmap/Map/changelog.txt"
    )
  elseif mmp.game == "ashyria" then
  downloadFile(
    mmp.crowdchangelogfile,
    "http://ashyria.github.io/ashyria-crowdmap/Map/changelog.txt"
  )
  elseif mmp.game == "stickmud" then
    downloadFile(
      mmp.crowdchangelogfile,
      "http://stickmud.github.io/StickMUDCrowdmap/Map/changelog.txt"
    )
  end
end

-- downloads the public crowdsources map!

function mmp.downloadmapperscript()
  local file =
    getModulePath("mudlet-mapper") or getMudletHomeDir() .. "/map downloads/mudlet-mapper.xml"
  if io.exists(file) then
    local s, m = os.remove(file)
    if not s then
      mmp.echo(
        "Couldn't delete the old xml (located at %s), because of: %s. This might be a problem.",
        file,
        m
      )
    end
  end
  mmp.downloadedscript = file
  downloadFile(
    mmp.downloadedscript,
    "http://ire-mudlet-mapping.github.io/ire-mapping-script/downloads/mudlet-mapper.xml"
  )
  mmp.echo("Okay, downloading the mapper script...")
end

function mmp.downloadcrowdmap(newversion)
  mmp.crowdmapfile = downloadfolder .. "crowdmap"
  local f, err = io.open(downloadfolder .. "current", "w")
  if not f then
    return mmp.echo("Couldn't write to the update file, because: " .. err)
  end
  f:write(newversion)
  f:close()
  if mmp.game == "achaea" then
    downloadFile(mmp.crowdmapfile, "http://ire-mudlet-mapping.github.io/AchaeaCrowdmap/Map/map")
  elseif mmp.game == "starmourn" then
    downloadFile(mmp.crowdmapfile, "http://ire-mudlet-mapping.github.io/StarmournCrowdmap/Map/map")
  elseif mmp.game == "lusternia" then
    downloadFile(mmp.crowdmapfile, "http://ire-mudlet-mapping.github.io/LusterniaCrowdmap/Map/map")
  elseif mmp.game == "imperian" then
    downloadFile(mmp.crowdmapfile, "http://ire-mudlet-mapping.github.io/ImperianCrowdmap/Map/map")
  elseif mmp.game == "aetolia" then
    downloadFile(mmp.crowdmapfile, "http://ire-mudlet-mapping.github.io/AetoliaCrowdmap/Map/map")
  elseif mmp.game == "asteria" then
    downloadFile(mmp.crowdmapfile, "http://asteria-ui.github.io/AsteriaCrowdmap/Map/map")
  elseif mmp.game == "ashyria" then
  downloadFile(mmp.crowdmapfile, "http://ashyria.github.io/ashyria-crowdmap/Map/map")
  elseif mmp.game == "stickmud" then
    downloadFile(mmp.crowdmapfile, "http://stickmud.github.io/StickMUDCrowdmap/Map/map")
  end
  mmp.echo("Downloading the latest crowdmap...")
end

function mmp.showcrowdchangelog()
  mmp.echo("Public map changelog:")
  if not mmp.crowdchangelog then
    mmp.echo("(none yet)")
    return
  end
  for k, v in ipairs(mmp.crowdchangelog) do
    cecho(string.format("  %s) %s\n", k, v:gsub("\t", "     ")))
  end
end

function mmp.installMapperScript()
  local path = getModulePath("mudlet-mapper")
  if not path then
    uninstallPackage("mudlet-mapper")
    tempTimer(1, [[installPackage(mmp.downloadedscript)]])
  else
    reloadModule("mudlet-mapper")
  end
end

