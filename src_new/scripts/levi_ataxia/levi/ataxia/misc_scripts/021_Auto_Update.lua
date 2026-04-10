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
    ataxia_Echo("Download complete. Removing old package...")
    -- Store path in a global so string-lambda tempTimers can reference it.
    -- Function closures get destroyed with uninstallPackage; string lambdas survive.
    ataxia.updater._pendingInstall = ataxia.updater.packageFile
    uninstallPackage("Levi_Ataxia")
    tempTimer(2, [[ installPackage(ataxia.updater._pendingInstall) ]])
    tempTimer(4, [[ if ataxia and ataxia.updater and ataxia.updater._pendingInstall then os.remove(ataxia.updater._pendingInstall) ataxia.updater._pendingInstall = nil end ]])
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
