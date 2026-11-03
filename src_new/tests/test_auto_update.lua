--- test_auto_update.lua -- SYSUPDATE keeps a copy of what it removes
--
-- Player report, 2026-11-03: an update removed their edits, and they stopped updating. An update
-- uninstalls the package, so it saves the settings and the profile first. Mudlet refuses the
-- uninstall while that save runs, and the save runs on a background thread.

local mock = require("mock_mudlet")

local TMP = (os.getenv("TEMP") or os.getenv("TMP") or ".") .. "/levi_test_update_" .. os.time()
local DIR = TMP .. "/sysupdate_backups"
-- Windows' mkdir makes the parents, and has no -p. Everywhere else needs -p.
if package.config:sub(1, 1) == "\\" then
  os.execute('mkdir "' .. DIR:gsub("/", "\\") .. '"')
else
  os.execute('mkdir -p "' .. DIR .. '"')
end

local realHome = getMudletHomeDir
getMudletHomeDir = function() return TMP end
function ataxia_Echo() end
ataxia = ataxia or {}
ataxiaVersion = "1.0.0"

dofile("src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/021_Auto_Update.lua")

local PACKAGE = TMP .. "/Levi_update.mpackage"

local calls, timers, saveResult, uninstallResults, echoes
local realCecho, realTimer = cecho, tempTimer

local function write(path, text)
  local f = assert(io.open(path, "w"))
  f:write(text)
  f:close()
end

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local text = f:read("*all")
  f:close()
  return text
end

local function reset()
  calls, timers, echoes, uninstallResults = {}, {}, {}, {}
  for i = 1, 4 do os.remove(DIR .. "/backup_" .. i .. ".xml") end
  saveResult = function(folder, name)
    local path = folder .. "/" .. name .. ".xml"
    write(path, "new")
    return true, path
  end
  ataxia_saveSettings = function() calls[#calls + 1] = "settings" end
  saveProfile = function(folder, name)
    calls[#calls + 1] = "profile"
    return saveResult(folder, name)
  end
  uninstallPackage = function(name)
    calls[#calls + 1] = "uninstall " .. name
    local r = table.remove(uninstallResults, 1)
    if r then return nil, r end
    return true
  end
  installPackage = function(path) calls[#calls + 1] = "install " .. path end
  tempTimer = function(delay, code) timers[#timers + 1] = code end
  cecho = function(text) echoes[#echoes + 1] = text end
  ataxia.updater.packageFile = PACKAGE
  ataxia.updater.latestKnown = nil
end

-- Runs every timer in order, as the time passes, including timers that those timers start.
local function runTimers()
  local i = 1
  while i <= #timers do
    assert(loadstring(timers[i]))()
    i = i + 1
  end
end

local function downloaded()
  write(PACKAGE, "package")
  ataxia.updater.onDownloadDone(nil, PACKAGE)
end

local function echoed(fragment)
  for _, text in ipairs(echoes) do
    if text:find(fragment, 1, true) then return true end
  end
  return false
end

describe("SYSUPDATE keeps a copy of what it removes", function()
  it("saves the settings, then the profile, before it uninstalls", function()
    reset()
    downloaded()
    expect(calls[1]).toBe("settings")
    expect(calls[2]).toBe("profile")
    expect(#calls).toBe(2) -- no uninstall in the same pass: the background save has only started
    runTimers()
    expect(calls[3]).toBe("uninstall Levi_Ataxia")
    expect(calls[4]).toBe("install " .. PACKAGE)
  end)

  it("saves to its own folder, never to current/, which Mudlet loads at start-up", function()
    reset()
    local folder, name
    saveResult = function(f, n)
      folder, name = f, n
      write(f .. "/" .. n .. ".xml", "new")
      return true, f .. "/" .. n .. ".xml"
    end
    downloaded()
    expect(folder).toBe(DIR)
    expect(name).toBe("backup_1")
  end)

  it("keeps three backups, so that the next update does not overwrite an edit", function()
    reset()
    write(DIR .. "/backup_1.xml", "newest")
    write(DIR .. "/backup_2.xml", "middle")
    write(DIR .. "/backup_3.xml", "oldest")
    downloaded()
    expect(read(DIR .. "/backup_1.xml")).toBe("new")
    expect(read(DIR .. "/backup_2.xml")).toBe("newest")
    expect(read(DIR .. "/backup_3.xml")).toBe("middle")
    expect(read(DIR .. "/backup_4.xml")).toBe(nil)
  end)

  it("retries the uninstall while Mudlet refuses it for a running save", function()
    reset()
    uninstallResults = {
      "a profile save is in progress, try again once it has finished",
      "a profile save is in progress, try again once it has finished",
    }
    downloaded()
    runTimers()
    local uninstalls, installs = 0, 0
    for _, c in ipairs(calls) do
      if c:find("^uninstall") then uninstalls = uninstalls + 1 end
      if c:find("^install") then installs = installs + 1 end
    end
    expect(uninstalls).toBe(3)
    expect(installs).toBe(1)
  end)

  it("stops with the old version in place if the save never ends", function()
    reset()
    for i = 1, 40 do uninstallResults[i] = "a profile save is in progress" end
    downloaded()
    runTimers()
    for _, c in ipairs(calls) do
      expect(c:find("^install")).toBe(nil)
    end
    expect(ataxia.updater._pendingInstall).toBe(nil)
    expect(echoed("Update stopped")).toBe(true)
  end)

  it("still installs for any other uninstall failure, as it always did", function()
    reset()
    uninstallResults = { "package 'Levi_Ataxia' is not installed" }
    downloaded()
    runTimers()
    expect(calls[#calls]).toBe("install " .. PACKAGE)
  end)

  it("still updates if the backup fails, and says so", function()
    reset()
    saveResult = function() return nil, "the disk is full" end
    downloaded()
    runTimers()
    expect(calls[#calls]).toBe("install " .. PACKAGE)
    expect(echoed("the disk is full")).toBe(true)
  end)

  it("still updates if saveProfile throws, as a client without it would", function()
    reset()
    saveProfile = function() error("attempt to call global 'saveProfile' (a nil value)") end
    downloaded()
    runTimers()
    expect(calls[#calls]).toBe("install " .. PACKAGE)
    expect(echoed("profile backup failed")).toBe(true)
  end)

  it("still updates if saving the settings throws", function()
    reset()
    ataxia_saveSettings = function() error("boom") end
    downloaded()
    runTimers()
    expect(calls[#calls]).toBe("install " .. PACKAGE)
  end)

  it("names the backup after the install, when the file is complete", function()
    reset()
    downloaded()
    runTimers()
    expect(echoed(DIR .. "/backup_1.xml")).toBe(true)
  end)

  it("reports a failure if Mudlet accepted the save but the file never came", function()
    reset()
    saveResult = function(f, n) return true, f .. "/" .. n .. ".xml" end
    downloaded()
    runTimers()
    expect(echoed("profile backup failed")).toBe(true)
  end)

  it("says nothing about a backup when an older updater ran the install", function()
    reset()
    ataxia.updater._pendingInstall = PACKAGE
    ataxia.updater._installOk = true
    ataxia.updater._backupPath, ataxia.updater._backupError = nil, nil
    ataxia.updater.finishInstall()
    expect(echoed("backup")).toBe(false)
  end)

  it("warns in the new-version notice that an update replaces edits", function()
    reset()
    ataxia.updater.versionFile = TMP .. "/version.txt"
    write(ataxia.updater.versionFile, "2.0.0")
    ataxia.updater.onDownloadDone(nil, ataxia.updater.versionFile)
    expect(echoed("replaces edits inside Levi_Ataxia")).toBe(true)
  end)
end)

-- Restore what other test files share.
getMudletHomeDir, cecho, tempTimer = realHome, realCecho, realTimer
saveProfile, uninstallPackage, installPackage, ataxia_saveSettings = nil, nil, nil, nil
for i = 1, 4 do os.remove(DIR .. "/backup_" .. i .. ".xml") end
os.remove(PACKAGE)
