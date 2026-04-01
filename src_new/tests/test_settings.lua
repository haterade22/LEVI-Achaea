--- test_settings.lua
-- Tests for ataxia_saveSettings() in 001_Save_Load_Settings.lua.
-- Mocks all Mudlet I/O so tests run outside the client.

-- ─── Mock I/O ────────────────────────────────────────────────────────────────

getMudletHomeDir = function() return "/tmp/test_mudlet" end

local _saved = {}   -- in-memory "disk" for table.save / table.load

table.save = function(path, t)
  -- Deep-copy to mimic real serialization
  local function copy(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do dst[copy(k)] = copy(v) end
    return dst
  end
  _saved[path] = copy(t)
end

table.load = function(path, t)
  if _saved[path] then
    for k, v in pairs(_saved[path]) do t[k] = v end
  end
end

io.exists = function(path) return _saved[path] ~= nil end

io.open = function(path, mode)
  if mode == "r" then
    if not _saved[path] then return nil end
    -- Return a minimal file handle whose read() returns a non-trivial string
    return { read = function() return '{"__version":1}' end, close = function() end }
  end
  -- Write mode — no-op handle
  return { write = function() end, close = function() end }
end

ataxia_Echo = function() end   -- silence UI output during tests

-- ─── Reset namespaces ────────────────────────────────────────────────────────

ataxia         = { afflictions = {}, vitals = { bleed = 0 } }
ataxiaBasher   = nil
ataxiaNDB      = nil
ataxiaExtraction = nil
selfLimbDamage = nil
itemCatalog    = nil
ldm            = nil
_ataxia_backup = {}

dofile("src_new/scripts/levi_ataxia/levi/ataxia/001_Save_Load_Settings.lua")

-- ─── ataxia_saveSettings() ───────────────────────────────────────────────────

describe("ataxia_saveSettings()", function()
  it("returns false when ataxia.settings is nil", function()
    ataxia.settings = nil
    local result = ataxia_saveSettings()
    expect(result).toBeFalse()
  end)

  it("calls table.save for the main ataxia table when settings exist", function()
    _saved = {}
    ataxia.settings = { class = "Serpent", separator = "/" }
    ataxia_saveSettings()
    local found = false
    for path in pairs(_saved) do
      if path:find("ataxia") then found = true end
    end
    expect(found).toBeTrue()
  end)

  it("does not save basher when ataxiaBasher is nil", function()
    _saved = {}
    ataxia.settings = { class = "Serpent" }
    ataxiaBasher = nil
    ataxia_saveSettings()
    local basherSaved = false
    for path in pairs(_saved) do
      if path:find("basher") then basherSaved = true end
    end
    expect(basherSaved).toBeFalse()
  end)

  it("saves basher table when ataxiaBasher is populated", function()
    _saved = {}
    ataxia.settings = { class = "Serpent" }
    ataxiaBasher = { enabled = false, targetList = {} }
    ataxia_saveSettings()
    local found = false
    for path in pairs(_saved) do
      if path:find("basher") then found = true end
    end
    expect(found).toBeTrue()
  end)

  it("does not error when optional subsystems are absent", function()
    _saved = {}
    ataxia.settings  = { class = "Magi" }
    ataxiaBasher     = nil
    ataxiaNDB        = nil
    ataxiaExtraction = nil
    selfLimbDamage   = nil
    itemCatalog      = nil
    ldm              = nil
    -- Should complete without raising an error
    ataxia_saveSettings()
    expect(true).toBeTrue()
  end)

  it("populates _ataxia_backup.ataxia after saving", function()
    _saved = {}
    _ataxia_backup = {}
    ataxia.settings = { class = "Blademaster" }
    ataxia_saveSettings()
    -- table.load fills _ataxia_backup.ataxia from the just-saved file
    expect(type(_ataxia_backup.ataxia)).toBe("table")
  end)
end)
