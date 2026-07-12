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
      ataxia.updater.latestKnown = latest
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
    ataxia.updater._installOk = false
    uninstallPackage("Levi_Ataxia")
    tempTimer(2, [[ installPackage(ataxia.updater._pendingInstall) ]])
    tempTimer(6, [[ if ataxia and ataxia.updater and ataxia.updater.finishInstall then ataxia.updater.finishInstall() end ]])
  end
end

-- Runs 6s after uninstall (4s after installPackage). On success, delete the
-- downloaded mpackage; on failure, keep it as evidence and tell the user --
-- previously the file was deleted blindly and a failed install left the
-- system uninstalled with no message at all.
function ataxia.updater.finishInstall()
  local path = ataxia.updater._pendingInstall
  if not path then
    return
  end
  ataxia.updater._pendingInstall = nil
  if ataxia.updater._installOk then
    os.remove(path)
  else
    cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <red>Update install did NOT complete!\n")
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>The package file was kept at: " .. path .. "\n")
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>Retry SYSUPDATE, or install that file manually via the Package Manager.\n\n")
  end
end

-- Confirms the install actually happened (sysInstallPackage only fires on a
-- real, successful install) and cross-checks the version that came in.
function ataxia.updater.onInstalled(_, name)
  if not name or not (name:find("Ataxia") or name:find("ataxia")) then
    return
  end
  ataxia.updater._installOk = true
  local latest = ataxia.updater.latestKnown
  if latest and ataxiaVersion and ataxiaVersion ~= latest then
    -- GitHub's releases/latest/download redirect is CDN-cached for a few
    -- minutes after a release publishes, and version.txt can run ahead of
    -- the pushed tags -- either way an old asset installs as "success".
    cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <red>Installed v" .. ataxiaVersion .. " but the latest version is v" .. latest .. ".\n")
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>GitHub may still be propagating the new release. Try SYSUPDATE again in a few minutes.\n\n")
  end
  if ataxia.updater._pendingInstall then
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <DimGrey>If the Package Manager window is open, close and reopen it to see the updated package.\n")
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
if ataxia.updater._installHandler then
  killAnonymousEventHandler(ataxia.updater._installHandler)
end

ataxia.updater._downloadHandler = registerAnonymousEventHandler(
  "sysDownloadDone", ataxia.updater.onDownloadDone
)
ataxia.updater._errorHandler = registerAnonymousEventHandler(
  "sysDownloadError", ataxia.updater.onDownloadError
)
ataxia.updater._installHandler = registerAnonymousEventHandler(
  "sysInstallPackage", ataxia.updater.onInstalled
)

-- Check for updates on load
registerAnonymousEventHandler("sysLoadEvent", function()
  tempTimer(5, function() ataxia.updater.checkVersion() end)
end)
