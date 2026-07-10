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
ataxiaEcho  = function() end   -- NDB/extraction echo helper (used by ataxia_loadSettings)

-- deepcopy is a Mudlet global used by the load path's profile-backup restores.
deepcopy = function(src)
  local function copy(s)
    if type(s) ~= "table" then return s end
    local d = {}
    for k, v in pairs(s) do d[copy(k)] = copy(v) end
    return d
  end
  return copy(src)
end

-- ataxiaNDB_Install lives in another file (not loaded here). The load path only
-- calls it when there is genuinely no name database on disk or in backup; the
-- tests below avoid that branch, but stub it so an accidental hit is observable.
ataxiaNDB_Install = function() ataxiaNDB = { installed = true, players = {}, _installed_by_stub = true } end

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

-- ─── ataxia_loadSettings() resilience ────────────────────────────────────────
-- Regression coverage for the qwp "NDB not loaded" bug: the load path used to set
-- ataxia.loaded early and run every sub-load in one un-isolated function, so a
-- corrupt basher/paths/extraction file could abort the whole load before the NDB
-- block ran, leaving ataxiaNDB nil forever.

local ATAXIA = "/tmp/test_mudlet/ataxia"
local BASHER = "/tmp/test_mudlet/basher"
local ANDB   = "/tmp/test_mudlet/andb"

local function freshLoadState()
  _saved         = {}
  _ataxia_backup = {}
  ataxia         = { afflictions = {}, vitals = { bleed = 0 } }
  ataxiaBasher   = nil
  ataxiaNDB      = nil
  ataxiaExtraction = nil
  selfLimbDamage = nil
  itemCatalog    = nil
  ldm            = nil
end

describe("ataxia_loadSettings()", function()
  it("loads the name database and marks loaded on a clean start", function()
    freshLoadState()
    _saved[ATAXIA] = { settings = { class = "Priest" } }
    _saved[ANDB]   = { installed = true, players = { Someone = { city = "Targossas" } } }

    ataxia_loadSettings()

    expect(type(ataxiaNDB)).toBe("table")
    expect(ataxiaNDB.players.Someone.city).toBe("Targossas")
    expect(ataxia.loaded).toBeTrue()
  end)

  it("still loads the name database when an earlier sub-load throws", function()
    freshLoadState()
    _saved[ATAXIA] = { settings = { class = "Serpent" } }
    _saved[BASHER] = { enabled = true }
    _saved[ANDB]   = { installed = true, players = { Keeper = { city = "Mhaldor" } } }

    -- Simulate a corrupt basher file: table.load throws the first time it is read.
    local realLoad = table.load
    local threw = false
    table.load = function(path, t)
      if path:find("basher") and not threw then
        threw = true
        error("simulated corrupt basher file")
      end
      return realLoad(path, t)
    end

    ataxia_loadSettings()
    table.load = realLoad

    -- NDB block runs despite the earlier failure, and the load completes.
    expect(type(ataxiaNDB)).toBe("table")
    expect(ataxiaNDB.players.Keeper.city).toBe("Mhaldor")
    expect(ataxia.loaded).toBeTrue()
  end)

  it("does not overwrite the on-disk name database when its own load throws", function()
    freshLoadState()
    _saved[ATAXIA] = { settings = { class = "Magi" } }
    _saved[ANDB]   = { installed = true, players = { Archivist = { city = "Cyrene" } } }

    -- andb is present but unreadable: table.load throws only for it.
    local realLoad = table.load
    table.load = function(path, t)
      if path:find("andb") then error("simulated corrupt andb file") end
      return realLoad(path, t)
    end

    ataxia_loadSettings()
    table.load = realLoad

    -- Must NOT install an empty DB over the good file: ataxiaNDB stays nil (so the
    -- save guard `if ataxiaNDB then` skips it) and the disk file is preserved intact.
    expect(ataxiaNDB).toBeNil()
    expect(_saved[ANDB].players.Archivist.city).toBe("Cyrene")
  end)

  it("loads without stack-overflowing when the saved data has a cyclic reference", function()
    -- Regression for the real "NDB not loaded" root cause: deepMerge in mergeLoad had
    -- no cycle guard, so a cyclic/self-referential saved table recursed forever ->
    -- stack overflow -> the whole loader aborted before the NDB block.
    freshLoadState()
    ataxia = { afflictions = {}, vitals = { bleed = 0 } }
    ataxia.selfref = ataxia                       -- live parallel cycle -> deepMerge recurses into it
    local loaded = { settings = { class = "Serpent" } }
    loaded.selfref = loaded                       -- cyclic saved data
    _saved[ATAXIA] = loaded
    _saved[ANDB]   = { installed = true, players = { Cyclist = { city = "Hashan" } } }

    -- Neutralize the cycle-unsafe mock serializer for the end-of-load save so this
    -- test isolates the loader's deepMerge, not the mock's table.save.
    local realSave = table.save
    table.save = function() end

    ataxia_loadSettings()                          -- must return, not stack overflow

    table.save = realSave

    expect(ataxia.loaded).toBeTrue()
    expect(type(ataxiaNDB)).toBe("table")
    expect(ataxiaNDB.players.Cyclist.city).toBe("Hashan")
  end)

  it("still loads NDB when the main-settings load itself throws", function()
    freshLoadState()
    _saved[ATAXIA] = { settings = { class = "Sylvan" } }
    _saved[ANDB]   = { installed = true, players = { Survivor = { city = "Eleusis" } } }

    -- Main ataxia file read throws once (e.g. a bad merge). The pcall around the
    -- main-settings load must keep the loader going so NDB still loads.
    local realLoad = table.load
    local threw = false
    table.load = function(path, t)
      if path:find("ataxia") and not path:find("andb") and not threw then
        threw = true
        error("simulated main-settings load failure")
      end
      return realLoad(path, t)
    end

    ataxia_loadSettings()
    table.load = realLoad

    expect(type(ataxiaNDB)).toBe("table")
    expect(ataxiaNDB.players.Survivor.city).toBe("Eleusis")
  end)

  it("does not pollute a live GUI object with a stale serialized snapshot", function()
    -- GUI objects (e.g. ataxia.mnemosyne.map.window) live in the saved `ataxia`
    -- namespace, so a stale serialized snapshot is on disk. deepMerge must leave the
    -- live Geyser object untouched -- merging the snapshot pollutes its windowList
    -- with plain-table children, so container:hide()/show() later crashes.
    freshLoadState()
    ataxia = { afflictions = {}, vitals = { bleed = 0 } }
    local liveWindow = setmetatable(
      { windowList = { realChild = { name = "real" } }, hide = function() end, show = function() end },
      {})
    ataxia.gui = { window = liveWindow }
    _saved[ATAXIA] = { gui = { window = { windowList = { staleChild = { name = "stale" } } } } }
    _saved[ANDB]   = { installed = true, players = {} }

    local realSave = table.save
    table.save = function() end
    ataxia_loadSettings()
    table.save = realSave

    expect(ataxia.gui.window).toBe(liveWindow)                 -- same object, not replaced
    expect(ataxia.gui.window.windowList.staleChild).toBeNil()  -- not polluted
    expect(ataxia.gui.window.windowList.realChild.name).toBe("real")
    expect(ataxia.loaded).toBeTrue()
  end)

  it("does not restore a serialized GUI snapshot into a fresh/empty key", function()
    -- Cells (labels) start as an empty {} at load, so a saved snapshot would hit the
    -- assign branch and become a methodless table. It must be skipped; plain sibling
    -- data must still load normally (no false positive).
    freshLoadState()
    ataxia = { afflictions = {}, vitals = { bleed = 0 } }
    ataxia.map = { cells = {} }
    _saved[ATAXIA] = { map = {
      cells = { cell1 = { type = "label", stylesheet = "x", container = { name = "c" } } },
      cfg   = { zoom = 3 },
    } }
    _saved[ANDB] = { installed = true, players = {} }

    local realSave = table.save
    table.save = function() end
    ataxia_loadSettings()
    table.save = realSave

    expect(ataxia.map.cells.cell1).toBeNil()   -- GUI snapshot skipped
    expect(ataxia.map.cfg.zoom).toBe(3)        -- plain data still loaded
  end)

  it("strips GUI snapshots nested inside a wholesale-assigned subtree", function()
    -- ataxia.bars doesn't exist at load, so the whole subtree is assigned at once;
    -- the recursive pre-strip must still remove the nested window snapshot while
    -- keeping sibling data (the per-key deepMerge guard alone would miss this).
    freshLoadState()
    ataxia = { afflictions = {}, vitals = { bleed = 0 } }
    _saved[ATAXIA] = { bars = {
      hp = { window = { nestedLabels = { l1 = { name = "x" } } }, max = 100 },
    } }
    _saved[ANDB] = { installed = true, players = {} }

    local realSave = table.save
    table.save = function() end
    ataxia_loadSettings()
    table.save = realSave

    expect(ataxia.bars.hp.window).toBeNil()   -- nested GUI snapshot stripped
    expect(ataxia.bars.hp.max).toBe(100)      -- sibling data kept
  end)

  it("saveSettings strips live GUI objects from the serialized data", function()
    _saved = {}
    _ataxia_backup = {}
    ataxiaBasher, ataxiaNDB, ataxiaExtraction, selfLimbDamage, itemCatalog, ldm = nil, nil, nil, nil, nil, nil
    ataxia = { settings = { class = "Serpent" }, mnemosyne = { map = {} } }
    ataxia.mnemosyne.map.window = setmetatable(
      { windowList = {}, hide = function() end, show = function() end }, {})
    ataxia.mnemosyne.map.rooms = { r1 = { num = 1 } }

    ataxia_saveSettings()

    local savedAtaxia
    for path, data in pairs(_saved) do
      if path:find("ataxia") and not path:find("andb") then savedAtaxia = data end
    end
    expect(type(savedAtaxia)).toBe("table")
    expect(savedAtaxia.mnemosyne.map.window).toBeNil()      -- live GUI object stripped
    expect(savedAtaxia.mnemosyne.map.rooms.r1.num).toBe(1)  -- data kept
    expect(savedAtaxia.settings.class).toBe("Serpent")
  end)
end)
