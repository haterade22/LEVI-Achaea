--[[mudlet
type: script
name: Auto_Update
hierarchy:
- Levi_Ataxia
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
eventHandlers:
- sysDownloadDone
- sysDownloadError
]]--

ataxia.updater = ataxia.updater or {}

local UPDATE_URL = "https://github.com/haterade22/LEVI-Achaea/raw/main/muddler_project/build/Levi_Ataxia.mpackage"
local VERSION_URL = "https://raw.githubusercontent.com/haterade22/LEVI-Achaea/main/version.txt"

function ataxia.updater.checkVersion()
  ataxia.updater.versionFile = getMudletHomeDir() .. "/levi_version_check.txt"
  downloadFile(ataxia.updater.versionFile, VERSION_URL)
end

function ataxia.updater.doUpdate()
  ataxia.updater.packageFile = getMudletHomeDir() .. "/Levi_update.mpackage"
  ataxia_Echo("Downloading latest Levi Ataxia update...")
  downloadFile(ataxia.updater.packageFile, UPDATE_URL)
end

function ataxia.updater.onDownloadDone(_, filename)
  if filename == ataxia.updater.versionFile then
    local f = io.open(filename, "r")
    if f then
      local latest = f:read("*all"):gsub("%s+", "")
      f:close()
      os.remove(filename)
      if latest ~= ataxiaVersion then
        cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <orange>Levi Ataxia v" .. ataxiaVersion .. " loaded.\n")
        cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <red>New version available: " .. latest .. "\n")
        cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>Type SYSUPDATE to update.\n\n")
      else
        cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <green>Levi Ataxia v" .. ataxiaVersion .. " is up to date.\n\n")
      end
    end
  elseif filename == ataxia.updater.packageFile then
    ataxia_Echo("Download complete. Installing...")
    uninstallPackage("Levi_Ataxia")
    tempTimer(1, function()
      installPackage(ataxia.updater.packageFile)
      os.remove(ataxia.updater.packageFile)
      ataxia_Echo("Levi Ataxia updated successfully!")
    end)
  end
end

function ataxia.updater.onDownloadError(_, errMsg, url)
  if url and (url:find("haterade22/LEVI%-Achaea") or url:find("version%.txt")) then
    ataxia_Echo("Update check failed: " .. tostring(errMsg))
  end
end

-- Event handler dispatch (Mudlet calls this by script name)
function Auto_Update(event, ...)
  if event == "sysDownloadDone" then
    ataxia.updater.onDownloadDone(event, ...)
  elseif event == "sysDownloadError" then
    ataxia.updater.onDownloadError(event, ...)
  end
end

-- Check for updates on load
registerAnonymousEventHandler("sysLoadEvent", function()
  tempTimer(5, function() ataxia.updater.checkVersion() end)
end)
