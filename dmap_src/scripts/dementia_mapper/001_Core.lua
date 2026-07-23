--[[mudlet
type: script
name: dmap Core
hierarchy:
- Dementia_Mapper
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    DEMENTIA MAPPER (dmap) - standalone Mnemosyne mapper + auto-explorer
    ============================================================================
    A self-contained Mudlet package that maps and auto-explores the Achaea
    Mnemosyne ("tides of memory"), whose incurable dementia (Creville's Legacy)
    FAKES the gmcp exits/area -- so a normal mapper can't trust the room data.
    This extracts the dementia-tolerant map + explorer from the LEVI combat
    system into a `dmap` namespace that runs with NO other dependencies.

    Modules:
      001_Core      - namespace, config, run lifecycle (this file)
      002_Map       - room graph, BFS relayout, dementia-tolerant routing
      003_Denizens  - own gmcp.Char.Items room-denizen tracking
      004_Explorer  - auto-navigation move-machine (basher-free)
      005_Window    - the 4x4 mini-map window
      006_Commands  - `dmap ...` command dispatch
    ============================================================================
]]--

dmap = dmap or {}

-- Config (persisted via Mudlet's own profile if the user saves; plain table here).
dmap.config = dmap.config or {}
dmap.config.separator   = dmap.config.separator   or ";"     -- command separator
dmap.config.autoShow    = (dmap.config.autoShow ~= false)    -- show the map on tower entry
-- Optional combat hook for auto-explore. Leave nil for MAP-ONLY (explorer waits for you to
-- clear a room, then moves on). Set to a function(id, name) that sends your attack, e.g.
--   dmap.config.attack = function(id) send("kill " .. id) end
-- and the explorer will clear rooms itself. See 004_Explorer / `dmap attack`.
dmap.config.attack      = dmap.config.attack      or nil

-- Run lifecycle: `active` == "we are inside a Mnemosyne ripple". Set by the wade-status
-- trigger (001_Wade_Status), cleared by run-end (005_Run_End). The map + explorer both gate
-- on this single flag (the LEVI original juggled a basher flag + a telemetry run; dmap has one).
dmap.run = dmap.run or { active = false, ripple = nil }

function dmap.setActive(on)
  local was = dmap.run.active
  dmap.run.active = on and true or false
  if was and not dmap.run.active then
    -- Left the tower: stop any sweep + hide the map.
    if dmap.explore and dmap.exploreStop then dmap.exploreStop("left tower") end
    if dmap.map and dmap.map.autoShow then dmap.map.autoShow() end
  end
end

-- Ripple level changed (or first entry): the map resets per ripple.
function dmap.onRipple(n)
  n = tonumber(n)
  if n then dmap.run.ripple = n end
  dmap.run.active = true
  if dmap.map and dmap.map.onRipple then dmap.map.onRipple(n) end
end

function dmap.echo(msg)
  cecho("\n<deep_sky_blue>[dmap]<reset> " .. tostring(msg))
end

-- One-time welcome on install, so the package needs no external instructions: it explains what it
-- does + the ONE thing people miss (combat is opt-in). Guarded so it prints at most once.
function dmap._welcome()
  if dmap._welcomed then return end
  dmap._welcomed = true
  cecho("\n<deep_sky_blue>═══ Dementia Mapper installed ═══<reset>")
  cecho("\n<deep_sky_blue>[dmap]<reset> Maps + auto-explores the Mnemosyne — it starts automatically once you wade in.")
  cecho("\n   <cyan>dmap explore on<reset>  auto-sweep the ripple      <cyan>dmap help<reset>  all commands")
  cecho("\n   <yellow>Combat is opt-in:<reset> by default the sweep WAITS for you to clear each room.")
  cecho("\n   For hands-free clearing set your attack, e.g. <cyan>dmap attack curse @id<reset>  (<cyan>dmap attack off<reset> = map-only).")
end

-- Fire the welcome when THIS package is installed (Mudlet raises sysInstall with the package name).
if dmap._installH then pcall(killAnonymousEventHandler, dmap._installH) end
dmap._installH = registerAnonymousEventHandler("sysInstall", function(_, pkg)
  if pkg == "Dementia_Mapper" then dmap._welcome() end
end)
