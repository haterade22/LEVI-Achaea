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
-- NOT <profile>/current: Mudlet loads the newest file there at start-up.
local BACKUP_DIR = "sysupdate_backups"
local BACKUP_KEEP = 3
-- Mudlet refuses uninstallPackage while a profile save runs, so the swap retries once a second.
local UNINSTALL_MAX_TRIES = 30

function ataxia.updater.checkVersion()
  ataxia.updater.versionFile = getMudletHomeDir() .. "/levi_version_check.txt"
  downloadFile(ataxia.updater.versionFile, VERSION_URL)
end

function ataxia.updater.doUpdate()
  ataxia.updater.packageFile = getMudletHomeDir() .. "/Levi_update.mpackage"
  ataxia_Echo("Downloading latest Levi Ataxia update...")
  ataxia_Echo("The update replaces every edit inside Levi_Ataxia. Your own folders stay. A backup is saved first.")
  downloadFile(ataxia.updater.packageFile, UPDATE_URL)
end

-- An update uninstalls the package, so an edit inside it is lost (player report, 2026-11-03). This
-- saves the whole profile first. Three are kept because the next update must not overwrite the only
-- copy of an edit. The rotation also means backup_1 exists only if THIS save wrote it.
-- Returns the path of the file Mudlet is writing, or nil and the reason. A failure must not stop the update.
function ataxia.updater.backupProfile()
  local dir = getMudletHomeDir() .. "/" .. BACKUP_DIR
  if lfs and lfs.mkdir then pcall(lfs.mkdir, dir) end
  os.remove(dir .. "/backup_" .. BACKUP_KEEP .. ".xml")
  for i = BACKUP_KEEP - 1, 1, -1 do
    os.rename(dir .. "/backup_" .. i .. ".xml", dir .. "/backup_" .. (i + 1) .. ".xml")
  end
  local called, ok, result = pcall(saveProfile, dir, "backup_1")
  if not called then
    return nil, tostring(ok)
  end
  if not ok then
    return nil, tostring(result)
  end
  return result
end

-- Runs from string-lambda timers: see the note in onDownloadDone.
function ataxia.updater.swapPackage(tries)
  tries = tries or 1
  local removed, err = uninstallPackage("Levi_Ataxia")
  if not removed and type(err) == "string" and err:find("save") then
    if tries >= UNINSTALL_MAX_TRIES then
      ataxia.updater._pendingInstall = nil
      cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <red>Update stopped: a profile save did not finish.\n")
      cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>The old version is still installed. Try SYSUPDATE again.\n\n")
      return
    end
    tempTimer(1, "ataxia.updater.swapPackage(" .. (tries + 1) .. ")")
    return
  end
  tempTimer(2, [[ installPackage(ataxia.updater._pendingInstall) ]])
  tempTimer(6, [[ if ataxia and ataxia.updater and ataxia.updater.finishInstall then ataxia.updater.finishInstall() end ]])
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
        cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>Type SYSUPDATE to update.\n")
        cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <yellow>It replaces edits inside Levi_Ataxia. Keep your own items in your own folder.\n\n")
      else
        cecho("\n<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <green>Levi Ataxia v" .. ataxiaVersion .. " is up to date.\n\n")
      end
    end
  elseif filename == ataxia.updater.packageFile then
    ataxia_Echo("Download complete. Saving your settings and a backup of your profile...")
    -- Store path in a global so string-lambda tempTimers can reference it.
    -- Function closures get destroyed with uninstallPackage; string lambdas survive.
    ataxia.updater._pendingInstall = ataxia.updater.packageFile
    ataxia.updater._installOk = false
    if ataxia_saveSettings then pcall(ataxia_saveSettings, false) end
    local backup, why = ataxia.updater.backupProfile()
    ataxia.updater._backupPath = backup
    ataxia.updater._backupError = why
    -- The save runs on a background thread. Give it a second before the first uninstall attempt.
    tempTimer(1, "ataxia.updater.swapPackage(1)")
  end
end

-- Runs after the install, because the file is complete only when the background save ends.
function ataxia.updater.reportBackup()
  local path = ataxia.updater._backupPath
  -- No attempt: an older updater, which makes no backup, ran the install of this version.
  if not path and not ataxia.updater._backupError then
    return
  end
  local f = path and io.open(path, "r")
  if f then
    f:close()
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <DimGrey>Your profile from before this update: " .. path .. "\n")
  else
    local why = ataxia.updater._backupError or "the file is not there"
    cecho("<a_darkcyan>(<a_darkmagenta>LEVI<a_darkcyan>): <red>The profile backup failed: " .. why .. "\n")
  end
  ataxia.updater._backupPath, ataxia.updater._backupError = nil, nil
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
  ataxia.updater.reportBackup()
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
