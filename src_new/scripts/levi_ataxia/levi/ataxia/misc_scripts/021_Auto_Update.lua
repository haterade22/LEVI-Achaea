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
]]--

ataxia.updater = ataxia.updater or {}

local UPDATE_URL = "https://github.com/haterade22/LEVI-Achaea/releases/latest/download/Levi_Ataxia.mpackage"
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
    -- capture path locally before uninstalling the package that contains this script
    local packagePath = ataxia.updater.packageFile
    ataxia_Echo("Download complete. Removing old package...")
    uninstallPackage("Levi_Ataxia")
    ataxia_Echo("Installing new package...")
    tempTimer(2, function()
      installPackage(packagePath)
      tempTimer(1, function()
        os.remove(packagePath)
      end)
    end)
  end
end

function ataxia.updater.onDownloadError(_, errMsg, url)
  if url and (url:find("haterade22/LEVI%-Achaea") or url:find("version%.txt")) then
    ataxia_Echo("Update check failed: " .. tostring(errMsg))
  end
end

-- Register event handlers via anonymous handlers so they survive uninstallPackage.
-- The old approach used YAML eventHandlers + a dispatch function named after the script,
-- but those handlers get removed when the package is uninstalled during self-update.
if ataxia.updater._downloadHandler then
  killAnonymousEventHandler(ataxia.updater._downloadHandler)
end
if ataxia.updater._errorHandler then
  killAnonymousEventHandler(ataxia.updater._errorHandler)
end

ataxia.updater._downloadHandler = registerAnonymousEventHandler(
  "sysDownloadDone", ataxia.updater.onDownloadDone
)
ataxia.updater._errorHandler = registerAnonymousEventHandler(
  "sysDownloadError", ataxia.updater.onDownloadError
)

-- Check for updates on load
registerAnonymousEventHandler("sysLoadEvent", function()
  tempTimer(5, function() ataxia.updater.checkVersion() end)
end)
